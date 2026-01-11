# EnGarde Staging-to-Production Deployment Guide

**Last Updated:** January 9, 2026
**Version:** 2.0
**Status:** Production Ready

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Current Infrastructure](#current-infrastructure)
3. [Staging Environment Setup](#staging-environment-setup)
4. [Production Environment](#production-environment)
5. [Deployment Workflow](#deployment-workflow)
6. [Testing Checklist](#testing-checklist)
7. [Rollback Procedures](#rollback-procedures)
8. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### Current Stack
- **Backend:** Python FastAPI on Railway
- **Frontend:** Next.js on Vercel
- **Database:** PostgreSQL on Railway
- **AI/Workflow:** Langflow on Railway
- **Cache:** Redis on Railway

### Environment Strategy
```
┌─────────────────────────────────────────────────────────────┐
│                     Development                              │
│                  (Local Machine)                             │
│         Backend: localhost:8000                              │
│         Frontend: localhost:3000                             │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                      STAGING                                 │
│              (Main Copy Service)                             │
│         Backend: staging.engarde.media                       │
│         Frontend: staging-frontend.vercel.app                │
│         Database: Staging DB (separate)                      │
│                                                              │
│  Purpose: Test all changes before production                │
│  Audience: Internal team only                               │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼ (After Testing & Approval)
┌─────────────────────────────────────────────────────────────┐
│                     PRODUCTION                               │
│                  (Main Service)                              │
│         Backend: api.engarde.media                           │
│         Frontend: engarde.app                                │
│         Database: Production DB                              │
│                                                              │
│  Purpose: Live customer-facing application                  │
│  Audience: All users                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## Current Infrastructure

### Railway Services

| Service | Purpose | Environment | URL |
|---------|---------|-------------|-----|
| **Main** | Production Backend | Production | https://api.engarde.media |
| **Main Copy** | Staging Backend | Staging | https://staging.engarde.media |
| **Postgres** | Production Database | Production | Internal |
| **Postgres-Staging** | Staging Database | Staging | Internal (needs creation) |
| **Redis** | Cache (shared) | Both | Internal |
| **langflow-server** | AI Workflows | Production | Internal |
| **MySQL** | Legacy/Optional | N/A | Internal |

### Vercel Projects

| Project | Environment | Branch | URL |
|---------|-------------|--------|-----|
| **production-frontend** | Production | main | https://engarde.app |
| **production-frontend (preview)** | Staging | staging | https://staging-frontend.vercel.app |

---

## Staging Environment Setup

### Step 1: Configure "Main Copy" Backend Service

#### 1.1 Create Staging Database
```bash
# In Railway dashboard:
# 1. Create new PostgreSQL database named "Postgres-Staging"
# 2. Note the connection credentials
```

#### 1.2 Set Environment Variables for Main Copy

Link to the Main Copy service and configure:

```bash
railway link
# Select "Main Copy" service

railway variables set \
  ENVIRONMENT=staging \
  DATABASE_URL=$STAGING_DATABASE_URL \
  DATABASE_PUBLIC_URL=$STAGING_DATABASE_PUBLIC_URL \
  FRONTEND_URL=https://staging.engarde.media \
  CORS_ORIGINS='["https://staging.engarde.media","https://staging-frontend.vercel.app"]' \
  DEBUG_MODE=true \
  LOG_LEVEL=DEBUG \
  API_RATE_LIMIT_PER_MINUTE=1000
```

**Critical Staging Variables:**
```env
# Deployment
ENVIRONMENT=staging
PORT=8080

# Database (separate from production)
DATABASE_URL=postgresql://user:pass@staging-db-host:5432/engarde_staging
DATABASE_PUBLIC_URL=postgresql://user:pass@public-host:5432/engarde_staging

# Frontend Configuration
FRONTEND_URL=https://staging.engarde.media
CORS_ORIGINS=["https://staging.engarde.media","https://staging-frontend.vercel.app"]

# Security (use different keys from production)
SECRET_KEY=<staging-secret-key>
JWT_SECRET_KEY=<staging-jwt-secret>

# Feature Flags (enable experimental features)
ENABLE_EXPERIMENTAL_FEATURES=true
DEBUG_MODE=true
LOG_LEVEL=DEBUG

# Rate Limiting (more lenient for testing)
API_RATE_LIMIT_PER_MINUTE=1000

# External Services (use sandbox/test credentials)
STRIPE_SECRET_KEY=sk_test_...
OPENAI_API_KEY=<staging-openai-key>
ANTHROPIC_API_KEY=<staging-anthropic-key>

# Redis (can share with production or use separate)
REDIS_URL=redis://staging-redis:6379
```

#### 1.3 Configure Custom Domain
1. Go to Railway Dashboard → Main Copy service → Settings
2. Add custom domain: `staging.engarde.media`
3. Update DNS records as instructed by Railway
4. Wait for SSL certificate provisioning (5-10 minutes)

#### 1.4 Deploy Main Copy
```bash
# From production-backend directory
railway up --service "Main Copy"
```

### Step 2: Configure Staging Frontend on Vercel

#### 2.1 Create Staging Branch
```bash
cd /Users/cope/EnGardeHQ/production-frontend

# Create and push staging branch
git checkout -b staging
git push -u origin staging
```

#### 2.2 Configure Vercel Preview Deployment
```bash
# Install Vercel CLI if not already installed
npm i -g vercel

# Link to project
vercel link

# Set staging environment variables
vercel env add NEXT_PUBLIC_API_URL staging
# Enter: https://staging.engarde.media

vercel env add NEXT_PUBLIC_APP_ENV staging
# Enter: staging

vercel env add NEXTAUTH_URL staging
# Enter: https://staging-frontend.vercel.app

vercel env add NEXT_PUBLIC_ENABLE_AUTH_INIT_FIX staging
# Enter: true

vercel env add NEXT_PUBLIC_AUTH_FIX_ROLLOUT_PERCENTAGE staging
# Enter: 100

vercel env add NEXT_PUBLIC_ENABLE_DEVTOOLS staging
# Enter: true

vercel env add NEXT_PUBLIC_ENABLE_ANALYTICS staging
# Enter: false

vercel env add NEXT_PUBLIC_SENTRY_ENVIRONMENT staging
# Enter: staging
```

#### 2.3 Create Staging Vercel Configuration

Create `.vercel.staging.json`:
```json
{
  "buildCommand": "npm run build",
  "framework": "nextjs",
  "installCommand": "npm ci --legacy-peer-deps --include=dev",
  "outputDirectory": ".next",
  "devCommand": "npm run dev",
  "regions": ["iad1"],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        }
      ]
    }
  ],
  "rewrites": [
    {
      "source": "/api/token",
      "destination": "https://staging.engarde.media/api/token"
    },
    {
      "source": "/api/auth/:path*",
      "destination": "https://staging.engarde.media/api/auth/:path*"
    },
    {
      "source": "/api/:path*",
      "destination": "https://staging.engarde.media/api/:path*"
    }
  ],
  "env": {
    "NODE_ENV": "production",
    "NEXT_TELEMETRY_DISABLED": "1",
    "NEXT_PUBLIC_ENABLE_ANALYTICS": "false",
    "NEXT_PUBLIC_API_URL": "https://staging.engarde.media"
  }
}
```

#### 2.4 Configure Branch-Based Deployment

In Vercel Dashboard:
1. Go to Settings → Git → Branch Configuration
2. Set Production Branch: `main`
3. Enable Preview Deployments for `staging` branch
4. Set custom domain for staging: `staging-frontend.vercel.app` or custom domain

---

## Production Environment

### Production Backend (Main Service)

**Current Configuration:**
- Service: `Main` on Railway
- URL: https://api.engarde.media
- Database: Production PostgreSQL
- Branch: `main`

**Environment Variables:**
```env
ENVIRONMENT=production
DEBUG_MODE=false
LOG_LEVEL=INFO
DATABASE_URL=<production-db-url>
FRONTEND_URL=https://engarde.app
CORS_ORIGINS=["https://engarde.app","https://www.engarde.app"]
API_RATE_LIMIT_PER_MINUTE=100
```

### Production Frontend (Vercel)

**Current Configuration:**
- Project: `production-frontend`
- URL: https://engarde.app
- Branch: `main`
- Auto-deploy: Enabled

---

## Deployment Workflow

### Standard Development Workflow

```bash
┌─────────────────────────────────────────────────────────────┐
│ Step 1: Develop Locally                                     │
└─────────────────────────────────────────────────────────────┘
# Make changes in local environment
# Test locally with:
cd /Users/cope/EnGardeHQ/production-backend
docker-compose up  # Backend
cd /Users/cope/EnGardeHQ/production-frontend
npm run dev  # Frontend

┌─────────────────────────────────────────────────────────────┐
│ Step 2: Commit to Feature Branch                            │
└─────────────────────────────────────────────────────────────┘
git checkout -b feature/your-feature-name
git add .
git commit -m "feat: your feature description"
git push origin feature/your-feature-name

┌─────────────────────────────────────────────────────────────┐
│ Step 3: Merge to Staging Branch                             │
└─────────────────────────────────────────────────────────────┘
# Create PR to staging branch
# After review, merge to staging
git checkout staging
git merge feature/your-feature-name
git push origin staging

┌─────────────────────────────────────────────────────────────┐
│ Step 4: Deploy to Staging                                   │
└─────────────────────────────────────────────────────────────┘
# Backend (Main Copy)
cd /Users/cope/EnGardeHQ/production-backend
railway up --service "Main Copy" --environment staging

# Frontend (Vercel auto-deploys on staging branch push)
# Check deployment at: https://staging-frontend.vercel.app

┌─────────────────────────────────────────────────────────────┐
│ Step 5: Test in Staging                                     │
└─────────────────────────────────────────────────────────────┘
# Use testing checklist below
# Verify all functionality works
# Check logs for errors
railway logs --service "Main Copy"

┌─────────────────────────────────────────────────────────────┐
│ Step 6: Promote to Production                               │
└─────────────────────────────────────────────────────────────┘
# After successful staging testing
git checkout main
git merge staging --no-ff -m "chore: promote staging to production"
git push origin main

# Backend deploys automatically to Main service
# Frontend deploys automatically to engarde.app

┌─────────────────────────────────────────────────────────────┐
│ Step 7: Monitor Production                                  │
└─────────────────────────────────────────────────────────────┘
# Watch logs for issues
railway logs --service "Main" --follow

# Monitor error rates in Sentry (if configured)
# Check health endpoint
curl https://api.engarde.media/health
```

---

## Testing Checklist

### Pre-Deployment Checklist

Before deploying to staging, ensure:

- [ ] All unit tests pass locally
- [ ] No TypeScript errors
- [ ] Environment variables are set correctly
- [ ] Database migrations are tested
- [ ] Dependencies are up to date
- [ ] No hardcoded credentials
- [ ] Dockerfile builds successfully

### Staging Testing Checklist

Test these features in staging before promoting to production:

#### 1. Authentication & Authorization
- [ ] User login works
- [ ] User registration works
- [ ] JWT token refresh works
- [ ] Password reset flow works
- [ ] Session persistence works
- [ ] Logout works correctly
- [ ] Protected routes redirect properly

#### 2. Core Features
- [ ] Dashboard loads without errors
- [ ] Campaign creation works
- [ ] Brand management works
- [ ] Integration connections work
- [ ] AI agents respond correctly
- [ ] Workflow builder loads
- [ ] Analytics display correctly

#### 3. API Endpoints
```bash
# Test key endpoints
curl https://staging.engarde.media/health
# Should return: {"status":"running","version":"2.0.0"}

curl https://staging.engarde.media/api/v1/me \
  -H "Authorization: Bearer $TOKEN"
# Should return user data

# Test CORS
curl -I https://staging.engarde.media/api/v1/health \
  -H "Origin: https://staging-frontend.vercel.app"
# Should include Access-Control-Allow-Origin header
```

#### 4. Database
- [ ] Migrations applied successfully
- [ ] Seed data present (if applicable)
- [ ] Queries executing properly
- [ ] Connection pooling working
- [ ] No connection leaks

#### 5. Frontend
- [ ] All pages load without errors
- [ ] No console errors
- [ ] Images load correctly
- [ ] API calls succeed
- [ ] Error boundaries catch errors
- [ ] Mobile responsive design works
- [ ] Browser compatibility (Chrome, Firefox, Safari)

#### 6. Performance
- [ ] Page load time < 3 seconds
- [ ] API response time < 500ms
- [ ] No memory leaks
- [ ] Database queries optimized
- [ ] Images optimized
- [ ] Bundle size reasonable

#### 7. Security
- [ ] HTTPS enabled
- [ ] CORS configured correctly
- [ ] Rate limiting works
- [ ] SQL injection protected
- [ ] XSS protected
- [ ] CSRF tokens working

### Production Smoke Tests

After deploying to production, immediately test:

1. **Critical Path** (5 minutes)
   - Login → Dashboard → Create Campaign → Logout

2. **Health Checks**
   ```bash
   curl https://api.engarde.media/health
   curl https://engarde.app/api/health
   ```

3. **Error Monitoring**
   - Check Sentry for new errors
   - Check Railway logs for crashes
   ```bash
   railway logs --service Main --tail 50
   ```

---

## Rollback Procedures

### Emergency Rollback (If Production Breaks)

#### Option 1: Rollback via Railway Dashboard
1. Go to Railway Dashboard → Main service
2. Click "Deployments" tab
3. Find last working deployment
4. Click "Redeploy" on that deployment
5. Monitor logs to confirm rollback successful

#### Option 2: Rollback via Git
```bash
# Backend
cd /Users/cope/EnGardeHQ/production-backend
git checkout main
git revert HEAD --no-edit  # Revert last commit
git push origin main
# Railway auto-deploys

# Frontend
cd /Users/cope/EnGardeHQ/production-frontend
git checkout main
git revert HEAD --no-edit  # Revert last commit
git push origin main
# Vercel auto-deploys
```

#### Option 3: Instant Rollback via CLI
```bash
# Backend
railway rollback --service Main

# Frontend (use Vercel CLI)
vercel rollback
```

### Database Rollback

If database migration breaks production:

```bash
# Connect to production database
railway connect Postgres

# Rollback last migration
alembic downgrade -1

# Or rollback to specific version
alembic downgrade <revision_id>

# Verify database state
alembic current
```

---

## Troubleshooting

### Issue: Staging shows backend API JSON instead of frontend

**Cause:** Frontend not configured or domain pointing to wrong service

**Fix:**
1. Check that `staging.engarde.media` points to Main Copy backend
2. Create separate frontend staging deployment on Vercel
3. Use `staging-frontend.vercel.app` for frontend access
4. Update backend CORS to allow staging frontend domain

### Issue: CORS errors in staging

**Cause:** Staging frontend URL not in CORS_ORIGINS

**Fix:**
```bash
railway variables set CORS_ORIGINS='["https://staging.engarde.media","https://staging-frontend.vercel.app"]' --service "Main Copy"
```

### Issue: Database migration fails in staging

**Cause:** Migration conflicts or schema issues

**Fix:**
```bash
# Check current migration state
railway run --service "Main Copy" alembic current

# Reset to base and re-run
railway run --service "Main Copy" alembic downgrade base
railway run --service "Main Copy" alembic upgrade head
```

### Issue: Environment variables not loading

**Cause:** Railway cache or variable not set

**Fix:**
```bash
# Clear Railway cache
railway run --service "Main Copy" "printenv | grep DATABASE"

# Verify variables are set
railway variables --service "Main Copy"

# Force rebuild
railway up --service "Main Copy" --detach
```

### Issue: 502 Bad Gateway

**Cause:** Service crashed or health check failing

**Fix:**
```bash
# Check logs
railway logs --service "Main Copy" --tail 100

# Check health endpoint
curl -v https://staging.engarde.media/health

# Restart service
railway restart --service "Main Copy"
```

---

## Quick Reference Commands

### Railway Commands
```bash
# View all services
railway status

# Link to Main Copy
railway link --service "Main Copy"

# View logs
railway logs --service "Main Copy" --follow

# Deploy
railway up --service "Main Copy"

# Set variable
railway variables set KEY=value --service "Main Copy"

# View variables
railway variables --service "Main Copy"

# Connect to database
railway connect Postgres-Staging
```

### Vercel Commands
```bash
# Deploy to staging
vercel --prod --scope staging

# Set environment variable
vercel env add VARIABLE_NAME staging

# View deployments
vercel ls

# Rollback
vercel rollback
```

### Git Workflow
```bash
# Update staging
git checkout staging
git pull origin main  # Sync with main if needed
git push origin staging

# Promote to production
git checkout main
git merge staging --no-ff
git push origin main
```

---

## Maintenance Schedule

### Daily
- Monitor error rates in staging and production
- Check Railway logs for anomalies
- Review Sentry errors (if configured)

### Weekly
- Update dependencies in staging first
- Test new features in staging
- Review and clean up old deployments

### Monthly
- Database backup verification
- Security updates
- Performance optimization review
- Cost optimization review

---

## Support & Resources

### Documentation
- Railway Docs: https://docs.railway.app
- Vercel Docs: https://vercel.com/docs
- EnGarde Backend API: https://api.engarde.media/docs

### Team Contacts
- DevOps Lead: [Your Name]
- Backend Team: [Contact]
- Frontend Team: [Contact]

### Emergency Contacts
- On-call Engineer: [Phone/Slack]
- Database Admin: [Contact]
- Railway Support: support@railway.app

---

**Document Version:** 2.0
**Last Review:** January 9, 2026
**Next Review:** February 9, 2026
