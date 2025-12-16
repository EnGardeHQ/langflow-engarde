#!/bin/bash

################################################################################
# dev-health.sh - Check Health of Development Environment
#
# Purpose: Comprehensive health check of all development services
# Usage: ./dev-health.sh [OPTIONS]
# Author: EnGarde DevOps Team
################################################################################

set -e  # Exit on error

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Project root directory (absolute path)
readonly PROJECT_ROOT="/Users/cope/EnGardeHQ"
readonly COMPOSE_FILE="${PROJECT_ROOT}/docker-compose.dev.yml"

# Track overall health
HEALTH_ISSUES=0

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
    ((HEALTH_ISSUES++))
}

log_error() {
    echo -e "${RED}✗${NC} $1"
    ((HEALTH_ISSUES++))
}

show_help() {
    cat << EOF
Usage: ./dev-health.sh [OPTIONS]

Check the health status of all development services.

OPTIONS:
    --verbose, -v       Show detailed information
    --help, -h          Show this help message

WHAT IT CHECKS:
    1. Container status (running/stopped)
    2. Container health (healthy/unhealthy)
    3. Port mappings
    4. Service endpoints (HTTP health checks)
    5. Database connectivity
    6. Redis connectivity
    7. Recent errors in logs
    8. Resource usage

EXAMPLES:
    # Basic health check
    ./dev-health.sh

    # Detailed health check
    ./dev-health.sh --verbose

EXIT CODES:
    0 - All services healthy
    1 - One or more health issues detected

EOF
}

################################################################################
# Parse Arguments
################################################################################

VERBOSE=false

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
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
# Health Check Functions
################################################################################

check_docker_running() {
    print_header "Docker Status"

    if ! docker info &> /dev/null; then
        log_error "Docker is not running"
        return 1
    fi

    log_success "Docker daemon is running"

    if [ "$VERBOSE" = true ]; then
        local docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
        log_info "Docker version: $docker_version"
    fi
}

check_containers() {
    print_header "Container Status"

    cd "$PROJECT_ROOT"

    local compose_cmd
    if docker compose version &> /dev/null; then
        compose_cmd="docker compose -f $COMPOSE_FILE"
    else
        compose_cmd="docker-compose -f $COMPOSE_FILE"
    fi

    # Get list of services
    local services=("postgres" "redis" "backend" "frontend")

    for service in "${services[@]}"; do
        local container_state=$($compose_cmd ps "$service" 2>/dev/null | grep -c "Up" || echo "0")

        if [ "$container_state" -gt 0 ]; then
            log_success "$service container is running"

            # Check health status if available
            local health_status=$($compose_cmd ps --format json "$service" 2>/dev/null | grep -o '"Health":"[^"]*"' | cut -d'"' -f4 || echo "no-healthcheck")

            if [ "$health_status" = "healthy" ]; then
                log_success "  └─ Health check: ${GREEN}healthy${NC}"
            elif [ "$health_status" = "starting" ]; then
                log_warning "  └─ Health check: ${YELLOW}starting${NC}"
            elif [ "$health_status" = "unhealthy" ]; then
                log_error "  └─ Health check: ${RED}unhealthy${NC}"
            fi
        else
            log_error "$service container is not running"
        fi
    done
}

check_port_mappings() {
    print_header "Port Mappings"

    # Check each service individually (compatible with older bash)
    local services=("postgres:5432" "redis:6379" "backend:8000" "frontend:3000")

    for svc_port in "${services[@]}"; do
        local service="${svc_port%:*}"
        local port="${svc_port#*:}"
        local container_name="engarde_${service}_dev"

        if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
            local port_mapping=$(docker port "$container_name" "$port" 2>/dev/null || echo "")

            if [ -n "$port_mapping" ]; then
                log_success "$service: $port_mapping"
            else
                log_warning "$service: Port $port not mapped"
            fi
        fi
    done
}

