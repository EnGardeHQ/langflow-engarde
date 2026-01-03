# Custom Components Deployment - Ready to Deploy

**Date**: December 28, 2025
**Status**: ✅ ALL COMPONENTS READY
**Next Step**: Deploy to Langflow service

---

## 📦 What's Ready

### Walker Agents (7 Components)
**Location**: `production-backend/langflow/custom_components/walker_agents/`

**Complete Components** (drag-and-drop ready):
1. SEO Walker Agent (Complete)
2. Paid Ads Walker Agent (Complete)
3. Content Walker Agent (Complete)
4. Audience Intelligence Walker Agent (Complete)

**Building Blocks** (for advanced flows):
5. Tenant ID Input
6. Walker Suggestion Builder
7. Walker Agent API Request

**File**: `walker_agent_components.py` (540 lines)

---

### EnGarde Agents (6 Components)
**Location**: `production-backend/langflow/custom_components/engarde_agents/`

**Marketing Automation Components**:
1. Campaign Creation Agent - Auto-create campaigns
2. Analytics Report Agent - Fetch analytics and insights
3. Content Approval Agent - Approve/reject content workflows
4. Scheduled Campaign Launcher - Launch draft campaigns
5. Multi-Channel Notification Agent - Email/WhatsApp/in-app notifications
6. Performance Monitoring Agent - Monitor metrics with threshold alerts

**File**: `engarde_agent_components.py` (380 lines)

---

## 🚀 Quick Deployment (Choose One)

### Method 1: Automated Script (Easiest)

```bash
cd /Users/cope/EnGardeHQ
./deploy-to-langflow.sh
```

Follow the prompts to:
- Copy to existing Langflow repo
- Fork official Langflow
- Create deployment package

---

### Method 2: Manual Deployment

**If you have a Langflow GitHub repository:**

```bash
# 1. Clone your Langflow repo (if not already)
cd /Users/cope/EnGardeHQ
git clone YOUR_LANGFLOW_REPO langflow-repo
cd langflow-repo

# 2. Copy both component folders
cp -r ../production-backend/langflow/custom_components/walker_agents \
  src/backend/base/langflow/components/

cp -r ../production-backend/langflow/custom_components/engarde_agents \
  src/backend/base/langflow/components/

# 3. Commit and push
git add .
git commit -m "Add Walker and EnGarde custom components (13 total)"
git push

# 4. Railway auto-deploys (wait 2-5 minutes)
```

---

### Method 3: Fork Official Langflow

**If using Langflow Docker image:**

```bash
cd /Users/cope/EnGardeHQ

# 1. Clone official Langflow
git clone https://github.com/langflow-ai/langflow.git langflow-engarde
cd langflow-engarde

# 2. Copy components
cp -r ../production-backend/langflow/custom_components/walker_agents \
  src/backend/base/langflow/components/

cp -r ../production-backend/langflow/custom_components/engarde_agents \
  src/backend/base/langflow/components/

# 3. Create GitHub repo and push
# Create repo: EnGardeHQ/langflow-engarde on GitHub
git remote set-url origin https://github.com/EnGardeHQ/langflow-engarde.git
git add .
git commit -m "Fork Langflow with EnGarde custom components"
git push -u origin main

# 4. Update Railway
# Dashboard → langflow-server → Settings → Source → Select your fork
```

---

## ✅ Verification Steps

### 1. Check Railway Logs

```bash
railway logs --service langflow-server | grep -i "walker\|engarde\|component"
```

**Expected**:
```
✓ Loading component: walker_agents
✓ Loading component: engarde_agents
✓ Successfully loaded 13 custom components
```

---

### 2. Check Langflow UI

1. Open: https://langflow.engarde.media
2. Create new flow
3. Look in left sidebar

**Expected categories**:
- **Walker Agents** (7 components)
  - SEO Walker Agent (Complete)
  - Paid Ads Walker Agent (Complete)
  - Content Walker Agent (Complete)
  - Audience Intelligence Walker Agent (Complete)
  - Tenant ID Input
  - Walker Suggestion Builder
  - Walker Agent API Request

- **EnGarde Agents** (6 components)
  - Campaign Creation Agent
  - Analytics Report Agent
  - Content Approval Agent
  - Scheduled Campaign Launcher
  - Multi-Channel Notification Agent
  - Performance Monitoring Agent

---

### 3. Test a Component

**Quick test flow**:

1. Drag **"SEO Walker Agent (Complete)"** to canvas
2. Click component to configure
3. Set `tenant_id` to a valid UUID (get from database)
4. Run

**Expected output**:
```json
{
  "success": true,
  "batch_id": "uuid",
  "suggestions_received": 1,
  "suggestions_stored": 1,
  "notifications_sent": {
    "email": true
  }
}
```

---

## 📁 File Structure

After deployment, your Langflow should have:

```
langflow/
└── components/
    ├── walker_agents/
    │   ├── __init__.py (23 lines)
    │   └── walker_agent_components.py (540 lines)
    │       ├── TenantIDInputComponent
    │       ├── WalkerSuggestionBuilderComponent
    │       ├── WalkerAgentAPIComponent
    │       ├── SEOWalkerAgentComponent ⭐
    │       ├── PaidAdsWalkerAgentComponent ⭐
    │       ├── ContentWalkerAgentComponent ⭐
    │       └── AudienceIntelligenceWalkerAgentComponent ⭐
    │
    └── engarde_agents/
        ├── __init__.py (20 lines)
        └── engarde_agent_components.py (380 lines)
            ├── CampaignCreationAgentComponent ⭐
            ├── AnalyticsReportAgentComponent ⭐
            ├── ContentApprovalAgentComponent ⭐
            ├── CampaignLauncherAgentComponent ⭐
            ├── NotificationAgentComponent ⭐
            └── PerformanceMonitoringAgentComponent ⭐
```

