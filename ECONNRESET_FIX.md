# ECONNRESET Fix - Login Request Abortion Issue

## Problem Summary

The login request was being aborted mid-flight, causing `ECONNRESET` errors on the backend. The error looked like:

```
Error: aborted
    at connResetException (node:internal/errors:720:14)
    at abortIncoming (node:_http_server:781:17)
    at socketOnClose (node:_http_server:775:3)
  code: 'ECONNRESET'
```

## Root Cause

The issue was a **timeout mismatch** between different layers of the application:

### Request Flow
```
Browser (Client) → Next.js API Route → Backend FastAPI
     30s timeout         NO TIMEOUT        (slow/down)
```

1. **Client-side timeout**: The `apiClient` had a default 30-second timeout with AbortController
2. **API Route**: The Next.js `/api/auth/login` route had **NO timeout** on its backend fetch
3. **Backend**: Could be slow or down, causing the API route's fetch to hang

### The Race Condition

```
Time  | Client                    | API Route              | Backend
------|---------------------------|------------------------|------------------
0s    | POST /api/auth/login      |                        |
0.1s  |                          | fetch /api/token       |
0.2s  |                          |                        | Processing...
...   |                          |                        | (slow or down)
30s   | ⏰ Timeout! Abort!        | Still waiting...       | Still processing
30.1s | ❌ Cancel request         | Connection closed!     | Trying to respond
30.2s | (ECONNRESET)             | ❌ ECONNRESET error    | ❌ aborted
```

**What happened:**
1. Client sends request to API route
2. API route starts fetch to backend (no timeout)
3. Backend is slow or down
4. After 30 seconds, client's AbortController aborts the request
5. Browser cancels the connection to the API route
6. API route's backend fetch is still waiting
7. Backend finally responds, but API route → client connection is already closed
8. Result: **ECONNRESET** - "connection reset by peer"

## The Fix

### 1. Increased Client Timeout ✅

**File**: `/Users/cope/EnGardeHQ/production-frontend/services/auth.service.ts`

```typescript
const response = await apiClient.request<BackendLoginResponse>('/auth/login', {
  method: 'POST',
  body: JSON.stringify(requestBody),
  skipAuth: true,
  timeout: 60000, // ⬆️ Increased from 30s to 60s
  headers: {
    'Content-Type': 'application/json'
  }
});
```

**Why**: Give the backend more time to respond before aborting.

### 2. Added API Route Timeout ✅

**File**: `/Users/cope/EnGardeHQ/production-frontend/app/api/auth/login/route.ts`

```typescript
// Add timeout and abort controller
const controller = new AbortController();
const timeoutId = setTimeout(() => {
  console.error('❌ API ROUTE: Backend request timeout after 50 seconds');
  controller.abort();
}, 50000); // 50 seconds - MUST be less than client timeout (60s)

try {
  const backendResponse = await fetch(`${BACKEND_URL}/api/token`, {
    method: 'POST',
    body: backendFormData,
    headers: {
      'Accept': 'application/json',
    },
    signal: controller.signal, // ⬅️ Added abort signal
  });

  clearTimeout(timeoutId);

  // ... handle response
} catch (fetchError: any) {
  clearTimeout(timeoutId);

  // Handle timeout specifically
  if (fetchError.name === 'AbortError') {
    return NextResponse.json(
      { detail: 'Backend authentication service took too long to respond.' },
      { status: 504 } // Gateway Timeout
    );
  }

  // Handle connection errors
  if (fetchError.message?.includes('ECONNREFUSED')) {
    return NextResponse.json(
      { detail: 'Cannot connect to authentication service.' },
      { status: 503 } // Service Unavailable
    );
  }
}
```

**Why**:
- API route times out at 50s (before client's 60s timeout)
- Prevents client from aborting while API route is still waiting
- Provides better error messages

### 3. Enhanced Error Handling ✅

**File**: `/Users/cope/EnGardeHQ/production-frontend/app/login/page.tsx`

```typescript
try {
  await login({ email, password, userType });
  // Keep button disabled during navigation
} catch (error: any) {
  // Handle ECONNRESET specifically
  if (error?.code === 'ECONNRESET' || error?.message?.includes('aborted')) {
    setFormErrors({
      general: 'Connection was interrupted. Please check your internet connection and try again.'
    });
    setIsSubmitting(false);
    return;
  }

  // ... other error handling
  setIsSubmitting(false);
}
```

**Why**: Provide user-friendly error messages for connection issues.

## New Timeout Hierarchy

```
Client Request (60s)
    └── API Route Backend Fetch (50s)
            └── Backend Processing (variable)
```

The API route **ALWAYS** times out before the client, ensuring:
- Clean error responses instead of ECONNRESET
- Better error messages to users
- No hanging requests

## Testing the Fix

### 1. Test with Running Backend

```bash
# Terminal 1: Start backend
cd backend
python -m uvicorn main:app --reload

# Terminal 2: Start frontend
cd production-frontend
npm run dev

# Browser: Try login at http://localhost:3000/login
```

Expected: Login should work normally (completes in < 5 seconds).

### 2. Test with Slow Backend

```bash
# Simulate slow backend by adding delay in backend code
# OR use network throttling in browser DevTools
```

Expected:
- If backend responds within 50s → Login succeeds
- If backend takes > 50s → Clean error: "Backend took too long to respond"
- If backend is down → Clean error: "Cannot connect to authentication service"

### 3. Test with No Backend

```bash
# Don't start backend, just frontend
cd production-frontend
npm run dev
```

Expected: Error message "Cannot connect to authentication service" after 50 seconds.

## Key Improvements

1. **No More ECONNRESET**: Timeouts are properly coordinated
2. **Better Error Messages**: Users see helpful messages instead of cryptic errors
3. **Faster Feedback**: Errors are detected in 50s instead of hanging indefinitely
4. **Graceful Degradation**: Application handles backend issues cleanly

## Files Modified

1. `/Users/cope/EnGardeHQ/production-frontend/services/auth.service.ts`
   - Increased login timeout to 60 seconds

2. `/Users/cope/EnGardeHQ/production-frontend/app/api/auth/login/route.ts`
   - Added AbortController with 50-second timeout
   - Enhanced error handling for timeouts and connection errors

3. `/Users/cope/EnGardeHQ/production-frontend/app/login/page.tsx`
   - Added specific handling for ECONNRESET errors
   - Improved user-facing error messages

## Monitoring

To verify the fix is working, check the browser console for:

```
✅ AUTH SERVICE: Login completed successfully
```

And backend logs for:

```
200 OK /api/token
```

If you see errors, check for:
- ❌ API ROUTE: Backend request timeout (means backend > 50s)
- ❌ API ROUTE: Cannot connect to backend (means backend is down)
- ❌ LOGIN PAGE: ECONNRESET (should NOT happen anymore)

## Related Issues

- Request abortion during navigation
- Timeout mismatches causing race conditions
- Poor error handling for backend connectivity issues

## Prevention

To prevent similar issues in the future:

1. **Always set timeouts** on server-side fetch calls
2. **Coordinate timeouts** across layers (server timeout < client timeout)
3. **Handle abort errors** explicitly in catch blocks
4. **Provide user-friendly errors** instead of technical error codes
