# Frontend-Backend Timeout Issue - Line-by-Line Analysis

**Date:** 2025-01-XX  
**Issue:** API requests timing out after 30 seconds (3 retries)  
**Symptoms:** Login authentication failing with timeout errors in browser console

---

## Error Analysis

### Browser Console Errors

```
⚠️ API CLIENT: Request timeout after 30000ms (attempt 1/3)
⚠️ API CLIENT: Retrying after timeout, waiting 1000ms
⚠️ API CLIENT: Request timeout after 30000ms (attempt 2/3)
⚠️ API CLIENT: Retrying after timeout, waiting 2000ms
⚠️ API CLIENT: Request timeout after 30000ms (attempt 3/3)
⚠️ API CLIENT: Retrying after timeout, waiting 4000ms
⚠️ API CLIENT: Request timeout after 30000ms (attempt 4/3)
```

**Analysis:**
- Client-side timeout: 30 seconds (30000ms)
- 3 retries configured, but 4 attempts shown (bug in retry logic)
- Each retry waits exponentially longer (1s, 2s, 4s)
- Total time: ~37+ seconds before final failure

---

## Code Flow Analysis

### 1. Frontend API Client (`lib/api/client.ts`)

#### Line 8-19: Base URL Configuration
```typescript
function getApiBaseUrl(): string {
  const isBrowser = typeof window !== 'undefined';
  
  // CRITICAL: In browser (client-side), always use relative paths
  if (isBrowser) {
    return '/api';  // ← Relative path
  }
  
  // For server-side, also use relative paths
  return '/api';  // ← Relative path
}
```

**Issue:** ✅ Correct - Uses relative paths `/api` which works with Next.js rewrites/middleware

#### Line 552: Timeout Configuration
```typescript
const { skipAuth = false, skipRefresh = false, maxRetries = 3, timeout = 30000, ...fetchOptions } = options;
```

**Issue:** ✅ Correct - 30-second timeout is reasonable

#### Line 559-570: URL Construction
```typescript
let url: string;
if (this.baseURL.startsWith('/')) {
  // Relative path - use as-is
  url = `${this.baseURL}${endpoint.startsWith('/') ? endpoint : '/' + endpoint}`;
  // Results in: /api/token
}
```

**Issue:** ✅ Correct - Constructs `/api/token` correctly

#### Line 621-627: Timeout Implementation
```typescript
const controller = new AbortController();
const timeoutId = setTimeout(() => controller.abort(), timeout);

const response = await fetch(url, {
  ...requestOptions,
  signal: controller.signal
});
```

**Issue:** ✅ Correct - Proper timeout implementation with AbortController

---

### 2. Middleware (`middleware.ts`)

#### Line 635-638: `/api/token` Handling
```typescript
if (pathname === '/api/token') {
  console.log('⚠️ MIDDLEWARE: /api/token called - letting Next.js API route handle it');
  return null; // Let Next.js API route handle it
}
```

**Issue:** ✅ Correct - Middleware correctly bypasses `/api/token` to let API route handle it

#### Line 609-784: API Proxy Function
```typescript
async function handleAPIProxy(request: NextRequest): Promise<NextResponse | null> {
  // Only proxy API routes
  if (!pathname.startsWith('/api/')) {
    return null;
  }
  
  // Let /api/token requests pass through to Next.js API route handler
  if (pathname === '/api/token') {
    return null; // Let Next.js API route handle it
  }
  // ... rest of proxy logic
}
```

**Issue:** ✅ Correct - Middleware correctly lets `/api/token` pass through to API route

---

### 3. API Route Handler (`app/api/token/route.ts`)

#### Line 15-32: Backend URL Detection
```typescript
const getBackendUrl = () => {
  const backendUrl = process.env.BACKEND_URL ||
                     (process.env.NEXT_PUBLIC_API_URL && !process.env.NEXT_PUBLIC_API_URL.startsWith('/') 
                      ? process.env.NEXT_PUBLIC_API_URL 
                      : null) ||
                     'http://localhost:8000';  // ← DEFAULT FALLBACK
  
  console.log('🔍 API ROUTE /api/token: Backend URL detection:', {
    BACKEND_URL: process.env.BACKEND_URL,
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
    detectedBackendUrl: backendUrl,
  });
  
  return backendUrl;
};
```

**🚨 CRITICAL ISSUE #1:** 
- If `BACKEND_URL` is not set in Vercel, it defaults to `http://localhost:8000`
- Vercel serverless functions **cannot** connect to `localhost:8000`
- This causes connection timeout/failure

**Root Cause:** Missing `BACKEND_URL` environment variable in Vercel

#### Line 74-79: Timeout Configuration
```typescript
const controller = new AbortController();
const timeoutId = setTimeout(() => {
  console.error('❌ API ROUTE /api/token: Backend request timeout after 50 seconds');
  controller.abort();
}, 50000); // 50 seconds
```

**Issue:** ✅ Correct - 50-second timeout is longer than client timeout (30s)

