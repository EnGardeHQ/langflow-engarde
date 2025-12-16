# PostgreSQL ENUM Migration Conflict - Comprehensive Solution Guide

## Problem Analysis

### Root Cause
The error `type "platformtype" already exists` occurs because:

1. **Multiple migrations create the same ENUM**: Both `advanced_analytics_system.py` and `20251010_create_missing_analytics_webhook_tables.py` attempt to create the same ENUM types (`platformtype`, `metrictype`, `culturalsegment`, `analyticsgranularity`)

2. **Different ENUM creation patterns**:
   - `advanced_analytics_system.py` uses the less safe approach with `DO $$ BEGIN... EXCEPTION WHEN duplicate_object`
   - `20251010_create_missing_analytics_webhook_tables.py` uses `IF NOT EXISTS` check which is more reliable

3. **Railway deployment context**: Multiple concurrent deployments or restarts can trigger race conditions where both migrations attempt to create ENUMs simultaneously

4. **Migration chain issue**: The migration `20251010_missing_tables` has `down_revision = 'advanced_analytics_001'`, creating a dependency that might cause re-execution

---

## Solution 1: IMMEDIATE FIX (Deploy Now)

### Option A: Manual Database Cleanup + Migration Retry

**Step 1: Connect to Railway PostgreSQL Database**
```bash
# Get Railway database connection string
railway variables | grep DATABASE_URL

# Or connect directly via Railway CLI
railway connect
```

**Step 2: Check Current Migration State**
```sql
-- Check which migrations have been applied
SELECT version_num, TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') as applied_at
FROM alembic_version
ORDER BY created_at DESC;

-- Check if ENUMs exist
SELECT typname, typnamespace::regnamespace AS schema
FROM pg_type
WHERE typname IN ('platformtype', 'metrictype', 'culturalsegment', 'analyticsgranularity');

-- Check if analytics tables exist
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('analytics_data_points', 'analytics_aggregations',
                    'cultural_analytics', 'predictive_analyses',
                    'automated_insights', 'performance_benchmarks');
```

**Step 3A: If ENUMs exist but migration failed (recommended)**
```sql
-- This is the safest option - just mark the migration as complete
-- The ENUMs and tables already exist from the previous migration

-- First verify the advanced_analytics_001 migration is recorded
SELECT version_num FROM alembic_version WHERE version_num = 'advanced_analytics_001';

-- If it's there, the database state is correct, deployment should succeed on retry
-- Railway may have stopped mid-migration due to timeout

-- If not there, add it manually (ONLY if tables/ENUMs exist):
INSERT INTO alembic_version (version_num)
VALUES ('advanced_analytics_001')
ON CONFLICT (version_num) DO NOTHING;
```

**Step 3B: If ENUMs exist but tables are missing**
```sql
-- Check which tables from advanced_analytics_001 are missing
SELECT table_name
FROM (VALUES
    ('analytics_data_points'),
    ('analytics_aggregations'),
    ('predictive_models'),
    ('predictive_analyses'),
    ('cultural_analytics'),
    ('custom_reports'),
    ('report_executions'),
    ('performance_benchmarks'),
    ('automated_insights')
) AS expected(table_name)
WHERE NOT EXISTS (
    SELECT 1 FROM pg_tables
    WHERE schemaname = 'public' AND tablename = expected.table_name
);

-- If tables are missing, you need to either:
-- 1. Drop the ENUMs and retry the migration (risky if other tables use them)
-- 2. Manually create the missing tables (complex, error-prone)
-- 3. Use Solution 2 below to fix the migration files
```

**Step 4: Redeploy on Railway**
```bash
# Trigger a new deployment
git commit --allow-empty -m "Retry deployment after ENUM fix"
git push railway main
```

### Option B: Skip Problematic Migration

If you want to quickly bypass the issue:

```bash
# Locally, update the migration to skip ENUM creation if they exist
# Then deploy the fixed migration

railway up
```

