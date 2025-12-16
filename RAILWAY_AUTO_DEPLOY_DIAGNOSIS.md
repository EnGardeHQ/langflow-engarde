# Railway Auto-Deploy Diagnosis

## Why Railway May Not Auto-Deploy

Railway auto-deployment depends on several factors. Here's what to check:

---

## 1. Railway GitHub Integration

### Check Railway Dashboard

**Railway auto-deploys when:**
1. ✅ GitHub repository is connected to Railway service
2. ✅ Railway is watching the correct branch (usually `main`)
3. ✅ Railway detects changes in watched files
4. ✅ No deployment errors occur

### Common Issues

#### Issue 1: GitHub Not Connected
**Symptom:** Railway doesn't detect new commits
**Fix:** 
- Go to Railway Dashboard → Your Service → Settings → GitHub
- Ensure repository is connected
- Verify branch is set to `main`

#### Issue 2: Wrong Branch Watched
**Symptom:** Pushes to `main` don't trigger deployment
**Fix:**
- Railway Dashboard → Service → Settings → Source
- Verify "Branch" is set to `main` (not `master` or other)

#### Issue 3: Railway Service Paused/Stopped
**Symptom:** No deployments happening at all
**Fix:**
- Railway Dashboard → Service → Check if service is paused
- Unpause if needed

---

## 2. Railway Configuration Files

### Current Configuration

**`railway.toml`:**
- ✅ Exists and configured
- ✅ `watchPatterns` includes `**/*.py`, `requirements.txt`, `Dockerfile`
- ✅ Build configuration present

**`railway.json`:**
- ⚠️ **CONFLICT:** Different dockerfile path
  - `railway.toml` uses: `Dockerfile`
  - `railway.json` uses: `Dockerfile.optimized`
- ⚠️ **CONFLICT:** Different startCommand
  - `railway.toml` has comprehensive startCommand
  - `railway.json` uses: `gunicorn app.main:app -c gunicorn.conf.py`

**Railway Priority:**
- Railway uses `railway.toml` if present (higher priority)
- `railway.json` is ignored if `railway.toml` exists

---

## 3. File Watch Patterns

**Current `watchPatterns` in `railway.toml`:**
```toml
watchPatterns = ["**/*.py", "requirements.txt", "Dockerfile", "alembic/**", "scripts/**"]
```

