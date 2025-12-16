# Authentication Code Rollback Guide

**Date:** 2025-10-29
**Purpose:** Exact code changes to restore working authentication
**Issue:** 401 errors after login due to removed login success flag

---

## Quick Summary

Two files were modified on **Oct 29, 2025 at 12:44-12:45 AM** that broke authentication:
1. `/Users/cope/EnGardeHQ/production-frontend/lib/api/client.ts` (12:45 AM)
2. `/Users/cope/EnGardeHQ/production-frontend/contexts/AuthContext.tsx` (12:44 AM)

**What was removed:** Login success flag mechanism that provided a 10-second grace period after login
**Why it was removed:** Documented in `401_AUTHENTICATION_FIX.md` - attempt to simplify auth flow
**Why it broke:** The grace period was actually needed to prevent race condition during post-login API calls

---

## File 1: API Client - Restore Login Success Check

**File:** `/Users/cope/EnGardeHQ/production-frontend/lib/api/client.ts`

### Find This Code Block (Around Line 396-420)

**Current Broken Code:**
```typescript
// Handle authentication errors
if (response.status === 401) {
  console.log('🔒 API CLIENT: 401 Unauthorized error received');

  this.clearTokens();
  // Clear user data from localStorage as well
  if (typeof window !== 'undefined') {
    localStorage.removeItem('engarde_user');
    // Clear any stale login flags
    sessionStorage.removeItem('engarde_login_success');

    // Only redirect if we're not already on the login page
    if (window.location.pathname !== '/login') {
      console.log('🔄 API CLIENT: 401 error, redirecting to login');
      window.location.href = '/login';
    }
  }
}
```

### Replace With Working Code:

```typescript
// Handle authentication errors
if (response.status === 401) {
  console.log('🔒 API CLIENT: 401 Unauthorized error received');

  // Check if we just completed a login (within last 10 seconds)
  // This prevents clearing tokens during the post-login initialization period
  const loginSuccess = typeof window !== 'undefined' &&
    sessionStorage.getItem('engarde_login_success') === 'true';

  if (loginSuccess) {
    console.warn('⚠️ API CLIENT: Got 401 right after login, ignoring redirect to prevent loop');
    console.warn('⚠️ This is normal during post-login token propagation');
    // Don't clear tokens or redirect - the login just succeeded
    // Let the natural auth flow handle it
    return error;
  }

  // Normal 401 handling: clear tokens and redirect
  console.log('🔒 API CLIENT: Clearing tokens and redirecting to login');
  this.clearTokens();

  // Clear user data from localStorage as well
  if (typeof window !== 'undefined') {
    localStorage.removeItem('engarde_user');

    // Only redirect if we're not already on the login page
    if (window.location.pathname !== '/login') {
      console.log('🔄 API CLIENT: 401 error, redirecting to login');
      window.location.href = '/login';
    }
  }
}
```

**Key Changes:**
- Added check for `engarde_login_success` flag in sessionStorage
- If flag is present, return error without clearing tokens
- Prevents token clearing during post-login 10-second grace period
- Normal 401 handling applies after grace period expires

---

## File 2: AuthContext - Restore Login Success Flag

**File:** `/Users/cope/EnGardeHQ/production-frontend/contexts/AuthContext.tsx`

### Find the Login Success Section

Search for the comment that mentions "LOGIN_SUCCESS" dispatch or the login function completion.

**Look for code around line 620-650** (after successful login, before navigation)

### Add This Code Block

**After the successful login dispatch and before navigation:**

```typescript
// Set login success flag to prevent auth loop during token propagation
// This gives the app 10 seconds to initialize after login without
// treating 401 errors as authentication failures
if (typeof window !== 'undefined') {
  sessionStorage.setItem('engarde_login_success', 'true');
  console.log('✅ AUTH CONTEXT: Set login success flag (10 second grace period)');

  // Clear the flag after 10 seconds
  setTimeout(() => {
    sessionStorage.removeItem('engarde_login_success');
    console.log('🧹 AUTH CONTEXT: Cleared login success flag');
  }, 10000);
}
```

**Typical Context (your actual code may vary):**

