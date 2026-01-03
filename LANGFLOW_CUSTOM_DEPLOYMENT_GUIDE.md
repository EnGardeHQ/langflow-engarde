# Custom Langflow Deployment Guide - EnGarde Branded

**Complete guide to deploy custom Langflow with EnGarde branding to Railway**

---

## ✅ What Was Changed

### 1. Logo Replacement
- **Removed:** DataStax logo and Langflow logo
- **Added:** EnGarde logo in header (top-left)
- **File:** `src/frontend/src/components/core/appHeaderComponent/index.tsx`

### 2. Custom Footer Added
- **Added:** "From EnGarde with Love ❤️" footer
- **Position:** Fixed at bottom-left
- **File:** `src/frontend/src/components/core/engardeFooter/index.tsx`

### 3. Assets Added
- **EnGarde Logo:** `src/frontend/src/assets/EnGardeLogo.png`
- **Source:** Copied from `/Users/cope/EnGardeHQ/production-frontend/public/engarde-logo.png`

---

## 🚀 Deployment Steps

### Step 1: Build Docker Image (In Progress)

The custom Docker image is currently building. This may take 10-30 minutes.

**Command running:**
```bash
docker build -t langflow-engarde:latest -f docker/build_and_push.Dockerfile .
```

**Check build progress:**
```bash
# View last 50 lines
tail -50 /tmp/docker-build.log

# Follow build in real-time
tail -f /tmp/docker-build.log
```

---

### Step 2: Tag Image for Railway

Once the build completes, tag the image for Railway:

```bash
# Get your Railway project ID
railway status

# Tag the image
docker tag langflow-engarde:latest registry.railway.app/langflow-engarde:latest
```

---

### Step 3: Push to Railway Registry

**Option A: Using Railway CLI (Recommended)**

```bash
# Login to Railway
railway login

# Link to your project
railway link

# Push the Docker image
docker push registry.railway.app/langflow-engarde:latest
```

**Option B: Deploy from GitHub**

1. Create a new repository for custom Langflow:
```bash
cd /Users/cope/EnGardeHQ/langflow-custom
git add .
git commit -m "Custom Langflow with EnGarde branding"
git remote add origin https://github.com/EnGardeHQ/langflow-engarde.git
git push -u origin main
```

2. In Railway Dashboard:
   - Go to `langflow-server` service
   - Settings → Service → Source
   - Connect to GitHub repository: `EnGardeHQ/langflow-engarde`
   - Set build configuration:
     - Dockerfile Path: `docker/build_and_push.Dockerfile`
     - Build Command: (leave default)

---

### Step 4: Configure Railway Service

**Environment Variables (verify these are still set):**

```bash
railway variables --service langflow-server | grep "ONSIDE\|SANKORE\|MADANSARA\|BIGQUERY\|ZERODB"
```

**If missing, set them:**
```bash
# Microservices
railway variables --service langflow-server --set ONSIDE_API_URL=https://onside-production.up.railway.app
railway variables --service langflow-server --set SANKORE_API_URL=https://sankore-production.up.railway.app
railway variables --service langflow-server --set MADANSARA_API_URL=https://madansara-production.up.railway.app

# (Add all other variables from PRODUCTION_ENVIRONMENT_VARIABLES.md)
```

---

### Step 5: Deploy to Railway

**Option A: Using Railway CLI**

```bash
railway up
```

**Option B: Using Railway Dashboard**

1. Go to Railway Dashboard
2. Select `langflow-server` service
3. Go to "Deployments" tab
4. Click "Deploy"
5. Wait for deployment to complete (5-10 minutes)

---

### Step 6: Verify Deployment

**Check deployment status:**
```bash
railway status --service langflow-server
```

**View logs:**
```bash
railway logs --service langflow-server | tail -50
```

**Test the service:**
```bash
curl -I https://langflow.engarde.media
```

**Expected response:**
```
HTTP/2 200
```

