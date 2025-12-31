# Railway Deployment Guide - EnGarde Langflow

## ✅ Fixed Image - Railway Compatible

The Docker image has been **successfully rebuilt and pushed** with Railway compatibility fixes.

### 📦 Available Docker Images

All images are available on Docker Hub under `cope84/engarde-langflow`:

- **`cope84/engarde-langflow:latest`** - Latest stable version
- **`cope84/engarde-langflow:v1.0.4`** - Version-tagged release
- **`cope84/engarde-langflow:railway`** - Railway-specific tag

**Image Digest:** `sha256:2b882d4f9baea6b180ecb51f0f52beb09c08fd5304ec0e169663dd90215c1ee0`
**Size:** ~5.33GB

---

## 🔧 What Was Fixed

### Issue
Railway deployment was failing with "Container failed to start" error because:
- The image had a hardcoded port (7860) in the CMD
- Railway provides a dynamic `PORT` environment variable that must be used

### Solution
Created a startup script (`/app/start.sh`) that:
1. Reads Railway's `PORT` environment variable
2. Falls back to port 7860 if PORT is not set
3. Starts Langflow with the correct port dynamically

**Startup Script:**
```bash
#!/bin/bash
PORT=${PORT:-7860}
echo "Starting Langflow on port $PORT"
exec langflow run --host 0.0.0.0 --port $PORT
```

---

## ✨ Verified Features

### ✅ EnGarde Branding Applied
The custom branding has been verified in the built image:

**Title:** `EnGarde - AI Campaign Builder`
**App Name:** `EnGarde`
**Description:** `EnGarde - AI-powered social media campaign builder and management platform`

**Verification Commands:**
```bash
# Check title
docker run --rm cope84/engarde-langflow:latest cat /app/.venv/lib/python3.12/site-packages/langflow/frontend/index.html | grep title

# Check manifest
docker run --rm cope84/engarde-langflow:latest cat /app/.venv/lib/python3.12/site-packages/langflow/frontend/manifest.json | grep name
```

---

## 🚀 Railway Deployment Instructions

### Option 1: Deploy via Railway Dashboard

1. **Create New Project** in Railway
2. **Deploy from Docker Hub:**
   - Image: `cope84/engarde-langflow:railway`
   - Or use: `cope84/engarde-langflow:latest`

3. **Set Environment Variables** (Optional):
   ```
   LANGFLOW_COMPONENTS_PATH=/app/custom_components
   LANGFLOW_AUTO_LOGIN=true
   ```

4. **Railway will automatically:**
   - Set the `PORT` environment variable
   - Map that port to a public URL
   - Start the container with the startup script

### Option 2: Deploy via Railway CLI

```bash
# Login to Railway
railway login

# Link to your project (or create new)
railway link

# Set the Docker image
railway up -d cope84/engarde-langflow:railway

# Or deploy with environment variables
railway run --service langflow
```

### Option 3: Deploy via railway.json

Create a `railway.json` in your project:

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile.engarde"
  },
  "deploy": {
    "numReplicas": 1,
    "sleepApplication": false,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

---

## 🔍 Testing the Image Locally

### Test with Default Port (7860)
```bash
docker run -p 7860:7860 cope84/engarde-langflow:latest
```
Access at: http://localhost:7860

### Test with Railway-style Dynamic Port
```bash
docker run -e PORT=8080 -p 8080:8080 cope84/engarde-langflow:latest
```
Access at: http://localhost:8080

You should see in the logs:
```
Starting Langflow on port 8080
```

---

## 📋 Image Build Details

**Base Images:**
- Builder: `ghcr.io/astral-sh/uv:python3.12-bookworm-slim`
- Runtime: `python:3.12.3-slim`

**Multi-stage Build:**
- Stage 1: Build Python dependencies and frontend assets
- Stage 2: Runtime with only necessary files

**Optimizations:**
- Multi-stage build keeps image efficient
- Only runtime dependencies included in final image
- Frontend built with EnGarde branding during build
- uv package manager for fast dependency resolution

---

## 🐛 Troubleshooting

### Container Fails to Start on Railway

**Check logs for:**
```
Container failed to start
```

**Solution:** Ensure you're using the latest image:
```bash
docker pull cope84/engarde-langflow:latest
```

### Port Binding Issues

**Error:** `bind: address already in use`

**Solution:** Railway handles port binding automatically. Don't specify port mappings in Railway config.

### Branding Not Showing

**Possible causes:**
1. Browser cache - Clear cache and hard reload (Ctrl+Shift+R)
2. Using old image - Pull latest: `docker pull cope84/engarde-langflow:latest`

**Verify branding is in image:**
```bash
docker run --rm cope84/engarde-langflow:latest cat /app/.venv/lib/python3.12/site-packages/langflow/frontend/index.html | grep -i "engarde"
```

---

## 📝 Environment Variables

The following environment variables are pre-configured in the image:

```bash
PATH=/app/.venv/bin:$PATH
LANGFLOW_HOST=0.0.0.0
LANGFLOW_PORT=7860  # Overridden by Railway's PORT
LANGFLOW_COMPONENTS_PATH=/app/custom_components
LANGFLOW_AUTO_LOGIN=true
```

You can override any of these in Railway's environment variables section.

---

## 🔐 Security Notes

- Image runs as non-root user `user` (UID 1000)
- Working directory: `/app`
- Data directory: `/app/data`

For persistent data on Railway, configure a volume mount to `/app/data`.

---

## 📚 Additional Resources

- **Docker Hub:** https://hub.docker.com/r/cope84/engarde-langflow
- **GitHub Source:** https://github.com/EnGardeHQ/langflow-custom
- **Railway Docs:** https://docs.railway.app/

---

## 🎯 Quick Reference

**Pull Latest Image:**
```bash
docker pull cope84/engarde-langflow:latest
```

**Run Locally:**
```bash
docker run -p 7860:7860 cope84/engarde-langflow:latest
```

**Deploy to Railway:**
```bash
railway up -d cope84/engarde-langflow:railway
```

**Check Image Digest:**
```bash
docker inspect cope84/engarde-langflow:latest | grep -i digest
```

---

## ✅ Deployment Checklist

- [x] Image built with Railway PORT support
- [x] EnGarde branding verified in frontend
- [x] Multi-stage build for optimization
- [x] Pushed to Docker Hub with multiple tags
- [x] Startup script handles dynamic PORT
- [x] Tested locally with dynamic port
- [ ] Deploy to Railway and verify
- [ ] Test application functionality
- [ ] Verify branding in production

---

**Last Updated:** 2025-12-30
**Image Version:** v1.0.4
**Maintainer:** EnGarde Team
