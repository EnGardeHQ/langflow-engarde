# Langflow EnGarde Integration - Complete Activation Guide

## Executive Summary

**Status**: All code is implemented. Infrastructure is configured. Only activation steps remain.

**What's Already Done**:
- ✅ SSO authentication endpoints (both sides)
- ✅ 14 Walker Agent custom components built
- ✅ PostgreSQL database with `langflow` schema
- ✅ Multi-tenant isolation with RLS policies
- ✅ Frontend pages for Agent Suite
- ✅ Backend APIs for flow management
- ✅ Langflow deployed on Railway at `https://langflow.engarde.media`

**What Needs Activation**:
1. Set environment variables in Railway (5 minutes)
2. Verify custom components are loaded (2 minutes)
3. Test SSO authentication flow (5 minutes)
4. Verify multi-tenant isolation (5 minutes)

**Total Time to Activate**: ~20 minutes

---

## Architecture Overview

```
EnGarde Platform (app.engarde.media)
    │
    ├── Frontend (/agent-suite page) ────────┐
    │                                          │
    ├── Backend API (/api/v1/sso/langflow) ──┤
    │         generates JWT token             │
    │                                          ▼
    │                              Langflow (langflow.engarde.media)
    │                                          │
    │                              ┌───────────┴─────────────┐
    │                              │                         │
    └────────────────────────────► │  SSO Login Endpoint     │
                                   │  (/api/v1/custom/       │
                                   │   sso_login)            │
                                   │                         │
                                   │  • Validates JWT        │
                                   │  • Creates/updates user │
                                   │  • Sets auth cookies    │
                                   │  • Redirects to UI      │
                                   │                         │
                                   └───────────┬─────────────┘
                                               │
                        ┌──────────────────────┼──────────────────────┐
                        │                      │                      │
                   14 Walker          PostgreSQL DB         Multi-tenant
                   Agent Custom       (langflow schema)     Isolation
                   Components                               (RLS policies)
```

---

## Part 1: Environment Variables Setup

### Required Variables for `langflow-server` Service

Set these in Railway dashboard for the **langflow-server** service:

```bash
# SSO Shared Secret (must match production-backend)
LANGFLOW_SECRET_KEY=66Frxa-W2jv1e7PrSlRbFR4bxCut0uN-wyzSNiRdid0

# Custom Components Path
LANGFLOW_COMPONENTS_PATH=/app/components/engarde_components

# Walker Agent API Keys (for custom components)
WALKER_AGENT_API_KEY_ONSIDE_SEO=wa_onside_production_...
WALKER_AGENT_API_KEY_SANKORE_PAID_ADS=wa_sankore_production_...
WALKER_AGENT_API_KEY_ONSIDE_CONTENT=wa_onside_production_...
WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE=wa_madansara_production_...

# EnGarde Backend URL (for Walker components to call back)
ENGARDE_API_URL=https://api.engarde.media

# Database Connection (should already be set via Railway)
LANGFLOW_DATABASE_URL=postgresql://user:pass@host:port/db?options=-csearch_path=langflow,public
```

### Required Variables for `production-backend` Service

```bash
# Langflow Integration
LANGFLOW_BASE_URL=https://langflow.engarde.media
LANGFLOW_SECRET_KEY=66Frxa-W2jv1e7PrSlRbFR4bxCut0uN-wyzSNiRdid0
```

### How to Set Via Railway Dashboard

1. Go to https://railway.app
2. Select "EnGarde Suite" project
3. Select "production" environment
4. Click "langflow-server" service
5. Go to "Variables" tab
6. Click "New Variable" for each one above
7. Service will auto-redeploy

### How to Verify

```bash
# Check langflow-server variables
railway link --service langflow-server
railway variables | grep -E "LANGFLOW_SECRET_KEY|LANGFLOW_COMPONENTS_PATH|WALKER_AGENT"

# Check production-backend variables
railway link --service production-backend
railway variables | grep -E "LANGFLOW_BASE_URL|LANGFLOW_SECRET_KEY"
```