---

## Solution 2: MIGRATION PATTERN FIX (Permanent Fix)

### Fix 1: Centralize ENUM Creation

Create a separate migration that ONLY creates ENUMs, which all other migrations depend on.

**Create new migration file: `/Users/cope/EnGardeHQ/production-backend/alembic/versions/000_create_base_enums.py`**

```python
"""Create base ENUM types used across analytics system

Revision ID: 000_create_base_enums
Revises: 7903a818df74
Create Date: 2025-11-08 00:00:00.000000

This migration creates all ENUM types in one place to prevent duplication.
All analytics migrations depend on this one.
"""
from alembic import op
import sqlalchemy as sa

# revision identifiers
revision = '000_create_base_enums'
down_revision = '7903a818df74'
branch_labels = None
depends_on = None


def upgrade():
    """Create all ENUM types used by analytics system"""

    # Platform Type ENUM - used by analytics, integrations, webhooks
    op.execute("""
        DO $$ BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'platformtype') THEN
                CREATE TYPE platformtype AS ENUM (
                    'meta_ads', 'tiktok_ads', 'google_ads', 'instagram', 'facebook',
                    'pos_system', 'email_marketing', 'sms_marketing', 'website', 'mobile_app'
                );
                RAISE NOTICE 'Created ENUM type: platformtype';
            ELSE
                RAISE NOTICE 'ENUM type platformtype already exists, skipping';
            END IF;
        END $$;
    """)

    # Metric Type ENUM - used by analytics system
    op.execute("""
        DO $$ BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'metrictype') THEN
                CREATE TYPE metrictype AS ENUM (
                    'impressions', 'clicks', 'conversions', 'revenue', 'spend',
                    'engagement', 'reach', 'ctr', 'cpc', 'cpa', 'roas', 'custom'
                );
                RAISE NOTICE 'Created ENUM type: metrictype';
            ELSE
                RAISE NOTICE 'ENUM type metrictype already exists, skipping';
            END IF;
        END $$;
    """)

    # Cultural Segment ENUM - used by cultural analytics
    op.execute("""
        DO $$ BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'culturalsegment') THEN
                CREATE TYPE culturalsegment AS ENUM (
                    'hispanic_latino', 'african_american', 'asian_american', 'native_american',
                    'middle_eastern', 'european_american', 'multi_cultural', 'general_market'
                );
                RAISE NOTICE 'Created ENUM type: culturalsegment';
            ELSE
                RAISE NOTICE 'ENUM type culturalsegment already exists, skipping';
            END IF;
        END $$;
    """)

    # Analytics Granularity ENUM - used by aggregations
    op.execute("""
        DO $$ BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'analyticsgranularity') THEN
                CREATE TYPE analyticsgranularity AS ENUM (
                    'minute', 'hour', 'day', 'week', 'month', 'quarter', 'year'
                );
                RAISE NOTICE 'Created ENUM type: analyticsgranularity';
            ELSE
                RAISE NOTICE 'ENUM type analyticsgranularity already exists, skipping';
            END IF;
        END $$;
    """)


def downgrade():
    """Drop all ENUM types (CASCADE to drop dependent objects)"""

    op.execute("DROP TYPE IF EXISTS analyticsgranularity CASCADE;")
    op.execute("DROP TYPE IF EXISTS culturalsegment CASCADE;")
    op.execute("DROP TYPE IF EXISTS metrictype CASCADE;")
    op.execute("DROP TYPE IF EXISTS platformtype CASCADE;")
```

### Fix 2: Update Advanced Analytics Migration

Update `advanced_analytics_system.py` to depend on the ENUM migration:

