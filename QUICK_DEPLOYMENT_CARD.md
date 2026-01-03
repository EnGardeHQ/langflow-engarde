# Quick Deployment Card - Langflow Agents

**Copy-paste guide for deploying all 10 agents in 30 minutes**

---

## 📂 Files You Need

| File | What's Inside | When to Use |
|------|---------------|-------------|
| **FINAL_WALKER_AGENTS_COMPLETE.md** | Agents 1-4 code | Copy agent code |
| **FINAL_ENGARDE_AGENTS_COMPLETE.md** | Agents 5-10 code | Copy agent code |
| **DEPLOYMENT_READY_SUMMARY.md** | Full deployment guide | Complete reference |
| **ARCHITECTURE_VISUAL_SUMMARY.md** | Architecture diagrams | Understanding flows |
| **This file** | Quick cheat sheet | Fast deployment |

---

## ⚡ 3-Minute Deployment (Per Agent)

### Step 1: Open Langflow
```
https://langflow.engarde.media
```

### Step 2: Create Flow
1. Click "New Flow"
2. Give it a descriptive name:
   - "SEO Walker Agent"
   - "Paid Ads Walker Agent"
   - "Campaign Creation Agent"
   - etc.

### Step 3: Add Input Node
1. Search for "Text Input" component
2. Drag to canvas
3. Configure:
   - **Name:** `tenant_id`
   - **Value:** Leave empty (or use test UUID)

### Step 4: Add Python Function
1. Search for "Python Function" component
2. Drag to canvas
3. Click on the node to open editor

### Step 5: Copy Agent Code

**For Agents 1-4 (Walker):**
Open `FINAL_WALKER_AGENTS_COMPLETE.md` → Find agent section → Copy entire `def run(tenant_id: str) -> dict:` function

**For Agents 5-10 (EnGarde):**
Open `FINAL_ENGARDE_AGENTS_COMPLETE.md` → Find agent section → Copy entire `def run(...) -> dict:` function

### Step 6: Paste Code
1. Delete placeholder code in Python Function editor
2. Paste copied code
3. Click "Check & Save"

### Step 7: Connect Nodes
1. Drag from Text Input output handle
2. Connect to Python Function `tenant_id` input parameter

### Step 8: Test
1. Set `tenant_id` in Text Input (use real tenant UUID from database)
2. Click "Run" button (▶️)
3. Wait for execution
4. Check output panel shows `"success": true`

### Step 9: Save
1. Click "Save" in top toolbar
2. Flow is now ready to use!

---

## 🗂️ Agent Deployment Order

### Phase 1: Walker Agents (Foundation)

| Order | Agent | Source File | Section | Test With |
|-------|-------|-------------|---------|-----------|
| 1 | SEO Walker | FINAL_WALKER_AGENTS_COMPLETE.md | Agent 1 | Real tenant_id |
| 2 | Paid Ads Walker | FINAL_WALKER_AGENTS_COMPLETE.md | Agent 2 | Real tenant_id |
| 3 | Content Walker | FINAL_WALKER_AGENTS_COMPLETE.md | Agent 3 | Real tenant_id |
| 4 | Audience Intelligence | FINAL_WALKER_AGENTS_COMPLETE.md | Agent 4 | Real tenant_id |

**Verify:** Check `walker_agent_suggestions` table has new rows

### Phase 2: EnGarde Agents (Workflows)

| Order | Agent | Source File | Section | Test With |
|-------|-------|-------------|---------|-----------|
| 5 | Campaign Creation | FINAL_ENGARDE_AGENTS_COMPLETE.md | Agent 5 | tenant_id, name, platform |
| 6 | Analytics Report | FINAL_ENGARDE_AGENTS_COMPLETE.md | Agent 6 | tenant_id, days_back=30 |
| 7 | Content Approval | FINAL_ENGARDE_AGENTS_COMPLETE.md | Agent 7 | tenant_id, content_id |
| 8 | Campaign Launcher | FINAL_ENGARDE_AGENTS_COMPLETE.md | Agent 8 | tenant_id, campaign_id |
| 9 | Notification | FINAL_ENGARDE_AGENTS_COMPLETE.md | Agent 9 | tenant_id |
| 10 | Performance Monitoring | FINAL_ENGARDE_AGENTS_COMPLETE.md | Agent 10 | tenant_id |

**Verify:** Check respective tables (`campaigns`, `analytics_reports`, etc.)

---

## ✅ Quick Test Commands

### Get Test Tenant ID
```bash
railway run --service Main -- python3 -c "
import os, psycopg2
conn = psycopg2.connect(os.getenv('DATABASE_PUBLIC_URL'))
cur = conn.cursor()
cur.execute('SELECT id, name FROM tenants LIMIT 1')
row = cur.fetchone()
print(f'Tenant ID: {row[0]}')
print(f'Tenant Name: {row[1]}')
"
```

### Check Walker Suggestions
```bash
railway run --service Main -- python3 -c "
import os, psycopg2
conn = psycopg2.connect(os.getenv('DATABASE_PUBLIC_URL'))
cur = conn.cursor()
cur.execute('SELECT COUNT(*) FROM walker_agent_suggestions WHERE created_at >= NOW() - INTERVAL \'1 hour\'')
print(f'New suggestions in last hour: {cur.fetchone()[0]}')
"
```

### Check Campaigns Created
```bash
railway run --service Main -- python3 -c "
import os, psycopg2
conn = psycopg2.connect(os.getenv('DATABASE_PUBLIC_URL'))
cur = conn.cursor()
cur.execute('SELECT COUNT(*) FROM campaigns WHERE created_at >= NOW() - INTERVAL \'1 hour\'')
print(f'New campaigns in last hour: {cur.fetchone()[0]}')
"
```

