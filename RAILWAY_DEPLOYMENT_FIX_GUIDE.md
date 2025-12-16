# Railway Deployment Fix Guide

## Problem Summary

Your Railway deployment was experiencing a **crash loop due to worker timeouts**, NOT actual "sleeping" behavior. The root causes were:

1. **Worker Timeout**: Gunicorn's default 30-second timeout was insufficient for loading 69 routers + database connections
2. **Heavy Startup**: All routers were loading synchronously before the worker signaled "ready"
3. **Health Check Failures**: Railway's health checks failed because workers never completed initialization
4. **Crash Loop**: Workers continuously timed out ’ got killed ’ restarted ’ timed out again

## Solution Overview

The fix implements a multi-layered approach:

1. **Increased Gunicorn Timeout**: 30s ’ 300s (5 minutes) to allow startup completion
2. **Deferred Router Loading**: Only critical routers load immediately; remaining routers load in background
3. **Database Connection Optimization**: Better connection pooling and health checks
4. **Fast Health Checks**: Lightweight `/health` endpoint responds immediately
5. **Monitoring**: Detailed metrics to track performance and catch issues early

## Implementation Steps

### Step 1: Update Gunicorn Configuration

Replace your current startup command with:

```bash
gunicorn app.main:app -c gunicorn.conf.py
```

The `gunicorn.conf.py` file (created above) includes:
- **timeout = 300**: 5-minute worker initialization timeout
- **graceful_timeout = 30**: Clean shutdown time
- **Worker hooks**: Logging for debugging timeout issues

### Step 2: Implement Optimized Application Startup

Replace your current `app/main.py` with the optimized version:

```python
# Use the app/main_optimized.py as your new main.py
# OR adapt your existing main.py to use the startup_optimizer module
```

Key changes:
1. **Router Registry**: Separate critical vs. deferred routers
2. **Lifespan Context**: Modern FastAPI startup/shutdown using `@asynccontextmanager`
3. **Background Loading**: Non-critical routers load after the app is "ready"

### Step 3: Configure Router Priority

Update your router registration to classify routers:

```python
# CRITICAL ROUTERS - Must load immediately (< 3-5 routers)
critical_routers = [
    ("app.api.routes.health.router", "/health", ["health"]),
    ("app.api.routes.auth.router", "/api/auth", ["authentication"]),
    # Only include routes needed for health checks + core functionality
]

# DEFERRED ROUTERS - Load in background after startup
deferred_routers = [
    ("app.api.routes.videos.router", "/api/videos", ["videos"]),
    ("app.api.routes.analysis.router", "/api/analysis", ["analysis"]),
    # All other routes go here
]
```

**Rule of thumb**: Only mark routes as "critical" if they're needed for health checks or authentication. Everything else can be deferred.

### Step 4: Update Railway Configuration

Create `railway.json` in your project root with the configuration provided above. This sets:
- **healthcheckPath**: `/health` endpoint
- **healthcheckTimeout**: 300 seconds (matches Gunicorn timeout)
- **restartPolicyMaxRetries**: 3 attempts before giving up

### Step 5: Set Environment Variables in Railway

Add these variables in Railway dashboard:

```bash
# Critical settings
GUNICORN_TIMEOUT=300
WEB_CONCURRENCY=4  # Adjust based on your Railway plan

# Database connection pool
DB_POOL_SIZE=20
DB_MAX_OVERFLOW=10

# Feature flags
ENABLE_DEFERRED_LOADING=true

# Transformers cache (if using ML features)
TRANSFORMERS_CACHE=/tmp/transformers_cache
HF_HOME=/tmp/huggingface_cache
TOKENIZERS_PARALLELISM=false
```

### Step 6: Optimize Dockerfile (Optional but Recommended)

Replace your current Dockerfile with `Dockerfile.optimized`:

```bash
# Rename in your Railway build settings
mv Dockerfile Dockerfile.old
mv Dockerfile.optimized Dockerfile
```

Benefits:
- Multi-stage build reduces image size
- Better layer caching speeds up deployments
- Non-root user improves security
- Built-in health check

### Step 7: Deploy and Monitor

1. **Commit changes**:
   ```bash
   git add .
   git commit -m "Fix worker timeout with deferred router loading"
   git push origin main
   ```

2. **Monitor deployment** in Railway logs. You should see:
   ```
   Starting: Health check warmup
   Completed: Health check warmup in 0.10s
   Starting: Database connection pool initialization
   Completed: Database connection pool initialization in 1.20s
   Starting: Loading 3 critical routers
   Completed: Loading 3 critical routers in 2.50s
   Server is ready. Listening on: 0.0.0.0:8000
   [Background] Starting: Loading 66 deferred routers
   ```

3. **Verify health check**:
   ```bash
   curl https://your-app.railway.app/health
   # Should return: {"status": "healthy", "critical_routers_loaded": true}
   ```

## Monitoring and Troubleshooting

### Check Startup Performance

Access the detailed health endpoint:

```bash
curl https://your-app.railway.app/health/detailed
```

This returns:
- System metrics (CPU, memory, disk)
- Database pool stats
- Worker metrics
- Router loading status

### Common Issues

#### Issue 1: Still Timing Out

**Symptoms**: Workers still timeout even with 300s limit

