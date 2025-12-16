# Quick Fix Guide - PostgreSQL ENUM Conflict

## Problem
Railway deployment fails with: `type "platformtype" already exists`

## 5-Minute Fix (Most Common Case)

### Step 1: Connect to Railway Database
```bash
# Option A: Use Railway CLI
railway connect

# Option B: Get connection string and connect via psql
railway variables | grep DATABASE_URL
psql $DATABASE_URL
```

### Step 2: Check if Migration Already Complete
```sql
-- Check if ENUMs exist
SELECT typname FROM pg_type
WHERE typname IN ('platformtype', 'metrictype', 'culturalsegment', 'analyticsgranularity');

-- Should return 4 rows if ENUMs exist

-- Check if migration is recorded
SELECT version_num FROM alembic_version
WHERE version_num = 'advanced_analytics_001';

-- If this returns NO ROWS, proceed to Step 3
```

### Step 3: Mark Migration as Complete (SAFEST FIX)
```sql
-- This tells Alembic the migration already ran
INSERT INTO alembic_version (version_num)
VALUES ('advanced_analytics_001')
ON CONFLICT (version_num) DO NOTHING;
```

### Step 4: Redeploy
```bash
# Trigger a new deployment
git commit --allow-empty -m "Retry after ENUM fix"
git push railway main

# Or via Railway CLI
railway up
```

## Alternative: Use Automated Fix Script

```bash
# Set DATABASE_URL
export DATABASE_URL="your_railway_database_url"

# Run diagnostics
python scripts/diagnose_and_fix_enums.py --diagnose

# Auto-fix (safest option)
python scripts/diagnose_and_fix_enums.py --auto-fix

# Or specific fix
python scripts/diagnose_and_fix_enums.py --fix mark-complete
```

## If That Doesn't Work

### Option B: Clean State and Retry (DESTRUCTIVE)

**WARNING: This will delete analytics data!**

```sql
-- Drop tables in order
DROP TABLE IF EXISTS automated_insights CASCADE;
DROP TABLE IF EXISTS performance_benchmarks CASCADE;
DROP TABLE IF EXISTS report_executions CASCADE;
DROP TABLE IF EXISTS custom_reports CASCADE;
DROP TABLE IF EXISTS cultural_analytics CASCADE;
DROP TABLE IF EXISTS predictive_analyses CASCADE;
DROP TABLE IF EXISTS predictive_models CASCADE;
DROP TABLE IF EXISTS analytics_aggregations CASCADE;
DROP TABLE IF EXISTS analytics_data_points CASCADE;

-- Drop ENUMs
DROP TYPE IF EXISTS analyticsgranularity CASCADE;
DROP TYPE IF EXISTS culturalsegment CASCADE;
DROP TYPE IF EXISTS metrictype CASCADE;
DROP TYPE IF EXISTS platformtype CASCADE;

-- Remove migration record
DELETE FROM alembic_version WHERE version_num = 'advanced_analytics_001';

-- Now retry deployment
```

## Verification After Fix

```sql
-- Should return 1 row
SELECT version_num FROM alembic_version
WHERE version_num = 'advanced_analytics_001';

-- Should return 4 rows
SELECT typname FROM pg_type
WHERE typname IN ('platformtype', 'metrictype', 'culturalsegment', 'analyticsgranularity');

-- Should return 9 rows
SELECT tablename FROM pg_tables
WHERE schemaname = 'public'
  AND (tablename LIKE '%analytics%' OR tablename LIKE 'predictive_%'
       OR tablename LIKE 'custom_reports' OR tablename LIKE 'report_%'
       OR tablename LIKE 'performance_%' OR tablename LIKE 'automated_%');
```

## Still Having Issues?

1. **Check Railway logs** for other errors:
   ```bash
   railway logs
   ```

2. **Verify migration chain**:
   ```sql
   SELECT version_num, created_at FROM alembic_version ORDER BY created_at;
   ```

3. **Run full diagnostics**:
   ```bash
   python scripts/diagnose_and_fix_enums.py --diagnose
   ```

4. **Review comprehensive guide**:
   See `POSTGRESQL_ENUM_MIGRATION_FIX.md` for detailed solutions

## Contact Points

- Full documentation: `/Users/cope/EnGardeHQ/POSTGRESQL_ENUM_MIGRATION_FIX.md`
- Diagnostic script: `/Users/cope/EnGardeHQ/production-backend/scripts/diagnose_and_fix_enums.py`
- SQL fix script: `/Users/cope/EnGardeHQ/production-backend/scripts/fix_enum_conflict.sql`

## Prevention (For Future)

After fixing, consider implementing:

1. **Centralized ENUM creation** - Create ENUMs in one migration, reference in others
2. **Use `enum_utils.py`** - Safe ENUM management functions
3. **Single-instance deploys** - Configure Railway for sequential deployments
4. **Pre-deploy checks** - Run validation before migration

See comprehensive guide for details.
