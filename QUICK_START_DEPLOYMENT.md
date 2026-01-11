# EnGarde Quick Start Deployment Guide

**TL;DR:** Deploy safely with staging → production workflow

## Prerequisites

Install required tools:
```bash
# Railway CLI
npm install -g @railway/cli

# Vercel CLI
npm install -g vercel

# Login to Railway
railway login

# Login to Vercel
vercel login
```

## One-Time Setup (Do This Once)

### 1. Create Staging Branch

```bash
# Backend
cd /Users/cope/EnGardeHQ/production-backend
git checkout -b staging
git push -u origin staging

# Frontend
cd /Users/cope/EnGardeHQ/production-frontend
git checkout -b staging
git push -u origin staging
```

### 2. Configure Railway "Main Copy" for Staging

```bash
cd /Users/cope/EnGardeHQ/production-backend
railway link
# Select "Main Copy" service

# Set staging environment variables
railway variables set ENVIRONMENT=staging
railway variables set FRONTEND_URL=https://staging.engarde.media
railway variables set CORS_ORIGINS='["https://staging.engarde.media","https://staging-frontend.vercel.app"]'
railway variables set DEBUG_MODE=true
railway variables set LOG_LEVEL=DEBUG

# Add custom domain in Railway dashboard:
# Railway Dashboard → Main Copy → Settings → Custom Domain
# Add: staging.engarde.media
```

### 3. Configure Vercel Staging Environment

```bash
cd /Users/cope/EnGardeHQ/production-frontend

# Set staging environment variables
vercel env add NEXT_PUBLIC_API_URL staging
# Enter: https://staging.engarde.media

vercel env add NEXT_PUBLIC_APP_ENV staging
# Enter: staging

vercel env add NEXTAUTH_URL staging
# Enter: https://staging-frontend.vercel.app

vercel env add NEXT_PUBLIC_ENABLE_DEVTOOLS staging
# Enter: true

# In Vercel Dashboard:
# Settings → Git → Set staging branch for preview deployments
```

## Daily Workflow

### Step 1: Make Changes Locally

```bash
# Create feature branch
git checkout -b feature/my-new-feature

# Make your changes...
# Test locally:
# Backend: docker-compose up
# Frontend: npm run dev

# Commit changes
git add .
git commit -m "feat: add new feature"
```

### Step 2: Deploy to Staging (Test First!)

```bash
# Merge to staging branch
git checkout staging
git merge feature/my-new-feature
git push origin staging

# Deploy using automated script
cd /Users/cope/EnGardeHQ
./deploy-to-staging.sh all
```

**What happens:**
- Backend deploys to: https://staging.engarde.media
- Frontend deploys to: https://staging-frontend.vercel.app
- Health checks run automatically

### Step 3: Test in Staging

Open https://staging-frontend.vercel.app and test:
- [ ] Login works
- [ ] Dashboard loads
- [ ] Your new feature works
- [ ] No console errors
- [ ] Check logs: `railway logs --service "Main Copy"`

### Step 4: Promote to Production (When Ready)

```bash
# Automated promotion script
cd /Users/cope/EnGardeHQ
./promote-to-production.sh
```

**What happens:**
- Backs up current production
- Merges staging → main
- Deploys to production automatically
- Runs health checks
- Shows rollback commands if needed

## URLs & Monitoring

### Staging
- **Frontend:** https://staging-frontend.vercel.app
- **Backend:** https://staging.engarde.media
- **Health:** https://staging.engarde.media/health
- **Logs:** `railway logs --service "Main Copy" --follow`

### Production
- **Frontend:** https://engarde.app
- **Backend:** https://api.engarde.media
- **Health:** https://api.engarde.media/health
- **Logs:** `railway logs --service Main --follow`

## Troubleshooting

### Staging shows {"message":"EnGarde Backend API"...}
**Issue:** Frontend not deployed or domain pointing to backend

**Fix:**
- Access frontend at: https://staging-frontend.vercel.app
- NOT at: https://staging.engarde.media (that's the backend)

## Support

- **Full Guide:** See STAGING_TO_PRODUCTION_DEPLOYMENT_GUIDE.md
- **Deployment Scripts:**
  - `./deploy-to-staging.sh`
  - `./promote-to-production.sh`
