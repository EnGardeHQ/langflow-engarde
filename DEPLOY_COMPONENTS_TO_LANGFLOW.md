# Deploy Custom Components to Langflow Server

**Goal**: Copy Walker Agents and EnGarde Agents components to Langflow service

---

## 📦 What You're Deploying

### Walker Agents (4 components)
Location: `production-backend/langflow/custom_components/walker_agents/`

1. **SEO Walker Agent** - SEO optimization suggestions
2. **Paid Ads Walker Agent** - Campaign optimization
3. **Content Walker Agent** - Content gap analysis
4. **Audience Intelligence Walker Agent** - Audience segmentation

Plus 3 building block components (Tenant ID Input, Suggestion Builder, API Request)

### EnGarde Agents (6 components)
Location: `production-backend/langflow/custom_components/engarde_agents/`

1. **Campaign Creation Agent** - Auto-create campaigns
2. **Analytics Report Agent** - Fetch analytics and insights
3. **Content Approval Agent** - Approve/reject content
4. **Scheduled Campaign Launcher** - Launch campaigns
5. **Multi-Channel Notification Agent** - Send notifications
6. **Performance Monitoring Agent** - Monitor metrics and alerts

---

## 🔍 Step 1: Identify Langflow Deployment Method

First, we need to understand how Langflow is deployed on Railway.

### Check Deployment Source

```bash
# Navigate to Railway dashboard
open https://railway.app

# Or check via CLI
railway status --service langflow-server
```

Look for one of these:

**Option A: GitHub Repository**
- Langflow is deployed from a GitHub repo
- Example: `EnGardeHQ/langflow-engarde`

**Option B: Docker Image**
- Langflow is deployed from Docker Hub
- Example: `cope84/engarde-langflow:latest` or `langflowai/langflow:latest`

**Option C: Template/Marketplace**
- Langflow was deployed from Railway template
- Uses default Langflow image

---

## 📋 Step 2: Choose Deployment Method

### Method A: GitHub Repository (Recommended)

**If Langflow is deployed from a GitHub repo you control:**

1. **Clone the Langflow repository**:
   ```bash
   cd /Users/cope/EnGardeHQ
   git clone YOUR_LANGFLOW_REPO_URL langflow-repo
   cd langflow-repo
   ```

2. **Copy Walker Agents components**:
   ```bash
   # Find the components directory in Langflow repo
   # Usually: src/backend/base/langflow/components/

   cp -r ../production-backend/langflow/custom_components/walker_agents \
     src/backend/base/langflow/components/
   ```

3. **Copy EnGarde Agents components**:
   ```bash
   cp -r ../production-backend/langflow/custom_components/engarde_agents \
     src/backend/base/langflow/components/
   ```

4. **Commit and push**:
   ```bash
   git add .
   git commit -m "Add Walker Agents and EnGarde Agents custom components"
   git push origin main
   ```

5. **Railway auto-deploys**:
   - Wait 2-5 minutes for deployment
   - Check Langflow UI for new components

---

### Method B: Fork Official Langflow (If Using Docker Image)

**If Langflow is deployed from official Docker image:**

1. **Fork Langflow**:
   ```bash
   cd /Users/cope/EnGardeHQ
   git clone https://github.com/langflow-ai/langflow.git langflow-engarde
   cd langflow-engarde
   ```

2. **Copy components**:
   ```bash
   cp -r ../production-backend/langflow/custom_components/walker_agents \
     src/backend/base/langflow/components/

   cp -r ../production-backend/langflow/custom_components/engarde_agents \
     src/backend/base/langflow/components/
   ```

3. **Create your GitHub repo**:
   ```bash
   # Create new repo on GitHub: EnGardeHQ/langflow-engarde

   git remote set-url origin https://github.com/EnGardeHQ/langflow-engarde.git
   git add .
   git commit -m "Fork Langflow with custom EnGarde components"
   git push -u origin main
   ```

4. **Update Railway service**:
   - Go to Railway dashboard
   - Select `langflow-server` service
   - Settings → Source → Change to your GitHub repo
   - Select `EnGardeHQ/langflow-engarde`
   - Deploy

---

### Method C: Custom Dockerfile (Advanced)

**If you want to extend the official Langflow image:**

1. **Create Dockerfile**:
   ```bash
   cd /Users/cope/EnGardeHQ
   mkdir langflow-custom
   cd langflow-custom
   ```

