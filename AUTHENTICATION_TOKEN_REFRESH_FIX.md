# Authentication Token Refresh Fix

## Problem Diagnosis

**Issue**: Getting 401 errors and booted to login when accessing Agent Workflows pages

**Root Cause**: The `JWT_SECRET_KEY` environment variable is set to a placeholder value, causing token validation to fail during refresh attempts.

**Error Flow**:
1. ✅ Initial login succeeds
2. ✅ Access token works initially
3. ⏰ Access token expires (30 minutes)
4. 🔄 Frontend attempts token refresh
5. ❌ Backend fails to validate refresh token
6. 🚪 User redirected to login

## Log Evidence

```
GET /api/agents/installed 401 (Unauthorized)
GET /api/agents/config 401 (Unauthorized)
❌ API CLIENT: Error during token refresh: {message: 'Could not validate credentials', status: 401}
⚠️ API CLIENT: Token refresh failed, clearing session
```

## Solution

### Step 1: Set Secure JWT Secret in Railway

1. **Generate the secure secret** (already done):
   ```
   714a9efe00dff36cd367708b77c132bfcffb0e78837710b9f38565c1aadb5d15
   ```

2. **Add to Railway environment variables**:
   - Go to https://railway.app/
   - Navigate to your project
   - Select the **production-backend** service
   - Go to **Variables** tab
   - Add the following environment variable:
     ```
     JWT_SECRET_KEY=714a9efe00dff36cd367708b77c132bfcffb0e78837710b9f38565c1aadb5d15
     ```
   - Click **Save**
   - Railway will automatically redeploy the backend

3. **Alternative: Use Railway CLI** (if installed):
   ```bash
   railway variables --set JWT_SECRET_KEY=714a9efe00dff36cd367708b77c132bfcffb0e78837710b9f38565c1aadb5d15
   ```

### Step 2: Clear Browser Storage

**Why**: Old tokens were created with the placeholder secret and won't work with the new secret.

**How to clear**:

#### Option A: Browser DevTools (Recommended)
1. Open https://app.engarde.media
2. Press **F12** (or Cmd+Option+I on Mac)
3. Go to **Application** tab (Chrome) or **Storage** tab (Firefox)
4. Click **Local Storage** → **https://app.engarde.media**
5. Find and delete: `engarde_tokens`
6. Reload the page

#### Option B: Console Command
1. Open https://app.engarde.media
2. Press **F12** (or Cmd+Option+I on Mac)
3. Go to **Console** tab
4. Paste and run:
   ```javascript
   localStorage.removeItem('engarde_tokens');
   localStorage.removeItem('auth_state');
   console.log('✅ Auth tokens cleared');
   location.reload();
   ```

### Step 3: Wait for Deployment

1. Go to Railway dashboard
2. Wait for backend deployment to complete (usually 2-3 minutes)
3. Check deployment logs for:
   ```
   ✅ JWT_SECRET_KEY validated
   🚀 Server started successfully
   ```

### Step 4: Test Login

1. Navigate to https://app.engarde.media/login
2. Log in with your credentials
3. Navigate to **Agent Workflows** → **My Agents**
4. Verify no 401 errors occur

## Verification

After completing the fix, you should see:

✅ **Successful login** without errors
✅ **Agent pages load** without 401 errors
✅ **Token refresh works** silently in background
✅ **No redirect to login** when navigating

### Backend Logs (Railway)
```
[AUTH-VALIDATION] Token decoded successfully, email: your@email.com
✅ JWT_SECRET_KEY configured securely
Token refresh verified for user: your@email.com
```

### Frontend Console
```
✅ API CLIENT: Tokens loaded from storage
🔍 API CLIENT: Authentication check (AUTHORITATIVE): isAuthenticated: true
✅ API CLIENT: Token refresh successful
```

## Security Best Practices

### ⚠️ Important Notes

1. **Never commit JWT_SECRET_KEY** to git repositories
2. **Use different secrets** for development, staging, and production
3. **Rotate secrets periodically** (every 90 days recommended)
4. **Keep secret length ≥ 64 characters** (32 bytes hex = 64 chars)

### Recommended: Also Set SECRET_KEY

Railway should also have a general `SECRET_KEY`:
```
SECRET_KEY=<generate-another-64-char-hex-string>
```

Generate another:
```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
```

## Troubleshooting

### Still Getting 401 Errors?

1. **Check Railway deployment completed**:
   - Go to Railway dashboard
   - Verify backend shows "Active" status
   - Check recent logs for startup messages

2. **Verify environment variable**:
   ```bash
   # In Railway service logs, search for:
   JWT_SECRET_KEY
   ```

3. **Clear ALL browser data**:
   ```javascript
   localStorage.clear();
   sessionStorage.clear();
   location.reload();
   ```

4. **Check token expiration**:
   - Frontend Console → Application → Local Storage
   - Check `expiresAt` timestamp
   - Should be 30 minutes in the future

### Token Still Won't Refresh?

Check backend logs for:
```
❌ JWT decode error during refresh
⚠️ Refresh token invalid or expired
```

If you see these, the refresh token itself has expired (7 days). Simply log in again.

## Technical Details

### Current Backend Configuration

**File**: `production-backend/app/routers/auth.py:35`
```python
SECRET_KEY = getattr(settings, 'JWT_SECRET_KEY', None) or \
             getattr(settings, 'SECRET_KEY', None) or \
             os.getenv('JWT_SECRET_KEY', None) or \
             os.getenv('SECRET_KEY', 'your-secret-key-change-in-production')
```

**Priority**:
1. `settings.JWT_SECRET_KEY` (from config.py)
2. `settings.SECRET_KEY` (from config.py)
3. `JWT_SECRET_KEY` environment variable ← **This is what we're setting**
4. `SECRET_KEY` environment variable
5. Placeholder (insecure default)

### Token Lifecycle

```
┌─────────────┐
│    Login    │ ← User provides credentials
└──────┬──────┘
       │
       ├─► Access Token (30 min TTL)
       │   └─► Used for API requests
       │
       └─► Refresh Token (7 days TTL)
           └─► Used to get new access tokens
```

**When Access Token Expires**:
```
API Request → 401 → Frontend detects → Calls /auth/refresh
                                             ↓
                                    Validates refresh token
                                             ↓
                                   Returns new access token
                                             ↓
                                     Retries API request
```

## Files Involved

### Backend
- `production-backend/app/routers/auth.py` - Token creation/validation
- `production-backend/app/core/config.py` - Settings configuration
- `production-backend/.env` - Local environment (placeholder values)

### Frontend
- `/tmp/production-frontend/lib/api/client.ts` - Token refresh logic
- `/tmp/production-frontend/contexts/AuthContext.tsx` - Auth state management
- Browser localStorage: `engarde_tokens` - Token storage

## Next Steps After Fix

1. ✅ **Update local .env files** (optional):
   ```bash
   # In /Users/cope/EnGardeHQ/.env
   JWT_SECRET_KEY=714a9efe00dff36cd367708b77c132bfcffb0e78837710b9f38565c1aadb5d15
   ```

2. ✅ **Set up token rotation** (recommended):
   - Add to calendar: Rotate JWT secret every 90 days
   - Process: Generate new secret → Update Railway → Notify users to re-login

3. ✅ **Monitor authentication metrics**:
   - Token refresh success rate
   - 401 error frequency
   - Average session duration

---

**Status**: Ready to implement
**Est. Time**: 5-10 minutes
**Risk**: Low (tokens will be re-generated on login)
**Requires**: Railway dashboard access
