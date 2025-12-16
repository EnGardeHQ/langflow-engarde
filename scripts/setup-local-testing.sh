#!/bin/bash

# EnGarde Local Development Setup Script
# This script sets up a complete local testing environment with all services

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"
COMPOSE_OVERRIDE="$PROJECT_ROOT/docker-compose.local.yml"
MAX_WAIT_TIME=300  # 5 minutes maximum wait time
HEALTH_CHECK_INTERVAL=5

# Function to print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Function to print section headers
print_header() {
    echo ""
    print_color "$CYAN" "=========================================="
    print_color "$CYAN" "$1"
    print_color "$CYAN" "=========================================="
}

# Function to print success messages
print_success() {
    print_color "$GREEN" "✓ $1"
}

# Function to print error messages
print_error() {
    print_color "$RED" "✗ $1"
}

# Function to print warning messages
print_warning() {
    print_color "$YELLOW" "⚠ $1"
}

# Function to print info messages
print_info() {
    print_color "$BLUE" "ℹ $1"
}

# Function to check if Docker is running
check_docker() {
    print_header "Checking Prerequisites"

    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker Desktop."
        exit 1
    fi
    print_success "Docker CLI found"

    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker Desktop."
        exit 1
    fi
    print_success "Docker daemon is running"

    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed."
        exit 1
    fi
    print_success "Docker Compose found"
}

# Function to cleanup old containers and volumes
cleanup_old_environment() {
    print_header "Cleaning Up Old Environment"

    print_info "Stopping all EnGarde containers..."
    if [ -f "$COMPOSE_OVERRIDE" ]; then
        docker-compose -f "$COMPOSE_FILE" -f "$COMPOSE_OVERRIDE" down --remove-orphans 2>/dev/null || true
    else
        docker-compose -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true
    fi
    print_success "Containers stopped"

    print_info "Removing old containers..."
    docker ps -a --filter "name=engarde_" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true
    print_success "Old containers removed"

    print_warning "Keeping volumes for data persistence"
    print_info "To reset database, run: docker volume rm engarde_postgres_data"
}

# Function to build Docker images
build_images() {
    print_header "Building Docker Images"

    print_info "Building images without cache (this may take several minutes)..."
    if [ -f "$COMPOSE_OVERRIDE" ]; then
        docker-compose -f "$COMPOSE_FILE" -f "$COMPOSE_OVERRIDE" build --no-cache --parallel
    else
        docker-compose -f "$COMPOSE_FILE" build --no-cache --parallel
    fi
    print_success "Images built successfully"
}

# Function to start services
start_services() {
    print_header "Starting Services"

    print_info "Starting all services in detached mode..."
    if [ -f "$COMPOSE_OVERRIDE" ]; then
        docker-compose -f "$COMPOSE_FILE" -f "$COMPOSE_OVERRIDE" up -d
    else
        docker-compose -f "$COMPOSE_FILE" up -d
    fi
    print_success "Services started"
}

# Function to wait for a service to be healthy
wait_for_service() {
    local service_name=$1
    local max_wait=$2
    local elapsed=0

    print_info "Waiting for $service_name to be healthy..."

    while [ $elapsed -lt $max_wait ]; do
        if docker inspect --format='{{.State.Health.Status}}' "engarde_$service_name" 2>/dev/null | grep -q "healthy"; then
            print_success "$service_name is healthy"
            return 0
        fi

        # Check if container is running but doesn't have health check
        if docker inspect --format='{{.State.Running}}' "engarde_$service_name" 2>/dev/null | grep -q "true"; then
            if ! docker inspect --format='{{.State.Health}}' "engarde_$service_name" 2>/dev/null | grep -q "Status"; then
                print_success "$service_name is running (no health check)"
                return 0
            fi
        fi

        # Check if container exited
        if docker inspect --format='{{.State.Status}}' "engarde_$service_name" 2>/dev/null | grep -q "exited"; then
            print_error "$service_name exited unexpectedly"
            docker logs --tail 50 "engarde_$service_name"
            return 1
        fi

        echo -n "."
        sleep $HEALTH_CHECK_INTERVAL
        elapsed=$((elapsed + HEALTH_CHECK_INTERVAL))
    done

    echo ""
    print_error "$service_name failed to become healthy within ${max_wait}s"
    print_warning "Container logs:"
    docker logs --tail 50 "engarde_$service_name"
    return 1
}

# Function to wait for all services
wait_for_services() {
    print_header "Waiting for Services to be Healthy"

    # Wait for database first
    wait_for_service "postgres" 60 || exit 1

    # Wait for Redis
    wait_for_service "redis" 30 || exit 1

    # Wait for backend
    wait_for_service "backend" 120 || exit 1

    # Wait for frontend
    wait_for_service "frontend" 120 || exit 1

    # Wait for Langflow (optional)
    wait_for_service "langflow" 90 || print_warning "Langflow may still be starting"

    print_success "All critical services are healthy"
}

# Function to run database migrations
run_migrations() {
    print_header "Running Database Migrations"

    print_info "Executing Alembic migrations..."
    docker exec engarde_backend alembic upgrade head

    if [ $? -eq 0 ]; then
        print_success "Migrations completed successfully"
    else
        print_error "Migrations failed"
        exit 1
    fi
}

