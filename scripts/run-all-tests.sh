#!/bin/bash
# Comprehensive Test Suite Runner
# Runs all authentication and brand management tests

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
BACKEND_AUTH_RESULT=0
BACKEND_BRAND_RESULT=0
FRONTEND_AUTH_RESULT=0
FRONTEND_BRAND_RESULT=0
E2E_RESULT=0

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  EnGarde Comprehensive Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print section header
print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# ============================================================================
# Backend Authentication Tests
# ============================================================================

print_header "Backend Authentication Tests"

cd /Users/cope/EnGardeHQ/production-backend

if pytest tests/test_auth_comprehensive.py \
    -v \
    --cov=app.routers.zerodb_auth \
    --cov=app.services.zerodb_auth \
    --cov-report=html:coverage/auth-html \
    --cov-report=term \
    --junit-xml=test-results/auth-junit.xml; then
    print_success "Backend authentication tests passed!"
    BACKEND_AUTH_RESULT=0
else
    print_error "Backend authentication tests failed!"
    BACKEND_AUTH_RESULT=1
fi

# ============================================================================
# Backend Brand Management Tests
# ============================================================================

print_header "Backend Brand Management Tests"

cd /Users/cope/EnGardeHQ/production-backend

if pytest tests/test_brands_comprehensive.py \
    -v \
    --cov=app.routers.brands \
    --cov=app.models.brand_models \
    --cov=app.schemas.brand_schemas \
    --cov-report=html:coverage/brand-html \
    --cov-report=term \
    --junit-xml=test-results/brand-junit.xml; then
    print_success "Backend brand tests passed!"
    BACKEND_BRAND_RESULT=0
else
    print_error "Backend brand tests failed!"
    BACKEND_BRAND_RESULT=1
fi

# ============================================================================
# Frontend Authentication Tests
# ============================================================================

print_header "Frontend Authentication Tests"

cd /Users/cope/EnGardeHQ/production-frontend

if npm test -- __tests__/auth-comprehensive.test.tsx \
    --coverage \
    --coverageDirectory=coverage/auth \
    --watchAll=false; then
    print_success "Frontend authentication tests passed!"
    FRONTEND_AUTH_RESULT=0
else
    print_error "Frontend authentication tests failed!"
    FRONTEND_AUTH_RESULT=1
fi

# ============================================================================
# Frontend Brand Tests
# ============================================================================

print_header "Frontend Brand Tests"

cd /Users/cope/EnGardeHQ/production-frontend

if npm test -- __tests__/brands-comprehensive.test.tsx \
    --coverage \
    --coverageDirectory=coverage/brands \
    --watchAll=false; then
    print_success "Frontend brand tests passed!"
    FRONTEND_BRAND_RESULT=0
else
    print_error "Frontend brand tests failed!"
    FRONTEND_BRAND_RESULT=1
fi

# ============================================================================
# E2E Integration Tests
# ============================================================================

print_header "E2E Integration Tests"

cd /Users/cope/EnGardeHQ/production-frontend

print_warning "Note: E2E tests require backend and frontend servers to be running"
print_warning "Starting servers if not already running..."

# Check if backend is running
if ! curl -s http://localhost:8000/docs > /dev/null; then
    print_warning "Backend not running. Please start with: docker-compose up -d"
    print_warning "Skipping E2E tests."
    E2E_RESULT=2  # 2 = skipped
else
    # Check if frontend is running
    if ! curl -s http://localhost:3001 > /dev/null; then
        print_warning "Frontend not running. Please start with: npm run dev"
        print_warning "Skipping E2E tests."
        E2E_RESULT=2
    else
        if npx playwright test e2e/auth-brand-integration.spec.ts --reporter=html; then
            print_success "E2E integration tests passed!"
            E2E_RESULT=0
        else
            print_error "E2E integration tests failed!"
            E2E_RESULT=1
        fi
    fi
fi

# ============================================================================
# Test Summary
# ============================================================================

print_header "Test Results Summary"

echo ""
echo "Backend Authentication Tests:  $([ $BACKEND_AUTH_RESULT -eq 0 ] && echo -e ${GREEN}PASSED${NC} || echo -e ${RED}FAILED${NC})"
echo "Backend Brand Tests:           $([ $BACKEND_BRAND_RESULT -eq 0 ] && echo -e ${GREEN}PASSED${NC} || echo -e ${RED}FAILED${NC})"
echo "Frontend Authentication Tests: $([ $FRONTEND_AUTH_RESULT -eq 0 ] && echo -e ${GREEN}PASSED${NC} || echo -e ${RED}FAILED${NC})"
echo "Frontend Brand Tests:          $([ $FRONTEND_BRAND_RESULT -eq 0 ] && echo -e ${GREEN}PASSED${NC} || echo -e ${RED}FAILED${NC})"
echo "E2E Integration Tests:         $([ $E2E_RESULT -eq 0 ] && echo -e ${GREEN}PASSED${NC} || [ $E2E_RESULT -eq 2 ] && echo -e ${YELLOW}SKIPPED${NC} || echo -e ${RED}FAILED${NC})"
echo ""

# ============================================================================
# Coverage Reports
# ============================================================================

print_header "Coverage Reports"

echo "Backend coverage reports:"
echo "  - Auth: file:///Users/cope/EnGardeHQ/production-backend/coverage/auth-html/index.html"
echo "  - Brand: file:///Users/cope/EnGardeHQ/production-backend/coverage/brand-html/index.html"
echo ""
echo "Frontend coverage reports:"
echo "  - Auth: file:///Users/cope/EnGardeHQ/production-frontend/coverage/auth/lcov-report/index.html"
echo "  - Brand: file:///Users/cope/EnGardeHQ/production-frontend/coverage/brands/lcov-report/index.html"
echo ""

if [ $E2E_RESULT -eq 0 ]; then
    echo "E2E test report:"
    echo "  - file:///Users/cope/EnGardeHQ/production-frontend/playwright-report/index.html"
    echo ""
fi

# ============================================================================
# Exit Code
# ============================================================================

# Calculate total failures
TOTAL_FAILURES=$((BACKEND_AUTH_RESULT + BACKEND_BRAND_RESULT + FRONTEND_AUTH_RESULT + FRONTEND_BRAND_RESULT))

# Only add E2E result if it was actually run (not skipped)
if [ $E2E_RESULT -eq 1 ]; then
    TOTAL_FAILURES=$((TOTAL_FAILURES + 1))
fi

if [ $TOTAL_FAILURES -eq 0 ]; then
    print_success "All tests passed! 🎉"
    echo ""
    exit 0
else
    print_error "Some tests failed. Please review the output above."
    echo ""
    exit 1
fi
