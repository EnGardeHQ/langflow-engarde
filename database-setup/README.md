# En Garde Database Schema Isolation - Setup Guide

## Overview

This guide explains how to set up schema isolation for all En Garde microservices using the existing PostgreSQL database on Railway.

## Why Schema Isolation?

✅ **Cost-effective**: One PostgreSQL instance ($10/mo) vs multiple databases ($50+/mo)  
✅ **Simpler operations**: One backup, one restore, one connection pool  
✅ **Cross-service analytics**: Can join across schemas when needed  
✅ **Logical separation**: Each service owns its schema  
✅ **Easy migration**: Can split into separate databases later if needed

## Architecture

```
PostgreSQL Database (Railway)
├── Schema: public (production-backend)
├── Schema: madansara (MadanSara microservice)
├── Schema: sankore (Sankore microservice)
├── Schema: onside (Onside microservice)
└── Schema: langflow (Langflow)

Separate MySQL Database (Railway)
└── EasyAppointments/Scheduler (uses MySQL, not PostgreSQL)
```

## Setup Steps

### 1. Connect to Railway PostgreSQL

```bash
# Get Railway PostgreSQL connection string
railway variables --service postgresql

# Connect using psql
psql "postgresql://postgres:PASSWORD@HOST:5432/railway"
```

### 2. Run Schema Setup Script

```bash
# From the database-setup directory
psql "postgresql://postgres:PASSWORD@HOST:5432/railway" -f schema-isolation-setup.sql
```

**Important**: Before running, update the script with:
- Replace `SECURE_PASSWORD_HERE` with actual secure passwords (generate with `openssl rand -base64 32`)
- Replace `postgres` database name with your actual Railway database name (usually `railway`)

### 3. Update Railway Environment Variables

For each microservice on Railway, update the `DATABASE_URL`:

#### MadanSara
```bash
DATABASE_URL=postgresql://madansara_user:PASSWORD@HOST:5432/railway?options=-c%20search_path=madansara,public
```

#### Sankore
```bash
DATABASE_URL=postgresql://sankore_user:PASSWORD@HOST:5432/railway?options=-c%20search_path=sankore,public
```

#### Onside
```bash
DATABASE_URL=postgresql://onside_user:PASSWORD@HOST:5432/railway?options=-c%20search_path=onside,public
```

#### Langflow
```bash
DATABASE_URL=postgresql://langflow_user:PASSWORD@HOST:5432/railway?options=-c%20search_path=langflow,public
```

**Note**: EasyAppointments/Scheduler uses MySQL and maintains its own separate database connection.

### 4. Update Alembic Configurations

Each microservice needs its Alembic config updated to use schema-specific version tables.

**Example for MadanSara** (`alembic/env.py`):

```python
from sqlalchemy import engine_from_config, pool

# Set schema for all operations
target_metadata = Base.metadata
target_metadata.schema = "madansara"

def run_migrations_online():
    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
        connect_args={"options": "-c search_path=madansara,public"}
    )
    
    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            version_table_schema="madansara",  # Store alembic_version in schema
            include_schemas=True
        )
        
        with context.begin_transaction():
            context.run_migrations()
```

**Update SQLAlchemy models** (`app/db/base.py`):

```python
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()
Base.metadata.schema = "madansara"  # Set schema for all models
```

### 5. Run Migrations

```bash
# MadanSara
cd /Users/cope/EnGardeHQ/MadanSara
alembic upgrade head

# Sankore
cd /Users/cope/EnGardeHQ/Sankore
alembic upgrade head

# Onside
cd /Users/cope/EnGardeHQ/Onside
alembic upgrade head
```

## Verification

### Check Schemas Created

```sql
SELECT schema_name 
FROM information_schema.schemata 
WHERE schema_name IN ('madansara', 'sankore', 'onside', 'langflow')
ORDER BY schema_name;
```

### Check Users Created

```sql
SELECT usename, usecreatedb, usesuper 
FROM pg_catalog.pg_user 
WHERE usename LIKE '%_user' OR usename = 'analytics_readonly'
ORDER BY usename;
```

### Check Permissions