---

## 🔍 Verification Checklist

After deployment, verify:

- [ ] Langflow is accessible at https://langflow.engarde.media
- [ ] EnGarde logo appears in top-left header (instead of Langflow logo)
- [ ] Footer shows "From EnGarde with Love ❤️" at bottom-left
- [ ] No DataStax branding visible
- [ ] All environment variables are set
- [ ] Can create new flows
- [ ] Can run Python Function nodes

---

## 📝 Changes Summary

### Modified Files:

1. **src/frontend/src/components/core/appHeaderComponent/index.tsx**
   - Replaced `DataStaxLogo` and `LangflowLogo` imports with `EnGardeLogo`
   - Changed logo component from SVG to PNG image
   - Updated className to `h-8 w-8`

2. **src/frontend/src/App.tsx**
   - Added `EnGardeFooter` import
   - Added footer component to render tree

3. **src/frontend/src/components/core/engardeFooter/index.tsx** (NEW)
   - Created custom footer component
   - Shows EnGarde logo + "From EnGarde with Love ❤️"
   - Fixed position at bottom-left

4. **src/frontend/src/assets/EnGardeLogo.png** (NEW)
   - Added EnGarde logo asset

---

## 🐛 Troubleshooting

### Issue: Docker Build Fails

**Check build log:**
```bash
cat /tmp/docker-build.log | grep -i error
```

**Common errors:**

**Error: "Cannot find module '@/assets/EnGardeLogo.png'"**
- Solution: Verify file exists at `src/frontend/src/assets/EnGardeLogo.png`
- Run: `ls -la src/frontend/src/assets/EnGardeLogo.png`

**Error: "Frontend build failed"**
- Solution: Check TypeScript errors
- Run: `cd src/frontend && npm install && npm run build`

---

### Issue: Railway Deployment Fails

**Check Railway logs:**
```bash
railway logs --service langflow-server | grep -i error
```

**Common errors:**

**Error: "Image pull failed"**
- Solution: Verify image was pushed to Railway registry
- Check: `docker images | grep langflow-engarde`

**Error: "Health check failed"**
- Solution: Increase health check timeout in Railway
- Dashboard → Service → Settings → Health Check → Timeout: 300s

---

### Issue: Logo Not Appearing

**Check browser console:**
- Open DevTools (F12)
- Look for 404 errors for EnGardeLogo.png
- Verify asset was included in build

**Rebuild if needed:**
```bash
docker build --no-cache -t langflow-engarde:latest -f docker/build_and_push.Dockerfile .
```

---

### Issue: Footer Not Showing

**Check z-index conflicts:**
- Footer has `z-50` which should be above most content
- If still hidden, increase z-index to `z-[100]`

**Modify footer component:**
```tsx
// Change this line in engardeFooter/index.tsx
<div className="fixed bottom-0 left-0 z-[100] flex items-center gap-2 ...">
```

---

## 🎨 Customization Options

### Change Footer Position

**Bottom-right instead of bottom-left:**
```tsx
<div className="fixed bottom-0 right-0 z-50 flex items-center gap-2 px-4 py-2">
```

**Top-right:**
```tsx
<div className="fixed top-0 right-0 z-50 flex items-center gap-2 px-4 py-2">
```

---

### Change Footer Text

Edit `src/frontend/src/components/core/engardeFooter/index.tsx`:

```tsx
<span className="text-sm text-muted-foreground">
  Powered by EnGarde 💚  {/* or any other text/emoji */}
</span>
```

---

### Change Logo Size

In `src/frontend/src/components/core/appHeaderComponent/index.tsx`:

```tsx
{/* Current: h-8 w-8 */}
<img src={EnGardeLogo} alt="EnGarde" className="h-10 w-10" />  {/* Larger */}
<img src={EnGardeLogo} alt="EnGarde" className="h-6 w-6" />   {/* Smaller */}
```

---

