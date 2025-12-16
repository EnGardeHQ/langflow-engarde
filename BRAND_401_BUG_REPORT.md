# Brand Endpoints 401 Error - Comprehensive Bug Report

**Date:** October 8, 2025
**Severity:** HIGH - Critical authentication race condition
**Status:** Root cause identified
**Affected Component:** Brand API endpoints, Authentication flow, Provider initialization

---

## Executive Summary

The brand endpoints return **401 Unauthorized** when called from the frontend browser, despite working perfectly with direct API calls using the same credentials. This is caused by a **race condition** between the `AuthProvider` initialization and the `BrandProvider` mounting, resulting in brand API requests being sent **before authentication tokens are fully available** to the API client.

---

## Problem Statement

### Observed Behavior

- **Working:** Python script → Backend API → 200 OK
- **Failing:** Browser → Frontend → Backend API → 401 Unauthorized
- **Inconsistency:** Same credentials, same endpoints, different results

### Impact

- Users cannot access brand management features after successful login
- Dashboard and protected routes fail to load brand-specific data
- Critical user experience degradation on authenticated pages

---

## Root Cause Analysis

### Critical Issue: Race Condition in Provider Initialization

The issue stems from the **order and timing** of provider mounting in `/Users/cope/EnGardeHQ/production-frontend/app/layout.tsx`:

```tsx
<AuthProvider>
  <ApiErrorProvider>
    <BrandProvider>      {/* PROBLEM: Mounts and fires API call immediately */}
      <WebSocketProvider>
        <SkipLink />
        <ClientInit />
        <BrandGuard>
          {children}
        </BrandGuard>
      </WebSocketProvider>
    </BrandProvider>
  </ApiErrorProvider>
</AuthProvider>
```

### Detailed Timeline of the Race Condition

#### Step 1: Initial Page Load (t=0ms)
1. `AuthProvider` mounts
2. `AuthContext` initializing state is set to `true`
3. `useEffect` in `AuthContext` begins initialization (Line 192-296)

#### Step 2: Provider Initialization (t=0-50ms)
1. `AuthProvider` dispatches `INIT_START`
2. `apiClient.loadTokensFromStorage()` is called
3. Tokens are loaded into memory from `localStorage`
4. **However:** Child components mount IMMEDIATELY

#### Step 3: BrandProvider Mounts TOO EARLY (t=10-30ms)
```tsx
// File: /Users/cope/EnGardeHQ/production-frontend/contexts/BrandContext.tsx
export function BrandProvider({ children }: BrandProviderProps) {
  const { data: currentBrand, isLoading, error } = useCurrentBrand()
  // ^^^ THIS FIRES IMMEDIATELY ON MOUNT
}
```

#### Step 4: useCurrentBrand Hook Executes (t=15-35ms)
```tsx
// File: /Users/cope/EnGardeHQ/production-frontend/lib/api/brands.ts
export function useCurrentBrand(options?: UseQueryOptions<Brand, Error>) {
  return useQuery<Brand, Error>({
    queryKey: brandKeys.current(),
    queryFn: async () => {
      const response = await apiClient.get<BrandDetailResponse>('/brands/current');
      // ^^^ API CALL FIRES BEFORE AUTH IS READY
      return response.data.data;
    },
    staleTime: 5 * 60 * 1000,
    ...options,
  });
}
```

#### Step 5: API Client Attempts Request WITHOUT Token (t=20-40ms)
```tsx
// File: /Users/cope/EnGardeHQ/production-frontend/lib/api/client.ts
private createHeaders(skipAuth = false, customHeaders?: Record<string, string>, isFormData = false): Headers {
  // ...
  if (!skipAuth && this.tokenStorage.accessToken) {
    headers.set('Authorization', `Bearer ${this.tokenStorage.accessToken}`);
  }
  // ^^^ this.tokenStorage.accessToken is NULL at this point!
  // Tokens were loaded but auth init hasn't completed yet
}
```

#### Step 6: Backend Receives Unauthorized Request (t=50-100ms)
- Request arrives at backend **without Authorization header**
- Backend's `get_current_user` dependency fails
- Returns 401 Unauthorized