```typescript
// After successful login
dispatch({
  type: 'LOGIN_SUCCESS',
  payload: { user: userData }
});

// Store user in localStorage for persistence
if (typeof window !== 'undefined') {
  localStorage.setItem('engarde_user', JSON.stringify(userData));
}

// SET LOGIN SUCCESS FLAG HERE (add the code block above)
if (typeof window !== 'undefined') {
  sessionStorage.setItem('engarde_login_success', 'true');
  console.log('✅ AUTH CONTEXT: Set login success flag (10 second grace period)');

  setTimeout(() => {
    sessionStorage.removeItem('engarde_login_success');
    console.log('🧹 AUTH CONTEXT: Cleared login success flag');
  }, 10000);
}

// Navigate to dashboard or intended route
await router.push('/dashboard');
```

---

## Understanding the Fix

### Why the Login Success Flag is Needed

**The Problem:**
1. User logs in successfully
2. JWT tokens are stored in localStorage
3. Frontend redirects to dashboard
4. Dashboard immediately makes API calls (e.g., fetch brands)
5. **Timing Issue:** Sometimes the auth state hasn't fully propagated yet
6. API returns 401 because auth middleware sees the request as unauthenticated
7. Without the flag, API client immediately clears tokens and redirects to login
8. User appears to be logged out despite successful login

**The Solution:**
1. Set `engarde_login_success` flag in sessionStorage after successful login
2. Flag lasts for 10 seconds
3. During this 10-second window, 401 errors are returned but don't clear tokens
4. This gives React time to propagate auth state throughout the app
5. After 10 seconds, normal 401 handling resumes

### Why Removing It Broke Authentication

The original fix documented in `401_AUTHENTICATION_FIX.md` argued that:
- The flag was masking legitimate authentication failures
- It created a "confusing state"
- Better to always clear tokens on 401

**However, the fix failed to account for:**
- Post-login timing issues are REAL and common
- React state propagation is asynchronous
- The 10-second grace period was solving a legitimate race condition
- Without it, successful logins appear to fail

---

## After Making Changes

### 1. Rebuild Frontend Container

```bash
cd /Users/cope/EnGardeHQ

# Stop frontend
docker compose -f docker-compose.dev.yml stop frontend

# Rebuild with changes
docker compose -f docker-compose.dev.yml build frontend

# Start frontend
docker compose -f docker-compose.dev.yml up -d frontend

# Watch logs
docker logs -f engarde_frontend_dev
```

### 2. Clear Browser Storage

**Before testing, clear all browser storage:**

```javascript
// In browser console (F12)
localStorage.clear();
sessionStorage.clear();
location.reload();
```

### 3. Test Authentication

**Test Sequence:**
1. Navigate to http://localhost:3000/login
2. Open browser DevTools (F12) → Console tab
3. Enter test credentials and submit
4. Watch console logs for:
   - `✅ AUTH CONTEXT: Set login success flag (10 second grace period)`
   - Successful login messages
   - Dashboard navigation
5. Open Network tab and verify `/api/brands` requests return 200 (not 401)
6. Verify dashboard loads without errors

**Expected Console Output:**
```
✅ AUTH CONTEXT: Set login success flag (10 second grace period)
🔒 API CLIENT: Making authenticated request to /api/brands/current
✅ API CLIENT: Request successful (200)
🧹 AUTH CONTEXT: Cleared login success flag
```

### 4. Test Edge Cases

**Test 1: Verify Grace Period Works**
```javascript
// After login, during the 10-second grace period
// Open console and check:
sessionStorage.getItem('engarde_login_success')
// Should return: "true"

// Wait 11 seconds, then check again:
sessionStorage.getItem('engarde_login_success')
// Should return: null
```

**Test 2: Verify 401 Handling After Grace Period**
```javascript
// After grace period expires (11+ seconds after login)
// Manually trigger a 401 by using invalid token:
fetch('/api/brands', {
  headers: {
    'Authorization': 'Bearer invalid_token'
  }
})
// Should redirect to login page
```

