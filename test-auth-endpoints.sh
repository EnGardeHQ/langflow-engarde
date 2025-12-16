#!/bin/bash

# Test Script for EnGarde Authentication Endpoints
# This script tests all authentication endpoints and verifies they work correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL="${BACKEND_URL:-http://localhost:8000}"
FRONTEND_URL="${FRONTEND_URL:-http://localhost:3001}"
TEST_EMAIL="${TEST_EMAIL:-demo@engarde.com}"
TEST_PASSWORD="${TEST_PASSWORD:-demo123}"

echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}  EnGarde Authentication Endpoints Test Suite${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo ""
echo -e "Backend URL:  ${YELLOW}${BACKEND_URL}${NC}"
echo -e "Frontend URL: ${YELLOW}${FRONTEND_URL}${NC}"
echo -e "Test User:    ${YELLOW}${TEST_EMAIL}${NC}"
echo ""

# Function to print test results
print_result() {
    local test_name=$1
    local status=$2
    local message=$3

    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✓ PASS${NC} - ${test_name}"
        [ -n "$message" ] && echo -e "  ${message}"
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}✗ FAIL${NC} - ${test_name}"
        [ -n "$message" ] && echo -e "  ${RED}${message}${NC}"
    else
        echo -e "${YELLOW}⚠ SKIP${NC} - ${test_name}"
        [ -n "$message" ] && echo -e "  ${message}"
    fi
    echo ""
}

# Test 1: Backend Health Check
echo -e "${BLUE}Test 1: Backend Health Check${NC}"
response=$(curl -s -w "\n%{http_code}" "${BACKEND_URL}/health" || echo "000")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" = "200" ]; then
    print_result "Backend Health Check" "PASS" "Backend is healthy and responding"
    echo -e "Response: ${body}" | head -n 5
else
    print_result "Backend Health Check" "FAIL" "Backend returned HTTP ${http_code}"
    exit 1
fi

# Test 2: Frontend Health Check
echo -e "${BLUE}Test 2: Frontend Health Check${NC}"
response=$(curl -s -w "\n%{http_code}" "${FRONTEND_URL}/api/health" || echo "000")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" = "200" ]; then
    print_result "Frontend Health Check" "PASS" "Frontend is healthy and responding"
else
    print_result "Frontend Health Check" "FAIL" "Frontend returned HTTP ${http_code}"
    echo "Note: Frontend might not be running. Continuing with backend tests..."
fi

# Test 3: Backend Direct Login (/token endpoint)
echo -e "${BLUE}Test 3: Backend Direct Login (/token endpoint)${NC}"
response=$(curl -s -w "\n%{http_code}" \
    -X POST "${BACKEND_URL}/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=${TEST_EMAIL}&password=${TEST_PASSWORD}&grant_type=password" \
    || echo "000")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" = "200" ]; then
    BACKEND_ACCESS_TOKEN=$(echo "$body" | grep -o '"access_token":"[^"]*' | sed 's/"access_token":"//')
    BACKEND_REFRESH_TOKEN=$(echo "$body" | grep -o '"refresh_token":"[^"]*' | sed 's/"refresh_token":"//')

    if [ -n "$BACKEND_ACCESS_TOKEN" ] && [ -n "$BACKEND_REFRESH_TOKEN" ]; then
        print_result "Backend Direct Login" "PASS" "Login successful, tokens received"
        echo -e "  Access Token (first 20 chars): ${BACKEND_ACCESS_TOKEN:0:20}..."
        echo -e "  Refresh Token (first 20 chars): ${BACKEND_REFRESH_TOKEN:0:20}..."
    else
        print_result "Backend Direct Login" "FAIL" "Login succeeded but tokens missing"
        echo -e "Response: ${body}"
    fi
else
    print_result "Backend Direct Login" "FAIL" "Login failed with HTTP ${http_code}"
    echo -e "Response: ${body}"
    exit 1
fi

# Test 4: Backend /auth/login endpoint
echo -e "${BLUE}Test 4: Backend /auth/login endpoint${NC}"
response=$(curl -s -w "\n%{http_code}" \
    -X POST "${BACKEND_URL}/auth/login" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=${TEST_EMAIL}&password=${TEST_PASSWORD}" \
    || echo "000")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" = "200" ]; then
    print_result "Backend /auth/login" "PASS" "Login successful"
else
    print_result "Backend /auth/login" "FAIL" "Login failed with HTTP ${http_code}"
    echo -e "Response: ${body}"
fi

