# EnGarde Database Architecture

## Overview

The EnGarde platform uses a **dual-database architecture** with separate PostgreSQL instances for different concerns:

1. **EnGarde Main Database (Postgres)** - Core application data
2. **Langflow Database (En-Garde-FlowDB)** - Isolated flow and workflow data

## Architecture Decision

### Problem

Previously, Langflow and the EnGarde backend shared the same PostgreSQL instance using separate schemas:
- `public` schema: EnGarde backend tables
- `langflow` schema: Langflow tables

This dual-schema approach caused:
- Migration conflicts during Langflow startup
- Database state corruption from competing migration systems
- Startup hangs when Langflow attempted to run Alembic migrations
- Restart failures after database troubleshooting operations

### Solution

**Dedicated Database Isolation**: Each service now has its own PostgreSQL instance.

## Current Database Architecture

### 1. EnGarde Main Database (`Postgres`)

**Connection**: Original Railway PostgreSQL service
**Used by**:
- `Main` - EnGarde backend microservice
- `Main Copy` - Secondary backend instance
- `madan-sara` - Microservice
- `sankore-paidads` - Microservice
- `capilytics-seo` - Microservice
- `EGM Scheduler` - Scheduling service

**Schema**: `public`
**Tables**: EnGarde application data (users, campaigns, analytics, etc.)

### 2. Langflow Database (`En-Garde-FlowDB`)

**Connection**: Dedicated Railway PostgreSQL service
**Used by**:
- `langflow-server` - Langflow workflow engine

**Schema**: `public` (default)
**Tables**: Langflow-specific data:
- `flow` - Workflow definitions
- `message` - Chat messages and conversation history
- `user` - Langflow users
- `folder` - Organization structure
- `alembic_version` - Migration tracking
- Other Langflow internal tables

**Environment Variable**: `LANGFLOW_DATABASE_URL`

## Benefits

### Isolation
- No migration conflicts between systems
- Independent schema evolution
- Separate backup/restore operations
- Isolated performance impacts

### Reliability
- Langflow restarts don't affect EnGarde backend
- Database maintenance can be scheduled independently
- Cleaner separation of concerns

### Scalability
- Each database can be scaled independently
- Different performance tuning for different workloads
- Separate connection pooling limits

## Migration Notes

### What Changed

**Before** (Single Database):
```
Postgres Database
├── public schema (EnGarde)
└── langflow schema (Langflow) ❌ Conflicted
```

**After** (Dual Database):
```
Postgres Database
└── public schema (EnGarde) ✅

En-Garde-FlowDB Database
└── public schema (Langflow) ✅
```

### Environment Variables

**Langflow Service**:
- `LANGFLOW_DATABASE_URL` → Points to `En-Garde-FlowDB`
- Database URL format: `postgresql://postgres:<password>@<host>:<port>/railway`

**EnGarde Backend Services**:
- `DATABASE_URL` or `DATABASE_PUBLIC_URL` → Points to `Postgres`
- No changes required

## Cross-Database Access

Some flows and microservices may need to access both databases:

### Scenarios Requiring Dual Access

1. **Walker Agent Flows** - May need EnGarde campaign data + Langflow execution context
2. **Analytics Services** - May aggregate data from both systems
3. **SSO Integration** - Authentication spans both systems

### Implementation Pattern

For services needing both databases:

```python
# EnGarde database connection
engarde_db = f"postgresql://{ENGARDE_DB_HOST}:{ENGARDE_DB_PORT}/railway"

# Langflow database connection
langflow_db = f"postgresql://{LANGFLOW_DB_HOST}:{LANGFLOW_DB_PORT}/railway"

# Use separate connection pools
engarde_engine = create_engine(engarde_db)
langflow_engine = create_engine(langflow_db)
```

### Environment Variables for Dual Access

Add both database references in Railway service variables:
- Reference `Postgres` service → `DATABASE_PUBLIC_URL`
- Reference `En-Garde-FlowDB` service → `LANGFLOW_DATABASE_URL`

## Deployment History

### Resolution Timeline

1. **Issue Identified**: Langflow startup hang with infinite "Launching Langflow..." spinner
2. **Root Cause**: Dual-schema PostgreSQL causing migration conflicts
3. **Solution**: Created dedicated `En-Garde-FlowDB` PostgreSQL instance
4. **Result**: Langflow initialization time: ~100s (normal)

**Working Deployment**:
- Commit: `0bdd21319` (Jan 19, 2026)
- Langflow with SSO + dedicated database
- Status: ✅ Operational

### Key Commits

- `692baa290` - First deployment with dedicated database (SSO disabled for testing)
- `0bdd21319` - Production deployment with SSO re-enabled

## Maintenance

### Database Backups

Each database should be backed up independently:
- EnGarde Main: Full application state
- Langflow: Workflow definitions and execution history

### Migration Management

- **EnGarde**: Uses own migration system (Alembic/SQLAlchemy)
- **Langflow**: Uses Langflow's built-in Alembic migrations
- No coordination needed between systems

### Monitoring

Monitor both databases separately:
- Connection pool utilization
- Query performance
- Disk usage
- Replication lag (if applicable)

## Future Considerations

### Potential Enhancements

1. **Read Replicas**: Add read replicas for heavy analytical queries
2. **Connection Pooling**: Consider PgBouncer for connection management
3. **Data Sync**: If needed, implement event-driven sync between databases
4. **Cross-Database Queries**: Use FDW (Foreign Data Wrappers) if complex joins needed

### Scaling Strategy

- Langflow database can scale independently based on workflow execution volume
- EnGarde database scales based on user/campaign growth
- Consider sharding if either database exceeds single-instance limits
