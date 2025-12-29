# EnGarde Custom Langflow

**Langflow with EnGarde branding - Ready for Docker Hub deployment**

---

## ✅ What's Customized

### 1. EnGarde Logo in Header
- **Location:** Top-left corner
- **File:** `src/frontend/src/components/core/appHeaderComponent/index.tsx`
- **Replaces:** Langflow logo

### 2. Custom Footer
- **Text:** "From EnGarde with Love ❤️"
- **Location:** Bottom-left corner (fixed position)
- **File:** `src/frontend/src/components/core/engardeFooter/index.tsx`

### 3. Branding Removed
- ❌ DataStax logo
- ❌ Langflow branding references

---

## 🚀 Deployment Status

### ✅ Code Ready - GitHub Repository

Custom Langflow with EnGarde branding is pushed to:
**https://github.com/EnGardeHQ/langflow-engarde**

### ⚠️ Local Docker Build Issue

The Docker image built successfully, but failed to unpack locally due to disk space constraints (99% full).

**Two deployment options available:**

### Option 1: Railway GitHub Deployment (Recommended)

Railway will build the Docker image on their infrastructure (no local disk space needed).

See detailed instructions in: `RAILWAY_GITHUB_DEPLOYMENT_SOLUTION.md`

**Quick steps:**
1. Railway Dashboard → langflow-server service → Settings
2. Source → GitHub Repository → `EnGardeHQ/langflow-engarde`
3. Set Dockerfile path: `docker/build_and_push.Dockerfile`
4. Click Deploy

### Option 2: Docker Hub via GitHub Actions

Use GitHub Actions to build and push to Docker Hub automatically.

See: `RAILWAY_GITHUB_DEPLOYMENT_SOLUTION.md` for setup instructions

---

## 📋 Manual Deployment Steps

### Step 1: Login to Docker Hub

```bash
docker login
```

### Step 2: Build Image

```bash
docker build \
  --tag langflowai/langflow-engarde:latest \
  --tag langflowai/langflow-engarde:v1.0.0 \
  --file docker/build_and_push.Dockerfile \
  .
```

### Step 3: Push to Docker Hub

```bash
docker push langflowai/langflow-engarde:latest
docker push langflowai/langflow-engarde:v1.0.0
```

---

## 🔧 Configure Railway

### Option A: Via Command Line

```bash
railway variables --service langflow-server --set RAILWAY_DOCKER_IMAGE=langflowai/langflow-engarde:latest
railway up
```

### Option B: Via Dashboard

1. Go to https://railway.app
2. Select project → `langflow-server` service
3. Settings → Source → Change Source
4. Select "Docker Image"
5. Enter: `langflowai/langflow-engarde:latest`
6. Click "Deploy"

---

## ✅ Verification

After deployment:

1. **Check URL:** https://langflow.engarde.media
2. **Verify branding:**
   - ✅ EnGarde logo in header (top-left)
   - ✅ Footer shows "From EnGarde with Love ❤️"
   - ❌ No DataStax/Langflow branding

3. **Test functionality:**
   - Create a new flow
   - Add Python Function node
   - Paste agent code
   - Run successfully

---

## 📁 Modified Files

```
src/frontend/
├── src/
│   ├── App.tsx (modified)
│   │   └── Added EnGardeFooter component
│   ├── components/core/
│   │   ├── appHeaderComponent/index.tsx (modified)
│   │   │   └── Replaced logo with EnGarde
│   │   └── engardeFooter/
│   │       └── index.tsx (new)
│   │           └── Custom footer component
│   └── assets/
│       └── EnGardeLogo.png (new)
```

---

## 🎯 Next Steps After Deployment

### 1. Set Production Environment Variables

```bash
# Microservice URLs
railway variables --service langflow-server --set ONSIDE_API_URL=https://onside-production.up.railway.app
railway variables --service langflow-server --set SANKORE_API_URL=https://sankore-production.up.railway.app
railway variables --service langflow-server --set MADANSARA_API_URL=https://madansara-production.up.railway.app

# See PRODUCTION_ENVIRONMENT_VARIABLES.md for all variables
```

### 2. Deploy All 10 Agents

Follow the guide in `/Users/cope/EnGardeHQ/FINAL_ANSWERS_AND_INSTRUCTIONS.md`

**Time estimate:** 30 minutes (3 min per agent)

**Agents to deploy:**
1. SEO Walker
2. Paid Ads Walker
3. Content Walker
4. Audience Intelligence Walker
5. Campaign Creation
6. Analytics Report
7. Content Approval
8. Campaign Launcher
9. Notification
10. Performance Monitoring

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| `README_ENGARDE.md` | This file - Quick start |
| `build-and-push-dockerhub.sh` | Automated deployment script |
| `DOCKER_HUB_DEPLOYMENT_GUIDE.md` | Detailed Docker Hub guide |
| `FINAL_ANSWERS_AND_INSTRUCTIONS.md` | Complete deployment reference |
| `LANGFLOW_COPY_PASTE_GUIDE.md` | How to paste agent code |
| `PRODUCTION_ENVIRONMENT_VARIABLES.md` | All environment variables |

---

## 🐛 Troubleshooting

### Build Fails with "No space left on device"

```bash
# Clean up Docker
docker system prune -af --volumes

# Check space
df -h .

# Rebuild
./build-and-push-dockerhub.sh
```

### Push Fails with "unauthorized"

```bash
# Re-login
docker login

# Verify
docker info | grep Username
```

### Railway Can't Pull Image

**Make repository public on Docker Hub:**
1. Go to https://hub.docker.com/r/langflowai/langflow-engarde
2. Settings → Make Public

---

## ⏱️ Build Time Estimates

| Task | Duration |
|------|----------|
| Docker build | 10-30 min |
| Push to Docker Hub | 5-15 min |
| Railway deployment | 5-10 min |
| **Total** | **20-55 min** |

---

## 🎉 What You'll Have

After following this guide:

✅ Custom Langflow with EnGarde branding on Docker Hub
✅ Deployed to Railway at https://langflow.engarde.media
✅ EnGarde logo in header
✅ Custom footer with love message
✅ Ready to deploy 10 production agents
✅ All Walker & EnGarde agents functional

---

## 🚀 Ready to Deploy!

**Run this command to start:**

```bash
cd /Users/cope/EnGardeHQ/langflow-custom
./build-and-push-dockerhub.sh
```

**Then follow the on-screen instructions!**

---

**Built with ❤️ by EnGarde**

🤖 *Generated with [Claude Code](https://claude.com/claude-code)*
