# Token Refresh Authentication Fix

## Problem Summary

Your application was experiencing `401 Unauthorized` errors with the message "Could not validate credentials" when trying to refresh authentication tokens. This caused users to be logged out unexpectedly and redirected to the login page.

## Root Cause

The `JWT_SECRET_KEY` environment variable was set to a placeholder value:
```
JWT_SECRET_KEY=your-jwt-secret-key-min-32-chars-CHANGE-THIS
```

This caused token validation to fail because:
1. Login creates tokens signed with this placeholder secret
2. Token refresh attempts to decode tokens using the same secret
3. Any mismatch or change in the secret causes decode failure
4. Backend throws "Could not validate credentials" (401)
5. Frontend clears tokens and redirects to login

## Files Affected

### Backend
- `/production-backend/app/routers/auth.py` (Lines 562-694)
  - Token refresh endpoint
  - JWT decode logic
- `/production-backend/app/core/config.py` (Line 36)
  - JWT_SECRET_KEY configuration
- `/production-backend/app/middleware/auth_middleware.py` (Lines 220-261)
  - Token validation

### Frontend
- `/production-frontend/lib/api/client.ts` (Lines 323-420)
  - Token refresh logic
  - 401 error handling
- `/production-frontend/app/api/auth/refresh/route.ts` (Lines 113-225)
  - Proxy to backend refresh endpoint

## Solution Applied

### 1. Generated Secure JWT Secret ✅

Generated a cryptographically secure 64-character hexadecimal secret:
```bash
openssl rand -hex 32
# Result: a44fe15adf6a091dd88c6345d6eea0f66466a97708655f7046e8b2ec7b9cc0c3
```

### 2. Updated Local .env File ✅

Updated `/Users/cope/EnGardeHQ/.env` line 20:
```bash
JWT_SECRET_KEY=a44fe15adf6a091dd88c6345d6eea0f66466a97708655f7046e8b2ec7b9cc0c3
```

### 3. Created Helper Scripts ✅

**`set-jwt-secret.sh`** - Instructions for setting the secret in Railway
**`clear-frontend-tokens.html`** - Web tool to clear browser tokens

## Deployment Steps

### Step 1: Set JWT_SECRET_KEY in Railway

#### Option A: Railway CLI
```bash
railway variables set JWT_SECRET_KEY="a44fe15adf6a091dd88c6345d6eea0f66466a97708655f7046e8b2ec7b9cc0c3"
```

#### Option B: Railway Dashboard
1. Go to https://railway.app/dashboard
2. Select project: EnGardeHQ
3. Select service: backend (or production-backend)
4. Click "Variables" tab
5. Click "+ New Variable"
6. Set:
   - Name: `JWT_SECRET_KEY`
   - Value: `a44fe15adf6a091dd88c6345d6eea0f66466a97708655f7046e8b2ec7b9cc0c3`
7. Click "Add"
8. Railway will automatically redeploy (~2-3 minutes)

### Step 2: Clear User Tokens

After Railway redeploys:

1. Open `clear-frontend-tokens.html` in a browser
2. Click "Check Current Tokens" to see what's stored
3. Click "Clear All Tokens" to remove invalid tokens
4. Click "Go to Login" to be redirected

**OR** manually in browser console:
```javascript
localStorage.removeItem('engarde_tokens');
sessionStorage.clear();
window.location.href = '/login';
```

### Step 3: Test the Fix

1. Login with valid credentials
2. Wait 30+ minutes (or modify token expiry for testing)
3. Make an API request that requires authentication
4. Verify that token refresh works without 401 errors

## Verification Commands

### Check Railway Environment Variables
```bash
railway variables | grep JWT_SECRET_KEY
```

### Test Token Refresh Endpoint
```bash
# Get a refresh token by logging in first
# Then test refresh:
curl -X POST https://api.engarde.media/api/auth/refresh \
  -H 'Content-Type: application/json' \
  -d '{"refresh_token": "YOUR_REFRESH_TOKEN"}'
```

### Check Backend Logs
```bash
railway logs --service backend | grep "JWT decode error"
railway logs --service backend | grep "Token refresh"
```

