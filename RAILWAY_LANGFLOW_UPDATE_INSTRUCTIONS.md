# Update Railway Langflow Service to Use Custom Fork

**Repository Created**: https://github.com/EnGardeHQ/langflow-engarde
**Status**: Pushing to GitHub (in progress...)

---

## ✅ What's Been Done

1. ✅ Forked official Langflow repository
2. ✅ Copied Walker Agents custom components (7 components)
3. ✅ Copied EnGarde Agents custom components (6 components)
4. ✅ Committed changes to git
5. ✅ Created GitHub repository: `EnGardeHQ/langflow-engarde`
6. 🔄 Pushing to GitHub (in progress)

---

## 🚀 Next Step: Update Railway Service

Once the push completes, follow these steps to update your Langflow service on Railway:

### Method 1: Railway Dashboard (Recommended)

1. **Open Railway Dashboard**:
   ```
   https://railway.app
   ```

2. **Navigate to your project**:
   - Project: `EnGarde Suite`
   - Service: `langflow-server`

3. **Update Source Repository**:
   - Click on `langflow-server` service
   - Go to **Settings** tab
   - Scroll to **Source** section
   - Click **Disconnect Source** (if connected to Docker image)
   - Click **Connect GitHub Repo**
   - Select: `EnGardeHQ/langflow-engarde`
   - Branch: `main`
   - Click **Connect**

4. **Configure Build**:
   - Build Command: (leave as default)
   - Start Command: (leave as default)  
   - Root Directory: (leave as default)

5. **Deploy**:
   - Click **Deploy** button
   - Wait 5-10 minutes for build and deployment

---

### Method 2: Railway CLI

```bash
# Switch to langflow-server service
railway service langflow-server

# Link to GitHub repo
railway up

# Or redeploy with new source
railway link EnGardeHQ/langflow-engarde
railway deploy
```

---

## ✅ Verification Steps

### 1. Check Deployment Logs

```bash
railway logs --service langflow-server
```

Look for:
```
✓ Building custom components
✓ Loading component: walker_agents
✓ Loading component: engarde_agents
✓ Successfully loaded 13 custom components
```

### 2. Open Langflow UI

1. Go to: https://langflow.engarde.media
2. Create new flow
3. Check components panel (left sidebar)

**Expected categories**:
- **Walker Agents** (7 components)
- **EnGarde Agents** (6 components)

### 3. Test a Component

1. Drag **"SEO Walker Agent (Complete)"** onto canvas
2. Get a tenant UUID from your database
3. Set `tenant_id` input
4. Run the component
5. Check for `"success": true` in output

### 4. Verify in Database

```bash
railway run --service Main -- python3 -c "
import os, psycopg2
conn = psycopg2.connect(os.getenv('DATABASE_PUBLIC_URL'))
cur = conn.cursor()
cur.execute('SELECT id, title, created_at FROM walker_agent_suggestions ORDER BY created_at DESC LIMIT 1')
print(cur.fetchone())
"
```

You should see your test suggestion!

---

## 📊 Component Inventory

After deployment, you'll have access to:

### Walker Agents (7)
1. SEO Walker Agent (Complete) ⭐
2. Paid Ads Walker Agent (Complete) ⭐
3. Content Walker Agent (Complete) ⭐
4. Audience Intelligence Walker Agent (Complete) ⭐
5. Tenant ID Input
6. Walker Suggestion Builder
7. Walker Agent API Request

### EnGarde Agents (6)
1. Campaign Creation Agent ⭐
2. Analytics Report Agent ⭐
3. Content Approval Agent ⭐
4. Scheduled Campaign Launcher ⭐
5. Multi-Channel Notification Agent ⭐
6. Performance Monitoring Agent ⭐

⭐ = Production-ready (drag, configure, run)

---

## 🆘 Troubleshooting

### Components Don't Appear

**Check build logs**:
```bash
railway logs --service langflow-server | grep -i "component\|error"
```

**Common issues**:
- Python import errors → Check httpx is installed
- Module not found → Verify components copied correctly
- Build failed → Check Railway build logs

### Railway Won't Connect to Repo

**Fix**:
1. Disconnect current source
2. Reconnect GitHub account if needed
3. Ensure repo is public or Railway has access
4. Try again

### Deployment Takes Too Long

Langflow is a large application. First deployment from source can take **10-15 minutes**.

Be patient and monitor logs:
```bash
railway logs --service langflow-server --tail
```

---

## 🎯 After Successful Deployment

1. **Test all components** - Verify each of 13 components loads
2. **Build production flows** - Create flows for Walker Agents
3. **Set up scheduling** - Add cron triggers for daily runs
4. **Monitor logs** - Check for errors daily
5. **Iterate** - Improve suggestions based on feedback

---

## 📚 Documentation

- **Quick Start**: `WALKER_AGENTS_QUICK_START.md`
- **Component Reference**: `production-backend/langflow/custom_components/README.md`
- **Python Snippets** (alternative): `LANGFLOW_PYTHON_SNIPPETS_FOR_AGENTS.md`
- **Architecture**: `WALKER_AGENTS_ARCHITECTURE_RATIONALE.md`

---

## ✅ Checklist

Track your progress:

- [ ] GitHub push completed successfully
- [ ] Opened Railway dashboard
- [ ] Navigated to langflow-server service
- [ ] Disconnected current source (if needed)
- [ ] Connected to EnGardeHQ/langflow-engarde repo
- [ ] Started deployment
- [ ] Waited for build to complete (10-15 min)
- [ ] Checked deployment logs for errors
- [ ] Opened Langflow UI
- [ ] Verified Walker Agents category appears
- [ ] Verified EnGarde Agents category appears
- [ ] Tested SEO Walker Agent component
- [ ] Verified suggestion in database
- [ ] Checked email notification sent

---

**Status**: Ready to update Railway
**Estimated Time**: 15-20 minutes total
**Difficulty**: Easy (just point and click in Railway dashboard)

**Last Updated**: December 28, 2025