check_postgres() {
    print_header "PostgreSQL Health"

    # Check if postgres container is running
    if ! docker ps --format '{{.Names}}' | grep -q "engarde_postgres_dev"; then
        log_error "PostgreSQL container not running"
        return 1
    fi

    # Check if postgres is accepting connections
    if command -v pg_isready &> /dev/null; then
        if pg_isready -h localhost -p 5432 -U engarde_user &> /dev/null; then
            log_success "PostgreSQL is accepting connections"
        else
            log_error "PostgreSQL is not accepting connections"
        fi
    else
        # Try with docker exec
        if docker exec engarde_postgres_dev pg_isready -U engarde_user &> /dev/null; then
            log_success "PostgreSQL is accepting connections"
        else
            log_error "PostgreSQL is not accepting connections"
        fi
    fi

    # Check database exists
    if docker exec engarde_postgres_dev psql -U engarde_user -d engarde -c "SELECT 1" &> /dev/null; then
        log_success "Database 'engarde' is accessible"

        if [ "$VERBOSE" = true ]; then
            # Count tables
            local table_count=$(docker exec engarde_postgres_dev psql -U engarde_user -d engarde -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'" 2>/dev/null | tr -d ' ')
            log_info "  └─ Tables in public schema: $table_count"
        fi
    else
        log_error "Cannot access database 'engarde'"
    fi
}

check_redis() {
    print_header "Redis Health"

    # Check if redis container is running
    if ! docker ps --format '{{.Names}}' | grep -q "engarde_redis_dev"; then
        log_error "Redis container not running"
        return 1
    fi

    # Check if redis is responding
    if command -v redis-cli &> /dev/null; then
        if redis-cli -h localhost -p 6379 ping &> /dev/null; then
            log_success "Redis is responding to PING"
        else
            log_error "Redis is not responding to PING"
        fi
    else
        # Try with docker exec
        if docker exec engarde_redis_dev redis-cli ping &> /dev/null; then
            log_success "Redis is responding to PING"
        else
            log_error "Redis is not responding to PING"
        fi
    fi

    if [ "$VERBOSE" = true ]; then
        # Get Redis info
        local redis_version=$(docker exec engarde_redis_dev redis-cli INFO server 2>/dev/null | grep "redis_version:" | cut -d: -f2 | tr -d '\r')
        log_info "  └─ Redis version: $redis_version"
    fi
}

check_backend_api() {
    print_header "Backend API Health"

    # Check if backend container is running
    if ! docker ps --format '{{.Names}}' | grep -q "engarde_backend_dev"; then
        log_error "Backend container not running"
        return 1
    fi

    # Check health endpoint
    if curl -sf http://localhost:8000/health &> /dev/null; then
        log_success "Backend API /health endpoint is responding"

        if [ "$VERBOSE" = true ]; then
            local health_response=$(curl -s http://localhost:8000/health)
            log_info "  └─ Response: $health_response"
        fi
    else
        log_error "Backend API /health endpoint is not responding"
    fi

    # Check API docs
    if curl -sf http://localhost:8000/docs &> /dev/null; then
        log_success "Backend API docs are accessible"
    else
        log_warning "Backend API docs are not accessible"
    fi

    # Check database connection from backend
    if curl -sf http://localhost:8000/health 2>/dev/null | grep -q "healthy\|ok"; then
        log_success "Backend can connect to database"
    fi
}

check_frontend() {
    print_header "Frontend Health"

    # Check if frontend container is running
    if ! docker ps --format '{{.Names}}' | grep -q "engarde_frontend_dev"; then
        log_error "Frontend container not running"
        return 1
    fi

    # Check if frontend is responding
    if curl -sf http://localhost:3000 &> /dev/null; then
        log_success "Frontend is responding on http://localhost:3000"
    else
        log_warning "Frontend is not responding (may still be building)"
    fi

    if [ "$VERBOSE" = true ]; then
        # Check if Next.js is running
        local next_status=$(docker exec engarde_frontend_dev ps aux 2>/dev/null | grep -c "next" || echo "0")
        if [ "$next_status" -gt 0 ]; then
            log_info "  └─ Next.js process is running"
        fi
    fi
}

check_logs_for_errors() {
    print_header "Recent Errors in Logs"

    cd "$PROJECT_ROOT"

    local compose_cmd
    if docker compose version &> /dev/null; then
        compose_cmd="docker compose -f $COMPOSE_FILE"
    else
        compose_cmd="docker-compose -f $COMPOSE_FILE"
    fi

    local services=("backend" "frontend")

    for service in "${services[@]}"; do
        local error_count=$($compose_cmd logs --tail=100 "$service" 2>&1 | grep -ciE "error|ERROR|exception|Exception|failed|FAILED" || echo "0")

        if [ "$error_count" -eq 0 ]; then
            log_success "$service: No errors in last 100 lines"
        elif [ "$error_count" -lt 5 ]; then
            log_warning "$service: $error_count potential errors found"
        else
            log_error "$service: $error_count potential errors found"
        fi

        if [ "$VERBOSE" = true ] && [ "$error_count" -gt 0 ]; then
            echo -e "${CYAN}    Recent errors:${NC}"
            $compose_cmd logs --tail=20 "$service" 2>&1 | grep -iE "error|exception|failed" | head -3 | sed 's/^/    /'
        fi
    done
}

check_resource_usage() {
    if [ "$VERBOSE" = false ]; then
        return
    fi

    print_header "Resource Usage"

    # Docker stats (one-shot)
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" \
        engarde_backend_dev engarde_frontend_dev engarde_postgres_dev engarde_redis_dev 2>/dev/null || \
        log_warning "Unable to fetch resource stats"
}

show_summary() {
    print_header "Health Check Summary"

    echo ""

    if [ $HEALTH_ISSUES -eq 0 ]; then
        echo -e "${GREEN}✓ All services are healthy! 🎉${NC}"
        echo ""
        echo -e "${BLUE}Service URLs:${NC}"
        echo -e "  Frontend:     ${GREEN}http://localhost:3000${NC}"
        echo -e "  Backend API:  ${GREEN}http://localhost:8000${NC}"
        echo -e "  API Docs:     ${GREEN}http://localhost:8000/docs${NC}"
    else
        echo -e "${RED}✗ Found $HEALTH_ISSUES health issue(s)${NC}"
        echo ""
        echo -e "${YELLOW}Troubleshooting:${NC}"
        echo -e "  View logs:      ${CYAN}./scripts/dev-logs.sh${NC}"
        echo -e "  Restart:        ${CYAN}./scripts/dev-stop.sh && ./scripts/dev-start.sh${NC}"
        echo -e "  Rebuild:        ${CYAN}./scripts/dev-rebuild.sh${NC}"
        echo -e "  Complete reset: ${CYAN}./scripts/dev-reset.sh${NC}"
    fi

    echo ""
}

################################################################################
# Main Execution
################################################################################

main() {
    parse_args "$@"

    print_header "EnGarde Development Environment - Health Check"

    echo ""

    # Run all checks
    check_docker_running
    echo ""

    check_containers
    echo ""

    check_port_mappings
    echo ""

    check_postgres
    echo ""

    check_redis
    echo ""

    check_backend_api
    echo ""

    check_frontend
    echo ""

    check_logs_for_errors
    echo ""

    check_resource_usage
    echo ""

    # Show summary
    show_summary

    # Exit with appropriate code
    if [ $HEALTH_ISSUES -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
