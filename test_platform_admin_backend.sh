#!/bin/bash
# Test script for SignUp_Sync Platform Admin Backend
# Tests all routers, endpoints, and scheduler integration

set -e

echo "========================================"
echo "SignUp_Sync Platform Admin Backend Test"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0

function test_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        ((TESTS_FAILED++))
    fi
}

# =====================================================
# 1. VERIFY ROUTER REGISTRATION
# =====================================================
echo "1. Testing Router Registration in main.py"
echo "-------------------------------------------"

# Check if routers are imported
grep -q "from app.routers import.*admin_platform_brands" /Users/cope/EnGardeHQ/production-backend/app/main.py
test_result $? "admin_platform_brands imported in main.py"

grep -q "from app.routers import.*admin_platform_usage" /Users/cope/EnGardeHQ/production-backend/app/main.py
test_result $? "admin_platform_usage imported in main.py"

# Check if routers are registered
grep -q "app.include_router(admin_platform_brands.router)" /Users/cope/EnGardeHQ/production-backend/app/main.py
test_result $? "admin_platform_brands.router registered"

grep -q "app.include_router(admin_platform_usage.router)" /Users/cope/EnGardeHQ/production-backend/app/main.py
test_result $? "admin_platform_usage.router registered"

echo ""

# =====================================================
# 2. VERIFY FUNNEL SYNC SCHEDULER
# =====================================================
echo "2. Testing Funnel Sync Scheduler Integration"
echo "---------------------------------------------"

# Check scheduler service exists
test -f /Users/cope/EnGardeHQ/production-backend/app/services/funnel_sync_scheduler.py
test_result $? "funnel_sync_scheduler.py exists"

# Check scheduler imported in main.py
grep -q "from app.services.funnel_sync_scheduler import start_funnel_sync_scheduler" /Users/cope/EnGardeHQ/production-backend/app/main.py
test_result $? "Scheduler imported in main.py"

# Check scheduler started in lifespan
grep -q "start_funnel_sync_scheduler()" /Users/cope/EnGardeHQ/production-backend/app/main.py
test_result $? "Scheduler started in lifespan"

# Check scheduler stopped in lifespan
grep -q "stop_funnel_sync_scheduler()" /Users/cope/EnGardeHQ/production-backend/app/main.py
test_result $? "Scheduler stopped in lifespan"

echo ""

# =====================================================
# 3. VERIFY DATABASE MODELS
# =====================================================
echo "3. Testing Database Models"
echo "--------------------------"

# Check platform models
test -f /Users/cope/EnGardeHQ/production-backend/app/models/platform_models.py
test_result $? "platform_models.py exists"

grep -q "class PlatformBrand" /Users/cope/EnGardeHQ/production-backend/app/models/platform_models.py
test_result $? "PlatformBrand model defined"

grep -q "class AdminUsageReport" /Users/cope/EnGardeHQ/production-backend/app/models/platform_models.py
test_result $? "AdminUsageReport model defined"

# Check funnel models
test -f /Users/cope/EnGardeHQ/production-backend/app/models/funnel_models.py
test_result $? "funnel_models.py exists"

grep -q "class FunnelSource" /Users/cope/EnGardeHQ/production-backend/app/models/funnel_models.py
test_result $? "FunnelSource model defined"

grep -q "class FunnelEvent" /Users/cope/EnGardeHQ/production-backend/app/models/funnel_models.py
test_result $? "FunnelEvent model defined"

grep -q "class FunnelConversion" /Users/cope/EnGardeHQ/production-backend/app/models/funnel_models.py
test_result $? "FunnelConversion model defined"

echo ""

# =====================================================
# 4. VERIFY ROUTER ENDPOINTS
# =====================================================
echo "4. Testing Router Endpoints Definition"
echo "---------------------------------------"

# Platform Brands Router
grep -q 'GET.*"/brands"' /Users/cope/EnGardeHQ/production-backend/app/routers/admin_platform_brands.py
test_result $? "GET /api/admin/platform/brands endpoint defined"

grep -q 'POST.*"/brands"' /Users/cope/EnGardeHQ/production-backend/app/routers/admin_platform_brands.py
test_result $? "POST /api/admin/platform/brands endpoint defined"

grep -q 'GET.*"/brands/{brand_id}/usage"' /Users/cope/EnGardeHQ/production-backend/app/routers/admin_platform_brands.py
test_result $? "GET /api/admin/platform/brands/{brand_id}/usage endpoint defined"

# Platform Usage Router
grep -q 'GET.*"/users"' /Users/cope/EnGardeHQ/production-backend/app/routers/admin_platform_usage.py
test_result $? "GET /api/admin/platform/usage/users endpoint defined"

grep -q 'GET.*"/tenants"' /Users/cope/EnGardeHQ/production-backend/app/routers/admin_platform_usage.py
test_result $? "GET /api/admin/platform/usage/tenants endpoint defined"

