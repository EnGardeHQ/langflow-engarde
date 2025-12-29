# Railway Deployment Solution - EnGarde Langflow

## Current Situation

### Docker Build Status
- ✅ Docker image **built successfully** (all layers completed)
- ❌ Failed to unpack locally due to **disk space** (99% full - 413Gi/460Gi used)
- ✅ Custom Langflow code with EnGarde branding **pushed to GitHub**
- Repository: https://github.com/EnGardeHQ/langflow-engarde

### Disk Space Constraint
```
Filesystem: /dev/disk3s5
Total: 460Gi
Used: 413Gi (99%)
Available: 4.3Gi
```

**Problem**: Docker image is ~2.5GB. Need ~3-4GB free space to unpack, but only 4.3GB available.

---

## Recommended Solution: Railway GitHub Deployment

### Why This Will Work (vs. Previous Attempt)

**Previous failure**: Railway tried to build official Langflow from source using Node.js/npm
**New approach**: Railway will use our **custom Dockerfile** which builds correctly

**Key difference**:
- ❌ Before: Railway's auto-detect tried to build frontend with npm (failed)
- ✅ Now: Railway uses `docker/build_and_push.Dockerfile` (succeeds)

### Evidence This Works

The Docker build logs show the frontend built successfully:
```
#27 179.0 ✓ built in 2m 5s
#27 DONE 183.3s
```

The only failure was unpacking due to local disk space, NOT the build itself.

---

## Deployment Steps

### Step 1: Configure Railway to Build from GitHub

Via Railway Dashboard:

1. Go to https://railway.app
2. Select your project → `langflow-server` service
3. Click **Settings** tab
4. Scroll to **Source** section
5. Click **Change Source** → **GitHub Repository**
6. Select: `EnGardeHQ/langflow-engarde`
7. Branch: `main`
8. **IMPORTANT**: Set build configuration:
   - **Builder**: Docker
   - **Dockerfile Path**: `docker/build_and_push.Dockerfile`
   - **Docker Build Context**: `.` (root)

### Step 2: Set Environment Variables

Railway will use Railway.app environment variables during build. Verify these are set:

```bash
railway variables --service langflow-server
```

Should include:
- `ONSIDE_API_URL=https://onside-production.up.railway.app`
- `SANKORE_API_URL=https://sankore-production.up.railway.app`
- `MADANSARA_API_URL=https://madansara-production.up.railway.app`
- Plus all BigQuery, ZeroDB, PostgreSQL credentials

### Step 3: Deploy

**Option A**: Railway Dashboard
- Click **Deploy** button in the service

**Option B**: Railway CLI
```bash
cd /Users/cope/EnGardeHQ/langflow-custom
railway up
```

### Step 4: Monitor Build

Railway will build the Docker image on their infrastructure (no local disk space needed).

**Check logs**:
```bash
railway logs --service langflow-server | grep -i "building\|docker\|frontend"
```

**Expected build time**: 15-25 minutes

---

## Verification

Once deployed, verify:

### 1. Check Deployment Status
```bash
railway status --service langflow-server
```

### 2. Test URL
```bash
curl -I https://langflow.engarde.media
```

Expected: `HTTP/2 200`

### 3. Verify Branding

Open https://langflow.engarde.media in browser:

- ✅ EnGarde logo in header (top-left)
- ✅ Footer: "From EnGarde with Love ❤️" (bottom-left)
- ❌ No DataStax/Langflow branding

---

## Alternative: Docker Hub (If Railway GitHub Fails)

If Railway GitHub deployment fails, we can use a **remote build server** to push to Docker Hub.

### Option 1: GitHub Actions to Build and Push

Create `.github/workflows/docker-hub.yml`:

```yaml
name: Build and Push to Docker Hub

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_HUB_USERNAME }}
          password: ${{ secrets.DOCKER_HUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          file: docker/build_and_push.Dockerfile
          push: true
          tags: |
            langflowai/langflow-engarde:latest
            langflowai/langflow-engarde:v1.0.0
```

Then configure Railway to use Docker Hub image:
```bash
railway variables --service langflow-server --set RAILWAY_DOCKER_IMAGE=langflowai/langflow-engarde:latest
railway up
```

### Option 2: Use Cloud Build Service

Services like **Google Cloud Build** or **AWS CodeBuild** can build and push to Docker Hub without local resources.

---

## Why Railway GitHub Deployment Should Work

1. **Railway has build resources**: No disk space constraints
2. **Dockerfile is proven**: Build succeeded locally, only unpacking failed
3. **Frontend builds in Docker**: The build logs show `✓ built in 2m 5s`
4. **Railway.json configured**: Tells Railway to use Docker builder

The only risk is if Railway's Docker builder has different behavior than local Docker, but this is unlikely since we're using the same Dockerfile.

---

## Rollback Plan

If deployment fails:

```bash
# Revert to official Langflow Docker image
railway variables --service langflow-server --unset RAILWAY_DOCKER_IMAGE
railway variables --service langflow-server --set LANGFLOW_IMAGE=langflowai/langflow:latest
railway up
```

---

## Next Steps After Successful Deployment

1. ✅ Verify EnGarde branding
2. ✅ Deploy all 10 agents using `FINAL_ANSWERS_AND_INSTRUCTIONS.md`
3. ✅ Test each agent with real tenant_id
4. ✅ Set up cron schedules for automated runs

---

## Recommendation

**Use Railway GitHub deployment** with custom Dockerfile. This:
- ✅ Bypasses local disk space issues
- ✅ Uses proven Dockerfile that built successfully
- ✅ Leverages Railway's build infrastructure
- ✅ Enables future updates via git push
- ✅ Avoids Docker Hub intermediate step

**Fallback**: If Railway GitHub fails, use GitHub Actions to build and push to Docker Hub, then configure Railway to pull from Docker Hub.

---

## Files Ready

All code is committed and pushed to:
- **Repository**: https://github.com/EnGardeHQ/langflow-engarde
- **Branch**: main
- **Dockerfile**: `docker/build_and_push.Dockerfile`
- **Config**: `railway.json`

**Ready to deploy!** 🚀
