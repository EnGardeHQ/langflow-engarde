#!/bin/bash
# ============================================================================
# Cleanup Langflow Installation
# ============================================================================
# Purpose: Complete cleanup and reset of Langflow service and data
# Author: EnGarde DevOps Team
# Usage: ./scripts/cleanup-langflow.sh [--full] [--keep-data]
# WARNING: This will delete Langflow data! Use with caution.
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Parse arguments
FULL_CLEANUP=false
KEEP_DATA=false
SKIP_CONFIRMATION=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --full|-f)
            FULL_CLEANUP=true
            shift
            ;;
        --keep-data|-k)
            KEEP_DATA=true
            shift
            ;;
        --yes|-y)
            SKIP_CONFIRMATION=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --full, -f       Full cleanup including database schema and tables"
            echo "  --keep-data, -k  Keep data volumes (logs and data)"
            echo "  --yes, -y        Skip confirmation prompts"
            echo "  --help, -h       Show this help message"
            echo ""
            echo "Cleanup levels:"
            echo "  Default:         Stop container, remove image"
            echo "  --full:          Also drop schema and tables from database"
            echo "  --keep-data:     Preserve data volumes"
            echo ""
            echo "Examples:"
            echo "  $0                      # Basic cleanup"
            echo "  $0 --full               # Complete reset including database"
            echo "  $0 --keep-data          # Remove container but keep data"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Change to project root
cd "$PROJECT_ROOT"

# ============================================================================
# Functions
# ============================================================================

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

confirm() {
    if [ "$SKIP_CONFIRMATION" = true ]; then
        return 0
    fi

    echo -e "${YELLOW}$1${NC}"
    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
}

# ============================================================================
# Load Environment
# ============================================================================

if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

