#!/bin/bash

###############################################################################
# EnGarde Frontend - Post-Deployment Verification Script
# This script verifies that the deployment was successful and the application
# is functioning correctly with comprehensive health checks
###############################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verification configuration
PROJECT_ROOT="/Users/cope/EnGardeHQ"
FRONTEND_DIR="${PROJECT_ROOT}/production-frontend"
VERIFY_LOG="${PROJECT_ROOT}/logs/verify-$(date +%Y%m%d-%H%M%S).log"
ENVIRONMENT="${1:-production}"
API_URL="${2:-http://localhost:3000}"

# Create logs directory if it doesn't exist
mkdir -p "${PROJECT_ROOT}/logs"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date +%Y-%m-%d\ %H:%M:%S) - $1" | tee -a "${VERIFY_LOG}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date +%Y-%m-%d\ %H:%M:%S) - $1" | tee -a "${VERIFY_LOG}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date +%Y-%m-%d\ %H:%M:%S) - $1" | tee -a "${VERIFY_LOG}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date +%Y-%m-%d\ %H:%M:%S) - $1" | tee -a "${VERIFY_LOG}"
}

# Verification tracking
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

###############################################################################
# Verification Functions
###############################################################################

verify_check() {
    local check_name="$1"
    local result="$2"

    if [ "${result}" = "pass" ]; then
        log_success "${check_name}"
        ((CHECKS_PASSED++))
        return 0
    elif [ "${result}" = "warn" ]; then
        log_warning "${check_name}"
        ((CHECKS_WARNING++))
        return 0
    else
        log_error "${check_name}"
        ((CHECKS_FAILED++))
        return 1
    fi
}

###############################################################################
# Start Verification
###############################################################################

echo ""
log_info "======================================"
log_info "  POST-DEPLOYMENT VERIFICATION"
log_info "======================================"
echo ""

log_info "Environment: ${ENVIRONMENT}"
log_info "API URL: ${API_URL}"
log_info "Verification log: ${VERIFY_LOG}"
log_info "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"

cd "${FRONTEND_DIR}"

###############################################################################
# 1. Configuration Verification
###############################################################################

echo ""
log_info "=== 1. Configuration Verification ==="

# Check .env.production exists
if [ -f .env.production ]; then
    verify_check ".env.production exists" "pass"
else
    verify_check ".env.production exists" "fail"
fi

# Check feature flag configuration
if grep -q "NEXT_PUBLIC_ENABLE_AUTH_INIT_FIX=true" .env.production; then
    verify_check "Auth fix feature flag enabled" "pass"
else
    verify_check "Auth fix feature flag enabled" "warn"
fi

# Check rollout percentage
ROLLOUT_PCT=$(grep "NEXT_PUBLIC_AUTH_FIX_ROLLOUT_PERCENTAGE" .env.production | cut -d'=' -f2 || echo "0")
log_info "Current rollout percentage: ${ROLLOUT_PCT}%"

if [ "${ROLLOUT_PCT}" -gt 0 ] && [ "${ROLLOUT_PCT}" -le 100 ]; then
    verify_check "Rollout percentage valid (${ROLLOUT_PCT}%)" "pass"
else
    verify_check "Rollout percentage valid (${ROLLOUT_PCT}%)" "fail"
fi

# Check monitoring configuration
if grep -q "NEXT_PUBLIC_ENABLE_AUTH_MONITORING=true" .env.production; then
    verify_check "Auth monitoring enabled" "pass"
else
    verify_check "Auth monitoring enabled" "warn"
fi

###############################################################################
# 2. Build Verification
###############################################################################

echo ""
log_info "=== 2. Build Verification ==="

# Check build output exists
if [ -d .next ]; then
    verify_check "Build output directory exists" "pass"
else
    verify_check "Build output directory exists" "fail"
fi

# Check critical build files
BUILD_FILES=(
    ".next/BUILD_ID"
    ".next/package.json"
    ".next/server"
    ".next/static"
)

