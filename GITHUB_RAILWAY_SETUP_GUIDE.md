# GitHub + Railway Setup for En Garde Microservices

Complete guide for setting up GitHub repositories and Railway deployments for all three intelligence microservices.

**Date:** December 24, 2024

---

## Two Deployment Strategies

### Strategy 1: Separate Repositories (Recommended)
**Best for:** Independent versioning, clear separation, easier CI/CD

```
EnGardeHQ/
├── Onside/          → Railway Service: onside
├── MadanSara/       → Railway Service: madan-sara
└── Sankore/         → Railway Service: sankore
```

### Strategy 2: Monorepo with Subdirectories
**Best for:** Shared code, single repo management, coordinated releases

```
EnGardeHQ/Intelligence/
├── onside/          → Railway Service: onside
├── madan-sara/      → Railway Service: madan-sara
└── sankore/         → Railway Service: sankore
```

---

## Strategy 1: Separate Repositories Setup

### Step 1: Create GitHub Repositories

```bash
# Navigate to EnGardeHQ directory
cd /Users/cope/EnGardeHQ

# 1. MadanSara (already exists)
cd MadanSara
git init
git add .
git commit -m "Initial commit - Madan Sara microservice"
git branch -M main
git remote add origin https://github.com/EnGardeHQ/MadanSara.git
git push -u origin main

# 2. Create Onside repo (if not already)
cd ../Onside
git init
git add .
git commit -m "Initial commit - Onside SEO microservice"
git branch -M main
git remote add origin https://github.com/EnGardeHQ/Onside.git
git push -u origin main

# 3. Create Sankore repo
cd ../Sankore
git init
git add .
git commit -m "Initial commit - Sankore Paid Ads microservice"
git branch -M main
git remote add origin https://github.com/EnGardeHQ/Sankore.git
git push -u origin main
```

### Step 2: Deploy Each Service to Railway

#### Deploy Madan Sara

```bash
cd /Users/cope/EnGardeHQ/MadanSara

# Login to Railway
railway login

# Create new service or link existing
railway init

# Name: madan-sara
# Link to GitHub repo: EnGardeHQ/MadanSara
# Branch: main

# Set environment variables
railway variables set SERVICE_NAME=madan-sara
railway variables set PORT=8002
railway variables set ENVIRONMENT=production

# Enable GitHub deployments
railway domain  # This will give you a URL

# Deploy
railway up

# Enable auto-deploy on git push
# (Done automatically when linked to GitHub)
```

#### Deploy Onside

```bash
cd /Users/cope/EnGardeHQ/Onside

railway login
railway init

# Name: onside
# Link to GitHub repo: EnGardeHQ/Onside
# Branch: main

railway variables set SERVICE_NAME=onside
railway variables set PORT=8001
railway variables set ENVIRONMENT=production

railway up
```

#### Deploy Sankore

```bash
cd /Users/cope/EnGardeHQ/Sankore

railway login
railway init

# Name: sankore
# Link to GitHub repo: EnGardeHQ/Sankore
# Branch: main

railway variables set SERVICE_NAME=sankore
railway variables set PORT=8003
railway variables set ENVIRONMENT=production

railway up
```

### Step 3: Configure Auto-Deploy

Each repo will auto-deploy to Railway when you push to GitHub:

```bash
# In any repo
git add .
git commit -m "Update feature"
git push origin main

# Railway automatically:
# 1. Detects the push
# 2. Pulls latest code
# 3. Builds Docker container
# 4. Deploys to production
# 5. Runs health checks
```

---

## Strategy 2: Monorepo Setup

### Step 1: Create Monorepo Structure

```bash
cd /Users/cope/EnGardeHQ

# Create Intelligence monorepo
mkdir -p Intelligence
cd Intelligence

# Copy services into subdirectories
mkdir -p onside madan-sara sankore

# Copy Madan Sara
cp -r ../MadanSara/* madan-sara/

# Copy Onside (adjust path as needed)
cp -r ../Onside/* onside/

# Copy Sankore (adjust path as needed)
cp -r ../Sankore/* sankore/

# Initialize git
git init
git add .
git commit -m "Initial commit - En Garde Intelligence microservices"
git branch -M main
git remote add origin https://github.com/EnGardeHQ/Intelligence.git
git push -u origin main
```

### Step 2: Create Root Directory Configuration

Create `Intelligence/railway.services.json`:

```json
{
  "services": [
    {
      "name": "onside",
      "root": "onside",
      "build": {
        "builder": "DOCKERFILE",
        "dockerfilePath": "Dockerfile"
      },
      "deploy": {
        "startCommand": "uvicorn app.main:app --host 0.0.0.0 --port $PORT"
      }
    },
    {
      "name": "madan-sara",
      "root": "madan-sara",
      "build": {
        "builder": "DOCKERFILE",
        "dockerfilePath": "Dockerfile"
      },
      "deploy": {
        "startCommand": "uvicorn app.main:app --host 0.0.0.0 --port $PORT"
      }
    },
    {
      "name": "sankore",
      "root": "sankore",
      "build": {
        "builder": "DOCKERFILE",
        "dockerfilePath": "Dockerfile"
      },
      "deploy": {
        "startCommand": "uvicorn app.main:app --host 0.0.0.0 --port $PORT"
      }
    }
  ]
}
```

