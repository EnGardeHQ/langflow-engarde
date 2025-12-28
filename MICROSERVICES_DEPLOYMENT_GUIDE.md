# En Garde Microservices Deployment Guide

Complete guide for deploying Onside, Sankore, and Madan Sara microservices to Railway with GitHub subdirectory integration.

**Date:** December 24, 2024
**Version:** 1.0.0

---

## Overview

En Garde's intelligence layer consists of three specialized microservices:

1. **Onside** (Port 8001) - SEO Intelligence
2. **Madan Sara** (Port 8002) - Audience Conversion Intelligence
3. **Sankore** (Port 8003) - Paid Ads Intelligence

All services share:
- En Garde's PostgreSQL database
- ZeroDB memory layer for Walker agents
- Service mesh for inter-service communication

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Railway Platform                         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Onside     │  │  Madan Sara  │  │   Sankore    │      │
│  │  (SEO AI)    │  │(Conversion AI│  │ (Paid Ads AI)│      │
│  │  Port 8001   │  │  Port 8002   │  │  Port 8003   │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │               │
│         └──────────────────┴──────────────────┘               │
│                            │                                  │
│         ┌──────────────────┴──────────────────┐              │
│         │        Service Mesh Layer            │              │
│         │  - Service Discovery                 │              │
│         │  - Load Balancing                    │              │
│         │  - Circuit Breaking                  │              │
│         └──────────────────┬──────────────────┘              │
│                            │                                  │
│    ┌───────────────────────┴────────────────────┐            │
│    │         Shared Infrastructure               │            │
│    ├─────────────────────────────────────────────┤            │
│    │  PostgreSQL Database (Shared)               │            │
│    │  ZeroDB Memory Layer (Qdrant)               │            │
│    │  En Garde Core Application                  │            │
│    └─────────────────────────────────────────────┘            │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### 1. Install Railway CLI

```bash
# macOS
brew install railway

# npm
npm install -g @railway/cli

# Verify installation
railway --version
```

### 2. Install Git

```bash
# macOS
brew install git

# Verify
git --version
```

### 3. Railway Account Setup

1. Create account at https://railway.app
2. Create a new project: **EnGarde-Microservices**
3. Note your project ID

### 4. GitHub Repository Setup

```bash
# If not already done, create EnGardeHQ organization
# Structure:
EnGardeHQ/
├── Onside/              # SEO microservice
├── MadanSara/           # Conversion microservice
└── Sankore/             # Paid Ads microservice (to be created)
```

---

## Step 1: GitHub Subdirectory Setup

Railway supports GitHub subdirectory deployments, allowing multiple services from one repo.

### Option A: Separate Repositories (Recommended)

```bash
# Each service in its own repo
https://github.com/EnGardeHQ/Onside
https://github.com/EnGardeHQ/MadanSara
https://github.com/EnGardeHQ/Sankore
```

**Pros:**
- Clear separation
- Independent versioning
- Easier CI/CD

### Option B: Monorepo with Subdirectories

```bash
# Single repo with subdirectories
https://github.com/EnGardeHQ/Intelligence
├── /onside
├── /madan-sara
└── /sankore
```

**Pros:**
- Shared code easy
- Single repo to manage

For this guide, we use **Option A** (separate repos).

---

## Step 2: Database Setup

### Create Shared PostgreSQL Instance

```bash
# Login to Railway
railway login

# Link to your project
railway link

# Add PostgreSQL plugin
railway add postgresql

# Get database URL
railway variables get DATABASE_PUBLIC_URL

# Save this URL - all services will use it
```

### Environment Variable

All three services need:
```bash
ENGARDE_DATABASE_URL=<your-database-url>
```

---

## Step 3: ZeroDB Setup (Qdrant)

### Deploy Qdrant on Railway

```bash
# Add Qdrant from template
railway add qdrant

# Or use Qdrant Cloud
# https://cloud.qdrant.io

# Get Qdrant URL and API key
ZERODB_URL=<qdrant-url>
ZERODB_API_KEY=<qdrant-api-key>
```

### Initialize Collections

```bash
# Run this script to create collections
python scripts/init-zerodb-collections.py
```

---

## Step 4: Deploy Madan Sara

### 4.1 Prepare Repository

```bash
cd /Users/cope/EnGardeHQ/MadanSara

# Ensure Dockerfile and railway.json exist
ls Dockerfile railway.json

# Commit any changes
git add .
git commit -m "Prepare for Railway deployment"
git push origin main
```

### 4.2 Deploy to Railway

```bash
# Make deploy script executable
chmod +x scripts/deploy-railway.sh

# Run deployment
./scripts/deploy-railway.sh

# Follow prompts:
# 1. Select environment (production/staging)
# 2. Link to Railway project
# 3. Set environment variables
```

### 4.3 Configure Environment Variables

Required variables:
```bash
# Database
ENGARDE_DATABASE_URL=postgresql://...
DATABASE_PUBLIC_URL=postgresql://...

# ZeroDB
ZERODB_URL=http://zerodb:6333
ZERODB_API_KEY=your-key

# Service Mesh
SERVICE_MESH_SECRET=shared-secret-here
ONSIDE_URL=https://onside-production.up.railway.app
SANKORE_URL=https://sankore-production.up.railway.app
ENGARDE_CORE_URL=https://engarde-core.up.railway.app

# AI Services
ANTHROPIC_API_KEY=your-anthropic-key

# Email (via Walker SDK)
ENGARDE_API_KEY=your-engarde-key
ENGARDE_BASE_URL=https://api.engarde.com/v1

# Application
PORT=8002
ENVIRONMENT=production
```

### 4.4 Verify Deployment

```bash
# Check logs
railway logs

# Test health endpoint
curl https://madan-sara-production.up.railway.app/health

# Should return:
# {
#   "status": "healthy",
#   "service": "madan-sara",
#   "components": { ... }
# }
```

---

## Step 5: Deploy Onside

### 5.1 Navigate to Onside

```bash
cd /Users/cope/EnGardeHQ/production-frontend  # Or wherever Onside is
```

### 5.2 Add Railway Configuration

Create `railway.json`:
```json
{
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile"
  },
  "deploy": {
    "startCommand": "uvicorn app.main:app --host 0.0.0.0 --port $PORT",
    "healthcheckPath": "/health",
    "healthcheckTimeout": 100,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

Create `Dockerfile` (if not exists):
```dockerfile
FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8001

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001"]
```

### 5.3 Deploy

```bash
# Link to Railway
railway link

# Set environment variables (same as Madan Sara, but:)
railway variables set SERVICE_NAME=onside
railway variables set PORT=8001
railway variables set MADAN_SARA_URL=https://madan-sara-production.up.railway.app

# Deploy
railway up
```

---

## Step 6: Deploy Sankore

```bash
cd /Users/cope/EnGardeHQ/Sankore

# Same process as Onside
# PORT=8003
# SERVICE_NAME=sankore
```

---

## Step 7: Configure Service Mesh

### Update Each Service

Each service needs to know about the others:

**Madan Sara** .env:
```bash
ONSIDE_URL=https://onside-production.up.railway.app
SANKORE_URL=https://sankore-production.up.railway.app
ENGARDE_CORE_URL=https://engarde-core.up.railway.app
```

**Onside** .env:
```bash
MADAN_SARA_URL=https://madan-sara-production.up.railway.app
SANKORE_URL=https://sankore-production.up.railway.app
ENGARDE_CORE_URL=https://engarde-core.up.railway.app
```

**Sankore** .env:
```bash
ONSIDE_URL=https://onside-production.up.railway.app
MADAN_SARA_URL=https://madan-sara-production.up.railway.app
ENGARDE_CORE_URL=https://engarde-core.up.railway.app
```

### Set in Railway

```bash
# For each service:
railway variables set ONSIDE_URL=...
railway variables set MADAN_SARA_URL=...
railway variables set SANKORE_URL=...
```

---

## Step 8: Test Inter-Service Communication

### Test from Madan Sara

```bash
# SSH into Madan Sara
railway run bash

# Test calling Onside
curl http://onside:8001/health

# Test calling Sankore
curl http://sankore:8003/health
```

### Test Service Mesh

```python
# In Madan Sara
from app.core.service_mesh import get_service_mesh, ServiceName

mesh = get_service_mesh()

# Call Onside for SEO analysis
result = await mesh.call_service(
    ServiceName.ONSIDE,
    "/api/v1/seo/analyze",
    method="POST",
    data={"url": "https://example.com"}
)

print(result)
```

---

## Step 9: Configure GitHub Actions (Optional)

### Auto-deploy on Push

Create `.github/workflows/deploy.yml` in each repo:

```yaml
name: Deploy to Railway

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install Railway
        run: npm install -g @railway/cli

      - name: Deploy to Railway
        run: railway up
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```

---

## Step 10: Monitoring & Logging

### Railway Logs

```bash
# View logs for each service
railway logs --service madan-sara
railway logs --service onside
railway logs --service sankore

# Follow logs
railway logs -f --service madan-sara
```

### Health Checks

Each service has three health endpoints:

```bash
# General health
GET /health

# Kubernetes readiness
GET /health/ready

# Kubernetes liveness
GET /health/live
```

### Service Mesh Status

```bash
# Check service mesh status
curl https://madan-sara.railway.app/api/v1/system/service-mesh-status
```

---

## Step 11: Database Migrations

### Run Migrations for All Services

```bash
# Madan Sara
cd /Users/cope/EnGardeHQ/MadanSara
railway run alembic upgrade head

# Onside
cd /Users/cope/EnGardeHQ/Onside
railway run alembic upgrade head

# Sankore
cd /Users/cope/EnGardeHQ/Sankore
railway run alembic upgrade head
```

---

## Environment Variables Reference

### Shared Across All Services

```bash
# Database
ENGARDE_DATABASE_URL=postgresql://...
DATABASE_PUBLIC_URL=postgresql://...
DB_POOL_SIZE=5
DB_MAX_OVERFLOW=10
DB_POOL_TIMEOUT=30

# ZeroDB
ZERODB_URL=http://zerodb:6333
ZERODB_API_KEY=your-key

# Service Mesh
SERVICE_MESH_SECRET=shared-secret
SERVICE_MESH_TIMEOUT=30
CIRCUIT_BREAKER_THRESHOLD=5

# AI
ANTHROPIC_API_KEY=your-key

# En Garde Integration
ENGARDE_API_KEY=your-key
ENGARDE_BASE_URL=https://api.engarde.com/v1

# Application
ENVIRONMENT=production
LOG_LEVEL=INFO
```

### Service-Specific

**Madan Sara:**
```bash
SERVICE_NAME=madan-sara
PORT=8002
```

**Onside:**
```bash
SERVICE_NAME=onside
PORT=8001
```

**Sankore:**
```bash
SERVICE_NAME=sankore
PORT=8003
```

---

## Troubleshooting

### Database Connection Issues

```bash
# Test connection
railway run python -c "from app.core.engarde_db import check_db_connection; print(check_db_connection())"

# Check pool stats
railway run python -c "from app.core.engarde_db import get_db_stats; print(get_db_stats())"
```

### Service Mesh Issues

```bash
# Check service discovery
curl https://madan-sara.railway.app/health

# Check from another service
railway run --service onside curl http://madan-sara:8002/health
```

### ZeroDB Connection Issues

```bash
# Test ZeroDB
railway run python -c "from app.core.zerodb_integration import get_zerodb; import asyncio; asyncio.run(get_zerodb().store_memory('test', 'SHORT_TERM', 'test'))"
```

---

## Cost Optimization

### Railway Pricing

Each service:
- **Free tier:** $5/month credit
- **Hobby:** $5/service/month
- **Pro:** $20/service/month

For 3 services + PostgreSQL + Qdrant:
- **Hobby:** ~$25-30/month
- **Pro:** ~$100-120/month

### Optimization Tips

1. **Use Shared Database:** Don't create separate DB per service
2. **Optimize Connection Pools:** Set appropriate pool sizes
3. **Enable Auto-sleep:** For staging environments
4. **Use CDN:** For static assets
5. **Monitor Usage:** Track monthly costs

---

## Security Checklist

- [ ] All services use HTTPS
- [ ] Database credentials in environment variables (not code)
- [ ] Service mesh secret configured
- [ ] CORS properly configured
- [ ] API rate limiting enabled
- [ ] Logs don't contain sensitive data
- [ ] Database connection uses SSL
- [ ] ZeroDB API key secured

---

## Next Steps

1. **Set up monitoring:** Integrate Sentry or similar
2. **Configure alerts:** Railway alerts for downtime
3. **Set up backups:** Database backup schedule
4. **Load testing:** Test with production load
5. **Documentation:** API docs for each service
6. **CI/CD:** Automate deployments

---

## Support

- Railway Docs: https://docs.railway.app
- Railway Discord: https://discord.gg/railway
- En Garde Docs: [Internal]

---

**Deployment Complete!** 🚀

All three microservices are now running on Railway with shared database and ZeroDB integration.
