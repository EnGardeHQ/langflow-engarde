#!/bin/bash

################################################################################
# seed-status.sh - Show Database Seed Status
#
# Purpose: Display detailed seed version information
# Usage: ./seed-status.sh [OPTIONS]
# Exit Codes:
#   0 - Success
#   2 - Error
################################################################################

set -e

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Configuration
readonly PROJECT_ROOT="/Users/cope/EnGardeHQ"

# Flags
VERBOSE=false

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

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Display detailed seed version information and current status.

OPTIONS:
    -v, --verbose       Show additional details
    -h, --help          Show this help message

EXIT CODES:
    0    Success
    2    Error

EXAMPLES:
    # Show seed status
    $0

    # Show detailed status
    $0 --verbose

EOF
    exit 0
}

################################################################################
# Status Functions
################################################################################

check_table_exists() {
    docker compose -f "${PROJECT_ROOT}/docker-compose.dev.yml" exec -T postgres \
        psql -U engarde_user -d engarde -tAc \
        "SELECT EXISTS (
            SELECT FROM information_schema.tables
            WHERE table_schema = 'public'
            AND table_name = 'database_seed_versions'
        );" 2>/dev/null || echo "f"
}

get_all_seeds() {
    docker compose -f "${PROJECT_ROOT}/docker-compose.dev.yml" exec -T postgres \
        psql -U engarde_user -d engarde -c \
        "SELECT
            version,
            seed_type,
            description,
            seeded_at,
            seeded_by
         FROM database_seed_versions
         ORDER BY seeded_at DESC;" 2>/dev/null
}

get_seed_details() {
    docker compose -f "${PROJECT_ROOT}/docker-compose.dev.yml" exec -T postgres \
        psql -U engarde_user -d engarde -c \
        "SELECT
            version,
            seed_type,
            description,
            seeded_at,
            seeded_by,
            seed_file,
            row_count,
            metadata
         FROM database_seed_versions
         WHERE version = '1.0.0' AND seed_type = 'demo_data';" 2>/dev/null
}

get_demo_data_counts() {
    echo ""
    echo -e "${CYAN}Demo Data Counts:${NC}"

    local users brands tenants connections
    users=$(docker compose -f "${PROJECT_ROOT}/docker-compose.dev.yml" exec -T postgres \
        psql -U engarde_user -d engarde -tAc \
        "SELECT COUNT(*) FROM users WHERE email LIKE 'demo%@engarde.local';" 2>/dev/null || echo "0")

    brands=$(docker compose -f "${PROJECT_ROOT}/docker-compose.dev.yml" exec -T postgres \
        psql -U engarde_user -d engarde -tAc \
        "SELECT COUNT(*) FROM brands WHERE tenant_id LIKE 'tenant-%';" 2>/dev/null || echo "0")

    tenants=$(docker compose -f "${PROJECT_ROOT}/docker-compose.dev.yml" exec -T postgres \
        psql -U engarde_user -d engarde -tAc \
        "SELECT COUNT(*) FROM tenants WHERE id LIKE 'tenant-%';" 2>/dev/null || echo "0")

    connections=$(docker compose -f "${PROJECT_ROOT}/docker-compose.dev.yml" exec -T postgres \
        psql -U engarde_user -d engarde -tAc \
        "SELECT COUNT(*) FROM platform_connections WHERE tenant_id LIKE 'tenant-%';" 2>/dev/null || echo "0")

    echo -e "  Demo Users:              ${GREEN}$users${NC}"
    echo -e "  Brands:                  ${GREEN}$brands${NC}"
    echo -e "  Tenants:                 ${GREEN}$tenants${NC}"
    echo -e "  Platform Connections:    ${GREEN}$connections${NC}"
}

display_seed_status() {
    print_header "Database Seed Status"

    # Check if table exists
    local table_exists
    table_exists=$(check_table_exists)

    if [ "$table_exists" != "t" ]; then
        echo ""
        echo -e "${RED}✗ Seed versions table does not exist${NC}"
        echo ""
        echo -e "${YELLOW}To initialize, run:${NC}"
        echo -e "  ${BLUE}./scripts/seed-database.sh${NC}"
        echo ""
        return 2
    fi

    log_success "Seed versions table exists"
    echo ""

    # Check current seed version
    local current_version
    current_version=$(docker compose -f "${PROJECT_ROOT}/docker-compose.dev.yml" exec -T postgres \
        psql -U engarde_user -d engarde -tAc \
        "SELECT version FROM database_seed_versions
         WHERE seed_type = 'demo_data'
         ORDER BY seeded_at DESC LIMIT 1;" 2>/dev/null || echo "")

    if [ -z "$current_version" ]; then
        echo -e "${YELLOW}⚠  No demo data seed found${NC}"
        echo ""
        echo -e "${BLUE}Current Status:${NC}"
        echo -e "  Version:     ${YELLOW}Not Seeded${NC}"
        echo -e "  Type:        demo_data"
        echo -e "  Expected:    ${GREEN}1.0.0${NC}"
        echo ""
        echo -e "${YELLOW}To seed database, run:${NC}"
        echo -e "  ${BLUE}./scripts/seed-database.sh${NC}"
        echo ""
    else
        if [ "$current_version" = "1.0.0" ]; then
            echo -e "${GREEN}✓ Demo data seed is current${NC}"
        else
            echo -e "${YELLOW}⚠  Demo data seed version mismatch${NC}"
        fi

        echo ""
        echo -e "${BLUE}Current Status:${NC}"
        echo -e "  Version:     ${GREEN}$current_version${NC}"
        echo -e "  Type:        demo_data"
        echo -e "  Expected:    1.0.0"
        echo ""

        if [ "$VERBOSE" = true ]; then
            echo -e "${BLUE}Detailed Information:${NC}"
            get_seed_details
            echo ""
        fi
    fi

    # Show all seed versions
    echo -e "${CYAN}All Seed Versions:${NC}"
    get_all_seeds
    echo ""

    # Show data counts if verbose
    if [ "$VERBOSE" = true ]; then
        get_demo_data_counts
        echo ""
    fi

    # Show management commands
    echo -e "${BLUE}Management Commands:${NC}"
    echo -e "  Check status:    ${CYAN}./scripts/check-seed-status.sh${NC}"
    echo -e "  Seed database:   ${CYAN}./scripts/seed-database.sh${NC}"
    echo -e "  Reset seed:      ${CYAN}./scripts/reset-seed.sh${NC}"
    echo -e "  Interactive:     ${CYAN}./scripts/prompt-seed-database.sh${NC}"
    echo ""

    return 0
}

################################################################################
# Main Workflow
################################################################################

main() {
    display_seed_status
    return $?
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

main
exit $?
