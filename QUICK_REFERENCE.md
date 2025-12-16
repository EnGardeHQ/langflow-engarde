# Langflow Schema Isolation - Quick Reference Guide

**For Developers & DevOps Engineers**

---

## Architecture Overview

```
PostgreSQL Database: engarde
├── Schema: public (EnGarde Application)
│   ├── Tables: tenants, users, brands, campaigns, workflows, etc.
│   └── alembic_version (EnGarde migrations)
│
├── Schema: langflow (Langflow Engine)
│   ├── Tables: flow, vertex, edge, transaction, message, etc.
│   └── alembic_version (Langflow migrations)
│
└── Schema: audit (Cross-Schema Monitoring)
    └── Table: cross_schema_access
```

**Key Principle:** Same database, separate schemas = Complete isolation + Cross-schema access

---

## Essential Commands

### Database Operations

```bash
# Access PostgreSQL
docker exec -it engarde_postgres psql -U engarde_user -d engarde

# List schemas
\dn

# List tables in public schema (EnGarde)
\dt public.*

# List tables in langflow schema
\dt langflow.*

# Check alembic versions
SELECT * FROM public.alembic_version;    -- EnGarde
SELECT * FROM langflow.alembic_version;  -- Langflow

# View schema permissions
\dp langflow.*
```

### Service Management

```bash
# Start all services
docker-compose -f docker-compose.langflow-isolated.yml up -d

# Start with production features (PgBouncer)
docker-compose -f docker-compose.langflow-isolated.yml --profile production up -d

# Restart Langflow only
docker-compose restart langflow

# View Langflow logs
docker-compose logs -f langflow

# Check service health
curl http://localhost:7860/health  # Langflow
curl http://localhost:8000/health  # EnGarde Backend
```

### Migration Management

```bash
# EnGarde migrations (public schema)
cd production-backend
alembic upgrade head
alembic current
alembic history

# Langflow migrations (langflow schema - automatic)
# Langflow handles its own migrations on startup
docker-compose logs langflow | grep -i migration
```

---

## SQL Quick Reference

### Cross-Schema Queries

**From EnGarde (read Langflow flows):**
```sql
-- Get all Langflow flows with campaign info
SELECT
    c.id as campaign_id,
    c.name as campaign_name,
    f.id as flow_id,
    f.name as flow_name,
    f.updated_at
FROM public.campaigns c
LEFT JOIN langflow.flow f ON f.id::text = c.langflow_flow_id
WHERE c.tenant_id = '<tenant-uuid>'
ORDER BY f.updated_at DESC;
```

**From Langflow (read EnGarde campaigns):**
```sql
-- Get campaign data for workflow
SELECT
    id,
    name,
    status,
    data
FROM public.campaigns
WHERE id = '<campaign-uuid>'
AND tenant_id = current_setting('app.current_tenant_id')::uuid;
```

### Tenant Isolation

**Set tenant context:**
```sql
-- Set for current session
SELECT set_config('app.current_tenant_id', '<tenant-uuid>', true);

-- Verify current tenant
SELECT current_setting('app.current_tenant_id', true);

-- Clear tenant context (admin mode)
SELECT set_config('app.current_tenant_id', NULL, true);
```

**Query with tenant isolation:**
```sql
-- Only see flows for current tenant
SELECT * FROM langflow.flow;

-- Only see campaigns for current tenant
SELECT * FROM public.campaigns;
```

---

## Python Integration Examples

### EnGarde: Accessing Langflow Data

```python
from app.database import engine
from sqlalchemy import text

def get_tenant_flows(tenant_id: str):
    """Get all Langflow flows for a tenant."""
    with engine.connect() as conn:
        flows = conn.execute(text("""
            SELECT id, name, data, updated_at
            FROM langflow.flow
            WHERE tenant_id = :tenant_id
            ORDER BY updated_at DESC
        """), {"tenant_id": tenant_id})

        return [dict(row._mapping) for row in flows]

def get_flow_executions(flow_id: str, limit: int = 10):
    """Get recent executions of a flow."""
    with engine.connect() as conn:
        executions = conn.execute(text("""
            SELECT
                id,
                flow_id,
                timestamp,
                status,
                inputs,
                outputs
            FROM langflow.transaction
            WHERE flow_id = :flow_id
            ORDER BY timestamp DESC
            LIMIT :limit
        """), {"flow_id": flow_id, "limit": limit})

        return [dict(row._mapping) for row in executions]
```

