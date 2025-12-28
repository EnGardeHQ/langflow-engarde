# Quick Deploy Guide - En Garde Microservices

**One script to deploy all three microservices to Railway with GitHub auto-sync**

---

## What This Does

The `setup-all-microservices.sh` script will:

1. ✅ Set up **3 separate GitHub repositories**:
   - `EnGardeHQ/Onside` (SEO Intelligence)
   - `EnGardeHQ/MadanSara` (Conversion Intelligence)
   - `EnGardeHQ/Sankore` (Paid Ads Intelligence)

2. ✅ Create **3 separate Railway containers**:
   - One for each microservice
   - Auto-deploy on `git push` to main branch
   - Shared PostgreSQL database
   - Shared ZeroDB (Qdrant) memory layer

3. ✅ Configure **service mesh** for inter-service communication

4. ✅ Set up **auto-deploy from GitHub**:
   - Push code → GitHub → Railway webhook → Auto-deploy
   - No manual deployment needed after initial setup

---

## Prerequisites (Do These First!)

### 1. Create GitHub Repositories

Go to https://github.com/EnGardeHQ and create three empty repositories:

- [ ] `Onside`
- [ ] `MadanSara` (may already exist)
- [ ] `Sankore`

**Important:** Don't initialize with README, .gitignore, or license (keep them empty)

### 2. Install Railway CLI

```bash
# Option 1: npm
npm install -g @railway/cli

# Option 2: Homebrew
brew install railway

# Verify
railway --version
```

### 3. Login to Railway

```bash
railway login
# Opens browser for authentication
```

### 4. Create Railway Project

Go to https://railway.app and create a new project named: **EnGarde-Intelligence**

### 5. Add PostgreSQL to Railway

```bash
# In Railway dashboard, click "New" → "Database" → "PostgreSQL"
# Or via CLI:
railway add postgresql
```

### 6. Add Qdrant (ZeroDB) to Railway

```bash
# Option 1: Railway template
railway add qdrant

# Option 2: Use Qdrant Cloud
# Sign up at https://cloud.qdrant.io
```

### 7. Get Database URLs

```bash
railway variables get DATABASE_PUBLIC_URL
# Copy this URL - you'll need it during setup
```

---

## Running the Setup Script

### Step 1: Navigate to EnGardeHQ Directory

```bash
cd /Users/cope/EnGardeHQ
```

### Step 2: Run Setup Script

```bash
./setup-all-microservices.sh
```

### Step 3: Follow Prompts

The script will ask for:

1. **ENGARDE_DATABASE_URL**: PostgreSQL connection string from Railway
   ```
   Example: postgresql://postgres:password@host.railway.app:5432/railway
   ```

2. **ZERODB_URL**: Qdrant URL
   ```
   Example: http://qdrant:6333
   Or: https://xxx-xxx.qdrant.io
   ```

3. **ZERODB_API_KEY**: Qdrant API key (if using Qdrant Cloud)

4. **ANTHROPIC_API_KEY**: Your Claude API key
   ```
   Example: sk-ant-api03-xxxxx
   ```

5. **ENGARDE_API_KEY**: Your En Garde Walker SDK API key

6. **Environment**: `production` or `staging` (press Enter for production)

### Step 4: Wait for Deployment

The script will:
- ✓ Push code to GitHub (3 repos)
- ✓ Create Railway services (3 containers)
- ✓ Set environment variables
- ✓ Deploy all services
- ✓ Configure service mesh URLs

**Estimated time: 10-15 minutes**

---

## What Happens Automatically

### For Each Service:

```
┌──────────────┐
│ Local Files  │
└──────┬───────┘
       │ git push
       ↓
┌──────────────┐
│   GitHub     │ ← Separate repo for each service
└──────┬───────┘
       │ webhook
       ↓
┌──────────────┐
│   Railway    │ ← Detects push
└──────┬───────┘
       │ build
       ↓
┌──────────────┐
│   Docker     │ ← Builds container
└──────┬───────┘
       │ deploy
       ↓
┌──────────────┐
│     Live     │ ← Service running!
└──────────────┘
```

### Shared Infrastructure:

```
┌────────────────────────────────────┐
│     Railway Platform               │
│                                    │
│  ┌──────┐  ┌──────┐  ┌──────┐    │
│  │Onside│  │Madan │  │Sankore│   │
│  │:8001 │  │Sara  │  │:8003 │    │
│  │      │  │:8002 │  │      │    │
│  └───┬──┘  └───┬──┘  └───┬──┘    │
│      └─────────┼─────────┘        │
│                │                   │
│  ┌─────────────┴─────────────┐    │
│  │  PostgreSQL (Shared DB)   │    │
│  └───────────────────────────┘    │
│                                    │
│  ┌─────────────┬─────────────┐    │
│  │  Qdrant (ZeroDB Memory)   │    │
│  └───────────────────────────┘    │
└────────────────────────────────────┘
```

---

## After Setup - Testing

### 1. Initialize ZeroDB Collections

```bash
cd /Users/cope/EnGardeHQ/MadanSara
python scripts/init-zerodb-collections.py
```

Expected output:
```
✓ Connected to ZeroDB
✓ All collections ready for Walker agents
```

### 2. Test Health Endpoints

```bash
# Get URLs
cd /Users/cope/EnGardeHQ/Onside
ONSIDE_URL=$(cat .railway-url)

cd /Users/cope/EnGardeHQ/MadanSara
MADANSARA_URL=$(cat .railway-url)

cd /Users/cope/EnGardeHQ/Sankore
SANKORE_URL=$(cat .railway-url)

# Test health
curl $ONSIDE_URL/health
curl $MADANSARA_URL/health
curl $SANKORE_URL/health
```