# Function to seed test data
seed_test_data() {
    print_header "Seeding Test Data"

    print_info "Checking if test data already exists..."
    local user_exists=$(docker exec engarde_postgres psql -U engarde_user -d engarde -tAc "SELECT COUNT(*) FROM users WHERE email='demo@engarde.local';" 2>/dev/null || echo "0")

    if [ "$user_exists" -gt "0" ]; then
        print_warning "Test data already exists. Skipping seed."
        print_info "To reset database, run: docker volume rm engarde_postgres_data && ./scripts/setup-local-testing.sh"
        return 0
    fi

    print_info "Running seed script..."
    docker exec -i engarde_postgres psql -U engarde_user -d engarde < "$PROJECT_ROOT/production-backend/scripts/seed-local-test-data.sql"

    if [ $? -eq 0 ]; then
        print_success "Test data seeded successfully"
    else
        print_error "Failed to seed test data"
        exit 1
    fi
}

# Function to display test credentials
display_credentials() {
    print_header "Test User Credentials"

    print_color "$GREEN" "Email:    demo@engarde.local"
    print_color "$GREEN" "Password: demo123"
    print_color "$GREEN" "Role:     Admin"
    print_color "$GREEN" "Tenant:   Demo Organization"
}

# Function to display service URLs
display_urls() {
    print_header "Service URLs"

    print_color "$PURPLE" "Frontend Application:"
    print_color "$CYAN" "  → http://localhost:3001"
    print_color "$CYAN" "  → http://127.0.0.1:3001"
    echo ""

    print_color "$PURPLE" "Backend API:"
    print_color "$CYAN" "  → http://localhost:8000"
    print_color "$CYAN" "  → http://localhost:8000/docs (Swagger UI)"
    print_color "$CYAN" "  → http://localhost:8000/redoc (ReDoc)"
    print_color "$CYAN" "  → http://localhost:8000/health (Health Check)"
    echo ""

    print_color "$PURPLE" "Langflow AI Workflow:"
    print_color "$CYAN" "  → http://localhost:7860"
    print_color "$CYAN" "  Username: admin"
    print_color "$CYAN" "  Password: admin"
    echo ""

    print_color "$PURPLE" "Database (PostgreSQL):"
    print_color "$CYAN" "  → localhost:5432"
    print_color "$CYAN" "  Database: engarde"
    print_color "$CYAN" "  Username: engarde_user"
    print_color "$CYAN" "  Password: engarde_password"
    echo ""

    print_color "$PURPLE" "Redis:"
    print_color "$CYAN" "  → localhost:6379"
}

# Function to display helpful commands
display_helpful_commands() {
    print_header "Helpful Commands"

    print_info "View logs for all services:"
    echo "  docker-compose logs -f"
    echo ""

    print_info "View logs for specific service:"
    echo "  docker-compose logs -f backend"
    echo "  docker-compose logs -f frontend"
    echo ""

    print_info "Restart a service:"
    echo "  docker-compose restart backend"
    echo ""

    print_info "Stop all services:"
    echo "  docker-compose down"
    echo ""

    print_info "Reset database (WARNING: destroys all data):"
    echo "  docker-compose down -v"
    echo "  ./scripts/setup-local-testing.sh"
    echo ""

    print_info "Access backend shell:"
    echo "  docker exec -it engarde_backend /bin/bash"
    echo ""

    print_info "Access database shell:"
    echo "  docker exec -it engarde_postgres psql -U engarde_user -d engarde"
}

# Function to verify services are accessible
verify_services() {
    print_header "Verifying Service Accessibility"

    # Check backend health endpoint
    print_info "Checking backend health endpoint..."
    if curl -sf http://localhost:8000/health > /dev/null 2>&1; then
        print_success "Backend is accessible"
    else
        print_warning "Backend health check failed (may still be initializing)"
    fi

    # Check frontend
    print_info "Checking frontend..."
    if curl -sf http://localhost:3001 > /dev/null 2>&1; then
        print_success "Frontend is accessible"
    else
        print_warning "Frontend check failed (may still be initializing)"
    fi

    # Check Langflow
    print_info "Checking Langflow..."
    if curl -sf http://localhost:7860/health > /dev/null 2>&1; then
        print_success "Langflow is accessible"
    else
        print_warning "Langflow check failed (may still be initializing)"
    fi
}

# Main execution
main() {
    print_color "$PURPLE" "
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     EnGarde Local Development Environment Setup              ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
"

    # Change to project root
    cd "$PROJECT_ROOT"

    # Execute setup steps
    check_docker
    cleanup_old_environment
    build_images
    start_services
    wait_for_services

    # Small delay to ensure backend is ready
    print_info "Waiting for backend to fully initialize..."
    sleep 10

    run_migrations
    seed_test_data
    verify_services

    # Display information
    echo ""
    display_credentials
    display_urls
    display_helpful_commands

    # Final success message
    print_header "Setup Complete"
    print_color "$GREEN" "
Your EnGarde local development environment is ready!

Access the application at: http://localhost:3001
Login with: demo@engarde.local / demo123

Happy developing!
"
}

# Run main function
main
