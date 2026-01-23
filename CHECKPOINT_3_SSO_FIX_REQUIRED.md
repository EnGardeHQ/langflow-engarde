# Checkpoint 3: SSO Authentication Fix Required

**Date**: January 12, 2026
**Status**: ⚠️ FIX REQUIRED
**Issue**: Cookie domain not set, preventing SSO authentication

---

## Problem Summary

The SSO authentication flow is failing at the cookie handshake stage. When users are redirected from the SSO endpoint to the Langflow dashboard, the authentication cookies are not being accepted by the browser.

### Root Cause

**Missing Environment Variable**: `LANGFLOW_COOKIE_DOMAIN` is not set in langflow-server

Without this setting, cookies are scoped to `langflow.engarde.media` only and cannot be shared across the parent domain `engarde.media`. This breaks SSO when users navigate from `app.engarde.media` to `langflow.engarde.media`.

---

## Error Symptoms

From the browser console:
```
langflow.engarde.media/api/v1/auto_login:1  Failed to load resource: the server responded with a status of 400 ()
langflow.engarde.media/api/v1/config:1  Failed to load resource: the server responded with a status of 403 ()
langflow.engarde.media/api/v1/refresh:1  Failed to load resource: the server responded with a status of 401 ()
Uncaught (in promise) Authentication error
```

### Why This Happens

1. User clicks SSO link with valid JWT token
2. `/api/v1/custom/sso_login` endpoint validates token successfully
3. Endpoint creates user and generates Langflow access token
4. Endpoint sets cookie `access_token_lf` with the token
5. **PROBLEM**: Cookie domain defaults to `langflow.engarde.media` (no cross-subdomain sharing)
6. Endpoint redirects browser to langflow dashboard at `/`
7. Browser loads dashboard but cookie is not sent with API requests
8. API calls fail with 401/403 errors
9. User sees login screen instead of authenticated dashboard

---

## The Fix

### Required Environment Variable

Add this to **langflow-server** in Railway:

```bash
LANGFLOW_COOKIE_DOMAIN=.engarde.media
```

**Important**: The dot prefix `.engarde.media` is crucial - it allows the cookie to be shared across all subdomains:
- `app.engarde.media` ✅
- `langflow.engarde.media` ✅
- `api.engarde.media` ✅

Without the dot, cookies would only work on the exact domain.

---

## Current Environment Configuration

### langflow-server (Current)

```bash
# Cookie Settings
LANGFLOW_COOKIE_HTTPONLY=false
LANGFLOW_ACCESS_SECURE=true
LANGFLOW_REFRESH_SECURE=true
LANGFLOW_ACCESS_SAME_SITE=none
LANGFLOW_REFRESH_SAME_SITE=none
# ❌ MISSING: LANGFLOW_COOKIE_DOMAIN
```

### langflow-server (Required)

```bash
# Cookie Settings
LANGFLOW_COOKIE_HTTPONLY=false           # Keep as false for debugging
LANGFLOW_ACCESS_SECURE=true              # ✅ HTTPS only
LANGFLOW_REFRESH_SECURE=true             # ✅ HTTPS only
LANGFLOW_ACCESS_SAME_SITE=none           # ✅ Allows cross-site
LANGFLOW_REFRESH_SAME_SITE=none          # ✅ Allows cross-site
LANGFLOW_COOKIE_DOMAIN=.engarde.media    # ⭐ ADD THIS
```

---

## Code Reference

The SSO endpoint uses this configuration at:

**File**: `langflow-engarde/src/backend/base/langflow/api/v1/custom.py:136-144`

```python
# Set the access token cookie on the redirect response
redirect_response.set_cookie(
    "access_token_lf",
    access_token,
    httponly=auth_settings.ACCESS_HTTPONLY,
    samesite=auth_settings.ACCESS_SAME_SITE,
    secure=auth_settings.ACCESS_SECURE,
    max_age=60 * 60 * 24 * 30,  # 30 days in seconds
    domain=auth_settings.COOKIE_DOMAIN,  # ⭐ This reads LANGFLOW_COOKIE_DOMAIN
)
```

---

## Implementation Steps

### Step 1: Add Environment Variable

1. Go to Railway dashboard
2. Select `EnGarde Suite` project → `production` environment
3. Click `langflow-server` service
4. Go to **Variables** tab
5. Click **New Variable**
6. Set:
   - Name: `LANGFLOW_COOKIE_DOMAIN`
   - Value: `.engarde.media`
7. Click **Add**
8. Service will auto-redeploy (takes ~2-3 minutes)

### Step 2: Verify Deployment

Wait for deployment to complete:
```bash
# Check deployment status
railway status

# Expected output:
# langflow-server: deployed
```

### Step 3: Test SSO Flow

```bash
# Generate test token
python3 -c "
import jwt
from datetime import datetime, timedelta

SECRET_KEY = '8089de54f58a71771ad1f5665eaa2a927a386d2d5afc86a4dc9eb9f7fad2adbc'

payload = {
    'email': 'test@engarde.com',
    'sub': 'test-user-id',
    'tenant_id': '123e4567-e89b-12d3-a456-426614174000',
    'tenant_name': 'Test Tenant',
    'role': 'user',
    'subscription_tier': 'starter',
    'exp': datetime.utcnow() + timedelta(minutes=5),
    'iat': datetime.utcnow()
}

token = jwt.encode(payload, SECRET_KEY, algorithm='HS256')
print(f'https://langflow.engarde.media/api/v1/custom/sso_login?token={token}')
"
```

