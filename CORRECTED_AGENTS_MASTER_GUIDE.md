# CORRECTED Production Agents - Master Guide

**All 10 agents with proper architecture - Ready to deploy**

---

## Critical Architecture Corrections

### ❌ What Was WRONG in Previous Versions

1. **Invented "lakehouse API"** - Does not exist
2. **Invented "BigQuery integration"** - Not implemented
3. **Invented "ZeroDB"** - Does not exist
4. **EnGarde agents using Walker microservices** - Incorrect, they use main database only

### ✅ What Is CORRECT Now

**Walker Agents (4):**
- Connect to their **dedicated microservices**: Onside, Sankore, MadanSara
- Each microservice has: MinIO + Airflow + PostgreSQL + Redis + Celery
- Store suggestions in: **Main EnGarde PostgreSQL** (`walker_agent_suggestions` table)

**EnGarde Agents (6):**
- Connect ONLY to: **Main EnGarde PostgreSQL database**
- Do NOT use Walker microservices
- Use tables: `campaigns`, `content`, `analytics_reports`, etc.

---

## Environment Variables (CORRECTED)

```bash
# Main EnGarde Backend API
ENGARDE_API_URL=https://api.engarde.media
ENGARDE_API_KEY=<main_backend_api_key>

# Walker Microservices
ONSIDE_API_URL=http://localhost:8000  # SEO + Content
SANKORE_API_URL=http://localhost:8001  # Paid Ads
MADANSARA_API_URL=http://localhost:8002  # Audience Intelligence

# Walker Agent API Keys (for authentication when storing suggestions)
WALKER_AGENT_API_KEY_ONSIDE_SEO=wa_onside_production_<random>
WALKER_AGENT_API_KEY_SANKORE_PAID_ADS=wa_sankore_production_<random>
WALKER_AGENT_API_KEY_ONSIDE_CONTENT=wa_onside_production_<random>
WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE=wa_madansara_production_<random>
```

---

## File Organization

| File | Contains | Purpose |
|------|----------|---------|
| `CORRECTED_WALKER_AGENTS_ALL_4.md` | 4 Walker Agents | Connect to microservices, store in main DB |
| `CORRECTED_ENGARDE_AGENTS_ALL_6.md` | 6 EnGarde Agents | Work with main database only |
| `CORRECTED_AGENTS_MASTER_GUIDE.md` | This file | Overview and deployment guide |

---

## Agent Summary

### Walker Agents (Fetch from Microservices → Store in Main DB)

| # | Agent | Microservice | Port | Data Source | Stores In |
|---|-------|--------------|------|-------------|-----------|
| 1 | SEO Walker | Onside | 8000 | SEO metrics, keywords, backlinks | walker_agent_suggestions |
| 2 | Paid Ads Walker | Sankore | 8001 | Ad performance, ROI, keywords | walker_agent_suggestions |
| 3 | Content Walker | Onside | 8000 | Content gaps, performance | walker_agent_suggestions |
| 4 | Audience Intelligence | MadanSara | 8002 | Churn risk, segments, carts | walker_agent_suggestions |

### EnGarde Agents (Main Database Only)

| # | Agent | Data Source | Purpose |
|---|-------|-------------|---------|
| 5 | Campaign Creation | Main PostgreSQL (`campaigns`, `templates`) | Create new campaigns |
| 6 | Analytics Report | Main PostgreSQL (`campaigns`, `analytics`) | Generate reports |
| 7 | Content Approval | Main PostgreSQL (`content`) | Auto-approve content |
| 8 | Campaign Launcher | Main PostgreSQL (`campaigns`) | Launch campaigns |
| 9 | Notification | Main PostgreSQL (`users`, `walker_agent_suggestions`) | Send notifications |
| 10 | Performance Monitoring | Main PostgreSQL (`campaigns`, `analytics`) | Monitor KPIs |

---

## Data Flow Diagrams

### Walker Agent Flow

```
┌────────────────────────────────────────────────────────────┐
│  Langflow                                                   │
│  - Receives tenant_id                                       │
│  - Runs Python Function (Walker Agent)                     │
└────┬──────────────────────────────────────────────────┬────┘
     │                                                    │
     ▼                                                    ▼
┌─────────────────────┐                    ┌──────────────────────────┐
│ Walker Microservice │                    │ Main EnGarde Backend API │
│ (Onside/Sankore/    │                    │ (https://api.engarde.    │
│  MadanSara)         │                    │  media)                  │
│                     │                    │                          │
│ MinIO + Airflow +   │                    │ Stores suggestions in:   │
│ PostgreSQL + Redis  │                    │ walker_agent_suggestions │
│                     │                    │ table                    │
└─────────────────────┘                    └──────────────────────────┘
     │                                                    ▲
     │  Fetches data (SEO,                              │
     │  ads, content, audience)                         │
     │                                                   │
     └───────────────────────────────────────────────────┘
              Generates suggestions, sends to main DB
```

### EnGarde Agent Flow

```
┌────────────────────────────────────────────────────────────┐
│  Langflow                                                   │
│  - Receives tenant_id (+ other params)                      │
│  - Runs Python Function (EnGarde Agent)                     │
└────────────────────────────┬───────────────────────────────┘
                             │
                             ▼
            ┌──────────────────────────────────┐
            │  Main EnGarde Backend API        │
            │  (https://api.engarde.media)     │
            │                                  │
            │  Main PostgreSQL Database:       │
            │  - campaigns                     │
            │  - content                       │
            │  - analytics_reports             │
            │  - notifications                 │
            │  - users                         │
            └──────────────────────────────────┘
                      │
                      ▼
            Creates/reads/updates records
            in main database tables
```

---

## Quick Deployment (30 Minutes)

