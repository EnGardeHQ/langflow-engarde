# Authentication & Brands Endpoint Validation Rules

**Last Verified**: 2025-11-03
**Status**: ✅ PASSING - All systems operational

## Purpose

This document defines validation rules and restoration procedures to ensure the authentication and brands endpoint functionality remains constant. If authentication breaks, follow the restoration procedure at the bottom.

---

## 1. Core Validation Rules

### Rule 1.1: Authentication Flow Must Work End-to-End

**Validation Test**:
```bash
# Test login and token generation
curl -s -X POST "http://localhost:8000/api/auth/email-login" \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@engarde.com","password":"demo123"}' | jq .

# Expected: 200 OK with access_token, refresh_token, and user object
```

**Success Criteria**:
- HTTP 200 OK
- Response contains `access_token` (JWT)
- Response contains `user.id` = "demo-user-id"
- Response contains `user.email` = "demo@engarde.com"
- Token expiry = 1800 seconds (30 minutes)

**Failure Actions**: See [Restoration Procedure - Auth Failure](#restoration-procedure---auth-failure)

---

### Rule 1.2: User-Brand Relationships Must Be Intact

**Validation Test**:
```bash
# Get fresh token
TOKEN=$(curl -s -X POST "http://localhost:8000/api/auth/email-login" \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@engarde.com","password":"demo123"}' | jq -r .access_token)

# Test brands endpoint
curl -s -X GET "http://localhost:8000/api/brands/" \
  -H "Authorization: Bearer $TOKEN" | jq .

# Expected: 200 OK with array of brands
```

**Success Criteria**:
- HTTP 200 OK
- Response contains `items` array with at least 9 brands
- Each brand has `id`, `name`, `tenant_id`
- Demo user has brands from multiple tenants (default-tenant, tenant-demo-main, tenant-shared)

**Failure Actions**: See [Restoration Procedure - Brands Endpoint Failure](#restoration-procedure---brands-endpoint-failure)

---

### Rule 1.3: Multi-Tenant Architecture Must Function Correctly

**Validation Test**:
```bash
# Check user's tenant associations
docker-compose exec postgres psql -U engarde_user -d engarde -c \
  "SELECT u.id, u.email, array_agg(tu.tenant_id) as tenants
   FROM users u
   LEFT JOIN tenant_users tu ON u.id = tu.user_id
   WHERE u.email = 'demo@engarde.com'
   GROUP BY u.id, u.email;"
```

**Success Criteria**:
- Demo user has 3 tenant associations: `{default-tenant, tenant-demo-main, tenant-shared}`
- All tenant_users foreign keys are valid
- No orphaned tenant_users records

**Failure Actions**: See [Restoration Procedure - Tenant Relationship Failure](#restoration-procedure---tenant-relationship-failure)

---

### Rule 1.4: Brand Memberships Must Be Established

**Validation Test**:
```bash
# Check brand memberships
docker-compose exec postgres psql -U engarde_user -d engarde -c \
  "SELECT bm.user_id, bm.brand_id, bm.role, b.name
   FROM brand_members bm
   JOIN brands b ON bm.brand_id = b.id
   WHERE bm.user_id = 'demo-user-id'
   ORDER BY b.name;"
```

**Success Criteria**:
- Demo user has 9 brand memberships
- Memberships include roles: owner (8 brands), admin (1 brand)
- All brand_members foreign keys are valid
- No duplicate memberships for same user+brand

**Failure Actions**: See [Restoration Procedure - Brand Membership Failure](#restoration-procedure---brand-membership-failure)

---

### Rule 1.5: Database Schema Must Match Models

**Validation Test**:
```bash
# Check table structure
docker-compose exec postgres psql -U engarde_user -d engarde -c \
  "\d users" | grep -E "tenant_id|id|email"
```

**Success Criteria**:
- Users table does NOT have a `tenant_id` column (tenant relationship is via junction table)
- Users table has: `id`, `email`, `hashed_password`, `first_name`, `last_name`, `is_active`
- Brands table HAS a `tenant_id` column
- Junction table `tenant_users` exists with proper foreign keys

**Failure Actions**: See [Restoration Procedure - Schema Mismatch](#restoration-procedure---schema-mismatch)

---

### Rule 1.6: Frontend Environment Configuration Must Be Correct

**Validation Test**:
```bash
# Check frontend environment variables
docker-compose exec frontend printenv | grep -E "NEXT_PUBLIC_API_URL|BACKEND_URL|DOCKER_CONTAINER"
```

**Success Criteria**:
- `NEXT_PUBLIC_API_URL=/api` (relative paths for browser)
- `BACKEND_URL=http://backend:8000` (Docker internal network for server-side)
- `DOCKER_CONTAINER=true` (enables Docker detection)

**Failure Actions**: See [Restoration Procedure - Environment Config Failure](#restoration-procedure---environment-config-failure)

---

### Rule 1.7: Backend CORS Must Allow Frontend Origin

**Validation Test**:
```bash
# Check CORS configuration
docker-compose exec backend printenv | grep CORS_ORIGINS
```

**Success Criteria**:
- CORS_ORIGINS includes: `http://localhost:3000`, `http://localhost:3001`, `http://frontend:3000`
- CORS_ALLOW_CREDENTIALS is true

**Failure Actions**: See [Restoration Procedure - CORS Failure](#restoration-procedure---cors-failure)

---

## 2. Automated Validation Script

Save this script as `/Users/cope/EnGardeHQ/scripts/validate-auth-system.sh`:

```bash
#!/bin/bash
set -e

echo "========================================="
echo "EnGarde Authentication System Validation"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

passed=0
failed=0

# Test 1: Login Authentication
echo "Test 1: Authentication Flow..."
response=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:8000/api/auth/email-login" \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@engarde.com","password":"demo123"}')

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

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
  ((failed++))
  exit 1
fi

# Test 2: Brands Endpoint
echo "Test 2: Brands Endpoint..."
response=$(curl -s -w "\n%{http_code}" -X GET "http://localhost:8000/api/brands/" \
  -H "Authorization: Bearer $TOKEN")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "200" ]; then
  brand_count=$(echo "$body" | jq '.items | length')
  if [ "$brand_count" -ge 9 ]; then
    echo -e "${GREEN}✓ PASS${NC} - Brands endpoint working ($brand_count brands returned)"
    ((passed++))
  else
    echo -e "${RED}✗ FAIL${NC} - Expected at least 9 brands, got $brand_count"
    ((failed++))
  fi
else
  echo -e "${RED}✗ FAIL${NC} - Brands endpoint failed (HTTP $http_code)"
  ((failed++))
fi

# Test 3: Current Brand Endpoint
echo "Test 3: Current Brand Endpoint..."
response=$(curl -s -w "\n%{http_code}" -X GET "http://localhost:8000/api/brands/current" \
  -H "Authorization: Bearer $TOKEN")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "200" ]; then
  brand_name=$(echo "$body" | jq -r '.brand.name')
  echo -e "${GREEN}✓ PASS${NC} - Current brand: $brand_name"
  ((passed++))
else
  echo -e "${RED}✗ FAIL${NC} - Current brand endpoint failed (HTTP $http_code)"
  ((failed++))
fi

# Test 4: User Tenant Associations
echo "Test 4: User Tenant Associations..."
tenant_count=$(docker-compose exec -T postgres psql -U engarde_user -d engarde -tAc \
  "SELECT COUNT(*) FROM tenant_users WHERE user_id = 'demo-user-id'")

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
  "SELECT COUNT(*) FROM brand_members WHERE user_id = 'demo-user-id'")

if [ "$membership_count" -ge 9 ]; then
  echo -e "${GREEN}✓ PASS${NC} - User has $membership_count brand memberships"
  ((passed++))
else
  echo -e "${RED}✗ FAIL${NC} - Expected at least 9 brand memberships, got $membership_count"
  ((failed++))
fi

# Test 6: Frontend Environment
echo "Test 6: Frontend Environment Configuration..."
api_url=$(docker-compose exec -T frontend printenv NEXT_PUBLIC_API_URL)
backend_url=$(docker-compose exec -T frontend printenv BACKEND_URL)

if [ "$api_url" = "/api" ] && [ "$backend_url" = "http://backend:8000" ]; then
  echo -e "${GREEN}✓ PASS${NC} - Frontend environment correctly configured"
  ((passed++))
else
  echo -e "${RED}✗ FAIL${NC} - Frontend environment misconfigured (API_URL=$api_url, BACKEND_URL=$backend_url)"
  ((failed++))
fi

# Test 7: Docker Container Health
echo "Test 7: Docker Container Health..."
unhealthy=$(docker-compose ps | grep -c "unhealthy" || true)

if [ "$unhealthy" -eq 0 ]; then
  echo -e "${GREEN}✓ PASS${NC} - All containers healthy"
  ((passed++))
else
  echo -e "${RED}✗ FAIL${NC} - $unhealthy unhealthy containers detected"
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
```

**Usage**:
```bash
chmod +x /Users/cope/EnGardeHQ/scripts/validate-auth-system.sh
./scripts/validate-auth-system.sh
```

---

## 3. Restoration Procedures

### Restoration Procedure - Auth Failure

**Symptoms**: Login endpoint returns 401, 500, or no token

**Diagnostic Steps**:
```bash
# Check if demo user exists
docker-compose exec postgres psql -U engarde_user -d engarde -c \
  "SELECT id, email, is_active FROM users WHERE email='demo@engarde.com';"

# Check backend logs
docker-compose logs backend --tail=50 | grep -i "auth\|error"
```

**Fix**:
```bash
# 1. Verify user exists with correct password hash
# 2. Re-run database seeding if user missing
bash scripts/seed-database.sh

# 3. Restart backend
docker-compose restart backend

# 4. Verify fix
curl -s -X POST "http://localhost:8000/api/auth/email-login" \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@engarde.com","password":"demo123"}' | jq .
```

---

### Restoration Procedure - Brands Endpoint Failure

**Symptoms**: GET /api/brands/ returns 500, 404, or empty array

**Diagnostic Steps**:
```bash
# Check if brands exist
docker-compose exec postgres psql -U engarde_user -d engarde -c \
  "SELECT COUNT(*) FROM brands;"

# Check if brand_members exist
docker-compose exec postgres psql -U engarde_user -d engarde -c \
  "SELECT COUNT(*) FROM brand_members WHERE user_id='demo-user-id';"

# Check backend logs
docker-compose logs backend --tail=50 | grep -i "brands\|error"
```

**Fix**:
```bash
# 1. Re-run database seeding
bash scripts/seed-database.sh

# 2. Verify brand memberships were created
docker-compose exec postgres psql -U engarde_user -d engarde -c \
  "SELECT bm.user_id, b.name, bm.role
   FROM brand_members bm
   JOIN brands b ON bm.brand_id = b.id
   WHERE bm.user_id = 'demo-user-id';"

# 3. Restart backend
docker-compose restart backend

# 4. Test endpoint
TOKEN=$(curl -s -X POST "http://localhost:8000/api/auth/email-login" \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@engarde.com","password":"demo123"}' | jq -r .access_token)

curl -s -X GET "http://localhost:8000/api/brands/" \
  -H "Authorization: Bearer $TOKEN" | jq .
```

---

### Restoration Procedure - Tenant Relationship Failure

**Symptoms**: User cannot access brands, tenant_id is null

**Diagnostic Steps**:
```bash
# Check tenant_users table
docker-compose exec postgres psql -U engarde_user -d engarde -c \
  "SELECT * FROM tenant_users WHERE user_id='demo-user-id';"

# Verify tenants exist
docker-compose exec postgres psql -U engarde_user -d engarde -c \
  "SELECT id, name FROM tenants ORDER BY id;"
```

**Fix**:
```bash
# 1. Manual tenant association repair (if needed)
docker-compose exec postgres psql -U engarde_user -d engarde << EOF
INSERT INTO tenant_users (tenant_id, user_id, role, is_active, joined_at)
VALUES
  ('default-tenant', 'demo-user-id', 'owner', true, NOW()),
  ('tenant-demo-main', 'demo-user-id', 'owner', true, NOW()),
  ('tenant-shared', 'demo-user-id', 'admin', true, NOW())
ON CONFLICT (tenant_id, user_id) DO NOTHING;
EOF

# 2. Verify fix
docker-compose exec postgres psql -U engarde_user -d engarde -c \
  "SELECT tenant_id, role FROM tenant_users WHERE user_id='demo-user-id';"

# 3. Restart backend
docker-compose restart backend
```

---

### Restoration Procedure - Brand Membership Failure

**Symptoms**: Brands exist but user cannot see them

**Diagnostic Steps**:
```bash
# Check if memberships exist
docker-compose exec postgres psql -U engarde_user -d engarde -c \
  "SELECT COUNT(*) FROM brand_members WHERE user_id='demo-user-id';"

# Check if brands exist without memberships
docker-compose exec postgres psql -U engarde_user -d engarde -c \
  "SELECT b.id, b.name FROM brands b
   WHERE NOT EXISTS (
     SELECT 1 FROM brand_members bm
     WHERE bm.brand_id = b.id AND bm.user_id='demo-user-id'
   );"
```

**Fix**:
```bash
# 1. Re-create brand memberships
docker-compose exec postgres psql -U engarde_user -d engarde << EOF
-- Link demo user to all brands
INSERT INTO brand_members (brand_id, user_id, role, is_active, joined_at)
SELECT b.id, 'demo-user-id', 'owner', true, NOW()
FROM brands b
WHERE b.tenant_id IN ('default-tenant', 'tenant-demo-main')
AND NOT EXISTS (
  SELECT 1 FROM brand_members bm
  WHERE bm.brand_id = b.id AND bm.user_id = 'demo-user-id'
);

-- Add shared brand with admin role
INSERT INTO brand_members (brand_id, user_id, role, is_active, joined_at)
SELECT b.id, 'demo-user-id', 'admin', true, NOW()
FROM brands b
WHERE b.tenant_id = 'tenant-shared'
AND NOT EXISTS (
  SELECT 1 FROM brand_members bm
  WHERE bm.brand_id = b.id AND bm.user_id = 'demo-user-id'
);
EOF

# 2. Verify memberships
docker-compose exec postgres psql -U engarde_user -d engarde -c \
  "SELECT COUNT(*) FROM brand_members WHERE user_id='demo-user-id';"

# 3. Restart backend
docker-compose restart backend
```

---

### Restoration Procedure - Schema Mismatch

**Symptoms**: SQLAlchemy errors about missing columns, wrong table structure

**Diagnostic Steps**:
```bash
# Check if Users table incorrectly has tenant_id column
docker-compose exec postgres psql -U engarde_user -d engarde -c \
  "\d users" | grep tenant_id

# Check Alembic migration status
docker-compose exec backend alembic current
docker-compose exec backend alembic history
```

**Fix**:
```bash
# 1. If migrations are out of sync, reset to head
docker-compose exec backend alembic upgrade head

# 2. If Users table has incorrect tenant_id column (it shouldn't), drop it
# WARNING: This should NOT be necessary - validate before running
docker-compose exec postgres psql -U engarde_user -d engarde << EOF
-- Only run if Users.tenant_id column exists (it shouldn't)
-- ALTER TABLE users DROP COLUMN IF EXISTS tenant_id;
EOF

# 3. Verify schema matches models
docker-compose exec postgres psql -U engarde_user -d engarde -c "\d users"
docker-compose exec postgres psql -U engarde_user -d engarde -c "\d brands"
docker-compose exec postgres psql -U engarde_user -d engarde -c "\d tenant_users"
docker-compose exec postgres psql -U engarde_user -d engarde -c "\d brand_members"

# 4. Restart backend
docker-compose restart backend
```

---

### Restoration Procedure - Environment Config Failure

**Symptoms**: ERR_NAME_NOT_RESOLVED, 503 errors, requests to http://backend:8000 from browser

**Diagnostic Steps**:
```bash
# Check frontend environment variables
docker-compose exec frontend printenv | grep -E "NEXT_PUBLIC_API_URL|BACKEND_URL"

# Check docker-compose.dev.yml
grep -A 10 "NEXT_PUBLIC_API_URL" docker-compose.dev.yml
```

**Fix**:
```bash
# 1. Edit docker-compose.dev.yml
# Ensure these environment variables are set in frontend service:
#   NEXT_PUBLIC_API_URL: /api
#   BACKEND_URL: http://backend:8000
#   DOCKER_CONTAINER: "true"

# 2. Rebuild frontend container (required to clear webpack cache)
docker-compose stop frontend
docker-compose rm -f frontend
docker-compose build --no-cache frontend
docker-compose up -d frontend

# 3. Verify environment variables
docker-compose exec frontend printenv | grep -E "NEXT_PUBLIC_API_URL|BACKEND_URL"

# 4. Check browser console - should see relative /api requests
# Open http://localhost:3000 in browser and check Network tab
```

---

### Restoration Procedure - CORS Failure

**Symptoms**: CORS errors in browser console, preflight OPTIONS requests failing

**Diagnostic Steps**:
```bash
# Check CORS configuration
docker-compose exec backend printenv | grep CORS

# Test CORS headers
curl -i -X OPTIONS "http://localhost:8000/api/brands/" \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: GET"
```

**Fix**:
```bash
# 1. Edit docker-compose.dev.yml
# Ensure CORS_ORIGINS includes all frontend origins:
#   CORS_ORIGINS: '["http://localhost:3000","http://localhost:3001","http://frontend:3000"]'
#   CORS_ALLOW_CREDENTIALS: "true"

# 2. Restart backend
docker-compose restart backend

# 3. Verify CORS headers in response
curl -i -X GET "http://localhost:8000/api/health" \
  -H "Origin: http://localhost:3000"

# Expected headers:
# access-control-allow-origin: http://localhost:3000
# access-control-allow-credentials: true
```

---

## 4. Complete System Reset (Nuclear Option)

**Use this only if all other restoration procedures fail**

```bash
#!/bin/bash
echo "⚠️  WARNING: This will delete all Docker containers, volumes, and rebuild from scratch"
read -p "Are you sure? (type 'yes' to continue): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Cancelled"
  exit 0
fi

# 1. Stop and remove all containers
docker-compose down -v

# 2. Remove all volumes (THIS DELETES ALL DATA)
docker volume prune -f

# 3. Rebuild all containers
docker-compose build --no-cache

# 4. Start services
docker-compose up -d

# 5. Wait for services to be healthy
echo "Waiting for services to become healthy..."
sleep 30

# 6. Run database migrations
docker-compose exec backend alembic upgrade head

# 7. Seed database
bash scripts/seed-database.sh

# 8. Validate system
bash scripts/validate-auth-system.sh
```

---

## 5. Monitoring & Alerting

**Recommended Monitoring**:
- Run validation script daily via cron
- Monitor Docker container health
- Track authentication success/failure rates
- Alert on brands endpoint 500 errors

**Cron Job Example**:
```bash
# Add to crontab
0 9 * * * /Users/cope/EnGardeHQ/scripts/validate-auth-system.sh >> /Users/cope/EnGardeHQ/logs/validation.log 2>&1
```

---

## 6. Version History

| Date | Status | Notes |
|------|--------|-------|
| 2025-11-03 | ✅ PASSING | Initial validation - all systems operational |

---

**Document Maintained By**: Claude Code
**Last Validation**: 2025-11-03
**Next Validation Due**: 2025-11-04