echo ""

# =====================================================
# 5. VERIFY SIGNUP_SYNC SERVICE
# =====================================================
echo "5. Testing SignUp_Sync Service Files"
echo "-------------------------------------"

# Check service directory
test -d /Users/cope/EnGardeHQ/signup-sync-service
test_result $? "signup-sync-service directory exists"

test -f /Users/cope/EnGardeHQ/signup-sync-service/app/main.py
test_result $? "SignUp_Sync main.py exists"

test -f /Users/cope/EnGardeHQ/signup-sync-service/requirements.txt
test_result $? "SignUp_Sync requirements.txt exists"

test -f /Users/cope/EnGardeHQ/signup-sync-service/Dockerfile
test_result $? "SignUp_Sync Dockerfile exists"

test -f /Users/cope/EnGardeHQ/signup-sync-service/railway.json
test_result $? "SignUp_Sync railway.json exists"

# Check service endpoints
grep -q 'POST.*"/sync/easyappointments"' /Users/cope/EnGardeHQ/signup-sync-service/app/main.py
test_result $? "POST /sync/easyappointments endpoint defined"

grep -q 'POST.*"/sync/all"' /Users/cope/EnGardeHQ/signup-sync-service/app/main.py
test_result $? "POST /sync/all endpoint defined"

grep -q 'POST.*"/funnel/event"' /Users/cope/EnGardeHQ/signup-sync-service/app/main.py
test_result $? "POST /funnel/event endpoint defined"

echo ""

# =====================================================
# 6. VERIFY MIGRATIONS
# =====================================================
echo "6. Testing Database Migration Files"
echo "------------------------------------"

test -f /Users/cope/EnGardeHQ/production-backend/migrations/20260119_create_funnel_tables.sql
test_result $? "Funnel tables migration exists"

test -f /Users/cope/EnGardeHQ/production-backend/migrations/20260119_create_platform_tables.sql
test_result $? "Platform tables migration exists"

test -f /Users/cope/EnGardeHQ/production-backend/migrations/20260119_seed_platform_user.sql
test_result $? "Platform user seed migration exists"

echo ""

# =====================================================
# 7. VERIFY PYTHON IMPORTS
# =====================================================
echo "7. Testing Python Import Integrity"
echo "-----------------------------------"

cd /Users/cope/EnGardeHQ/production-backend

# Test router imports (suppress database warnings)
python3 -c "from app.routers import admin_platform_brands" 2>&1 | grep -q "Traceback"
if [ $? -eq 0 ]; then
    test_result 1 "admin_platform_brands imports without errors"
else
    test_result 0 "admin_platform_brands imports without errors"
fi

python3 -c "from app.routers import admin_platform_usage" 2>&1 | grep -q "Traceback"
if [ $? -eq 0 ]; then
    test_result 1 "admin_platform_usage imports without errors"
else
    test_result 0 "admin_platform_usage imports without errors"
fi

# Test model imports
python3 -c "from app.models import platform_models" 2>&1 | grep -q "Traceback"
if [ $? -eq 0 ]; then
    test_result 1 "platform_models imports without errors"
else
    test_result 0 "platform_models imports without errors"
fi

python3 -c "from app.models import funnel_models" 2>&1 | grep -q "Traceback"
if [ $? -eq 0 ]; then
    test_result 1 "funnel_models imports without errors"
else
    test_result 0 "funnel_models imports without errors"
fi

echo ""

# =====================================================
# 8. CHECK SCHEDULER CONFIGURATION
# =====================================================
echo "8. Testing Scheduler Configuration"
echo "-----------------------------------"

# Check for required scheduler components
grep -q "AsyncIOScheduler" /Users/cope/EnGardeHQ/production-backend/app/services/funnel_sync_scheduler.py
test_result $? "AsyncIOScheduler used"

grep -q "CronTrigger" /Users/cope/EnGardeHQ/production-backend/app/services/funnel_sync_scheduler.py
test_result $? "CronTrigger used for scheduling"

grep -q "SIGNUP_SYNC_SERVICE_URL" /Users/cope/EnGardeHQ/production-backend/app/services/funnel_sync_scheduler.py
test_result $? "SIGNUP_SYNC_SERVICE_URL configured"

grep -q "SIGNUP_SYNC_SERVICE_TOKEN" /Users/cope/EnGardeHQ/production-backend/app/services/funnel_sync_scheduler.py
test_result $? "SIGNUP_SYNC_SERVICE_TOKEN configured"

echo ""

# =====================================================
# TEST SUMMARY
# =====================================================
echo "========================================"
echo "TEST SUMMARY"
echo "========================================"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
    echo ""
    echo "The SignUp_Sync Platform Admin Backend is correctly configured!"
    exit 0
else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    echo ""
    echo "Please review the failures above and fix the issues."
    exit 1
fi