Expected response:
```json
{
  "status": "healthy",
  "service": "madan-sara",
  "components": {
    "database": {"status": "healthy"},
    "service_mesh": {"status": "healthy"},
    "zerodb": {"status": "healthy"}
  }
}
```

### 3. Test Auto-Deploy

```bash
cd /Users/cope/EnGardeHQ/MadanSara

# Make a small change
echo "# Test auto-deploy" >> README.md

# Commit and push
git add .
git commit -m "Test auto-deploy"
git push origin main

# Watch Railway logs
railway logs -f
```

You should see:
```
✓ GitHub webhook received
✓ Building Docker image
✓ Deployment started
✓ Health check passed
✓ Deployment successful
```

### 4. View Railway Dashboard

```bash
railway open
```

This opens the Railway dashboard where you can see:
- All three services running
- Deployment history
- Logs for each service
- Environment variables
- Service URLs

---

## Understanding the GitHub → Railway Connection

### How Auto-Deploy Works

1. **You push to GitHub:**
   ```bash
   git push origin main
   ```

2. **GitHub sends webhook to Railway:**
   - Railway has a webhook configured for each repo
   - Webhook triggers on push to main branch

3. **Railway builds Docker image:**
   - Uses `Dockerfile` in repo root
   - Follows `railway.json` configuration
   - Installs dependencies
   - Runs tests (if configured)

4. **Railway deploys new version:**
   - Replaces old container with new one
   - Zero-downtime deployment
   - Automatic health checks

5. **Service goes live:**
   - New version accessible at same URL
   - Old version shut down
   - Logs available in Railway dashboard

### Which Files Trigger Rebuild?

✅ **Triggers deployment:**
- Any Python file in `app/`
- `requirements.txt`
- `Dockerfile`
- `railway.json`
- `.env` changes via Railway dashboard

❌ **Does NOT trigger deployment:**
- `README.md`
- Documentation files
- Comments in code
- `.github/` directory (unless you change workflows)

---

## Troubleshooting

### Script Fails at GitHub Push

**Problem:** `git push` fails with authentication error

**Solutions:**

1. **Set up GitHub CLI:**
   ```bash
   brew install gh
   gh auth login
   ```

2. **Or use SSH:**
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   cat ~/.ssh/id_ed25519.pub
   # Add to GitHub: Settings → SSH Keys → New SSH key
   ```

3. **Or use Personal Access Token:**
   ```bash
   # Create token at: https://github.com/settings/tokens
   # Use token as password when prompted
   ```

### Railway Deployment Fails

**Check logs:**
```bash
railway logs --service madan-sara
```

**Common issues:**
- Missing environment variables
- Database connection failed
- Port conflict
- Build timeout

**Solution:**
```bash
# Check environment variables
railway variables

# Check service status
railway status

# Redeploy
railway up
```

### Services Can't Communicate

**Problem:** Service mesh not working

**Check:**
```bash
# Verify all service URLs are set
cd /Users/cope/EnGardeHQ/MadanSara
railway variables get ONSIDE_URL
railway variables get SANKORE_URL

# Should return URLs, not empty
```

**Fix:**
```bash
# Manually set service URLs
railway variables set ONSIDE_URL=https://onside-production.up.railway.app
railway variables set SANKORE_URL=https://sankore-production.up.railway.app
```

---

## Managing Deployments

### View Logs

```bash
# Real-time logs
railway logs -f --service madan-sara

# Historical logs
railway logs --service madan-sara --lines 100
```

### Rollback Deployment

```bash
# In Railway dashboard:
# 1. Go to service
# 2. Click "Deployments"
# 3. Find previous successful deployment
# 4. Click "Redeploy"
```

### Update Environment Variables

```bash
# Set new variable
railway variables set NEW_VAR=value

# Requires redeploy (automatic if auto-deploy enabled)
```

### Scale Service

```bash
# In Railway dashboard:
# 1. Go to service
# 2. Click "Settings"
# 3. Adjust memory/CPU
# 4. Save (triggers redeploy)
```

---

## Cost Estimate

### Hobby Plan (~$25-30/month)
- Onside: $5/month
- Madan Sara: $5/month
- Sankore: $5/month
- PostgreSQL: $5/month
- Qdrant: $5-10/month

### Pro Plan (~$100-120/month)
- Each service: $20/month
- PostgreSQL: $20/month
- Qdrant: $20/month

---

## Next Steps After Deployment

### 1. Set Up Monitoring

Add to each service:
```bash
railway variables set SENTRY_DSN=your-sentry-dsn
```

### 2. Configure Custom Domains

```bash
railway domain add mydomain.com --service madan-sara
```

### 3. Set Up CI/CD

Add `.github/workflows/test.yml` to each repo:
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: pip install -r requirements-test.txt
      - run: pytest
```

### 4. Add Database Backups

```bash
# In Railway dashboard:
# PostgreSQL → Settings → Backups → Enable
```

---

## Summary

✅ **What You Get:**
- 3 microservices deployed to Railway
- 3 GitHub repos with auto-deploy
- Shared database and memory layer
- Service mesh for communication
- Production-ready infrastructure

✅ **How It Works:**
- Push to GitHub → Automatic deployment to Railway
- Each service in its own container
- All services share database and ZeroDB
- Services communicate via service mesh

✅ **Maintenance:**
- Update code: `git push` (auto-deploys)
- View logs: `railway logs`
- Monitor: Railway dashboard
- Scale: Adjust in Railway settings

---

**Ready to deploy? Run:**
```bash
cd /Users/cope/EnGardeHQ
./setup-all-microservices.sh
```