---

## Part 2: Custom Components Verification

The 14 Walker Agent components are located in:
```
/Users/cope/EnGardeHQ/langflow-engarde/En Garde Components/
```

### Components List

1. **seo_walker_agent.py** - Complete SEO analysis agent
2. **paid_ads_walker_agent.py** - Paid advertising optimization
3. **content_walker_agent.py** - Content gap analysis
4. **audience_intelligence_walker_agent.py** - Audience segmentation
5. **campaign_creation_agent.py** - Campaign builder
6. **campaign_launcher_agent.py** - Campaign launcher
7. **analytics_report_agent.py** - Analytics reporting
8. **content_approval_agent.py** - Content approval workflow
9. **notification_agent.py** - Notification sender
10. **performance_monitoring_agent.py** - Performance tracking
11. **tenant_id_input.py** - Tenant ID input component
12. **walker_suggestion_builder.py** - Suggestion builder
13. **walker_agent_api.py** - API request component
14. **README.md** - Complete documentation

### Verify Components Are Loaded

After setting `LANGFLOW_COMPONENTS_PATH` and redeploying:

1. **Check Langflow logs**:
   ```bash
   railway logs --service langflow-server | grep -i "component\|custom"
   ```

   Expected output:
   ```
   INFO: Loading custom components from /app/components/engarde_components
   INFO: Loaded component: SEOWalkerAgent
   INFO: Loaded component: PaidAdsWalkerAgent
   ... (14 total)
   ```

2. **Check via Langflow UI**:
   - Visit https://langflow.engarde.media
   - Create new flow
   - Look in left sidebar for "En Garde Components" category
   - Should see all 14 components listed

3. **Test component**:
   - Drag "SEO Walker Agent" onto canvas
   - Verify it has these inputs:
     - tenant_id (text input)
     - api_url (auto-filled from env var)
     - api_key (auto-filled from env var)

---

## Part 3: SSO Authentication Testing

### Test Flow

1. **User clicks "Agent Suite" in EnGarde**:
   - URL: `https://app.engarde.media/agent-suite`
   - Frontend page already exists

2. **Frontend calls SSO endpoint**:
   ```bash
   # Test manually
   curl -X POST https://api.engarde.media/api/v1/sso/langflow \
     -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
   ```

   Expected response:
   ```json
   {
     "sso_url": "https://langflow.engarde.media/api/v1/custom/sso_login?token=eyJ...",
     "expires_in": 300
   }
   ```

3. **User is redirected to SSO URL**:
   - Langflow receives JWT token
   - Validates with shared secret
   - Creates/updates user in `langflow.user` table
   - Sets authentication cookies
   - Redirects to Langflow dashboard

4. **Verify user was created**:
   ```sql
   SELECT id, username, is_superuser, is_active, created_at
   FROM langflow.user
   WHERE username = 'your-email@example.com'
   ORDER BY created_at DESC;
   ```

### SSO Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| "SSO not configured" | `LANGFLOW_SECRET_KEY` not set in production-backend | Set variable and redeploy |
| "Invalid SSO token" | Secret key mismatch between services | Ensure both services have identical `LANGFLOW_SECRET_KEY` |
| User redirected but not logged in | Cookie domain issues | Verify both are under `engarde.media` parent domain |
| "Expired token" | Too much time between generation and use | Token expires in 5 min, regenerate if needed |

---

## Part 4: Multi-Tenant Isolation Verification

### Test Tenant Isolation

1. **Create test users in different tenants**:
   ```sql
   -- Get two different tenant IDs
   SELECT id, name FROM tenants LIMIT 2;
   ```

2. **Login as Tenant A user**:
   - Navigate to `/agent-suite`
   - SSO authenticate
   - Create a flow in Langflow
   - Note the flow ID

