#!/bin/bash

################################################################################
# dev-stop.sh - Stop EnGarde Development Environment
#
# Purpose: Stop development environment cleanly with optional cleanup
# Usage: ./dev-stop.sh [OPTIONS]
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
CLEAN=false

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
Usage: ./dev-stop.sh [OPTIONS]

Stop the EnGarde development environment.

OPTIONS:
    --clean, -c         Remove volumes and networks (WARNING: deletes data)
    --help, -h          Show this help message

EXAMPLES:
    # Stop services (preserve volumes)
    ./dev-stop.sh

    # Stop and clean everything
    ./dev-stop.sh --clean

NOTES:
    - By default, volumes are preserved to keep your database data
    - Use --clean to completely reset the environment
    - Containers will be removed, but images will be kept for faster restart

EOF
}

################################################################################
# Parse Arguments
################################################################################

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean|-c)
                CLEAN=true
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
# Service Management
################################################################################

check_docker_running() {
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Nothing to stop."
        exit 1
    fi
}

stop_services() {
    print_header "Stopping Development Services"

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

clean_volumes() {
    print_header "Cleaning Volumes and Networks"

    log_warning "This will delete all development data!"
    log_info "Press Ctrl+C within 5 seconds to cancel..."
    sleep 5

    cd "$PROJECT_ROOT"

    log_info "Removing containers, volumes, and networks..."

    # Use docker compose (v2) or docker-compose (v1)
    if docker compose version &> /dev/null; then
        docker compose -f "$COMPOSE_FILE" down -v --remove-orphans
    else
        docker-compose -f "$COMPOSE_FILE" down -v --remove-orphans
    fi

    log_success "Volumes and networks removed"
}

show_status() {
    print_header "Container Status"

    cd "$PROJECT_ROOT"

    log_info "Checking for remaining containers..."

    # Use docker compose (v2) or docker-compose (v1)
    if docker compose version &> /dev/null; then
        if docker compose -f "$COMPOSE_FILE" ps 2>/dev/null | grep -q "Up"; then
            log_warning "Some containers are still running:"
            docker compose -f "$COMPOSE_FILE" ps
        else
            log_success "All containers are stopped"
        fi
    else
        if docker-compose -f "$COMPOSE_FILE" ps 2>/dev/null | grep -q "Up"; then
            log_warning "Some containers are still running:"
            docker-compose -f "$COMPOSE_FILE" ps
        else
            log_success "All containers are stopped"
        fi
    fi
}

show_cleanup_info() {
    echo ""
    if [ "$CLEAN" = true ]; then
        log_info "To restart with fresh data:"
        echo -e "  ${YELLOW}./scripts/dev-start.sh${NC}"
    else
        log_info "Your data volumes have been preserved."
        log_info "To start again:"
        echo -e "  ${YELLOW}./scripts/dev-start.sh${NC}"
        echo ""
        log_info "To completely reset (delete volumes):"
        echo -e "  ${YELLOW}./scripts/dev-reset.sh${NC}"
    fi
}

################################################################################
# Main Execution
################################################################################

main() {
    parse_args "$@"

    if [ "$CLEAN" = true ]; then
        print_header "EnGarde Development Environment - Clean Stop"
    else
        print_header "EnGarde Development Environment - Stop"
    fi

    # Check Docker
    check_docker_running

    echo ""

    # Stop services
    if [ "$CLEAN" = true ]; then
        clean_volumes
    else
        stop_services
    fi

    echo ""

    # Show status
    show_status

    echo ""

    # Show next steps
    show_cleanup_info

    echo ""
    log_success "Done!"
}

# Run main function
main "$@"
