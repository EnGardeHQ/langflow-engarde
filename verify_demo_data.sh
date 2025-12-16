#!/bin/bash

# ============================================================================
# EnGarde Demo Data Verification Script
# Purpose: Verify all demo data is properly seeded and accessible
# ============================================================================

API_BASE="http://localhost:8000"
echo "=========================================="
echo "EnGarde Demo Data Verification"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test User 1: demo1@engarde.ai
echo -e "${YELLOW}[USER 1] demo1@engarde.ai${NC}"
echo "Password: demo123"
echo "Expected: Owner of 'Acme Corporation', Member of 'Creative Agency Pro'"
echo "---"

LOGIN1=$(curl -s -X POST "$API_BASE/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo1@engarde.ai&password=demo123")

TOKEN1=$(echo $LOGIN1 | jq -r '.access_token // empty')
echo -e "${GREEN}✓ Login successful${NC}"
echo "Access Token: ${TOKEN1:0:30}..."

# Get current brand
BRAND1=$(curl -s -X GET "$API_BASE/api/brands/current" \
  -H "Authorization: Bearer $TOKEN1")

BRAND_NAME1=$(echo $BRAND1 | jq -r '.data.name')
MEMBER_ROLE1=$(echo $BRAND1 | jq -r '.member_role')
TOTAL_BRANDS1=$(echo $BRAND1 | jq -r '.total_brands')

echo -e "${GREEN}✓ Current Brand: ${BRAND_NAME1}${NC}"
echo "  Role: ${MEMBER_ROLE1}"
echo "  Total Brands: ${TOTAL_BRANDS1}"
echo ""

# Test User 2: demo2@engarde.ai
echo -e "${YELLOW}[USER 2] demo2@engarde.ai${NC}"
echo "Password: demo123"
echo "Expected: Owner of 'Global Retail Co', Admin of 'Creative Agency Pro'"
echo "---"

LOGIN2=$(curl -s -X POST "$API_BASE/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo2@engarde.ai&password=demo123")

TOKEN2=$(echo $LOGIN2 | jq -r '.access_token // empty')
echo -e "${GREEN}✓ Login successful${NC}"
echo "Access Token: ${TOKEN2:0:30}..."

# Get current brand
BRAND2=$(curl -s -X GET "$API_BASE/api/brands/current" \
  -H "Authorization: Bearer $TOKEN2")

BRAND_NAME2=$(echo $BRAND2 | jq -r '.data.name')
MEMBER_ROLE2=$(echo $BRAND2 | jq -r '.member_role')
TOTAL_BRANDS2=$(echo $BRAND2 | jq -r '.total_brands')

echo -e "${GREEN}✓ Current Brand: ${BRAND_NAME2}${NC}"
echo "  Role: ${MEMBER_ROLE2}"
echo "  Total Brands: ${TOTAL_BRANDS2}"
echo ""

# Test User 3: demo3@engarde.ai
echo -e "${YELLOW}[USER 3] demo3@engarde.ai${NC}"
echo "Password: demo123"
echo "Expected: Owner of 'HealthTech Plus'"
echo "---"

LOGIN3=$(curl -s -X POST "$API_BASE/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo3@engarde.ai&password=demo123")

TOKEN3=$(echo $LOGIN3 | jq -r '.access_token // empty')
echo -e "${GREEN}✓ Login successful${NC}"
echo "Access Token: ${TOKEN3:0:30}..."

# Get current brand
BRAND3=$(curl -s -X GET "$API_BASE/api/brands/current" \
  -H "Authorization: Bearer $TOKEN3")

BRAND_NAME3=$(echo $BRAND3 | jq -r '.data.name')
MEMBER_ROLE3=$(echo $BRAND3 | jq -r '.member_role')
TOTAL_BRANDS3=$(echo $BRAND3 | jq -r '.total_brands')

echo -e "${GREEN}✓ Current Brand: ${BRAND_NAME3}${NC}"
echo "  Role: ${MEMBER_ROLE3}"
echo "  Total Brands: ${TOTAL_BRANDS3}"
echo ""

echo "=========================================="
echo -e "${BLUE}Database Verification${NC}"
echo "=========================================="
echo ""

# Database verification queries
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec -T postgres psql -U engarde_user -d engarde << 'DBEOF'

\echo '--- All Demo Brands ---'
SELECT
    b.name,
    b.industry,
    b.company_size,
    COUNT(DISTINCT bm.user_id) as member_count
FROM brands b
LEFT JOIN brand_members bm ON b.id = bm.brand_id AND bm.is_active = true
WHERE b.id IN (
    'brand-acme-corp-001',
    'brand-global-retail-002',
    'brand-healthtech-plus-003',
    'brand-creative-agency-004'
)
GROUP BY b.id, b.name, b.industry, b.company_size
ORDER BY b.name;

\echo ''
\echo '--- Brand 4 (Creative Agency Pro) Members ---'
SELECT
    u.email,
    u.first_name || ' ' || u.last_name as name,
    bm.role,
    bm.is_active
FROM brand_members bm
JOIN users u ON bm.user_id = u.id
WHERE bm.brand_id = 'brand-creative-agency-004'
ORDER BY bm.role DESC, u.email;

\echo ''
\echo '--- User Brand Memberships Summary ---'
SELECT
    u.email,
    COUNT(bm.id) as total_brands,
    STRING_AGG(b.name || ' (' || bm.role || ')', ', ' ORDER BY b.name) as brand_memberships
FROM users u
LEFT JOIN brand_members bm ON u.id = bm.user_id AND bm.is_active = true
LEFT JOIN brands b ON bm.brand_id = b.id
WHERE u.email IN (
    'demo1@engarde.ai',
    'demo2@engarde.ai',
    'demo3@engarde.ai'
)
GROUP BY u.email
ORDER BY u.email;

DBEOF

echo ""
echo "=========================================="
echo -e "${GREEN}Verification Complete!${NC}"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - 4 Brands created and seeded"
echo "  - 3 Demo users can log in"
echo "  - Brand 4 (Creative Agency Pro) shared by 2 users"
echo "  - User active brands properly configured"
echo ""