```python
# At the top of advanced_analytics_system.py
revision = 'advanced_analytics_001'
down_revision = 'comprehensive_audit_system'
depends_on = ('000_create_base_enums',)  # Add this line
branch_labels = None

def upgrade():
    """Create advanced analytics system tables"""

    bind = op.get_bind()
    inspector = inspect(bind)
    existing_tables = inspector.get_table_names()

    # REMOVE ALL ENUM CREATION CODE (lines 28-70)
    # The ENUMs are now created by 000_create_base_enums migration

    # Start directly with table creation
    if 'analytics_data_points' not in existing_tables:
        op.create_table(
            'analytics_data_points',
            # ... rest of the table definition
            # Use create_type=False to reference existing ENUM
            sa.Column('platform_type', sa.Enum('meta_ads', ..., name='platformtype', create_type=False), ...),
            # ... continue
        )
    # ... rest of migration
```

### Fix 3: Update 20251010 Migration

Update `20251010_create_missing_analytics_webhook_tables.py`:

```python
# Update revision info
revision = '20251010_missing_tables'
down_revision = 'advanced_analytics_001'
depends_on = ('000_create_base_enums',)  # Add dependency
branch_labels = None

def upgrade():
    # REMOVE ENUM CREATION CODE (lines 76-125)
    # ENUMs are created by 000_create_base_enums migration

    # Start directly with table creation
    bind = op.get_bind()
    inspector = inspect(bind)
    existing_tables = inspector.get_table_names()

    # Table creation continues with create_type=False
    # ... rest of migration
```

---

## Solution 3: DEPLOYMENT ROBUSTNESS (Prevent Future Issues)

### Pattern 1: Idempotent ENUM Management Utility

**Create `/Users/cope/EnGardeHQ/production-backend/alembic/enum_utils.py`:**

