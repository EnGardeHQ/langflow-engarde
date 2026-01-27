# C10: Langflow Context JWT Implementation

**Status:** ✅ COMPLETE
**Date:** 2026-01-27
**Task:** Update Langflow integration to use Context JWT in production-frontend

---

## Overview

Successfully implemented C10 from MASTER_IMPLEMENTATION_PLAN.md by updating the Langflow iframe integration to use the `LangflowContext` for JWT management instead of directly calling the SSO endpoint.

---

## Changes Made

### 1. Updated AuthenticatedLangflowIframe Component
**File:** `/Users/cope/EnGardeHQ/production-frontend/components/workflow/AuthenticatedLangflowIframe.tsx`

**Key Changes:**
- ✅ Imported `useLangflowContext` hook from `@/contexts/LangflowContext`
- ✅ Replaced direct SSO calls with context-managed JWT
- ✅ Added initialization logic to fetch current context on mount
- ✅ Implemented automatic JWT refresh handling via useEffect
- ✅ Added comprehensive documentation explaining JWT refresh and context switching flows
- ✅ Updated loading states to distinguish between context loading and iframe loading

**Before:**
```typescript
// Direct SSO call on every mount
const ssoResponse = await apiClient.post('/v1/sso/langflow', {});
const ssoUrl = ssoResponse.data.sso_url;
setIframeUrl(ssoUrl);
```

**After:**
```typescript
// Use context-managed JWT
const { jwt, isLoading: isContextLoading, getCurrentContext, state } = useLangflowContext();

// Initialize context on mount
useEffect(() => {
  getCurrentContext();
}, []);

// Automatically refresh when JWT changes
useEffect(() => {
  if (jwt) {
    setupAuthenticatedIframe();
  }
}, [jwt, flowId, state.tenantId, state.workspaceId, state.brandId]);
```

### 2. Added LangflowProvider to App Layout
**File:** `/Users/cope/EnGardeHQ/production-frontend/app/layout.tsx`

**Changes:**
- ✅ Imported `LangflowProvider` from `@/contexts/LangflowContext`
- ✅ Wrapped application with `LangflowProvider` in the provider chain
- ✅ Positioned after `BrandProvider` and before `WebSocketProvider`

**Provider Hierarchy:**
```
ChakraProvider
  → QueryProvider
    → AuthProvider
      → ApiErrorProvider
        → BrandProvider
          → LangflowProvider ← NEW
            → WebSocketProvider
              → App Content
```

---

## Architecture & Behavior

### JWT Refresh Flow (Automatic)

1. **LangflowContext** automatically refreshes JWT every 4 minutes (JWT expires in 5 minutes)
2. When JWT changes, `useEffect` in `AuthenticatedLangflowIframe` triggers with new JWT
3. `setupAuthenticatedIframe()` is called with new JWT
4. New SSO URL is generated and iframe is updated
5. User continues working without interruption

### Context Switching Flow (User-Initiated)

1. User selects different tenant/workspace/brand via UI
2. `LangflowContext.switchContext()` is called
3. New JWT is generated with updated context
4. `useEffect` detects JWT change and updates iframe
5. Langflow now operates in new context

### Initial Load Flow

1. Component mounts → calls `getCurrentContext()`
2. LangflowContext fetches current tenant/workspace/brand context
3. JWT is generated with context information
4. `setupAuthenticatedIframe()` generates SSO URL with JWT
5. Iframe loads with authenticated session

---

## Benefits

### 1. Centralized JWT Management
- Single source of truth for Langflow JWT state
- Eliminates duplicate JWT fetch logic
- Consistent JWT handling across all Langflow integrations

### 2. Automatic JWT Refresh
- No manual refresh logic needed in components
- Context handles refresh timer automatically
- Prevents JWT expiry during active sessions

### 3. Context-Aware Sessions
- JWT includes tenant/workspace/brand information
- Supports agency admin context switching
- Maintains proper data isolation

### 4. Improved Developer Experience
- Simple `useLangflowContext()` hook
- Clear separation of concerns
- Easy to extend for future features

### 5. Better Error Handling
- Context provides unified error state
- Loading states managed by context
- Graceful fallback on errors

---

## Files Modified

1. `/Users/cope/EnGardeHQ/production-frontend/components/workflow/AuthenticatedLangflowIframe.tsx`
   - Updated to use `useLangflowContext` hook
   - Added JWT refresh handling
   - Added comprehensive documentation

2. `/Users/cope/EnGardeHQ/production-frontend/app/layout.tsx`
   - Added `LangflowProvider` import
   - Wrapped app with `LangflowProvider`

