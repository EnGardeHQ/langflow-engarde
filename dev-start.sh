#!/bin/bash
# EnGarde Development Environment Startup Script
# This script makes it easy to start the development environment with hot-reload

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker Desktop or Docker Engine."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to check Docker Compose version
check_compose_version() {
    if ! command -v docker compose &> /dev/null; then
        print_error "Docker Compose v2 is not installed. Please upgrade Docker Desktop or install Docker Compose v2."
        exit 1
    fi

    version=$(docker compose version --short 2>/dev/null || echo "0.0.0")
    required_version="2.22.0"

    if [ "$(printf '%s\n' "$required_version" "$version" | sort -V | head -n1)" != "$required_version" ]; then
        print_warning "Docker Compose version $version detected. Watch mode requires v2.22.0+."
        print_warning "Watch mode may not work correctly. Consider upgrading Docker Desktop."
    else
        print_success "Docker Compose version $version (meets requirements)"
    fi
}

# Function to create necessary directories
create_directories() {
    print_info "Creating necessary directories..."

    mkdir -p ./production-backend/uploads
    mkdir -p ./production-backend/marketplace/csv_imports
    mkdir -p ./production-backend/logs
    mkdir -p ./production-backend/app/static/cached_logos

    print_success "Directories created"
}

# Function to check for .env files
check_env_files() {
    print_info "Checking for .env files..."

    if [ ! -f ./.env ]; then
        print_warning "Root .env file not found. Creating from example..."
        if [ -f ./.env.example ]; then
            cp ./.env.example ./.env
            print_success "Created .env from .env.example"
        else
            print_warning "No .env.example found. Using defaults."
        fi
    fi

    if [ ! -f ./production-backend/.env ]; then
        print_warning "Backend .env file not found."
    fi

    if [ ! -f ./production-frontend/.env ]; then
        print_warning "Frontend .env file not found."
    fi
}

# Function to clean up old containers and volumes
cleanup() {
    print_info "Cleaning up old development containers..."
    docker compose -f docker-compose.dev.yml down --remove-orphans
    print_success "Cleanup complete"
}

# Function to start services in watch mode
start_watch_mode() {
    print_info "Starting development environment with watch mode..."
    print_info "This will:"
    print_info "  - Build development containers"
    print_info "  - Start PostgreSQL, Redis, Backend, and Frontend"
    print_info "  - Enable hot-reload for code changes"
    echo ""

    # Build and start services
    docker compose -f docker-compose.dev.yml up --build -d

    print_success "Services are starting..."
    echo ""
    print_info "Waiting for services to become healthy..."
    sleep 5

    # Show status
    docker compose -f docker-compose.dev.yml ps

    echo ""
    print_success "Development environment is ready!"
    echo ""
    print_info "Access points:"
    echo "  Frontend:  http://localhost:3000"
    echo "  Backend:   http://localhost:8000"
    echo "  Docs:      http://localhost:8000/docs"
    echo "  PostgreSQL: localhost:5432"
    echo "  Redis:      localhost:6379"
    echo ""
    print_info "To enable automatic sync on file changes, run:"
    echo "  docker compose -f docker-compose.dev.yml watch"
    echo ""
    print_info "To view logs:"
    echo "  docker compose -f docker-compose.dev.yml logs -f [service]"
    echo ""
    print_info "To stop services:"
    echo "  docker compose -f docker-compose.dev.yml down"
}

# Function to start services with watch mode automatically
start_with_watch() {
    print_info "Starting development environment with automatic watch mode..."

    # Build and start services in background
    docker compose -f docker-compose.dev.yml up --build -d

    print_success "Services are starting in background..."
    sleep 5

    # Show status
    docker compose -f docker-compose.dev.yml ps

    echo ""
    print_success "Development environment is ready!"
    echo ""
    print_info "Access points:"
    echo "  Frontend:  http://localhost:3000"
    echo "  Backend:   http://localhost:8000"
    echo "  Docs:      http://localhost:8000/docs"
    echo ""
    print_info "Starting watch mode (automatic sync on file changes)..."
    print_warning "Press Ctrl+C to stop watch mode (services will continue running)"
    echo ""

    # Start watch mode (this will block and show sync events)
    docker compose -f docker-compose.dev.yml watch
}

# Main script
main() {
    echo ""
    echo "============================================"
    echo "  EnGarde Development Environment"
    echo "============================================"
    echo ""

    # Parse command line arguments
    WATCH_MODE=false
    CLEAN=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --watch|-w)
                WATCH_MODE=true
                shift
                ;;
            --clean|-c)
                CLEAN=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  -w, --watch    Start with automatic watch mode"
                echo "  -c, --clean    Clean up old containers before starting"
                echo "  -h, --help     Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0              # Start services (manual watch mode)"
                echo "  $0 --watch      # Start services with automatic watch"
                echo "  $0 --clean      # Clean and start services"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Run checks
    check_docker
    check_compose_version
    create_directories
    check_env_files

    # Clean up if requested
    if [ "$CLEAN" = true ]; then
        cleanup
    fi

    # Start services
    if [ "$WATCH_MODE" = true ]; then
        start_with_watch
    else
        start_watch_mode
    fi
}

# Run main function
main "$@"
