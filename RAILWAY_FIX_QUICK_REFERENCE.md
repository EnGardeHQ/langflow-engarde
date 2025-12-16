# Railway Worker Timeout - Quick Reference

## Problem Diagnosis

**NOT Sleeping - It's a Crash Loop!**

```
Worker starts → Loads 69 routers → Times out at 30s → SIGABRT killed → New worker starts → Repeat
```

## Root Cause

1. **Timeout**: Gunicorn default 30s < Actual startup time (~60-120s)
2. **Blocking Startup**: All 69 routers loading synchronously
3. **Health Check Fail**: Railway health checks timeout before worker ready

## Quick Fix (5 Minutes)

### Minimum Changes Required

1. **Create gunicorn.conf.py**:
```python
timeout = 300  # 5 minutes
worker_class = 'uvicorn.workers.UvicornWorker'
bind = "0.0.0.0:8000"
```

2. **Update Railway Environment Variables**:
```bash
GUNICORN_TIMEOUT=300
WEB_CONCURRENCY=4
```

3. **Create railway.json**:
```json
{
  "deploy": {
    "healthcheckTimeout": 300,
    "healthcheckPath": "/health"
  }
}
```

4. **Deploy**:
```bash
git add gunicorn.conf.py railway.json
git commit -m "Fix worker timeout"
git push
```

## Optimal Fix (30 Minutes)

Implement deferred router loading for faster startup:

1. Copy files created:
   - `/Users/cope/EnGardeHQ/gunicorn.conf.py`
   - `/Users/cope/EnGardeHQ/app/core/startup_optimizer.py`
   - `/Users/cope/EnGardeHQ/app/main_optimized.py`
   - `/Users/cope/EnGardeHQ/railway.json`
   - `/Users/cope/EnGardeHQ/Dockerfile.optimized`

2. Classify routers (in `app/main_optimized.py`):
   - **Critical**: Health, Auth (2-3 routers)
   - **Deferred**: Everything else (66 routers)

3. Set environment variables in Railway:
```bash
ENABLE_DEFERRED_LOADING=true
GUNICORN_TIMEOUT=300
WEB_CONCURRENCY=4
DB_POOL_SIZE=20
```

4. Deploy and verify:
```bash
curl https://your-app.railway.app/health
# Should return quickly: {"status": "healthy"}
```

## Expected Results

### Before Fix
```
Startup time: 60-120s → Worker timeout at 30s → CRASH
Health check: FAIL
Status: Crash loop (container stops)
```

### After Quick Fix
```
Startup time: 60-120s → Worker ready (300s timeout)
Health check: PASS (after 60-120s)
Status: Running (all routers loaded)
```

### After Optimal Fix
```
Startup time: 5-10s → Worker ready
Health check: PASS (after 5-10s)
Background: Remaining routers load in 30-60s
Status: Running (fast startup, full features)
```

## Verification Commands

```bash
# Check Railway logs
railway logs -f

# Look for these messages:
# ✅ "Server is ready. Listening on: 0.0.0.0:8000"
# ✅ "Completed: Loading X critical routers in Y.Ys"
# ❌ "WORKER TIMEOUT (pid:XXX)" - Bad!
# ❌ "Worker was sent SIGABRT" - Bad!

# Test health endpoint
curl https://your-app.railway.app/health

# Check detailed metrics
curl https://your-app.railway.app/health/detailed
```

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Still timing out | Too many critical routers | Reduce to 2-3 critical routers only |
| Database errors | Connection pool too large | Set `DB_POOL_SIZE=10` |
| High memory | Too many workers | Set `WEB_CONCURRENCY=2` |
| Slow background load | Import errors | Check logs for specific router failures |

## File Locations

All generated files are in `/Users/cope/EnGardeHQ/`:

- `gunicorn.conf.py` - Gunicorn configuration with timeout
- `railway.json` - Railway deployment settings
- `app/core/startup_optimizer.py` - Deferred loading system
- `app/core/database_optimized.py` - Database connection pooling
- `app/core/monitoring.py` - Health checks and metrics
- `app/main_optimized.py` - Example optimized main.py
- `Dockerfile.optimized` - Multi-stage Docker build
- `.env.railway.template` - Environment variable template
- `RAILWAY_DEPLOYMENT_FIX_GUIDE.md` - Complete documentation

## Key Metrics

**Critical Thresholds**:
- Gunicorn timeout: **300s** (5 min safety buffer)
- Railway health timeout: **300s** (must match)
- Worker count: **2-4** (depends on plan)
- Database pool: **20+10** overflow (30 max per worker)
- Critical routers: **2-3** only
- Deferred routers: **Everything else**

**Target Performance**:
- Health check response: **< 1s**
- Critical routers loaded: **< 10s**
- Full application ready: **< 70s**
- Worker restarts: **0** (no crashes)

## Railway-Specific Notes

**Hobby Plan** (512MB RAM):
```bash
WEB_CONCURRENCY=2
DB_POOL_SIZE=10
```

**Pro Plan** (8GB RAM):
```bash
WEB_CONCURRENCY=4
DB_POOL_SIZE=20
```

**Health Check Settings**:
- Path: `/health`
- Timeout: `300` seconds
- Start period: `60` seconds (Docker only)
- Retries: `3`

## Prevention Checklist

Future deployments should:
- [ ] Always set explicit `GUNICORN_TIMEOUT`
- [ ] Match Railway `healthcheckTimeout` to Gunicorn timeout
- [ ] Use deferred loading for non-critical routes
- [ ] Monitor startup time in logs
- [ ] Keep critical routers count low (2-3)
- [ ] Test locally before deploying: `gunicorn app.main:app -c gunicorn.conf.py`
- [ ] Set up alerts for worker timeouts

## Support

- Full guide: `RAILWAY_DEPLOYMENT_FIX_GUIDE.md`
- Railway logs: `railway logs -f`
- Railway docs: https://docs.railway.app/

---

**TL;DR**: Workers timeout because 69 routers take >30s to load. Fix: Increase timeout to 300s OR use deferred loading to load only 2-3 critical routers immediately.