### Langflow Custom Component: EnGarde Data Access

```python
# /Users/cope/EnGardeHQ/production-backend/custom_components/engarde_campaign.py
from langflow import CustomComponent
from langchain.schema import Document
from sqlalchemy import create_engine, text
import os

class EnGardeCampaignLoader(CustomComponent):
    display_name = "EnGarde Campaign"
    description = "Load campaign data from EnGarde platform"

    def build_config(self):
        return {
            "campaign_id": {
                "display_name": "Campaign ID",
                "info": "UUID of the EnGarde campaign"
            },
            "include_metrics": {
                "display_name": "Include Metrics",
                "type": "bool",
                "value": True
            }
        }

    def build(self, campaign_id: str, include_metrics: bool = True) -> Document:
        # Connect using Langflow's database URL
        engine = create_engine(os.environ['LANGFLOW_DATABASE_URL'])

        with engine.connect() as conn:
            # Get campaign data (respects RLS automatically)
            campaign = conn.execute(text("""
                SELECT
                    id,
                    name,
                    status,
                    data,
                    created_at,
                    updated_at
                FROM public.campaigns
                WHERE id = :campaign_id
            """), {"campaign_id": campaign_id}).fetchone()

            if not campaign:
                raise ValueError(f"Campaign {campaign_id} not found")

            campaign_data = dict(campaign._mapping)

            # Optionally get metrics
            if include_metrics:
                metrics = conn.execute(text("""
                    SELECT
                        impressions,
                        clicks,
                        conversions,
                        spend
                    FROM public.campaign_metrics
                    WHERE campaign_id = :campaign_id
                    ORDER BY timestamp DESC
                    LIMIT 1
                """), {"campaign_id": campaign_id}).fetchone()

                if metrics:
                    campaign_data['metrics'] = dict(metrics._mapping)

            # Return as Langchain Document
            return Document(
                page_content=f"Campaign: {campaign_data['name']}",
                metadata=campaign_data
            )
```

---

## Common Patterns

### 1. Create Flow with Tenant Context

```python
from sqlalchemy import create_engine, text
import os

engine = create_engine(os.environ['LANGFLOW_DATABASE_URL'])

def create_tenant_flow(tenant_id: str, flow_name: str, flow_data: dict):
    with engine.connect() as conn:
        # Set tenant context
        conn.execute(
            text("SELECT set_config('app.current_tenant_id', :tenant_id, true)"),
            {"tenant_id": str(tenant_id)}
        )

        # Insert flow (tenant_id auto-populated by trigger)
        result = conn.execute(text("""
            INSERT INTO langflow.flow (name, data)
            VALUES (:name, :data::jsonb)
            RETURNING id
        """), {"name": flow_name, "data": json.dumps(flow_data)})

        conn.commit()
        return result.fetchone()[0]
```

### 2. Execute Flow with Campaign Context

```python
def execute_flow_for_campaign(flow_id: str, campaign_id: str, inputs: dict):
    with engine.connect() as conn:
        # Get campaign tenant
        campaign = conn.execute(text("""
            SELECT tenant_id FROM public.campaigns WHERE id = :campaign_id
        """), {"campaign_id": campaign_id}).fetchone()

        # Set tenant context
        conn.execute(
            text("SELECT set_config('app.current_tenant_id', :tenant_id, true)"),
            {"tenant_id": str(campaign['tenant_id'])}
        )

        # Execute flow (call Langflow API)
        # Transaction log will auto-include tenant_id
```

### 3. Cross-Schema Analytics