**Test 3: Verify Token Persistence**
```javascript
// After successful login
console.log('Tokens:', localStorage.getItem('engarde_tokens'));
// Should show valid JWT tokens

// Refresh page
location.reload();

// Should still be logged in (no redirect to login)
```

---

## Troubleshooting

### Issue: 401 Errors Still Occurring

**Check 1: Verify flag is being set**
```javascript
// In console after login
sessionStorage.getItem('engarde_login_success')
// Should return: "true" for first 10 seconds
```

**Check 2: Verify code changes took effect**
```javascript
// Check if new code is running
// Look for console message: "Set login success flag"
```

**Check 3: Rebuild container**
```bash
# Force rebuild without cache
docker compose -f docker-compose.dev.yml build --no-cache frontend
docker compose -f docker-compose.dev.yml up -d frontend
```

### Issue: Build Fails

**Check TypeScript syntax:**
```bash
cd /Users/cope/EnGardeHQ/production-frontend
npm run type-check
```

**Check for syntax errors:**
- Verify all brackets are balanced
- Check for missing semicolons
- Ensure proper indentation

### Issue: Flag Doesn't Clear After 10 Seconds

**This is usually okay**, but verify with:
```javascript
// Check after 11 seconds
sessionStorage.getItem('engarde_login_success')
// Should return: null
```

If it persists, the setTimeout might not be working. Check browser console for errors.

---

## Verification Checklist

- [ ] Code changes made to `client.ts`
- [ ] Code changes made to `AuthContext.tsx`
- [ ] Frontend container rebuilt
- [ ] Browser storage cleared
- [ ] Login successful (no redirect loop)
- [ ] Dashboard loads without 401 errors
- [ ] Console shows "Set login success flag" message
- [ ] Flag clears after 10 seconds
- [ ] Token persistence works after page refresh
- [ ] Logout clears tokens properly

---

## Alternative: Use Dockerfile.old

If code changes are too complex or risky, the frontend has a backup Dockerfile:

```bash
cd /Users/cope/EnGardeHQ/production-frontend

# Check if Dockerfile.old exists
ls -la Dockerfile.old

# If it exists and is from before the auth fix:
cp Dockerfile Dockerfile.broken-20251029
cp Dockerfile.old Dockerfile

# Rebuild
cd /Users/cope/EnGardeHQ
docker compose -f docker-compose.dev.yml build frontend
docker compose -f docker-compose.dev.yml up -d frontend
```

**Note:** `Dockerfile.old` exists but may not contain the code changes needed. The manual code changes above are more reliable.

---

## Backup Your Changes

**After fixing, create backups:**

```bash
cd /Users/cope/EnGardeHQ

# Create backups directory
mkdir -p backups/auth-working-20251029

# Backup working files
cp production-frontend/lib/api/client.ts \
   backups/auth-working-20251029/client.ts.working

cp production-frontend/contexts/AuthContext.tsx \
   backups/auth-working-20251029/AuthContext.tsx.working

# Tag working Docker image
docker tag engarde-frontend:dev engarde-frontend:dev-working-20251029

echo "Backups created in: backups/auth-working-20251029/"
```

---

## Summary

**Two files to edit:**
1. `production-frontend/lib/api/client.ts` - Add login success check in 401 handler
2. `production-frontend/contexts/AuthContext.tsx` - Add login success flag setter

**What to add:**
- 10-second grace period using `engarde_login_success` sessionStorage flag
- Check flag before clearing tokens on 401
- Set flag after successful login
- Clear flag after 10 seconds

**After changes:**
- Rebuild frontend container
- Clear browser storage
- Test login flow
- Verify dashboard loads without 401 errors

**Files Modified:** 2 files
**Estimated Time:** 15-20 minutes
**Risk Level:** Low (reverting to previous working state)
**Testing Time:** 10 minutes

---

**Reference Documents:**
- Full rollback strategy: `/Users/cope/EnGardeHQ/DOCKER_ROLLBACK_STRATEGY.md`
- Original fix documentation: `/Users/cope/EnGardeHQ/401_AUTHENTICATION_FIX.md`
- Auth issue summary: `/Users/cope/EnGardeHQ/AUTH_ISSUE_SUMMARY.md`
