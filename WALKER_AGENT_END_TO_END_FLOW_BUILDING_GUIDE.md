# Walker Agent End-to-End Flow Building Guide

## Complete Step-by-Step Instructions for Building Walker Agents in Langflow UI

This guide provides comprehensive instructions for assembling En Garde custom components into complete, production-ready Walker agent flows that:
- Generate daily strategy prompts via microservices
- Interface with users through WhatsApp, Email, or In-App Chat
- Allow user control (execute, pause, request details)
- Persist user customizations and data integrations across admin updates

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Flow Component Assembly](#flow-component-assembly)
4. [Building Each Walker Agent Type](#building-each-walker-agent-type)
5. [User Data Persistence Strategy](#user-data-persistence-strategy)
6. [Admin Update Workflow](#admin-update-workflow)
7. [Testing & Validation](#testing--validation)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Setup

1. **Langflow Deployment Running**
   ```bash
   railway status --service langflow-server
   # Should show: langflow.engarde.media (or Railway URL)
   ```

2. **Environment Variables Configured**
   ```bash
   railway variables --service langflow-server
   ```
   Required variables:
   - `ENGARDE_API_URL` = `https://api.engarde.media`
   - `WALKER_AGENT_API_KEY_ONSIDE_SEO`
   - `WALKER_AGENT_API_KEY_ONSIDE_CONTENT`
   - `WALKER_AGENT_API_KEY_SANKORE_PAID_ADS`
   - `WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE`

3. **Custom Components Loaded**
   - Location: `/production-backend/langflow/custom_components/walker_agents/`
   - Components should appear in Langflow component palette
   - If missing, restart Langflow: `railway restart --service langflow-server`

4. **Database Tables Created**
   ```bash
   # Verify tables exist
   railway run --service Main python -c "
   from app.database import engine
   from sqlalchemy import inspect
   inspector = inspect(engine)
   tables = inspector.get_table_names()
   print('walker_agent_suggestions' in tables)
   print('walker_agent_api_keys' in tables)
   print('walker_agent_notification_preferences' in tables)
   "
   ```

5. **Microservices Running**
   - OnSide (SEO + Content): Port 8000
   - Sankore (Paid Ads): Port 8001
   - MadanSara (Audience): Port 8002

---

## Architecture Overview

### Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    LANGFLOW FLOW (Scheduled Daily)              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Schedule Trigger (Cron)                                    │
│         ↓                                                       │
│  2. Tenant ID Input (from user setup)                          │
│         ↓                                                       │
│  3. Data Fetching (Multi-Source)                               │
│         ├── Microservice API (domain-specific data)            │
│         ├── BigQuery (historical analytics 30-90 days)         │
│         ├── ZeroDB (real-time events, 24 hours)                │
│         └── PostgreSQL (cached suggestions, preferences)       │
│         ↓                                                       │
│  4. AI Analysis (GPT-4 via LangChain)                          │
│         ↓                                                       │
│  5. Suggestion Builder (Format & Structure)                    │
│         ↓                                                       │
│  6. Backend API Submit (POST with Bearer Token)                │
│         ↓                                                       │
│  7. Notification Dispatch (Email/WhatsApp/Chat)                │
│         ↓                                                       │
│  8. User Interaction Handler (Execute/Pause/Details)           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Component Categories

| Category | Components | Purpose |
|----------|-----------|---------|
| **Triggers** | Schedule Trigger | Daily cron job execution |
| **Inputs** | Tenant ID Input | User-specific configuration |
| **Data Sources** | HTTP Request, Custom Fetchers | Multi-source data retrieval |
| **Processing** | AI Model, Prompt Templates | Strategy generation |
| **Builders** | Walker Suggestion Builder | Format suggestions |
| **Output** | HTTP Request (POST) | Submit to backend API |
| **Handlers** | User Action Router | Process user commands |

---

## Flow Component Assembly

### Core Flow Template (All Walker Agents)

Every Walker agent follows this standard structure:

```
┌────────────────────┐
│ 1. TRIGGER         │  Schedule Trigger (Daily Cron)
└──────┬─────────────┘
       │
       ↓
┌────────────────────┐
│ 2. INPUT           │  Tenant ID Input Component
└──────┬─────────────┘
       │
       ↓
┌────────────────────┐
│ 3. DATA FETCH      │  Multi-Source Data Retrieval
│                    │  ├── Microservice API
│                    │  ├── BigQuery Historical
│                    │  ├── ZeroDB Real-time
│                    │  └── PostgreSQL Cache
└──────┬─────────────┘
       │
       ↓
┌────────────────────┐
│ 4. PROCESS         │  AI Analysis (GPT-4)
│                    │  ├── Prompt Template
│                    │  ├── Context Assembly
│                    │  └── Strategy Generation
└──────┬─────────────┘
       │
       ↓
┌────────────────────┐
│ 5. BUILD           │  Walker Suggestion Builder
│                    │  ├── Format Suggestions
│                    │  ├── Add Metadata
│                    │  └── Calculate Confidence
└──────┬─────────────┘
       │
       ↓
┌────────────────────┐
│ 6. SUBMIT          │  HTTP POST to Backend API
│                    │  ├── Bearer Token Auth
│                    │  ├── Batch ID Assignment
│                    │  └── Error Handling
└──────┬─────────────┘
       │
       ↓
┌────────────────────┐
│ 7. NOTIFY          │  Notification Dispatch
│                    │  ├── Check User Preferences
│                    │  ├── Send Email (Brevo)
│                    │  ├── Send WhatsApp (Twilio)
│                    │  └── Send Chat (WebSocket)
└──────┬─────────────┘
       │
       ↓
┌────────────────────┐
│ 8. INTERACT        │  User Action Handler
│                    │  ├── Listen for Commands
│                    │  ├── Execute Actions
│                    │  ├── Pause/Resume
│                    │  └── Provide Details
└────────────────────┘
```

---

## Building Each Walker Agent Type

### 1. SEO Walker Agent Flow

#### Step 1: Create New Flow
1. Open Langflow UI: `https://langflow.engarde.media`
2. Click "New Flow"
3. Name: `SEO Walker Agent - Production`
4. Description: `Daily SEO analysis and strategy recommendations`

#### Step 2: Add Schedule Trigger
1. Search components for "Schedule Trigger"
2. Drag to canvas
3. Configure:
   - **Name**: `Daily SEO Analysis Trigger`
   - **Schedule**: `0 5 * * *` (5:00 AM UTC daily)
   - **Timezone**: `UTC`
   - **Enabled**: `true`

#### Step 3: Add Tenant ID Input
1. Search for "Tenant ID Input" custom component
2. Connect to Schedule Trigger output
3. Configure:
   - **Label**: `Target Tenant`
   - **Info**: `Enter the UUID of the tenant to analyze`
   - **Advanced**: Mark as "Required"

**User Customization Point**: Each user's tenant ID is stored here. When admin updates the flow, this node preserves the user's tenant ID.

#### Step 4: Add Multi-Source Data Fetcher

##### 4a. Microservice Data (OnSide SEO)
1. Add "HTTP Request" component
2. Configure:
   - **Method**: `GET`
   - **URL**: `http://onside:8000/api/v1/seo/analyze/{tenant_id}`
   - **Headers**:
     ```json
     {
       "Authorization": "Bearer ${WALKER_AGENT_API_KEY_ONSIDE_SEO}",
       "Content-Type": "application/json"
     }
     ```
   - **URL Variables**:
     - `tenant_id`: Connect from Tenant ID Input output

##### 4b. BigQuery Historical Data
1. Add "BigQuery Query" component (if available) or HTTP Request
2. Configure:
   - **Project**: From environment variable
   - **Query**:
     ```sql
     SELECT
       date,
       keyword,
       position,
       impressions,
       clicks,
       ctr
     FROM `engarde-analytics.seo_metrics.rankings`
     WHERE tenant_id = @tenant_id
       AND date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
     ORDER BY date DESC
     ```
   - **Parameters**: `tenant_id` from Tenant ID Input

##### 4c. ZeroDB Real-Time Data
1. Add "HTTP Request" component
2. Configure:
   - **Method**: `POST`
   - **URL**: `http://zerodb:6379/api/query`
   - **Body**:
     ```json
     {
       "query": "SELECT * FROM seo_events WHERE tenant_id = '{tenant_id}' AND timestamp >= NOW() - INTERVAL '24 hours'",
       "format": "json"
     }
     ```

##### 4d. PostgreSQL Cached Suggestions
1. Add "PostgreSQL Query" component
2. Configure:
   - **Connection String**: From environment variable
   - **Query**:
     ```sql
     SELECT * FROM walker_agent_suggestions
     WHERE tenant_id = $1
       AND agent_type = 'seo'
       AND created_at >= NOW() - INTERVAL '30 days'
     ORDER BY created_at DESC
     LIMIT 50
     ```
   - **Parameters**: `[$1: tenant_id]`

#### Step 5: Merge Data Sources
1. Add "Data Merger" component (or Python Code component)
2. Connect all 4 data sources
3. Python code:
   ```python
   def merge_data(microservice, bigquery, zerodb, postgres):
       return {
           "current_metrics": microservice,
           "historical_trends": bigquery,
           "realtime_events": zerodb,
           "past_suggestions": postgres,
           "tenant_id": microservice.get("tenant_id")
       }
   ```

#### Step 6: AI Analysis with GPT-4
1. Add "ChatOpenAI" component
2. Configure:
   - **Model**: `gpt-4`
   - **Temperature**: `0.7`
   - **Max Tokens**: `2000`

3. Add "Prompt Template" component before AI
4. Template:
   ```
   You are an expert SEO strategist analyzing data for a client.

   Current Metrics:
   {current_metrics}

   Historical Trends (90 days):
   {historical_trends}

   Real-time Events (24 hours):
   {realtime_events}

   Past Suggestions:
   {past_suggestions}

   Based on this data, generate 3-5 high-impact SEO strategy recommendations.
   For each recommendation, provide:
   1. Title (concise, actionable)
   2. Description (detailed explanation)
   3. Estimated Revenue Increase ($ amount)
   4. Confidence Score (0.0-1.0)
   5. Priority (high/medium/low)
   6. Suggested Actions (step-by-step)
   7. CTA URL (link to implement in EnGarde dashboard)

   Format as JSON array.
   ```

#### Step 7: Build Suggestions
1. Add "Walker Suggestion Builder" component
2. Connect AI output
3. Configure for each suggestion:
   - **Suggestion Type**: Dropdown (keyword_opportunity, technical_seo, backlink_strategy, content_optimization)
   - **Title**: From AI output
   - **Description**: From AI output
   - **Estimated Revenue**: From AI output (parsed)
   - **Confidence Score**: From AI output (parsed)
   - **Priority**: Based on confidence + revenue
   - **Actions**: From AI output (JSON array)
   - **CTA URL**: Construct: `https://app.engarde.media/seo/implement/{suggestion_id}`

#### Step 8: Submit to Backend API
1. Add "HTTP Request" component
2. Configure:
   - **Method**: `POST`
   - **URL**: `${ENGARDE_API_URL}/api/v1/walker-agents/suggestions`
   - **Headers**:
     ```json
     {
       "Authorization": "Bearer ${WALKER_AGENT_API_KEY_ONSIDE_SEO}",
       "Content-Type": "application/json"
     }
     ```
   - **Body**: Connect from Walker Suggestion Builder output
   - **Retry Logic**:
     - Max retries: 3
     - Backoff: Exponential (1s, 2s, 4s)

#### Step 9: Notification Handler (Automatic)
*Note: Notifications are handled by backend API automatically after POST. No additional nodes needed.*

Backend will:
1. Check user notification preferences
2. Send email via Brevo (if enabled)
3. Send WhatsApp via Twilio (if enabled)
4. Send chat notification via WebSocket (if enabled)

#### Step 10: User Interaction Handler
1. Add "WebSocket Listener" component (for chat commands)
2. Configure:
   - **Channel**: `walker-agent-{tenant_id}-seo`
   - **Event Types**: `['execute', 'pause', 'details', 'feedback']`

3. Add "User Command Router" component
4. Connect to WebSocket Listener
5. Python code:
   ```python
   def route_command(command, suggestion_id, tenant_id):
       if command == "execute":
           # Trigger execution workflow
           return execute_suggestion(suggestion_id, tenant_id)
       elif command == "pause":
           # Mark suggestion as paused
           return pause_suggestion(suggestion_id)
       elif command == "details":
           # Fetch full suggestion details
           return get_suggestion_details(suggestion_id)
       elif command == "feedback":
           # Record user feedback
           return record_feedback(suggestion_id, payload)
   ```

6. Add "HTTP Request" components for each action:
   - **Execute**: `POST /api/v1/walker-agents/suggestions/{id}/execute`
   - **Pause**: `PATCH /api/v1/walker-agents/suggestions/{id}` (status: paused)
   - **Details**: `GET /api/v1/walker-agents/suggestions/{id}`
   - **Feedback**: `POST /api/v1/walker-agents/suggestions/{id}/feedback`

#### Step 11: Save Flow
1. Click "Save Flow"
2. **Flow ID** is generated (e.g., `seo-walker-v1-abc123`)
3. Copy Flow ID for agent replication setup

---

### 2. Content Walker Agent Flow

#### Differences from SEO Agent:
- **Microservice**: OnSide Content API (`/api/v1/content/analyze`)
- **API Key**: `WALKER_AGENT_API_KEY_ONSIDE_CONTENT`
- **Schedule**: `0 6 * * *` (6:00 AM UTC)
- **Suggestion Types**: `content_gap`, `topic_opportunity`, `engagement_optimization`, `format_recommendation`
- **Data Sources**:
  - Content performance metrics
  - Engagement analytics (time on page, bounce rate)
  - Social shares and backlinks
  - Competitor content analysis
- **AI Prompt Focus**: Content ideas, topics, formats, engagement strategies

#### Step-by-Step:
1. Duplicate SEO Walker flow
2. Rename: `Content Walker Agent - Production`
3. Update Schedule Trigger: `0 6 * * *`
4. Update Microservice URL: `http://onside:8000/api/v1/content/analyze/{tenant_id}`
5. Update API Key: `${WALKER_AGENT_API_KEY_ONSIDE_CONTENT}`
6. Update BigQuery query to pull content metrics:
   ```sql
   SELECT
     date,
     page_url,
     pageviews,
     avg_time_on_page,
     bounce_rate,
     social_shares
   FROM `engarde-analytics.content_metrics.performance`
   WHERE tenant_id = @tenant_id
     AND date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
   ```
7. Update AI Prompt Template:
   ```
   You are an expert content strategist analyzing performance data.

   Generate 3-5 high-impact content strategy recommendations focusing on:
   - Content gaps in existing library
   - High-performing topic opportunities
   - Engagement optimization strategies
   - Format recommendations (blog, video, infographic, etc.)
   ```
8. Update Suggestion Builder suggestion types
9. Save flow with new Flow ID

---

### 3. Paid Ads Walker Agent Flow

#### Differences:
- **Microservice**: Sankore Ads API (`http://sankore:8001/api/v1/ads/analyze`)
- **API Key**: `WALKER_AGENT_API_KEY_SANKORE_PAID_ADS`
- **Schedule**: `0 6 * * *` (6:00 AM UTC)
- **Suggestion Types**: `campaign_optimization`, `budget_reallocation`, `creative_testing`, `audience_expansion`, `bid_strategy`
- **Data Sources**:
  - Campaign performance (CTR, CPC, ROAS)
  - Ad creative performance
  - Audience segment performance
  - Competitor ad intelligence
- **AI Prompt Focus**: Campaign optimizations, budget allocation, creative testing, audience targeting

#### Step-by-Step:
1. Duplicate SEO Walker flow
2. Rename: `Paid Ads Walker Agent - Production`
3. Update Schedule: `0 6 * * *`
4. Update Microservice: `http://sankore:8001/api/v1/ads/analyze/{tenant_id}`
5. Update API Key: `${WALKER_AGENT_API_KEY_SANKORE_PAID_ADS}`
6. Update BigQuery query for ad metrics:
   ```sql
   SELECT
     date,
     campaign_id,
     campaign_name,
     impressions,
     clicks,
     ctr,
     cpc,
     conversions,
     cost,
     revenue,
     roas
   FROM `engarde-analytics.ads_metrics.campaigns`
   WHERE tenant_id = @tenant_id
     AND date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
   ```
7. Update AI Prompt for ad strategy
8. Update Suggestion Builder types
9. Save flow

---

### 4. Audience Intelligence Walker Agent Flow

#### Differences:
- **Microservice**: MadanSara API (`http://madansara:8002/api/v1/audience/analyze`)
- **API Key**: `WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE`
- **Schedule**: `0 8 * * *` (8:00 AM UTC)
- **Suggestion Types**: `segment_opportunity`, `retention_campaign`, `cart_recovery`, `upsell_strategy`, `churn_prevention`
- **Data Sources**:
  - Customer segmentation data
  - Behavioral analytics
  - Purchase patterns
  - Churn predictions
- **AI Prompt Focus**: Audience segments, retention strategies, personalization, lifecycle marketing

#### Step-by-Step:
1. Duplicate SEO Walker flow
2. Rename: `Audience Intelligence Walker Agent - Production`
3. Update Schedule: `0 8 * * *`
4. Update Microservice: `http://madansara:8002/api/v1/audience/analyze/{tenant_id}`
5. Update API Key: `${WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE}`
6. Update BigQuery query for audience data:
   ```sql
   SELECT
     segment_id,
     segment_name,
     customer_count,
     avg_ltv,
     churn_rate,
     engagement_score
   FROM `engarde-analytics.audience_metrics.segments`
   WHERE tenant_id = @tenant_id
   ```
7. Update AI Prompt for audience insights
8. Update Suggestion Builder types
9. Save flow

---

## User Data Persistence Strategy

### Challenge: Maintaining User Customizations Across Admin Updates

When an admin updates a Walker agent flow template, users should retain:
- Their tenant ID configuration
- Data source integrations (BigQuery project, ZeroDB credentials)
- Notification preferences
- Custom thresholds and filters
- Historical suggestions and feedback

### Solution: Flow Variables + External State Management

#### 1. Flow Variables (Langflow Feature)

Use Langflow's built-in variable system to store user-specific configs:

```json
{
  "flow_id": "seo-walker-v1-abc123",
  "flow_version": "1.0.0",
  "user_variables": {
    "tenant_id": "uuid-from-user",
    "bigquery_project": "user-project-123",
    "zerodb_url": "http://custom-zerodb.user.com",
    "min_confidence_threshold": 0.75,
    "min_revenue_threshold": 1000,
    "notification_channels": ["email", "whatsapp"]
  }
}
```

**How to Implement:**
1. Mark critical input nodes as "Variables"
2. In Langflow UI: Right-click node → "Mark as Variable"
3. Variable names follow pattern: `{agent_type}_{setting_name}`
4. Example: `seo_tenant_id`, `seo_min_confidence`

#### 2. External State Management (PostgreSQL)

Store user customizations in database table:

```sql
CREATE TABLE walker_agent_user_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    user_id UUID NOT NULL REFERENCES users(id),
    agent_type agent_type_enum NOT NULL,
    flow_id TEXT NOT NULL, -- Links to Langflow flow
    flow_version TEXT NOT NULL,
    config_json JSONB NOT NULL, -- User's variable overrides
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(tenant_id, user_id, agent_type)
);
```

**Stored Config Example:**
```json
{
  "tenant_id": "user-tenant-uuid",
  "data_sources": {
    "bigquery_project": "custom-project",
    "zerodb_enabled": true,
    "custom_api_endpoints": {
      "seo": "https://custom-seo-api.com"
    }
  },
  "thresholds": {
    "min_confidence": 0.8,
    "min_revenue": 5000,
    "max_suggestions_per_day": 10
  },
  "notifications": {
    "email": true,
    "whatsapp": false,
    "chat": true,
    "quiet_hours": {
      "start": "22:00",
      "end": "08:00",
      "timezone": "America/New_York"
    }
  }
}
```

#### 3. Config Injection at Runtime

When flow executes:
1. Schedule Trigger fires
2. First node: "Load User Config" component
3. Fetches config from `walker_agent_user_configs` table
4. Injects variables into flow context
5. All subsequent nodes use injected values

**Load User Config Component (Python):**
```python
from langflow import CustomComponent
from sqlalchemy import create_engine, text

class LoadUserConfig(CustomComponent):
    display_name = "Load User Config"
    description = "Loads user-specific Walker agent configuration from database"

    def build_config(self):
        return {
            "tenant_id": {"display_name": "Tenant ID"},
            "agent_type": {"display_name": "Agent Type", "options": ["seo", "content", "paid_ads", "audience_intelligence"]},
            "database_url": {"display_name": "Database URL", "password": True}
        }

    def build(self, tenant_id: str, agent_type: str, database_url: str):
        engine = create_engine(database_url)

        query = text("""
            SELECT config_json
            FROM walker_agent_user_configs
            WHERE tenant_id = :tenant_id
              AND agent_type = :agent_type
        """)

        with engine.connect() as conn:
            result = conn.execute(query, {"tenant_id": tenant_id, "agent_type": agent_type}).fetchone()

        if result:
            config = result[0]
            return config
        else:
            # Return default config
            return {
                "tenant_id": tenant_id,
                "thresholds": {
                    "min_confidence": 0.7,
                    "min_revenue": 1000
                }
            }
```

#### 4. Admin Update Workflow

When admin updates flow template:

1. **Create New Flow Version**
   - Flow ID remains same: `seo-walker-v1`
   - Version increments: `1.0.0` → `1.1.0`

2. **Preserve Variable Definitions**
   - Keep same variable names (e.g., `tenant_id`, `min_confidence`)
   - Add new variables if needed
   - Never remove existing variables (mark deprecated instead)

3. **Migration Script**
   ```python
   def migrate_user_configs(old_version, new_version):
       """
       Migrate user configs from old flow version to new version
       """
       configs = db.query(WalkerAgentUserConfig).filter_by(
           flow_version=old_version
       ).all()

       for config in configs:
           # Apply transformations if needed
           new_config = transform_config(config.config_json, new_version)

           # Update version
           config.flow_version = new_version
           config.config_json = new_config
           config.updated_at = datetime.now()

       db.commit()
   ```

4. **User Notification**
   - Email users: "Your SEO Walker agent has been upgraded to v1.1.0"
   - Changelog: List new features and improvements
   - Action required: If breaking changes, guide user to re-configure

5. **Rollback Plan**
   - Keep old flow versions available
   - Allow users to switch back: `flow_id + version`
   - Automatic rollback if new version errors

---

### 5. Reconnection After Admin Updates

#### Scenario: Admin Updates SEO Walker Flow

**Before Update:**
- User has customized: tenant_id, BigQuery project, confidence threshold
- Flow version: `1.0.0`

**Admin Updates:**
- Adds new data source: Google Search Console API
- Improves AI prompt template
- Flow version: `1.1.0`

**User Reconnection Process:**

1. **Automatic Detection**
   ```python
   # In flow execution
   current_flow_version = get_flow_version()  # 1.1.0
   user_config_version = user_config.flow_version  # 1.0.0

   if current_flow_version != user_config_version:
       # Trigger migration
       migrate_config(user_config, current_flow_version)
   ```

2. **Config Mapping**
   ```python
   def migrate_config(old_config, new_version):
       # Map old variable names to new ones
       mapping = {
           "1.0.0->1.1.0": {
               "tenant_id": "tenant_id",  # No change
               "bigquery_project": "bigquery_project",  # No change
               "min_confidence": "min_confidence_threshold",  # Renamed
               # New variable with default
               "search_console_property": None  # User needs to set
           }
       }

       new_config = {}
       for old_key, new_key in mapping[f"{old_config['version']}->{new_version}"].items():
           if new_key and old_key in old_config:
               new_config[new_key] = old_config[old_key]

       return new_config
   ```

3. **User Prompt for New Settings**
   - If new required variables added: Show setup wizard
   - Example: "The SEO Walker now integrates with Google Search Console. Please connect your property."
   - User completes setup → Config saved

4. **Seamless Transition**
   - All existing customizations preserved
   - New features opt-in (default disabled)
   - Zero data loss

---

## Admin Update Workflow

### Best Practices for Flow Updates

1. **Version Control**
   - Use semantic versioning: `MAJOR.MINOR.PATCH`
   - MAJOR: Breaking changes (requires user action)
   - MINOR: New features (backward compatible)
   - PATCH: Bug fixes

2. **Flow Export/Import**
   ```bash
   # Export current flow
   langflow export --flow-id seo-walker-v1 --output seo-walker-v1.0.0.json

   # Make changes in UI
   # Import updated flow as new version
   langflow import --file seo-walker-v1.1.0.json --version 1.1.0
   ```

3. **Testing New Version**
   - Create test tenant
   - Run flow with test data
   - Verify suggestions quality
   - Check notification delivery
   - Test user interaction handlers

4. **Gradual Rollout**
   - Deploy to 10% of users first
   - Monitor for errors/issues
   - Increase to 50%, then 100%
   - Rollback if critical issues

5. **User Communication**
   - Pre-announcement: "SEO Walker update coming next week"
   - Release notes: Detailed changelog
   - Support documentation: Updated guides
   - Feedback channel: Allow users to report issues

---

## Testing & Validation

### Manual Testing Checklist

- [ ] Flow executes on schedule trigger
- [ ] Tenant ID loads correctly from user config
- [ ] All data sources return valid data
- [ ] AI generates quality suggestions (3-5 per run)
- [ ] Suggestions POST to backend successfully
- [ ] Backend returns 201 Created with suggestion IDs
- [ ] Email notification sent (check Brevo dashboard)
- [ ] WhatsApp notification sent (if enabled)
- [ ] Chat notification sent (if enabled)
- [ ] User can execute suggestion (API call succeeds)
- [ ] User can pause suggestion (status updates)
- [ ] User can request details (full data returned)
- [ ] User feedback recorded in database

### Automated Testing

```bash
# Test script: test_walker_agent_flow.sh

# 1. Trigger flow manually
curl -X POST https://langflow.engarde.media/api/v1/flows/seo-walker-v1/run \
  -H "Authorization: Bearer ${LANGFLOW_API_KEY}" \
  -d '{"inputs": {"tenant_id": "test-tenant-uuid"}}'

# 2. Wait for execution
sleep 30

# 3. Check backend for new suggestions
curl -X GET https://api.engarde.media/api/v1/walker-agents/suggestions \
  -H "Authorization: Bearer ${WALKER_AGENT_API_KEY_ONSIDE_SEO}" \
  -G -d "tenant_id=test-tenant-uuid" \
  -d "agent_type=seo" \
  -d "limit=10"

# 4. Verify notification sent
curl -X GET https://api.brevo.com/v3/smtp/emails \
  -H "api-key: ${BREVO_API_KEY}" \
  -G -d "email=test@engarde.com" \
  -d "limit=1"

# 5. Test user interaction
SUGGESTION_ID=$(curl ... | jq -r '.suggestions[0].id')

curl -X POST https://api.engarde.media/api/v1/walker-agents/suggestions/${SUGGESTION_ID}/execute \
  -H "Authorization: Bearer ${USER_JWT_TOKEN}"
```

---

## Troubleshooting

### Common Issues

#### 1. Flow Doesn't Execute on Schedule
**Symptoms**: No suggestions created at scheduled time

**Diagnosis**:
```bash
# Check Langflow scheduler status
railway logs --service langflow-server --filter "scheduler"

# Verify cron expression
# Tool: https://crontab.guru/
```

**Solutions**:
- Verify Langflow version supports scheduling (v1.0+)
- Check schedule trigger enabled: `enabled: true`
- Verify timezone setting matches expectation
- Check Langflow service not crashed

#### 2. Data Fetch Fails
**Symptoms**: AI generates generic suggestions (no real data)

**Diagnosis**:
```bash
# Test microservice endpoint
curl http://onside:8000/api/v1/seo/analyze/test-tenant-uuid \
  -H "Authorization: Bearer ${WALKER_AGENT_API_KEY_ONSIDE_SEO}"

# Check HTTP Request node logs in Langflow
```

**Solutions**:
- Verify microservice running: `docker ps | grep onside`
- Check API key valid: Not expired or revoked
- Verify network connectivity: Langflow can reach microservice
- Check tenant ID exists in microservice database

#### 3. Backend API POST Fails
**Symptoms**: Flow executes but no suggestions in database

**Diagnosis**:
```bash
# Check backend logs
railway logs --service Main --filter "walker-agents"

# Test API endpoint directly
curl -X POST https://api.engarde.media/api/v1/walker-agents/suggestions \
  -H "Authorization: Bearer ${WALKER_AGENT_API_KEY_ONSIDE_SEO}" \
  -H "Content-Type: application/json" \
  -d '{
    "agent_type": "seo",
    "tenant_id": "test-uuid",
    "suggestions": [...]
  }'
```

**Solutions**:
- Verify API key in request header
- Check request body format matches schema
- Verify tenant_id exists in database
- Check backend service not overloaded (CPU/memory)

#### 4. Notifications Not Sent
**Symptoms**: Suggestions created but user doesn't receive email/WhatsApp

**Diagnosis**:
```bash
# Check user notification preferences
curl https://api.engarde.media/api/v1/users/me/walker-agent-preferences \
  -H "Authorization: Bearer ${USER_JWT_TOKEN}"

# Check Brevo API status
curl https://api.brevo.com/v3/account \
  -H "api-key: ${BREVO_API_KEY}"
```

**Solutions**:
- Verify user has email enabled: `email_enabled: true`
- Check quiet hours not active
- Verify Brevo API key valid
- Check user's email address valid
- For WhatsApp: Verify phone number format

#### 5. User Config Not Loaded
**Symptoms**: Flow uses default values instead of user's customizations

**Diagnosis**:
```bash
# Query user config table
psql $DATABASE_URL -c "
  SELECT * FROM walker_agent_user_configs
  WHERE tenant_id = 'user-tenant-uuid'
    AND agent_type = 'seo';
"
```

**Solutions**:
- Verify config exists in database
- Check "Load User Config" component connected properly
- Verify database connection string in component
- Check variable injection logic

#### 6. Admin Update Breaks User Flows
**Symptoms**: After admin updates flow, user's customizations lost

**Diagnosis**:
```bash
# Check flow version mismatch
# Compare user_config.flow_version vs current flow version
```

**Solutions**:
- Run migration script before rollout
- Test migration with sample user configs
- Provide rollback option to previous version
- Communicate breaking changes to users

---

## Appendix: Quick Reference

### Environment Variables Checklist
```bash
✓ ENGARDE_API_URL
✓ WALKER_AGENT_API_KEY_ONSIDE_SEO
✓ WALKER_AGENT_API_KEY_ONSIDE_CONTENT
✓ WALKER_AGENT_API_KEY_SANKORE_PAID_ADS
✓ WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE
✓ BREVO_API_KEY
✓ TWILIO_ACCOUNT_SID
✓ TWILIO_AUTH_TOKEN
✓ DATABASE_PUBLIC_URL
```

### Cron Schedule Reference
| Time | Expression | Description |
|------|-----------|-------------|
| 5:00 AM UTC | `0 5 * * *` | SEO analysis |
| 6:00 AM UTC | `0 6 * * *` | Content & Paid Ads |
| 8:00 AM UTC | `0 8 * * *` | Audience Intelligence |

### API Endpoints Reference
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/walker-agents/suggestions` | POST | Submit suggestions |
| `/api/v1/walker-agents/suggestions/{id}` | GET | Get suggestion details |
| `/api/v1/walker-agents/suggestions/{id}/execute` | POST | Execute suggestion |
| `/api/v1/walker-agents/suggestions/{id}` | PATCH | Update status (pause) |
| `/api/v1/walker-agents/suggestions/{id}/feedback` | POST | Submit feedback |

### Component Palette Quick Find
| Component | Category | Search Term |
|-----------|----------|-------------|
| Schedule Trigger | Triggers | "schedule" |
| Tenant ID Input | Custom | "tenant" |
| HTTP Request | Helpers | "http" |
| ChatOpenAI | Models | "gpt" |
| Prompt Template | Prompts | "prompt" |
| Walker Suggestion Builder | Custom | "walker" |

---

## Next Steps

1. **Complete This Guide**: Build all 4 Walker agent flows in Langflow UI
2. **Create Migration Scripts**: Prepare for future admin updates
3. **Build Frontend UI**: Display suggestions to users, handle interactions
4. **Set Up Monitoring**: Dashboards for agent performance, error tracking
5. **User Onboarding**: Wizard to help users configure their Walker agents
6. **Documentation**: User-facing guides for each Walker agent type

---

**Document Version**: 1.0.0
**Last Updated**: 2026-01-05
**Author**: EnGarde Development Team
**Related Docs**:
- LANGFLOW_WALKER_AGENTS_SETUP_INSTRUCTIONS.md
- WALKER_AGENTS_IMPLEMENTATION.md
- WALKER_AGENTS_LAKEHOUSE_ARCHITECTURE.md