## 📊 Build Status

**Check if Docker build completed:**
```bash
ps aux | grep docker | grep langflow-engarde
```

**If process is still running:**
- Wait for completion (may take 10-30 minutes)
- Monitor with: `tail -f /tmp/docker-build.log`

**If process completed:**
```bash
# Check if image was created
docker images | grep langflow-engarde

# Expected output:
# langflow-engarde   latest   abc123def456   5 minutes ago   2.5GB
```

---

## 🔄 Rollback Plan

If something goes wrong, you can quickly rollback:

**Option 1: Revert to Official Langflow**

```bash
railway variables --service langflow-server --set RAILWAY_DOCKERFILE_PATH=
# This will use the official langflow image again
railway up
```

**Option 2: Previous Deployment**

In Railway Dashboard:
1. Go to `langflow-server` service
2. Go to "Deployments" tab
3. Find previous working deployment
4. Click "Redeploy"

---

## ✅ Next Steps After Deployment

Once Langflow is deployed with EnGarde branding:

### 1. Set Production Microservice URLs

```bash
railway variables --service langflow-server --set ONSIDE_API_URL=https://onside-production.up.railway.app
railway variables --service langflow-server --set SANKORE_API_URL=https://sankore-production.up.railway.app
railway variables --service langflow-server --set MADANSARA_API_URL=https://madansara-production.up.railway.app
```

### 2. Deploy All 10 Agents

Follow the guide in `FINAL_ANSWERS_AND_INSTRUCTIONS.md`:

For each agent (1-10):
1. Open Langflow at https://langflow.engarde.media
2. Create New Flow
3. Add Text Input node (name: `tenant_id`)
4. Add Python Function node
5. Copy agent code from `FINAL_WALKER_AGENTS_COMPLETE.md` (agents 1-4) or `FINAL_ENGARDE_AGENTS_COMPLETE.md` (agents 5-10)
6. Paste into "Function Code" field
7. Connect nodes
8. Test with real tenant_id
9. Save flow

**Time estimate:** 3 minutes per agent = 30 minutes total

### 3. Verify Agents Are Working

```bash
# Check Walker suggestions
railway run --service Main -- python3 -c "
import os, psycopg2
conn = psycopg2.connect(os.getenv('DATABASE_PUBLIC_URL'))
cur = conn.cursor()
cur.execute('SELECT COUNT(*) FROM walker_agent_suggestions WHERE created_at >= NOW() - INTERVAL \'1 hour\'')
print(f'New suggestions: {cur.fetchone()[0]}')
"
```

### 4. Set Up Cron Schedules

In Langflow, configure automated runs:
- Walker agents: Daily at 9 AM (`0 9 * * *`)
- Analytics Report: Weekly Monday 8 AM (`0 8 * * 1`)
- Performance Monitoring: Every 30 min (`*/30 * * * *`)

---

## 📚 Documentation Reference

- **FINAL_ANSWERS_AND_INSTRUCTIONS.md** - Complete deployment guide for agents
- **LANGFLOW_COPY_PASTE_GUIDE.md** - How to paste code into Python Function nodes
- **PRODUCTION_ENVIRONMENT_VARIABLES.md** - All environment variables
- **QUICK_DEPLOYMENT_CARD.md** - 30-minute agent deployment guide

---

## 🎉 Success Indicators

When everything is working correctly:

✅ **Langflow UI:**
- EnGarde logo in header (top-left)
- "From EnGarde with Love ❤️" footer (bottom-left)
- No DataStax/Langflow branding

✅ **Functionality:**
- Can create flows
- Python Function nodes work
- Can paste agent code
- Can run agents with tenant_id
- Agents execute successfully

✅ **Database:**
- `walker_agent_suggestions` table growing
- `campaigns` being created
- `analytics_reports` generated

---

**Ready to deploy! Wait for Docker build to complete, then proceed with Railway deployment! 🚀**