---

## 🔧 Troubleshooting Quick Fixes

### Error: "Connection refused to Onside"
```bash
# Check if microservice is running
docker ps | grep onside

# If not running, start it
docker-compose up -d onside

# Test endpoint
curl http://localhost:8000/health
```

### Error: "BigQuery authentication failed"
```bash
# Verify env var is set
railway variables --service langflow-server | grep BIGQUERY

# Test credentials
railway run --service langflow-server -- python3 -c "
import os, json
from google.cloud import bigquery
from google.oauth2 import service_account

creds_json = os.getenv('GOOGLE_APPLICATION_CREDENTIALS_JSON')
creds_dict = json.loads(creds_json)
credentials = service_account.Credentials.from_service_account_info(creds_dict)
client = bigquery.Client(credentials=credentials, project='engarde-production')
print('✓ BigQuery authentication successful')
"
```

### Error: "ZeroDB 404 Not Found"
```bash
# Test ZeroDB API
curl -H "X-API-Key: $ZERODB_API_KEY" \
  "https://api.ainative.studio/api/v1/public/projects/$ZERODB_PROJECT_ID/events?limit=1"
```

### Error: "No suggestions in database"
```bash
# Check API key is valid
railway variables --service langflow-server | grep WALKER_AGENT_API_KEY

# Check EnGarde backend is running
railway status --service Main

# Check backend logs
railway logs --service Main | grep "walker-agents/suggestions"
```

---

## 📊 Data Source Quick Reference

### Walker Agents Use 4 Sources:

```
1. Microservice     → Domain data (SEO, ads, content, audience)
2. BigQuery         → Historical analytics (30-90 days)
3. ZeroDB           → Real-time events
4. PostgreSQL       → Store suggestions
```

### EnGarde Agents Use 3 Sources:

```
1. BigQuery         → Historical analytics
2. ZeroDB           → Real-time events
3. PostgreSQL       → CRUD operations
```

---

## 🎯 Environment Variables Checklist

Make sure these are set in Railway `langflow-server`:

```bash
✓ ENGARDE_API_URL
✓ ENGARDE_API_KEY
✓ DATABASE_URL
✓ BIGQUERY_PROJECT_ID
✓ BIGQUERY_DATASET_ID
✓ GOOGLE_APPLICATION_CREDENTIALS_JSON
✓ ZERODB_API_KEY
✓ ZERODB_PROJECT_ID
✓ ZERODB_API_BASE_URL
✓ ONSIDE_API_URL
✓ SANKORE_API_URL
✓ MADANSARA_API_URL
✓ WALKER_AGENT_API_KEY_ONSIDE_SEO
✓ WALKER_AGENT_API_KEY_SANKORE_PAID_ADS
✓ WALKER_AGENT_API_KEY_ONSIDE_CONTENT
✓ WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE
```

Check with:
```bash
railway variables --service langflow-server
```

---

## ⏱️ Time Estimates

| Task | Time |
|------|------|
| Deploy 1 Walker agent | 3 min |
| Deploy 1 EnGarde agent | 3 min |
| **Total for all 10 agents** | **30 min** |
| Verify all agents working | 10 min |
| Set up Cron schedules | 5 min |
| **GRAND TOTAL** | **45 min** |

---

## 🚀 Post-Deployment

### Set Up Cron Schedules

**Walker Agents:** Daily at 9 AM
```
Cron: 0 9 * * *
```

**Analytics Report:** Weekly Monday at 8 AM
```
Cron: 0 8 * * 1
```

**Performance Monitoring:** Every 30 minutes
```
Cron: */30 * * * *
```

### Enable API Access

Each flow gets an API endpoint:
```
POST https://langflow.engarde.media/api/v1/run/{flow_id}
Headers: X-API-Key: {langflow_api_key}
Body: {"tenant_id": "abc123"}
```

### Monitor Execution

Check Langflow logs:
```bash
railway logs --service langflow-server | grep "execution\|success\|error"
```

---

## ✅ Final Checklist

Before declaring "done":

- [ ] All 10 agents deployed to Langflow
- [ ] Each agent tested with real tenant_id
- [ ] Walker suggestions appearing in database
- [ ] EnGarde operations working (campaigns, reports, etc.)
- [ ] Microservices accessible
- [ ] BigQuery queries executing
- [ ] ZeroDB events retrieving
- [ ] Cron schedules configured
- [ ] API endpoints documented
- [ ] Error monitoring enabled

---

## 🎉 Success Indicators

When everything is working, you should see:

```bash
# Database activity
walker_agent_suggestions: Growing daily
campaigns: New entries from Agent 5
analytics_reports: Weekly reports from Agent 6
content: Status updates from Agent 7
monitoring_alerts: Real-time alerts from Agent 10

# Langflow logs
✓ Flow executed successfully
✓ All data sources connected
✓ Suggestions stored in database
✓ 0 errors

# User experience
✓ Dashboard shows new suggestions
✓ Campaigns auto-created
✓ Reports generated weekly
✓ Notifications sent
✓ Performance alerts triggered
```

---

**Ready to deploy! Start with Agent 1 (SEO Walker) and work through the list. 🚀**

**Questions? Check:**
- `DEPLOYMENT_READY_SUMMARY.md` - Full guide
- `ARCHITECTURE_VISUAL_SUMMARY.md` - Architecture details
- `FINAL_COMPLETE_MASTER_GUIDE.md` - Complete reference
