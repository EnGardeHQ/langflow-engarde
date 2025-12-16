#!/bin/bash

################################################################################
# prompt-seed-database.sh - Interactive Database Seeding Prompt
#
# Purpose: Interactively prompt user to seed database if needed
# Usage: ./prompt-seed-database.sh [OPTIONS]
# Exit Codes:
#   0 - Success (seeding completed or not needed)
#   1 - User declined seeding
#   2 - Error during seeding
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
readonly SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
readonly BACKEND_SCRIPTS_DIR="${PROJECT_ROOT}/production-backend/scripts"
readonly LOG_FILE="${PROJECT_ROOT}/logs/seed-database.log"

# Flags
AUTO_YES=false
SKIP_CHECK=false

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

Interactively prompt user to seed database if seeding is needed.

OPTIONS:
    -y, --yes           Automatically answer yes to seeding prompt
    --skip-check        Skip status check and go straight to prompt
    -h, --help          Show this help message

EXIT CODES:
    0    Success (seeding completed or not needed)
    1    User declined seeding
    2    Error during seeding

EXAMPLES:
    # Interactive prompt
    $0

    # Auto-yes (non-interactive)
    $0 --yes

    # Force prompt without status check
    $0 --skip-check

EOF
    exit 0
}

################################################################################
# Seeding Functions
################################################################################

check_seed_status() {
    log_info "Checking database seed status..."

    if [ ! -f "${SCRIPTS_DIR}/check-seed-status.sh" ]; then
        log_error "check-seed-status.sh not found"
        return 2
    fi

    # Run status check quietly
    if "${SCRIPTS_DIR}/check-seed-status.sh" --quiet; then
        # Seed is current
        return 0
    else
        # Seed is missing or outdated
        return 1
    fi
}

display_seed_info() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                    DATABASE SEEDING REQUIRED                           ${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Your database needs to be seeded with demo data.${NC}"
    echo ""
    echo -e "${BLUE}This will create:${NC}"
    echo -e "  • 4 demo brands (TechFlow, EcoStyle, GlobalEats, SharedTeam)"
    echo -e "  • 3 demo users with credentials: demo1@engarde.local / demo123"
    echo -e "  • Platform connections for testing"
    echo -e "  • Sample campaign data"
    echo ""
    echo -e "${BLUE}What happens:${NC}"
    echo -e "  1. Create seed versions tracking table (if needed)"
    echo -e "  2. Seed database with version 1.0.0 demo data"
    echo -e "  3. Record seed version to prevent duplicate seeding"
    echo ""
    echo -e "${BLUE}Safe operation:${NC}"
    echo -e "  • Idempotent (safe to run multiple times)"
    echo -e "  • Uses ON CONFLICT to handle existing data"
    echo -e "  • No data loss - only adds missing records"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

prompt_user() {
    local response

    if [ "$AUTO_YES" = true ]; then
        log_info "Auto-yes mode enabled, proceeding with seeding..."
        return 0
    fi

    echo -e "${YELLOW}Do you want to seed the database now? (y/n)${NC}"
    read -r -p "> " response

    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        [nN][oO]|[nN])
            return 1
            ;;
        *)
            log_warning "Invalid response. Please enter 'y' or 'n'."
            prompt_user
            ;;
    esac
}

create_seed_versions_table() {
    log_info "Ensuring seed versions table exists..."

    local create_table_script="${BACKEND_SCRIPTS_DIR}/create_seed_versions_table.sql"

    if [ ! -f "$create_table_script" ]; then
        log_error "create_seed_versions_table.sql not found at: $create_table_script"
        return 2
    fi

    # Execute the SQL script
    if docker compose -f "${PROJECT_ROOT}/docker-compose.dev.yml" exec -T postgres \
        psql -U engarde_user -d engarde -f - < "$create_table_script" >> "$LOG_FILE" 2>&1; then
        log_success "Seed versions table initialized"
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
        log_error "seed_demo_data.sql not found at: $seed_script"
        return 2
    fi

    echo ""
    echo -e "${BLUE}Seeding database...${NC}"

    # Execute the SQL script
    if docker compose -f "${PROJECT_ROOT}/docker-compose.dev.yml" exec -T postgres \
        psql -U engarde_user -d engarde -f - < "$seed_script" 2>&1 | tee -a "$LOG_FILE"; then
        echo ""
        log_success "Database seeded successfully"
        return 0
    else
        echo ""
        log_error "Failed to seed database"
        return 2
    fi
}

display_completion_message() {
    echo ""
    print_header "Database Seeding Complete"
    echo ""
    echo -e "${GREEN}✓ Demo data has been successfully seeded!${NC}"
    echo ""
    echo -e "${BLUE}You can now log in with:${NC}"
    echo -e "  • demo1@engarde.local / demo123 (TechFlow Solutions)"
    echo -e "  • demo2@engarde.local / demo123 (EcoStyle Fashion)"
    echo -e "  • demo3@engarde.local / demo123 (GlobalEats Delivery)"
    echo ""
    echo -e "${BLUE}Access your environment:${NC}"
    echo -e "  • Frontend: ${CYAN}http://localhost:3000${NC}"
    echo -e "  • Backend API: ${CYAN}http://localhost:8000${NC}"
    echo -e "  • API Docs: ${CYAN}http://localhost:8000/docs${NC}"
    echo ""
    echo -e "${GREEN}Happy developing! 🚀${NC}"
    echo ""
}

display_declined_message() {
    echo ""
    log_warning "Database seeding declined"
    echo ""
    echo -e "${YELLOW}⚠  You chose not to seed the database.${NC}"
    echo ""
    echo -e "${BLUE}To seed later, run:${NC}"
    echo -e "  ${CYAN}./scripts/seed-database.sh${NC}"
    echo ""
    echo -e "${YELLOW}Note: The application may not function properly without seed data.${NC}"
    echo ""
}

################################################################################
# Main Workflow
################################################################################

perform_seeding() {
    print_header "Database Seeding Workflow"

    # Create logs directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")"

    # Step 1: Create seed versions table
    if ! create_seed_versions_table; then
        log_error "Failed to initialize seed versions table"
        return 2
    fi

    echo ""

    # Step 2: Run seed script
    if ! run_seed_script; then
        log_error "Failed to seed database"
        return 2
    fi

    # Step 3: Display completion message
    display_completion_message

    return 0
}

main() {
    # Check if we need to seed (unless skip-check is enabled)
    if [ "$SKIP_CHECK" = false ]; then
        if check_seed_status; then
            log_success "Database seed is already current"
            log_info "No seeding action required"
            return 0
        fi
    fi

    # Display information about what will be seeded
    display_seed_info

    # Prompt user
    if prompt_user; then
        # User said yes - perform seeding
        if perform_seeding; then
            return 0
        else
            return 2
        fi
    else
        # User said no
        display_declined_message
        return 1
    fi
}

################################################################################
# Parse Arguments
################################################################################

while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        --skip-check)
            SKIP_CHECK=true
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
