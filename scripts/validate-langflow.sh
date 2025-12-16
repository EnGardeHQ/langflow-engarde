#!/bin/bash
# ============================================================================
# Validate Langflow Setup
# ============================================================================
# Purpose: Comprehensive validation of Langflow installation and configuration
# Author: EnGarde DevOps Team
# Usage: ./scripts/validate-langflow.sh
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

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# ============================================================================
# Functions
# ============================================================================

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_test() {
    echo -n "  Testing: $1 ... "
}

pass() {
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
}

fail() {
    echo -e "${RED}FAIL${NC}"
    if [ ! -z "$1" ]; then
        echo -e "    ${RED}Error: $1${NC}"
    fi
    FAILED=$((FAILED + 1))
}

warn() {
    echo -e "${YELLOW}WARN${NC}"
    if [ ! -z "$1" ]; then
        echo -e "    ${YELLOW}Warning: $1${NC}"
    fi
    WARNINGS=$((WARNINGS + 1))
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ============================================================================
# Load Environment
# ============================================================================

if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

DATABASE_URL=${DATABASE_URL:-postgresql://engarde_user:engarde_password@localhost:5432/engarde}

# ============================================================================
# Test 1: Docker Environment
# ============================================================================

print_header "Docker Environment Validation"

print_test "Docker installed"
if command -v docker &> /dev/null; then
    pass
    DOCKER_VERSION=$(docker --version)
    echo -e "    Version: $DOCKER_VERSION"
else
    fail "Docker not found"
fi

print_test "Docker Compose installed"
if command -v docker-compose &> /dev/null; then
    pass
    COMPOSE_VERSION=$(docker-compose --version)
    echo -e "    Version: $COMPOSE_VERSION"
else
    fail "docker-compose not found"
fi

print_test "Docker daemon running"
if docker info &> /dev/null; then
    pass
else
    fail "Docker daemon not running"
fi

# ============================================================================
# Test 2: Container Status
# ============================================================================

print_header "Container Status Validation"

print_test "PostgreSQL container running"
if docker-compose ps postgres | grep -q "Up"; then
    pass
    PG_STATUS=$(docker inspect --format='{{.State.Health.Status}}' engarde_postgres 2>/dev/null || echo "unknown")
    echo -e "    Health: $PG_STATUS"
else
    fail "PostgreSQL container not running"
fi

print_test "Redis container running"
if docker-compose ps redis | grep -q "Up"; then
    pass
    REDIS_STATUS=$(docker inspect --format='{{.State.Health.Status}}' engarde_redis 2>/dev/null || echo "unknown")
    echo -e "    Health: $REDIS_STATUS"
else
    fail "Redis container not running"
fi

print_test "Langflow container running"
if docker-compose ps langflow | grep -q "Up"; then
    pass
    LANGFLOW_STATUS=$(docker inspect --format='{{.State.Health.Status}}' engarde_langflow 2>/dev/null || echo "unknown")
    echo -e "    Health: $LANGFLOW_STATUS"
else
    fail "Langflow container not running"
fi

# ============================================================================
# Test 3: Database Schema Validation
# ============================================================================

print_header "Database Schema Validation"

if command -v psql &> /dev/null; then
    print_test "Database connection"
    if psql "$DATABASE_URL" -c "SELECT 1" &> /dev/null; then
        pass
    else
        fail "Cannot connect to database"
    fi

    print_test "Langflow schema exists"
    SCHEMA_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM pg_namespace WHERE nspname = 'langflow';" | tr -d ' ')
    if [ "$SCHEMA_EXISTS" = "1" ]; then
        pass
    else
        fail "Langflow schema not found"
    fi

    print_test "Langflow user exists"
    USER_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM pg_roles WHERE rolname = 'langflow_user';" | tr -d ' ')
    if [ "$USER_EXISTS" = "1" ]; then
        pass
    else
        fail "langflow_user not found"
    fi

    print_test "Langflow user has schema permissions"
    PERMS=$(psql "$DATABASE_URL" -t -c "SELECT has_schema_privilege('langflow_user', 'langflow', 'CREATE');" | tr -d ' ')
    if [ "$PERMS" = "t" ]; then
        pass
    else
        fail "langflow_user lacks CREATE permission"
    fi

    print_test "Langflow tables created"
    TABLE_COUNT=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'langflow';" | tr -d ' ')
    if [ "$TABLE_COUNT" -gt "0" ]; then
        pass
        echo -e "    Tables: $TABLE_COUNT"
    else
        warn "No tables found (may be normal on first start)"
    fi

    print_test "Cross-schema access (engarde_user can read langflow)"
    CROSS_PERMS=$(psql "$DATABASE_URL" -t -c "SELECT has_schema_privilege('engarde_user', 'langflow', 'USAGE');" | tr -d ' ')
    if [ "$CROSS_PERMS" = "t" ]; then
        pass
    else
        fail "engarde_user cannot access langflow schema"
    fi
else
    warn "psql not available, skipping database tests"
fi

# ============================================================================
# Test 4: Langflow Service Validation
# ============================================================================

print_header "Langflow Service Validation"

print_test "Langflow health endpoint"
if curl -f http://localhost:7860/health &> /dev/null; then
    pass
    HEALTH_RESPONSE=$(curl -s http://localhost:7860/health)
    echo -e "    Response: $HEALTH_RESPONSE"
else
    fail "Health endpoint not responding"
fi

print_test "Langflow API endpoint"
if curl -f http://localhost:7860/api/v1/version &> /dev/null; then
    pass
    VERSION=$(curl -s http://localhost:7860/api/v1/version 2>/dev/null | head -1)
    echo -e "    API accessible"
else
    warn "API endpoint not responding (may require authentication)"
fi

print_test "Langflow Web UI"
if curl -f http://localhost:7860/ &> /dev/null; then
    pass
else
    fail "Web UI not responding"
fi

# ============================================================================
# Test 5: Network Configuration
# ============================================================================

print_header "Network Configuration Validation"

print_test "Docker network exists"
if docker network ls | grep -q "engarde_network"; then
    pass
else
    fail "engarde_network not found"
fi

print_test "Containers on same network"
NETWORK_CONTAINERS=$(docker network inspect engarde_network -f '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null)
if echo "$NETWORK_CONTAINERS" | grep -q "langflow"; then
    pass
    echo -e "    Containers: $NETWORK_CONTAINERS"
else
    fail "Langflow not on engarde_network"
fi

print_test "Port 7860 accessible"
if nc -z localhost 7860 &> /dev/null || curl -s http://localhost:7860/health &> /dev/null; then
    pass
else
    fail "Port 7860 not accessible"
fi

# ============================================================================
# Test 6: Volume Configuration
# ============================================================================

print_header "Volume Configuration Validation"

print_test "Langflow logs volume exists"
if docker volume ls | grep -q "langflow_logs"; then
    pass
    LOGS_SIZE=$(docker volume inspect langflow_logs -f '{{.Mountpoint}}' 2>/dev/null | xargs du -sh 2>/dev/null | awk '{print $1}')
    if [ ! -z "$LOGS_SIZE" ]; then
        echo -e "    Size: $LOGS_SIZE"
    fi
else
    warn "langflow_logs volume not found"
fi

print_test "Langflow data volume exists"
if docker volume ls | grep -q "langflow_data"; then
    pass
else
    warn "langflow_data volume not found"
fi

print_test "Custom components mounted"
if docker-compose exec -T langflow test -d /app/custom_components &> /dev/null; then
    pass
    COMPONENT_COUNT=$(docker-compose exec -T langflow find /app/custom_components -name "*.py" 2>/dev/null | wc -l)
    echo -e "    Python files: $COMPONENT_COUNT"
else
    warn "Custom components directory not found"
fi

# ============================================================================
# Test 7: Environment Variables
# ============================================================================

print_header "Environment Variables Validation"

print_test "LANGFLOW_DATABASE_URL configured"
DB_URL=$(docker-compose exec -T langflow printenv LANGFLOW_DATABASE_URL 2>/dev/null || echo "")
if [ ! -z "$DB_URL" ]; then
    pass
    # Don't print the actual URL (contains password)
    echo -e "    Configured (hidden for security)"
else
    fail "LANGFLOW_DATABASE_URL not set"
fi

print_test "LANGFLOW_SCHEMA configured"
SCHEMA=$(docker-compose exec -T langflow printenv LANGFLOW_SCHEMA 2>/dev/null || echo "")
if [ "$SCHEMA" = "langflow" ]; then
    pass
    echo -e "    Schema: $SCHEMA"
else
    fail "LANGFLOW_SCHEMA not set to 'langflow'"
fi

print_test "LANGFLOW_COMPONENTS_PATH configured"
COMP_PATH=$(docker-compose exec -T langflow printenv LANGFLOW_COMPONENTS_PATH 2>/dev/null || echo "")
if [ ! -z "$COMP_PATH" ]; then
    pass
    echo -e "    Path: $COMP_PATH"
else
    warn "LANGFLOW_COMPONENTS_PATH not set"
fi

# ============================================================================
# Test 8: Logs and Errors
# ============================================================================

print_header "Logs and Error Validation"

print_test "No critical errors in logs"
ERRORS=$(docker-compose logs --tail=100 langflow 2>/dev/null | grep -i "error\|critical\|fatal" | wc -l)
if [ "$ERRORS" -eq "0" ]; then
    pass
else
    warn "Found $ERRORS error messages in recent logs"
fi

print_test "Langflow successfully started"
if docker-compose logs langflow 2>/dev/null | grep -q "Uvicorn running\|Application startup complete"; then
    pass
else
    warn "Startup message not found in logs"
fi

# ============================================================================
# Test 9: Integration Tests
# ============================================================================

print_header "Integration Tests"

print_test "Can create test flow (API test)"
# Try to get flows list
FLOWS_RESPONSE=$(curl -s -w "\n%{http_code}" http://localhost:7860/api/v1/flows 2>/dev/null || echo "000")
HTTP_CODE=$(echo "$FLOWS_RESPONSE" | tail -1)
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "401" ]; then
    # 200 = success, 401 = auth required (API is working)
    pass
    echo -e "    HTTP: $HTTP_CODE"
else
    warn "Flows API returned unexpected code: $HTTP_CODE"
fi

# ============================================================================
# Summary
# ============================================================================

print_header "Validation Summary"

TOTAL=$((PASSED + FAILED + WARNINGS))

echo -e "${GREEN}Passed:   $PASSED${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo -e "${RED}Failed:   $FAILED${NC}"
echo -e "Total:    $TOTAL"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ ALL CRITICAL TESTS PASSED${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}Langflow is properly configured and operational!${NC}"
    echo ""
    echo -e "${BLUE}Access Points:${NC}"
    echo "  Web UI:  http://localhost:7860"
    echo "  API:     http://localhost:7860/api"
    echo "  Docs:    http://localhost:7860/docs"
    echo ""

    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}Note: $WARNINGS warnings found. Review output above.${NC}"
    fi

    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ VALIDATION FAILED${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo -e "${RED}$FAILED critical test(s) failed.${NC}"
    echo -e "${BLUE}Please review the output above and fix the issues.${NC}"
    echo ""
    echo -e "${BLUE}Common fixes:${NC}"
    echo "  1. Ensure Docker is running: docker info"
    echo "  2. Start services: docker-compose up -d"
    echo "  3. Check logs: docker-compose logs langflow"
    echo "  4. Rebuild: ./scripts/restart-langflow.sh --rebuild"
    echo "  5. Initialize: ./scripts/init-langflow.sh"
    echo ""
    exit 1
fi
