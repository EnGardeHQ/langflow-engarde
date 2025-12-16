# 401 Unauthorized Error Fix - Authentication Flow

## Problem Summary

After successful login, the frontend was receiving 401 Unauthorized errors when fetching brands:
- Login works successfully (JWT tokens obtained)
- Direct curl test with token works
- Browser requests to `/api/brands/current` and `/api/brands` return 401
- Brand modal still appears despite errors

## Root Cause Analysis

### Issue 1: Problematic Login Success Flag
**Location:** `/Users/cope/EnGardeHQ/production-frontend/lib/api/client.ts` (lines 396-406)

The API client had a "safety mechanism" that prevented 401 errors from clearing tokens if login just succeeded:

```typescript
// PROBLEMATIC CODE (REMOVED)
if (loginSuccess) {
  console.warn('⚠️ API CLIENT: Got 401 right after login, ignoring redirect to prevent loop');
  // Don't clear tokens or redirect - the login just succeeded
  return error;
}
```

**Why this caused issues:**
1. After login, the `engarde_login_success` flag was set in sessionStorage
2. This flag persisted for 10 seconds
3. During this window, ANY 401 error would be "swallowed" - the error was returned but tokens weren't cleared
4. The brand API calls happened immediately after login, within this 10-second window
5. If the backend returned 401 (for any reason), the error handler would return the error but not clear tokens
6. This created a confusing state where the app thought it was authenticated but API calls were failing

### Issue 2: Token Propagation Timing
The `engarde_login_success` flag was being used to prevent redirect loops, but it created a worse problem by masking legitimate authentication failures during the critical post-login period.

## Solution Implemented

### Fix 1: Removed Login Success Flag Logic
**File:** `/Users/cope/EnGardeHQ/production-frontend/lib/api/client.ts`

Simplified the 401 error handler to always clear tokens and redirect:

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

### Fix 2: Removed Login Success Flag from AuthContext
**File:** `/Users/cope/EnGardeHQ/production-frontend/contexts/AuthContext.tsx`

Removed the code that set and managed the `engarde_login_success` flag:

```typescript
// REMOVED: No longer setting login success flag
// sessionStorage.setItem('engarde_login_success', 'true');
// setTimeout(() => {
//   sessionStorage.removeItem('engarde_login_success');
//   console.log('🧹 AUTH CONTEXT: Cleared login success flag');
// }, 10000);
```

## How Authentication Works Now

### 1. Login Flow
```
User submits credentials
    ↓
AuthContext.login() calls authService.login()
    ↓
authService.login() sends POST to /api/auth/login
    ↓
Backend returns JWT tokens + user data
    ↓
apiClient.setTokens() stores tokens in:
  - Memory (this.tokenStorage)
  - localStorage ('engarde_tokens')
    ↓
authService.setCurrentUser() stores user data in:
  - localStorage ('engarde_user')
    ↓
AuthContext updates state (isAuthenticated = true)
    ↓
Router redirects to /dashboard
```

### 2. API Request Flow (e.g., /api/brands)
```
Component calls useBrands() hook
    ↓
React Query executes queryFn
    ↓
apiClient.get('/brands')
    ↓
apiClient.request() adds headers:
  - Authorization: Bearer {accessToken}
    ↓
Fetch request sent to backend
    ↓
If 401 response:
  - Clear tokens from memory + localStorage
  - Clear user data from localStorage
  - Redirect to /login
```

### 3. Token Storage Details

**Access Token Storage:**
- **Location:** `localStorage.engarde_tokens`
- **Format:** JSON object with:
  ```json
  {
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhbGc...",
    "expiresAt": 1696789234567
  }
  ```

**User Data Storage:**
- **Location:** `localStorage.engarde_user`
- **Format:** JSON object with:
  ```json
  {
    "id": "user_123",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "userType": "advertiser",
    "cachedAt": 1696789234567
  }
  ```

## Verification Steps

### Test the Fix

1. **Clear Browser Storage:**
   ```javascript
   // In browser console:
   localStorage.clear();
   sessionStorage.clear();
   ```

2. **Login:**
   - Go to http://localhost:3001/login
   - Enter credentials
   - Submit form

