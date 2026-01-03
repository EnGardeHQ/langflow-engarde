# FINAL COMPLETE Master Guide - All 10 Production Agents

**✅ Correct Architecture: BigQuery + ZeroDB + PostgreSQL + Microservices**

---

## 🎯 Final Correct Architecture

### All Agents (Walker + EnGarde) Use:
1. **BigQuery** - Historical analytics (campaign metrics, time-series data)
2. **ZeroDB** - Real-time operational events (live dashboards, streaming metrics)
3. **PostgreSQL** - Cache insights, store suggestions (via EnGarde API)

### Walker Agents ADDITIONALLY Use:
4. **Microservices** - Domain-specific data (Onside, Sankore, MadanSara)

---

## 📁 File Organization

| File | Contains | Purpose |
|------|----------|---------|
| `FINAL_WALKER_AGENTS_COMPLETE.md` | Agents 1-4 | Walker agents with all 4 data sources |
| `FINAL_ENGARDE_AGENTS_COMPLETE.md` | Agents 5-10 | EnGarde agents with 3 data sources |
| `FINAL_COMPLETE_MASTER_GUIDE.md` | This file | Deployment and reference guide |

---

## 🗂️ Complete Agent Summary

| # | Agent | Type | Data Sources | Stores In |
|---|-------|------|--------------|-----------|
| 1 | SEO Walker | Walker | Onside + BigQuery + ZeroDB + PostgreSQL | walker_agent_suggestions |
| 2 | Paid Ads Walker | Walker | Sankore + BigQuery + ZeroDB + PostgreSQL | walker_agent_suggestions |
| 3 | Content Walker | Walker | Onside + BigQuery + ZeroDB + PostgreSQL | walker_agent_suggestions |
| 4 | Audience Intelligence | Walker | MadanSara + BigQuery + ZeroDB + PostgreSQL | walker_agent_suggestions |
| 5 | Campaign Creation | EnGarde | BigQuery + ZeroDB + PostgreSQL | campaigns |
| 6 | Analytics Report | EnGarde | BigQuery + ZeroDB + PostgreSQL | analytics_reports |
| 7 | Content Approval | EnGarde | BigQuery + ZeroDB + PostgreSQL | content |
| 8 | Campaign Launcher | EnGarde | BigQuery + ZeroDB + PostgreSQL | campaigns |
| 9 | Notification | EnGarde | ZeroDB + PostgreSQL | notifications |
| 10 | Performance Monitoring | EnGarde | BigQuery + ZeroDB + PostgreSQL | monitoring_alerts |

---

## 🔧 Complete Environment Variables

```bash
# Main EnGarde Backend
ENGARDE_API_URL=https://api.engarde.media
ENGARDE_API_KEY=<main_backend_api_key>

# PostgreSQL (Main Database)
DATABASE_URL=postgresql://user:pass@host:port/engarde_production

# BigQuery Data Lake
BIGQUERY_PROJECT_ID=engarde-production
BIGQUERY_DATASET_ID=engarde_analytics
GOOGLE_APPLICATION_CREDENTIALS_JSON={"type":"service_account","project_id":"engarde-production",...}

# ZeroDB (Real-time Operations)
ZERODB_API_KEY=<zerodb_api_key>
ZERODB_PROJECT_ID=<zerodb_project_uuid>
ZERODB_API_BASE_URL=https://api.ainative.studio/api/v1

# Walker Microservices
ONSIDE_API_URL=http://localhost:8000  # or https://onside.engarde.media
SANKORE_API_URL=http://localhost:8001  # or https://sankore.engarde.media
MADANSARA_API_URL=http://localhost:8002  # or https://madansara.engarde.media

# Walker Agent API Keys (for authentication)
WALKER_AGENT_API_KEY_ONSIDE_SEO=wa_onside_production_<random>
WALKER_AGENT_API_KEY_SANKORE_PAID_ADS=wa_sankore_production_<random>
WALKER_AGENT_API_KEY_ONSIDE_CONTENT=wa_onside_production_<random>
WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE=wa_madansara_production_<random>
```

---

## 📊 Data Flow Architecture

