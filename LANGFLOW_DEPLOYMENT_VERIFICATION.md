# Langflow Deployment Verification

## Current Status

✅ **Code Status**: All code is committed and pushed to `langflow-engarde` repository
✅ **Environment Variables**: All set in Railway (as confirmed by user)
✅ **Dockerfile**: Configured to copy components and SSO endpoint
✅ **Langflow Service**: Running and responding (HTTP 200 at https://langflow.engarde.media/health)

---

## What's Already in the Deployed Code

### 1. Dockerfile Configuration (Lines 260-334)

**Components Copy**:
```dockerfile
RUN mkdir -p "/app/components/En Garde Components"
COPY ["En Garde Components", "/app/components/En Garde Components"]
```

**Components Path**:
```dockerfile
ENV LANGFLOW_COMPONENTS_PATH="/app/components"
```

This means Langflow will scan `/app/components/` and find the `En Garde Components/` subdirectory with all 14 Walker Agent components.

### 2. SSO Endpoint

File: `src/backend/base/langflow/api/v1/custom.py`
- Endpoint: `GET /api/v1/custom/sso_login?token={jwt}`
- Validates JWT using `LANGFLOW_SECRET_KEY`
- Creates/updates users with tenant isolation
- Sets authentication cookies
- Redirects to Langflow dashboard

### 3. Walker Agent Components

Directory: `En Garde Components/`
- ✅ seo_walker_agent.py
- ✅ paid_ads_walker_agent.py
- ✅ content_walker_agent.py
- ✅ audience_intelligence_walker_agent.py
- ✅ campaign_creation_agent.py
- ✅ campaign_launcher_agent.py
- ✅ analytics_report_agent.py
- ✅ content_approval_agent.py
- ✅ notification_agent.py
- ✅ performance_monitoring_agent.py
- ✅ tenant_id_input.py
- ✅ walker_suggestion_builder.py
- ✅ walker_agent_api.py
- ✅ README.md

---

## Quick Verification Steps

### Step 1: Verify Current Deployment (1 min)

```bash
# Check Langflow is running
curl https://langflow.engarde.media/health
# Expected: HTTP 200

# Check Railway deployment status
railway status
```

### Step 2: Check Component Loading in Logs (2 min)

```bash
# View recent logs
railway logs --service langflow-server | tail -100

# Look for these lines:
# "Loading custom components from /app/components"
# "Loaded component: SEOWalkerAgent"
# "Loaded component: PaidAdsWalkerAgent"
# ... etc
```

### Step 3: Test SSO Endpoint (3 min)

```bash
# Generate test SSO token (requires EnGarde access token)
curl -X POST https://api.engarde.media/api/v1/sso/langflow \
  -H "Authorization: Bearer YOUR_TOKEN"

# Expected response:
# {
#   "sso_url": "https://langflow.engarde.media/api/v1/custom/sso_login?token=...",
#   "expires_in": 300
# }
```

### Step 4: Test Component Visibility in UI (2 min)

1. Visit https://langflow.engarde.media
2. Login (or use SSO)
3. Create new flow
4. Check left sidebar for "En Garde Components" or "Custom" category
5. Verify 14 components are listed

---

## If Components Don't Appear

### Possible Issue 1: Components Not Loading

**Symptom**: No custom components in Langflow UI

**Check logs**:
```bash
railway logs --service langflow-server | grep -i "component\|custom\|walker"
```

**Possible causes**:
1. `LANGFLOW_COMPONENTS_PATH` not set correctly (should be `/app/components`)
2. Components directory not copied during Docker build
3. Python syntax errors in component files

**Fix**:
```bash
# Verify environment variable
railway variables --service langflow-server | grep COMPONENTS_PATH

# Should show:
# LANGFLOW_COMPONENTS_PATH=/app/components
```

### Possible Issue 2: Components Load but Don't Work

**Symptom**: Components visible but fail when executed

**Check logs**:
```bash
railway logs --service langflow-server | grep -i "error\|exception"
```

**Possible causes**:
1. Missing API keys (WALKER_AGENT_API_KEY_*)
2. Missing ENGARDE_API_URL
3. Network connectivity issues

**Fix**:
```bash
# Verify API keys are set
railway variables --service langflow-server | grep WALKER_AGENT_API_KEY

# Should show 4 keys:
# WALKER_AGENT_API_KEY_ONSIDE_SEO=wa_...
# WALKER_AGENT_API_KEY_SANKORE_PAID_ADS=wa_...
# WALKER_AGENT_API_KEY_ONSIDE_CONTENT=wa_...
# WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE=wa_...
```

### Possible Issue 3: SSO Fails

**Symptom**: "Invalid SSO token" or "SSO not configured"

**Possible causes**:
1. `LANGFLOW_SECRET_KEY` not set
2. `LANGFLOW_SECRET_KEY` doesn't match between production-backend and langflow-server
3. JWT token expired (5 min expiry)

**Fix**:
```bash
# Check both services have matching secret
railway link --service production-backend
railway variables | grep LANGFLOW_SECRET_KEY

railway link --service langflow-server
railway variables | grep LANGFLOW_SECRET_KEY

# Both should show the EXACT same value
```

---

## Force Redeploy (If Needed)

If you want to force Railway to rebuild and redeploy with the latest code:

```bash
# Option 1: Make a trivial commit to trigger rebuild
echo "# Force rebuild $(date)" >> README.md
git add README.md
git commit -m "chore: trigger Railway rebuild"
git push

# Option 2: Redeploy via Railway CLI (if available)
railway redeploy --service langflow-server

# Option 3: Via Railway Dashboard
# Go to langflow-server service → Deployments → Click "Redeploy"
```

---

## Expected Results After Verification

When everything is working correctly:

1. ✅ Langflow UI loads at https://langflow.engarde.media
2. ✅ SSO authentication works (no manual login needed from EnGarde)
3. ✅ "En Garde Components" category visible in component sidebar
4. ✅ 14 custom components listed and draggable
5. ✅ Components execute successfully (test with SEO Walker Agent)
6. ✅ Results appear in `walker_agent_suggestions` database table

---

## Next Steps After Verification

Once verified:

1. **Test end-to-end flow**:
   - Login to EnGarde
   - Navigate to `/agent-suite`
   - Create a Walker Agent flow
   - Execute it
   - Verify results in database

2. **Document for team**:
   - Share verification results
   - Note any issues encountered
   - Update team wiki/docs

3. **Monitor in production**:
   - Watch Railway logs for errors
   - Check database for execution records
   - Monitor user feedback

---

**Created**: January 11, 2026
**Status**: Ready for Verification
**Estimated Time**: 10 minutes