**Files Changed in Latest Commit:**
- ✅ `app/services/bigquery_service.py` - Matches `**/*.py`
- ✅ `app/services/langflow_bigquery_integration.py` - Matches `**/*.py`
- ✅ `app/routers/platform_integrations.py` - Matches `**/*.py`
- ✅ `requirements.txt` - Matches `requirements.txt`
- ⚠️ `migrations/bigquery/schema.sql` - **NOT in watchPatterns** (but shouldn't block deployment)
- ⚠️ Documentation files - **NOT in watchPatterns** (but shouldn't block deployment)

**Verdict:** ✅ All code changes match watch patterns

---

## 4. Railway Deployment Triggers

### How Railway Detects Changes

Railway watches for:
1. **Git commits** to the watched branch
2. **File changes** matching `watchPatterns`
3. **Manual triggers** from Railway dashboard

### Verification Steps

1. **Check Railway Dashboard:**
   - Go to Railway → Your Service → Deployments
   - Look for latest deployment
   - Check if it shows the latest commit `081b783`

2. **Check Railway Logs:**
   - Railway → Service → Logs
   - Look for deployment start messages
   - Check for any errors

3. **Check GitHub Webhook:**
   - GitHub → Repository → Settings → Webhooks
   - Verify Railway webhook exists
   - Check recent deliveries for errors

---

## 5. Potential Issues

### Issue 1: Railway Service Not Connected to GitHub

**Check:**
- Railway Dashboard → Service → Settings → Source
- Should show: "Connected to GitHub" with repository URL

**Fix:**
- If not connected, connect GitHub repository
- Select branch: `main`
- Save settings

### Issue 2: Railway Service Paused

**Check:**
- Railway Dashboard → Service → Overview
- Look for "Paused" or "Stopped" status

**Fix:**
- Click "Deploy" or "Resume" button

### Issue 3: Build Failures

**Check:**
- Railway Dashboard → Service → Deployments
- Look for failed deployments
- Check build logs for errors

**Common Build Errors:**
- Missing dependencies in `requirements.txt`
- Dockerfile errors
- Environment variable issues

### Issue 4: Railway Free Tier Limitations

**Free Tier:**
- May have deployment delays
- May pause services after inactivity
- May have rate limits

**Check:**
- Railway Dashboard → Account → Billing
- Verify account status

### Issue 5: Manual Deployment Required

**Some Railway configurations require manual deployment:**
- Check Railway Dashboard → Service → Settings
- Look for "Auto Deploy" toggle
- Ensure it's enabled

---

## 6. Manual Deployment Trigger

If auto-deploy isn't working, you can manually trigger:

### Via Railway Dashboard:
1. Go to Railway → Your Service
2. Click "Deploy" or "Redeploy"
3. Select branch: `main`
4. Click "Deploy"

### Via Railway CLI:
```bash
# Install Railway CLI
npm i -g @railway/cli

# Login
railway login

# Link to service
railway link

# Deploy
railway up
```

---

## 7. Verification Checklist

Use this checklist to diagnose:

- [ ] **GitHub Repository Connected**
  - Railway Dashboard → Service → Settings → Source
  - Shows: "Connected to GitHub: EnGardeHQ/production-backend"

- [ ] **Correct Branch Watched**
  - Branch set to: `main`
  - Not `master` or other branch

- [ ] **Service Not Paused**
  - Service status: "Active" or "Running"
  - Not "Paused" or "Stopped"

- [ ] **Latest Commit Detected**
  - Railway → Deployments → Latest shows commit `081b783`
  - Or shows "Deploying..." status

- [ ] **No Build Errors**
  - Deployment logs show successful build
  - No errors in build phase

- [ ] **Auto-Deploy Enabled**
  - Settings → Auto Deploy toggle is ON
  - Not manually disabled

- [ ] **Watch Patterns Match**
  - Changed files match `watchPatterns` in `railway.toml`
  - ✅ All Python files match `**/*.py`
  - ✅ `requirements.txt` matches

---

## 8. Quick Fixes

### Fix 1: Force Redeploy
```bash
# Via Railway Dashboard
1. Go to Railway → Service → Deployments
2. Click "Redeploy" on latest deployment
3. Or click "Deploy" → Select branch `main`
```

### Fix 2: Check Railway Status
```bash
# Check Railway service status
# Go to Railway Dashboard → Service → Overview
# Look for any warnings or errors
```

### Fix 3: Verify GitHub Connection
```bash
# Railway Dashboard → Service → Settings → Source
# Click "Disconnect" then "Connect GitHub"
# Re-select repository and branch
```

### Fix 4: Check Railway Logs
```bash
# Railway Dashboard → Service → Logs
# Look for deployment messages
# Check for errors
```

---

## 9. Expected Behavior

### Normal Auto-Deploy Flow:

```
1. Git push to main branch
   ↓
2. GitHub webhook triggers Railway
   ↓
3. Railway detects changes in watchPatterns
   ↓
4. Railway starts build process
   ↓
5. Railway builds Docker image
   ↓
6. Railway deploys new container
   ↓
7. Railway runs health check
   ↓
8. Service goes live
```

### Timeline:
- **Git push:** Immediate
- **Railway detection:** 10-30 seconds
- **Build time:** 2-5 minutes (depending on Dockerfile)
- **Deploy time:** 30-60 seconds
- **Total:** 3-7 minutes from push to live

---

## 10. Troubleshooting Steps

### Step 1: Check Railway Dashboard
1. Go to https://railway.app
2. Navigate to your service
3. Check "Deployments" tab
4. Look for latest deployment

### Step 2: Check Deployment Status
- **If deploying:** Wait for completion
- **If failed:** Check build logs
- **If no deployment:** Check GitHub connection

### Step 3: Verify GitHub Webhook
1. GitHub → Repository → Settings → Webhooks
2. Find Railway webhook
3. Check "Recent Deliveries"
4. Look for successful deliveries

### Step 4: Manual Trigger
If auto-deploy isn't working:
1. Railway Dashboard → Service → Deploy
2. Select branch: `main`
3. Click "Deploy"
4. Monitor deployment logs

---

## 11. Common Railway Auto-Deploy Issues

### Issue: Railway Not Detecting Commits

**Possible Causes:**
1. GitHub webhook not configured
2. Wrong branch watched
3. Service paused
4. Railway free tier limitations

**Solution:**
- Verify GitHub connection in Railway dashboard
- Check branch settings
- Ensure service is active

### Issue: Build Fails

**Possible Causes:**
1. Missing dependencies
2. Dockerfile errors
3. Environment variable issues
4. Build timeout

**Solution:**
- Check build logs in Railway
- Verify `requirements.txt` includes all dependencies
- Check Dockerfile for errors

### Issue: Deployment Succeeds But Service Doesn't Start

**Possible Causes:**
1. Health check failing
2. Start command errors
3. Port configuration issues
4. Environment variables missing

**Solution:**
- Check Railway logs for startup errors
- Verify `startCommand` in `railway.toml`
- Check health check endpoint `/health`

---

## 12. Next Steps

### Immediate Actions:

1. **Check Railway Dashboard:**
   - Verify latest deployment shows commit `081b783`
   - Check if deployment is in progress or failed

2. **If No Deployment:**
   - Manually trigger deployment
   - Check GitHub webhook status
   - Verify Railway service is active

3. **If Deployment Failed:**
   - Check build logs
   - Verify BigQuery dependencies in `requirements.txt`
   - Check for missing environment variables

4. **If Deployment Succeeded:**
   - Check service logs
   - Verify BigQuery service initializes
   - Test webhook → BigQuery flow

---

**Diagnosis Date:** 2025-11-18  
**Latest Commit:** `081b783`  
**Expected:** Railway should auto-deploy within 3-7 minutes  
**Action:** Check Railway dashboard for deployment status
