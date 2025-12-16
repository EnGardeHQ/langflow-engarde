#!/bin/bash

################################################################################
# dev-rebuild.sh - Force Clean Rebuild of Development Environment
#
# Purpose: Rebuild services from scratch without cache
# Usage: ./dev-rebuild.sh [OPTIONS]
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

# Options
FOLLOW_LOGS=false

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

show_help() {
    cat << EOF
Usage: ./dev-rebuild.sh [OPTIONS]

Force a clean rebuild of the development environment.
This clears all caches and rebuilds images from scratch.

OPTIONS:
    --logs, -l          Follow logs after rebuild
    --help, -h          Show this help message

EXAMPLES:
    # Basic rebuild
    ./dev-rebuild.sh

    # Rebuild and watch logs
    ./dev-rebuild.sh --logs

WHAT THIS DOES:
    1. Stop all running containers
    2. Clear Docker build cache
    3. Rebuild images without cache
    4. Restart services
    5. Optionally follow logs

WHEN TO USE:
    - After changing Dockerfiles
    - After updating dependencies (package.json, requirements.txt)
    - When experiencing weird caching issues
    - After major code changes that affect build process

NOTE:
    - This preserves your database volumes
    - Build may take 5-10 minutes depending on your machine
    - Frontend build is the slowest part

EOF
}

################################################################################
# Parse Arguments
################################################################################

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --logs|-l)
                FOLLOW_LOGS=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

################################################################################
# Build Functions
################################################################################

check_docker_running() {
    log_info "Checking if Docker is running..."

    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker Desktop and try again."
        exit 1
    fi

    log_success "Docker is running"
}

stop_services() {
    print_header "Stopping Services"

    cd "$PROJECT_ROOT"

    log_info "Stopping containers..."

    # Use docker compose (v2) or docker-compose (v1)
    if docker compose version &> /dev/null; then
        docker compose -f "$COMPOSE_FILE" down
    else
        docker-compose -f "$COMPOSE_FILE" down
    fi

    log_success "Containers stopped"
}

clear_build_cache() {
    print_header "Clearing Build Cache"

    log_warning "This will clear Docker build cache to ensure a clean rebuild"
    log_info "Docker builder prune in progress..."

    # Prune build cache
    docker builder prune -f &> /dev/null || true

    log_success "Build cache cleared"
}

rebuild_images() {
    print_header "Rebuilding Images"

    cd "$PROJECT_ROOT"

    log_info "Building images without cache (this may take several minutes)..."
    log_info "Grab a coffee - frontend build typically takes 3-5 minutes ☕"

    echo ""

    # Use docker compose (v2) or docker-compose (v1)
    if docker compose version &> /dev/null; then
        docker compose -f "$COMPOSE_FILE" build --no-cache --progress=plain
    else
        docker-compose -f "$COMPOSE_FILE" build --no-cache --progress=plain
    fi

    echo ""
    log_success "Images rebuilt successfully"
}

start_services() {
    print_header "Starting Services"

    cd "$PROJECT_ROOT"

    log_info "Starting services with new images..."

    # Use docker compose (v2) or docker-compose (v1)
    if docker compose version &> /dev/null; then
        docker compose -f "$COMPOSE_FILE" up -d
    else
        docker-compose -f "$COMPOSE_FILE" up -d
    fi

    log_success "Services started"
}

wait_for_services() {
    print_header "Waiting for Services"

    log_info "Waiting for services to be healthy (this may take 30-60 seconds)..."

    local max_wait=60
    local waited=0

    while [ $waited -lt $max_wait ]; do
        sleep 2
        ((waited+=2))

        # Check if backend is responding
        if curl -sf http://localhost:8000/health &> /dev/null; then
            log_success "Backend is ready"
            break
        fi

        echo -n "."
    done

    echo ""

    # Quick check on frontend
    sleep 5
    if curl -sf http://localhost:3000 &> /dev/null; then
        log_success "Frontend is ready"
    else
        log_warning "Frontend may still be starting (check logs)"
    fi
}

follow_logs() {
    print_header "Following Logs"

    log_info "Press Ctrl+C to stop watching logs"
    echo ""

    cd "$PROJECT_ROOT"

    # Use docker compose (v2) or docker-compose (v1)
    if docker compose version &> /dev/null; then
        docker compose -f "$COMPOSE_FILE" logs -f
    else
        docker-compose -f "$COMPOSE_FILE" logs -f
    fi
}

show_summary() {
    print_header "Rebuild Complete"

    echo ""
    echo -e "${GREEN}🎉 Rebuild successful!${NC}"
    echo ""
    echo -e "${BLUE}Services:${NC}"
    echo -e "  Frontend:     ${GREEN}http://localhost:3000${NC}"
    echo -e "  Backend API:  ${GREEN}http://localhost:8000${NC}"
    echo -e "  API Docs:     ${GREEN}http://localhost:8000/docs${NC}"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo -e "  View logs:    ${YELLOW}./scripts/dev-logs.sh${NC}"
    echo -e "  Check health: ${YELLOW}./scripts/dev-health.sh${NC}"
    echo ""
}

################################################################################
# Main Execution
################################################################################

main() {
    parse_args "$@"

    print_header "EnGarde Development Environment - Force Rebuild"

    # Pre-flight checks
    check_docker_running

    echo ""

    # Stop services
    stop_services

    echo ""

    # Clear cache
    clear_build_cache

    echo ""

    # Rebuild images
    rebuild_images

    echo ""

    # Start services
    start_services

    echo ""

    # Wait for services
    wait_for_services

    echo ""

    # Show summary
    show_summary

    # Follow logs if requested
    if [ "$FOLLOW_LOGS" = true ]; then
        echo ""
        follow_logs
    fi
}

# Run main function
main "$@"