### Prerequisites

1. **Environment variables** set in Railway (langflow-server)
2. **Langflow running**: https://langflow.engarde.media
3. **Microservices running**:
   - Onside: http://localhost:8000
   - Sankore: http://localhost:8001
   - MadanSara: http://localhost:8002

### Deploy Each Agent (3 min each)

1. Open Langflow → New Flow
2. Add "Python Function" node
3. Copy agent code from files:
   - Agents 1-4: `CORRECTED_WALKER_AGENTS_ALL_4.md`
   - Agents 5-10: `CORRECTED_ENGARDE_AGENTS_ALL_6.md`
4. Paste into Python Function
5. Add "Text Input" node (name: `tenant_id`)
6. Connect Text Input → Python Function
7. Run with test tenant_id
8. Save flow

---

## Testing Checklist

### For Walker Agents (1-4)

- [ ] Microservice is running and accessible
- [ ] Agent fetches data from microservice successfully
- [ ] Suggestions are generated from real data
- [ ] Suggestions stored in `walker_agent_suggestions` table
- [ ] Response shows `success: true`

### For EnGarde Agents (5-10)

- [ ] Main backend API is accessible
- [ ] Agent performs database operation successfully
- [ ] Records created/updated in appropriate table
- [ ] Response shows `success: true`

---

## Verification Commands

### Check Walker Suggestions in Database

```bash
railway run --service Main -- python3 -c "
import os, psycopg2
conn = psycopg2.connect(os.getenv('DATABASE_PUBLIC_URL'))
cur = conn.cursor()

# Count suggestions by agent type
cur.execute('''
    SELECT agent_type, COUNT(*), MAX(created_at)
    FROM walker_agent_suggestions
    GROUP BY agent_type
''')

print('Walker Agent Suggestions:')
for row in cur.fetchall():
    print(f'  {row[0]}: {row[1]} suggestions (latest: {row[2]})')
"
```

### Check Campaigns Created

```bash
railway run --service Main -- python3 -c "
import os, psycopg2
conn = psycopg2.connect(os.getenv('DATABASE_PUBLIC_URL'))
cur = conn.cursor()

cur.execute('SELECT id, name, status, created_at FROM campaigns ORDER BY created_at DESC LIMIT 5')

print('Recent Campaigns:')
for row in cur.fetchall():
    print(f'  {row[1]}: {row[2]} ({row[3]})')
"
```

---

## API Endpoints Reference

### Onside Microservice (Port 8000)

```
GET /api/v1/seo/analytics/{tenant_id}      # SEO metrics
GET /api/v1/content/analytics/{tenant_id}  # Content data
```

### Sankore Microservice (Port 8001)

```
GET /api/v1/ads/performance/{tenant_id}    # Paid ads data
```

### MadanSara Microservice (Port 8002)

```
GET /api/v1/audience/analytics/{tenant_id} # Audience data
```

### Main EnGarde Backend API

```
# Walker suggestions
POST /api/v1/walker-agents/suggestions      # Store suggestion
GET  /api/v1/walker-agents/suggestions/{tenant_id}/recent

# Campaigns
GET  /api/v1/campaigns/templates
POST /api/v1/campaigns
POST /api/v1/campaigns/{id}/launch

# Content
GET  /api/v1/content/{id}
POST /api/v1/content/{id}/approval

# Analytics
GET  /api/v1/analytics/campaigns/{tenant_id}
POST /api/v1/analytics/reports

# Notifications
POST /api/v1/notifications/send

# Monitoring
GET  /api/v1/monitoring/metrics/{tenant_id}
POST /api/v1/monitoring/alerts
```

---

## Troubleshooting

### Walker Agent Fails to Connect to Microservice

**Error**: Connection refused to Onside/Sankore/MadanSara

**Solution**:
1. Verify microservice is running: `docker ps | grep onside`
2. Check port mapping: Onside=8000, Sankore=8001, MadanSara=8002
3. If using Railway, update URL to Railway service URL
4. Test endpoint manually: `curl http://localhost:8000/health`

### Suggestions Not Appearing in Database

**Error**: Agent returns success but no rows in `walker_agent_suggestions`

**Solution**:
1. Check API key is valid: `WALKER_AGENT_API_KEY_*`
2. Verify endpoint: `POST /api/v1/walker-agents/suggestions`
3. Check backend logs for validation errors
4. Ensure `tenant_id` exists in `tenants` table

### EnGarde Agent Can't Access Main Database

**Error**: 401 Unauthorized or 403 Forbidden

**Solution**:
1. Verify `ENGARDE_API_KEY` is set correctly
2. Check API key has necessary permissions
3. Test API endpoint manually: `curl -H "Authorization: Bearer $ENGARDE_API_KEY" https://api.engarde.media/api/v1/health`

---

## Summary

**All 10 agents are now CORRECTED and production-ready:**

✅ **Walker Agents** connect to actual microservices (Onside, Sankore, MadanSara)
✅ **Walker suggestions** stored in main PostgreSQL `walker_agent_suggestions` table
✅ **EnGarde Agents** use ONLY main PostgreSQL database
✅ **No fake services** (no BigQuery, no ZeroDB, no generic "lakehouse API")
✅ **Real architecture** matching actual system implementation

**Ready to deploy to Langflow and start generating real marketing insights!**

---

**Files to use:**
1. `CORRECTED_WALKER_AGENTS_ALL_4.md` - Copy agents 1-4
2. `CORRECTED_ENGARDE_AGENTS_ALL_6.md` - Copy agents 5-10
3. This file - Reference for deployment and testing

**Deployment time**: 30 minutes for all 10 agents
**Maintenance**: Low (automated daily runs via Cron Schedule)