```python
"""
Utilities for idempotent ENUM type management in Alembic migrations.

This module provides safe ENUM creation, modification, and deletion
that works correctly in concurrent deployment scenarios.
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect, text
import logging

logger = logging.getLogger('alembic.runtime.migration')


def create_enum_type_safe(enum_name: str, values: list[str]) -> bool:
    """
    Safely create a PostgreSQL ENUM type if it doesn't exist.

    This uses an advisory lock to prevent race conditions during
    concurrent deployments (e.g., Railway auto-deploys).

    Args:
        enum_name: Name of the ENUM type
        values: List of enum values

    Returns:
        True if created, False if already existed
    """
    bind = op.get_bind()

    if bind.dialect.name != 'postgresql':
        logger.warning(f"ENUM types only supported on PostgreSQL, skipping {enum_name}")
        return False

    # Use advisory lock specific to this ENUM
    lock_id = hash(enum_name) % 2147483647  # Max int32 value

    try:
        # Acquire advisory lock for this specific ENUM
        result = bind.execute(
            text("SELECT pg_try_advisory_lock(:lock_id)"),
            {"lock_id": lock_id}
        ).scalar()

        if not result:
            logger.info(f"Waiting for ENUM {enum_name} lock...")
            # Wait for lock with timeout
            bind.execute(
                text("SELECT pg_advisory_lock(:lock_id)"),
                {"lock_id": lock_id}
            )

        # Check if ENUM exists (double-check inside lock)
        exists = bind.execute(
            text("SELECT 1 FROM pg_type WHERE typname = :enum_name"),
            {"enum_name": enum_name}
        ).scalar()

        if exists:
            logger.info(f"ENUM type '{enum_name}' already exists")
            return False

        # Create ENUM
        values_str = "', '".join(values)
        bind.execute(
            text(f"CREATE TYPE {enum_name} AS ENUM ('{values_str}')")
        )
        logger.info(f"Created ENUM type '{enum_name}' with {len(values)} values")
        return True

    finally:
        # Always release lock
        try:
            bind.execute(
                text("SELECT pg_advisory_unlock(:lock_id)"),
                {"lock_id": lock_id}
            )
        except Exception as e:
            logger.error(f"Error releasing advisory lock for {enum_name}: {e}")


def enum_type_exists(enum_name: str) -> bool:
    """Check if a PostgreSQL ENUM type exists"""
    bind = op.get_bind()

    if bind.dialect.name != 'postgresql':
        return False

    result = bind.execute(
        text("SELECT 1 FROM pg_type WHERE typname = :enum_name"),
        {"enum_name": enum_name}
    ).scalar()

    return result is not None


def add_enum_value_safe(enum_name: str, new_value: str, before: str = None, after: str = None):
    """
    Safely add a value to an existing ENUM type.

    Args:
        enum_name: Name of the ENUM type
        new_value: Value to add
        before: Add before this existing value (optional)
        after: Add after this existing value (optional)
    """
    bind = op.get_bind()

    if bind.dialect.name != 'postgresql':
        logger.warning(f"ENUM types only supported on PostgreSQL")
        return

    # Check if value already exists
    existing_values = bind.execute(
        text("""
            SELECT e.enumlabel
            FROM pg_type t
            JOIN pg_enum e ON t.oid = e.enumtypid
            WHERE t.typname = :enum_name
        """),
        {"enum_name": enum_name}
    ).scalars().all()

    if new_value in existing_values:
        logger.info(f"Value '{new_value}' already exists in ENUM '{enum_name}'")
        return

    # Build ALTER TYPE statement
    if before:
        sql = f"ALTER TYPE {enum_name} ADD VALUE '{new_value}' BEFORE '{before}'"
    elif after:
        sql = f"ALTER TYPE {enum_name} ADD VALUE '{new_value}' AFTER '{after}'"
    else:
        sql = f"ALTER TYPE {enum_name} ADD VALUE '{new_value}'"

    bind.execute(text(sql))
    logger.info(f"Added value '{new_value}' to ENUM '{enum_name}'")


def drop_enum_type_safe(enum_name: str, cascade: bool = False):
    """
    Safely drop a PostgreSQL ENUM type.

    Args:
        enum_name: Name of the ENUM type
        cascade: Whether to CASCADE the drop (drops dependent objects)
    """
    bind = op.get_bind()

    if bind.dialect.name != 'postgresql':
        return

    cascade_str = " CASCADE" if cascade else ""
    bind.execute(text(f"DROP TYPE IF EXISTS {enum_name}{cascade_str}"))
    logger.info(f"Dropped ENUM type '{enum_name}'{cascade_str}")
```

**Usage in migrations:**

```python
from alembic import op
from alembic.enum_utils import create_enum_type_safe, enum_type_exists

def upgrade():
    # Create ENUMs safely
    create_enum_type_safe('platformtype', [
        'meta_ads', 'tiktok_ads', 'google_ads', 'instagram', 'facebook',
        'pos_system', 'email_marketing', 'sms_marketing', 'website', 'mobile_app'
    ])

    # Use in table creation with create_type=False
    op.create_table(
        'analytics_data_points',
        sa.Column('platform_type',
                  sa.Enum('meta_ads', ..., name='platformtype', create_type=False),
                  nullable=False)
    )
```

### Pattern 2: Migration Pre-flight Checks

**Create `/Users/cope/EnGardeHQ/production-backend/scripts/pre_deploy_check.py`:**

