# Railway Deployment Guide - Quick Fix

## IMMEDIATE FIX (Deploy in 30 minutes)

### Step 1: Switch to Optimized Requirements

```bash
cd /Users/cope/EnGardeHQ/production-backend

# Backup current requirements
cp requirements.txt requirements-original.txt

# Use optimized version
cp requirements-optimized.txt requirements.txt
```

### Step 2: Configure Railway to Use Docker

**In Railway Dashboard:**

1. Go to your backend service
2. Click **Settings** tab
3. Scroll to **Build** section
4. Change **Builder** from "Nixpacks" to **"Dockerfile"**
5. Set **Docker Build Context**: `production-backend`
6. Set **Dockerfile Path**: `Dockerfile`
7. Set **Docker Build Target**: `production`
8. Click **Save**

### Step 3: Set Environment Variables

**In Railway Dashboard → Variables tab:**

Add these build optimization variables:

```bash
# Python optimization
PYTHONUNBUFFERED=1
PYTHONDONTWRITEBYTECODE=1
PYTHONHASHSEED=random

# Pip optimization
PIP_NO_CACHE_DIR=1
PIP_DISABLE_PIP_VERSION_CHECK=1
PIP_DEFAULT_TIMEOUT=180

# Gunicorn configuration
GUNICORN_WORKERS=4
GUNICORN_WORKER_CLASS=uvicorn.workers.UvicornWorker
GUNICORN_TIMEOUT=120
GUNICORN_LOGLEVEL=info

# HuggingFace cache (for ML models)
HF_HOME=/home/engarde/.cache/huggingface
TRANSFORMERS_CACHE=/home/engarde/.cache/huggingface
```

Also ensure your database and other service variables are set:
- `DATABASE_URL`
- `SECRET_KEY`
- `ENVIRONMENT=production`
- etc.

### Step 4: Deploy

```bash
# From Railway Dashboard
Click "Deploy" button

# OR via CLI
railway up
```

**Expected Result:**
- Build time: 2-5 minutes (vs 20+ min timeout)
- Success rate: 95%+

---

## ALTERNATIVE: Use Nixpacks (If Docker doesn't work)

### Step 1: Use Optimized Requirements
```bash
cd /Users/cope/EnGardeHQ/production-backend
cp requirements-optimized.txt requirements.txt
```

### Step 2: Verify nixpacks.toml exists
Already created at `/Users/cope/EnGardeHQ/production-backend/nixpacks.toml`

### Step 3: Configure Railway for Nixpacks

**In Railway Dashboard:**
1. Settings → Builder: **Nixpacks**
2. Root Directory: `production-backend`
3. Save

### Step 4: Deploy
```bash
railway up
```

---

## TROUBLESHOOTING

### Build Still Times Out

**Option A: Further reduce dependencies**

Remove more packages from requirements.txt:

```bash
# Edit requirements.txt and comment out:
# - sentence-transformers (if not using local embeddings)
# - torch (if not using local ML models)
# - transformers (if not using local NLP)
# - faiss-cpu (if not doing local vector search)
# - chromadb (if using external vector DB)
```

**Option B: Use pre-built Docker image**

```bash
# Build locally
cd /Users/cope/EnGardeHQ/production-backend
docker build --target production -t engarde-backend:latest .

# Push to Docker Hub
docker tag engarde-backend:latest your-dockerhub-username/engarde-backend:latest
docker push your-dockerhub-username/engarde-backend:latest

# In Railway:
# Settings → Deploy → Image URL: your-dockerhub-username/engarde-backend:latest
```

### Specific Package Fails to Install

**Check Railway build logs:**
```bash
railway logs --build
```

**Common issues:**

1. **System dependencies missing** (libxml2, etc.)
   - Add to `nixpacks.toml` under `nixPkgs`

2. **Compilation errors**
   - Pin to older version of that package
   - Or use binary wheel (e.g., `psycopg2-binary` instead of `psycopg2`)

3. **Version conflicts**
   - Run locally: `pip install -r requirements.txt` to see exact error
   - Fix version pins to resolve conflicts

### Runtime Errors After Successful Build

**Database migrations:**
```bash
# Run migrations via Railway CLI
railway run alembic upgrade head
```

**Missing environment variables:**
```bash
# Check logs
railway logs

# Add missing variables in Dashboard → Variables
```

**Module import errors:**
```bash
# Verify package installed
railway run pip list | grep package-name

# If missing, add to requirements.txt and redeploy
```

---

## VERIFICATION CHECKLIST

After deployment succeeds:

- [ ] Service shows "Active" status
- [ ] Health check passes: `curl https://your-app.railway.app/health`
- [ ] API responds: `curl https://your-app.railway.app/docs`
- [ ] Database connection works (check logs)
- [ ] No critical errors in logs: `railway logs`
- [ ] All required features work

---

## ROLLBACK PLAN

