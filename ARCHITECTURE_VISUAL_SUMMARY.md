# EnGarde Langflow Agents - Complete Architecture

**Visual guide to all 10 production agents and their data flows**

---

## 🏗️ Complete System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           LANGFLOW ORCHESTRATION                         │
│                      (https://langflow.engarde.media)                    │
└────────┬────────────────────────────────────────────────────────────┬───┘
         │                                                             │
         │                                                             │
    ┌────▼─────┐                                                  ┌───▼────┐
    │  WALKER  │                                                  │ENGARDE │
    │  AGENTS  │                                                  │ AGENTS │
    │  (1-4)   │                                                  │ (5-10) │
    └────┬─────┘                                                  └───┬────┘
         │                                                             │
         │  4 Data Sources                                            │  3 Data Sources
         │                                                             │
    ┌────▼─────────────────────────────────────┐         ┌───────────▼──────────────┐
    │                                           │         │                          │
    │  1️⃣  Domain Microservice                 │         │  1️⃣  BigQuery Data Lake  │
    │      - Onside (SEO + Content)            │         │      (Historical)        │
    │      - Sankore (Paid Ads)                │         │                          │
    │      - MadanSara (Audience)              │         │  2️⃣  ZeroDB             │
    │                                           │         │      (Real-time)         │
    │  2️⃣  BigQuery Data Lake                  │         │                          │
    │      (Historical analytics)              │         │  3️⃣  PostgreSQL         │
    │                                           │         │      (Main database)     │
    │  3️⃣  ZeroDB                              │         │                          │
    │      (Real-time events)                  │         └──────────────────────────┘
    │                                           │
    │  4️⃣  PostgreSQL                          │
    │      (Store suggestions)                 │
    │                                           │
    └───────────────────────────────────────────┘
```

---

## 🎯 Walker Agents (1-4) - Data Flow

### Agent 1: SEO Walker

```
┌──────────────────────────────────────────────────────────────────────┐
│  INPUT: tenant_id                                                     │
└────────────────────────────┬─────────────────────────────────────────┘
                             │
         ┌───────────────────┼───────────────────┬────────────────┐
         │                   │                   │                │
         ▼                   ▼                   ▼                ▼
    ┌─────────┐         ┌─────────┐        ┌─────────┐     ┌──────────┐
    │ Onside  │         │BigQuery │        │ ZeroDB  │     │PostgreSQL│
    │Micro-   │         │Data Lake│        │Real-time│     │  Main    │
    │service  │         │         │        │         │     │ Database │
    └────┬────┘         └────┬────┘        └────┬────┘     └─────┬────┘
         │                   │                   │                │
         │ GET /api/v1/      │ Query 90 days    │ GET events:   │
         │ seo/analytics     │ campaign_metrics │ seo_crawl_    │
         │ /{tenant_id}      │ WHERE platform=  │ error         │
         │                   │ 'google_search'  │               │
         │                   │                  │               │
         ▼                   ▼                  ▼               │
    ┌────────────────────────────────────────────────┐          │
    │  ANALYSIS & SUGGESTION GENERATION               │          │
    │                                                 │          │
    │  • Keyword ranking drops (from Onside)         │          │
    │  • Traffic decline trends (from BigQuery)      │          │
    │  • Active crawl errors (from ZeroDB)           │          │
    │                                                 │          │
    │  Output: List of actionable suggestions        │          │
    └─────────────────────┬───────────────────────────┘          │
                          │                                      │
                          │  POST /api/v1/walker-agents/         │
                          │  suggestions                         │
                          └──────────────────────────────────────▶│
                                                                  │
                          ┌───────────────────────────────────────┘
                          ▼
                    walker_agent_suggestions table:
                    - tenant_id
                    - agent_type: 'seo'
                    - suggestion_type
                    - title
                    - description
                    - priority
                    - estimated_revenue_increase
                    - confidence_score
                    - actions
```

### Agent 2: Paid Ads Walker

```
┌──────────────────────────────────────────────────────────────────────┐
│  INPUT: tenant_id                                                     │
└────────────────────────────┬─────────────────────────────────────────┘
                             │
         ┌───────────────────┼───────────────────┬────────────────┐
         │                   │                   │                │
         ▼                   ▼                   ▼                ▼
    ┌─────────┐         ┌─────────┐        ┌─────────┐     ┌──────────┐
    │Sankore  │         │BigQuery │        │ ZeroDB  │     │PostgreSQL│
    │Micro-   │         │Data Lake│        │Real-time│     │  Main    │
    │service  │         │         │        │         │     │ Database │
    └────┬────┘         └────┬────┘        └────┬────┘     └─────┬────┘
         │                   │                   │                │
         │ GET /api/v1/      │ Query 30 days    │ GET events:   │
         │ ads/performance   │ campaign_metrics │ ad_bid_       │
         │ /{tenant_id}      │ WHERE platform=  │ change        │
         │                   │ 'meta/google'    │               │
         │                   │                  │               │
         ▼                   ▼                  ▼               │
    ┌────────────────────────────────────────────────┐          │
    │  ANALYSIS & SUGGESTION GENERATION               │          │
    │                                                 │          │
    │  • Low ROAS campaigns (from Sankore)           │          │
    │  • Budget reallocation (from BigQuery)         │          │
    │  • Bid strategy changes (from ZeroDB)          │          │
    │                                                 │          │
    │  Output: List of actionable suggestions        │          │
    └─────────────────────┬───────────────────────────┘          │
                          │                                      │
                          │  POST /api/v1/walker-agents/         │
                          │  suggestions                         │
                          └──────────────────────────────────────▶│
                                                                  │
                          ┌───────────────────────────────────────┘
                          ▼
                    walker_agent_suggestions table:
                    - agent_type: 'paid_ads'
                    - suggestion_type
                    - title, description, priority
```

### Agent 3: Content Walker

```
Same 4-source pattern:
Onside → Content gaps, performance
BigQuery → Historical engagement metrics
ZeroDB → Real-time content views
PostgreSQL → Store content suggestions
```

### Agent 4: Audience Intelligence Walker

```
Same 4-source pattern:
MadanSara → Churn risk, segments, abandoned carts
BigQuery → Historical customer behavior
ZeroDB → Real-time audience events
PostgreSQL → Store audience suggestions
```

---

## 🎯 EnGarde Agents (5-10) - Data Flow

### Agent 5: Campaign Creation

```
┌──────────────────────────────────────────────────────────────────────┐
│  INPUT: tenant_id, campaign_name, platform                           │
└────────────────────────────┬─────────────────────────────────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
    ┌─────────┐         ┌─────────┐        ┌──────────┐
    │BigQuery │         │ ZeroDB  │        │PostgreSQL│
    │Data Lake│         │Real-time│        │  Main    │
    └────┬────┘         └────┬────┘        └─────┬────┘
         │                   │                   │
         │ Query template   │ Check platform    │ GET /api/v1/
         │ performance      │ health status     │ campaigns/
         │ history          │                   │ templates
         │                  │                   │
         ▼                  ▼                   │
    ┌──────────────────────────────┐           │
    │  CAMPAIGN GENERATION          │           │
    │                               │           │
    │  • Select best template      │           │
    │  • Customize for tenant      │           │
    │  • Set budget & targeting    │           │
    │                               │           │
    └───────────┬───────────────────┘           │
                │                               │
                │  POST /api/v1/campaigns       │
                └───────────────────────────────▶│
                                                 │
                ┌────────────────────────────────┘
                ▼
          campaigns table:
          - tenant_id
          - name
          - platform
          - status: 'draft'
          - created_by: 'langflow_agent'
```

### Agent 6: Analytics Report

```
┌──────────────────────────────────────────────────────────────────────┐
│  INPUT: tenant_id, days_back                                         │
└────────────────────────────┬─────────────────────────────────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
    ┌─────────┐         ┌─────────┐        ┌──────────┐
    │BigQuery │         │ ZeroDB  │        │PostgreSQL│
    │Data Lake│         │Real-time│        │  Main    │
    └────┬────┘         └────┬────┘        └─────┬────┘
         │                   │                   │
         │ Aggregate        │ Latest KPI        │
         │ campaign metrics │ updates           │
         │ (30/60/90 days)  │                   │
         │                  │                   │
         ▼                  ▼                   │
    ┌──────────────────────────────┐           │
    │  REPORT GENERATION            │           │
    │                               │           │
    │  • Platform breakdown        │           │
    │  • Performance trends        │           │
    │  • ROI analysis              │           │
    │  • Recommendations           │           │
    │                               │           │
    └───────────┬───────────────────┘           │
                │                               │
                │  POST /api/v1/analytics/      │
                │  reports                      │
                └───────────────────────────────▶│
                                                 │
                ┌────────────────────────────────┘
                ▼
          analytics_reports table:
          - tenant_id
          - report_type: 'campaign_performance'
          - data: {platforms, metrics, trends}
          - generated_at
```

### Agent 7: Content Approval

```
3-source pattern:
BigQuery → Content performance history
ZeroDB → Real-time quality scores
PostgreSQL → GET content, POST approval
```

### Agent 8: Campaign Launcher

```
3-source pattern:
BigQuery → Launch history & success rates
ZeroDB → Platform health check
PostgreSQL → POST /api/v1/campaigns/{id}/launch
```

### Agent 9: Notification

```
2-source pattern (minimal):
ZeroDB → Recent events requiring notification
PostgreSQL → GET users, POST /api/v1/notifications/send
```

### Agent 10: Performance Monitoring

```
3-source pattern:
BigQuery → KPI trend analysis
ZeroDB → Real-time alert triggers
PostgreSQL → POST /api/v1/monitoring/alerts
```

---

## 📊 Data Source Details

### 1️⃣ Domain Microservices (Walker Agents Only)

**Onside (Port 8000):**
- MinIO object storage
- Airflow workflow orchestration
- PostgreSQL (microservice-specific DB)
- Redis caching
- Celery task queue

Endpoints:
- `GET /api/v1/seo/analytics/{tenant_id}` - SEO metrics
- `GET /api/v1/content/analytics/{tenant_id}` - Content data

**Sankore (Port 8001):**
- Same tech stack as Onside
- Endpoints:
  - `GET /api/v1/ads/performance/{tenant_id}` - Paid ads data

**MadanSara (Port 8002):**
- Same tech stack as Onside
- Endpoints:
  - `GET /api/v1/audience/analytics/{tenant_id}` - Audience data

### 2️⃣ BigQuery Data Lake (All Agents)

**Project:** `engarde-production`
**Dataset:** `engarde_analytics`

Tables:
- `campaign_metrics` - Time-series campaign performance
- `platform_events` - Integration webhook events
- `integration_raw_data` - Raw data from platforms
- `audience_insights` - Langflow-generated insights

Authentication:
- Service account JSON via `GOOGLE_APPLICATION_CREDENTIALS_JSON`
- Requires roles: BigQuery Data Viewer + Job User

### 3️⃣ ZeroDB (All Agents)

**API:** `https://api.ainative.studio/api/v1`
**Purpose:** Real-time event sourcing

Event types:
- `seo_crawl_error` - SEO issues
- `ad_bid_change` - Paid ads bid updates
- `content_engagement` - Content interactions
- `churn_risk` - Customer churn signals
- `kpi_update` - Real-time KPI changes
- `platform_health` - Platform status

Authentication:
- Header: `X-API-Key: {ZERODB_API_KEY}`
- Project-scoped queries

### 4️⃣ PostgreSQL (All Agents)

**Main EnGarde Database**

Tables:
- `walker_agent_suggestions` - All Walker agent outputs
- `campaigns` - Marketing campaigns
- `content` - Content items
- `analytics_reports` - Generated reports
- `notifications` - User notifications
- `monitoring_alerts` - Performance alerts
- `tenants` - Multi-tenant isolation
- `users` - User accounts

Access:
- Via EnGarde API: `https://api.engarde.media/api/v1/`
- Authentication: Bearer token (`ENGARDE_API_KEY` or `WALKER_AGENT_API_KEY_*`)

---

## 🔄 Complete Request Flow Example

### User triggers SEO Walker for tenant `abc123`

```
1. Langflow receives: tenant_id = "abc123"

2. SEO Walker Agent executes:

   Step 1: Fetch Onside microservice
   → GET http://localhost:8000/api/v1/seo/analytics/abc123
   → Returns: {keyword_rankings: [...], backlinks: [...]}

   Step 2: Query BigQuery
   → SELECT * FROM campaign_metrics WHERE tenant_id='abc123' AND platform='google_search'
   → Returns: 90 days of SEO performance data

   Step 3: Query ZeroDB
   → GET https://api.ainative.studio/api/v1/public/projects/{id}/events?tenant_id=abc123&event_type=seo_crawl_error
   → Returns: [{url: "...", error_type: "404"}, ...]

   Step 4: Analyze all 3 data sources
   → Generate suggestions:
     - "Keyword 'marketing automation' dropped 5 positions"
     - "Organic traffic declined 22% over 30 days"
     - "Fix 12 active crawl errors"

   Step 5: Store in PostgreSQL
   → POST https://api.engarde.media/api/v1/walker-agents/suggestions
   → Body: {tenant_id, agent_type: 'seo', suggestions: [...]}
   → Inserts rows into walker_agent_suggestions table

3. Langflow returns: {success: true, suggestions_generated: 3}

4. User sees suggestions in EnGarde dashboard
```

---

## 🎯 Key Architectural Principles

### 1. Separation of Concerns

**Walker Agents:**
- Domain-specific intelligence
- Connect to specialized microservices
- Generate actionable suggestions
- Store in central database

**EnGarde Agents:**
- Cross-cutting workflows
- Work with aggregated data only
- Perform automation tasks
- Use central database exclusively

### 2. Data Layering

**Historical (BigQuery):**
- 30-90 day trends
- Aggregated metrics
- Time-series analysis

**Real-time (ZeroDB):**
- Live events
- Operational metrics
- Immediate alerts

**Transactional (PostgreSQL):**
- Master data (tenants, users, campaigns)
- Cached insights (suggestions, reports)
- Workflow state

**Domain-specific (Microservices):**
- Specialized data processing
- ETL pipelines (Airflow)
- Object storage (MinIO)

### 3. Multi-Tenancy

All agents are **fully dynamic** and parameterized by `tenant_id`:
- No hardcoded tenant data
- Same code for all tenants
- Easy to duplicate flows per tenant
- Supports batch processing

---

## ✅ Verification Matrix

| Agent | Microservice | BigQuery | ZeroDB | PostgreSQL | Status |
|-------|--------------|----------|---------|------------|--------|
| 1. SEO Walker | ✅ Onside | ✅ Yes | ✅ Yes | ✅ Store | Ready |
| 2. Paid Ads Walker | ✅ Sankore | ✅ Yes | ✅ Yes | ✅ Store | Ready |
| 3. Content Walker | ✅ Onside | ✅ Yes | ✅ Yes | ✅ Store | Ready |
| 4. Audience Intelligence | ✅ MadanSara | ✅ Yes | ✅ Yes | ✅ Store | Ready |
| 5. Campaign Creation | ❌ N/A | ✅ Yes | ✅ Yes | ✅ CRUD | Ready |
| 6. Analytics Report | ❌ N/A | ✅ Yes | ✅ Yes | ✅ CRUD | Ready |
| 7. Content Approval | ❌ N/A | ✅ Yes | ✅ Yes | ✅ CRUD | Ready |
| 8. Campaign Launcher | ❌ N/A | ✅ Yes | ✅ Yes | ✅ CRUD | Ready |
| 9. Notification | ❌ N/A | ❌ N/A | ✅ Yes | ✅ CRUD | Ready |
| 10. Performance Monitoring | ❌ N/A | ✅ Yes | ✅ Yes | ✅ CRUD | Ready |

---

**All 10 agents are production-ready with correct architecture! 🚀**

**Next step:** Deploy to Langflow using the guide in `DEPLOYMENT_READY_SUMMARY.md`