```
WALKER AGENTS (1-4):
  ┌──────────────────────────────────────────────────────┐
  │ Langflow Python Function                             │
  └──┬────────┬────────┬────────┬─────────────────────┬──┘
     │        │        │        │                     │
     ▼        ▼        ▼        ▼                     ▼
  ┌─────┐ ┌──────┐ ┌──────┐ ┌──────────┐   ┌──────────────┐
  │Micro│ │BigQry│ │ZeroDB│ │PostgreSQL│   │ EnGarde API  │
  │svc  │ │(GCP) │ │(API) │ │(Main DB) │◄──┤ (stores      │
  └─────┘ └──────┘ └──────┘ └──────────┘   │ suggestions) │
     │        │        │         ▲          └──────────────┘
     │        │        │         │
     └────────┴────────┴─────────┘
              │
              ▼
     Analyze & generate suggestions
              │
              ▼
     POST /api/v1/walker-agents/suggestions


ENGARDE AGENTS (5-10):
  ┌──────────────────────────────────────────────────────┐
  │ Langflow Python Function                             │
  └──┬────────┬────────┬─────────────────────────────────┘
     │        │        │
     ▼        ▼        ▼
  ┌──────┐ ┌──────┐ ┌──────────┐   ┌──────────────┐
  │BigQry│ │ZeroDB│ │PostgreSQL│◄──┤ EnGarde API  │
  │(GCP) │ │(API) │ │(Main DB) │   │ (CRUD ops)   │
  └──────┘ └──────┘ └──────────┘   └──────────────┘
     │        │         ▲
     │        │         │
     └────────┴─────────┘
              │
              ▼
     Analyze & perform operations
              │
              ▼
     POST /api/v1/{resource}
```

---

## 🚀 Quick Deployment (30 Minutes)

### Prerequisites

1. **Environment variables** configured in Railway (langflow-server)
2. **Langflow** running at https://langflow.engarde.media
3. **Microservices** accessible:
   - Onside: http://localhost:8000 or deployed
   - Sankore: http://localhost:8001 or deployed
   - MadanSara: http://localhost:8002 or deployed
4. **BigQuery** dataset created: `engarde-production.engarde_analytics`
5. **ZeroDB** project created with valid API key
6. **PostgreSQL** main database running

### Deploy Each Agent (3 min each)

**For Agents 1-4 (Walker):**
1. Open Langflow → New Flow
2. Add "Python Function" node
3. Copy code from `FINAL_WALKER_AGENTS_COMPLETE.md`
4. Paste into Python Function
5. Add "Text Input" node (name: `tenant_id`, value: test UUID)
6. Connect: Text Input → Python Function (`tenant_id` parameter)
7. Click "Run" to test
8. Verify output shows `success: true`
9. Save flow (e.g., "SEO Walker Agent")

**For Agents 5-10 (EnGarde):**
- Same process, but copy from `FINAL_ENGARDE_AGENTS_COMPLETE.md`
- Some agents need additional inputs (e.g., campaign_id, content_id)

---

## ✅ Verification Checklist

### Walker Agents (1-4)

For each Walker agent, verify:
- [ ] Microservice API is accessible
- [ ] BigQuery query executes successfully
- [ ] ZeroDB events retrieved (or empty array if no events)
- [ ] Suggestions stored in PostgreSQL `walker_agent_suggestions` table
- [ ] Response shows `success: true`
- [ ] Response includes data_sources_used with all 4 sources

**Verification command:**
```bash
railway run --service Main -- python3 -c "
import os, psycopg2
conn = psycopg2.connect(os.getenv('DATABASE_PUBLIC_URL'))
cur = conn.cursor()
cur.execute('''
    SELECT agent_type, COUNT(*), MAX(created_at)
    FROM walker_agent_suggestions
    WHERE tenant_id = '<YOUR_TENANT_ID>'
    GROUP BY agent_type
''')
print('Walker Suggestions by Agent:')
for row in cur.fetchall():
    print(f'  {row[0]}: {row[1]} suggestions (latest: {row[2]})')
"
```

### EnGarde Agents (5-10)

For each EnGarde agent, verify:
- [ ] BigQuery query executes (if applicable)
- [ ] ZeroDB events retrieved (if applicable)
- [ ] PostgreSQL operation completes successfully
- [ ] Response shows `success: true`
- [ ] Records created/updated in appropriate table