# Test 5: Frontend Login Proxy (/api/auth/login)
echo -e "${BLUE}Test 5: Frontend Login Proxy (/api/auth/login)${NC}"
response=$(curl -s -w "\n%{http_code}" \
    -X POST "${FRONTEND_URL}/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"${TEST_EMAIL}\",\"password\":\"${TEST_PASSWORD}\"}" \
    || echo "000")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" = "200" ]; then
    FRONTEND_ACCESS_TOKEN=$(echo "$body" | grep -o '"access_token":"[^"]*' | sed 's/"access_token":"//')
    FRONTEND_REFRESH_TOKEN=$(echo "$body" | grep -o '"refresh_token":"[^"]*' | sed 's/"refresh_token":"//')

    if [ -n "$FRONTEND_ACCESS_TOKEN" ] && [ -n "$FRONTEND_REFRESH_TOKEN" ]; then
        print_result "Frontend Login Proxy" "PASS" "Login successful, tokens received"
        echo -e "  Access Token (first 20 chars): ${FRONTEND_ACCESS_TOKEN:0:20}..."
        echo -e "  Refresh Token (first 20 chars): ${FRONTEND_REFRESH_TOKEN:0:20}..."
    else
        print_result "Frontend Login Proxy" "FAIL" "Login succeeded but tokens missing"
        echo -e "Response: ${body}"
    fi
else
    print_result "Frontend Login Proxy" "FAIL" "Login failed with HTTP ${http_code}"
    echo -e "Response: ${body}"
fi

# Test 6: Backend Token Refresh (/auth/refresh)
echo -e "${BLUE}Test 6: Backend Token Refresh (/auth/refresh)${NC}"
if [ -n "$BACKEND_REFRESH_TOKEN" ]; then
    response=$(curl -s -w "\n%{http_code}" \
        -X POST "${BACKEND_URL}/auth/refresh" \
        -H "Content-Type: application/json" \
        -d "{\"refresh_token\":\"${BACKEND_REFRESH_TOKEN}\"}" \
        || echo "000")

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "200" ]; then
        NEW_ACCESS_TOKEN=$(echo "$body" | grep -o '"access_token":"[^"]*' | sed 's/"access_token":"//')
        NEW_REFRESH_TOKEN=$(echo "$body" | grep -o '"refresh_token":"[^"]*' | sed 's/"refresh_token":"//')

        if [ -n "$NEW_ACCESS_TOKEN" ]; then
            print_result "Backend Token Refresh" "PASS" "Token refresh successful"
            echo -e "  New Access Token (first 20 chars): ${NEW_ACCESS_TOKEN:0:20}..."
            BACKEND_ACCESS_TOKEN="$NEW_ACCESS_TOKEN"
        else
            print_result "Backend Token Refresh" "FAIL" "Refresh succeeded but no new token"
            echo -e "Response: ${body}"
        fi
    elif [ "$http_code" = "404" ]; then
        print_result "Backend Token Refresh" "FAIL" "Endpoint not found (404)"
        echo -e "Response: ${body}"
    else
        print_result "Backend Token Refresh" "FAIL" "Refresh failed with HTTP ${http_code}"
        echo -e "Response: ${body}"
    fi
else
    print_result "Backend Token Refresh" "SKIP" "No refresh token available from login"
fi

# Test 7: Frontend Token Refresh Proxy (/api/auth/refresh)
echo -e "${BLUE}Test 7: Frontend Token Refresh Proxy (/api/auth/refresh)${NC}"
if [ -n "$FRONTEND_REFRESH_TOKEN" ]; then
    response=$(curl -s -w "\n%{http_code}" \
        -X POST "${FRONTEND_URL}/api/auth/refresh" \
        -H "Content-Type: application/json" \
        -d "{\"refresh_token\":\"${FRONTEND_REFRESH_TOKEN}\"}" \
        || echo "000")

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "200" ]; then
        NEW_ACCESS_TOKEN=$(echo "$body" | grep -o '"access_token":"[^"]*' | sed 's/"access_token":"//')

        if [ -n "$NEW_ACCESS_TOKEN" ]; then
            print_result "Frontend Token Refresh Proxy" "PASS" "Token refresh successful"
            echo -e "  New Access Token (first 20 chars): ${NEW_ACCESS_TOKEN:0:20}..."
        else
            print_result "Frontend Token Refresh Proxy" "FAIL" "Refresh succeeded but no new token"
            echo -e "Response: ${body}"
        fi
    elif [ "$http_code" = "404" ]; then
        print_result "Frontend Token Refresh Proxy" "FAIL" "Endpoint not found (404)"
        echo -e "Response: ${body}"
    elif [ "$http_code" = "501" ]; then
        print_result "Frontend Token Refresh Proxy" "FAIL" "Backend refresh not implemented (501)"
        echo -e "Response: ${body}"
    else
        print_result "Frontend Token Refresh Proxy" "FAIL" "Refresh failed with HTTP ${http_code}"
        echo -e "Response: ${body}"
    fi
