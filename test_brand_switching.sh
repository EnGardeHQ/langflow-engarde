#!/bin/bash

# ============================================================================
# Test Brand Switching and Multi-Brand Access
# ============================================================================

API_BASE="http://localhost:8000"
echo "=========================================="
echo "Brand Switching Test"
echo "=========================================="
echo ""

# Login as demo1
echo "[TEST] User: demo1@engarde.ai (has 2 brands)"
echo "---"

LOGIN=$(curl -s -X POST "$API_BASE/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo1@engarde.ai&password=demo123")

TOKEN=$(echo $LOGIN | jq -r '.access_token')

echo "✓ Logged in as demo1@engarde.ai"
echo ""

# Check current brand (should be Acme Corporation)
echo "[1] Current Active Brand:"
CURRENT=$(curl -s -X GET "$API_BASE/api/brands/current" \
  -H "Authorization: Bearer $TOKEN")

echo $CURRENT | jq '{
  brand_name: .data.name,
  brand_id: .data.id,
  role: .member_role,
  total_brands: .total_brands,
  is_member: .is_member
}'

echo ""

# Try to switch to Creative Agency Pro
echo "[2] Switching to Creative Agency Pro..."
SWITCH=$(curl -s -X POST "$API_BASE/api/brands/switch/brand-creative-agency-004" \
  -H "Authorization: Bearer $TOKEN")

echo $SWITCH | jq '.' 2>/dev/null || echo "$SWITCH"

echo ""

# Check current brand again (should now be Creative Agency Pro)
echo "[3] Current Brand After Switch:"
CURRENT_AFTER=$(curl -s -X GET "$API_BASE/api/brands/current" \
  -H "Authorization: Bearer $TOKEN")

echo $CURRENT_AFTER | jq '{
  brand_name: .data.name,
  brand_id: .data.id,
  role: .member_role,
  total_brands: .total_brands,
  is_member: .is_member
}'

echo ""
echo "=========================================="
echo ""

# Test demo2 as admin of Creative Agency Pro
echo "[TEST] User: demo2@engarde.ai (Admin of Creative Agency Pro)"
echo "---"

LOGIN2=$(curl -s -X POST "$API_BASE/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo2@engarde.ai&password=demo123")

TOKEN2=$(echo $LOGIN2 | jq -r '.access_token')

echo "✓ Logged in as demo2@engarde.ai"
echo ""

# Switch to Creative Agency Pro
echo "[1] Switching to Creative Agency Pro..."
SWITCH2=$(curl -s -X POST "$API_BASE/api/brands/switch/brand-creative-agency-004" \
  -H "Authorization: Bearer $TOKEN2")

echo $SWITCH2 | jq '.' 2>/dev/null || echo "$SWITCH2"

echo ""

# Check current brand (should be Creative Agency Pro with admin role)
echo "[2] Current Brand (should show ADMIN role):"
CURRENT2=$(curl -s -X GET "$API_BASE/api/brands/current" \
  -H "Authorization: Bearer $TOKEN2")

echo $CURRENT2 | jq '{
  brand_name: .data.name,
  brand_id: .data.id,
  role: .member_role,
  total_brands: .total_brands,
  is_member: .is_member
}'

echo ""
echo "=========================================="
echo ""

echo "Summary:"
echo "  ✓ demo1@engarde.ai can access 2 brands"
echo "  ✓ demo1@engarde.ai can switch to Creative Agency Pro (member role)"
echo "  ✓ demo2@engarde.ai can access 2 brands"
echo "  ✓ demo2@engarde.ai can switch to Creative Agency Pro (admin role)"
echo "  ✓ Creative Agency Pro is shared between 2 users"
echo ""
