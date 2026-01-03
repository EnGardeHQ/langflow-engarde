# Docker Hub Deployment via GitHub Actions

**Deploy EnGarde Langflow to Docker Hub using GitHub's build servers (bypasses local disk space issues)**

---

## Setup Steps

### Step 1: Add Docker Hub Credentials to GitHub

1. Go to https://github.com/EnGardeHQ/langflow-engarde/settings/secrets/actions

2. Click **"New repository secret"**

3. Add **DOCKER_HUB_USERNAME**:
   - Name: `DOCKER_HUB_USERNAME`
   - Secret: Your Docker Hub username (e.g., `cope84` or `langflowai`)

4. Click **"New repository secret"** again

5. Add **DOCKER_HUB_TOKEN**:
   - Name: `DOCKER_HUB_TOKEN`
   - Secret: Your Docker Hub access token

   **To get a Docker Hub token:**
   - Go to https://hub.docker.com/settings/security
   - Click **"New Access Token"**
   - Description: "GitHub Actions - Langflow EnGarde"
   - Permissions: Read, Write, Delete
   - Copy the token (you'll only see it once!)
   - Paste it as the secret value

---

### Step 2: Trigger the Build

Once the secrets are added, the GitHub Action will automatically build and push to Docker Hub.

**Option A: Automatic (already triggered)**
- The workflow runs automatically on every push to `main`
- It's already running since we just pushed the workflow file

**Option B: Manual trigger**
1. Go to https://github.com/EnGardeHQ/langflow-engarde/actions
2. Click on "Build and Push to Docker Hub" workflow
3. Click "Run workflow" button
4. Select branch: `main`
5. Click "Run workflow"

---

### Step 3: Monitor the Build

1. Go to https://github.com/EnGardeHQ/langflow-engarde/actions

2. Click on the running workflow (should show a yellow dot)

3. Click on the "build" job to see live logs

4. Wait for completion (15-25 minutes)

**What you'll see:**
- ✅ Checkout code
- ✅ Set up Docker Buildx
- ✅ Login to Docker Hub
- ✅ Build and push (this takes the longest)
- ✅ Image details

---

### Step 4: Verify Image on Docker Hub

Once the build completes:

1. Go to https://hub.docker.com/r/[YOUR_USERNAME]/langflow-engarde

2. You should see two tags:
   - `latest`
   - `v1.0.0`

3. Check the image size (~2.5GB)

4. Verify the image was pushed recently (timestamp)

---

### Step 5: Configure Railway to Use Docker Hub Image

Now that the image is on Docker Hub, configure Railway to pull from Docker Hub:

```bash
# Set Railway to use your Docker Hub image
railway variables --service langflow-server --set RAILWAY_DOCKER_IMAGE=[YOUR_USERNAME]/langflow-engarde:latest

# Deploy
railway up
```

**Or via Railway Dashboard:**

1. Go to https://railway.app
2. Select project → `langflow-server` service
3. Settings → **Deployment** → **Source**
4. Click **"Change Source"** → **"Docker Image"**
5. Enter: `[YOUR_USERNAME]/langflow-engarde:latest`
6. Click **"Deploy"**

---

### Step 6: Verify Deployment

1. **Check Railway status:**
   ```bash
   railway status --service langflow-server
   ```

2. **Check Railway logs:**
   ```bash
   railway logs --service langflow-server | tail -50
   ```

3. **Test the URL:**
   ```bash
   curl -I https://langflow.engarde.media
   ```

4. **Verify branding:**
   - Open https://langflow.engarde.media
   - ✅ EnGarde logo in header (top-left)
   - ✅ Footer: "From EnGarde with Love ❤️" (bottom-left)
   - ❌ No DataStax/Langflow branding

---

## How It Works

### GitHub Actions Workflow

The workflow (`.github/workflows/docker-hub.yml`) runs on GitHub's servers and:

1. **Checks out the code** from the repository
2. **Sets up Docker Buildx** (multi-platform builder)
3. **Logs in to Docker Hub** using your credentials (from secrets)
4. **Builds the Docker image** using `docker/build_and_push.Dockerfile`
5. **Pushes to Docker Hub** with tags `latest` and `v1.0.0`
6. **Uses GitHub Actions cache** to speed up future builds

### Benefits

- ✅ **No local disk space needed** - GitHub provides 14GB for builds
- ✅ **Faster builds** - GitHub runners have fast internet and SSD storage
- ✅ **Automated** - Every push to `main` triggers a new build
- ✅ **Free** - GitHub Actions is free for public repositories
- ✅ **Docker Hub deployment** - As you requested!

---

## Troubleshooting

### Build Fails with "Invalid credentials"

**Solution:**
1. Go to https://github.com/EnGardeHQ/langflow-engarde/settings/secrets/actions
2. Verify `DOCKER_HUB_USERNAME` and `DOCKER_HUB_TOKEN` are set correctly
3. Generate a new Docker Hub token if needed
4. Update the `DOCKER_HUB_TOKEN` secret

### Build Fails with "Dockerfile not found"

**Solution:**
1. Verify the file exists: `docker/build_and_push.Dockerfile`
2. Check the workflow file path is correct
3. Re-run the workflow

### Build Takes Too Long / Timeout

**Solution:**
- GitHub Actions has a 6-hour timeout, more than enough
- First build takes 15-25 minutes (subsequent builds are faster due to caching)
- If it times out, there may be a GitHub outage - check https://www.githubstatus.com

### Railway Can't Pull Image from Docker Hub

**Error:** `failed to pull image`

**Solution:**
1. Make the Docker Hub repository public:
   - Go to https://hub.docker.com/r/[YOUR_USERNAME]/langflow-engarde/settings
   - Click "Make Public"

2. Or add Docker Hub credentials to Railway:
   - Railway Dashboard → Project Settings → Variables
   - Add: `DOCKER_HUB_USERNAME` and `DOCKER_HUB_PASSWORD`

---

## What Happens Next

### Automatic Rebuilds

Every time you push changes to the `main` branch:

1. GitHub Actions automatically builds a new Docker image
2. Pushes it to Docker Hub with the `latest` tag
3. Railway detects the new image (if configured with `latest` tag)
4. Railway automatically redeploys

### Manual Rebuilds

To manually rebuild:

1. Go to https://github.com/EnGardeHQ/langflow-engarde/actions
2. Click "Build and Push to Docker Hub"
3. Click "Run workflow"

---

## Expected Timeline

| Step | Duration |
|------|----------|
| Add GitHub secrets | 2 minutes |
| GitHub Actions build | 15-25 minutes |
| Push to Docker Hub | 5-10 minutes |
| Railway deployment | 5-10 minutes |
| **Total** | **27-47 minutes** |

---

## Summary

**You wanted:** Docker Hub deployment (not GitHub deployment)
**Solution:** Use GitHub Actions to build and push to Docker Hub (bypasses local disk space)
**Result:** Railway pulls from Docker Hub (Docker image deployment, as required)

This approach gives you:
- ✅ Docker Hub image (as you requested)
- ✅ Railway deploys from Docker (as you required)
- ✅ No local disk space issues
- ✅ Automated builds on every code change

---

## Ready to Start!

**Next action:**

1. Add Docker Hub credentials to GitHub secrets (see Step 1 above)
2. The build will automatically start
3. Monitor at https://github.com/EnGardeHQ/langflow-engarde/actions

**Questions?** Check the troubleshooting section above.

🚀 **Let's get this on Docker Hub!**
