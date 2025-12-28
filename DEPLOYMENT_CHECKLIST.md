# Deployment Checklist - En Garde Microservices

Use this checklist before running `./setup-all-microservices.sh`

---

## Pre-Deployment Checklist

### GitHub Setup
- [ ] GitHub organization created: `EnGardeHQ`
- [ ] Empty repository created: `EnGardeHQ/Onside`
- [ ] Empty repository created: `EnGardeHQ/MadanSara`
- [ ] Empty repository created: `EnGardeHQ/Sankore`
- [ ] GitHub authentication configured (SSH or Personal Access Token)
- [ ] You have push access to all three repos

**Test:**
```bash
gh auth status
# or
ssh -T git@github.com
```

---

### Railway Setup
- [ ] Railway account created at https://railway.app
- [ ] Railway CLI installed (`railway --version` works)
- [ ] Logged into Railway CLI (`railway whoami` shows your account)
- [ ] New project created in Railway: `EnGarde-Intelligence`
- [ ] PostgreSQL database added to Railway project
- [ ] Database URL obtained and saved

**Test:**
```bash
railway whoami
railway variables get DATABASE_PUBLIC_URL
```

---

### ZeroDB (Qdrant) Setup
- [ ] Qdrant added to Railway project OR Qdrant Cloud account created
- [ ] Qdrant URL obtained
- [ ] Qdrant API key obtained (if using Qdrant Cloud)

**Test:**
```bash
railway variables get ZERODB_URL
# or test Qdrant Cloud URL
curl https://your-instance.qdrant.io/collections
```

---

### API Keys Ready
- [ ] Anthropic (Claude) API key: `sk-ant-api03-...`
- [ ] En Garde API key: `your-engarde-key`
- [ ] All keys tested and valid

**Test Claude API:**
```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":10,"messages":[{"role":"user","content":"Hi"}]}'
```

---

### Local Environment
- [ ] All three service directories exist:
  - [ ] `/Users/cope/EnGardeHQ/Onside`
  - [ ] `/Users/cope/EnGardeHQ/MadanSara`
  - [ ] `/Users/cope/EnGardeHQ/Sankore`
- [ ] Each directory has required files:
  - [ ] `Dockerfile`
  - [ ] `railway.json`
  - [ ] `requirements.txt`
  - [ ] `app/main.py`
  - [ ] `app/core/engarde_db.py`
  - [ ] `app/core/zerodb_integration.py`
  - [ ] `app/core/service_mesh.py`

**Check:**
```bash
ls -la /Users/cope/EnGardeHQ/Onside/Dockerfile
ls -la /Users/cope/EnGardeHQ/MadanSara/Dockerfile
ls -la /Users/cope/EnGardeHQ/Sankore/Dockerfile
```

---

### Information to Have Ready

When running the script, you'll need:

```bash
# Database
ENGARDE_DATABASE_URL=postgresql://postgres:___@___.railway.app:5432/railway

# Qdrant
ZERODB_URL=http://qdrant:6333
ZERODB_API_KEY=your-qdrant-key

# AI
ANTHROPIC_API_KEY=sk-ant-api03-___

# En Garde
ENGARDE_API_KEY=your-engarde-key

# Environment
ENVIRONMENT=production
```

**Save these in a temporary file (DO NOT COMMIT):**
```bash
cat > /tmp/env-vars.txt << 'EOF'
ENGARDE_DATABASE_URL=postgresql://...
ZERODB_URL=http://...
ZERODB_API_KEY=...
ANTHROPIC_API_KEY=sk-ant-...
ENGARDE_API_KEY=...
EOF

# Use for reference during setup
cat /tmp/env-vars.txt

# Delete after setup
rm /tmp/env-vars.txt
```

---

## Running the Script

### Step 1: Navigate to Directory
```bash
cd /Users/cope/EnGardeHQ
```

### Step 2: Verify Script Exists
```bash
ls -la setup-all-microservices.sh
# Should show: -rwxr-xr-x (executable)
```

### Step 3: Run Script
```bash
./setup-all-microservices.sh
```

### Step 4: Follow Prompts
The script will ask for each value. Copy-paste from your saved file.