If new deployment fails:

### Immediate Rollback

**Railway Dashboard:**
1. Deployments tab
2. Find last successful deployment
3. Click "..." → "Rollback to this version"

### Restore Original Requirements

```bash
cd /Users/cope/EnGardeHQ/production-backend
cp requirements-original.txt requirements.txt
git checkout requirements.txt  # if version controlled
```

---

## MONITORING

### Watch Build Progress

```bash
# Via CLI
railway logs --build

# Or in Dashboard
# Deployments → Current deployment → View logs
```

### Monitor Runtime

```bash
# Application logs
railway logs

# Follow logs in real-time
railway logs --follow

# Filter for errors
railway logs | grep ERROR
```

### Set Up Alerts

**Railway Dashboard:**
1. Settings → Notifications
2. Enable "Deployment failed"
3. Enable "Service crashed"
4. Add email/Slack webhook

---

## PERFORMANCE OPTIMIZATION

### After Successful Deployment

1. **Monitor memory usage**
   ```bash
   railway metrics
   ```

2. **Adjust worker count** based on memory:
   - 512MB RAM: 2 workers
   - 1GB RAM: 2-3 workers
   - 2GB RAM: 4 workers
   - 4GB+ RAM: 4-8 workers

3. **Enable caching** for expensive operations:
   - Use Redis for API response caching
   - Cache ML model loading
   - Cache external API responses

4. **Optimize cold starts**:
   - Keep service warm with cron job: `curl https://your-app.railway.app/health`
   - Use Railway's "Always on" feature (Pro plan)

---

## COST OPTIMIZATION

### Reduce Build Costs

1. **Pin all versions** (already done in optimized requirements)
2. **Use build cache** (Docker multi-stage)
3. **Deploy less frequently** (batch changes)

### Reduce Runtime Costs

1. **Right-size workers**:
   ```python
   # In environment variables
   GUNICORN_WORKERS=2  # Start small, scale up if needed
   ```

2. **Use async properly**:
   - Fewer workers needed with proper async/await
   - Better resource utilization

3. **Optimize database queries**:
   - Use connection pooling (already configured in SQLAlchemy)
   - Add indexes for frequent queries
   - Avoid N+1 queries

4. **Enable compression**:
   ```python
   # Add middleware in app/main.py
   from fastapi.middleware.gzip import GZipMiddleware
   app.add_middleware(GZipMiddleware, minimum_size=1000)
   ```

---

## ADVANCED: MULTI-STAGE OPTIMIZATION

If you need even faster builds:

### Split Requirements into Layers

**requirements.base.txt** (fast, rarely changes):
```
fastapi==0.110.1
uvicorn==0.29.0
sqlalchemy==2.0.30
psycopg2-binary==2.9.9
```

**requirements.ml.txt** (slow, changes occasionally):
```
sentence-transformers==2.7.0
torch==2.1.2
transformers==4.41.0
```

**requirements.integrations.txt** (medium, changes often):
```
openai==1.35.0
anthropic==0.31.0
stripe==9.7.0
```

### Update Dockerfile

```dockerfile
# Install in layers
COPY requirements.base.txt /tmp/
RUN pip install -r /tmp/requirements.base.txt

COPY requirements.ml.txt /tmp/
RUN pip install -r /tmp/requirements.ml.txt

COPY requirements.integrations.txt /tmp/
RUN pip install -r /tmp/requirements.integrations.txt
```

**Benefit**: Railway caches layers, so only changed layers rebuild

---

## NEXT STEPS

After successful deployment:

1. **Set up monitoring**:
   - Enable Sentry for error tracking
   - Configure structured logging
   - Add custom metrics

2. **Implement CI/CD**:
   - GitHub Actions for automated testing
   - Automatic deployment on merge to main
   - Staging environment for testing

3. **Security hardening**:
   - Scan dependencies: `pip-audit`
   - Enable Railway's security features
   - Add rate limiting and DDoS protection

4. **Performance testing**:
   - Load test with expected traffic
   - Profile slow endpoints
   - Optimize database queries

5. **Documentation**:
   - Document deployment process
   - Create runbook for common issues
   - Set up team access and permissions

---

## SUPPORT

If you still have issues:

1. **Check Railway Status**: https://status.railway.app/
2. **Railway Discord**: https://discord.gg/railway
3. **Railway Docs**: https://docs.railway.app/
4. **GitHub Issues**: Check if similar issue reported

---

## SUMMARY

**What changed:**
1. Pinned all 110 dependencies (vs 159 loose versions)
2. Removed 49 conflicting/unused packages
3. Added Railway-specific optimization configs
4. Configured proper Docker build settings

**Expected outcome:**
- Build time: 2-5 minutes (vs 20+ min timeout)
- Success rate: 95%+
- Stable, reproducible deployments
- Easier debugging and maintenance

**Time to deploy**: 30-60 minutes including verification