```sql
SELECT 
    grantee,
    table_schema,
    privilege_type
FROM information_schema.schema_privileges
WHERE table_schema IN ('madansara', 'sankore', 'onside', 'langflow')
ORDER BY grantee, table_schema;
```

### Test Service Connection

```bash
# Test MadanSara connection
psql "postgresql://madansara_user:PASSWORD@HOST:5432/railway?options=-c%20search_path=madansara,public"

# Should only see madansara schema
\dn
```

## Cross-Service Data Access

### Option 1: API Calls (Recommended)

```python
# MadanSara calls production-backend API
async def get_brand_users(brand_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{PRODUCTION_BACKEND_URL}/api/brands/{brand_id}/users"
        )
        return response.json()
```

### Option 2: Cross-Schema Query (Use Sparingly)

```python
# Direct database query across schemas
from sqlalchemy import text

async def get_brand_users_direct(brand_id: str):
    query = text("""
        SELECT u.id, u.email, u.name
        FROM public.users u
        JOIN public.brand_users bu ON u.id = bu.user_id
        WHERE bu.brand_id = :brand_id
    """)
    
    result = await db.execute(query, {"brand_id": brand_id})
    return result.fetchall()
```

**Best Practice**: Use API calls for loose coupling. Use cross-schema queries only for analytics/reporting.

## Monitoring

### Schema Size

```sql
SELECT 
    schemaname,
    pg_size_pretty(SUM(pg_total_relation_size(schemaname||'.'||tablename))::bigint) as size
FROM pg_tables
WHERE schemaname IN ('madansara', 'sankore', 'onside', 'public')
GROUP BY schemaname
ORDER BY SUM(pg_total_relation_size(schemaname||'.'||tablename)) DESC;
```

### Active Connections

```sql
SELECT 
    datname,
    usename,
    application_name,
    state,
    COUNT(*)
FROM pg_stat_activity
WHERE datname = 'railway'
GROUP BY datname, usename, application_name, state;
```

### Slow Queries by Schema

```sql
-- Enable pg_stat_statements extension first
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Find slow queries
SELECT 
    schemaname,
    query,
    calls,
    total_exec_time,
    mean_exec_time
FROM pg_stat_statements pss
JOIN pg_namespace pn ON pss.query LIKE '%' || pn.nspname || '%'
WHERE pn.nspname IN ('madansara', 'sankore', 'onside')
ORDER BY mean_exec_time DESC
LIMIT 20;
```

## Security Best Practices

1. **Use service-specific users**: Each microservice has its own database user
2. **Revoke cross-schema access**: Services can only access their own schema
3. **Read-only analytics user**: For cross-service reporting without write access
4. **Rotate passwords regularly**: Update Railway environment variables
5. **Monitor connection pools**: Limit connections per service (5-10 max)

## Troubleshooting

### "Permission denied for schema"

```sql
-- Grant missing permissions
GRANT USAGE ON SCHEMA madansara TO madansara_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA madansara TO madansara_user;
```

### "Relation does not exist"

Check search_path is set correctly:
```sql
SHOW search_path;
-- Should show: madansara, public
```

### Alembic version table conflicts

```sql
-- Check which schema has alembic_version
SELECT schemaname, tablename 
FROM pg_tables 
WHERE tablename = 'alembic_version';

-- Move to correct schema if needed
ALTER TABLE public.alembic_version SET SCHEMA madansara;
```

## Rollback Plan

If you need to revert to separate databases:

```sql
-- Export schema
pg_dump -n madansara -h HOST -U postgres railway > madansara_backup.sql

-- Create new database
createdb madansara_db

-- Import
psql madansara_db < madansara_backup.sql

-- Update Railway DATABASE_URL to point to new database
```

## Next Steps

1. ✅ Run `schema-isolation-setup.sql` on Railway PostgreSQL
2. ✅ Update Railway environment variables for each service
3. ✅ Update Alembic configurations
4. ✅ Run migrations for each service
5. ✅ Test service connections
6. ✅ Monitor schema sizes and query performance

## Support

For issues or questions:
- Check Railway logs: `railway logs --service <service-name>`
- Verify DATABASE_URL is correct
- Check PostgreSQL logs for permission errors
- Review Alembic migration history: `alembic history`
