# Railway Deployment Sleep Diagnosis & Prevention Guide

**Date:** 2025-01-XX  
**Status:** Comprehensive Analysis & Solutions  
**Priority:** High - Production Availability

---

## Executive Summary

Railway deployments can appear to "sleep" for multiple reasons. This document diagnoses the root causes and provides comprehensive solutions to prevent sleeping and ensure consistent availability.

### Common Causes of Railway "Sleeping"

1. **Free Tier Inactivity** (Most Common)
   - Services sleep after 5-15 minutes of no traffic
   - First request after sleep takes 30-60 seconds (cold start)
   - Appears as "sleeping" in Railway dashboard

2. **Health Check Failures**
   - Railway marks service as unhealthy
   - Stops routing traffic to the service
   - Service appears inactive/sleeping

3. **Worker Timeout/Crash Loops**
   - Workers timeout during startup
   - Container continuously restarts
   - Railway eventually stops the service

4. **Configuration Issues**
   - Missing or incorrect health check configuration
   - Port mismatches
   - Environment variable issues

---

## Diagnosis: Why Is Your Deployment Sleeping?

### Step 1: Check Railway Dashboard Status

1. Go to [Railway Dashboard](https://railway.app)
2. Navigate to your project → Service
3. Check the **Status** indicator:
   - 🟢 **Active** = Running normally
   - 🟡 **Sleeping** = Inactive (free tier) or unhealthy
   - 🔴 **Failed** = Crash loop or startup failure
   - ⚪ **Stopped** = Manually stopped or deployment failed

### Step 2: Review Recent Logs

```bash
# View recent logs
railway logs --tail 100

# Follow logs in real-time
railway logs --follow

# Check for specific patterns
railway logs | grep -i "error\|timeout\|killed\|sleep"
```

**Look for these patterns:**

#### Pattern A: Free Tier Sleep (Normal)
```
[No recent logs - service is sleeping]
[First request after sleep takes 30-60s]
```

#### Pattern B: Health Check Failures
```
[Railway] Health check failed: connection refused
[Railway] Health check failed: timeout
GET /health → 503 Service Unavailable
```

#### Pattern C: Worker Timeout/Crash Loop
```
[Gunicorn] Worker timeout (pid: 12345)
[Gunicorn] Worker killed (SIGABRT)
[Gunicorn] Booting worker with pid: 12346
[Repeats continuously]
```

#### Pattern D: Startup Issues
```
[ERROR] Failed to connect to database
[ERROR] ModuleNotFoundError: No module named 'X'
[ERROR] Port 8080 already in use
```

### Step 3: Test Health Endpoint

```bash
# Test your health endpoint
curl -v https://your-app.up.railway.app/health

# Expected response:
# HTTP/1.1 200 OK
# {"status":"healthy","timestamp":"...","version":"...","uptime_seconds":...}
```

**If health check fails:**
- Service may be marked as unhealthy
- Railway stops routing traffic
- Service appears to be "sleeping"

### Step 4: Check Railway Configuration

```bash
# View Railway configuration
cat production-backend/railway.toml

# Check for:
# - healthcheckPath = "/health" ✓
# - healthcheckTimeout = 600 ✓
# - PORT = "8080" ✓
```

### Step 5: Verify Environment Variables

In Railway Dashboard → Service → Variables, ensure these are set:

**Critical Variables:**
- `PORT=8080` (must match Railway's expected port)
- `GUNICORN_TIMEOUT=300` (or higher if startup takes longer)
- `GUNICORN_WORKERS=4` (adjust based on memory)

**Health Check Variables:**
- `ENVIRONMENT=production`
- `DEBUG=false`

---

## Root Cause Analysis

### Cause 1: Free Tier Inactivity (Most Likely)

**Symptom:**
- Service shows "Sleeping" status
- First request after inactivity takes 30-60 seconds
- No errors in logs, just inactivity

**Why It Happens:**
- Railway free tier automatically sleeps services after inactivity
- Sleep threshold: ~5-15 minutes of no requests
- This is **normal behavior** for free tier

**Solution:** See "Prevention Strategies" below

### Cause 2: Health Check Failures

**Symptom:**
- Health checks fail repeatedly
- Service marked as unhealthy
- No traffic routed to service

**Why It Happens:**
- Health endpoint (`/health`) not responding
- Health endpoint too slow (>10 seconds)
- Port mismatch (app listening on wrong port)
- Service crashes before health check succeeds

**Diagnosis:**
```bash
# Test health endpoint directly
curl -v -m 10 https://your-app.up.railway.app/health

# Check if service is listening on correct port
railway ssh "netstat -tlnp | grep 8080"
```

**Solution:** Fix health check endpoint (see below)

### Cause 3: Worker Timeout/Crash Loop

**Symptom:**
- Continuous worker restarts
- Workers killed with SIGABRT
- Service never becomes healthy

**Why It Happens:**
- Startup takes longer than Gunicorn timeout (default 30s)
- Heavy router loading (69 routers in your case)
- Database connection delays
- ML library imports taking too long

**Diagnosis:**
```bash
# Check logs for timeout patterns
railway logs | grep -i "timeout\|killed\|SIGABRT"

# Check startup time
railway logs | grep -i "startup\|ready\|listening"
```

**Solution:** Increase Gunicorn timeout (see below)

### Cause 4: Configuration Mismatch

**Symptom:**
- Service starts but health checks fail
- Port binding errors
- Environment variable issues

**Why It Happens:**
- `railway.toml` config not applied
- Railway Dashboard override
- Missing environment variables

**Diagnosis:**
```bash
# Check Railway Dashboard → Service → Settings
# - Start Command should be BLANK (uses railway.toml)
# - Port should match railway.toml PORT variable
# - Health check path should match healthcheckPath
```

**Solution:** Fix configuration (see below)

---

## Solutions: Immediate Fixes

### Fix 1: Prevent Free Tier Sleep (Keep-Alive)

#### Option A: External Monitoring Service (Recommended)

Use a free monitoring service to ping your app every 5 minutes:

**UptimeRobot** (Free):
1. Sign up at https://uptimerobot.com
2. Add monitor:
   - Type: HTTP(s)
   - URL: `https://your-app.up.railway.app/health`
   - Interval: 5 minutes
   - Status: Enabled

**Cron-Job.org** (Free):
1. Sign up at https://cron-job.org
2. Create cron job:
   - URL: `https://your-app.up.railway.app/health`
   - Schedule: `*/5 * * * *` (every 5 minutes)
   - Method: GET

**Better Uptime** (Free):
1. Sign up at https://betteruptime.com
2. Add monitor with 5-minute interval

#### Option B: Railway Cron Service (Self-Hosted)

Create a separate Railway service that pings your main service:

**File: `production-backend/scripts/keep-alive.sh`**
```bash
#!/bin/bash
# Keep-alive script for Railway free tier

APP_URL="${RAILWAY_PUBLIC_DOMAIN:-https://your-app.up.railway.app}"
HEALTH_ENDPOINT="${APP_URL}/health"

echo "[$(date)] Pinging ${HEALTH_ENDPOINT}"

response=$(curl -s -o /dev/null -w "%{http_code}" -m 10 "${HEALTH_ENDPOINT}")

if [ "$response" -eq 200 ]; then
    echo "[$(date)] ✅ Health check passed (HTTP $response)"
    exit 0
else
    echo "[$(date)] ❌ Health check failed (HTTP $response)"
    exit 1
fi
```

**File: `production-backend/railway-cron.toml`**
```toml
[build]
builder = "NIXPACKS"

[deploy]
startCommand = "while true; do curl -s -m 10 ${RAILWAY_PUBLIC_DOMAIN}/health > /dev/null && sleep 300 || sleep 60; done"
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 3

[deploy.environmentVariables]
RAILWAY_PUBLIC_DOMAIN = "https://your-app.up.railway.app"
```

**Deploy as separate service:**
```bash
railway link --service keep-alive
railway up --config railway-cron.toml
```

#### Option C: Upgrade to Railway Pro (Paid)

Railway Pro plan includes "Always On" feature:
- Services never sleep
- No cold starts
- Better performance

**Cost:** ~$20/month per service

### Fix 2: Fix Health Check Endpoint

#### Ensure Health Endpoint Exists

Your app already has a health endpoint at `/health`. Verify it's working:

**File: `production-backend/app/main.py`** (already exists)
```python
@app.get("/health")
async def minimal_health_check():
    """Minimal health check for Railway."""
    uptime = time.time() - _app_start_time
    version = os.getenv("APP_VERSION", "1.0.0")
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "version": version,
        "uptime_seconds": uptime
    }
```

**Verify configuration:**
```toml
# railway.toml
[deploy]
healthcheckPath = "/health"
healthcheckTimeout = 600  # 10 minutes (allows for slow startup)
```

#### Test Health Endpoint

```bash
# Local test
curl http://localhost:8080/health

# Railway test
curl https://your-app.up.railway.app/health

# Expected: {"status":"healthy",...}
```

### Fix 3: Increase Gunicorn Timeout

If workers are timing out during startup:

**Update `railway.toml`:**
```toml
[deploy.environmentVariables]
GUNICORN_TIMEOUT = "300"  # 5 minutes (increase if needed)
```

**Or create `gunicorn.conf.py`:**
```python
# production-backend/gunicorn.conf.py
timeout = 300  # 5 minutes
worker_class = 'uvicorn.workers.UvicornWorker'
bind = "0.0.0.0:8080"
workers = 4
keepalive = 65
max_requests = 1000
max_requests_jitter = 100
```

**Update startCommand in `railway.toml`:**
```toml
startCommand = "gunicorn app.main:app -c gunicorn.conf.py"
```

### Fix 4: Fix Configuration Issues

#### Clear Railway Dashboard Override

1. Go to Railway Dashboard → Service → Settings
2. Find **Start Command** field
3. **DELETE** any custom command (leave blank)
4. Click **Save**
5. Railway will now use `railway.toml` configuration

#### Verify Port Configuration

Ensure port matches Railway's expectation:

```toml
# railway.toml
[deploy.environmentVariables]
PORT = "8080"  # Must match Railway's PORT
```

**Verify in Railway Dashboard:**
- Service → Settings → Port should show 8080
- Or Railway auto-detects from PORT env var

---

## Prevention Strategies

### Strategy 1: Keep-Alive Monitoring (Required for Free Tier)

**Setup external monitoring:**
- ✅ UptimeRobot (free, 5-minute intervals)
- ✅ Cron-Job.org (free, custom schedules)
- ✅ Better Uptime (free tier available)

**Benefits:**
- Prevents free tier sleep
- Monitors service availability
- Alerts on downtime

**Setup Time:** 5 minutes

### Strategy 2: Optimize Startup Time

**Current Issue:** 69 routers loading synchronously takes 60-120 seconds

**Solution:** Deferred router loading

**File: `production-backend/app/core/startup_optimizer.py`** (create if needed)
```python
"""
Startup optimizer for faster Railway deployments.
Loads critical routers immediately, defers others.
"""
import asyncio
from fastapi import FastAPI
from typing import List, Callable

class StartupOptimizer:
    def __init__(self, app: FastAPI):
        self.app = app
        self.critical_routers = []
        self.deferred_routers = []
    
    def register_critical(self, router_func: Callable):
        """Register router that must load immediately."""
        self.critical_routers.append(router_func)
    
    def register_deferred(self, router_func: Callable):
        """Register router that can load after startup."""
        self.deferred_routers.append(router_func)
    
    async def load_critical(self):
        """Load critical routers immediately."""
        for router_func in self.critical_routers:
            router_func(self.app)
    
    async def load_deferred(self):
        """Load deferred routers in background."""
        await asyncio.sleep(1)  # Let app become ready first
        for router_func in self.deferred_routers:
            try:
                router_func(self.app)
            except Exception as e:
                logger.error(f"Failed to load deferred router: {e}")
```

**Benefits:**
- Faster startup (<30 seconds)
- Health endpoint available immediately
- Better Railway health check success rate

### Strategy 3: Health Check Optimization

**Ensure health endpoint is fast:**
- ✅ No database queries (already done)
- ✅ No external API calls
- ✅ Response time <100ms

**Current implementation is good:**
```python
@app.get("/health")
async def minimal_health_check():
    # Fast, no dependencies
    return {"status": "healthy", ...}
```

### Strategy 4: Railway Configuration Best Practices

**File: `production-backend/railway.toml`** (update if needed)
```toml
[deploy]
# Health check configuration
healthcheckPath = "/health"
healthcheckTimeout = 600  # 10 minutes (allows slow startup)

# Restart policy
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 3

# Environment variables
[deploy.environmentVariables]
PORT = "8080"
GUNICORN_TIMEOUT = "300"  # 5 minutes
GUNICORN_WORKERS = "4"
```

**Key Points:**
- ✅ `healthcheckTimeout` should be > startup time
- ✅ `GUNICORN_TIMEOUT` should be > startup time
- ✅ `PORT` must match Railway's port (usually 8080)

### Strategy 5: Monitoring & Alerts

**Set up Railway alerts:**
1. Railway Dashboard → Service → Settings → Notifications
2. Enable:
   - ✅ Deployment failed
   - ✅ Service crashed
   - ✅ Health check failed

**Set up external monitoring:**
- UptimeRobot: Email/SMS alerts
- Better Uptime: Slack/Discord webhooks
- Cron-Job.org: Email notifications

### Strategy 6: Upgrade Considerations

**When to upgrade to Railway Pro:**
- ✅ Production application with users
- ✅ Need guaranteed uptime
- ✅ Want faster response times (no cold starts)
- ✅ Budget allows (~$20/month)

**Benefits:**
- Always-on services (no sleep)
- Better performance
- Priority support
- More resources

---

## Quick Reference: Commands

### Diagnosis Commands

```bash
# Check Railway status
railway status

# View logs
railway logs --tail 100
railway logs --follow

# Test health endpoint
curl -v https://your-app.up.railway.app/health

# SSH into service
railway ssh

# Check environment variables
railway variables
```

### Fix Commands

```bash
# Update Railway configuration
git add railway.toml
git commit -m "Fix Railway sleep prevention"
git push

# Force redeploy
railway up

# Rollback if needed
# Railway Dashboard → Deployments → Rollback
```

### Monitoring Commands

```bash
# Test health endpoint locally
curl http://localhost:8080/health

# Test from Railway
railway ssh "curl -s http://localhost:8080/health"

# Monitor logs for health checks
railway logs | grep -i health
```

---

## Troubleshooting Checklist

### Service Shows "Sleeping"

- [ ] Check if free tier (normal behavior)
- [ ] Set up keep-alive monitoring (UptimeRobot, etc.)
- [ ] Test health endpoint manually
- [ ] Check Railway logs for errors
- [ ] Verify health check configuration

### Health Checks Failing

- [ ] Verify `/health` endpoint exists
- [ ] Test endpoint: `curl https://your-app.up.railway.app/health`
- [ ] Check `healthcheckPath` in `railway.toml`
- [ ] Verify `healthcheckTimeout` is sufficient
- [ ] Check if service is listening on correct port
- [ ] Review logs for startup errors

### Workers Timing Out

- [ ] Check startup time in logs
- [ ] Increase `GUNICORN_TIMEOUT` to 300+ seconds
- [ ] Implement deferred router loading
- [ ] Optimize database connection pooling
- [ ] Reduce number of workers if memory constrained

### Configuration Not Applied

- [ ] Clear Railway Dashboard Start Command override
- [ ] Verify `railway.toml` is in correct location
- [ ] Check if Railway is using correct config file
- [ ] Verify environment variables in Railway Dashboard
- [ ] Force redeploy: `git commit --allow-empty && git push`

---

## Long-Term Prevention Plan

### Phase 1: Immediate (Today)

1. ✅ **Set up keep-alive monitoring**
   - Sign up for UptimeRobot
   - Add monitor for `/health` endpoint
   - Set 5-minute interval

2. ✅ **Verify health check configuration**
   - Test `/health` endpoint
   - Verify `railway.toml` settings
   - Clear Dashboard overrides

3. ✅ **Review logs**
   - Check for errors
   - Verify startup time
   - Identify any issues

### Phase 2: Short-Term (This Week)

1. ✅ **Optimize startup time**
   - Implement deferred router loading
   - Reduce startup dependencies
   - Optimize database connections

2. ✅ **Set up alerts**
   - Railway notifications
   - External monitoring alerts
   - Slack/Discord webhooks

3. ✅ **Document configuration**
   - Update README with Railway setup
   - Document keep-alive requirements
   - Create deployment checklist

### Phase 3: Long-Term (This Month)

1. ✅ **Consider upgrade**
   - Evaluate Railway Pro benefits
   - Compare costs vs. free tier + monitoring
   - Plan migration if needed

2. ✅ **Implement monitoring dashboard**
   - Set up comprehensive monitoring
   - Track uptime metrics
   - Create status page

3. ✅ **Automate prevention**
   - CI/CD health checks
   - Automated testing
   - Deployment validation

---

## Summary

### Most Likely Cause: Free Tier Inactivity

Railway free tier services sleep after inactivity. This is **normal behavior**, not a bug.

### Immediate Solution: Keep-Alive Monitoring

Set up external monitoring (UptimeRobot, Cron-Job.org, etc.) to ping your `/health` endpoint every 5 minutes.

### Long-Term Solution: Upgrade or Optimize

- **Free Tier:** Keep-alive monitoring (free)
- **Pro Tier:** Always-on feature (~$20/month)
- **Optimization:** Faster startup = better health checks

### Key Takeaways

1. ✅ Free tier sleep is normal - use keep-alive monitoring
2. ✅ Health checks must be fast (<100ms) and reliable
3. ✅ Startup time should be <30 seconds for best results
4. ✅ Configuration must match Railway's expectations
5. ✅ Monitoring prevents surprises and ensures availability

---

## Additional Resources

- **Railway Docs:** https://docs.railway.app
- **Railway Discord:** https://discord.gg/railway
- **UptimeRobot:** https://uptimerobot.com
- **Cron-Job.org:** https://cron-job.org
- **Better Uptime:** https://betteruptime.com

---

**Last Updated:** 2025-01-XX  
**Next Review:** After implementing keep-alive monitoring