---

## Post-Deployment Checklist

After script completes:

### Verify GitHub
- [ ] All three repos show recent commits
- [ ] Each repo has a `.railway` file (Railway link)

**Check:**
```bash
cd /Users/cope/EnGardeHQ/MadanSara
git log -1
# Should show recent commit
```

### Verify Railway
- [ ] Railway project shows 3 services
- [ ] All 3 services show "Deployed" status
- [ ] Each service has a URL assigned

**Check:**
```bash
railway status
# Should show all services healthy
```

### Test Health Endpoints
- [ ] Onside health check: `curl <onside-url>/health` returns 200
- [ ] Madan Sara health check: `curl <madan-sara-url>/health` returns 200
- [ ] Sankore health check: `curl <sankore-url>/health` returns 200

**Run:**
```bash
cd /Users/cope/EnGardeHQ/MadanSara
MADANSARA_URL=$(cat .railway-url)
curl $MADANSARA_URL/health | jq .
# Should show: {"status": "healthy", ...}
```

### Initialize ZeroDB
- [ ] Collections initialized: `python scripts/init-zerodb-collections.py`
- [ ] All 6 collections created successfully

**Run:**
```bash
cd /Users/cope/EnGardeHQ/MadanSara
python scripts/init-zerodb-collections.py
# Should show: ✓ All collections ready for Walker agents
```

### Test Auto-Deploy
- [ ] Made a test commit and pushed
- [ ] Railway automatically triggered deployment
- [ ] New deployment succeeded

**Test:**
```bash
cd /Users/cope/EnGardeHQ/MadanSara
echo "# Test $(date)" >> README.md
git add README.md
git commit -m "Test auto-deploy"
git push origin main

# Watch logs
railway logs -f
# Should show: deployment started, building, deployed
```

### Verify Service Mesh
- [ ] Each service knows about other services
- [ ] Services can call each other

**Check:**
```bash
# Check Madan Sara has other service URLs
cd /Users/cope/EnGardeHQ/MadanSara
railway variables get ONSIDE_URL
railway variables get SANKORE_URL
# Both should return URLs
```

---

## Troubleshooting

### If Script Fails

#### 1. Check Prerequisites
```bash
# Railway CLI installed?
railway --version

# Logged in?
railway whoami

# Git configured?
git config --global user.name
git config --global user.email
```

#### 2. Check GitHub Authentication
```bash
# Using GitHub CLI?
gh auth status

# Using SSH?
ssh -T git@github.com

# Using token?
# Ensure token is saved in keychain or use:
git config --global credential.helper store
```

#### 3. Check Railway Connection
```bash
# Can access project?
railway status

# Can access database?
railway variables get DATABASE_PUBLIC_URL
```

#### 4. Manual Recovery
If script partially completed, you can:

```bash
# Continue from specific service
cd /Users/cope/EnGardeHQ/Onside
railway link  # Link to existing Railway service
railway up    # Deploy manually

# Or start fresh
railway unlink
./setup-all-microservices.sh  # Run script again
```

---

## Support

### Useful Commands

```bash
# View all Railway services
railway service list

# View logs for service
railway logs --service madan-sara

# View environment variables
railway variables

# Open Railway dashboard
railway open

# Check deployment status
railway status
```

### Useful Links

- Railway Dashboard: https://railway.app/dashboard
- GitHub Organization: https://github.com/EnGardeHQ
- Railway Docs: https://docs.railway.app
- GitHub Docs: https://docs.github.com

---

## Ready to Deploy?

✅ All checkboxes above are checked?
✅ All API keys are ready?
✅ Database URL is ready?

**Then run:**
```bash
cd /Users/cope/EnGardeHQ
./setup-all-microservices.sh
```

**Estimated time:** 10-15 minutes

**What to expect:**
1. GitHub push for all 3 repos
2. Railway deployment for all 3 services
3. Environment variables set
4. Service mesh configured
5. Auto-deploy enabled

**When complete, you'll have:**
- 3 separate GitHub repos
- 3 Railway containers
- Auto-deploy on git push
- Shared database & ZeroDB
- Service mesh communication

🚀 **Good luck!**