**Solutions**:
1. Reduce number of critical routers (only keep 2-3 essential ones)
2. Increase timeout further: `GUNICORN_TIMEOUT=600` (10 minutes)
3. Check database connection - may be slow to establish
4. Disable ML features temporarily: `ENABLE_ML_FEATURES=false`

#### Issue 2: Database Connection Errors

**Symptoms**: `connection refused` or `too many connections`

**Solutions**:
1. Reduce pool size: `DB_POOL_SIZE=10`
2. Check Railway Postgres connection limit
3. Verify `DATABASE_URL` environment variable is set
4. Enable connection pre-ping: Already enabled in `database_optimized.py`

#### Issue 3: High Memory Usage

**Symptoms**: Workers crash with OOM (out of memory)

**Solutions**:
1. Reduce worker count: `WEB_CONCURRENCY=2`
2. Disable preload: `preload_app = False` (already set)
3. Reduce database pool: `DB_POOL_SIZE=5`
4. Use smaller ML models or disable: `ENABLE_ML_FEATURES=false`

#### Issue 4: Deferred Routers Not Loading

**Symptoms**: Background task fails to load routers

**Solutions**:
1. Check logs for import errors
2. Make router paths optional - don't raise on import failure
3. Increase background task delay: Change `await asyncio.sleep(5)` to `await asyncio.sleep(10)`

### Performance Benchmarks

Expected startup times with optimization:

| Phase                     | Time    | Notes                          |
|---------------------------|---------|--------------------------------|
| Health warmup             | < 1s    | Minimal initialization         |
| Database connection       | 1-3s    | Depends on Railway region      |
| Critical routers (3)      | 2-5s    | Only essential routes          |
| **Total to "ready"**      | **5-10s** | Worker accepts traffic       |
| Deferred routers (66)     | 30-60s  | Loads in background            |
| **Total to fully loaded** | **35-70s** | All features available      |

### Railway-Specific Considerations

1. **Resource Limits**:
   - **Hobby Plan**: 512MB RAM, 0.5 vCPU ’ Use `WEB_CONCURRENCY=2`
   - **Pro Plan**: 8GB RAM, 8 vCPU ’ Use `WEB_CONCURRENCY=4-8`

2. **Health Check Grace Period**:
   - Railway allows ~5 minutes for health checks to pass
   - Our 300s timeout fits within this window

3. **Connection Limits**:
   - Railway Postgres: 100 connections (hobby), 400 (pro)
   - Our pool: 20 + 10 overflow = 30 max per worker
   - With 4 workers: 120 total connections (fits within limits)

## Migration Checklist

- [ ] Create `gunicorn.conf.py` with timeout configuration
- [ ] Update `app/main.py` to use deferred loading
- [ ] Classify routers as critical vs. deferred
- [ ] Add environment variables to Railway
- [ ] Update Dockerfile (optional)
- [ ] Create `railway.json` configuration
- [ ] Test locally: `gunicorn app.main:app -c gunicorn.conf.py`
- [ ] Deploy to Railway
- [ ] Monitor logs for successful startup
- [ ] Verify `/health` endpoint responds quickly
- [ ] Check `/health/detailed` for metrics
- [ ] Test critical endpoints (auth, etc.)
- [ ] Wait for deferred routers to load
- [ ] Test deferred endpoints
- [ ] Set up monitoring alerts (Sentry, etc.)

## Rollback Plan

If issues occur:

1. **Revert to previous deployment**:
   ```bash
   railway rollback
   ```

2. **Quick fix - Just increase timeout**:
   ```bash
   # In Railway dashboard, add environment variable:
   GUNICORN_TIMEOUT=600
   ```

3. **Disable deferred loading**:
   ```bash
   # In Railway dashboard:
   ENABLE_DEFERRED_LOADING=false
   # This loads all routers immediately (slower but safer)
   ```

## Long-term Recommendations

1. **Router Consolidation**: Consider merging similar routers to reduce total count
2. **Lazy Imports**: Use `importlib` for heavy dependencies
3. **Model Preloading**: Cache ML models in shared volume (Railway persistent storage)
4. **Horizontal Scaling**: Add more instances instead of more workers per instance
5. **Database Optimization**: Add indexes, optimize queries
6. **Caching Layer**: Add Redis for frequently accessed data
7. **CDN**: Use Railway's CDN for static assets

## Support and Resources

- **Railway Docs**: https://docs.railway.app/
- **Gunicorn Docs**: https://docs.gunicorn.org/
- **FastAPI Performance**: https://fastapi.tiangolo.com/deployment/
- **This project's logs**: `railway logs -f`

## Questions?

Common questions and answers:

**Q: Why 300 seconds instead of just 60?**
A: Loading 69 routers + database + ML libraries can easily take 60-120 seconds. 300s provides a safe buffer.

**Q: Will deferred loading break my API?**
A: No - deferred routers load within 30-60 seconds. If a request comes in before loading, it will wait (blocking) until that specific router is loaded.

**Q: Can I increase workers to speed up startup?**
A: No - more workers won't speed up startup; each worker loads independently. Reduce routers or use deferred loading instead.

**Q: What if I can't modify the application code?**
A: Minimum fix: Just add `gunicorn.conf.py` with `timeout=600` and update Railway's `healthcheckTimeout=600`.

---

**Author**: DevOps Orchestrator
**Date**: 2025-11-17
**Version**: 1.0
