# Debug Timeout Issue - Immediate Steps

## Current Status
Timeout errors persist after code fix. Need to verify:
1. Code changes deployed?
2. Backend accessible?
3. Environment variables set?

## Immediate Debugging Steps

### Step 1: Check if Code Changes Are Deployed

**Check Vercel Deployment:**
1. Go to Vercel Dashboard → Deployments
2. Check latest deployment timestamp
3. Verify it's after the code changes were pushed

**Check Git Status:**
```bash
cd /Users/cope/EnGardeHQ
git status
git log --oneline -5
```

### Step 2: Check Vercel Function Logs

**Via Vercel CLI:**
```bash
vercel logs --follow
```

**Look for:**
- `🔍 API ROUTE /api/auth/login: Backend URL detection:` logs
- `⚠️ API ROUTE /api/auth/login: Production environment detected` warnings
- Connection errors (ECONNREFUSED, ENOTFOUND, timeout)

**Via Dashboard:**
1. Vercel Dashboard → Project → Deployments → [Latest]
2. Click on Functions tab
3. Find `/api/auth/login` function
4. Check logs for backend URL and errors

### Step 3: Test Backend Directly

**Test Backend Health:**
```bash
curl -v https://api.engarde.media/health --max-time 10
```

**Test Backend Token Endpoint:**
```bash
curl -v -X POST https://api.engarde.media/api/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=test@example.com&password=test123&grant_type=password" \
  --max-time 10
```

**Expected:**
- Health endpoint: 200 OK with `{"status":"healthy",...}`
- Token endpoint: 401 Unauthorized (expected - wrong credentials) or 200 OK (if credentials valid)

### Step 4: Check Environment Variables in Vercel

**Via Dashboard:**
1. Vercel Dashboard → Project → Settings → Environment Variables
2. Verify:
   - `BACKEND_URL` = `https://api.engarde.media` (or your Railway URL)
   - `NEXT_PUBLIC_API_URL` = `https://api.engarde.media` (absolute URL, not `/api`)

**Via CLI:**
```bash
vercel env ls
```

### Step 5: Add Debug Logging

**Add to `app/api/auth/login/route.ts` at the start of POST function:**

```typescript
export async function POST(request: NextRequest) {
  // DEBUG: Log environment detection
  console.log('🔍 DEBUG /api/auth/login: Environment Check:', {
    NODE_ENV: process.env.NODE_ENV,
    VERCEL: process.env.VERCEL,
    BACKEND_URL: process.env.BACKEND_URL || 'NOT SET',
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'NOT SET',
    detectedBackendUrl: BACKEND_URL,
    timestamp: new Date().toISOString()
  });
  
  // ... rest of function
}
```

### Step 6: Test from Browser DevTools

**Open Browser Console and run:**
```javascript
// Test direct backend connection
fetch('https://api.engarde.media/health')
  .then(r => r.json())
  .then(console.log)
  .catch(console.error);

// Test API route
fetch('/api/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ username: 'test@example.com', password: 'test123' })
})
  .then(r => r.json())
  .then(console.log)
  .catch(console.error);
```

## Common Issues & Solutions

### Issue 1: Code Not Deployed
**Symptom:** Logs show old backend URL detection logic
**Fix:** Push code and redeploy

### Issue 2: BACKEND_URL Not Set
**Symptom:** Logs show `detectedBackendUrl: http://localhost:8000`
**Fix:** Set `BACKEND_URL` in Vercel environment variables

### Issue 3: Backend Not Accessible
**Symptom:** Connection refused or timeout from Vercel
**Fix:** 
- Check Railway backend is running
- Check Railway backend URL is correct
- Check CORS allows Vercel domain

### Issue 4: Wrong Backend URL
**Symptom:** Logs show incorrect backend URL
**Fix:** Update `BACKEND_URL` in Vercel to correct Railway URL

## Quick Test Script

```bash
#!/bin/bash
# Quick backend connectivity test

echo "Testing backend health..."
curl -s https://api.engarde.media/health | jq . || echo "Health check failed"

echo -e "\nTesting backend token endpoint..."
curl -s -X POST https://api.engarde.media/api/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=test@example.com&password=test123&grant_type=password" | jq . || echo "Token endpoint failed"

echo -e "\nChecking Vercel environment..."
vercel env ls | grep -E "BACKEND_URL|NEXT_PUBLIC_API_URL" || echo "Vercel CLI not installed"
```

## Next Steps Based on Findings

### If Backend Not Accessible:
1. Check Railway deployment status
2. Check Railway logs for errors
3. Verify Railway backend URL

### If Environment Variables Wrong:
1. Update in Vercel Dashboard
2. Redeploy application

### If Code Not Deployed:
1. Commit and push changes
2. Wait for Vercel deployment
3. Test again

---

**Priority:** 🔴 Critical  
**Action:** Run debugging steps above to identify root cause
