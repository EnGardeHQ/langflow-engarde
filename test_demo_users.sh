#!/bin/bash

# ============================================================================
# EnGarde Demo Users Login & Brand Access Test Script
# Purpose: Test login and brand access for all demo users
# ============================================================================

API_BASE="http://localhost:8000"
echo "=========================================="
echo "EnGarde Demo Users Test Script"
echo "API Base URL: $API_BASE"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test User 1: demo1@engarde.ai
echo -e "${YELLOW}[TEST 1] User: demo1@engarde.ai${NC}"
echo "Expected: Owner of 'Acme Corporation', Member of 'Creative Agency Pro'"
echo "---"

LOGIN1=$(curl -s -X POST "$API_BASE/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo1@engarde.ai&password=demo123")

TOKEN1=$(echo $LOGIN1 | jq -r '.access_token // empty')

if [ -z "$TOKEN1" ]; then
  echo -e "${RED}FAILED: Login failed${NC}"
  echo "Response: $LOGIN1"
else
  echo -e "${GREEN}SUCCESS: Login successful${NC}"
  echo "Token: ${TOKEN1:0:50}..."

  # Test GET /api/brands/current
  echo ""
  echo "Testing GET /api/brands/current..."
  CURRENT_BRAND1=$(curl -s -X GET "$API_BASE/api/brands/current" \
    -H "Authorization: Bearer $TOKEN1")

  BRAND_NAME1=$(echo $CURRENT_BRAND1 | jq -r '.name // "ERROR"')
  echo "Current Brand: $BRAND_NAME1"
  echo "Full Response: $CURRENT_BRAND1" | jq '.' 2>/dev/null || echo "$CURRENT_BRAND1"
fi

echo ""
echo "=========================================="
echo ""

# Test User 2: demo2@engarde.ai
echo -e "${YELLOW}[TEST 2] User: demo2@engarde.ai${NC}"
echo "Expected: Owner of 'Global Retail Co', Admin of 'Creative Agency Pro'"
echo "---"

LOGIN2=$(curl -s -X POST "$API_BASE/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo2@engarde.ai&password=demo123")

TOKEN2=$(echo $LOGIN2 | jq -r '.access_token // empty')

if [ -z "$TOKEN2" ]; then
  echo -e "${RED}FAILED: Login failed${NC}"
  echo "Response: $LOGIN2"
else
  echo -e "${GREEN}SUCCESS: Login successful${NC}"
  echo "Token: ${TOKEN2:0:50}..."

  # Test GET /api/brands/current
  echo ""
  echo "Testing GET /api/brands/current..."
  CURRENT_BRAND2=$(curl -s -X GET "$API_BASE/api/brands/current" \
    -H "Authorization: Bearer $TOKEN2")

  BRAND_NAME2=$(echo $CURRENT_BRAND2 | jq -r '.name // "ERROR"')
  echo "Current Brand: $BRAND_NAME2"
  echo "Full Response: $CURRENT_BRAND2" | jq '.' 2>/dev/null || echo "$CURRENT_BRAND2"
fi

echo ""
echo "=========================================="
echo ""

# Test User 3: demo3@engarde.ai
echo -e "${YELLOW}[TEST 3] User: demo3@engarde.ai${NC}"
echo "Expected: Owner of 'HealthTech Plus'"
echo "---"

LOGIN3=$(curl -s -X POST "$API_BASE/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo3@engarde.ai&password=demo123")

TOKEN3=$(echo $LOGIN3 | jq -r '.access_token // empty')

if [ -z "$TOKEN3" ]; then
  echo -e "${RED}FAILED: Login failed${NC}"
  echo "Response: $LOGIN3"
else
  echo -e "${GREEN}SUCCESS: Login successful${NC}"
  echo "Token: ${TOKEN3:0:50}..."

  # Test GET /api/brands/current
  echo ""
  echo "Testing GET /api/brands/current..."
  CURRENT_BRAND3=$(curl -s -X GET "$API_BASE/api/brands/current" \
    -H "Authorization: Bearer $TOKEN3")

  BRAND_NAME3=$(echo $CURRENT_BRAND3 | jq -r '.name // "ERROR"')
  echo "Current Brand: $BRAND_NAME3"
  echo "Full Response: $CURRENT_BRAND3" | jq '.' 2>/dev/null || echo "$CURRENT_BRAND3"
fi

echo ""
echo "=========================================="
echo ""

# Test Brand 4 (Creative Agency Pro) - Verify 2 members
echo -e "${YELLOW}[TEST 4] Verify Brand 4 'Creative Agency Pro' has 2 members${NC}"
echo "Expected: demo1@engarde.ai (member), demo2@engarde.ai (admin)"
echo "---"

if [ ! -z "$TOKEN2" ]; then
  # Use demo2's token (admin of Creative Agency Pro)
  echo "Fetching team members for Creative Agency Pro..."

  # First, switch to Creative Agency Pro brand
  SWITCH_BRAND=$(curl -s -X POST "$API_BASE/api/brands/switch/brand-creative-agency-004" \
    -H "Authorization: Bearer $TOKEN2")

  echo "Switch brand response: $SWITCH_BRAND" | jq '.' 2>/dev/null || echo "$SWITCH_BRAND"

  # Try to get brand members (endpoint may vary)
  MEMBERS=$(curl -s -X GET "$API_BASE/api/brands/current/members" \
    -H "Authorization: Bearer $TOKEN2")

  echo "Team Members Response:"
  echo "$MEMBERS" | jq '.' 2>/dev/null || echo "$MEMBERS"
else
  echo -e "${RED}SKIPPED: No valid token for demo2@engarde.ai${NC}"
fi

echo ""
echo "=========================================="
echo ""

# Summary
echo -e "${YELLOW}[SUMMARY]${NC}"
echo "---"
if [ ! -z "$TOKEN1" ]; then
  echo -e "${GREEN}✓${NC} demo1@engarde.ai can log in (Brand: $BRAND_NAME1)"
else
  echo -e "${RED}✗${NC} demo1@engarde.ai login failed"
fi

if [ ! -z "$TOKEN2" ]; then
  echo -e "${GREEN}✓${NC} demo2@engarde.ai can log in (Brand: $BRAND_NAME2)"
else
  echo -e "${RED}✗${NC} demo2@engarde.ai login failed"
fi

if [ ! -z "$TOKEN3" ]; then
  echo -e "${GREEN}✓${NC} demo3@engarde.ai can log in (Brand: $BRAND_NAME3)"
else
  echo -e "${RED}✗${NC} demo3@engarde.ai login failed"
fi

echo ""
echo "=========================================="