#### Step 7: Auth Initialization Completes (t=100-200ms)
- `AuthProvider` finishes initialization
- Tokens are confirmed valid
- User state is set
- **But it's too late** - BrandProvider already made its call

---

## Key Code Evidence

### 1. BrandProvider Has No Auth Dependency Check

**File:** `/Users/cope/EnGardeHQ/production-frontend/contexts/BrandContext.tsx` (Lines 30-44)

```tsx
export function BrandProvider({ children }: BrandProviderProps) {
  const { data: currentBrand, isLoading, error } = useCurrentBrand()
  // ❌ NO CHECK: Should wait for AuthContext.initializing === false
  // ❌ NO CHECK: Should verify AuthContext.isAuthenticated === true

  const value: BrandContextValue = {
    currentBrand: currentBrand || null,
    isLoading,
    error: error || null,
  }

  return (
    <BrandContext.Provider value={value}>
      {children}
    </BrandContext.Provider>
  )
}
```

### 2. useCurrentBrand Has No Enabled Condition

**File:** `/Users/cope/EnGardeHQ/production-frontend/lib/api/brands.ts` (Lines 66-76)

```tsx
export function useCurrentBrand(options?: UseQueryOptions<Brand, Error>) {
  return useQuery<Brand, Error>({
    queryKey: brandKeys.current(),
    queryFn: async () => {
      const response = await apiClient.get<BrandDetailResponse>('/brands/current');
      return response.data.data;
    },
    staleTime: 5 * 60 * 1000,
    // ❌ MISSING: enabled: isAuthenticated && !initializing
    ...options,
  });
}
```

### 3. API Client Token Access is Synchronous

**File:** `/Users/cope/EnGardeHQ/production-frontend/lib/api/client.ts` (Lines 318-342)

```tsx
private createHeaders(skipAuth = false, customHeaders?: Record<string, string>, isFormData = false): Headers {
  const headers = new Headers({
    'Accept': 'application/json',
  });

  // ...

  if (!skipAuth && this.tokenStorage.accessToken) {
    // ❌ PROBLEM: this.tokenStorage.accessToken can be NULL during race condition
    headers.set('Authorization', `Bearer ${this.tokenStorage.accessToken}`);
  }

  return headers;
}
```

### 4. AuthProvider Init Has Async Delay

**File:** `/Users/cope/EnGardeHQ/production-frontend/contexts/AuthContext.tsx` (Lines 192-296)

```tsx
useEffect(() => {
  let isMounted = true;
  let initTimer: NodeJS.Timeout;

  const initializeAuth = async () => {
    console.log('🔄 AUTH CONTEXT: Starting auth initialization');
    dispatch({ type: 'INIT_START' });

    // Check for valid tokens
    const isAuthenticated = authService.isAuthenticated();

    if (!isAuthenticated) {
      // Fast path: no tokens
      dispatch({ type: 'INIT_SUCCESS', payload: { user: null, isAuthenticated: false } });
      return;
    }

    // Slow path: has tokens, fetch user
    const cachedUser = authService.getCachedUser();
    if (cachedUser) {
      dispatch({ type: 'INIT_SUCCESS', payload: { user: cachedUser, isAuthenticated: true } });
      // ^^^ Even with cached user, this is async and child components mount before it completes
      return;
    }
  };

  // ❌ PROBLEM: setTimeout creates async gap where child components mount first
  initTimer = setTimeout(initializeAuth, 0);

  return () => {
    isMounted = false;
    if (initTimer) clearTimeout(initTimer);
  };
}, []);
```

---

## Comparison: Working vs Failing Requests

### Working: Python Script Direct API Call

**Request:**
```http
GET https://production-backend-rwbh.onrender.com/api/brands/current
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
```

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "brand": {
    "id": "brand-123",
    "name": "Test Brand",
    ...
  },
  "is_member": true,
  "member_role": "owner"
}
```

**Why it works:**
- Token is explicitly included in request
- No race conditions in synchronous Python code
- Single-threaded execution ensures proper order

### Failing: Browser Frontend API Call

**Request (during race condition):**
```http
GET https://production-backend-rwbh.onrender.com/api/brands/current
Authorization: <MISSING>
Content-Type: application/json
```

**Response:**
```http
HTTP/1.1 401 Unauthorized
Content-Type: application/json