DATABASE_URL=${DATABASE_URL:-postgresql://engarde_user:engarde_password@localhost:5432/engarde}

# ============================================================================
# Display Cleanup Plan
# ============================================================================

print_header "Langflow Cleanup Plan"

echo -e "${BLUE}The following actions will be performed:${NC}\n"

echo "1. Stop Langflow container"
echo "2. Remove Langflow container"
echo "3. Remove Langflow Docker image"

if [ "$KEEP_DATA" = false ]; then
    echo "4. Remove Langflow data volumes"
    echo "5. Remove Langflow log files"
fi

if [ "$FULL_CLEANUP" = true ]; then
    echo "6. Drop Langflow schema from database"
    echo "7. Remove langflow_user role from database"
    echo "8. Clean up audit logs"
fi

echo ""
print_warning "This action cannot be undone!"

if [ "$FULL_CLEANUP" = true ]; then
    confirm "WARNING: Full cleanup will DELETE ALL LANGFLOW DATA from the database!"
else
    confirm "Proceed with cleanup?"
fi

# ============================================================================
# Stop and Remove Container
# ============================================================================

print_header "Removing Langflow Container"

if docker ps -a --format '{{.Names}}' | grep -q '^engarde_langflow$'; then
    print_info "Stopping Langflow container..."
    docker-compose stop langflow 2>/dev/null || true

    print_info "Removing Langflow container..."
    docker-compose rm -f langflow 2>/dev/null || true

    print_success "Container removed"
else
    print_info "No Langflow container found"
fi

# ============================================================================
# Remove Docker Image
# ============================================================================

print_header "Removing Langflow Docker Image"

IMAGE_ID=$(docker images | grep "engarde.*langflow\|production-backend.*langflow" | awk '{print $3}' | head -1)

if [ ! -z "$IMAGE_ID" ]; then
    print_info "Removing image: $IMAGE_ID"
    docker rmi -f "$IMAGE_ID" 2>/dev/null || true
    print_success "Image removed"
else
    print_info "No Langflow image found"
fi

# ============================================================================
# Remove Volumes
# ============================================================================

if [ "$KEEP_DATA" = false ]; then
    print_header "Removing Langflow Volumes"

    if docker volume ls | grep -q "langflow_logs"; then
        print_info "Removing langflow_logs volume..."
        docker volume rm langflow_logs 2>/dev/null || true
        print_success "Logs volume removed"
    fi

    if docker volume ls | grep -q "langflow_data"; then
        print_info "Removing langflow_data volume..."
        docker volume rm langflow_data 2>/dev/null || true
        print_success "Data volume removed"
    fi

    # Clean up any orphaned volumes
    print_info "Cleaning up orphaned volumes..."
    docker volume prune -f &>/dev/null || true
    print_success "Orphaned volumes cleaned"
else
    print_info "Keeping data volumes (--keep-data flag set)"
fi

# ============================================================================
# Database Cleanup (Full Mode)
# ============================================================================

if [ "$FULL_CLEANUP" = true ]; then
    print_header "Database Schema Cleanup"

    if command -v psql &> /dev/null; then
        if psql "$DATABASE_URL" -c "SELECT 1" &> /dev/null; then
            print_warning "This will DROP the Langflow schema and all its tables!"
            confirm "Proceed with database cleanup?"

            # Drop schema cascade (removes all tables)
            print_info "Dropping Langflow schema..."
            psql "$DATABASE_URL" -c "DROP SCHEMA IF EXISTS langflow CASCADE;" &>/dev/null
            print_success "Schema dropped"

            # Remove langflow_user role
            print_info "Removing langflow_user role..."
            psql "$DATABASE_URL" -c "DROP ROLE IF EXISTS langflow_user;" &>/dev/null
            print_success "User role removed"

            # Remove langflow_app role (if exists)
            print_info "Removing langflow_app role..."
            psql "$DATABASE_URL" -c "DROP ROLE IF EXISTS langflow_app;" &>/dev/null
            print_success "App role removed"

            # Clean up audit schema
            print_info "Cleaning audit logs..."
            psql "$DATABASE_URL" -c "DELETE FROM audit.cross_schema_access WHERE source_schema = 'langflow' OR target_schema = 'langflow';" &>/dev/null || true
            print_success "Audit logs cleaned"

            # Clean up version tracking
            print_info "Cleaning version tables..."
            psql "$DATABASE_URL" -c "DROP TABLE IF EXISTS langflow.alembic_version;" &>/dev/null || true
            psql "$DATABASE_URL" -c "DROP TABLE IF EXISTS public.alembic_version_langflow;" &>/dev/null || true
            print_success "Version tables removed"

            print_success "Database cleanup complete"
        else
            print_error "Cannot connect to database. Skipping database cleanup."
        fi
    else
        print_warning "psql not available. Skipping database cleanup."
    fi
fi

# ============================================================================
# Clean Up Local Files
# ============================================================================

print_header "Cleaning Local Files"

# Remove compiled Python files
if [ -d "$PROJECT_ROOT/production-backend/__pycache__" ]; then
    print_info "Removing Python cache files..."
    find "$PROJECT_ROOT/production-backend" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find "$PROJECT_ROOT/production-backend" -type f -name "*.pyc" -delete 2>/dev/null || true
    print_success "Python cache cleaned"
fi

# Remove Alembic cache (if full cleanup)
if [ "$FULL_CLEANUP" = true ]; then
    if [ -d "$PROJECT_ROOT/production-backend/alembic_langflow/versions/__pycache__" ]; then
        print_info "Removing Alembic cache..."
        rm -rf "$PROJECT_ROOT/production-backend/alembic_langflow/versions/__pycache__" 2>/dev/null || true
        print_success "Alembic cache cleaned"
    fi
fi

# ============================================================================
# Verification
# ============================================================================

print_header "Cleanup Verification"

print_info "Verifying cleanup..."

# Check container
if docker ps -a --format '{{.Names}}' | grep -q '^engarde_langflow$'; then
    print_warning "Langflow container still exists"
else
    print_success "Container removed"
fi

# Check image
if docker images | grep -q "engarde.*langflow\|production-backend.*langflow"; then
    print_warning "Langflow image still exists"
else
    print_success "Image removed"
fi

# Check volumes
if [ "$KEEP_DATA" = false ]; then
    if docker volume ls | grep -q "langflow_"; then
        print_warning "Some Langflow volumes still exist"
    else
        print_success "All volumes removed"
    fi
else
    print_info "Data volumes preserved (as requested)"
fi

# Check database
if [ "$FULL_CLEANUP" = true ] && command -v psql &> /dev/null; then
    if psql "$DATABASE_URL" -c "SELECT 1" &> /dev/null; then
        SCHEMA_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM pg_namespace WHERE nspname = 'langflow';" | tr -d ' ')
        if [ "$SCHEMA_EXISTS" = "0" ]; then
            print_success "Database schema removed"
        else
            print_warning "Database schema still exists"
        fi
    fi
fi

# ============================================================================
# Summary
# ============================================================================

print_header "Cleanup Complete"

echo -e "${GREEN}Langflow cleanup completed successfully!${NC}\n"

if [ "$KEEP_DATA" = true ]; then
    echo -e "${BLUE}Data volumes were preserved:${NC}"
    echo "  - langflow_logs"
    echo "  - langflow_data"
    echo ""
fi

echo -e "${BLUE}To reinstall Langflow:${NC}"
echo "  1. Initialize database:  ./scripts/init-langflow.sh"
echo "  2. Start service:        docker-compose up -d langflow"
echo "  3. Validate setup:       ./scripts/validate-langflow.sh"
echo ""

if [ "$FULL_CLEANUP" = true ]; then
    echo -e "${YELLOW}Note: Full database cleanup was performed.${NC}"
    echo -e "${YELLOW}You will need to run schema initialization again.${NC}"
    echo ""
fi

print_success "All cleanup operations completed!"
