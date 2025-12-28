# Tenant UUID Migration Guide

## Problem Summary

The backend was experiencing database errors due to an invalid tenant ID format:

```
ERROR: invalid input syntax for type uuid: "default-tenant-001"
WHERE usage_metrics.tenant_id = 'default-tenant-001'::UUID
```

### Root Cause
- The database had a tenant with ID `'default-tenant-001'` which is NOT a valid UUID
- PostgreSQL queries were attempting to cast this as a UUID, causing failures
- The `/api/storage/usage` endpoint and other tenant-related queries were failing

## Solution Implemented

### 1. Created UUID Constant (`app/constants/tenant_ids.py`)
```python
DEFAULT_TENANT_ID = "550e8400-e29b-41d4-a716-446655440000"
```

### 2. Updated Code References
Replaced all hardcoded `"default-tenant-001"` references with the constant in:
- ✅ `app/routers/campaigns.py` (4 occurrences)
- ✅ `app/routers/dashboard.py` (1 occurrence)
- ✅ `app/routers/marketplace_proxy.py` (1 occurrence)
- ✅ `app/routers/advertising.py` (1 occurrence)
- ✅ `app/routers/audience.py` (1 occurrence)
- ✅ `app/routers/maintenance.py` (3 occurrences)

### 3. Created Migration Script
Location: `production-backend/migrations/20251221_fix_default_tenant_uuid.sql`

## Migration Steps

### IMPORTANT: Follow these steps in order

### Step 1: Backup Database (CRITICAL!)
Before running the migration, create a backup of your Railway PostgreSQL database:

```bash
# Using Railway CLI
railway run pg_dump > backup_$(date +%Y%m%d_%H%M%S).sql

# Or via Railway dashboard
# Go to your PostgreSQL service > Data > Create Backup
```

### Step 2: Apply the SQL Migration

You have two options:

#### Option A: Via Railway Dashboard (Recommended)
1. Open your Railway project
2. Click on the PostgreSQL service
3. Go to the "Query" tab
4. Copy the contents of `production-backend/migrations/20251221_fix_default_tenant_uuid.sql`
5. Paste and execute
6. Verify the output shows success messages

#### Option B: Via psql Command Line
```bash
# Get your DATABASE_URL from Railway
railway variables | grep DATABASE_URL

# Run the migration
psql $DATABASE_URL -f production-backend/migrations/20251221_fix_default_tenant_uuid.sql
```

### Step 3: Verify Migration Success

Run these verification queries in Railway's Query tab:

```sql
-- Check tenant record has new UUID
SELECT id, name, slug
FROM tenants
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Verify no old tenant ID exists
SELECT COUNT(*) as should_be_zero
FROM tenants
WHERE id = 'default-tenant-001';

-- Check usage_metrics have been updated
SELECT COUNT(*) as migrated_records
FROM usage_metrics
WHERE tenant_id = '550e8400-e29b-41d4-a716-446655440000';

-- Check campaigns have been updated
SELECT COUNT(*) as migrated_records
FROM campaigns
WHERE tenant_id = '550e8400-e29b-41d4-a716-446655440000';
```

### Step 4: Deploy Updated Backend Code

The code changes have been made but need to be deployed:

```bash
# Navigate to production-backend submodule
cd production-backend

# Commit the changes
git add app/constants/ app/routers/
git commit -m "Fix: Migrate tenant ID to proper UUID format

- Add DEFAULT_TENANT_ID constant (550e8400-e29b-41d4-a716-446655440000)
- Replace all hardcoded 'default-tenant-001' references
- Fixes storage endpoint UUID casting errors"

# Push to trigger Railway deployment
git push origin main
```

### Step 5: Monitor Deployment

1. Watch Railway logs during deployment
2. Look for the backend service to restart successfully
3. Check that no UUID errors appear in logs

### Step 6: Test the Fixed Endpoint

After deployment, test the previously failing endpoint:

```bash
# Get an auth token (use your actual credentials)
TOKEN="your_jwt_token_here"

# Test storage endpoint
curl -H "Authorization: Bearer $TOKEN" \
     https://your-backend-url.railway.app/api/storage/usage

# Should return success instead of 500 error
```

## What the Migration Does

1. **Generates a proper UUID** for the default tenant
2. **Updates all foreign key references** in these tables:
   - usage_metrics
   - campaigns
   - brands
   - ai_agents
   - tenant_users
   - tenant_roles
   - hitl_approvals
   - conversations
   - tenant_subscriptions
   - workflow_definitions
   - workflow_executions
   - agent_insights
   - notifications
   - campaign_spaces
   - user_sessions
   - audit_logs
   - email_accounts
   - tenant_llm_keys

3. **Updates the tenant record itself** with the new UUID
4. **Maintains referential integrity** throughout the process

## Safety Features

- ✅ **Idempotent**: Safe to run multiple times
- ✅ **Transactional**: Uses deferred constraints for atomicity
- ✅ **Verified**: Includes verification queries
- ✅ **Logged**: Provides detailed NOTICE messages during execution

## Rollback Plan

If something goes wrong:

```bash
# Restore from backup
psql $DATABASE_URL < backup_YYYYMMDD_HHMMSS.sql

# Revert code changes
cd production-backend
git revert HEAD
git push origin main
```

## Expected Impact

### Before Migration
- ❌ `/api/storage/usage` returns 500 error
- ❌ Logs show UUID casting errors
- ❌ Storage metrics fail to load

### After Migration
- ✅ `/api/storage/usage` returns 200 success
- ✅ No UUID errors in logs
- ✅ Storage metrics load correctly
- ✅ All tenant-related queries work properly

## Future Tenant Creation

When creating new tenants in the future, they will automatically use proper UUIDs because the `Tenant` model already has:

```python
id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
```

The hardcoded 'default-tenant-001' was a legacy value that has now been properly migrated.

## Support

If you encounter issues:

1. Check Railway logs for detailed error messages
2. Verify the migration completed successfully with verification queries
3. Ensure the backend deployment succeeded
4. Check that DATABASE_URL environment variable is set correctly

## Files Modified

### New Files
- `app/constants/tenant_ids.py` - UUID constants
- `migrations/20251221_fix_default_tenant_uuid.sql` - Migration script
- `TENANT_UUID_MIGRATION_GUIDE.md` - This document

### Modified Files
- `app/routers/campaigns.py`
- `app/routers/dashboard.py`
- `app/routers/marketplace_proxy.py`
- `app/routers/advertising.py`
- `app/routers/audience.py`
- `app/routers/maintenance.py`

---

**Migration Created**: 2025-12-21
**Status**: Ready to execute
**Estimated Duration**: < 1 minute
**Risk Level**: Low (with backup)