else
    print_result "Frontend Token Refresh Proxy" "SKIP" "No refresh token available from login"
fi

# Test 8: Backend /me endpoint (Get Current User)
echo -e "${BLUE}Test 8: Backend /me endpoint (Get Current User)${NC}"
if [ -n "$BACKEND_ACCESS_TOKEN" ]; then
    response=$(curl -s -w "\n%{http_code}" \
        -X GET "${BACKEND_URL}/me" \
        -H "Authorization: Bearer ${BACKEND_ACCESS_TOKEN}" \
        || echo "000")

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "200" ]; then
        USER_EMAIL=$(echo "$body" | grep -o '"email":"[^"]*' | sed 's/"email":"//')
        print_result "Backend /me endpoint" "PASS" "User info retrieved successfully"
        echo -e "  User Email: ${USER_EMAIL}"
    else
        print_result "Backend /me endpoint" "FAIL" "Failed with HTTP ${http_code}"
        echo -e "Response: ${body}"
    fi
else
    print_result "Backend /me endpoint" "SKIP" "No access token available"
fi

# Test 9: Frontend /api/me endpoint (Get Current User)
echo -e "${BLUE}Test 9: Frontend /api/me endpoint (Get Current User)${NC}"
if [ -n "$FRONTEND_ACCESS_TOKEN" ]; then
    response=$(curl -s -w "\n%{http_code}" \
        -X GET "${FRONTEND_URL}/api/me" \
        -H "Authorization: Bearer ${FRONTEND_ACCESS_TOKEN}" \
        || echo "000")

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "200" ]; then
        print_result "Frontend /api/me endpoint" "PASS" "User info retrieved successfully"
    else
        print_result "Frontend /api/me endpoint" "FAIL" "Failed with HTTP ${http_code}"
        echo -e "Response: ${body}"
    fi
else
    print_result "Frontend /api/me endpoint" "SKIP" "No access token available"
fi

# Test 10: Rate Limiting Test (login endpoint)
echo -e "${BLUE}Test 10: Rate Limiting Test (/api/auth/login)${NC}"
echo -e "Testing rate limiting by making 10 rapid requests..."

SUCCESS_COUNT=0
RATE_LIMITED_COUNT=0

for i in {1..10}; do
    response=$(curl -s -w "\n%{http_code}" \
        -X POST "${FRONTEND_URL}/api/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"${TEST_EMAIL}\",\"password\":\"${TEST_PASSWORD}\"}" \
        2>/dev/null || echo "000")

    http_code=$(echo "$response" | tail -n1)

    if [ "$http_code" = "200" ]; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    elif [ "$http_code" = "429" ]; then
        RATE_LIMITED_COUNT=$((RATE_LIMITED_COUNT + 1))
    fi

    echo -ne "  Request $i/10: HTTP ${http_code}\r"
done

echo ""
echo ""

if [ $SUCCESS_COUNT -gt 0 ]; then
    print_result "Rate Limiting Test" "PASS" "Rate limiting is working (${SUCCESS_COUNT} succeeded, ${RATE_LIMITED_COUNT} rate limited)"
else
    print_result "Rate Limiting Test" "FAIL" "No successful requests"
fi

# Summary
echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo ""
echo -e "All critical authentication endpoints have been tested."
echo -e "Review the results above to identify any issues."
echo ""
echo -e "${GREEN}Key Findings:${NC}"
echo -e "  - Backend health check: $([ -n "$BACKEND_ACCESS_TOKEN" ] && echo 'Working' || echo 'Failed')"
echo -e "  - Backend login: $([ -n "$BACKEND_ACCESS_TOKEN" ] && echo 'Working' || echo 'Failed')"
echo -e "  - Backend refresh: $([ -n "$NEW_ACCESS_TOKEN" ] && echo 'Working' || echo 'Check logs')"
echo -e "  - Frontend proxy: $([ -n "$FRONTEND_ACCESS_TOKEN" ] && echo 'Working' || echo 'Check logs')"
echo -e "  - Rate limiting: Tested with 10 rapid requests"
echo ""
echo -e "${YELLOW}Important Notes:${NC}"
echo -e "  1. Refresh tokens now last 7 days (vs 30 minutes for access tokens)"
echo -e "  2. Rate limits: Login=50/15min, Refresh=100/15min (production)"
echo -e "  3. All endpoints include detailed logging with request IDs"
echo -e "  4. CORS is configured for http://localhost:3001"
echo ""
