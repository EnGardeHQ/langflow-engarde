# Agents Display Fix - Quick Start

## Problem
Agents are not displaying for `demo@engarde.com` because they're not mapped to the demo user's tenant.

## Solution
Run the fix endpoint or script to map existing agents to the demo user's tenant.

## Option 1: API Endpoint (Easiest)

After deployment, call the maintenance endpoint:

```bash
curl -X POST https://app.engarde.media/api/maintenance/fix-agents-tenant-mapping
```

Or with a specific email:
```bash
curl -X POST "https://app.engarde.media/api/maintenance/fix-agents-tenant-mapping?email=demo@engarde.com"
```

**Response:**
```json
{
  "status": "success",
  "user_email": "demo@engarde.com",
  "tenant_id": "...",
  "agents_mapped": 5,
  "agents_created": 0,
  "final_agent_count": 5,
  "message": "Successfully mapped 5 agents to tenant ..."
}
```

## Option 2: Railway CLI

The script automatically uses `DATABASE_PUBLIC_URL` if available (Railway's public database URL):

```bash
cd production-backend
railway run python scripts/fix_agents_tenant_mapping.py
```

The script will:
- Use `DATABASE_PUBLIC_URL` if set (preferred for Railway)
- Fall back to `DATABASE_URL` if `DATABASE_PUBLIC_URL` is not available

## Option 3: SQL Script

Connect to Railway PostgreSQL and run:

```bash
railway connect postgres
psql < scripts/fix_agents_tenant_mapping.sql
```

## What It Does

1. ✅ Finds demo user (`demo@engarde.com`)
2. ✅ Gets demo user's active brand and tenant_id
3. ✅ Ensures tenant has `plan_tier` set (defaults to "professional" if NULL)
4. ✅ Maps all existing agents to demo user's tenant if none are mapped
5. ✅ Creates 3 demo agents if no agents exist at all

## Verification

After running the fix, verify agents are visible:

1. **Check API endpoint:**
   ```bash
   curl -H "Authorization: Bearer <token>" \
     https://app.engarde.media/api/agents/installed
   ```

2. **Check database:**
   ```sql
   SELECT COUNT(*) 
   FROM ai_agents 
   WHERE tenant_id = (
       SELECT b.tenant_id 
       FROM brands b
       JOIN user_active_brands uab ON uab.brand_id = b.id
       JOIN users u ON u.id = uab.user_id
       WHERE u.email = 'demo@engarde.com'
       LIMIT 1
   );
   ```

## Files Created

- `app/routers/maintenance.py` - Added `/api/maintenance/fix-agents-tenant-mapping` endpoint
- `scripts/fix_agents_tenant_mapping.py` - Python script for Railway CLI
- `scripts/fix_agents_tenant_mapping.sql` - SQL script for direct database access
- `scripts/diagnose_agents_display_issue.py` - Diagnostic script
- `scripts/README_AGENTS_FIX.md` - Detailed documentation

## Next Steps

1. **Deploy** the changes (already pushed to `main` branch)
2. **Run** the fix endpoint: `POST /api/maintenance/fix-agents-tenant-mapping`
3. **Verify** agents are displaying in the UI
4. **Test** the agents endpoints:
   - `GET /api/agents/installed`
   - `GET /api/agents/analytics`
   - `GET /api/agents/config`

## Architecture Notes

- **Subscription tier** only limits **creation** of agents, not **viewing**
- Agents are queried by `tenant_id` only
- The demo user's tenant comes from their **active brand**, not directly from the user
- If no agents exist, the script creates 3 demo agents automatically