3. **Verify flow has tenant_id**:
   ```sql
   SELECT id, name, tenant_id, folder_id
   FROM langflow.flow
   WHERE id = 'your-flow-id';
   ```

4. **Login as Tenant B user**:
   - SSO authenticate (should create new user)
   - Try to list flows
   - Should NOT see Tenant A's flows

5. **Verify RLS policies work**:
   ```sql
   -- Set tenant context
   SELECT set_config('app.current_tenant_id', 'tenant-b-uuid', true);

   -- Try to query all flows
   SELECT id, name, tenant_id FROM langflow.flow;

   -- Should only return flows for tenant B
   ```

### RLS Policy Verification

The policies are already created. Verify they exist:

```sql
-- Check RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'langflow'
AND tablename IN ('flow', 'folder', 'transaction', 'message');

-- Check policies exist
SELECT schemaname, tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'langflow'
ORDER BY tablename, policyname;
```

Expected policies:
- `flow_tenant_isolation_policy` on `langflow.flow`
- `folder_tenant_isolation_policy` on `langflow.folder`
- `transaction_tenant_isolation_policy` on `langflow.transaction`
- `message_tenant_isolation_policy` on `langflow.message`

---

## Part 5: Walker Agent Testing

### Test Complete Walker Agent Flow

1. **Get a tenant ID**:
   ```sql
   SELECT id, name FROM tenants WHERE name LIKE '%test%' LIMIT 1;
   ```

2. **Login to Langflow as that tenant's user**:
   - Go to `/agent-suite`
   - SSO authenticate

3. **Create SEO Walker Agent flow**:
   - Create new flow
   - Drag "SEO Walker Agent (Complete)" component
   - Set tenant_id to the one from step 1
   - Click "Run"

4. **Verify execution**:
   - Should see success message in output
   - Check backend logs:
     ```bash
     railway logs --service production-backend | grep -i "walker\|suggestion"
     ```

5. **Verify database**:
   ```sql
   SELECT * FROM walker_agent_suggestions
   WHERE tenant_id = 'your-tenant-id'
   ORDER BY created_at DESC
   LIMIT 1;
   ```

6. **Verify execution history in Langflow**:
   ```sql
   SELECT id, flow_id, timestamp, status, inputs, outputs
   FROM langflow.transaction
   WHERE flow_id = 'your-flow-id'
   ORDER BY timestamp DESC
   LIMIT 5;
   ```

---

## Part 6: Frontend Integration Testing

### Test Agent Suite Page

1. **Navigate to page**:
   ```
   https://app.engarde.media/agent-suite
   ```