### Step 3: Deploy from Monorepo

#### Deploy Madan Sara from Subdirectory

```bash
cd /Users/cope/EnGardeHQ/Intelligence

railway login
railway init

# Create service: madan-sara
# Link to GitHub: EnGardeHQ/Intelligence
# Set root directory: madan-sara

# Using Railway CLI
railway service create madan-sara

# Link to GitHub repo
railway link

# Set root directory
railway variables set RAILWAY_ROOT_DIR=madan-sara

# Set other variables
railway variables set SERVICE_NAME=madan-sara
railway variables set PORT=8002

# Deploy
railway up --service madan-sara
```

#### Deploy Onside from Subdirectory

```bash
# From same Intelligence directory
railway service create onside
railway variables set RAILWAY_ROOT_DIR=onside
railway variables set SERVICE_NAME=onside
railway variables set PORT=8001
railway up --service onside
```

#### Deploy Sankore from Subdirectory

```bash
railway service create sankore
railway variables set RAILWAY_ROOT_DIR=sankore
railway variables set SERVICE_NAME=sankore
railway variables set PORT=8003
railway up --service sankore
```

### Step 4: Auto-Deploy from Monorepo

When you push to the monorepo:

```bash
cd /Users/cope/EnGardeHQ/Intelligence

# Make changes to any service
vim madan-sara/app/main.py

git add .
git commit -m "Update Madan Sara"
git push origin main

# Railway will:
# 1. Detect which subdirectory changed
# 2. Only rebuild affected service
# 3. Deploy that service
```

---

## Comparison: Separate Repos vs Monorepo

### Separate Repositories

**Pros:**
- ✅ Clear separation of concerns
- ✅ Independent versioning (v1.0 for Onside, v2.0 for Madan Sara)
- ✅ Smaller repo size per service
- ✅ Easier to set different permissions per service
- ✅ Simpler CI/CD (one repo = one service)
- ✅ Can have different teams owning different services

**Cons:**
- ❌ Shared code requires npm packages or git submodules
- ❌ Cross-service changes require multiple PRs
- ❌ More repos to manage

**Recommended for:** Production deployments, larger teams

### Monorepo

**Pros:**
- ✅ Easy to share code between services
- ✅ Atomic commits across services
- ✅ Single PR for cross-service changes
- ✅ Easier to keep dependencies in sync
- ✅ Single place for all documentation

**Cons:**
- ❌ Larger repo size
- ❌ All services use same version tags
- ❌ Requires careful CI/CD configuration
- ❌ All team members see all service code

**Recommended for:** Tight coupling between services, smaller teams

---

## Railway CLI Commands Reference

### Initial Setup

```bash
# Install Railway CLI
npm install -g @railway/cli
# or
brew install railway

# Login
railway login

# Link to existing project
railway link

# Or create new project
railway init
```

### Service Management

```bash
# Create new service
railway service create <service-name>

# List services
railway service list

# Switch service
railway service <service-name>

# Delete service
railway service delete <service-name>
```

### Deployment

```bash
# Deploy current directory
railway up

# Deploy specific service
railway up --service <service-name>

# Deploy with detach (don't wait)
railway up --detach

# Deploy specific environment
railway up --environment production
```

### Environment Variables

```bash
# Set variable
railway variables set KEY=value

# Set for specific environment
railway variables set KEY=value --environment production

# Get variable
railway variables get KEY

# List all variables
railway variables

# Delete variable
railway variables delete KEY
```

### Monitoring

```bash
# View logs
railway logs

# Follow logs
railway logs -f

# Logs for specific service
railway logs --service <service-name>

# View status
railway status

# Open Railway dashboard
railway open
```

### GitHub Integration

```bash
# Connect to GitHub repo
railway github connect

# Disconnect from GitHub
railway github disconnect

# Trigger deployment from GitHub
# (Automatic on git push when connected)
```

---

## Recommended Workflow: Separate Repositories

Based on your requirements, I recommend **Strategy 1: Separate Repositories**. Here's why:

1. **Already Exists:** MadanSara is already a separate repo
2. **Independence:** Each intelligence layer can evolve independently
3. **Clear Ownership:** Different teams can own different services
4. **Railway Native:** Railway works best with separate repos

### Complete Setup Steps

