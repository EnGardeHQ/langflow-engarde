# Backend Not Responding - Critical Fix

## Problem Identified

**Root Cause:** The backend at `https://api.engarde.media` is **not responding** to requests.

**Evidence:**
- `curl` to backend times out after 10 seconds
- Frontend API client times out after 30 seconds
- Backend health endpoint not accessible

## Immediate Actions Required

### Step 1: Check Railway Backend Status

**Via Railway Dashboard:**
1. Go to [Railway Dashboard](https://railway.app)
2. Select your backend service
3. Check status:
   - 🟢 **Active** = Running (but may be sleeping)
   - 🟡 **Sleeping** = Inactive (free tier)
   - 🔴 **Failed** = Error

**Via Railway CLI:**
```bash
railway status
railway logs --tail 50
```

### Step 2: Wake Up Backend (If Sleeping)

**If backend is sleeping:**
1. Use UptimeRobot (if set up) to ping `/health` endpoint
2. Or manually wake it up:
   ```bash
   curl https://api.engarde.media/health
   ```
3. Wait 30-60 seconds for cold start
4. Try again

### Step 3: Check Railway Logs

**Look for:**
- Startup errors
- Health check failures
- Worker timeout errors
- Database connection errors

```bash
railway logs --follow
```

### Step 4: Verify Backend URL

**Check Railway deployment:**
1. Railway Dashboard → Service → Settings
2. Verify **Public Domain** is set correctly
3. Should be: `api.engarde.media` or similar

**Check DNS:**
```bash
# Verify DNS resolution
nslookup api.engarde.media
dig api.engarde.media

# Should resolve to Railway IP
```

### Step 5: Test Backend Directly

**Health Check:**
```bash
curl -v https://api.engarde.media/health --max-time 10
```

**Expected:** `{"status":"healthy",...}` in < 5 seconds

**If timeout:**
- Backend is not running or not accessible
- Check Railway deployment status
- Check Railway logs for errors

## Common Issues & Solutions

### Issue 1: Backend Sleeping (Free Tier)

**Symptom:** First request times out, subsequent requests work
**Fix:** 
- Set up UptimeRobot monitoring (see `RAILWAY_SLEEP_DIAGNOSIS.md`)
- Or upgrade to Railway Pro for "Always On"

### Issue 2: Backend Crashed

**Symptom:** Railway shows "Failed" status
**Fix:**
1. Check Railway logs for errors
2. Fix the error (worker timeout, database connection, etc.)
3. Redeploy

### Issue 3: Wrong Backend URL

**Symptom:** DNS resolution fails or wrong IP
**Fix:**
1. Check Railway public domain
2. Update DNS records if needed
3. Update Vercel `BACKEND_URL` environment variable

### Issue 4: Backend Health Check Failing

**Symptom:** Backend starts but health checks fail
**Fix:**
1. Check `/health` endpoint exists and works
2. Check health check timeout in `railway.toml`
3. Increase timeout if startup is slow

## Quick Fix Checklist

- [ ] **Check Railway Status:**
  - Dashboard shows "Active" (not "Sleeping" or "Failed")
  - Logs show no errors

- [ ] **Wake Backend (if sleeping):**
  - Ping `/health` endpoint
  - Wait 30-60 seconds
  - Test again

- [ ] **Verify Backend URL:**
  - Railway public domain is correct
  - DNS resolves correctly
  - Vercel `BACKEND_URL` matches Railway URL

- [ ] **Test Backend:**
  - `curl https://api.engarde.media/health` returns 200 OK
  - Response time < 5 seconds

- [ ] **Check Logs:**
  - No startup errors
  - No worker timeout errors
  - No database connection errors

## Expected Behavior After Fix

**Backend Health Check:**
```bash
$ curl https://api.engarde.media/health
{"status":"healthy","timestamp":"2025-01-XX...","version":"1.0.0","uptime_seconds":1234}
```

**Frontend Login:**
- ✅ No timeout errors
- ✅ Login succeeds in < 5 seconds
- ✅ Authentication works

## Next Steps

1. **Immediate:** Check Railway backend status
2. **If sleeping:** Wake it up (UptimeRobot or manual ping)
3. **If crashed:** Check logs and fix errors
4. **If wrong URL:** Update Railway/Vercel configuration
5. **Test:** Verify backend responds to health checks
6. **Verify:** Test frontend login again

---

**Priority:** 🔴 Critical - Backend must be accessible for frontend to work  
**Estimated Fix Time:** 5-15 minutes depending on issue
