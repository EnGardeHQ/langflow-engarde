#!/bin/bash

################################################################################
# check-seed-status.sh - Check Database Seed Status
#
# Purpose: Verify if database seeding is needed by checking seed versions
# Usage: ./check-seed-status.sh [OPTIONS]
# Exit Codes:
#   0 - Seed is current (no action needed)
#   1 - Seed is missing or outdated (action needed)
#   2 - Error (cannot determine status)
################################################################################

set -e

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
readonly PROJECT_ROOT="/Users/cope/EnGardeHQ"
readonly COMPOSE_FILE="${PROJECT_ROOT}/docker-compose.dev.yml"
readonly EXPECTED_VERSION="1.1.0"
readonly EXPECTED_SEED_TYPE="demo_data"

# Flags
VERBOSE=false
QUIET=false

################################################################################
# Helper Functions
################################################################################

print_header() {
    if [ "$QUIET" = false ]; then
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}  $1${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
}

log_info() {
    if [ "$QUIET" = false ]; then
        echo -e "${BLUE}ℹ${NC} $1"
    fi
}

log_success() {
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}✓${NC} $1"
    fi
}

log_warning() {
    if [ "$QUIET" = false ]; then
        echo -e "${YELLOW}⚠${NC} $1"
    fi
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

log_verbose() {
    if [ "$VERBOSE" = true ] && [ "$QUIET" = false ]; then
        echo -e "${BLUE}  →${NC} $1"
    fi
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Check database seed status and determine if seeding is needed.

OPTIONS:
    -v, --verbose       Enable verbose output
    -q, --quiet         Suppress all output (except errors)
    -h, --help          Show this help message

EXIT CODES:
    0    Seed is current (no action needed)
    1    Seed is missing or outdated (seeding needed)
    2    Error occurred (cannot determine status)

EXAMPLES:
    # Check seed status with output
    $0

    # Check seed status quietly (for scripts)
    $0 --quiet

    # Check seed status with verbose details
    $0 --verbose

EOF
    exit 0
}

################################################################################
# Status Check Functions
################################################################################

check_docker_running() {
    log_verbose "Checking if Docker is running..."

    if ! docker info &> /dev/null; then
        log_error "Docker is not running"
        return 2
    fi

    log_verbose "Docker is running"
    return 0
}

check_postgres_container() {
    log_verbose "Checking if PostgreSQL container is running..."

    local container_status
    if docker compose version &> /dev/null; then
        container_status=$(docker compose -f "$COMPOSE_FILE" ps postgres --format json 2>/dev/null | grep -o '"State":"[^"]*"' | cut -d'"' -f4 || echo "")
    else
        container_status=$(docker-compose -f "$COMPOSE_FILE" ps postgres 2>/dev/null | grep -c "Up" || echo "0")
    fi

    if [ -z "$container_status" ] || [ "$container_status" = "0" ]; then
        log_error "PostgreSQL container is not running"
        return 2
    fi

    log_verbose "PostgreSQL container is running"
    return 0
}

check_postgres_ready() {
    log_verbose "Waiting for PostgreSQL to be ready..."

    local max_attempts=10
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if docker compose -f "$COMPOSE_FILE" exec -T postgres pg_isready -U engarde_user &> /dev/null; then
            log_verbose "PostgreSQL is ready"
            return 0
        fi

        log_verbose "PostgreSQL not ready yet (attempt $attempt/$max_attempts)..."
        sleep 2
        ((attempt++))
    done

    log_error "PostgreSQL did not become ready in time"
    return 2
}

check_seed_versions_table() {
    log_verbose "Checking if database_seed_versions table exists..."

    local table_exists
    table_exists=$(docker compose -f "$COMPOSE_FILE" exec -T postgres \
        psql -U engarde_user -d engarde -tAc \
        "SELECT EXISTS (
            SELECT FROM information_schema.tables
            WHERE table_schema = 'public'
            AND table_name = 'database_seed_versions'
        );" 2>/dev/null || echo "f")

    if [ "$table_exists" != "t" ]; then
        log_warning "database_seed_versions table does not exist"
        return 1
    fi

    log_verbose "database_seed_versions table exists"
    return 0
}

get_current_seed_version() {
    log_verbose "Checking current seed version..."

    local current_version
    current_version=$(docker compose -f "$COMPOSE_FILE" exec -T postgres \
        psql -U engarde_user -d engarde -tAc \
        "SELECT version FROM database_seed_versions
         WHERE seed_type = '$EXPECTED_SEED_TYPE'
         ORDER BY seeded_at DESC LIMIT 1;" 2>/dev/null || echo "")

    echo "$current_version"
}

get_seed_metadata() {
    log_verbose "Retrieving seed metadata..."

    docker compose -f "$COMPOSE_FILE" exec -T postgres \
        psql -U engarde_user -d engarde -tAc \
        "SELECT
            version,
            seed_type,
            description,
            seeded_at,
            seeded_by,
            metadata->>'brands' as brands,
            metadata->>'users' as users
         FROM database_seed_versions
         WHERE seed_type = '$EXPECTED_SEED_TYPE'
         ORDER BY seeded_at DESC LIMIT 1;" 2>/dev/null || echo ""
}

################################################################################
# Main Status Determination
################################################################################

determine_seed_status() {
    print_header "Database Seed Status Check"

    # Check Docker
    if ! check_docker_running; then
        log_error "Cannot check seed status - Docker is not running"
        return 2
    fi

    # Check PostgreSQL container
    if ! check_postgres_container; then
        log_error "Cannot check seed status - PostgreSQL container not running"
        return 2
    fi

    # Check PostgreSQL readiness
    if ! check_postgres_ready; then
        log_error "Cannot check seed status - PostgreSQL not ready"
        return 2
    fi

    # Check if seed versions table exists
    if ! check_seed_versions_table; then
        log_warning "Seed versions table missing - database needs initialization"
        if [ "$QUIET" = false ]; then
            echo ""
            echo -e "${YELLOW}Status: MISSING${NC}"
            echo -e "${YELLOW}Action Required: Initialize seed versions table and seed database${NC}"
        fi
        return 1
    fi

    # Get current seed version
    local current_version
    current_version=$(get_current_seed_version)

    if [ -z "$current_version" ]; then
        log_warning "No seed version found for type: $EXPECTED_SEED_TYPE"
        if [ "$QUIET" = false ]; then
            echo ""
            echo -e "${YELLOW}Status: MISSING${NC}"
            echo -e "${YELLOW}Action Required: Seed database with version $EXPECTED_VERSION${NC}"
        fi
        return 1
    fi

    # Compare versions
    if [ "$current_version" != "$EXPECTED_VERSION" ]; then
        log_warning "Seed version mismatch"
        if [ "$QUIET" = false ]; then
            echo ""
            echo -e "${YELLOW}Status: OUTDATED${NC}"
            echo -e "  Current Version:  ${YELLOW}$current_version${NC}"
            echo -e "  Expected Version: ${GREEN}$EXPECTED_VERSION${NC}"
            echo -e "${YELLOW}Action Required: Update seed data to version $EXPECTED_VERSION${NC}"
        fi
        return 1
    fi

    # Seed is current
    log_success "Seed version is current"

    if [ "$QUIET" = false ]; then
        echo ""
        echo -e "${GREEN}Status: CURRENT${NC}"
        echo -e "  Version: ${GREEN}$EXPECTED_VERSION${NC}"
        echo -e "  Type: $EXPECTED_SEED_TYPE"

        if [ "$VERBOSE" = true ]; then
            echo ""
            echo -e "${BLUE}Seed Details:${NC}"
            local metadata
            metadata=$(get_seed_metadata)
            if [ -n "$metadata" ]; then
                echo "$metadata" | while IFS='|' read -r version type desc seeded_at seeded_by brands users; do
                    echo -e "  Version:     $version"
                    echo -e "  Type:        $type"
                    echo -e "  Description: $desc"
                    echo -e "  Seeded At:   $seeded_at"
                    echo -e "  Seeded By:   $seeded_by"
                    echo -e "  Brands:      $brands"
                    echo -e "  Users:       $users"
                done
            fi
        fi

        echo ""
        echo -e "${GREEN}✓ No seeding action required${NC}"
    fi

    return 0
}

################################################################################
# Parse Arguments
################################################################################

while [ $# -gt 0 ]; do
    case "$1" in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

################################################################################
# Main Execution
################################################################################

determine_seed_status
exit $?