for file in "${BUILD_FILES[@]}"; do
    if [ -e "${file}" ]; then
        verify_check "Build file exists: ${file}" "pass"
    else
        verify_check "Build file exists: ${file}" "warn"
    fi
done

# Check build size
if [ -d .next ]; then
    BUILD_SIZE=$(du -sh .next | cut -f1)
    log_info "Build size: ${BUILD_SIZE}"
fi

###############################################################################
# 3. Application Health Check
###############################################################################

echo ""
log_info "=== 3. Application Health Check ==="

# Wait for application to be ready
log_info "Waiting for application to respond..."
sleep 5

# Check if application is running
HEALTH_CHECK_ATTEMPTS=0
MAX_ATTEMPTS=10

while [ ${HEALTH_CHECK_ATTEMPTS} -lt ${MAX_ATTEMPTS} ]; do
    if curl -f -s -o /dev/null -w "%{http_code}" "${API_URL}/" 2>/dev/null | grep -q "200\|301\|302"; then
        verify_check "Application responds to HTTP requests" "pass"
        break
    else
        ((HEALTH_CHECK_ATTEMPTS++))
        if [ ${HEALTH_CHECK_ATTEMPTS} -eq ${MAX_ATTEMPTS} ]; then
            verify_check "Application responds to HTTP requests" "fail"
        else
            log_info "Attempt ${HEALTH_CHECK_ATTEMPTS}/${MAX_ATTEMPTS} - Waiting for application..."
            sleep 3
        fi
    fi
done

# Check health endpoint (if available)
if curl -f -s "${API_URL}/api/health" > /dev/null 2>&1; then
    verify_check "Health endpoint accessible" "pass"
else
    verify_check "Health endpoint accessible" "warn"
fi

###############################################################################
# 4. Authentication Flow Verification
###############################################################################

echo ""
log_info "=== 4. Authentication Flow Verification ==="

# Check login page is accessible
if curl -f -s "${API_URL}/login" > /dev/null 2>&1; then
    verify_check "Login page accessible" "pass"
else
    verify_check "Login page accessible" "warn"
fi

# Check dashboard route is accessible (should redirect if not authenticated)
DASHBOARD_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${API_URL}/dashboard" 2>/dev/null || echo "000")
if [ "${DASHBOARD_STATUS}" = "200" ] || [ "${DASHBOARD_STATUS}" = "302" ] || [ "${DASHBOARD_STATUS}" = "307" ]; then
    verify_check "Dashboard route responds correctly" "pass"
else
    verify_check "Dashboard route responds correctly (status: ${DASHBOARD_STATUS})" "warn"
fi

###############################################################################
# 5. Static Assets Verification
###############################################################################

echo ""
log_info "=== 5. Static Assets Verification ==="

# Check for _next/static directory
if curl -f -s "${API_URL}/_next/static/" > /dev/null 2>&1; then
    verify_check "Static assets accessible" "pass"
else
    verify_check "Static assets accessible" "warn"
fi

###############################################################################
# 6. Performance Metrics
###############################################################################

echo ""
log_info "=== 6. Performance Metrics ==="

# Measure response time
START_TIME=$(date +%s%3N)
curl -f -s -o /dev/null "${API_URL}/" 2>/dev/null || true
END_TIME=$(date +%s%3N)
RESPONSE_TIME=$((END_TIME - START_TIME))

log_info "Homepage response time: ${RESPONSE_TIME}ms"

if [ ${RESPONSE_TIME} -lt 2000 ]; then
    verify_check "Response time acceptable (<2000ms)" "pass"
elif [ ${RESPONSE_TIME} -lt 5000 ]; then
    verify_check "Response time acceptable (<5000ms)" "warn"
else
    verify_check "Response time acceptable (>${RESPONSE_TIME}ms)" "fail"
fi

###############################################################################
# 7. Docker Verification (if applicable)
###############################################################################

echo ""
log_info "=== 7. Docker Verification ==="