2. **Verify tabs exist**:
   - "Workflow Builder" tab (embeds Langflow iframe)
   - "My Workflows" tab (lists tenant's flows)
   - "Execution History" tab (shows execution logs)

3. **Test Workflow Builder tab**:
   - Should show Langflow iframe
   - Should be already authenticated (via SSO)
   - Create a simple flow
   - Run it
   - Verify it executes

4. **Test My Workflows tab**:
   - Should call `/api/v1/langflow/flows`
   - Should show list of tenant's flows
   - Click "Execute Workflow" button
   - Should trigger flow execution

5. **Test Execution History tab**:
   - Select a workflow from dropdown
   - Should show execution history table
   - Should display timestamp, status, inputs, outputs

---

## Part 7: Database Schema Verification

### Verify Langflow Tables Exist

```sql
-- List all tables in langflow schema
\dt langflow.*

-- Expected tables:
-- langflow.flow
-- langflow.folder
-- langflow.vertex
-- langflow.edge
-- langflow.transaction
-- langflow.message
-- langflow.user
-- langflow.apikey
-- langflow.variable
-- langflow.alembic_version
```

### Verify Tenant Columns

```sql
-- Check tenant_id column exists
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'langflow'
AND table_name IN ('flow', 'folder', 'transaction', 'user')
AND column_name = 'tenant_id';
```

Expected: `tenant_id` column of type `uuid` in all tables

### Verify Cross-Schema Access

```sql
-- EnGarde can read Langflow flows
SELECT
    c.id as campaign_id,
    c.name as campaign_name,
    f.id as flow_id,
    f.name as flow_name
FROM public.campaigns c
LEFT JOIN langflow.flow f ON f.id::text = c.langflow_flow_id
LIMIT 5;
```

This query should work without errors (proves schemas can access each other).

---

## Part 8: Security Verification

### Test 1: Verify Shared Secret

```bash
# Get secret from production-backend
railway link --service production-backend
railway variables | grep LANGFLOW_SECRET_KEY

# Get secret from langflow-server
railway link --service langflow-server
railway variables | grep LANGFLOW_SECRET_KEY

# They MUST be identical
```

### Test 2: Verify Cookie Security

1. Login to Langflow via SSO
2. Open browser DevTools → Application → Cookies
3. Check `access_token_lf` cookie:
   - Domain: `.engarde.media`
   - HttpOnly: `true`
   - Secure: `true`
   - SameSite: `Lax` or `Strict`

### Test 3: Verify JWT Expiry

```bash
# Decode a JWT token
echo "YOUR_JWT_TOKEN" | cut -d '.' -f 2 | base64 -d | jq '.'
```

Check `exp` field - should be ~5 minutes from `iat`

### Test 4: Verify API Key Protection

Walker Agent API keys should be:
- Stored in Railway environment variables
- NOT visible in component UI
- Passed via environment variable references: `${WALKER_AGENT_API_KEY_...}`

---

## Part 9: Performance Verification

### Check Database Indexes

```sql
-- Verify tenant_id indexes exist
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'langflow'
AND indexname LIKE '%tenant_id%';
```

Expected indexes:
- `idx_langflow_flow_tenant_id`
- `idx_langflow_folder_tenant_id`
- `idx_langflow_transaction_tenant_id`
- `idx_langflow_user_tenant_id`

### Check Query Performance

```sql
-- Should use index scan (not seq scan)
EXPLAIN ANALYZE
SELECT id, name FROM langflow.flow
WHERE tenant_id = '123e4567-e89b-12d3-a456-426614174000';
```

Look for "Index Scan" in output (not "Seq Scan")

---

## Part 10: Monitoring and Logs

### Langflow Logs

```bash
# View real-time logs
railway logs --service langflow-server -f

# Filter for SSO authentication
railway logs --service langflow-server | grep -i "sso\|auth"

# Filter for component loading
railway logs --service langflow-server | grep -i "component"

# Filter for errors
railway logs --service langflow-server | grep -i "error\|exception"
```

### Backend Logs

```bash
# View real-time logs
railway logs --service production-backend -f

# Filter for Langflow integration
railway logs --service production-backend | grep -i "langflow\|sso"

# Filter for Walker Agent API
railway logs --service production-backend | grep -i "walker"
```

### Database Monitoring

```sql
-- Active connections to langflow schema
SELECT
    datname,
    usename,
    application_name,
    state,
    COUNT(*) as connections
FROM pg_stat_activity
WHERE datname = 'engarde'
GROUP BY datname, usename, application_name, state;

-- Langflow table sizes
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'langflow'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Recent flow executions
SELECT
    DATE(timestamp) as date,
    COUNT(*) as executions,
    COUNT(DISTINCT flow_id) as unique_flows,
    COUNT(DISTINCT tenant_id) as unique_tenants
FROM langflow.transaction
WHERE timestamp > NOW() - INTERVAL '7 days'
GROUP BY DATE(timestamp)
ORDER BY date DESC;
```

---

## Checklist: Activation Steps

### Before Starting
- [ ] Read this entire document
- [ ] Have Railway dashboard access
- [ ] Have database access (psql or GUI tool)
- [ ] Have test user credentials

### Step 1: Environment Variables (5 min)
- [ ] Set `LANGFLOW_SECRET_KEY` in langflow-server
- [ ] Set `LANGFLOW_COMPONENTS_PATH` in langflow-server
- [ ] Set 4 `WALKER_AGENT_API_KEY_*` variables in langflow-server
- [ ] Set `ENGARDE_API_URL` in langflow-server
- [ ] Set `LANGFLOW_BASE_URL` in production-backend
- [ ] Set `LANGFLOW_SECRET_KEY` in production-backend
- [ ] Wait for both services to redeploy

### Step 2: Component Verification (2 min)
- [ ] Check langflow-server logs for component loading
- [ ] Login to https://langflow.engarde.media
- [ ] Verify "En Garde Components" category exists
- [ ] Count 14 components visible

### Step 3: SSO Testing (5 min)
- [ ] Login to https://app.engarde.media
- [ ] Navigate to `/agent-suite`
- [ ] Verify redirected to Langflow
- [ ] Verify authenticated automatically
- [ ] Check `langflow.user` table for new user

### Step 4: Multi-Tenant Isolation (5 min)
- [ ] Create flow as Tenant A user
- [ ] Verify `tenant_id` set on flow
- [ ] Login as Tenant B user
- [ ] Verify cannot see Tenant A's flows
- [ ] Run RLS verification queries

### Step 5: Walker Agent Testing (5 min)
- [ ] Create SEO Walker Agent flow
- [ ] Set tenant_id and run
- [ ] Verify success response
- [ ] Check `walker_agent_suggestions` table
- [ ] Check execution in `langflow.transaction`

### Step 6: Frontend Testing (3 min)
- [ ] Test "Workflow Builder" tab
- [ ] Test "My Workflows" tab
- [ ] Test "Execution History" tab
- [ ] Verify all data displays correctly

### Step 7: Documentation (2 min)
- [ ] Bookmark key documentation files
- [ ] Share activation results with team
- [ ] Note any issues encountered

**Total Time**: ~25 minutes

---

## Quick Reference: Key Files

| File | Purpose | Location |
|------|---------|----------|
| SSO Login Endpoint | Langflow SSO authentication | `langflow-engarde/src/backend/base/langflow/api/v1/custom.py` |
| SSO Token Generator | EnGarde backend SSO | `production-backend/app/routers/langflow_sso.py` |
| Walker Components | 14 custom Langflow components | `langflow-engarde/En Garde Components/` |
| RLS Setup Script | Multi-tenant isolation | `production-backend/scripts/apply-langflow-rls.sql` |
| Agent Suite Page | Frontend integration | `production-frontend/app/agent-suite/page.tsx` |

---

## Support and Troubleshooting

### Common Issues

**Issue**: Components don't load
**Fix**: Check `LANGFLOW_COMPONENTS_PATH` is set correctly and service redeployed

**Issue**: SSO fails with "Invalid token"
**Fix**: Ensure `LANGFLOW_SECRET_KEY` is identical in both services

**Issue**: Can see other tenants' flows
**Fix**: Verify RLS policies are enabled, check `tenant_id` is being set

**Issue**: Walker API calls fail
**Fix**: Check `WALKER_AGENT_API_KEY_*` environment variables are set

### Getting Help

1. Check Railway logs first
2. Run database verification queries
3. Test each component independently
4. Review documentation in `langflow-engarde/docs/`

---

## Success Criteria

The integration is successfully activated when:

1. ✅ User can navigate to `/agent-suite` and see Langflow embedded
2. ✅ User is automatically authenticated via SSO (no manual login)
3. ✅ User can only see their tenant's flows (multi-tenant isolation works)
4. ✅ User can drag Walker Agent components and configure them
5. ✅ Walker Agent flows execute successfully
6. ✅ Suggestions appear in `walker_agent_suggestions` table
7. ✅ Execution history is logged in `langflow.transaction` table
8. ✅ Frontend displays flows and execution history correctly

---

**Created**: January 11, 2026
**Version**: 1.0.0
**Status**: Ready for Activation
**Estimated Activation Time**: 25 minutes
