# Dual Database Setup - Complete

## Summary

✅ **Langflow startup issue RESOLVED** by migrating to dedicated database architecture.

## Root Cause

The shared PostgreSQL database with dual-schema setup (`public` for EnGarde, `langflow` for Langflow) was causing:
- Migration conflicts
- Database state corruption
- Infinite startup loops

## Solution Implemented

Created **dedicated PostgreSQL databases**:
- **EnGarde Main DB** (`Postgres` service) - Application data
- **Langflow DB** (`En-Garde-FlowDB` service) - Flow and workflow data

## Current Configuration

### Langflow Service (`langflow-server`)

**Environment Variables Required**:
1. `LANGFLOW_DATABASE_URL` → Points to `En-Garde-FlowDB`
   - Used by Langflow core for flow storage
   - Format: `postgresql://postgres:<password>@<host>:<port>/railway`

2. `DATABASE_PUBLIC_URL` → Points to `Postgres` (EnGarde Main DB)
   - Used by EnGarde custom components
   - Needed by: `current_user_tenant.py`, `load_user_config.py`
   - Format: `postgresql://postgres:<password>@<host>:<port>/railway`

### Railway Setup

The `langflow-server` service should have **both database references**:
- ✅ Reference to `En-Garde-FlowDB` (provides `LANGFLOW_DATABASE_URL`)
- ✅ Reference to `Postgres` (provides `DATABASE_PUBLIC_URL`)

## Components Requiring Dual Database Access

### 1. current_user_tenant.py

**Purpose**: Retrieves tenant ID from authenticated user session
**Database Need**: EnGarde Main DB (`DATABASE_PUBLIC_URL`)
**Usage**: Queries user records to extract tenant_id

```python
SecretStrInput(
    name="database_url",
    display_name="Database URL",
    value=os.getenv("DATABASE_PUBLIC_URL", ""),
)
```

### 2. load_user_config.py

**Purpose**: Loads user-specific Walker agent configuration
**Database Need**: EnGarde Main DB (`DATABASE_PUBLIC_URL`)
**Usage**: Retrieves customized settings for tenant and agent type

```python
SecretStrInput(
    name="database_url",
    display_name="Database URL",
    value=os.getenv("DATABASE_PUBLIC_URL", ""),
)
```

## Verification Steps

### 1. Check Environment Variables

```bash
railway variables
```

Should show:
- `LANGFLOW_DATABASE_URL` (from En-Garde-FlowDB reference)
- `DATABASE_PUBLIC_URL` (from Postgres reference)

### 2. Test Component Access

Run a flow using `CurrentUserTenant` or `LoadUserConfig` components:
- Should successfully connect to EnGarde database
- Should retrieve user/tenant data
- No database connection errors

### 3. Verify Langflow Startup

```bash
railway logs
```

Should show:
- `Welcome to EnGarde Agent Suite`
- `Total initialization time: ~100s`
- No migration conflicts or hangs

## Deployment Status

**Current Deployment**: ✅ SUCCESS
- Commit: `0bdd21319`
- Date: January 19, 2026
- Langflow: Operational with SSO
- Database: Dedicated En-Garde-FlowDB

**Startup Time**: ~100 seconds (normal)
**HTTP Status**: 200 OK
**SSO**: ✅ Enabled

## Migration Benefits

### Before (Shared Database)
- ❌ Migration conflicts
- ❌ Startup hangs
- ❌ Database state corruption
- ❌ ~2-3 hour troubleshooting cycles

### After (Dedicated Databases)
- ✅ Clean Langflow startups
- ✅ No migration conflicts
- ✅ Independent schema evolution
- ✅ ~100 second initialization

## Future Maintenance

### Adding New Components That Need EnGarde Data

If creating new Langflow components that query EnGarde data:

1. Add `database_url` input with `DATABASE_PUBLIC_URL` default:
```python
SecretStrInput(
    name="database_url",
    display_name="Database URL",
    value=os.getenv("DATABASE_PUBLIC_URL", ""),
)
```

2. Use this connection for queries to EnGarde tables
3. Keep Langflow-specific data in Langflow DB

### Database Backups

Backup both databases independently:
- `En-Garde-FlowDB`: Flow definitions, execution history
- `Postgres`: Campaign data, user data, analytics

### Scaling

Each database can scale independently based on workload:
- Langflow DB: Scales with flow execution volume
- EnGarde DB: Scales with user/campaign growth

## Related Documentation

- `DATABASE_ARCHITECTURE.md` - Full architecture details
- `Dockerfile` - SSO integration and branding
- `railway.toml` - Deployment configuration

## Troubleshooting

### Issue: Component can't connect to EnGarde database

**Check**:
```bash
railway variables | grep DATABASE_PUBLIC_URL
```

**Fix**: Add `Postgres` service reference in Railway dashboard

### Issue: Langflow won't start

**Check**:
```bash
railway logs | grep "database\|migration"
```

**Fix**: Verify `LANGFLOW_DATABASE_URL` points to `En-Garde-FlowDB`

### Issue: SSO not working

**Check**: Dockerfile has SSO installation uncommented (lines 293-324)

**Verify**: `custom_router` is registered in Langflow API

## Success Metrics

✅ Langflow starts in ~100 seconds
✅ No migration conflicts in logs
✅ HTTP 200 response from Langflow URL
✅ SSO authentication functional
✅ Walker Agent components can access EnGarde data
✅ Dedicated database isolation achieved

---

**Issue Resolution Date**: January 19, 2026
**Resolved By**: Database architecture redesign (dual-database separation)
**Status**: ✅ **PRODUCTION READY**
