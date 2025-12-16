# Agents 500 Error - Current Status

## Problem
The `/api/agents/installed` and `/api/agents/config` endpoints are returning 500 errors when accessed from the UI (with authentication).

## Diagnostic Endpoint Results
When accessed **without authentication**, the diagnostic endpoint shows:
```json
{
  "user_email": null,
  "user_id": null,
  "authenticated": false,
  "tests": {
    "get_tenant_id": {
      "success": true,
      "tenant_id": null,
      "error": "tenant_id is None"
    }
  }
}
```

## Root Cause Analysis

The diagnostic endpoint shows that **without authentication**, `tenant_id` is `None`, which is expected. However, when users access the endpoints **with authentication** (from the UI), they're still getting 500 errors.

### Possible Causes:

1. **User has no active brand** - If `get_tenant_id_from_current_brand()` returns `None` even when authenticated, the endpoint should return an empty response (not a 500). This suggests the error is happening elsewhere.

2. **RLS Policy blocking access** - The RLS policy `tenant_id = get_current_tenant_id()` might be blocking all rows if `get_current_tenant_id()` returns NULL.

3. **Response serialization error** - The response model validation might be failing.

4. **Exception not being caught** - An exception might be escaping the try-except blocks.

## Next Steps

### Step 1: Access Diagnostic Endpoint While Logged In
Visit the diagnostic endpoint **while logged into the UI**:
```
https://app.engarde.media/api/agents/debug/test-endpoints
```

This will show:
- Whether the user is authenticated
- Whether `tenant_id` can be retrieved
- Whether RLS context is set correctly
- Whether agents can be queried

### Step 2: Check Railway Logs
Look for logs with these prefixes:
- `[AGENTS-RETRIEVAL]` - Shows the flow of the `/installed` endpoint
- `[AGENTS-CONFIG]` - Shows the flow of the `/config` endpoint
- `[AGENTS-RETRIEVAL] ❌` - Shows errors
- `[AGENTS-RETRIEVAL] ✅` - Shows successful steps

### Step 3: Check for Specific Errors
Look for:
- `tenant_id is None` - User has no active brand
- `RLS context mismatch` - RLS policy not working correctly
- `Database error` - Connection or query issues
- `Response validation error` - Pydantic model validation failing

## Fixes Applied

1. ✅ **Enhanced error handling** - All exceptions are caught and return safe defaults
2. ✅ **RLS context verification** - Added checks to ensure RLS context is set
3. ✅ **Response validation** - Added safety checks before returning responses
4. ✅ **Diagnostic endpoint** - Added `/api/agents/debug/test-endpoints` for testing
5. ✅ **Better logging** - Added detailed logging throughout the endpoints

## Expected Behavior After Fixes

- `/api/agents/installed` should return agents (even if empty list) or a safe error response
- `/api/agents/config` should return config with `current_plan: "business"` or safe defaults
- No 500 errors should occur - all errors should be caught and return safe responses

## If Errors Persist

If 500 errors continue after deployment:

1. **Check Railway logs** for the exact error message
2. **Access diagnostic endpoint while logged in** to see what's failing
3. **Check if user has active brand** - The user might need to select a brand first
4. **Check RLS policies** - Run `scripts/check_rls_policies.sql` to verify RLS is configured correctly
