#!/bin/bash

################################################################################
# dev-reset.sh - Complete Development Environment Reset
#
# Purpose: Nuclear option - completely reset development environment
# Usage: ./dev-reset.sh [OPTIONS]
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
SKIP_CONFIRMATION=false

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
Usage: ./dev-reset.sh [OPTIONS]

Complete reset of the development environment.
WARNING: This will delete ALL data and containers!

OPTIONS:
    --yes, -y           Skip confirmation prompt
    --help, -h          Show this help message

WHAT THIS DOES:
    1. Stop all running containers
    2. Remove all containers
    3. Remove all volumes (DATABASE DATA WILL BE LOST!)
    4. Remove all networks
    5. Clean Docker build cache
    6. Remove dangling images
    7. Optionally start fresh environment

EXAMPLES:
    # Interactive reset (will prompt for confirmation)
    ./dev-reset.sh

    # Reset without confirmation
    ./dev-reset.sh --yes

IMPORTANT:
    - All database data will be lost
    - All uploaded files will be preserved (they're in your local directories)
    - Docker images will be kept (for faster rebuild)
    - This is useful when things are completely broken

SAFER ALTERNATIVES:
    - Just rebuild: ./dev-rebuild.sh
    - Just restart: ./dev-stop.sh && ./dev-start.sh

EOF
}

################################################################################
# Parse Arguments
################################################################################

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --yes|-y)
                SKIP_CONFIRMATION=true
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
# Confirmation
################################################################################

confirm_reset() {
    if [ "$SKIP_CONFIRMATION" = true ]; then
        return 0
    fi

    print_header "⚠️  WARNING: DESTRUCTIVE OPERATION ⚠️"

    echo ""
    echo -e "${RED}This will completely reset your development environment!${NC}"
    echo ""
    echo -e "${YELLOW}What will be DELETED:${NC}"
    echo -e "  ${RED}✗${NC} All Docker containers"
    echo -e "  ${RED}✗${NC} All Docker volumes (DATABASE DATA)"
    echo -e "  ${RED}✗${NC} All Docker networks"
    echo -e "  ${RED}✗${NC} Docker build cache"
    echo ""
    echo -e "${GREEN}What will be PRESERVED:${NC}"
    echo -e "  ${GREEN}✓${NC} Your source code"
    echo -e "  ${GREEN}✓${NC} Docker images (can rebuild quickly)"
    echo -e "  ${GREEN}✓${NC} Local files (uploads, logs, etc.)"
    echo ""
    echo -e "${BLUE}After reset, you can start fresh with:${NC}"
    echo -e "  ${YELLOW}./scripts/dev-start.sh${NC}"
    echo ""

    read -p "Are you absolutely sure? Type 'yes' to continue: " confirmation

    if [ "$confirmation" != "yes" ]; then
        log_info "Reset cancelled"
        exit 0
    fi

    echo ""
    log_warning "Last chance! Waiting 5 seconds before proceeding..."
    log_info "Press Ctrl+C to cancel"
    sleep 5
}

################################################################################
# Reset Functions
################################################################################

check_docker_running() {
    log_info "Checking Docker status..."

    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi

    log_success "Docker is running"
}

stop_containers() {
    print_header "Stopping Containers"

    cd "$PROJECT_ROOT"

    log_info "Stopping all development containers..."

    # Use docker compose (v2) or docker-compose (v1)
    if docker compose version &> /dev/null; then
        docker compose -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true
    else
        docker-compose -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true
    fi

    log_success "Containers stopped"
}

remove_volumes() {
    print_header "Removing Volumes"

    cd "$PROJECT_ROOT"

    log_warning "Removing all data volumes..."

    # Use docker compose (v2) or docker-compose (v1)
    if docker compose version &> /dev/null; then
        docker compose -f "$COMPOSE_FILE" down -v --remove-orphans
    else
        docker-compose -f "$COMPOSE_FILE" down -v --remove-orphans
    fi

    log_success "Volumes removed"
}

clean_docker_cache() {
    print_header "Cleaning Docker Cache"

    log_info "Pruning build cache..."
    docker builder prune -f &> /dev/null || true

    log_info "Removing dangling images..."
    docker image prune -f &> /dev/null || true

    log_success "Docker cache cleaned"
}

clean_local_caches() {
    print_header "Cleaning Local Caches"

    # Clean backend __pycache__
    if [ -d "${PROJECT_ROOT}/production-backend/app/__pycache__" ]; then
        log_info "Removing Python cache files..."
        find "${PROJECT_ROOT}/production-backend" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
        find "${PROJECT_ROOT}/production-backend" -type f -name "*.pyc" -delete 2>/dev/null || true
    fi

    # Clean frontend .next
    if [ -d "${PROJECT_ROOT}/production-frontend/.next" ]; then
        log_info "Removing Next.js cache..."
        rm -rf "${PROJECT_ROOT}/production-frontend/.next" 2>/dev/null || true
    fi

    log_success "Local caches cleaned"
}

verify_cleanup() {
    print_header "Verifying Cleanup"

    cd "$PROJECT_ROOT"

    local compose_cmd
    if docker compose version &> /dev/null; then
        compose_cmd="docker compose -f $COMPOSE_FILE"
    else
        compose_cmd="docker-compose -f $COMPOSE_FILE"
    fi

    # Check for running containers
    local running_containers=$($compose_cmd ps -q 2>/dev/null | wc -l | tr -d ' ')

    if [ "$running_containers" -eq 0 ]; then
        log_success "No containers running"
    else
        log_warning "$running_containers containers still running"
    fi

    # Check for volumes
    local volumes=$(docker volume ls --filter "name=engarde" -q 2>/dev/null | wc -l | tr -d ' ')

    if [ "$volumes" -eq 0 ]; then
        log_success "No volumes remaining"
    else
        log_warning "$volumes volumes still exist"
    fi
}

offer_fresh_start() {
    print_header "Reset Complete"

    echo ""
    echo -e "${GREEN}✓ Development environment has been reset!${NC}"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo ""
    echo -e "1. Start fresh environment:"
    echo -e "   ${YELLOW}./scripts/dev-start.sh${NC}"
    echo ""
    echo -e "2. Or build and start:"
    echo -e "   ${YELLOW}./scripts/dev-rebuild.sh${NC}"
    echo ""

    if [ "$SKIP_CONFIRMATION" = false ]; then
        read -p "Would you like to start the environment now? (y/n): " start_now

        if [[ "$start_now" =~ ^[Yy]$ ]]; then
            echo ""
            log_info "Starting development environment..."
            exec "${PROJECT_ROOT}/scripts/dev-start.sh"
        fi
    fi
}

################################################################################
# Main Execution
################################################################################

main() {
    parse_args "$@"

    print_header "EnGarde Development Environment - Complete Reset"

    echo ""

    # Confirm destructive operation
    confirm_reset

    echo ""

    # Pre-flight checks
    check_docker_running

    echo ""

    # Stop containers
    stop_containers

    echo ""

    # Remove volumes
    remove_volumes

    echo ""

    # Clean caches
    clean_docker_cache

    echo ""

    # Clean local caches
    clean_local_caches

    echo ""

    # Verify cleanup
    verify_cleanup

    echo ""

    # Show next steps
    offer_fresh_start
}

# Run main function
main "$@"
