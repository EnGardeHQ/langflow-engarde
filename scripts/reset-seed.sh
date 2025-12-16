#!/bin/bash

################################################################################
# reset-seed.sh - Reset Database Seed Version
#
# Purpose: Clear seed version tracking to allow re-seeding
# Usage: ./reset-seed.sh [OPTIONS]
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
readonly NC='\033[0m' # No Color

# Configuration
readonly PROJECT_ROOT="/Users/cope/EnGardeHQ"

# Flags
AUTO_YES=false
VERSION="1.0.0"
SEED_TYPE="demo_data"

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
    echo -e "${RED}✗${NC} $1" >&2
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Reset database seed version tracking to allow re-seeding.

OPTIONS:
    -y, --yes           Skip confirmation prompt
    -v, --version VER   Reset specific version (default: 1.0.0)
    -t, --type TYPE     Reset specific seed type (default: demo_data)
    --all               Reset all seed versions
    -h, --help          Show this help message

EXIT CODES:
    0    Success
    2    Error

EXAMPLES:
    # Reset default seed version (with confirmation)
    $0

    # Reset without confirmation
    $0 --yes

    # Reset specific version
    $0 --version 1.0.0 --type demo_data

    # Reset all seed versions
    $0 --all --yes

EOF
    exit 0
}

################################################################################
# Reset Functions
################################################################################

confirm_reset() {
    if [ "$AUTO_YES" = true ]; then
        return 0
    fi

    echo ""
    echo -e "${YELLOW}⚠  WARNING: This will clear seed version tracking${NC}"
    echo ""
    echo -e "${BLUE}This will allow:${NC}"
    echo -e "  • Re-running seed scripts"
    echo -e "  • Testing seed idempotency"
    echo -e "  • Forcing fresh seed data"
    echo ""
    echo -e "${YELLOW}Note: This does NOT delete existing data, only version tracking${NC}"
    echo ""
    echo -e "${YELLOW}Are you sure you want to continue? (y/n)${NC}"

    local response
    read -r -p "> " response

    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            log_info "Reset cancelled"
            exit 0
            ;;
    esac
}

get_current_seeds() {
    log_info "Current seed versions:"
    echo ""

    docker compose -f "${PROJECT_ROOT}/docker-compose.dev.yml" exec -T postgres \
        psql -U engarde_user -d engarde -c \
        "SELECT version, seed_type, description, seeded_at
         FROM database_seed_versions
         ORDER BY seeded_at DESC;" 2>/dev/null || {
        log_warning "Could not retrieve seed versions"
    }

    echo ""
}

reset_specific_version() {
    log_info "Resetting seed version: $VERSION ($SEED_TYPE)"

    local result
    result=$(docker compose -f "${PROJECT_ROOT}/docker-compose.dev.yml" exec -T postgres \
        psql -U engarde_user -d engarde -tAc \
        "DELETE FROM database_seed_versions
         WHERE version = '$VERSION' AND seed_type = '$SEED_TYPE'
         RETURNING version;" 2>/dev/null || echo "")

    if [ -n "$result" ]; then
        log_success "Reset seed version: $VERSION ($SEED_TYPE)"
        return 0
    else
        log_warning "Seed version not found or already reset: $VERSION ($SEED_TYPE)"
        return 0
    fi
}

reset_all_versions() {
    log_info "Resetting ALL seed versions..."

    local count
    count=$(docker compose -f "${PROJECT_ROOT}/docker-compose.dev.yml" exec -T postgres \
        psql -U engarde_user -d engarde -tAc \
        "WITH deleted AS (
            DELETE FROM database_seed_versions
            WHERE version != '0.0.0'
            RETURNING version
         )
         SELECT COUNT(*) FROM deleted;" 2>/dev/null || echo "0")

    if [ "$count" -gt 0 ]; then
        log_success "Reset $count seed version(s)"
        return 0
    else
        log_warning "No seed versions to reset"
        return 0
    fi
}

################################################################################
# Main Workflow
################################################################################

main() {
    print_header "Reset Database Seed Versions"

    # Show current seeds
    get_current_seeds

    # Confirm reset
    confirm_reset

    echo ""

    # Perform reset
    if [ "$RESET_ALL" = true ]; then
        if ! reset_all_versions; then
            return 2
        fi
    else
        if ! reset_specific_version; then
            return 2
        fi
    fi

    echo ""
    log_success "Seed version tracking has been reset"
    echo ""
    echo -e "${BLUE}You can now re-seed the database with:${NC}"
    echo -e "  ${GREEN}./scripts/seed-database.sh${NC}"
    echo ""

    return 0
}

################################################################################
# Parse Arguments
################################################################################

RESET_ALL=false

while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -t|--type)
            SEED_TYPE="$2"
            shift 2
            ;;
        --all)
            RESET_ALL=true
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