```python
#!/usr/bin/env python3
"""
Pre-deployment database migration check script.

Runs before Railway deployment to validate migration safety.
"""
import os
import sys
from sqlalchemy import create_engine, text, inspect
from alembic.config import Config
from alembic.script import ScriptDirectory
from alembic.runtime.migration import MigrationContext

def check_migration_safety():
    """Check if pending migrations are safe to apply"""

    database_url = os.getenv('DATABASE_URL')
    if not database_url:
        print("ERROR: DATABASE_URL not set")
        return False

    engine = create_engine(database_url)

    try:
        with engine.connect() as conn:
            # Get current migration version
            context = MigrationContext.configure(conn)
            current_rev = context.get_current_revision()
            print(f"Current migration revision: {current_rev}")

            # Get pending migrations
            alembic_cfg = Config("alembic.ini")
            script = ScriptDirectory.from_config(alembic_cfg)

            # Check for ENUM conflicts
            inspector = inspect(engine)
            existing_enums = conn.execute(text("""
                SELECT typname FROM pg_type WHERE typtype = 'e'
            """)).scalars().all()

            print(f"Existing ENUM types: {existing_enums}")

            # Check for potential conflicts
            critical_enums = ['platformtype', 'metrictype', 'culturalsegment', 'analyticsgranularity']
            conflicts = [e for e in critical_enums if e in existing_enums]

            if conflicts:
                print(f"WARNING: Critical ENUM types already exist: {conflicts}")
                print("Ensure migrations use IF NOT EXISTS or create_type=False")

            return True

    except Exception as e:
        print(f"ERROR during migration check: {e}")
        return False


if __name__ == "__main__":
    success = check_migration_safety()
    sys.exit(0 if success else 1)
```

**Add to Railway deploy script (`railway.json` or Procfile):**

```json
{
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "python scripts/pre_deploy_check.py && alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port $PORT",
    "healthcheckPath": "/health",
    "healthcheckTimeout": 300
  }
}
```

### Pattern 3: Migration Locking (Already Implemented!)

Your `env.py` already has excellent advisory lock implementation (lines 92-186). This is perfect for preventing concurrent migrations.

**Enhance logging:**

```python
# In env.py, add more detailed logging
logger.info(f"Migration started at {time.strftime('%Y-%m-%d %H:%M:%S')}")
logger.info(f"Target revision: {context.get_current_revision()}")
logger.info(f"Using advisory lock ID: {ADVISORY_LOCK_ID}")
```

---

## Solution 4: RAILWAY-SPECIFIC CONSIDERATIONS

### Issue 1: Multiple Deployment Instances

**Problem**: Railway may spin up new instances before old ones shut down, causing concurrent migrations.

**Solution**: Configure Railway deployment strategy

```json
{
  "deploy": {
    "numReplicas": 1,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 3,
    "startCommand": "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port $PORT"
  }
}
```

### Issue 2: Migration Timeout

**Problem**: Long-running migrations timeout during Railway deployment.

**Solution**: Increase timeouts and add progress logging

```python
# In env.py
LOCK_TIMEOUT_SECONDS = 600  # Increase to 10 minutes
MIGRATION_TIMEOUT = 900  # 15 minutes for the entire migration

# Add migration progress callbacks
def on_version_apply(ctx, step):
    logger.info(f"Applying migration: {step.up_revision_id}")

context.configure(
    connection=connection,
    target_metadata=target_metadata,
    transaction_per_migration=False,
    on_version_apply=on_version_apply
)
```

### Issue 3: Zero-Downtime Deployments

**Strategy**: Separate migration from deployment

**Step 1: Manual migration job**
```bash
# Railway CLI - run migration separately
railway run alembic upgrade head

# Then deploy application
railway up
```

**Step 2: Use Railway database migration service**
```yaml
# railway.toml
[deploy]
healthcheckPath = "/health"
healthcheckTimeout = 300

[build]
builder = "nixpacks"

[[build.beforeBuild]]
command = "alembic upgrade head"
```

---

## RECOMMENDED ACTION PLAN

### Phase 1: Immediate Fix (15 minutes)

1. **Connect to Railway database** and check migration state:
   ```sql
   SELECT version_num FROM alembic_version;
   SELECT typname FROM pg_type WHERE typname LIKE '%type%';
   ```

2. **If ENUMs exist**, mark migration as complete:
   ```sql
   INSERT INTO alembic_version (version_num)
   VALUES ('advanced_analytics_001')
   ON CONFLICT DO NOTHING;
   ```

3. **Redeploy**: Trigger Railway deployment