⭐ = Production-ready components (just drag, configure, and run)

---

## 🔧 Environment Variables Required

All Walker Agent keys are **already configured** in Railway:

```bash
✅ ENGARDE_API_URL=https://api.engarde.media
✅ WALKER_AGENT_API_KEY_ONSIDE_SEO=wa_onside_production_...
✅ WALKER_AGENT_API_KEY_ONSIDE_CONTENT=wa_onside_production_...
✅ WALKER_AGENT_API_KEY_SANKORE_PAID_ADS=wa_sankore_production_...
✅ WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE=wa_madansara_production_...
```

**For EnGarde Agents**, you may need:
```bash
# If not already set
railway variables --set "ENGARDE_API_KEY=your-general-api-key" \
  --service langflow-server
```

---

## 🆘 Troubleshooting

### Components Don't Appear After Deployment

**1. Check logs for errors**:
```bash
railway logs --service langflow-server
```

**2. Verify components were copied**:
```bash
# In your Langflow repo
ls -la src/backend/base/langflow/components/walker_agents
ls -la src/backend/base/langflow/components/engarde_agents
```

**3. Check for Python import errors**:
Look for `ModuleNotFoundError` or `ImportError` in logs

**4. Ensure httpx is installed**:
Add to `pyproject.toml` or `requirements.txt`:
```
httpx>=0.25.0
```

---

### Components Appear But Don't Work

**1. Check environment variables**:
```bash
railway variables --service langflow-server | grep -E "ENGARDE|WALKER"
```

**2. Test API connectivity**:
```bash
curl https://api.engarde.media/health
```

**3. Verify tenant ID is valid UUID**:
```bash
railway run --service Main -- python3 -c "
import os, psycopg2
conn = psycopg2.connect(os.getenv('DATABASE_PUBLIC_URL'))
cur = conn.cursor()
cur.execute('SELECT id, name FROM tenants LIMIT 3')
print(cur.fetchall())
"
```

---

## 📚 Complete Documentation

All guides are ready:

1. **DEPLOY_COMPONENTS_TO_LANGFLOW.md** ← Comprehensive deployment guide
2. **WALKER_AGENTS_QUICK_START.md** ← Get first agent running in 10 min
3. **LANGFLOW_PYTHON_SNIPPETS_FOR_AGENTS.md** ← Alternative: copy-paste snippets
4. **LANGFLOW_ENVIRONMENT_VARIABLES_GUIDE.md** ← Env var setup (already done ✅)
5. **WALKER_AGENTS_ARCHITECTURE_RATIONALE.md** ← Why use Langflow
6. **production-backend/langflow/custom_components/README.md** ← Component reference

---

## 🎯 Deployment Checklist

Use this to track your deployment:

- [ ] Identified Langflow deployment method (GitHub/Docker/Template)
- [ ] Chose deployment approach (existing repo/fork/package)
- [ ] Copied walker_agents folder to Langflow
- [ ] Copied engarde_agents folder to Langflow
- [ ] Committed changes
- [ ] Pushed to GitHub
- [ ] Railway redeployed (wait 2-5 min)
- [ ] Checked logs for errors
- [ ] Opened Langflow UI
- [ ] Verified Walker Agents category appears
- [ ] Verified EnGarde Agents category appears
- [ ] Counted 13 total custom components
- [ ] Tested SEO Walker Agent component
- [ ] Verified database received suggestion
- [ ] Checked email was sent

---

## 🎉 After Successful Deployment

Once components are deployed:

1. **Build production flows**
   - Create flow for each of 4 Walker Agents
   - Create flows for EnGarde automation workflows

2. **Set up scheduling**
   - Add Cron nodes to run agents daily
   - Configure appropriate times (e.g., 9 AM daily)

3. **Monitor and iterate**
   - Check logs daily for errors
   - Review suggestions in database
   - Adjust thresholds and templates as needed

4. **Add AI enhancement** (optional)
   - Set `OPENAI_API_KEY` in Railway
   - Add OpenAI nodes for dynamic suggestion generation
   - Connect OpenAI → Suggestion Builder → API

---

## 📦 Deployment Package

Pre-built package ready to extract:

```bash
langflow-custom-components.tar.gz (6.8 KB)
```

Contains:
- `walker_agents/` folder
- `engarde_agents/` folder

Extract with:
```bash
tar -xzf langflow-custom-components.tar.gz -C path/to/langflow/components/
```

---

## 🚀 Ready to Deploy

**Everything is ready!**

Choose your deployment method and follow the steps above.

Estimated time: **5-15 minutes** (depending on method)

**Recommended**: Use Method 1 (automated script) or Method 2 (manual to existing repo)

---

**Status**: ✅ READY TO DEPLOY
**Components**: 13 total (7 Walker + 6 EnGarde)
**Files**: All created and tested
**Documentation**: Complete
**Next**: Run `./deploy-to-langflow.sh` or follow manual steps

**Last Updated**: December 28, 2025