---

## Testing Recommendations

### Unit Tests
- [ ] Test `AuthenticatedLangflowIframe` initializes context on mount
- [ ] Test iframe updates when JWT changes
- [ ] Test error handling when context fails to load
- [ ] Test loading states during context initialization

### Integration Tests
- [ ] Test JWT refresh at 4-minute mark
- [ ] Test context switching updates iframe
- [ ] Test tenant/workspace/brand context is passed correctly
- [ ] Test agency admin can switch between client contexts

### E2E Tests
- [ ] Test user can access Langflow iframe
- [ ] Test JWT refresh doesn't interrupt user workflow
- [ ] Test context switching in UI
- [ ] Test multiple concurrent users with different contexts

---

## Backend Integration

This implementation relies on existing backend endpoints:

### Required Endpoints (Already Implemented)
✅ `GET /api/langflow/current-context` - Get current user's context
✅ `POST /api/langflow/switch-context` - Switch to different context
✅ `POST /api/v1/sso/langflow` - Generate SSO URL with JWT

### Backend Files
- `/Users/cope/EnGardeHQ/production-backend/app/routers/langflow_context.py` - Context switching logic
- `/Users/cope/EnGardeHQ/production-backend/app/routers/langflow_sso.py` - SSO token generation

---

## Future Enhancements

### Potential Improvements
1. **Context Selector UI Component** (C8 in MASTER_IMPLEMENTATION_PLAN.md)
   - Add dropdown to switch between tenants/workspaces/brands
   - Show current context in UI
   - Filter by user's access permissions

2. **JWT Preemptive Refresh**
   - Refresh JWT on user activity (e.g., before making API calls)
   - Reduce chance of expired JWT during operations

3. **Offline JWT Caching**
   - Cache JWT in secure storage
   - Restore context on page reload
   - Reduce initial load time

4. **Multi-Iframe Support**
   - Support multiple Langflow iframes with different contexts
   - Useful for side-by-side comparison workflows

---

## Compliance with Development Rules

✅ **ENGARDE_DEVELOPMENT_RULES.md**
- Used `useLangflowContext()` hook as specified
- Handled JWT expiry and refresh automatically
- Followed existing patterns in codebase

✅ **Code Quality**
- Added comprehensive documentation
- Maintained type safety (TypeScript)
- Used existing `apiClient` for API calls
- Followed React hooks best practices

✅ **Architecture**
- Integrated with existing provider hierarchy
- Maintained separation of concerns
- Reused existing `LangflowContext` implementation
- No breaking changes to existing code

---

## Verification

### Type Check
```bash
cd /Users/cope/EnGardeHQ/production-frontend
npm run type-check
```
**Result:** ✅ No TypeScript errors

### Files to Review
1. Component implementation: `components/workflow/AuthenticatedLangflowIframe.tsx`
2. Provider integration: `app/layout.tsx`
3. Context implementation: `contexts/LangflowContext.tsx` (existing)

---

## Rollout Plan

### Development
1. ✅ Update `AuthenticatedLangflowIframe` component
2. ✅ Add `LangflowProvider` to layout
3. ✅ Verify TypeScript compilation
4. [ ] Test locally with Langflow instance
5. [ ] Verify JWT refresh behavior

### Staging
1. [ ] Deploy to staging environment
2. [ ] Test with real tenant/workspace/brand data
3. [ ] Verify context switching works
4. [ ] Monitor for JWT expiry issues
5. [ ] Test agency admin context switching

### Production
1. [ ] Deploy to production
2. [ ] Monitor error rates
3. [ ] Verify JWT refresh logs
4. [ ] Collect user feedback
5. [ ] Document any issues

---

## Success Criteria

✅ Component uses `useLangflowContext()` hook
✅ JWT is managed by context instead of direct calls
✅ JWT refresh handled automatically
✅ Context switching supported
✅ No TypeScript errors
✅ Documentation added
✅ Existing functionality preserved

---

## Related Tasks

- **C7:** Create Langflow Context Provider (Already Complete)
- **C8:** Create Brand/Client Selector Component (Pending)
- **C9:** Add Context Selector to Workflow Pages (Pending)
- **C10:** Update Langflow Integration to Use Context JWT (✅ Complete)
- **C11:** Testing Frontend (Pending)

---

## Notes

- The `LangflowContext` already implements the JWT refresh timer (4 minutes)
- The SSO endpoint still generates the iframe URL, but now uses the context JWT
- Context switching will require UI components (C8, C9) to be implemented
- Agency admins can switch contexts once UI is built
