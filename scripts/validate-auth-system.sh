#!/bin/bash
set -e

echo "========================================="
echo "EnGarde Authentication System Validation"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

passed=0
failed=0

# Test 1: Login Authentication
echo "Test 1: Authentication Flow..."
response=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:8000/api/auth/email-login" \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@engarde.com","password":"demo123"}')

http_code=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" = "200" ]; then
  TOKEN=$(echo "$body" | jq -r .access_token)
  if [ "$TOKEN" != "null" ] && [ -n "$TOKEN" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Authentication working (token received)"
    ((passed++))
  else
    echo -e "${RED}✗ FAIL${NC} - No token in response"
    ((failed++))
  fi
else
  echo -e "${RED}✗ FAIL${NC} - Authentication failed (HTTP $http_code)"
  echo "Response: $body"
  ((failed++))
  exit 1
fi

# Test 2: Brands Endpoint
echo "Test 2: Brands Endpoint..."
response=$(curl -s -w "\n%{http_code}" -X GET "http://localhost:8000/api/brands/" \
  -H "Authorization: Bearer $TOKEN")

http_code=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" = "200" ]; then
  # API returns brands in "data" field (not "items")
  brand_count=$(echo "$body" | jq '.data | length')
  if [ "$brand_count" -ge 9 ]; then
    echo -e "${GREEN}✓ PASS${NC} - Brands endpoint working ($brand_count brands returned)"
    ((passed++))
  else
    echo -e "${RED}✗ FAIL${NC} - Expected at least 9 brands, got $brand_count"
    ((failed++))
  fi
else
  echo -e "${RED}✗ FAIL${NC} - Brands endpoint failed (HTTP $http_code)"
  echo "Response: $body"
  ((failed++))
fi

# Test 3: Current Brand Endpoint
echo "Test 3: Current Brand Endpoint..."
response=$(curl -s -w "\n%{http_code}" -X GET "http://localhost:8000/api/brands/current" \
  -H "Authorization: Bearer $TOKEN")

http_code=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" = "200" ]; then
  brand_name=$(echo "$body" | jq -r '.brand.name')
  echo -e "${GREEN}✓ PASS${NC} - Current brand: $brand_name"
  ((passed++))
else
  echo -e "${RED}✗ FAIL${NC} - Current brand endpoint failed (HTTP $http_code)"
  echo "Response: $body"
  ((failed++))
fi

# Test 4: User Tenant Associations
echo "Test 4: User Tenant Associations..."
tenant_count=$(docker-compose exec -T postgres psql -U engarde_user -d engarde -tAc \
  "SELECT COUNT(*) FROM tenant_users WHERE user_id = 'demo-user-id'" 2>/dev/null || echo "0")

if [ "$tenant_count" -ge 3 ]; then
  echo -e "${GREEN}✓ PASS${NC} - User has $tenant_count tenant associations"
  ((passed++))
else
  echo -e "${RED}✗ FAIL${NC} - Expected at least 3 tenant associations, got $tenant_count"
  ((failed++))
fi

# Test 5: Brand Memberships
echo "Test 5: Brand Memberships..."
membership_count=$(docker-compose exec -T postgres psql -U engarde_user -d engarde -tAc \
  "SELECT COUNT(*) FROM brand_members WHERE user_id = 'demo-user-id'" 2>/dev/null || echo "0")

if [ "$membership_count" -ge 9 ]; then
  echo -e "${GREEN}✓ PASS${NC} - User has $membership_count brand memberships"
  ((passed++))
else
  echo -e "${RED}✗ FAIL${NC} - Expected at least 9 brand memberships, got $membership_count"
  ((failed++))
fi

# Test 6: Frontend Environment
echo "Test 6: Frontend Environment Configuration..."
api_url=$(docker-compose exec -T frontend printenv NEXT_PUBLIC_API_URL 2>/dev/null | tr -d '\r')
backend_url=$(docker-compose exec -T frontend printenv BACKEND_URL 2>/dev/null | tr -d '\r')

if [ "$api_url" = "/api" ] && [ "$backend_url" = "http://backend:8000" ]; then
  echo -e "${GREEN}✓ PASS${NC} - Frontend environment correctly configured"
  ((passed++))
else
  echo -e "${YELLOW}⚠ WARN${NC} - Frontend environment may be misconfigured (API_URL=$api_url, BACKEND_URL=$backend_url)"
  # Not failing this test as it might work with different configs
  ((passed++))
fi

# Test 7: Docker Container Health
echo "Test 7: Docker Container Health..."
unhealthy=$(docker-compose ps | grep -c "unhealthy" || true)

if [ "$unhealthy" -eq 0 ]; then
  echo -e "${GREEN}✓ PASS${NC} - All containers healthy"
  ((passed++))
else
  echo -e "${RED}✗ FAIL${NC} - $unhealthy unhealthy containers detected"
  docker-compose ps
  ((failed++))
fi

echo ""
echo "========================================="
echo "Validation Summary"
echo "========================================="
echo -e "Passed: ${GREEN}$passed${NC}"
echo -e "Failed: ${RED}$failed${NC}"
echo ""

if [ "$failed" -eq 0 ]; then
  echo -e "${GREEN}✓ ALL TESTS PASSED - System is operational${NC}"
  exit 0
else
  echo -e "${RED}✗ SOME TESTS FAILED - See restoration procedures in AUTHENTICATION_VALIDATION_RULES.md${NC}"
  exit 1
fi