### Phase 2: Permanent Fix (1 hour)

1. **Create centralized ENUM migration** (`000_create_base_enums.py`)

2. **Update existing migrations** to:
   - Remove ENUM creation code
   - Add `depends_on` to ENUM migration
   - Use `create_type=False` in table definitions

3. **Test locally**:
   ```bash
   # Reset local database
   alembic downgrade base
   alembic upgrade head

   # Test idempotency
   alembic upgrade head  # Should succeed with no changes
   ```

4. **Deploy to Railway**

### Phase 3: Long-term Robustness (2 hours)

1. **Implement `enum_utils.py`** for future migrations

2. **Add pre-deployment checks** (`pre_deploy_check.py`)

3. **Configure Railway** for single-instance deployments

4. **Document migration patterns** in team wiki

---

## TESTING CHECKLIST

Before deploying fixes:

- [ ] Test ENUM creation locally (fresh database)
- [ ] Test ENUM creation locally (existing ENUMs)
- [ ] Test migration rollback (`alembic downgrade`)
- [ ] Test concurrent migration attempts (simulate Railway race)
- [ ] Verify advisory locks are acquired/released
- [ ] Check migration execution time (<5 minutes)
- [ ] Test Railway deployment in staging environment
- [ ] Verify application starts correctly after migration
- [ ] Check database state matches expected schema
- [ ] Run application health checks

---

## ROLLBACK PLAN

If deployment fails:

1. **Quick rollback**:
   ```sql
   -- Remove problematic migration
   DELETE FROM alembic_version
   WHERE version_num = 'advanced_analytics_001';

   -- Optionally drop ENUMs (CASCADE if tables exist)
   DROP TYPE IF EXISTS platformtype CASCADE;
   DROP TYPE IF EXISTS metrictype CASCADE;
   DROP TYPE IF EXISTS culturalsegment CASCADE;
   DROP TYPE IF EXISTS analyticsgranularity CASCADE;
   ```

2. **Restore previous application version** via Railway dashboard

3. **Investigate** logs and database state

---

## MONITORING AND ALERTS

Add monitoring for migration health:

```python
# In env.py, add metrics logging
import time

migration_start = time.time()

# After migrations complete
migration_duration = time.time() - migration_start
logger.info(f"Migration completed in {migration_duration:.2f} seconds")

# Send to monitoring service (DataDog, Sentry, etc.)
# monitoring.record_metric('migration.duration', migration_duration)
# monitoring.record_event('migration.completed', {'revision': context.get_current_revision()})
```

---

## ADDITIONAL RESOURCES

- **PostgreSQL ENUM documentation**: https://www.postgresql.org/docs/current/datatype-enum.html
- **Alembic branches and dependencies**: https://alembic.sqlalchemy.org/en/latest/branches.html
- **Railway deployment guides**: https://docs.railway.app/deploy/deployments
- **PostgreSQL advisory locks**: https://www.postgresql.org/docs/current/functions-admin.html#FUNCTIONS-ADVISORY-LOCKS

---

## KEY TAKEAWAYS

1. **Never duplicate ENUM creation** across multiple migrations
2. **Always use IF NOT EXISTS** when creating ENUMs
3. **Use advisory locks** to prevent concurrent migration execution
4. **Test idempotency** - every migration should be safe to re-run
5. **Separate ENUM creation** from table creation for better dependency management
6. **Use `create_type=False`** when referencing existing ENUMs in SQLAlchemy
7. **Monitor Railway deployments** for migration timeout issues

---

## File Locations

- Migration files: `/Users/cope/EnGardeHQ/production-backend/alembic/versions/`
- Alembic env: `/Users/cope/EnGardeHQ/production-backend/alembic/env.py`
- Database URL: Set in Railway environment as `DATABASE_URL`

---

**Document Version**: 1.0
**Last Updated**: 2025-11-08
**Author**: System Architect
**Status**: Ready for Implementation
