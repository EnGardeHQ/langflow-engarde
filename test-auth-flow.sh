#!/bin/bash

# Authentication Flow Testing Script
# Tests login flow and identifies timing issues

set -e

echo "🔐 Authentication Flow Testing Script"
echo "======================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL="${BACKEND_URL:-http://localhost:3001}"
FRONTEND_URL="${FRONTEND_URL:-http://localhost:3000}"
TEST_EMAIL="${TEST_EMAIL:-demo@engarde.com}"
TEST_PASSWORD="${TEST_PASSWORD:-demo123}"

echo "Configuration:"
echo "- Backend URL: $BACKEND_URL"
echo "- Frontend URL: $FRONTEND_URL"
echo "- Test Email: $TEST_EMAIL"
echo ""

# Function to test backend health
test_backend_health() {
  echo "1. Testing Backend Health..."

  response=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/health" || echo "000")

  if [ "$response" = "200" ]; then
    echo -e "${GREEN}✅ Backend is healthy${NC}"
    return 0
  else
    echo -e "${RED}❌ Backend is not responding (HTTP $response)${NC}"
    echo "   Please ensure backend is running on $BACKEND_URL"
    return 1
  fi
}

# Function to test login endpoint
test_login_endpoint() {
  echo ""
  echo "2. Testing Login API Endpoint..."

  # Test direct backend login
  echo "   a) Testing backend /api/token endpoint..."

  response=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/api/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$TEST_EMAIL&password=$TEST_PASSWORD&grant_type=password")

  http_code=$(echo "$response" | tail -n 1)
  body=$(echo "$response" | head -n -1)

  if [ "$http_code" = "200" ]; then
    echo -e "   ${GREEN}✅ Backend login successful${NC}"

    # Parse response
    access_token=$(echo "$body" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
    user_email=$(echo "$body" | grep -o '"email":"[^"]*"' | cut -d'"' -f4)
    expires_in=$(echo "$body" | grep -o '"expires_in":[0-9]*' | cut -d':' -f2)

    echo "   - Access Token: ${access_token:0:20}..."
    echo "   - User Email: $user_email"
    echo "   - Expires In: ${expires_in}s"

    # Verify token
    if [ -n "$access_token" ] && [ -n "$user_email" ]; then
      echo -e "   ${GREEN}✅ Login response structure correct${NC}"
      return 0
    else
      echo -e "   ${RED}❌ Login response missing required fields${NC}"
      return 1
    fi
  else
    echo -e "   ${RED}❌ Backend login failed (HTTP $http_code)${NC}"
    echo "   Response: $body"
    return 1
  fi
}

# Function to test frontend API route
test_frontend_api_route() {
  echo ""
  echo "3. Testing Frontend API Route..."

  response=$(curl -s -w "\n%{http_code}" -X POST "$FRONTEND_URL/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

  http_code=$(echo "$response" | tail -n 1)
  body=$(echo "$response" | head -n -1)

  if [ "$http_code" = "200" ]; then
    echo -e "   ${GREEN}✅ Frontend API route successful${NC}"

    # Parse response
    access_token=$(echo "$body" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
    refresh_token=$(echo "$body" | grep -o '"refresh_token":"[^"]*"' | cut -d'"' -f4)

    echo "   - Access Token: ${access_token:0:20}..."
    echo "   - Refresh Token: ${refresh_token:0:20}..."

    if [ -n "$access_token" ] && [ -n "$refresh_token" ]; then
      echo -e "   ${GREEN}✅ Frontend API route returns correct format${NC}"
      return 0
    else
      echo -e "   ${YELLOW}⚠️  Frontend API route missing refresh_token${NC}"
      return 1
    fi
  else
    echo -e "   ${RED}❌ Frontend API route failed (HTTP $http_code)${NC}"
    echo "   Response: $body"
    return 1
  fi
}

# Function to measure timing
measure_auth_timing() {
  echo ""
  echo "4. Measuring Authentication Timing..."

  start_time=$(date +%s%3N)

  response=$(curl -s -w "\n%{http_code}" -X POST "$FRONTEND_URL/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

  end_time=$(date +%s%3N)
  duration=$((end_time - start_time))

  http_code=$(echo "$response" | tail -n 1)

  echo "   - Login Duration: ${duration}ms"

  if [ "$duration" -lt 500 ]; then
    echo -e "   ${GREEN}✅ Fast response (<500ms)${NC}"
  elif [ "$duration" -lt 1000 ]; then
    echo -e "   ${YELLOW}⚠️  Moderate response (500-1000ms)${NC}"
  else
    echo -e "   ${RED}❌ Slow response (>1000ms)${NC}"
  fi

  # Timing analysis for race condition
  echo ""
  echo "   Race Condition Window Analysis:"
  echo "   - AuthContext delay: 100ms"
  echo "   - ProtectedRoute grace period: 500ms"
  echo "   - Total artificial delay: 600ms"
  echo ""

  critical_window=$((duration + 600))

  if [ "$critical_window" -gt 1400 ]; then
    echo -e "   ${RED}⚠️  CRITICAL: Total time (${critical_window}ms) exceeds safe threshold${NC}"
    echo "   Race condition likely to occur!"
  else
    echo -e "   ${GREEN}✅ Total time (${critical_window}ms) within safe threshold${NC}"
  fi
}

# Function to check localStorage structure
check_localstorage_structure() {
  echo ""
  echo "5. Expected localStorage Structure:"
  echo ""
  echo "   After successful login, localStorage should contain:"
  echo ""
  echo "   a) Tokens (key: 'engarde_tokens'):"
  echo "   {"
  echo "     \"accessToken\": \"eyJ...\","
  echo "     \"refreshToken\": \"eyJ...\","
  echo "     \"expiresAt\": 1234567890"
  echo "   }"
  echo ""
  echo "   b) User (key: 'engarde_user'):"
  echo "   {"
  echo "     \"id\": \"user-id\","
  echo "     \"email\": \"$TEST_EMAIL\","
  echo "     \"firstName\": \"...\","
  echo "     \"lastName\": \"...\","
  echo "     \"userType\": \"advertiser\","
  echo "     \"isActive\": true,"
  echo "     \"cachedAt\": 1234567890"
  echo "   }"
  echo ""
  echo -e "   ${YELLOW}Use browser DevTools to verify after login${NC}"
}

# Function to explain the race condition
explain_race_condition() {
  echo ""
  echo "6. Race Condition Explanation:"
  echo ""
  echo "   The logout bug occurs when:"
  echo ""
  echo "   T=0ms    → User clicks Login"
  echo "   T=500ms  → Backend returns tokens"
  echo "   T=550ms  → Tokens stored ✅"
  echo "   T=600ms  → LOGIN_SUCCESS dispatched ✅"
  echo "   T=750ms  → Navigate to /dashboard (100ms delay)"
  echo "   T=850ms  → ProtectedRoute mounts"
  echo "   T=1350ms → Grace period expires (500ms)"
  echo "   T=1400ms → Auth check runs"
  echo "            → IF isAuthenticated=false (state not ready)"
  echo "            → Redirect to /login ❌"
  echo ""
  echo -e "   ${RED}PROBLEM:${NC} Fixed 500ms grace period doesn't guarantee state propagation"
  echo -e "   ${GREEN}SOLUTION:${NC} Remove artificial delays, use optimistic UI"
}

# Function to provide debugging tips
provide_debugging_tips() {
  echo ""
  echo "7. Debugging Tips:"
  echo ""
  echo "   To debug the logout issue:"
  echo ""
  echo "   a) Open browser DevTools Console"
  echo "   b) Filter logs by 'PROTECTED ROUTE' or 'AUTH CONTEXT'"
  echo "   c) Look for this sequence:"
  echo "      - '✅ Login successful'"
  echo "      - '🛡️ PROTECTED ROUTE: Auth check'"
  echo "      - '⏳ Waiting for grace period'"
  echo "      - '✅ Grace period ended'"
  echo "      - '🚫 Not authenticated' ← THE BUG"
  echo ""
  echo "   d) Check timing:"
  echo "      - If '🚫 Not authenticated' appears <1500ms after login"
  echo "      - Race condition confirmed"
  echo ""
  echo "   e) Verify localStorage:"
  echo "      - Check 'engarde_tokens' key exists"
  echo "      - Check 'engarde_user' key exists"
  echo "      - If present but still logged out = state propagation issue"
}

# Function to suggest fixes
suggest_fixes() {
  echo ""
  echo "8. Recommended Fixes:"
  echo ""
  echo "   Priority 1: Remove Artificial Delays"
  echo "   ────────────────────────────────────"
  echo "   File: components/auth/ProtectedRoute.tsx"
  echo "   Change: Remove lines 159, 174-180 (grace period)"
  echo ""
  echo "   File: contexts/AuthContext.tsx"
  echo "   Change: Remove line 641 (100ms navigation delay)"
  echo ""
  echo "   Priority 2: Add Optimistic UI"
  echo "   ─────────────────────────────"
  echo "   File: contexts/AuthContext.tsx"
  echo "   Add: sessionStorage.setItem('engarde_login_success', 'true')"
  echo ""
  echo "   File: components/auth/ProtectedRoute.tsx"
  echo "   Add: Check sessionStorage flag on mount"
  echo ""
  echo "   Priority 3: Add Tests"
  echo "   ─────────────────────"
  echo "   File: __tests__/auth-flow.test.tsx"
  echo "   Add: Integration test for login -> dashboard flow"
  echo ""
  echo -e "   ${GREEN}See AUTH_FLOW_ANALYSIS.md for detailed implementation${NC}"
}

# Main execution
main() {
  echo "Starting authentication flow tests..."
  echo ""

  # Run tests
  if test_backend_health; then
    test_login_endpoint
    test_frontend_api_route
    measure_auth_timing
  else
    echo ""
    echo -e "${RED}Cannot proceed with tests - backend is not available${NC}"
    echo "Please start the backend server and try again"
    exit 1
  fi

  # Provide additional information
  check_localstorage_structure
  explain_race_condition
  provide_debugging_tips
  suggest_fixes

  echo ""
  echo "======================================"
  echo -e "${GREEN}✅ Test script completed${NC}"
  echo ""
  echo "Next steps:"
  echo "1. Review the timing measurements above"
  echo "2. Follow debugging tips to confirm race condition"
  echo "3. Implement recommended fixes"
  echo "4. Test manually in browser"
  echo ""
}

# Run main function
main "$@"