```python
def get_campaign_workflow_analytics(tenant_id: str):
    """Get analytics combining EnGarde and Langflow data."""
    with engine.connect() as conn:
        result = conn.execute(text("""
            SELECT
                c.id as campaign_id,
                c.name as campaign_name,
                c.status,
                f.id as flow_id,
                f.name as flow_name,
                COUNT(t.id) as execution_count,
                AVG(EXTRACT(EPOCH FROM (t.updated_at - t.created_at))) as avg_duration_seconds,
                MAX(t.timestamp) as last_execution
            FROM public.campaigns c
            LEFT JOIN langflow.flow f
                ON f.id::text = c.langflow_flow_id
            LEFT JOIN langflow.transaction t
                ON t.flow_id = f.id
            WHERE c.tenant_id = :tenant_id
            GROUP BY c.id, c.name, c.status, f.id, f.name
            ORDER BY last_execution DESC NULLS LAST
        """), {"tenant_id": tenant_id})

        return [dict(row._mapping) for row in result]
```

---

## Troubleshooting

### Issue: Langflow tables appearing in public schema

**Cause:** Incorrect connection string or search_path not set

**Fix:**
```bash
# Verify Langflow DATABASE_URL includes search_path
docker exec engarde_langflow env | grep DATABASE_URL

# Should include: ?options=-csearch_path=langflow,public

# If not, update docker-compose.yml and restart
docker-compose restart langflow
```

### Issue: Migration conflicts

**Cause:** Alembic detecting tables from wrong schema

**Fix:**
```bash
# Check which schema has which alembic_version
docker exec engarde_postgres psql -U engarde_user -d engarde -c "
  SELECT 'public' as schema, version_num FROM public.alembic_version
  UNION ALL
  SELECT 'langflow' as schema, version_num FROM langflow.alembic_version;
"

# Ensure they're tracking different migrations
```

### Issue: Tenant isolation not working

**Cause:** RLS policies not applied or tenant context not set

**Fix:**
```sql
-- Check RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'langflow';

-- Apply RLS if needed
docker exec -i engarde_postgres psql -U engarde_user -d engarde < production-backend/scripts/apply-langflow-rls.sql

-- Verify tenant context is set in application
SELECT current_setting('app.current_tenant_id', true);
```

### Issue: Cross-schema queries failing

**Cause:** Missing permissions

**Fix:**
```sql
-- Grant read permissions
GRANT SELECT ON ALL TABLES IN SCHEMA public TO langflow_app;
GRANT SELECT ON ALL TABLES IN SCHEMA langflow TO engarde_user;

-- Verify permissions
SELECT grantee, table_schema, privilege_type
FROM information_schema.table_privileges
WHERE grantee IN ('langflow_app', 'engarde_user')
ORDER BY grantee, table_schema;
```

### Issue: Performance degradation

**Cause:** Missing indexes on frequently queried columns

**Fix:**
```sql
-- Add tenant_id indexes
CREATE INDEX IF NOT EXISTS idx_langflow_flow_tenant_id ON langflow.flow(tenant_id);
CREATE INDEX IF NOT EXISTS idx_langflow_transaction_tenant_id ON langflow.transaction(tenant_id);

-- Add composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_langflow_transaction_flow_timestamp
  ON langflow.transaction(flow_id, timestamp DESC);

-- Analyze tables
ANALYZE langflow.flow;
ANALYZE langflow.transaction;
```

---

## Monitoring Queries

### Connection Status
```sql
SELECT
    datname,
    usename,
    application_name,
    state,
    COUNT(*) as connections
FROM pg_stat_activity
WHERE datname = 'engarde'
GROUP BY datname, usename, application_name, state
ORDER BY connections DESC;
```

### Schema Size
```sql
SELECT
    schemaname,
    pg_size_pretty(SUM(pg_total_relation_size(schemaname||'.'||tablename))) as total_size
FROM pg_tables
WHERE schemaname IN ('public', 'langflow', 'audit')
GROUP BY schemaname
ORDER BY SUM(pg_total_relation_size(schemaname||'.'||tablename)) DESC;
```