Copy the URL and open it in a browser. Expected behavior:
1. Page redirects to Langflow dashboard
2. No login screen appears
3. Dashboard loads successfully
4. No 401/403 errors in console

### Step 4: Verify Cookie in Browser

Open browser DevTools:
1. Go to **Application** tab → **Cookies**
2. Find `access_token_lf` cookie
3. Verify:
   - ✅ Domain: `.engarde.media` (with dot prefix)
   - ✅ Secure: `true`
   - ✅ SameSite: `None`
   - ✅ HttpOnly: `false` (for debugging)
   - ✅ Expires: ~30 days from now

---

## Security Considerations

### Cookie Domain Scope

Setting `LANGFLOW_COOKIE_DOMAIN=.engarde.media` means:
- ✅ SSO works seamlessly across subdomains
- ⚠️ Cookie is shared with all `*.engarde.media` subdomains
- ✅ Still requires HTTPS (`secure=true`)
- ✅ Still protected by JWT signature validation

This is the standard approach for SSO across subdomains and is secure when combined with:
- HTTPS enforcement (`secure=true`)
- Short token expiry (5 minutes for SSO JWT)
- Strong secret key (`LANGFLOW_SECRET_KEY`)

### Alternative: Subdomain-Specific Cookies

If you want tighter security, you could:
1. Keep cookies subdomain-specific (`langflow.engarde.media`)
2. Use session storage or localStorage instead
3. Re-authenticate on each subdomain

However, this defeats the purpose of SSO and creates a poor user experience.

---

## Testing Checklist

After implementing the fix:

- [ ] Add `LANGFLOW_COOKIE_DOMAIN=.engarde.media` to Railway
- [ ] Wait for langflow-server redeployment to complete
- [ ] Generate fresh SSO token and test URL
- [ ] Open SSO URL in browser
- [ ] Verify redirect to dashboard (no login screen)
- [ ] Check browser console for errors (should be none)
- [ ] Inspect cookie in DevTools (verify domain=.engarde.media)
- [ ] Test from production-frontend `/agent-suite` page
- [ ] Verify user is logged in automatically
- [ ] Check `langflow.user` table for new user record

---

## Expected Results After Fix

### Before Fix (Current)
```
User → SSO URL → Token validated → Cookie set (domain: langflow.engarde.media)
                                 → Redirect to dashboard
                                 → Cookie not sent with API requests
                                 → 401/403 errors
                                 → Login screen appears ❌
```

### After Fix
```
User → SSO URL → Token validated → Cookie set (domain: .engarde.media)
                                 → Redirect to dashboard
                                 → Cookie sent with all API requests ✅
                                 → User authenticated
                                 → Dashboard loads successfully ✅
```

---

## Why Checkpoint 3 Initially Passed

Checkpoint 3 infrastructure tests passed because:
- ✅ langflow-server is running
- ✅ SSO endpoint responds to requests
- ✅ JWT validation works correctly
- ✅ Secret keys match between services
- ✅ Token generation works

The issue only appears during **browser-based end-to-end testing** because:
- Cookie domain scoping is a browser behavior
- curl/API tests don't enforce cookie domain restrictions
- The authentication flow works, but cookie delivery fails

---

## Related Files

| File | Purpose |
|------|---------|
| `langflow-engarde/src/backend/base/langflow/api/v1/custom.py:136-144` | Sets SSO cookies |
| `CHECKPOINT_3_SSO_VERIFICATION.md` | Initial checkpoint documentation |
| `LANGFLOW_SSO_SETUP_COMPLETE.md` | SSO setup guide |

---

## Next Steps

1. **Immediate**: Add `LANGFLOW_COOKIE_DOMAIN=.engarde.media` to Railway
2. **After deployment**: Test SSO flow end-to-end
3. **If successful**: Update checkpoint 3 status to COMPLETE
4. **Then**: Proceed to checkpoint 4 (Multi-tenant isolation)

---

## Additional Cookie Security Notes

### Why `HttpOnly=false`?

Currently set to `false` for debugging. After SSO is confirmed working, consider setting:
```bash
LANGFLOW_COOKIE_HTTPONLY=true
```

This prevents JavaScript from accessing the cookie, adding XSS protection.

### Why `SameSite=none`?

Required for SSO to work when embedding Langflow in an iframe on `app.engarde.media`. If you're not using iframes, you could use:
```bash
LANGFLOW_ACCESS_SAME_SITE=lax
LANGFLOW_REFRESH_SAME_SITE=lax
```

This provides better CSRF protection while still allowing SSO navigation.

---

**Status**: Ready to implement
**Estimated Time**: 5 minutes to add variable + 3 minutes deployment
**Risk Level**: Low (only affects cookie delivery, easily reversible)
**Priority**: High (blocks SSO functionality)

---

**Created By**: Claude Code
**Date**: January 12, 2026
**Checkpoint**: 3 - SSO Authentication Flow
