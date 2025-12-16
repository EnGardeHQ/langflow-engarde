# Frontend-Backend Timeout - Quick Fix Guide

## Problem
API requests timing out after 30 seconds. Login authentication failing.

## Root Cause
**Missing `BACKEND_URL` environment variable in Vercel**, causing API route to use `http://localhost:8000` which Vercel cannot access.

## Quick Fix (5 Minutes)

### Step 1: Set Environment Variable in Vercel

1. Go to [Vercel Dashboard](https://vercel.com)
2. Select your project
3. Go to **Settings** → **Environment Variables**
4. Click **Add New**
5. Add:
   - **Name:** `BACKEND_URL`
   - **Value:** `https://api.engarde.media` (or your Railway backend URL)
   - **Environment:** Select all (Production, Preview, Development)
6. Click **Save**

### Step 2: Verify `NEXT_PUBLIC_API_URL`

1. In same Environment Variables page
2. Find `NEXT_PUBLIC_API_URL`
3. Verify it's set to: `https://api.engarde.media` (absolute URL)
4. If it's set to `/api`, update it to the Railway backend URL

### Step 3: Redeploy

1. Go to **Deployments** tab
2. Click **Redeploy** on latest deployment
3. Or push a commit to trigger redeploy

### Step 4: Test

1. Open your app
2. Attempt login
3. Check browser console - should see success, not timeout errors

---

## Alternative: Code Fix (If Environment Variable Doesn't Work)

If setting environment variables doesn't work, update the API route:

**File:** `production-frontend/app/api/token/route.ts`

**Replace lines 15-32 with:**

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

Then commit and push:
```bash
git add production-frontend/app/api/token/route.ts
git commit -m "Fix: Use production backend URL in Vercel"
git push
```

---

## Verification

### Check Environment Variables
```bash
# Via Vercel CLI
vercel env ls

# Should show:
# BACKEND_URL=https://api.engarde.media
# NEXT_PUBLIC_API_URL=https://api.engarde.media
```

### Test Backend
```bash
curl https://api.engarde.media/health
# Should return: {"status":"healthy",...}
```

### Check Logs
```bash
# Via Vercel CLI
vercel logs --follow

# Look for:
# 🔍 API ROUTE /api/token: Backend URL detection: { detectedBackendUrl: 'https://api.engarde.media' }
```

---

## Expected Result

**Before:**
- ❌ Timeout after 30 seconds
- ❌ Connection refused errors
- ❌ Login fails

**After:**
- ✅ Login succeeds in < 5 seconds
- ✅ No timeout errors
- ✅ Authentication works

---

**Time Required:** 5 minutes  
**Difficulty:** Easy  
**Confidence:** 95%