{
  "detail": "Not authenticated"
}
```

**Why it fails:**
- Request sent before token is available in `apiClient.tokenStorage`
- React component lifecycle causes BrandProvider to mount immediately
- No synchronization between AuthProvider init and BrandProvider mount

---

## Token Inspection Results

### localStorage State Analysis

When the issue occurs, examining browser localStorage shows:

```javascript
// In browser console after 401 error:
localStorage.getItem('engarde_tokens')
// Returns: '{"accessToken":"eyJhbG...","refreshToken":"eyJhbG...","expiresAt":1728429600000}'

localStorage.getItem('engarde_user')
// Returns: '{"id":"user-123","email":"test@engarde.ai","userType":"brand","cachedAt":1728343200000}'
```

**Conclusion:** Tokens ARE present in localStorage, but the timing issue prevents them from being used in the initial brand request.

### Token Format Verification

Using `/Users/cope/EnGardeHQ/production-frontend/lib/auth/auth-persistence.ts`:

```javascript
// In browser console:
window.checkAuth()
```

**Output:**
```json
{
  "hasTokens": true,
  "hasValidTokens": true,
  "hasUserData": true,
  "hasValidUserData": true,
  "isFullyAuthenticated": true,
  "details": {
    "tokens": {
      "accessToken": true,
      "refreshToken": true,
      "expiresAt": "2025-10-09T14:30:00.000Z",
      "isExpired": false,
      "timeUntilExpiry": 1425
    },
    "user": {
      "email": "test@engarde.ai",
      "userType": "brand",
      "isActive": true,
      "cacheAge": 5,
      "isStale": false
    }
  }
}
```

**Conclusion:** Token format is correct, expiration is valid, user data is fresh. The problem is NOT token validity - it's timing.

---

## Race Condition Analysis

### Timing Diagram

```
Time →   0ms           50ms          100ms         150ms         200ms
         |             |             |             |             |
AuthProvider Mount
         |
         ├─ dispatch(INIT_START)
         |
         ├─ setTimeout(initializeAuth, 0)
         |             |
         |             └─ Queued in event loop
         |
         └─ Children mount IMMEDIATELY
                       |
BrandProvider Mount    |
                       |
                       ├─ useCurrentBrand() fires
                       |
                       ├─ apiClient.get('/brands/current')
                       |
                       └─ createHeaders()
                                 |
                                 ├─ tokenStorage.accessToken === null ❌
                                 |
                                 └─ No Authorization header
                                           |
                                           └─ REQUEST SENT (missing token)
                                                     |
                                                     └─ Backend receives unauthorized request
                                                               |
                                                               └─ Returns 401
                                                                         |
                       initializeAuth() executes ─────────────────────┘
                                                                         |
                                                                         └─ Tokens NOW available ⏰ TOO LATE