## Error Flow Before Fix

```
User Logged In
    ↓
[30 minutes pass]
    ↓
Access Token Expires
    ↓
Frontend detects expiration (client.ts:274-308)
    ↓
Calls /api/auth/refresh (client.ts:361-366)
    ↓
Frontend route proxies to backend (route.ts:113-225)
    ↓
Backend verify_refresh_token() (auth.py:562-614)
    ↓
jwt.decode() uses wrong/placeholder secret
    ↓
JWTError raised
    ↓
401 "Could not validate credentials"
    ↓
Frontend catches 401 (client.ts:403-406)
    ↓
Clears all tokens
    ↓
Redirects to /login
```

## Error Flow After Fix

```
User Logged In (with new secret)
    ↓
[30 minutes pass]
    ↓
Access Token Expires
    ↓
Frontend detects expiration
    ↓
Calls /api/auth/refresh
    ↓
Backend verify_refresh_token()
    ↓
jwt.decode() uses CORRECT secret
    ↓
✅ Token validated successfully
    ↓
New access_token + refresh_token generated
    ↓
200 OK response
    ↓
Frontend stores new tokens
    ↓
Original API request retried with new token
    ↓
✅ User stays logged in!
```

## Browser Console Errors (Before Fix)

```
layout-*.js:1 GET https://app.engarde.media/api/agents/installed 401 (Unauthorized)
layout-*.js:1 ⚠️ API CLIENT: Token refresh failed, clearing session
2472-*.js:1 ❌ API CLIENT: Error during token refresh: {message: 'Could not validate credentials', status: 401}
layout-*.js:1 ⚠️ API CLIENT: Token refresh error, clearing session
```

## Expected Behavior After Fix

No more console errors! Token refresh should happen silently in the background:
```
✅ Token refresh successful
✅ New tokens stored
✅ Request retried successfully
```

## Additional Security Improvements

Consider implementing:

1. **Token Versioning** - Add version field to tokens to handle secret rotation
2. **Graceful Migration** - Support old and new secrets during transition period
3. **Monitoring** - Alert on high frequency of 401 errors
4. **Automatic Logout** - After N failed refresh attempts, force re-authentication
5. **Token Blacklisting** - Revoke compromised tokens in Redis

## Related Configuration

Other secrets that should also be changed from placeholders:

```bash
MASTER_SECRET_KEY=your-master-secret-key-min-32-chars-CHANGE-THIS
NEXTAUTH_SECRET=your-nextauth-secret-min-32-chars-CHANGE-THIS
ENCRYPTION_KEY=your-encryption-key-32-bytes-base64-CHANGE-THIS
```

Generate these with:
```bash
# Master secret
openssl rand -hex 32

# NextAuth secret
openssl rand -hex 32

# Encryption key (base64)
openssl rand -base64 32
```

## Testing Checklist

- [ ] JWT_SECRET_KEY set in Railway
- [ ] Backend redeployed successfully
- [ ] Browser localStorage cleared
- [ ] Can login successfully
- [ ] Token stored in localStorage
- [ ] After 30 minutes, token refreshes without error
- [ ] No 401 errors in console
- [ ] User stays logged in

## Rollback Plan

If issues occur:

1. Revert JWT_SECRET_KEY to original value (not recommended)
2. Or keep new secret and wait for all old tokens to expire (30 min)
3. Force all users to logout/login

## Support

If users still experience issues:

1. Have them clear browser cache completely
2. Check if JWT_SECRET_KEY is actually set in Railway
3. Verify backend logs for JWT decode errors
4. Check that tokens are being stored in localStorage

## Files Created

1. `set-jwt-secret.sh` - Railway deployment script
2. `clear-frontend-tokens.html` - Token cleanup tool
3. `TOKEN_REFRESH_FIX.md` - This documentation

---

**Status**: ✅ Fix Applied - Awaiting Railway Deployment

**Next Steps**:
1. Run `./set-jwt-secret.sh` to see deployment instructions
2. Set JWT_SECRET_KEY in Railway
3. Open `clear-frontend-tokens.html` in browser
4. Test login and token refresh
