# Quick Test Guide - Platform Admin Backend

## Prerequisites
- Backend running locally or deployed
- Database migrations applied
- Admin user credentials

## Quick Verification Commands

### 1. Check Router Registration
```bash
# Verify imports in main.py
grep "admin_platform_brands\|admin_platform_usage" /Users/cope/EnGardeHQ/production-backend/app/main.py

# Expected output:
# Line 151: admin_platform_brands,
# Line 152: admin_platform_usage
# Line 185: app.include_router(admin_platform_brands.router)
# Line 186: app.include_router(admin_platform_usage.router)
```

### 2. Test Python Imports
```bash
cd /Users/cope/EnGardeHQ/production-backend

# Test router imports (ignore DB warnings)
python3 -c "from app.routers import admin_platform_brands, admin_platform_usage; print('✓ Routers import successfully')"

# Test model imports
python3 -c "from app.models import platform_models, funnel_models; print('✓ Models import successfully')"

# Test scheduler
python3 -c "from app.services.funnel_sync_scheduler import FunnelSyncScheduler; print('✓ Scheduler imports successfully')"
```

### 3. Verify Files Exist
```bash
# Router files
ls -lh /Users/cope/EnGardeHQ/production-backend/app/routers/admin_platform_brands.py
ls -lh /Users/cope/EnGardeHQ/production-backend/app/routers/admin_platform_usage.py

# Model files
ls -lh /Users/cope/EnGardeHQ/production-backend/app/models/platform_models.py
ls -lh /Users/cope/EnGardeHQ/production-backend/app/models/funnel_models.py

# Scheduler
ls -lh /Users/cope/EnGardeHQ/production-backend/app/services/funnel_sync_scheduler.py

# Migrations
ls -lh /Users/cope/EnGardeHQ/production-backend/migrations/20260119_*.sql

# SignUp_Sync service
ls -lh /Users/cope/EnGardeHQ/signup-sync-service/app/main.py
```

### 4. Test API Endpoints (requires running server)

#### Get Admin Token
```bash
# Login as platform admin
TOKEN=$(curl -s -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@engarde.platform",
    "password": "EnGardePlatform2026!SecurePassword"
  }' | jq -r '.access_token')

echo "Token: $TOKEN"
```

#### Test Platform Brands
```bash
# List platform brands
curl -s http://localhost:8000/api/admin/platform/brands \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# Create test brand
curl -s -X POST http://localhost:8000/api/admin/platform/brands \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "brand_name": "Test Platform Brand",
    "purpose": "Testing platform brands API",
    "is_demo": true,
    "industry": "Technology"
  }' | jq '.'
```

#### Test Platform Usage
```bash
# Get user usage (daily view)
curl -s "http://localhost:8000/api/admin/platform/usage/users?view_mode=daily&limit=5" \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# Get monthly usage
curl -s "http://localhost:8000/api/admin/platform/usage/users?view_mode=monthly&limit=5" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

### 5. Test SignUp_Sync Service (if deployed)

```bash
# Health check
curl https://signup-sync-service-production.up.railway.app/health

# Test sync (requires service token)
SYNC_TOKEN="a2a278b63efe89893977f1a1ac7b8cb79ce653efea4b6d13d39d655d0bf7a79c"

# Get EasyAppointments sync status
curl -s https://signup-sync-service-production.up.railway.app/sync/status/easyappointments \
  -H "Authorization: Bearer $SYNC_TOKEN" | jq '.'

# Trigger manual sync
curl -s -X POST https://signup-sync-service-production.up.railway.app/sync/easyappointments \
  -H "Authorization: Bearer $SYNC_TOKEN" | jq '.'
```

### 6. Database Verification (after migrations)

```bash
# Check tables exist
psql $DATABASE_PUBLIC_URL -c "\dt platform_brands"
psql $DATABASE_PUBLIC_URL -c "\dt admin_usage_reports"
psql $DATABASE_PUBLIC_URL -c "\dt funnel_sources"
psql $DATABASE_PUBLIC_URL -c "\dt funnel_events"

# Verify platform user
psql $DATABASE_PUBLIC_URL -c "
  SELECT id, email, is_superuser, is_active
  FROM users
  WHERE email = 'admin@engarde.platform';
"

# Verify platform tenant
psql $DATABASE_PUBLIC_URL -c "
  SELECT id, name, slug, plan_tier
  FROM tenants
  WHERE slug = 'engarde-admin';
"

# Check funnel source
psql $DATABASE_PUBLIC_URL -c "
  SELECT id, name, source_type, is_active, auto_sync_enabled
  FROM funnel_sources
  WHERE source_type = 'easyappointments';
"
```

## Expected Results

### ✅ Success Indicators
1. All imports work without import errors (DB warnings are OK)
2. Routers appear in main.py at lines 151-152 and 185-186
3. API endpoints return 200 OK with admin token
4. Database tables exist after migration
5. Platform user and tenant exist in database
6. SignUp_Sync service returns healthy status

### ❌ Failure Indicators
1. ImportError or ModuleNotFoundError
2. Routers not found in main.py
3. API endpoints return 404 Not Found
4. Database tables missing after migration
5. SignUp_Sync service unreachable

## Troubleshooting

### Router not found in main.py
**Check:** Lines 151-152 for imports, lines 185-186 for registration
**Fix:** Add missing import/registration statements

### Import errors
**Check:** Missing dependencies in requirements.txt
**Fix:** `pip install -r requirements.txt`

### 401 Unauthorized on admin endpoints
**Check:** Token expired or user not admin
**Fix:** Re-login or verify user has `is_superuser=true`

### Database connection errors
**Check:** DATABASE_URL environment variable
**Fix:** Verify connection string is correct

### Scheduler not starting
**Check:** Environment variable `FUNNEL_SYNC_ENABLED`
**Fix:** Set to "true" to enable scheduler

## Full Test Script

Run all verification checks:
```bash
cd /Users/cope/EnGardeHQ

# Test imports
echo "Testing Python imports..."
cd production-backend
python3 -c "from app.routers import admin_platform_brands, admin_platform_usage; print('✓ Routers OK')"
python3 -c "from app.models import platform_models, funnel_models; print('✓ Models OK')"
python3 -c "from app.services.funnel_sync_scheduler import FunnelSyncScheduler; print('✓ Scheduler OK')"

# Verify registrations
echo "Checking router registration..."
grep -q "admin_platform_brands.router" app/main.py && echo "✓ Platform brands router registered"
grep -q "admin_platform_usage.router" app/main.py && echo "✓ Platform usage router registered"

# Check files
echo "Verifying files exist..."
test -f app/routers/admin_platform_brands.py && echo "✓ Platform brands router exists"
test -f app/routers/admin_platform_usage.py && echo "✓ Platform usage router exists"
test -f app/services/funnel_sync_scheduler.py && echo "✓ Scheduler service exists"
test -f migrations/20260119_seed_platform_user.sql && echo "✓ Migration files exist"

cd ..
test -d signup-sync-service && echo "✓ SignUp_Sync service directory exists"

echo ""
echo "✅ All backend components verified!"
```

## Next Steps After Verification

1. **If tests pass:** Deploy SignUp_Sync service and run migrations
2. **If tests fail:** Review error messages and fix issues
3. **After deployment:** Test live API endpoints
4. **Frontend:** Begin building admin dashboard pages
