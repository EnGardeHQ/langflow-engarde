# Content Endpoint Fix Summary

## Issue
The `/api/content` endpoint was returning `500 Internal Server Error` because it was using `get_current_tenant_context` which relies on `current_user.tenant_id`, but users don't have a direct `tenant_id` - they get it from their active brand.

## Root Cause
The content endpoint was using the old tenant context pattern:
```python
tenant_context = Depends(get_current_tenant_context)
tenant_id = tenant_context["tenant_id"]  # This fails because user.tenant_id is None
```

## Solution
Updated the content endpoint to use the same pattern as the agents endpoint:
1. Added `get_tenant_id_from_current_brand()` function to content.py
2. Updated all content endpoints to use this function
3. Added RLS context setting using `set_current_tenant_id()` and `set_current_user_id()`
4. Updated pagination to use `page` and `pageSize` parameters (matching frontend expectations)

## Changes Made

### 1. Added Helper Function
```python
def get_tenant_id_from_current_brand(db: Session, current_user: User) -> Optional[str]:
    """Get tenant_id from the user's currently active brand."""
    # Gets active brand from UserActiveBrand or BrandMember
    # Returns brand.tenant_id
```

### 2. Updated All Endpoints
- `GET /api/content` - Get content items
- `POST /api/content` - Create content
- `GET /api/content/{content_id}` - Get specific content
- `PATCH /api/content/{content_id}` - Update content
- `DELETE /api/content/{content_id}` - Delete content

### 3. Added RLS Context Setting
All endpoints now set tenant context before querying:
```python
from app.database import set_current_tenant_id, set_current_user_id
set_current_tenant_id(tenant_id)
set_current_user_id(str(current_user.id))
```

### 4. Fixed Pagination
Changed from `skip`/`limit` to `page`/`pageSize` to match frontend expectations.

## Testing
The endpoint should now:
1. ✅ Get tenant_id from active brand (not from user directly)
2. ✅ Set RLS context properly
3. ✅ Return content items for the tenant
4. ✅ Handle pagination correctly
5. ✅ Return empty list if no tenant_id found (instead of 500 error)

## Migration Status
✅ Database migration for marketplace fields completed successfully
