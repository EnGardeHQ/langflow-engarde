#!/bin/bash

################################################################################
# dev-logs.sh - View Development Environment Logs
#
# Purpose: Tail and filter logs for development services
# Usage: ./dev-logs.sh [OPTIONS] [SERVICE]
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
TAIL_LINES="100"
FOLLOW=true
SERVICE=""
FILTER=""
TIMESTAMPS=false

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
Usage: ./dev-logs.sh [OPTIONS] [SERVICE]

View logs from development environment services.

SERVICES:
    frontend            Frontend (Next.js) logs
    backend             Backend (FastAPI) logs
    postgres            PostgreSQL logs
    redis               Redis logs
    (none)              All services

OPTIONS:
    -f, --follow        Follow log output (default: true)
    -n, --tail LINES    Number of lines to show (default: 100)
    -g, --grep PATTERN  Filter logs by pattern
    -t, --timestamps    Show timestamps
    --no-follow         Don't follow logs (just dump and exit)
    -h, --help          Show this help message

EXAMPLES:
    # Follow all logs
    ./dev-logs.sh

    # View last 50 backend logs
    ./dev-logs.sh -n 50 backend

    # Follow frontend logs
    ./dev-logs.sh frontend

    # Filter for errors in all services
    ./dev-logs.sh -g "error\|ERROR\|Error"

    # View backend logs with timestamps
    ./dev-logs.sh -t backend

    # Dump last 200 lines without following
    ./dev-logs.sh --no-follow -n 200

FILTERING TIPS:
    - Use grep patterns for filtering
    - Common patterns:
        Error logs:   -g "error\|ERROR\|Error"
        Warnings:     -g "warn\|WARN\|Warning"
        HTTP 4xx:     -g "\" 4[0-9][0-9]"
        HTTP 5xx:     -g "\" 5[0-9][0-9]"
        Specific API: -g "/api/auth"

EOF
}

################################################################################
# Parse Arguments
################################################################################

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--follow)
                FOLLOW=true
                shift
                ;;
            --no-follow)
                FOLLOW=false
                shift
                ;;
            -n|--tail)
                TAIL_LINES="$2"
                shift 2
                ;;
            -g|--grep)
                FILTER="$2"
                shift 2
                ;;
            -t|--timestamps)
                TIMESTAMPS=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                SERVICE="$1"
                shift
                ;;
        esac
    done
}

################################################################################
# Log Functions
################################################################################

check_docker_running() {
    if ! docker info &> /dev/null; then
        log_error "Docker is not running."
        exit 1
    fi
}

validate_service() {
    if [ -n "$SERVICE" ]; then
        local valid_services=("frontend" "backend" "postgres" "redis")
        local is_valid=false

        for svc in "${valid_services[@]}"; do
            if [ "$SERVICE" = "$svc" ]; then
                is_valid=true
                break
            fi
        done

        if [ "$is_valid" = false ]; then
            log_error "Invalid service: $SERVICE"
            log_info "Valid services: ${valid_services[*]}"
            exit 1
        fi
    fi
}

show_logs() {
    cd "$PROJECT_ROOT"

    # Build docker compose command
    local compose_cmd
    if docker compose version &> /dev/null; then
        compose_cmd="docker compose -f $COMPOSE_FILE"
    else
        compose_cmd="docker-compose -f $COMPOSE_FILE"
    fi

    # Build log command options
    local log_opts="--tail=$TAIL_LINES"

    if [ "$FOLLOW" = true ]; then
        log_opts="$log_opts -f"
    fi

    if [ "$TIMESTAMPS" = true ]; then
        log_opts="$log_opts -t"
    fi

    # Execute logs command
    if [ -n "$FILTER" ]; then
        log_info "Filtering logs for pattern: $FILTER"
        if [ -n "$SERVICE" ]; then
            log_info "Viewing $SERVICE logs"
            $compose_cmd logs $log_opts "$SERVICE" 2>&1 | grep -E "$FILTER" --color=always || true
        else
            log_info "Viewing all service logs"
            $compose_cmd logs $log_opts 2>&1 | grep -E "$FILTER" --color=always || true
        fi
    else
        if [ -n "$SERVICE" ]; then
            log_info "Viewing $SERVICE logs (Press Ctrl+C to stop)"
            $compose_cmd logs $log_opts "$SERVICE"
        else
            log_info "Viewing all service logs (Press Ctrl+C to stop)"
            $compose_cmd logs $log_opts
        fi
    fi
}

show_log_summary() {
    if [ "$FOLLOW" = true ]; then
        return
    fi

    print_header "Log Summary"

    cd "$PROJECT_ROOT"

    local compose_cmd
    if docker compose version &> /dev/null; then
        compose_cmd="docker compose -f $COMPOSE_FILE"
    else
        compose_cmd="docker-compose -f $COMPOSE_FILE"
    fi

    echo ""
    echo -e "${BLUE}Service Status:${NC}"

    # Show running services
    $compose_cmd ps

    echo ""
    echo -e "${BLUE}Recent Errors:${NC}"

    # Quick scan for errors
    local error_count
    if [ -n "$SERVICE" ]; then
        error_count=$($compose_cmd logs --tail=100 "$SERVICE" 2>&1 | grep -ciE "error|ERROR|exception|Exception|failed|FAILED" || echo "0")
    else
        error_count=$($compose_cmd logs --tail=100 2>&1 | grep -ciE "error|ERROR|exception|Exception|failed|FAILED" || echo "0")
    fi

    if [ "$error_count" -gt 0 ]; then
        log_warning "Found $error_count potential errors in last 100 lines"
        log_info "Use './dev-logs.sh -g \"error\|ERROR\"' to view them"
    else
        log_success "No obvious errors in recent logs"
    fi
}

################################################################################
# Main Execution
################################################################################

main() {
    parse_args "$@"

    # Build header based on options
    local header="Development Environment Logs"
    if [ -n "$SERVICE" ]; then
        header="$header - $SERVICE"
    fi

    print_header "$header"

    # Checks
    check_docker_running
    validate_service

    echo ""

    # Show logs
    show_logs

    # Summary (only for non-following mode)
    if [ "$FOLLOW" = false ]; then
        echo ""
        show_log_summary
    fi
}

# Run main function
main "$@"