### Query Performance
```sql
SELECT
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    n_tup_ins,
    n_tup_upd,
    n_tup_del
FROM pg_stat_user_tables
WHERE schemaname IN ('public', 'langflow')
ORDER BY seq_scan DESC
LIMIT 10;
```

### Cross-Schema Access Audit
```sql
SELECT
    source_schema,
    target_schema,
    user_role,
    COUNT(*) as access_count,
    MAX(timestamp) as last_access
FROM audit.cross_schema_access
GROUP BY source_schema, target_schema, user_role
ORDER BY access_count DESC;
```

---

## Environment Variables Reference

### Required
```bash
POSTGRES_PASSWORD=<secure-password>
LANGFLOW_PASSWORD=<secure-password>
SECRET_KEY=<engarde-secret>
LANGFLOW_SECRET_KEY=<langflow-secret>
NEXTAUTH_SECRET=<nextauth-secret>
```

### Langflow Specific
```bash
LANGFLOW_DATABASE_URL=postgresql://langflow_app:<password>@postgres:5432/engarde?options=-csearch_path=langflow,public
LANGFLOW_SUPERUSER=admin
LANGFLOW_SUPERUSER_PASSWORD=admin
LANGFLOW_LOG_LEVEL=INFO
LANGFLOW_WORKERS=4
LANGFLOW_AUTO_LOGIN=true
LANGFLOW_COMPONENTS_PATH=/app/custom_components
```

### Optional Performance
```bash
# PgBouncer
PGBOUNCER_POOL_MODE=transaction
PGBOUNCER_MAX_CLIENT_CONN=200
PGBOUNCER_DEFAULT_POOL_SIZE=25

# Database
DB_POOL_SIZE=20
DB_MAX_OVERFLOW=40
DB_POOL_TIMEOUT=30
```

---

## File Locations

| File | Purpose | Path |
|------|---------|------|
| Architecture Doc | Full design document | `/Users/cope/EnGardeHQ/LANGFLOW_INTEGRATION_ARCHITECTURE.md` |
| Implementation Checklist | Step-by-step guide | `/Users/cope/EnGardeHQ/IMPLEMENTATION_CHECKLIST.md` |
| Schema Init Script | Create Langflow schema | `/Users/cope/EnGardeHQ/production-backend/scripts/init-langflow-schema.sql` |
| Verification Script | Verify setup | `/Users/cope/EnGardeHQ/production-backend/scripts/verify-langflow-schema.sql` |
| RLS Setup Script | Multi-tenant isolation | `/Users/cope/EnGardeHQ/production-backend/scripts/apply-langflow-rls.sql` |
| Docker Compose | Isolated configuration | `/Users/cope/EnGardeHQ/docker-compose.langflow-isolated.yml` |
| Custom Components | Langflow extensions | `/Users/cope/EnGardeHQ/production-backend/custom_components/` |

---

## Quick Start (TL;DR)

```bash
# 1. Backup
docker exec engarde_postgres pg_dump -U engarde_user -d engarde > backup.sql

# 2. Stop Langflow
docker-compose stop langflow

# 3. Initialize schema
docker exec -i engarde_postgres psql -U engarde_user -d engarde < production-backend/scripts/init-langflow-schema.sql

# 4. Start Langflow with new config
docker-compose -f docker-compose.langflow-isolated.yml up -d langflow

# 5. Verify
docker exec engarde_postgres psql -U engarde_user -d engarde -c "\dt langflow.*"

# 6. Apply RLS
docker exec -i engarde_postgres psql -U engarde_user -d engarde < production-backend/scripts/apply-langflow-rls.sql

# 7. Test
curl http://localhost:7860/health
```

---

## Getting Help

**Documentation:**
- Full Architecture: `LANGFLOW_INTEGRATION_ARCHITECTURE.md`
- Implementation: `IMPLEMENTATION_CHECKLIST.md`

**Verification:**
```bash
# Run full verification
docker exec -i engarde_postgres psql -U engarde_user -d engarde < production-backend/scripts/verify-langflow-schema.sql
```

**Support:**
- Architecture Team: architecture@engarde.com
- Database Team: dba@engarde.com
- DevOps Team: devops@engarde.com