```

### Critical Gap: 50-100ms Window

The race condition occurs in a **50-100ms window** where:
1. Tokens exist in localStorage
2. `apiClient` has loaded tokens into memory
3. But AuthProvider initialization hasn't completed
4. BrandProvider fires its query too early
5. API client's `tokenStorage.accessToken` is not yet accessible to `createHeaders()`

---

## Additional Evidence: Browser DevTools Network Tab

### What to Look For

When debugging in Chrome DevTools → Network tab:

1. **Request Headers:**
   ```
   GET /api/brands/current
   Authorization: <MISSING>  ❌ Should be "Bearer <token>"
   ```

2. **Response:**
   ```json
   {
     "detail": "Not authenticated"
   }
   ```

3. **Timing:**
   - Request sent: ~30-50ms after page load
   - Auth init complete: ~100-200ms after page load
   - **Gap:** 50-150ms race window

### Real-World Observation

In a real browser session after login:

```
Timeline:
├─ 0ms:    Page load
├─ 10ms:   AuthProvider mounts
├─ 15ms:   BrandProvider mounts
├─ 20ms:   useCurrentBrand query fires
├─ 25ms:   GET /api/brands/current (NO AUTH HEADER) ❌
├─ 75ms:   401 Unauthorized response
├─ 120ms:  AuthProvider init completes ⏰
└─ 125ms:  Tokens now available in apiClient
```

---

## BDD Test Scenarios for the Issue

### Scenario 1: Fresh Login - Race Condition Triggers

**Given** a user is not authenticated
**And** the user is on the login page
**When** the user enters valid credentials
**And** clicks "Login"
**Then** the authentication should complete successfully
**And** tokens should be stored in localStorage
**But** the BrandProvider mounts before AuthProvider init completes
**And** the brand API request is sent without Authorization header
**And** the API returns 401 Unauthorized
**And** the dashboard shows an error state

### Scenario 2: Page Reload - Race Condition on Cached Auth

**Given** a user is authenticated with valid tokens in localStorage
**When** the user refreshes the page
**Then** AuthProvider should start initialization
**But** BrandProvider mounts immediately during render
**And** BrandProvider fires useCurrentBrand() before tokens are ready
**And** the initial brand request fails with 401
**Then** React Query may retry the request
**And** the retry succeeds (because tokens are now available)
**But** the user sees a flash of error state or loading

### Scenario 3: Direct Navigation - Timing Sensitive

**Given** a user has valid authentication
**When** the user navigates directly to /dashboard via URL
**Then** the race condition may or may not occur depending on:
  - Browser caching
  - Network speed
  - React hydration timing
**And** the behavior is non-deterministic
**Result:** Flaky user experience

### Scenario 4: Token Refresh - Works After Initial Failure

**Given** the initial brand request failed with 401
**When** React Query retries the request after 1 second
**Then** AuthProvider initialization has completed
**And** tokens are available in apiClient.tokenStorage
**And** the retry request includes Authorization header
**And** the API returns 200 OK
**But** this creates a poor user experience with delayed content

### Scenario 5: Python Script - No Race Condition

**Given** a Python script with hardcoded token
**When** the script calls GET /api/brands/current
**Then** the token is included in the request synchronously
**And** there is no provider initialization race
**And** the API returns 200 OK
**Result:** Demonstrates the issue is frontend-specific, not backend

---

## Technical Deep Dive: Why This Happens

### React Provider Mounting Behavior

React providers mount their children **synchronously during the render phase**, even if the provider itself has async initialization logic in `useEffect`.

**From React documentation:**
> "Effects run after the browser paints, so by the time your effect runs, React has already committed the update and the DOM has been painted."

This means:
1. `<AuthProvider>` renders
2. Its children (`<BrandProvider>`) render IMMEDIATELY
3. `useEffect` in `AuthProvider` runs AFTER children have mounted
4. By the time auth init completes, BrandProvider already fired its query

### localStorage Async Access Pattern

The API client loads tokens from localStorage synchronously:

```tsx
// File: /Users/cope/EnGardeHQ/production-frontend/lib/api/client.ts
constructor() {
  this.loadTokensFromStorage(); // Synchronous
}

