#!/bin/bash

################################################################################
# dev-start.sh - Start EnGarde Development Environment
#
# Purpose: Start the development environment with hot-reload and health checks
# Usage: ./dev-start.sh [OPTIONS]
# Author: EnGarde DevOps Team
################################################################################

set -e  # Exit on error

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Project root directory (absolute path)
readonly PROJECT_ROOT="/Users/cope/EnGardeHQ"
readonly COMPOSE_FILE="${PROJECT_ROOT}/docker-compose.dev.yml"

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

################################################################################
# Pre-flight Checks
################################################################################

check_dependencies() {
    log_info "Checking dependencies..."

    local missing_deps=()

    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        missing_deps+=("docker-compose")
    fi

    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Please install the missing dependencies and try again."
        exit 2
    fi

    log_success "All dependencies installed"
}

check_docker_running() {
    log_info "Checking if Docker is running..."

    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker Desktop and try again."
        exit 1
    fi

    log_success "Docker is running"
}

check_compose_file() {
    log_info "Checking Docker Compose file..."

    if [ ! -f "$COMPOSE_FILE" ]; then
        log_error "Docker Compose file not found: $COMPOSE_FILE"
        exit 1
    fi

    log_success "Docker Compose file found"
}

check_env_file() {
    log_info "Checking environment configuration..."

    if [ ! -f "${PROJECT_ROOT}/.env" ]; then
        log_warning ".env file not found at ${PROJECT_ROOT}/.env"
        if [ -f "${PROJECT_ROOT}/.env.example" ]; then
            log_info "Found .env.example - you may want to copy it to .env"
            log_info "  cp ${PROJECT_ROOT}/.env.example ${PROJECT_ROOT}/.env"
        fi
    else
        log_success "Environment file found"
    fi
}

################################################################################
# Service Management
################################################################################

start_services() {
    print_header "Starting Development Services"

    cd "$PROJECT_ROOT"

    log_info "Starting services with docker-compose..."
    log_info "Using: $COMPOSE_FILE"

    # Use docker compose (v2) or docker-compose (v1)
    if docker compose version &> /dev/null; then
        docker compose -f "$COMPOSE_FILE" up -d
    else
        docker-compose -f "$COMPOSE_FILE" up -d
    fi

    log_success "Services started"
}

wait_for_health() {
    local service=$1
    local max_attempts=30
    local attempt=1

    log_info "Waiting for $service to be healthy..."

    while [ $attempt -le $max_attempts ]; do
        local health_status
        if docker compose version &> /dev/null; then
            health_status=$(docker compose -f "$COMPOSE_FILE" ps --format json "$service" 2>/dev/null | grep -o '"Health":"[^"]*"' | cut -d'"' -f4 || echo "")
        else
            health_status=$(docker-compose -f "$COMPOSE_FILE" ps "$service" 2>/dev/null | grep -o "healthy" || echo "")
        fi

        if [[ "$health_status" == *"healthy"* ]] || [[ "$health_status" == "healthy" ]]; then
            log_success "$service is healthy"
            return 0
        fi

        echo -n "."
        sleep 2
        ((attempt++))
    done

    echo ""
    log_warning "$service health check timed out (may still be starting)"
    return 1
}

check_service_endpoints() {
    print_header "Checking Service Endpoints"

    # Check Postgres
    if command -v pg_isready &> /dev/null; then
        if pg_isready -h localhost -p 5432 -U engarde_user &> /dev/null; then
            log_success "PostgreSQL is ready"
        else
            log_warning "PostgreSQL may still be initializing"
        fi
    fi

    # Check Redis
    if command -v redis-cli &> /dev/null; then
        if redis-cli -h localhost -p 6379 ping &> /dev/null; then
            log_success "Redis is ready"
        else
            log_warning "Redis may still be initializing"
        fi
    fi

    # Check Backend
    sleep 5  # Give backend a moment to start
    if curl -sf http://localhost:8000/health &> /dev/null; then
        log_success "Backend API is ready"
    else
        log_warning "Backend API may still be starting (this can take 30-60 seconds)"
    fi

    # Check Frontend
    sleep 3
    if curl -sf http://localhost:3000 &> /dev/null; then
        log_success "Frontend is ready"
    else
        log_warning "Frontend may still be building (this can take 1-2 minutes)"
    fi
}

display_urls() {
    print_header "Development Environment Ready"

    echo ""
    echo -e "${GREEN}🚀 Services are running!${NC}"
    echo ""
    echo -e "${BLUE}Service URLs:${NC}"
    echo -e "  Frontend:        ${GREEN}http://localhost:3000${NC}"
    echo -e "  Backend API:     ${GREEN}http://localhost:8000${NC}"
    echo -e "  API Docs:        ${GREEN}http://localhost:8000/docs${NC}"
    echo -e "  PostgreSQL:      ${GREEN}localhost:5432${NC}"
    echo -e "  Redis:           ${GREEN}localhost:6379${NC}"
    echo ""
    echo -e "${BLUE}Useful Commands:${NC}"
    echo -e "  View logs:       ${YELLOW}./scripts/dev-logs.sh${NC}"
    echo -e "  Check health:    ${YELLOW}./scripts/dev-health.sh${NC}"
    echo -e "  Stop services:   ${YELLOW}./scripts/dev-stop.sh${NC}"
    echo -e "  Rebuild:         ${YELLOW}./scripts/dev-rebuild.sh${NC}"
    echo ""
    echo -e "${BLUE}Hot Reload:${NC}"
    echo -e "  Backend:  Edit files in ${YELLOW}production-backend/app/${NC} - changes apply immediately"
    echo -e "  Frontend: Edit files in ${YELLOW}production-frontend/${NC} - Next.js auto-reloads"
    echo ""
    echo -e "${GREEN}Happy coding! 🎉${NC}"
    echo ""
}

################################################################################
# Main Execution
################################################################################

main() {
    print_header "EnGarde Development Environment Startup"

    # Pre-flight checks
    check_dependencies
    check_docker_running
    check_compose_file
    check_env_file

    echo ""

    # Start services
    start_services

    echo ""

    # Wait for services to be healthy
    print_header "Waiting for Services to be Healthy"
    wait_for_health "postgres" || true
    wait_for_health "redis" || true
    wait_for_health "backend" || true
    wait_for_health "frontend" || true

    echo ""

    # Check endpoints
    check_service_endpoints

    echo ""

    # Check and prompt for database seeding if needed
    check_and_prompt_seeding

    echo ""

    # Display URLs and instructions
    display_urls
}

################################################################################
# Database Seeding Integration
################################################################################

check_and_prompt_seeding() {
    print_header "Database Seeding Check"

    # Check if seed status script exists
    if [ ! -f "${PROJECT_ROOT}/scripts/check-seed-status.sh" ]; then
        log_warning "Seed status check script not found - skipping seeding check"
        return 0
    fi

    # Check seed status quietly
    if "${PROJECT_ROOT}/scripts/check-seed-status.sh" --quiet; then
        log_success "Database seed is current"
        return 0
    fi

    # Seed is missing or outdated - prompt user
    log_warning "Database seeding is required"
    echo ""

    # Run interactive seeding prompt
    if [ -f "${PROJECT_ROOT}/scripts/prompt-seed-database.sh" ]; then
        "${PROJECT_ROOT}/scripts/prompt-seed-database.sh"
        return $?
    else
        log_warning "Seed prompt script not found"
        log_info "To seed manually, run: ./scripts/seed-database.sh"
        return 0
    fi
}

# Run main function
main "$@"
