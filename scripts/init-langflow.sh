#!/bin/bash
# ============================================================================
# Initialize Langflow Database
# ============================================================================
# Purpose: Initialize Langflow schema and run migrations
# Author: EnGarde DevOps Team
# Usage: ./scripts/init-langflow.sh
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

# ============================================================================
# Load Environment
# ============================================================================

print_header "Loading Environment Configuration"

if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    print_success "Environment loaded from .env"
else
    print_warning "No .env file found, using defaults"
fi

# Set defaults
DATABASE_URL=${DATABASE_URL:-postgresql://engarde_user:engarde_password@localhost:5432/engarde}
LANGFLOW_DB_USER=${LANGFLOW_DB_USER:-langflow_user}
LANGFLOW_DB_PASSWORD=${LANGFLOW_DB_PASSWORD:-langflow_password}

print_info "Database: $DATABASE_URL"

# ============================================================================
# Check PostgreSQL Connection
# ============================================================================

print_header "Checking PostgreSQL Connection"

if ! command -v psql &> /dev/null; then
    print_error "psql not found. Please install PostgreSQL client."
    exit 1
fi

# Extract connection details
DB_HOST=$(echo "$DATABASE_URL" | sed -e 's,.*://.*@\([^:/]*\).*,\1,')
DB_PORT=$(echo "$DATABASE_URL" | sed -e 's,.*://.*:\([0-9]*\)/.*,\1,')
DB_NAME=$(echo "$DATABASE_URL" | sed -e 's,.*://[^/]*/\([^?]*\).*,\1,')
DB_USER=$(echo "$DATABASE_URL" | sed -e 's,.*://\([^:]*\):.*,\1,')

print_info "Connecting to: $DB_HOST:$DB_PORT/$DB_NAME"

if psql "$DATABASE_URL" -c "SELECT 1" &> /dev/null; then
    print_success "Database connection successful"
else
    print_error "Cannot connect to database"
    print_info "Is PostgreSQL running? Try: docker-compose up -d postgres"
    exit 1
fi

# ============================================================================
# Initialize Schemas
# ============================================================================

print_header "Initializing Database Schemas"

# Check if schema initialization is needed
SCHEMA_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM pg_namespace WHERE nspname = 'langflow';" | tr -d ' ')

if [ "$SCHEMA_EXISTS" = "0" ]; then
    print_warning "Langflow schema not found. Running initialization..."

    # Run schema initialization scripts in order
    if [ -f "$PROJECT_ROOT/production-backend/scripts/init_schemas.sql" ]; then
        print_info "Running init_schemas.sql..."
        psql "$DATABASE_URL" -f "$PROJECT_ROOT/production-backend/scripts/init_schemas.sql"
        print_success "Schema initialization complete"
    else
        print_error "Schema initialization script not found"
        exit 1
    fi

    if [ -f "$PROJECT_ROOT/production-backend/scripts/init-langflow-schema.sql" ]; then
        print_info "Running init-langflow-schema.sql..."
        psql "$DATABASE_URL" -f "$PROJECT_ROOT/production-backend/scripts/init-langflow-schema.sql"
        print_success "Langflow schema initialization complete"
    fi
else
    print_success "Langflow schema already exists"
fi

# ============================================================================
# Verify Schema Permissions
# ============================================================================

print_header "Verifying Schema Permissions"

# Check if langflow_user exists
USER_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM pg_roles WHERE rolname = '$LANGFLOW_DB_USER';" | tr -d ' ')

if [ "$USER_EXISTS" = "0" ]; then
    print_error "User '$LANGFLOW_DB_USER' does not exist"
    print_info "Run schema initialization first"
    exit 1
else
    print_success "User '$LANGFLOW_DB_USER' exists"
fi

# Check schema permissions
SCHEMA_PERMS=$(psql "$DATABASE_URL" -t -c "SELECT has_schema_privilege('$LANGFLOW_DB_USER', 'langflow', 'CREATE');" | tr -d ' ')

if [ "$SCHEMA_PERMS" = "t" ]; then
    print_success "User has CREATE permission on langflow schema"
else
    print_error "User does not have CREATE permission on langflow schema"
    exit 1
fi

# ============================================================================
# Display Schema Status
# ============================================================================

print_header "Schema Status"

echo -e "${BLUE}Langflow Schema Tables:${NC}"
psql "$DATABASE_URL" -c "\dt langflow.*" 2>/dev/null || echo "  No tables yet (expected before first Langflow start)"

echo -e "\n${BLUE}Schema Sizes:${NC}"
psql "$DATABASE_URL" -c "
    SELECT
        schemaname,
        COUNT(*) as table_count,
        pg_size_pretty(SUM(pg_total_relation_size(schemaname||'.'||tablename))) as total_size
    FROM pg_tables
    WHERE schemaname IN ('public', 'langflow')
    GROUP BY schemaname;
" 2>/dev/null || true

# ============================================================================
# Run Langflow Migrations (if available)
# ============================================================================

print_header "Langflow Migration Status"

if [ -d "$PROJECT_ROOT/production-backend/alembic_langflow" ]; then
    print_info "Langflow Alembic configuration found"

    cd "$PROJECT_ROOT/production-backend"

    # Check current migration status
    print_info "Current migration version:"
    alembic -c alembic_langflow/alembic.ini current 2>/dev/null || echo "  No migrations applied yet"

    # Option to run migrations
    echo ""
    read -p "Run Langflow migrations now? (y/N) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Running migrations..."
        alembic -c alembic_langflow/alembic.ini upgrade head
        print_success "Migrations complete"
    else
        print_info "Skipping migrations (run manually with: cd production-backend && alembic -c alembic_langflow/alembic.ini upgrade head)"
    fi

    cd "$PROJECT_ROOT"
else
    print_warning "Langflow Alembic configuration not found"
    print_info "Langflow will auto-create tables on first start"
fi

# ============================================================================
# Display Next Steps
# ============================================================================

print_header "Initialization Complete"

echo -e "${GREEN}Langflow database is ready!${NC}\n"
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Start Langflow service:"
echo "     docker-compose up -d langflow"
echo ""
echo "  2. Check Langflow logs:"
echo "     docker-compose logs -f langflow"
echo ""
echo "  3. Access Langflow UI:"
echo "     http://localhost:7860"
echo ""
echo "  4. Validate setup:"
echo "     ./scripts/validate-langflow.sh"
echo ""

print_success "All initialization steps completed successfully!"
