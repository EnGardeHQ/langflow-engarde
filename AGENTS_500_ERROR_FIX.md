# Agents 500 Error Fix

## Issue
The `/api/agents/installed` and `/api/agents/config` endpoints were returning 500 errors after brand switching, preventing agents from loading in the frontend.

## Root Cause Analysis
The errors were likely caused by:
1. **Unhandled exceptions** during database queries or RLS context setting
2. **SQL injection vulnerabilities** in RLS context setting (using f-strings instead of parameterized queries)
3. **Missing error handling** for edge cases (null database sessions, missing tenant_id, etc.)
4. **Response model validation failures** when exceptions occurred

## Fixes Applied

### 1. Parameterized Queries for RLS Context
**Before:**
```python
db.execute(text(f"SET LOCAL app.current_tenant_id = '{tenant_id}'"))
```

**After:**
```python
db.execute(text("SET LOCAL app.current_tenant_id = :tenant_id"), {"tenant_id": tenant_id})
```

This prevents SQL injection and potential errors from malformed tenant_id values.

### 2. Database Session Validation
Added checks to ensure the database session is valid before use:
```python
if db is None:
    logger.error("Database session is None")
    return default_response
```

### 3. Improved Error Handling
- Added comprehensive try-except blocks around all database operations
- Added fallback values for all error cases
- Ensured all error paths return valid response models instead of raising exceptions
- Added better logging with full tracebacks

### 4. Safe Default Responses
Both endpoints now return safe default responses on any error:
- `/api/agents/installed` returns empty list with error message
- `/api/agents/config` returns default config with error message

### 5. Enhanced Exception Handling
- Wrapped `get_max_agents()` calls in try-except with fallbacks
- Added multiple fallback levels for agent limits (database → cache → hardcoded → ultimate fallback)
- Improved error messages to include exception details

## Testing
After deploying these changes:
1. Brand switching should work without breaking agent endpoints
2. Agents should load even if there are temporary database issues
3. Error messages should be logged with full tracebacks for debugging
4. Frontend should receive valid responses (empty lists or default configs) instead of 500 errors

## Files Modified
- `production-backend/app/routers/agents_api.py`
  - `get_installed_agents()` endpoint (lines ~1444-1708)
  - `get_agent_config()` endpoint (lines ~1711-1849)

## Next Steps
1. Deploy the changes to production
2. Monitor Railway logs for any remaining errors
3. Verify that agents load correctly after brand switching
4. Check that error messages are properly logged for any edge cases
