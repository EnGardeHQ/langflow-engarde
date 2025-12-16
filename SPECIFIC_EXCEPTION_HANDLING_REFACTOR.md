# Specific Exception Handling Refactor

## Summary

Refactored exception handling in `agents_api.py` to catch only **specific exception types** instead of using catch-all `except Exception` blocks. This prevents HTTPExceptions from being accidentally caught and converted to 500 errors.

## Changes Made

### 1. Added SQLAlchemy Exception Imports

```python
from sqlalchemy.exc import SQLAlchemyError, OperationalError, DatabaseError, IntegrityError
```

### 2. Replaced Generic Exception Handlers

**Before:**
```python
try:
    tenant_id = get_tenant_id_from_current_brand(db, current_user)
except HTTPException:
    raise  # Redundant!
except Exception as tenant_error:
    logger.error(...)
    tenant_id = None
```

**After:**
```python
try:
    tenant_id = get_tenant_id_from_current_brand(db, current_user)
except SQLAlchemyError as tenant_error:
    logger.error(...)
    tenant_id = None
# HTTPExceptions propagate naturally - no need to catch and re-raise
```

### 3. Updated Exception Types by Context

- **Database operations**: `SQLAlchemyError` (covers all SQLAlchemy exceptions)
- **Data serialization**: `ValueError`, `TypeError`, `AttributeError` (for date formatting, type conversions)
- **Configuration functions**: `ValueError`, `TypeError` (for `get_max_agents`, `get_agent_limit`)

## Benefits

1. **HTTPExceptions propagate naturally**: No need to catch and re-raise them
2. **More precise error handling**: Only catch exceptions we expect and can handle
3. **Prevents accidental exception swallowing**: HTTPExceptions won't be caught by database error handlers
4. **Better code clarity**: Makes it clear what types of errors each handler expects
5. **Prevents similar issues**: Other parts of the codebase won't accidentally catch HTTPExceptions

## Exception Handling Strategy

### Database Operations
```python
try:
    agents = db.query(AIAgent).filter(...).all()
except SQLAlchemyError as db_error:
    # Handle database errors (connection, query, RLS violations, etc.)
    logger.error(...)
    agents = []
```

### Data Processing
```python
try:
    created_at = agent.created_at.isoformat()
except (ValueError, TypeError, AttributeError):
    # Handle data conversion errors
    created_at = None
```

### Configuration Functions
```python
try:
    max_agents = get_max_agents("free")
except (ValueError, TypeError) as limit_error:
    # Handle invalid input errors
    logger.error(...)
    max_agents = 1
```

### Outer Endpoint Handlers (Still Catch-All)
```python
except HTTPException as http_exc:
    # Re-raise HTTP exceptions - these are intentional
    raise
except Exception as e:
    # Catch-all for truly unexpected errors
    logger.error(...)
    return default_response
```

## Files Modified

- `production-backend/app/routers/agents_api.py`
  - Updated `get_tenant_id_from_current_brand()` function
  - Updated `get_installed_agents()` endpoint
  - Updated `get_agent_config()` endpoint
  - Updated `get_agents_analytics()` endpoint
  - Updated debug endpoint exception handlers
  - Updated data serialization error handlers

## Testing Recommendations

1. Verify HTTPExceptions (401, 404, 403, etc.) propagate correctly
2. Verify database errors are handled gracefully
3. Verify data serialization errors don't crash endpoints
4. Check logs to ensure proper error categorization
