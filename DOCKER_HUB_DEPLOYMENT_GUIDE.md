# Docker Hub Deployment Guide - EnGarde Langflow

**Deploy custom Langflow with EnGarde branding via Docker Hub**

---

## 🎯 Summary

The Docker image was **successfully built** but failed during unpacking due to local disk space. We'll use Docker Hub to store and deploy the image to Railway.

---

## 🚀 Deployment Steps

### Step 1: Clean Up Docker Space (In Progress)

Currently running:
```bash
docker system prune -af --volumes
```

This will free up space by removing:
- All stopped containers
- All networks not used by at least one container
- All images without at least one container
- All build cache
- All volumes

---

### Step 2: Login to Docker Hub

```bash
docker login
```

**Enter your Docker Hub credentials:**
- Username: (your Docker Hub username)
- Password: (your Docker Hub password or access token)

---

### Step 3: Rebuild Docker Image (with cleanup)

Since we ran out of space, rebuild with cleanup:

```bash
cd /Users/cope/EnGardeHQ/langflow-custom

# Build with no cache to save space
docker build \
  --no-cache \
  --tag langflowai/langflow-engarde:latest \
  --file docker/build_and_push.Dockerfile \
  .
```

**Note:** Using `langflowai/langflow-engarde` format for Docker Hub

---

### Step 4: Push to Docker Hub

```bash
# Tag for Docker Hub
docker tag langflowai/langflow-engarde:latest langflowai/langflow-engarde:v1.0.0

# Push latest
docker push langflowai/langflow-engarde:latest

# Push versioned
docker push langflowai/langflow-engarde:v1.0.0
```

---

### Step 5: Configure Railway to Use Docker Hub Image

**Option A: Via Railway Dashboard**

1. Go to Railway Dashboard: https://railway.app
2. Select your project
3. Click on `langflow-server` service
4. Go to "Settings" tab
5. Scroll to "Source" section
6. Click "Change Source" → "Docker Image"
7. Enter image: `langflowai/langflow-engarde:latest`
8. Click "Deploy"

**Option B: Via Environment Variable**

```bash
railway variables --service langflow-server --set RAILWAY_DOCKER_IMAGE=langflowai/langflow-engarde:latest
railway up
```

---

### Step 6: Verify Deployment

**Check deployment status:**
```bash
railway status --service langflow-server
```

**View logs:**
```bash
railway logs --service langflow-server | tail -100
```

**Test the service:**
```bash
curl -I https://langflow.engarde.media
```

---

## 📝 What's in the Custom Image

### Branding Changes:

1. **Header Logo**
   - ❌ Removed: Langflow logo
   - ✅ Added: EnGarde logo (top-left)
   - File: `src/frontend/src/components/core/appHeaderComponent/index.tsx`

2. **Custom Footer**
   - ✅ Added: "From EnGarde with Love ❤️"
   - ✅ EnGarde logo included
   - Position: Fixed bottom-left
   - File: `src/frontend/src/components/core/engardeFooter/index.tsx`

3. **Assets**
   - ✅ EnGarde logo: `src/frontend/src/assets/EnGardeLogo.png`

---

## 🔍 Troubleshooting

### Issue: Docker Build Fails with Disk Space Error

**Solution:**
```bash
# Clean up Docker
docker system prune -af --volumes

# Check available space
df -h .

# If still low, clean up other files
cd /Users/cope/EnGardeHQ
rm -rf langflow-custom/node_modules
rm -rf */node_modules
```

---

### Issue: Docker Push Fails

**Error:** `unauthorized: authentication required`

**Solution:**
```bash
# Login to Docker Hub
docker login

# Verify login
docker info | grep Username
```

---

### Issue: Railway Can't Pull Image

**Error:** `failed to pull image`

**Solution 1: Make Repository Public**
1. Go to Docker Hub: https://hub.docker.com
2. Navigate to `langflowai/langflow-engarde`
3. Settings → Make Public

**Solution 2: Add Docker Hub Credentials to Railway**
1. Railway Dashboard → Project Settings
2. Add environment variables:
   - `DOCKER_HUB_USERNAME=your_username`
   - `DOCKER_HUB_PASSWORD=your_password`

---

### Issue: Image Too Large

**Error:** `image size exceeds limit`

**Current image size:** ~2.5GB

**Solution:** This is normal for Langflow. Railway supports images up to 10GB.

---

## 🎨 Alternative: Simplified Build

If disk space continues to be an issue, we can use a multi-stage build approach:

```dockerfile
# Dockerfile.engarde (simplified)
FROM langflowai/langflow:latest

# Copy only customized files
COPY src/frontend/src/assets/EnGardeLogo.png /app/src/backend/langflow/frontend/assets/
COPY src/frontend/src/components/core/appHeaderComponent/index.tsx /tmp/header.tsx
COPY src/frontend/src/components/core/engardeFooter/index.tsx /tmp/footer.tsx

# This would require a rebuild script, but saves space
```

---

## ✅ Verification Checklist

After deployment to Railway:

- [ ] Langflow accessible at https://langflow.engarde.media
- [ ] EnGarde logo appears in header (top-left)
- [ ] Footer shows "From EnGarde with Love ❤️" (bottom-left)
- [ ] No DataStax/Langflow branding visible
- [ ] Can create new flows
- [ ] Python Function nodes work
- [ ] All environment variables set

---

## 📊 Deployment Timeline

| Step | Duration | Status |
|------|----------|--------|
| Clean up Docker | 2-5 min | In progress |
| Rebuild image | 10-30 min | Pending |
| Push to Docker Hub | 5-15 min | Pending |
| Railway deployment | 5-10 min | Pending |
| **Total** | **22-60 min** | - |

---

## 🔄 Alternative: Use Existing Official Langflow + CSS Override

If Docker build continues to fail, we have a quick alternative:

**Use official Langflow image + CSS customization:**

1. Deploy official Langflow: `langflowai/langflow:latest`
2. Add custom CSS via browser extension (Stylus)
3. Inject EnGarde logo via custom header script

**This is a temporary solution** while we work on the Docker image.

---

## 📝 Next Steps

### After Docker Image is on Docker Hub:

1. **Configure Railway:**
   - Set Docker image to `langflowai/langflow-engarde:latest`
   - Deploy

2. **Verify branding:**
   - Check logo and footer

3. **Deploy all 10 agents:**
   - Follow `FINAL_ANSWERS_AND_INSTRUCTIONS.md`
   - 3 minutes per agent = 30 minutes total

4. **Set up environment variables:**
   - Production microservice URLs
   - BigQuery credentials
   - ZeroDB API keys
   - Walker agent API keys

---

## 🎉 Success Indicators

When everything works:

✅ **Docker Hub:**
- Image visible at https://hub.docker.com/r/langflowai/langflow-engarde
- Tag: `latest` and `v1.0.0`

✅ **Railway:**
- Service shows "Running"
- Logs show "Langflow started successfully"
- No errors in deployment logs

✅ **Langflow UI:**
- EnGarde logo in header
- Custom footer at bottom
- No DataStax branding

✅ **Functionality:**
- Can create flows
- Can paste agent code
- Agents execute successfully

---

**Waiting for Docker cleanup to complete, then we'll rebuild and push to Docker Hub! 🚀**
