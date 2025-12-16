# Brand Switch Dropdown Fix Analysis

## Current Flow

1. **Frontend**: `components/brands/BrandSelector.tsx`
   - Calls `useSwitchBrand` hook
   - Hook calls `POST /api/brands/:id/switch`

2. **Backend**: `app/routers/brands.py` → `switch_brand()` endpoint
   - Calls `_check_brand_access()` which requires active `BrandMember` record
   - Updates `UserActiveBrand` table
   - Returns brand switch response

## Root Cause Analysis

### Issue 1: Access Check Failure
The `_check_brand_access()` function raises a 403 error if:
- User doesn't have a `BrandMember` record for the brand
- The `BrandMember.is_active` is False
- There's a database query failure

### Issue 2: Error Handling
- Frontend error handling shows generic messages
- Backend errors might not be properly logged
- No retry mechanism for transient failures

### Issue 3: Race Conditions
- Brand list might be cached while membership changes
- Database transaction issues could cause failures

## Permanent Fix Strategy

1. **Improve Error Handling**
   - Add detailed logging at each step
   - Return specific error messages
   - Handle edge cases gracefully

2. **Add Validation**
   - Verify brand exists before checking access
   - Check if brand is deleted/inactive
   - Validate user membership before switch

3. **Frontend Improvements**
   - Better error messages
   - Retry mechanism
   - Refresh brand list after switch

4. **Database Consistency**
   - Ensure BrandMember records are created when brands are created
   - Add database constraints to prevent orphaned records
