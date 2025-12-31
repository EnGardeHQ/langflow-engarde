# Push Custom Langflow to Docker Hub via Docker Desktop

## Current Situation

- Custom Langflow code with EnGarde branding is ready at: `/Users/cope/EnGardeHQ/langflow-custom`
- Docker Hub repository exists: https://hub.docker.com/repository/docker/cope84/engarde-langflow
- Need to build and push from Docker Desktop

---

## Steps to Build and Push from Docker Desktop

### Step 1: Open Docker Desktop

1. Open **Docker Desktop** application
2. Wait for it to fully start (green indicator)

### Step 2: Build the Image Using Docker Desktop

Open Terminal and run:

```bash
cd /Users/cope/EnGardeHQ/langflow-custom

# Build the image (Docker Desktop will handle the build)
docker build \
  --tag cope84/engarde-langflow:latest \
  --tag cope84/engarde-langflow:v1.0.0 \
  --file docker/build_and_push.Dockerfile \
  .
```

**This will take 15-25 minutes**

Monitor progress in the terminal. You should see:
- `[builder 1/18]` through `[builder 18/18]` - backend build steps
- `[runtime 1/4]` through `[runtime 4/4]` - final image assembly
- `exporting to image` - final stage

### Step 3: Push to Docker Hub from Docker Desktop

#### Option A: Using Docker Desktop UI

1. Open **Docker Desktop**
2. Go to **Images** tab
3. Find `cope84/engarde-langflow:latest`
4. Click the **⋮** (three dots) menu
5. Select **Push to Hub**
6. Confirm the push

#### Option B: Using Terminal

```bash
# Make sure you're logged in
docker login
# Username: cope84
# Password: [your Docker Hub password or token]

# Push latest tag
docker push cope84/engarde-langflow:latest

# Push versioned tag
docker push cope84/engarde-langflow:v1.0.0
```

---

## Verify Push to Docker Hub

1. Go to https://hub.docker.com/repository/docker/cope84/engarde-langflow/general

2. Check that you see:
   - Tag: `latest` (updated timestamp)
   - Tag: `v1.0.0` (new)

---

## Then Configure Railway

Once the image is on Docker Hub:

```bash
# Configure Railway to use your Docker Hub image
railway variables --service langflow-server --set RAILWAY_DOCKER_IMAGE=cope84/engarde-langflow:latest

# Deploy
railway up
```

Or via Railway Dashboard:
1. Go to https://railway.app
2. Select project → `langflow-server` service
3. Settings → Source → **Docker Image**
4. Enter: `cope84/engarde-langflow:latest`
5. Click **Deploy**

---

## If Build Fails Due to Disk Space

If you see errors like "no space left on device":

### Clean up space:

```bash
# Remove unused Docker data
docker system prune -af --volumes

# Check available space
df -h .

# Remove node_modules to free more space
cd /Users/cope/EnGardeHQ
rm -rf */node_modules
rm -rf langflow-custom/src/frontend/node_modules
```

Then try building again.

---

## Alternative: Use GitHub Actions (Recommended if local build fails)

If local disk space continues to be an issue, use GitHub Actions to build on GitHub's servers:

1. Go to https://github.com/EnGardeHQ/langflow-engarde/settings/secrets/actions

2. Add secrets:
   - `DOCKER_HUB_USERNAME` = `cope84`
   - `DOCKER_HUB_TOKEN` = [create at https://hub.docker.com/settings/security]

3. Go to https://github.com/EnGardeHQ/langflow-engarde/actions

4. Click "Build and Push to Docker Hub" workflow

5. Click "Run workflow" → Select branch `main` → "Run workflow"

GitHub will build and push to Docker Hub automatically (15-25 minutes).

---

## Files Modified in Custom Langflow

The custom image includes these EnGarde branding changes:

1. **Header Logo** - `src/frontend/src/components/core/appHeaderComponent/index.tsx`
   - Replaced Langflow logo with EnGarde logo

2. **Custom Footer** - `src/frontend/src/components/core/engardeFooter/index.tsx`
   - Shows "From EnGarde with Love ❤️" at bottom-left

3. **EnGarde Logo** - `src/frontend/src/assets/EnGardeLogo.png`
   - Logo file copied from production-frontend

4. **App Integration** - `src/frontend/src/App.tsx`
   - Added EnGardeFooter component to render tree

---

## Expected Result

After pushing to Docker Hub and deploying to Railway:

✅ https://langflow.engarde.media shows:
- EnGarde logo in header (top-left)
- "From EnGarde with Love ❤️" footer (bottom-left)
- No DataStax/Langflow branding

✅ Ready to deploy all 10 agents (Walker + EnGarde)

---

## Next Steps After Railway Deployment

1. Verify branding at https://langflow.engarde.media
2. Deploy all 10 agents using `FINAL_ANSWERS_AND_INSTRUCTIONS.md`
3. Test agents with real tenant_id
4. Set up cron schedules

---

**Ready to build from Docker Desktop!**