2. **Create `Dockerfile`**:
   ```dockerfile
   FROM langflowai/langflow:latest

   # Copy custom components
   COPY walker_agents /app/langflow/components/walker_agents
   COPY engarde_agents /app/langflow/components/engarde_agents

   # Ensure Python can import them
   RUN python -c "from langflow.components.walker_agents import *"
   RUN python -c "from langflow.components.engarde_agents import *"
   ```

3. **Copy component folders**:
   ```bash
   cp -r ../production-backend/langflow/custom_components/walker_agents .
   cp -r ../production-backend/langflow/custom_components/engarde_agents .
   ```

4. **Build and push to Docker Hub**:
   ```bash
   docker build -t cope84/engarde-langflow:latest .
   docker push cope84/engarde-langflow:latest
   ```

5. **Update Railway**:
   - Railway dashboard → langflow-server
   - Settings → Image → `cope84/engarde-langflow:latest`
   - Deploy

---

## 🚀 Step 3: Verify Deployment

### 1. Check Langflow Logs

```bash
railway logs --service langflow-server | grep -i "component\|custom\|walker\|engarde"
```

Look for:
```
✅ "Loading component: walker_agents"
✅ "Loading component: engarde_agents"
✅ "Successfully loaded X components"
```

### 2. Open Langflow UI

1. Go to: https://langflow.engarde.media
2. Create new flow
3. Check left sidebar for custom components

You should see TWO new categories:
- **Walker Agents** (7 components)
- **EnGarde Agents** (6 components)

### 3. Test a Component

1. Drag **"SEO Walker Agent (Complete)"** onto canvas
2. Set tenant_id to a valid UUID
3. Run
4. Check output for `"success": true`

---

## 📁 Component Structure

After deployment, Langflow should have:

```
langflow/
└── components/
    ├── walker_agents/
    │   ├── __init__.py
    │   └── walker_agent_components.py
    │       ├── TenantIDInputComponent
    │       ├── WalkerSuggestionBuilderComponent
    │       ├── WalkerAgentAPIComponent
    │       ├── SEOWalkerAgentComponent
    │       ├── PaidAdsWalkerAgentComponent
    │       ├── ContentWalkerAgentComponent
    │       └── AudienceIntelligenceWalkerAgentComponent
    │
    └── engarde_agents/
        ├── __init__.py
        └── engarde_agent_components.py
            ├── CampaignCreationAgentComponent
            ├── AnalyticsReportAgentComponent
            ├── ContentApprovalAgentComponent
            ├── CampaignLauncherAgentComponent
            ├── NotificationAgentComponent
            └── PerformanceMonitoringAgentComponent
```

---

## 🆘 Troubleshooting

### Components Don't Appear

**Check logs**:
```bash
railway logs --service langflow-server
```

Look for Python import errors or missing dependencies.

**Common issue**: Missing `httpx` library

**Fix**:
Add to Langflow's `requirements.txt` (or `pyproject.toml`):
```
httpx>=0.25.0
```

### Import Errors

**Error**: `ModuleNotFoundError: No module named 'langflow.custom'`

**Fix**: Ensure you're copying to the correct Langflow version directory. The import path changed in Langflow 1.0+.

For older Langflow (< 1.0):
```python
from langflow import CustomComponent
```

For newer Langflow (>= 1.0):
```python
from langflow.custom import Component
```

### Components Load But Don't Work

**Check environment variables**:
```bash
railway variables --service langflow-server | grep -E "ENGARDE|WALKER"
```

Ensure all API keys are set.

---

## ✅ Quick Verification Checklist

After deployment, verify:

- [ ] Langflow redeployed successfully
- [ ] No errors in Railway logs
- [ ] "Walker Agents" category appears in Langflow UI
- [ ] "EnGarde Agents" category appears in Langflow UI
- [ ] Total 13 custom components visible
- [ ] Can drag components onto canvas
- [ ] Components have proper inputs/outputs
- [ ] Test run with SEO Walker Agent succeeds

---

## 🎯 Recommended Next Steps

After successful deployment:

1. **Build flows** for each agent type
2. **Set up cron schedules** for daily runs
3. **Test end-to-end** (component → API → database → email)
4. **Monitor logs** for errors
5. **Iterate and improve** based on results

---

## 📚 Files Ready to Deploy

All files are in:
```
/Users/cope/EnGardeHQ/production-backend/langflow/custom_components/
├── walker_agents/
│   ├── __init__.py
│   └── walker_agent_components.py
└── engarde_agents/
    ├── __init__.py
    └── engarde_agent_components.py
```

Just copy these two folders to your Langflow repository!

---

**Created**: December 28, 2025
**Status**: Ready to deploy
**Next**: Identify Langflow deployment method and choose deployment approach