3. **Verify Token Storage:**
   ```javascript
   // In browser console after login:
   console.log('Tokens:', localStorage.getItem('engarde_tokens'));
   console.log('User:', localStorage.getItem('engarde_user'));
   ```

4. **Check Network Tab:**
   - Open DevTools → Network tab
   - Look for `/api/brands/current` request
   - Verify `Authorization: Bearer {token}` header is present
   - Verify response is 200 OK (not 401)

5. **Verify Brand Loading:**
   - Dashboard should load without errors
   - If no brands exist, brand creation wizard should appear
   - If brands exist, they should load successfully

## Expected Behavior

### Successful Login
1. User enters valid credentials
2. Login succeeds, tokens stored
3. Redirect to `/dashboard`
4. Brand API calls succeed with 200 OK
5. Dashboard loads or brand wizard appears

### Failed Authentication
1. User enters invalid credentials
2. Login fails with 401
3. Error message displayed
4. User remains on login page

### Expired Token
1. User tries to access protected route with expired token
2. API call returns 401
3. Tokens cleared from storage
4. User redirected to `/login`

## Files Modified

1. **`/Users/cope/EnGardeHQ/production-frontend/lib/api/client.ts`**
   - Removed login success flag check from 401 error handler
   - Simplified error handling logic
   - Always clear tokens and redirect on 401

2. **`/Users/cope/EnGardeHQ/production-frontend/contexts/AuthContext.tsx`**
   - Removed `engarde_login_success` flag creation
   - Removed setTimeout cleanup of flag
   - Simplified login flow

## Testing Checklist

- [x] Build passes without TypeScript errors
- [ ] Login with valid credentials succeeds
- [ ] Brand API calls return 200 OK after login
- [ ] Authorization header is present in API requests
- [ ] Dashboard loads correctly after login
- [ ] Invalid credentials show error message
- [ ] Expired token redirects to login
- [ ] Logout clears all tokens and redirects

## Additional Notes

### Why the Old Approach Failed

The `engarde_login_success` flag was attempting to solve a redirect loop problem, but it created a worse issue:
- **Problem it tried to solve:** Prevent redirect loop if 401 happens right after login
- **Problem it created:** Masked legitimate 401 errors during post-login API calls
- **Better solution:** Ensure tokens are properly set before making API calls (which already happens)

### API Client Authentication Flow

The API client (`apiClient`) automatically adds the Authorization header to all requests:

```typescript
// From client.ts (line 336-338)
} else if (!skipAuth && this.tokenStorage.accessToken) {
  // Use user JWT token if no API key
  headers.set('Authorization', `Bearer ${this.tokenStorage.accessToken}`);
}
```

This means:
- Any request made through `apiClient.get()`, `apiClient.post()`, etc. automatically includes auth
- The `skipAuth` flag can be used to opt-out (e.g., for login endpoint)
- Tokens are read from `this.tokenStorage.accessToken` which is loaded from localStorage

### Race Conditions Eliminated

The fix eliminates race conditions by:
1. Removing the time-based flag (`engarde_login_success`)
2. Trusting the token storage as single source of truth
3. Immediately handling 401 errors without special cases
4. Letting the browser's synchronous localStorage handle token persistence

## Debugging Tips

If you still see 401 errors after this fix:

1. **Check if tokens are being stored:**
   ```javascript
   console.log(localStorage.getItem('engarde_tokens'));
   ```

2. **Check if Authorization header is present:**
   - Open Network tab in DevTools
   - Click on failed request
   - Check Request Headers section
   - Look for `Authorization: Bearer ...`

3. **Verify token is valid:**
   ```bash
   # Test with curl (replace $TOKEN with actual token from localStorage)
   curl -H "Authorization: Bearer $TOKEN" http://localhost:3001/api/brands
   ```

4. **Check backend logs:**
   - Look for authentication middleware logs
   - Verify token validation is passing
   - Check if token is being parsed correctly

5. **Verify environment configuration:**
   ```javascript
   // Check API base URL configuration
   fetch('/api/debug-env').then(r => r.json()).then(console.log);
   ```
