# Agents 500 Error - RLS Policy Diagnosis

## Problem
The `/api/agents/installed` and `/api/agents/config` endpoints are returning 500 errors, preventing agents from displaying in the UI.

## Root Cause: RLS Policy Issue

The `ai_agents` table has Row Level Security (RLS) enabled with this policy:

```sql
CREATE POLICY ai_agents_isolation_policy ON ai_agents
    FOR ALL
    USING (tenant_id = get_current_tenant_id());
```

The `get_current_tenant_id()` function returns:
```sql
RETURN current_setting('app.current_tenant_id', true);
```

**The Problem**: If `app.current_tenant_id` is not set (returns NULL), the RLS policy `tenant_id = NULL` will **never match any rows** (NULL != anything in SQL), effectively blocking all agents.

## How RLS Context Should Be Set

1. **Event Listener** (`app/database.py`): Automatically sets `app.current_tenant_id` via `set_config()` before each query
2. **Explicit SET LOCAL** (`agents_api.py`): Endpoints also call `SET LOCAL app.current_tenant_id` as backup

## Diagnostic Steps

### Step 1: Test RLS Context
Visit the diagnostic endpoint:
```
GET https://app.engarde.media/api/agents/debug/test-endpoints
```

This will show:
- Whether `get_tenant_id_from_current_brand()` works
- Whether RLS context is being set correctly
- Whether `get_current_tenant_id()` returns the expected value
- Whether agents can be queried with RLS applied

### Step 2: Check RLS Policy
Run the SQL script to check current RLS policies:
```bash
railway connect postgres
psql < scripts/check_rls_policies.sql
```

### Step 3: Fix RLS Policy (if needed)
If the policy is blocking access, run:
```bash
psql < scripts/fix_rls_policy_for_agents.sql
```

This updates the policy to handle NULL cases gracefully.

## Fixes Applied

1. ✅ **Enhanced Error Handling**: Added try-except around response model creation
2. ✅ **RLS Context Verification**: Added verification that `app.current_tenant_id` is set correctly
3. ✅ **Diagnostic Endpoint**: Added `/api/agents/debug/test-endpoints` to test RLS context
4. ✅ **RLS Policy Fix Script**: Created SQL script to fix policy if it's blocking access
5. ✅ **Better Logging**: Added detailed logging to identify where errors occur

## Next Steps

1. **After deployment**, visit the diagnostic endpoint to see what's failing:
   ```
   https://app.engarde.media/api/agents/debug/test-endpoints
   ```

2. **Check Railway logs** for:
   - `[AGENTS-RETRIEVAL]` logs showing RLS context
   - Any errors in `get_tenant_id_from_current_brand`
   - Any errors in RLS context setting

3. **If RLS policy is blocking**, run the fix script:
   ```bash
   railway connect postgres
   psql < scripts/fix_rls_policy_for_agents.sql
   ```

## Expected Behavior

After fixes:
- `/api/agents/installed` should return agents (even if empty list)
- `/api/agents/config` should return config with `current_plan: "business"`
- RLS context should be set before each query
- No 500 errors should occur

## Files Created

- `scripts/fix_rls_policy_for_agents.sql` - Fixes RLS policy to handle NULL
- `scripts/check_rls_policies.sql` - Checks current RLS policies
- Enhanced `/api/agents/debug/test-endpoints` - Diagnostic endpoint