```bash
# ============================================
# 1. Ensure all repos are created on GitHub
# ============================================

# MadanSara (already exists)
cd /Users/cope/EnGardeHQ/MadanSara
git remote -v  # Should show EnGardeHQ/MadanSara

# Onside
cd /Users/cope/EnGardeHQ/Onside
git init
git remote add origin https://github.com/EnGardeHQ/Onside.git
git add .
git commit -m "Initial commit - Onside SEO Intelligence"
git push -u origin main

# Sankore (create first)
cd /Users/cope/EnGardeHQ
# Copy structure from MadanSara as template
cp -r MadanSara Sankore
cd Sankore
# Update all references from madan-sara to sankore
# ... make necessary changes ...
git init
git remote add origin https://github.com/EnGardeHQ/Sankore.git
git add .
git commit -m "Initial commit - Sankore Paid Ads Intelligence"
git push -u origin main

# ============================================
# 2. Deploy to Railway (one at a time)
# ============================================

# Deploy MadanSara
cd /Users/cope/EnGardeHQ/MadanSara
railway login
railway init  # Link to EnGardeHQ/MadanSara
./scripts/deploy-railway.sh

# Deploy Onside
cd /Users/cope/EnGardeHQ/Onside
railway login
railway init  # Link to EnGardeHQ/Onside
./scripts/deploy-railway.sh  # (create this script in Onside)

# Deploy Sankore
cd /Users/cope/EnGardeHQ/Sankore
railway login
railway init  # Link to EnGardeHQ/Sankore
./scripts/deploy-railway.sh  # (create this script in Sankore)

# ============================================
# 3. Configure GitHub Auto-Deploy
# ============================================

# For each service, Railway will auto-detect GitHub pushes
# No additional configuration needed!

# Test auto-deploy:
cd /Users/cope/EnGardeHQ/MadanSara
echo "# Test" >> README.md
git add README.md
git commit -m "Test auto-deploy"
git push origin main

# Railway will automatically:
# ✓ Detect push
# ✓ Build Docker image
# ✓ Deploy to production
# ✓ Run health checks
# ✓ Notify via webhook (optional)
```

---

## Auto-Deploy Verification

After setup, verify auto-deploy is working:

### Check Railway Dashboard

```bash
railway open
# In browser, verify:
# ✓ GitHub repo is connected
# ✓ Auto-deploy is enabled
# ✓ Latest commit shows in deployments
```

### Test Deploy

```bash
# Make a small change
cd /Users/cope/EnGardeHQ/MadanSara
echo "# Updated $(date)" >> README.md
git add .
git commit -m "Test auto-deploy"
git push origin main

# Watch deployment
railway logs -f

# Should see:
# ✓ GitHub webhook received
# ✓ Building Docker image
# ✓ Deployment started
# ✓ Health check passed
# ✓ Deployment successful
```

---

## Shared Environment Variables Setup

All three services need the same core environment variables. Set these once for each service:

```bash
# Create shared-env.txt with common variables
cat > shared-env.txt << 'EOF'
ENGARDE_DATABASE_URL=postgresql://...
ZERODB_URL=http://...
ZERODB_API_KEY=...
SERVICE_MESH_SECRET=...
ANTHROPIC_API_KEY=...
ENGARDE_API_KEY=...
ENGARDE_BASE_URL=https://api.engarde.com/v1
ENVIRONMENT=production
EOF

# Set for MadanSara
cd /Users/cope/EnGardeHQ/MadanSara
while IFS='=' read -r key value; do
  railway variables set "$key=$value"
done < ../shared-env.txt
railway variables set SERVICE_NAME=madan-sara
railway variables set PORT=8002

# Set for Onside
cd /Users/cope/EnGardeHQ/Onside
while IFS='=' read -r key value; do
  railway variables set "$key=$value"
done < ../shared-env.txt
railway variables set SERVICE_NAME=onside
railway variables set PORT=8001

# Set for Sankore
cd /Users/cope/EnGardeHQ/Sankore
while IFS='=' read -r key value; do
  railway variables set "$key=$value"
done < ../shared-env.txt
railway variables set SERVICE_NAME=sankore
railway variables set PORT=8003

# Clean up
rm ../shared-env.txt
```

---

## GitHub Actions for CI/CD (Optional)

Add `.github/workflows/deploy.yml` to each repo for advanced CI/CD:

```yaml
name: Deploy to Railway

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install -r requirements-test.txt

      - name: Run tests
        run: pytest

      - name: Run linters
        run: |
          flake8 app/
          black --check app/

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v3

      - name: Install Railway CLI
        run: npm install -g @railway/cli

      - name: Deploy to Railway
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
        run: railway up
```

---

## Summary

### Recommended: Separate Repositories ✅

**GitHub Structure:**
```
EnGardeHQ/Onside       → railway.app/onside
EnGardeHQ/MadanSara    → railway.app/madan-sara
EnGardeHQ/Sankore      → railway.app/sankore
```

**Auto-Deploy Flow:**
```
Developer → git push → GitHub → Webhook → Railway → Docker Build → Deploy → Health Check → Live
```

**Benefits:**
- ✅ Each service deploys independently
- ✅ Railway auto-detects GitHub pushes
- ✅ No manual deployment needed after initial setup
- ✅ Each service has its own logs, metrics, and domain
- ✅ Rollback is per-service
- ✅ Clear separation of concerns

**Next Steps:**
1. Run the setup commands above
2. Verify auto-deploy works for each service
3. Set up shared environment variables
4. Test inter-service communication

---

**Ready to execute! Which strategy do you prefer?**