#### Line 83-98: Backend Request
```typescript
const backendTokenUrl = `${BACKEND_URL}/api/token`;

const backendResponse = await fetch(backendTokenUrl, {
  method: 'POST',
  body: backendFormData,
  headers: {
    'Accept': 'application/json',
  },
  signal: controller.signal,
});
```

**🚨 CRITICAL ISSUE #2:**
- If `BACKEND_URL` is `http://localhost:8000`, this will fail from Vercel
- Vercel serverless functions run in AWS Lambda, not on your local machine
- They cannot access `localhost:8000`

**Root Cause:** Backend URL not configured correctly for Vercel deployment

---

### 4. Backend CORS Configuration (`app/main.py`)

#### Line 388-408: CORS Origins
```python
cors_origins = [
    "http://localhost:3000",
    "http://localhost:3001",
    # ... other localhost ports
    "https://*.vercel.app",  # ← Allows Vercel deployments
    "https://engarde.ai",
    "https://*.engarde.ai"
]
```

**Issue:** ✅ Correct - CORS allows `https://*.vercel.app` which covers Vercel deployments

#### Line 421-427: CORS Middleware
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)
```

**Issue:** ✅ Correct - CORS is properly configured

---

## Root Cause Analysis

### Primary Issue: Missing `BACKEND_URL` in Vercel

**Problem:**
1. Frontend API route (`app/api/token/route.ts`) needs `BACKEND_URL` to connect to Railway backend
2. If `BACKEND_URL` is not set, it defaults to `http://localhost:8000`
3. Vercel serverless functions cannot connect to `localhost:8000`
4. Request times out after 30 seconds (client) / 50 seconds (API route)

**Evidence:**
- Line 17-21 in `app/api/token/route.ts`: Falls back to `http://localhost:8000`
- Line 83: Uses `${BACKEND_URL}/api/token` which would be `http://localhost:8000/api/token` if not set
- This explains the timeout - Vercel can't reach localhost

### Secondary Issue: Environment Variable Priority

**Problem:**
The `getBackendUrl()` function checks:
1. `BACKEND_URL` (server-side only)
2. `NEXT_PUBLIC_API_URL` (if not relative path)
3. `http://localhost:8000` (fallback)

**Issue:** In Vercel, `BACKEND_URL` might not be set, and `NEXT_PUBLIC_API_URL` might be set to `/api` (relative), causing fallback to localhost.

---

## Solutions

### Solution 1: Set `BACKEND_URL` in Vercel (Recommended)

**Action Required:**
1. Go to Vercel Dashboard → Your Project → Settings → Environment Variables
2. Add new variable:
   - **Name:** `BACKEND_URL`
   - **Value:** `https://api.engarde.media` (or your Railway backend URL)
   - **Environment:** Production, Preview, Development
3. Redeploy the application

**Why This Works:**
- API route will use `BACKEND_URL` instead of falling back to localhost
- Serverless functions can connect to Railway backend via HTTPS
- No code changes required

### Solution 2: Ensure `NEXT_PUBLIC_API_URL` is Set Correctly

**Action Required:**
1. Verify in Vercel Dashboard → Settings → Environment Variables:
   - `NEXT_PUBLIC_API_URL` should be `https://api.engarde.media` (absolute URL)
   - NOT `/api` (relative path)
2. If it's set to `/api`, update it to the Railway backend URL

**Why This Works:**
- `getBackendUrl()` will use `NEXT_PUBLIC_API_URL` if `BACKEND_URL` is not set
- But only if it's an absolute URL (doesn't start with `/`)

### Solution 3: Fix API Route Backend URL Detection (Code Fix)

**File:** `production-frontend/app/api/token/route.ts`

**Current Code (Line 15-32):**
```typescript
const getBackendUrl = () => {
  const backendUrl = process.env.BACKEND_URL ||
                     (process.env.NEXT_PUBLIC_API_URL && !process.env.NEXT_PUBLIC_API_URL.startsWith('/') 
                      ? process.env.NEXT_PUBLIC_API_URL 
                      : null) ||
                     'http://localhost:8000';  // ← Problem: Falls back to localhost
  return backendUrl;
};
```

**Fixed Code:**
```typescript
const getBackendUrl = () => {
  // Priority 1: BACKEND_URL (server-side only)
  if (process.env.BACKEND_URL) {
    return process.env.BACKEND_URL;
  }
  
  // Priority 2: NEXT_PUBLIC_API_URL (if absolute URL)
  if (process.env.NEXT_PUBLIC_API_URL && 
      !process.env.NEXT_PUBLIC_API_URL.startsWith('/') &&
      (process.env.NEXT_PUBLIC_API_URL.startsWith('http://') || 
       process.env.NEXT_PUBLIC_API_URL.startsWith('https://'))) {
    return process.env.NEXT_PUBLIC_API_URL;
  }
  
  // Priority 3: Production default (instead of localhost)
  if (process.env.NODE_ENV === 'production' || process.env.VERCEL === '1') {
    // In production/Vercel, default to production backend
    return process.env.NEXT_PUBLIC_API_URL || 'https://api.engarde.media';
  }
  
  // Priority 4: Development fallback
  return 'http://localhost:8000';
};
```