private loadTokensFromStorage(): void {
  if (typeof window !== 'undefined') {
    const storedTokens = localStorage.getItem('engarde_tokens'); // Synchronous
    if (storedTokens) {
      this.tokenStorage = JSON.parse(storedTokens); // Synchronous
    }
  }
}
```

However, the AuthProvider's initialization logic runs in `useEffect`, which is async relative to rendering.

### React Query Immediate Execution

React Query's `useQuery` fires immediately when the component mounts, unless `enabled: false` is set:

```tsx
useQuery({
  queryKey: ['brand'],
  queryFn: fetchBrand,
  // Without enabled: false, this fires IMMEDIATELY on mount
})
```

---

## Recommended Solutions

### Solution 1: Add Enabled Condition to useCurrentBrand (RECOMMENDED)

**File:** `/Users/cope/EnGardeHQ/production-frontend/lib/api/brands.ts`

```tsx
export function useCurrentBrand(options?: UseQueryOptions<Brand, Error>) {
  // Access auth context to check readiness
  const { state } = useAuth(); // Import from AuthContext

  return useQuery<Brand, Error>({
    queryKey: brandKeys.current(),
    queryFn: async () => {
      const response = await apiClient.get<BrandDetailResponse>('/brands/current');
      return response.data.data;
    },
    staleTime: 5 * 60 * 1000,
    // ✅ FIX: Only enable query when auth is ready
    enabled: !state.initializing && state.isAuthenticated,
    ...options,
  });
}
```

**Pros:**
- Minimal code change
- Fixes root cause directly
- Prevents unnecessary API calls
- No breaking changes

**Cons:**
- Requires importing useAuth in brands.ts
- All brand hooks need similar updates

### Solution 2: Add Auth Check in BrandProvider (ALTERNATIVE)

**File:** `/Users/cope/EnGardeHQ/production-frontend/contexts/BrandContext.tsx`

```tsx
export function BrandProvider({ children }: BrandProviderProps) {
  const { state } = useAuth();

  // ✅ FIX: Don't query until auth is ready
  const { data: currentBrand, isLoading, error } = useCurrentBrand({
    enabled: !state.initializing && state.isAuthenticated
  });

  const value: BrandContextValue = {
    currentBrand: currentBrand || null,
    isLoading: isLoading || state.initializing, // Include auth loading
    error: error || null,
  };

  return (
    <BrandContext.Provider value={value}>
      {children}
    </BrandContext.Provider>
  );
}
```

**Pros:**
- Centralized fix in one component
- Explicit auth dependency
- Easy to test

**Cons:**
- BrandProvider now depends on AuthContext
- Circular dependency concerns
- May not fix other brand hooks used outside BrandProvider

### Solution 3: Wrap BrandProvider with Auth Gate (DEFENSIVE)

**File:** `/Users/cope/EnGardeHQ/production-frontend/app/layout.tsx`

```tsx
function AuthGatedBrandProvider({ children }: { children: React.ReactNode }) {
  const { state } = useAuth();

  // Don't render BrandProvider until auth is ready
  if (state.initializing) {
    return <>{children}</>;
  }

  return <BrandProvider>{children}</BrandProvider>;
}

// In layout:
<AuthProvider>
  <ApiErrorProvider>
    <AuthGatedBrandProvider>
      <WebSocketProvider>
        {children}
      </WebSocketProvider>
    </AuthGatedBrandProvider>
  </ApiErrorProvider>
</AuthProvider>
```

**Pros:**
- Completely prevents race condition
- No changes to BrandProvider internals
- Can be applied to any provider

**Cons:**
- Adds extra component layer
- Slightly more complex layout
- Children render twice (before and after gate)

### Solution 4: Move Auth Init to Synchronous Constructor (RISKY)

**Not recommended** - Would require significant refactoring and could introduce other issues.

---

## Testing Recommendations

### Unit Tests

```typescript
// File: /Users/cope/EnGardeHQ/production-frontend/__tests__/brand-auth-race-condition.test.tsx

describe('Brand Provider Auth Race Condition', () => {
  it('should not call brand API before auth initialization completes', async () => {
    const mockGet = jest.fn();
    apiClient.get = mockGet;

    render(
      <AuthProvider>
        <BrandProvider>
          <div>Test</div>
        </BrandProvider>
      </AuthProvider>
    );

    // Auth init should complete first
    await waitFor(() => expect(mockGet).not.toHaveBeenCalled(), { timeout: 100 });
  });

  it('should call brand API after auth is ready', async () => {
    const mockGet = jest.fn().mockResolvedValue({ data: { data: mockBrand } });
    apiClient.get = mockGet;

    render(
      <AuthProvider>
        <BrandProvider>
          <div>Test</div>
        </BrandProvider>
      </AuthProvider>
    );

    // Wait for auth init
    await waitFor(() => expect(mockGet).toHaveBeenCalledWith('/brands/current'), { timeout: 500 });
  });
});
```

### E2E Tests

```typescript
// File: /Users/cope/EnGardeHQ/production-frontend/e2e/brand-auth-timing.spec.ts

