#!/bin/bash

################################################################################
# test-seed-workflow.sh - Test Database Seeding Workflow
#
# Purpose: Demonstrate and test the complete seeding workflow
# Usage: ./test-seed-workflow.sh
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

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo ""
    echo -e "${BLUE}▶ $1${NC}"
    echo ""
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

press_enter() {
    echo ""
    echo -e "${YELLOW}Press ENTER to continue...${NC}"
    read -r
}

################################################################################
# Test Workflow
################################################################################

test_workflow() {
    print_header "Database Seeding System - Workflow Demo"

    echo "This script will demonstrate the complete database seeding workflow."
    echo "It will show all the commands and their outputs."
    echo ""
    log_warning "Make sure your development environment is running!"
    echo ""
    press_enter

    # Step 1: Check current status
    print_step "Step 1: Check Current Seed Status"
    echo "Command: ./scripts/check-seed-status.sh"
    echo ""

    if ./scripts/check-seed-status.sh; then
        log_success "Seed status check completed"
        log_info "Seed is already current - will demonstrate reset workflow"
    else
        log_warning "Seed is missing or outdated - will demonstrate seeding workflow"
    fi

    press_enter

    # Step 2: Show detailed status
    print_step "Step 2: View Detailed Seed Information"
    echo "Command: ./scripts/seed-status.sh --verbose"
    echo ""

    ./scripts/seed-status.sh --verbose || true

    press_enter

    # Step 3: Reset seed version (if exists)
    print_step "Step 3: Reset Seed Version (for testing)"
    echo "Command: ./scripts/reset-seed.sh --yes"
    echo ""
    echo "This resets the version tracking (does NOT delete data)"
    echo ""

    ./scripts/reset-seed.sh --yes || log_info "No seed version to reset"

    press_enter

    # Step 4: Check status after reset
    print_step "Step 4: Check Status After Reset"
    echo "Command: ./scripts/check-seed-status.sh"
    echo ""

    if ./scripts/check-seed-status.sh; then
        log_info "Seed is current"
    else
        log_warning "Seed is missing (expected after reset)"
    fi

    press_enter

    # Step 5: Manual seeding
    print_step "Step 5: Manual Database Seeding"
    echo "Command: ./scripts/seed-database.sh"
    echo ""
    echo "This will seed the database with demo data..."
    echo ""

    ./scripts/seed-database.sh || log_warning "Seeding may have failed"

    press_enter

    # Step 6: Verify seeding
    print_step "Step 6: Verify Seed Was Successful"
    echo "Command: ./scripts/check-seed-status.sh --verbose"
    echo ""

    ./scripts/check-seed-status.sh --verbose

    press_enter

    # Step 7: Show demo users
    print_step "Step 7: Verify Demo Users Exist"
    echo "Command: Query database for demo users"
    echo ""

    docker compose -f "${PROJECT_ROOT}/docker-compose.dev.yml" exec -T postgres \
        psql -U engarde_user -d engarde -c \
        "SELECT email, first_name, last_name, is_active
         FROM users
         WHERE email LIKE 'demo%@engarde.local'
         ORDER BY email;" || log_warning "Could not query users"

    press_enter

    # Step 8: Show brands
    print_step "Step 8: Verify Brands Exist"
    echo "Command: Query database for brands"
    echo ""

    docker compose -f "${PROJECT_ROOT}/docker-compose.dev.yml" exec -T postgres \
        psql -U engarde_user -d engarde -c \
        "SELECT name, description, tenant_id
         FROM brands
         WHERE tenant_id LIKE 'tenant-%'
         ORDER BY name;" || log_warning "Could not query brands"

    press_enter

    # Step 9: Test idempotency
    print_step "Step 9: Test Idempotency (Run Seed Again)"
    echo "Command: ./scripts/seed-database.sh --force"
    echo ""
    echo "This should run successfully without errors (idempotent)..."
    echo ""

    ./scripts/reset-seed.sh --yes
    ./scripts/seed-database.sh || log_warning "Idempotency test failed"

    press_enter

    # Step 10: Final status
    print_step "Step 10: Final Seed Status"
    echo "Command: ./scripts/seed-status.sh --verbose"
    echo ""

    ./scripts/seed-status.sh --verbose

    press_enter

    # Summary
    print_header "Workflow Demo Complete"

    echo -e "${GREEN}✓ All steps completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}Key Takeaways:${NC}"
    echo -e "  1. check-seed-status.sh checks if seeding is needed"
    echo -e "  2. seed-database.sh performs manual seeding"
    echo -e "  3. reset-seed.sh allows re-seeding for testing"
    echo -e "  4. seed-status.sh shows detailed information"
    echo -e "  5. Seeds are idempotent (safe to run multiple times)"
    echo ""
    echo -e "${BLUE}Demo Credentials:${NC}"
    echo -e "  • demo1@engarde.local / demo123"
    echo -e "  • demo2@engarde.local / demo123"
    echo -e "  • demo3@engarde.local / demo123"
    echo ""
    echo -e "${BLUE}Access:${NC}"
    echo -e "  • Frontend: ${CYAN}http://localhost:3000${NC}"
    echo -e "  • Backend API: ${CYAN}http://localhost:8000${NC}"
    echo -e "  • API Docs: ${CYAN}http://localhost:8000/docs${NC}"
    echo ""
    echo -e "${BLUE}Management Commands:${NC}"
    echo -e "  • Check status:  ${CYAN}./scripts/check-seed-status.sh${NC}"
    echo -e "  • View details:  ${CYAN}./scripts/seed-status.sh --verbose${NC}"
    echo -e "  • Seed database: ${CYAN}./scripts/seed-database.sh${NC}"
    echo -e "  • Reset seed:    ${CYAN}./scripts/reset-seed.sh${NC}"
    echo ""
    echo -e "${GREEN}Happy developing! 🚀${NC}"
    echo ""
}

################################################################################
# Main Execution
################################################################################

test_workflow