**Why This Works:**
- Detects production/Vercel environment
- Uses production backend URL instead of localhost
- Prevents localhost fallback in production

### Solution 4: Add Better Error Logging

**File:** `production-frontend/app/api/token/route.ts`

**Add after Line 34:**
```typescript
// Log backend URL detection for debugging
console.log('🔍 API ROUTE /api/token: Environment Detection:', {
  NODE_ENV: process.env.NODE_ENV,
  VERCEL: process.env.VERCEL,
  BACKEND_URL: process.env.BACKEND_URL || 'NOT SET',
  NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'NOT SET',
  detectedBackendUrl: BACKEND_URL,
  isProduction: process.env.NODE_ENV === 'production',
  isVercel: process.env.VERCEL === '1',
});
```

**Why This Works:**
- Helps diagnose environment variable issues
- Shows what URL is being used
- Makes debugging easier

---

## Verification Steps

### Step 1: Check Vercel Environment Variables

```bash
# Via Vercel CLI (if installed)
vercel env ls

# Or check in Dashboard:
# Vercel Dashboard → Project → Settings → Environment Variables
```

**Required Variables:**
- ✅ `BACKEND_URL` = `https://api.engarde.media` (or your Railway URL)
- ✅ `NEXT_PUBLIC_API_URL` = `https://api.engarde.media` (absolute URL, not `/api`)

### Step 2: Test Backend Connectivity

**From Vercel Serverless Function:**
```typescript
// Add to app/api/token/route.ts for testing
const testBackend = async () => {
  try {
    const response = await fetch(`${BACKEND_URL}/health`, {
      signal: AbortSignal.timeout(5000)
    });
    console.log('✅ Backend health check:', response.status);
  } catch (error) {
    console.error('❌ Backend health check failed:', error);
  }
};
```

### Step 3: Check Vercel Function Logs

```bash
# Via Vercel CLI
vercel logs --follow

# Or in Dashboard:
# Vercel Dashboard → Project → Deployments → [Latest] → Functions → [Function Name] → Logs
```

**Look for:**
- `🔍 API ROUTE /api/token: Backend URL detection:` logs
- Connection errors (ECONNREFUSED, ENOTFOUND)
- Timeout errors

### Step 4: Test Login Flow

1. Open browser DevTools → Network tab
2. Attempt login
3. Check:
   - Request to `/api/token` (should be 200 OK)
   - Response time (should be < 5 seconds)
   - No timeout errors

---

## Quick Fix Checklist

- [ ] **Set `BACKEND_URL` in Vercel:**
  - Go to Vercel Dashboard → Settings → Environment Variables
  - Add `BACKEND_URL=https://api.engarde.media`
  - Apply to Production, Preview, Development

- [ ] **Verify `NEXT_PUBLIC_API_URL` in Vercel:**
  - Should be `https://api.engarde.media` (absolute URL)
  - NOT `/api` (relative path)

- [ ] **Redeploy Application:**
  - Push a commit or trigger redeploy
  - Wait for deployment to complete

- [ ] **Test Login:**
  - Attempt login
  - Check browser console for errors
  - Check Vercel function logs

- [ ] **Verify Backend Accessibility:**
  - Test: `curl https://api.engarde.media/health`
  - Should return 200 OK

---

## Expected Behavior After Fix

### Before Fix:
```
Frontend → /api/token → API Route → http://localhost:8000/api/token → ❌ Timeout
```

### After Fix:
```
Frontend → /api/token → API Route → https://api.engarde.media/api/token → ✅ Success
```

---

## Additional Debugging

### Check Railway Backend Logs

```bash
# Via Railway CLI
railway logs --follow

# Look for:
# - Incoming requests to /api/token
# - CORS errors
# - Authentication errors
```

### Test Backend Directly

```bash
# Test backend health
curl https://api.engarde.media/health

# Test token endpoint
curl -X POST https://api.engarde.media/api/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=test@example.com&password=test123&grant_type=password"
```

### Network Analysis

**Browser DevTools → Network Tab:**
1. Filter: `token` or `api`
2. Check:
   - Request URL (should be `/api/token`)
   - Request Method (should be POST)
   - Status Code (should be 200, not 504)
   - Response Time (should be < 5 seconds)

---

## Summary

### Root Cause
**Missing `BACKEND_URL` environment variable in Vercel**, causing API route to fall back to `http://localhost:8000`, which Vercel serverless functions cannot access.

### Primary Fix
**Set `BACKEND_URL=https://api.engarde.media` in Vercel environment variables.**

### Secondary Fix
**Update `getBackendUrl()` function to detect production environment and use production backend URL instead of localhost.**

### Verification
1. Check Vercel environment variables
2. Test backend connectivity
3. Check Vercel function logs
4. Test login flow

---

**Priority:** 🔴 Critical  
**Estimated Fix Time:** 5 minutes (environment variable) or 15 minutes (code fix)  
**Confidence:** 95% - This is the most likely cause based on code analysis