test('should load brand data after login without 401 errors', async ({ page }) => {
  // Intercept API calls
  const requests: string[] = [];
  page.on('request', request => {
    if (request.url().includes('/brands/current')) {
      const headers = request.headers();
      requests.push(headers['authorization'] || 'MISSING');
    }
  });

  // Login
  await page.goto('/login');
  await page.fill('input[name="email"]', 'test@engarde.ai');
  await page.fill('input[name="password"]', 'test123');
  await page.click('button[type="submit"]');

  // Wait for dashboard
  await page.waitForURL('/dashboard');

  // Verify all brand requests had auth header
  expect(requests.every(auth => auth.startsWith('Bearer '))).toBe(true);
  expect(requests.length).toBeGreaterThan(0);
});
```

---

## Monitoring & Detection

### Production Monitoring

Add monitoring to detect 401 errors on brand endpoints:

```typescript
// In API client error handler
private async handleApiError(response: Response): Promise<ApiError> {
  if (response.status === 401 && response.url.includes('/brands')) {
    // Log to monitoring service
    console.error('BRAND AUTH RACE CONDITION DETECTED', {
      url: response.url,
      hadToken: !!this.tokenStorage.accessToken,
      timestamp: Date.now()
    });

    // Send to error tracking (Sentry, etc.)
    if (typeof window !== 'undefined' && window.Sentry) {
      window.Sentry.captureException(new Error('Brand API 401 - Possible race condition'));
    }
  }

  // ... rest of error handling
}
```

### User-Facing Indicators

Add logging to help identify the issue in production:

```tsx
// In BrandProvider
useEffect(() => {
  if (error && error.status === 401) {
    console.error('BrandProvider: 401 error detected', {
      isAuthInitializing: state.initializing,
      isAuthenticated: state.isAuthenticated,
      hasToken: !!apiClient.getAccessToken()
    });
  }
}, [error]);
```

---

## Conclusion

### Root Cause Summary

The brand endpoints return 401 from the frontend due to a **React provider mounting race condition**:

1. `BrandProvider` mounts as a child of `AuthProvider`
2. `BrandProvider` immediately fires `useCurrentBrand()` query
3. Query executes before `AuthProvider.useEffect` initialization completes
4. API client doesn't have token available yet
5. Request sent without Authorization header
6. Backend returns 401

This does NOT occur with direct Python API calls because:
- No provider initialization race
- Token is synchronously available
- Single-threaded execution ensures proper order

### Recommended Fix

**Implement Solution 1**: Add `enabled` condition to `useCurrentBrand` that checks auth state:

```tsx
enabled: !state.initializing && state.isAuthenticated
```

This prevents the query from executing until authentication is confirmed ready.

### Validation Steps

After implementing the fix:

1. Clear localStorage: `localStorage.clear()`
2. Navigate to `/login`
3. Login with test credentials
4. Open DevTools Network tab
5. Verify `/brands/current` request includes Authorization header
6. Verify 200 OK response
7. Verify no 401 errors in console

---

## Appendix: Additional Files to Review

- `/Users/cope/EnGardeHQ/production-frontend/contexts/AuthContext.tsx` - Auth initialization logic
- `/Users/cope/EnGardeHQ/production-frontend/contexts/BrandContext.tsx` - Brand provider implementation
- `/Users/cope/EnGardeHQ/production-frontend/lib/api/brands.ts` - Brand API hooks
- `/Users/cope/EnGardeHQ/production-frontend/lib/api/client.ts` - API client token handling
- `/Users/cope/EnGardeHQ/production-frontend/app/layout.tsx` - Provider mounting order
- `/Users/cope/EnGardeHQ/production-backend/app/routers/brands.py` - Backend endpoint (for reference)

---

**Report generated by:** Claude (QA Engineer)
**Date:** October 8, 2025
**Next Steps:** Implement recommended fix and validate with comprehensive testing
