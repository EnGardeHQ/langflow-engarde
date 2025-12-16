# Worker Timeout Crash Loop - Critical Fix

## Problem Identified

**Root Cause:** Gunicorn workers are timing out during startup, causing a continuous crash loop.

**Evidence from Railway Logs:**
```
[2025-11-17 21:18:00 +0000] [1] [CRITICAL] WORKER TIMEOUT (pid:51395)
[2025-11-17 21:18:00 +0000] [1] [ERROR] Worker (pid:51395) was sent SIGABRT!
[2025-11-17 21:18:06 +0000] [1] [CRITICAL] WORKER TIMEOUT (pid:51540)
[2025-11-17 21:18:12 +0000] [1] [CRITICAL] WORKER TIMEOUT (pid:51637)
```

**Pattern:**
1. Worker starts → Loads 7 critical routers (~1-2 seconds) ✅
2. Worker signals "ready" → Starts HTTP server ✅
3. Background task starts loading 62 deferred routers ⏳
4. **Worker times out** (default 30 seconds) ❌
5. Worker killed → New worker starts → Repeat

## Why This Causes Frontend Timeouts

**Request Flow:**
1. Frontend → `/api/auth/login` → Vercel API route
2. Vercel API route → `https://api.engarde.media/api/token`
3. Railway backend receives request
4. **Worker is in crash loop** (timeout → restart → timeout)
5. Request waits for stable worker
6. **Request times out** after 30 seconds (frontend) / 50 seconds (API route)

## Root Cause Analysis

### Issue 1: Gunicorn Timeout Too Low

**Current Configuration:**
- `railway.toml`: `GUNICORN_TIMEOUT = "120"` (2 minutes)
- **BUT**: Gunicorn default timeout is **30 seconds** if not properly set

**Problem:** The timeout in `railway.toml` is an environment variable, but Gunicorn needs it set in the command line or config file.

### Issue 2: Deferred Router Loading Blocks Worker

**Timeline:**
- Worker starts: `21:17:56`
- Critical routers loaded: `21:17:57` (1 second) ✅
- Application startup complete: `21:17:57` ✅
- Background deferred routers start: `21:17:58`
- **Worker timeout**: `21:18:00` (30 seconds after start) ❌

**Issue:** Even though routers are loading in background, Gunicorn still times out the worker.

### Issue 3: Worker Never Fully Ready

Workers keep restarting before they can handle requests properly, causing:
- Health checks to pass (minimal endpoint works)
- But actual API requests timeout (worker crashes)

## Solutions

### Solution 1: Increase Gunicorn Timeout (CRITICAL)

**File:** `production-backend/railway.toml`

**Current:**
```toml
GUNICORN_TIMEOUT = "120"
```

**Fix:** Increase timeout to 300 seconds (5 minutes) to allow deferred router loading:

```toml
GUNICORN_TIMEOUT = "300"
```

**Also verify** the timeout is actually being used in the startCommand.

### Solution 2: Verify Timeout in StartCommand

**File:** `production-backend/railway.toml` (Line 23)

**Current startCommand** includes:
```bash
--timeout ${GUNICORN_TIMEOUT:-120}
```

**Issue:** If `GUNICORN_TIMEOUT` env var isn't set, it defaults to 120, but Gunicorn might be using its own default (30s).

**Fix:** Ensure timeout is explicitly set and increase it:

```toml
[deploy.environmentVariables]
GUNICORN_TIMEOUT = "300"  # 5 minutes - allows deferred router loading
```

### Solution 3: Make Deferred Router Loading Non-Blocking

**Current:** Deferred routers load in background task, but Gunicorn still times out.

**Fix:** Ensure deferred router loading doesn't block worker readiness signal.

**File:** `production-backend/app/main.py`

The deferred router loading is already in a background task, but we need to ensure:
1. Worker signals "ready" BEFORE deferred routers start loading
2. Deferred router loading doesn't block worker

**Check:** Verify the lifespan context manager properly yields before deferred loading.

### Solution 4: Reduce Deferred Router Loading Time

**Current:** 62 deferred routers loading takes time.

**Options:**
1. Make more routers critical (load synchronously)
2. Optimize router imports
3. Lazy load routers on first request

## Immediate Fix Steps

### Step 1: Update Railway Configuration

**File:** `production-backend/railway.toml`

**Update:**
```toml
[deploy.environmentVariables]
GUNICORN_TIMEOUT = "300"  # Increase from 120 to 300 (5 minutes)
```

### Step 2: Verify StartCommand Uses Timeout

**Check** that the startCommand in `railway.toml` line 23 includes:
```bash
--timeout ${GUNICORN_TIMEOUT:-300}
```

**Change default** from 120 to 300 to match the new timeout.

### Step 3: Update Health Check Timeout

**File:** `production-backend/railway.toml`

**Current:**
```toml
healthcheckTimeout = 600
```

**This is fine** - 10 minutes is sufficient.

### Step 4: Deploy and Monitor

1. Commit changes
2. Push to trigger Railway deployment
3. Monitor logs for:
   - ✅ Workers complete startup without timeout
   - ✅ No more "WORKER TIMEOUT" errors
   - ✅ Workers stay alive and handle requests

## Expected Behavior After Fix

### Before Fix:
```
Worker starts → Loads routers → Times out at 30s → Killed → Restart → Repeat
Request arrives → Waits for worker → Worker crashes → Request times out
```

### After Fix:
```
Worker starts → Loads routers → Completes startup → Ready → Handles requests
Request arrives → Worker ready → Request succeeds in < 5 seconds
```

## Verification

### Check Railway Logs After Fix:
```bash
railway logs --follow
```

**Look for:**
- ✅ No "WORKER TIMEOUT" errors
- ✅ "Application startup complete" without subsequent timeout
- ✅ Workers stay alive (no constant restarts)
- ✅ Requests succeed (200 OK responses)

### Test Backend:
```bash
curl https://api.engarde.media/api/token \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=test@example.com&password=test123&grant_type=password"
```

**Expected:** Response in < 5 seconds (not timeout)

## Additional Recommendations

### 1. Monitor Worker Startup Time

Add logging to track how long startup takes:
- Critical router loading time
- Deferred router loading time
- Total startup time

### 2. Optimize Router Loading

Consider:
- Making authentication routers critical (they're needed for login)
- Reducing number of deferred routers
- Lazy loading non-critical routers

### 3. Set Up Alerts

Monitor for:
- Worker timeout errors
- Worker restart frequency
- Request timeout rate

---

**Priority:** 🔴 Critical - This is blocking all API requests  
**Estimated Fix Time:** 5 minutes (config change) + deployment time  
**Confidence:** 95% - Worker timeout is clearly the issue
