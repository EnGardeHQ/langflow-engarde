#!/bin/bash

################################################################################
# seed-database.sh - Manually Seed Database
#
# Purpose: Manually seed the database with demo data (non-interactive)
# Usage: ./seed-database.sh [OPTIONS]
# Exit Codes:
#   0 - Success
#   1 - Seed already exists
#   2 - Error during seeding
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
readonly BACKEND_SCRIPTS_DIR="${PROJECT_ROOT}/production-backend/scripts"
readonly LOG_FILE="${PROJECT_ROOT}/logs/seed-database.log"

# Flags
FORCE=false

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
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$LOG_FILE" 2>&1 || true
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$LOG_FILE" 2>&1 || true
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$LOG_FILE" 2>&1 || true
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE" 2>&1 || true
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Manually seed the database with demo data.

OPTIONS:
    -f, --force         Force seeding even if already seeded (resets version first)
    -h, --help          Show this help message

EXIT CODES:
    0    Success
    1    Seed already exists (use --force to override)
    2    Error during seeding

EXAMPLES:
    # Seed database
    $0

    # Force re-seed
    $0 --force

EOF
    exit 0
}

################################################################################
# Seeding Functions
################################################################################

check_existing_seed() {
    log_info "Checking for existing seed..."

    if docker compose -f "${PROJECT_ROOT}/docker-compose.dev.yml" exec -T postgres \
        psql -U engarde_user -d engarde -tAc \
        "SELECT EXISTS (
            SELECT 1 FROM database_seed_versions
            WHERE version = '1.0.0' AND seed_type = 'demo_data'
        );" 2>/dev/null | grep -q "t"; then
        return 0  # Exists
    else
        return 1  # Does not exist
    fi
}

reset_seed_version() {
    log_info "Resetting seed version..."

    if docker compose -f "${PROJECT_ROOT}/docker-compose.dev.yml" exec -T postgres \
        psql -U engarde_user -d engarde -tAc \
        "DELETE FROM database_seed_versions WHERE version = '1.0.0' AND seed_type = 'demo_data';" \
        >> "$LOG_FILE" 2>&1; then
        log_success "Seed version reset"
        return 0
    else
        log_error "Failed to reset seed version"
        return 2
    fi
}

create_seed_versions_table() {
    log_info "Ensuring seed versions table exists..."

    local create_table_script="${BACKEND_SCRIPTS_DIR}/create_seed_versions_table.sql"

    if [ ! -f "$create_table_script" ]; then
        log_error "create_seed_versions_table.sql not found"
        return 2
    fi

    if docker compose -f "${PROJECT_ROOT}/docker-compose.dev.yml" exec -T postgres \
        psql -U engarde_user -d engarde -f - < "$create_table_script" >> "$LOG_FILE" 2>&1; then
        log_success "Seed versions table ready"
        return 0
    else
        log_error "Failed to create seed versions table"
        return 2
    fi
}

run_seed_script() {
    log_info "Running seed script..."

    local seed_script="${BACKEND_SCRIPTS_DIR}/seed_demo_data.sql"

    if [ ! -f "$seed_script" ]; then
        log_error "seed_demo_data.sql not found"
        return 2
    fi

    if docker compose -f "${PROJECT_ROOT}/docker-compose.dev.yml" exec -T postgres \
        psql -U engarde_user -d engarde -f - < "$seed_script" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Database seeded successfully"
        return 0
    else
        log_error "Failed to seed database"
        return 2
    fi
}

################################################################################
# Main Workflow
################################################################################

main() {
    print_header "Manual Database Seeding"

    # Create logs directory
    mkdir -p "$(dirname "$LOG_FILE")"

    # Check for existing seed (unless force)
    if [ "$FORCE" = false ]; then
        if check_existing_seed; then
            log_warning "Seed version 1.0.0 already exists"
            echo ""
            echo -e "${YELLOW}To force re-seeding, run:${NC}"
            echo -e "  ${BLUE}$0 --force${NC}"
            echo ""
            return 1
        fi
    else
        if check_existing_seed; then
            log_warning "Force mode enabled - resetting existing seed"
            if ! reset_seed_version; then
                return 2
            fi
        fi
    fi

    echo ""

    # Create seed versions table
    if ! create_seed_versions_table; then
        return 2
    fi

    echo ""

    # Run seed script
    if ! run_seed_script; then
        return 2
    fi

    echo ""
    print_header "Seeding Complete"
    echo ""
    log_success "Database has been successfully seeded"
    echo ""
    echo -e "${BLUE}Test credentials:${NC}"
    echo -e "  • demo1@engarde.local / demo123"
    echo -e "  • demo2@engarde.local / demo123"
    echo -e "  • demo3@engarde.local / demo123"
    echo ""

    return 0
}

################################################################################
# Parse Arguments
################################################################################

while [ $# -gt 0 ]; do
    case "$1" in
        -f|--force)
            FORCE=true
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