**Verification command:**
```bash
railway run --service Main -- python3 -c "
import os, psycopg2
conn = psycopg2.connect(os.getenv('DATABASE_PUBLIC_URL'))
cur = conn.cursor()

# Campaigns
cur.execute('SELECT COUNT(*) FROM campaigns WHERE created_by LIKE \"%langflow%\"')
print(f'Langflow Campaigns: {cur.fetchone()[0]}')

# Analytics Reports
cur.execute('SELECT COUNT(*) FROM analytics_reports WHERE generated_at >= NOW() - INTERVAL '\''7 days'\''')
print(f'Recent Reports: {cur.fetchone()[0]}')
"
```

---

## 🔍 Troubleshooting

### BigQuery Authentication Error

**Error:** `google.auth.exceptions.DefaultCredentialsError`

**Solution:**
1. Verify `GOOGLE_APPLICATION_CREDENTIALS_JSON` is set
2. Check JSON is valid (use json.loads() to test)
3. Ensure service account has BigQuery Data Viewer + Job User roles

### ZeroDB 404 Not Found

**Error:** `404: {"detail":"Not Found"}`

**Solution:**
1. Verify `ZERODB_API_KEY` is complete (not truncated)
2. Check `ZERODB_PROJECT_ID` exists
3. Test manually:
```bash
curl -H "X-API-Key: $ZERODB_API_KEY" \
  "https://api.ainative.studio/api/v1/public/projects/$ZERODB_PROJECT_ID/events?limit=10"
```

### Microservice Connection Refused

**Error:** `Connection refused to Onside/Sankore/MadanSara`

**Solution:**
1. Check microservice is running: `docker ps | grep onside`
2. Verify port mapping: Onside=8000, Sankore=8001, MadanSara=8002
3. If deployed, update URL to Railway/production URL
4. Test endpoint: `curl http://localhost:8000/health`

### No Suggestions in Database

**Error:** Agent returns success but no rows in `walker_agent_suggestions`

**Solution:**
1. Check `WALKER_AGENT_API_KEY_*` is valid
2. Verify EnGarde API endpoint: `POST /api/v1/walker-agents/suggestions`
3. Check backend logs for validation errors
4. Ensure `tenant_id` exists in `tenants` table

---

## 📈 Production Deployment Recommendations

### Scheduling

Set up daily automated runs in Langflow:

**Walker Agents:** Daily at 9 AM
```
Cron Schedule: 0 9 * * *
Connect: Cron → Text Input (tenant_id) → Python Function
```

**EnGarde Agents:**
- Analytics Report: Weekly Monday 8 AM (`0 8 * * 1`)
- Performance Monitoring: Every 30 min (`*/30 * * * *`)
- Campaign Creation/Launcher: On-demand (triggered via API)
- Notification: After Walker agents complete

### Monitoring

1. **Langflow execution logs** - Check daily for errors
2. **Railway logs** - Monitor API calls and database queries
3. **Database row counts** - Track suggestions/campaigns growth
4. **Email notifications** - Verify users receive alerts

### Scaling

**Per-tenant deployment:**
- Duplicate each flow in Langflow
- Change `tenant_id` input to new tenant UUID
- All logic remains the same (fully dynamic)

**Multi-tenant batch:**
- Create a "Tenant Loop" flow
- Fetch all tenant IDs from PostgreSQL
- Loop through each tenant and run agent
- Useful for running all tenants nightly

---

## 📝 Summary

**What's Complete:**
- ✅ 4 Walker Agents (Onside, Sankore, MadanSara + BigQuery + ZeroDB + PostgreSQL)
- ✅ 6 EnGarde Agents (BigQuery + ZeroDB + PostgreSQL)
- ✅ All agents fetch real data from correct sources
- ✅ All agents cache insights in PostgreSQL
- ✅ Production-ready with error handling
- ✅ Fully parameterized by tenant_id
- ✅ Ready to deploy to Langflow

**Deployment Time:** 30 minutes for all 10 agents
**Maintenance:** Low (automated daily runs)
**Scaling:** Linear (duplicate flows per tenant)

---

**Files to Use:**
1. **FINAL_WALKER_AGENTS_COMPLETE.md** - Copy Agents 1-4
2. **FINAL_ENGARDE_AGENTS_COMPLETE.md** - Copy Agents 5-10
3. **This file** - Reference for deployment and verification

**Ready to deploy and generate real, data-driven marketing insights! 🚀**