# Check if Docker image exists
if docker image inspect engarde-frontend:latest > /dev/null 2>&1; then
    verify_check "Docker image exists" "pass"

    # Check image size
    IMAGE_SIZE=$(docker image inspect engarde-frontend:latest --format='{{.Size}}' | awk '{printf "%.2f MB", $1/1024/1024}')
    log_info "Docker image size: ${IMAGE_SIZE}"

    # Check image labels
    BUILD_ID=$(docker image inspect engarde-frontend:latest --format='{{index .Config.Labels "build_id"}}' 2>/dev/null || echo "unknown")
    log_info "Build ID: ${BUILD_ID}"
else
    verify_check "Docker image exists" "warn"
fi

# Check if container is running
if docker ps | grep -q engarde_frontend; then
    verify_check "Docker container running" "pass"
else
    verify_check "Docker container running" "warn"
fi

###############################################################################
# 8. Monitoring Integration Verification
###############################################################################

echo ""
log_info "=== 8. Monitoring Integration ==="

# Check if Sentry is configured
if grep -q "NEXT_PUBLIC_SENTRY_DSN" .env.production && ! grep -q "NEXT_PUBLIC_SENTRY_DSN=$" .env.production; then
    verify_check "Sentry DSN configured" "pass"
else
    verify_check "Sentry DSN configured" "warn"
fi

# Check if DataDog is configured
if grep -q "NEXT_PUBLIC_DATADOG_APPLICATION_ID" .env.production && ! grep -q "NEXT_PUBLIC_DATADOG_APPLICATION_ID=$" .env.production; then
    verify_check "DataDog RUM configured" "pass"
else
    verify_check "DataDog RUM configured" "warn"
fi

###############################################################################
# 9. Security Headers Verification
###############################################################################

echo ""
log_info "=== 9. Security Headers ==="

# Check security headers
HEADERS=$(curl -s -I "${API_URL}/" 2>/dev/null || echo "")

if echo "${HEADERS}" | grep -qi "X-Frame-Options"; then
    verify_check "X-Frame-Options header present" "pass"
else
    verify_check "X-Frame-Options header present" "warn"
fi

if echo "${HEADERS}" | grep -qi "X-Content-Type-Options"; then
    verify_check "X-Content-Type-Options header present" "pass"
else
    verify_check "X-Content-Type-Options header present" "warn"
fi

###############################################################################
# Verification Summary
###############################################################################

echo ""
log_info "======================================"
log_info "  VERIFICATION SUMMARY"
log_info "======================================"
echo ""

TOTAL_CHECKS=$((CHECKS_PASSED + CHECKS_FAILED + CHECKS_WARNING))

log_info "Total checks: ${TOTAL_CHECKS}"
log_success "Passed: ${CHECKS_PASSED}"
log_warning "Warnings: ${CHECKS_WARNING}"
log_error "Failed: ${CHECKS_FAILED}"

echo ""

if [ ${CHECKS_FAILED} -eq 0 ] && [ ${CHECKS_WARNING} -eq 0 ]; then
    log_success "======================================"
    log_success "  ALL CHECKS PASSED"
    log_success "======================================"
    EXIT_CODE=0
elif [ ${CHECKS_FAILED} -eq 0 ]; then
    log_warning "======================================"
    log_warning "  VERIFICATION PASSED WITH WARNINGS"
    log_warning "======================================"
    log_info "Review warnings and address if necessary"
    EXIT_CODE=0
else
    log_error "======================================"
    log_error "  VERIFICATION FAILED"
    log_error "======================================"
    log_error "Critical issues found. Consider rollback."
    EXIT_CODE=1
fi

echo ""
log_info "Next steps:"

if [ ${EXIT_CODE} -eq 0 ]; then
    log_info "1. Monitor application metrics for 30 minutes"
    log_info "2. Check error rates in Sentry/DataDog"
    log_info "3. Review user feedback and support tickets"
    log_info "4. If stable, increase rollout: bash scripts/deploy.sh 50"
else
    log_error "1. Review failed checks in detail"
    log_error "2. Check application logs for errors"
    log_error "3. Consider rolling back: bash scripts/rollback.sh"
fi

echo ""
log_info "Full verification log: ${VERIFY_LOG}"

exit ${EXIT_CODE}
