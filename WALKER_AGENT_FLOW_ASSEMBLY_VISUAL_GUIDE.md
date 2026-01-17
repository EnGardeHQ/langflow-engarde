# Walker Agent Flow Assembly - Visual Guide
**Updated**: January 17, 2026
**Backend Status**: ✅ Production Ready (deployed on Railway)
**WebSocket**: ✅ Real-time notifications enabled
**Analytics**: ✅ Comprehensive analytics API available

## Component Chain Overview

This guide shows you exactly how to connect custom components in Langflow to build a complete Walker agent flow.

---

## ✅ Backend Deployment Status

### Production Backend (Railway)
**Status**: ✅ DEPLOYED AND OPERATIONAL
**Service**: production-backend (Main)
**Latest Commits**:
- `c0727f5`: Documentation updates
- `c5dab61`: Walker Agent notification functions added to twilio_service
- `69edc52`: TwilioService class restored for whatsapp router
- `eee7a3f`: ZeroDBService class restored with Walker Agent functions
- `1636485`: Walker Agent backend implementation

### Database Tables Created
✅ `walker_agent_suggestions` (18 columns, 6 indexes)
✅ `walker_agent_responses` (8 columns, 5 indexes)
✅ `walker_agent_notification_preferences` (17 columns, 3 indexes)
✅ Enum types: `suggestion_status`, `user_action`, `notification_channel`

### API Endpoints Ready
✅ `POST /api/v1/walker-agents/suggestions` - Store suggestions from Langflow
✅ `GET /api/v1/walker-agents/suggestions` - Retrieve suggestions with filters
✅ `POST /api/v1/walker-agents/responses` - Record user responses
✅ `GET /api/v1/walker-agents/notification-preferences` - Get notification preferences
✅ `POST /api/v1/walker-agents/notification-preferences` - Create notification preferences
✅ `PUT /api/v1/walker-agents/notification-preferences` - Update notification preferences
✅ `GET /api/v1/walker-agents/analytics` - **NEW** Comprehensive analytics with SQL aggregations
✅ `WebSocket /api/v1/walker-agents/ws/{tenant_id}` - **NEW** Real-time notifications
✅ `POST /api/v1/walker-agents/whatsapp-webhook` - Twilio webhook handler
✅ `POST /api/v1/notifications/send` - Multi-channel notifications
✅ `GET /api/brands/current` - Get current brand (tenant_id)

### Environment Variables Configured
✅ `DATABASE_URL` - PostgreSQL connection
✅ `META_LLAMA_API_KEY` - Together AI API key
✅ `BREVO_API_KEY` - Brevo email service
✅ `TWILIO_ACCOUNT_SID` - Twilio WhatsApp service
✅ `TWILIO_AUTH_TOKEN` - Twilio auth token
✅ `TWILIO_WHATSAPP_NUMBER` - Twilio sender number

---

## 🔗 Complete Component Chain (6 Components)

```
┌─────────────────────────────────────────────────────────────────┐
│                    WALKER AGENT FLOW                            │
└─────────────────────────────────────────────────────────────────┘

1. CurrentBrandTenantComponent     [NEW - REQUIRED]
   ↓ (outputs: tenant_id)

2. LoadUserConfig                  [OPTIONAL - For custom settings]
   ↓ (outputs: user_config)

3. MultiSourceDataFetcher          [NEW COMPONENT - TO CREATE]
   ↓ (outputs: aggregated_data)

4. AIAnalyzer                      [NEW COMPONENT - TO CREATE]
   ↓ (outputs: suggestions_json)

5. WalkerAgentAPIComponent         [EXISTING COMPONENT - UPDATED]
   ↓ (outputs: api_response)

6. NotificationAgentComponent      [EXISTING COMPONENT]
   ↓ (outputs: notification_result)
```

---

## 📋 Component-by-Component Assembly

### Component 1: CurrentBrandTenantComponent **[REQUIRED]**
**Status**: ✅ Exists in langflow-engarde/engarde_components/
**File**: `current_brand_tenant.py`

**Purpose**: Auto-fetch tenant_id from currently selected brand

**API Endpoint**: `GET /api/brands/current`

**Inputs**:
- api_url (secret): `${ENGARDE_API_URL}` (https://api.engarde.media)
- api_key (secret): User's JWT token from login

**Outputs**:
- tenant_id (text): UUID of current brand

**Connection**: Wire `tenant_id` output to all downstream components that need it

**Why Required**: All Walker Agent endpoints require `tenant_id` to know which brand the suggestions belong to. This component automatically fetches it from the user's currently selected brand in the EnGarde dashboard.

---

### Component 2: LoadUserConfig **[OPTIONAL]**
**Status**: ✅ Created (load_user_config.py)

**Purpose**: Load user's custom configuration from database (optional for advanced users)

**Inputs**:
- tenant_id (from Component 1)
- agent_type (dropdown: seo, content, paid_ads, audience_intelligence)
- flow_version (text, e.g., "1.0.0")

**Outputs**:
- config (JSON object)

**When to Use**: Only if users want to customize:
- Data source preferences (enable/disable BigQuery, ZeroDB, etc.)
- Custom prompt additions
- Notification preferences
- Analysis parameters

**Connection**: Wire output to Component 3's `user_config` input

---

### Component 3: MultiSourceDataFetcher
**Status**: ❌ MISSING - Need to create

**Purpose**: Fetch data from multiple sources (Microservice, BigQuery, ZeroDB)

**Inputs**:
- tenant_id (from Component 1) **[REQUIRED]**
- agent_type (dropdown) **[REQUIRED]**
- user_config (from Component 2) **[OPTIONAL]**

**Outputs**:
- aggregated_data (JSON object with all data sources)

**What it does**:
1. Reads user_config (if provided) to see which data sources are enabled
2. Fetches from microservice API (OnSide/Sankore/MadanSara) based on agent_type
3. Optionally fetches from BigQuery (if enabled in config)
4. Optionally fetches from ZeroDB (if enabled in config)
5. Merges all data into single JSON
6. Handles errors gracefully (returns partial data if some sources fail)

**Microservice Endpoints by Agent Type**:
- `seo`: `/api/seo/analysis`
- `content`: `/api/content/performance`
- `paid_ads`: `/api/ads/metrics`
- `audience_intelligence`: `/api/audience/insights`

**Connection**: Wire output to Component 4's `data` input

---

### Component 4: AIAnalyzer
**Status**: ❌ MISSING - Need to create

**Purpose**: Analyze data using AI and generate suggestions

**Inputs**:
- aggregated_data (from Component 3) **[REQUIRED]**
- tenant_id (from Component 1) **[REQUIRED]**
- agent_type (dropdown) **[REQUIRED]**
- user_config (from Component 2) **[OPTIONAL]**

**Outputs**:
- suggestions_json (JSON array of suggestions)

**What it does**:
1. Builds prompt template based on agent_type
2. Adds user's custom_prompt_additions from config (if provided)
3. Calls AI model (OpenAI GPT-4 or Meta Llama via Together AI)
4. Parses AI response into structured suggestions
5. Returns JSON array with required fields:
   ```json
   [
     {
       "type": "keyword_opportunity",
       "title": "Target high-volume keyword: 'best CRM software'",
       "description": "Detailed explanation...",
       "estimated_revenue": 5000.0,
       "confidence_score": 0.85,
       "priority": "high",
       "action_description": "Create content targeting this keyword",
       "cta_url": "https://app.engarde.media/seo/keywords/123",
       "metadata": {}
     }
   ]
   ```

**AI Model Options**:
- OpenAI GPT-4 (default)
- Meta Llama 3.1 70B (via Together AI - env: `META_LLAMA_API_KEY`)

**Connection**: Wire output to Component 5's `suggestions` input

---

### Component 5: WalkerAgentAPIComponent **[UPDATED]**
**Status**: ✅ Exists and Updated
**File**: `walker_agent_api.py` in langflow-engarde/engarde_components/

**Purpose**: Submit suggestions to backend API (PostgreSQL + ZeroDB)

**Backend Endpoint**: `POST /api/v1/walker-agents/suggestions`

**Inputs**:
- api_url (secret): `${ENGARDE_API_URL}` (https://api.engarde.media)
- api_key (secret): `${WALKER_AGENT_API_KEY_ONSIDE_SEO}` (or appropriate key)
- agent_type (dropdown): seo, content, paid_ads, audience_intelligence
- tenant_id (from Component 1) **[REQUIRED]**
- priority (dropdown): high, medium, low
- suggestions (JSON array from Component 4) **[REQUIRED]**

**Outputs**:
- response (JSON):
  ```json
  {
    "success": true,
    "suggestions_stored": 5,
    "batch_id": "uuid-here",
    "postgresql": "stored",
    "zerodb": "cached"
  }
  ```

**What it stores**:
1. PostgreSQL (permanent storage): All suggestion details
2. ZeroDB (optional cache): Real-time access for fast queries

**Error Handling**:
- Retries: 3 attempts with exponential backoff
- Partial success: If ZeroDB fails, PostgreSQL data is still saved
- Returns detailed error messages on failure

**Connection**: Wire `batch_id` output to Component 6's input

---

### Component 6: NotificationAgentComponent
**Status**: ✅ Exists
**File**: `notification_agent.py` in langflow-engarde/engarde_components/

**Purpose**: Send multi-channel notifications to users

**Backend Endpoint**: `POST /api/v1/notifications/send`

**Inputs**:
- api_url (secret): `${ENGARDE_API_URL}`
- api_key (secret): Same as Component 5
- tenant_id (from Component 1) **[REQUIRED]**
- message (text): "You have {count} new {agent_type} suggestions ready for review"
- channel (dropdown): email, whatsapp, in_app, all
- batch_id (from Component 5) **[REQUIRED]**
- suggestions_count (number from Component 5)

**Outputs**:
- notification_result (JSON):
  ```json
  {
    "success": true,
    "channels_sent": ["email", "whatsapp"],
    "email": {"status": "sent", "message_id": "xxx"},
    "whatsapp": {"status": "sent", "message_id": "yyy"}
  }
  ```

**Notification Channels**:
1. **Email** (via Brevo):
   - HTML template with action buttons
   - Links to dashboard with batch_id
   - Buttons: Execute, Pause, Reject, View Details

2. **WhatsApp** (via Twilio):
   - Text-based message with reply prompts
   - Reply keywords: EXECUTE, PAUSE, REJECT, DETAILS
   - Auto-linked to batch via webhook

3. **In-App** (via WebSocket):
   - Real-time dashboard notifications
   - Toast/banner alerts
   - Direct links to suggestion review page

**User Lookup**:
- Email: Queries `users.email` via `brands.tenant_id` → `brand_members` → `users`
- WhatsApp: Tries `walker_agent_notification_preferences.whatsapp_number` first, fallback to `users.phone_number`

**Connection**: Final component - no further wiring

---

## 🎨 Visual Flow Diagram

```
┌──────────────────────────────────────────┐
│  1. CurrentBrandTenantComponent          │
│  ┌────────────────────────────────────┐  │
│  │ api_url: ${ENGARDE_API_URL}       │  │
│  │ api_key: ${USER_JWT_TOKEN}        │  │
│  └────────────────────────────────────┘  │
│         ↓                                │
│  GET /api/brands/current                 │
│         ↓                                │
│  ┌────────────────────────────────────┐  │
│  │ tenant_id: "uuid-here"            │  │──┐
│  └────────────────────────────────────┘  │  │
└──────────────────────────────────────────┘  │
                                              │
         ┌────────────────────────────────────┘
         │
         ↓
┌──────────────────────────────────────────┐
│  2. LoadUserConfig (OPTIONAL)            │
│  ┌────────────────────────────────────┐  │
│  │ tenant_id  ◄───────────────────────┼──┘
│  │ agent_type: "seo"                  │  │
│  │ flow_version: "1.0.0"              │  │
│  └────────────────────────────────────┘  │
│         ↓                                │
│  ┌────────────────────────────────────┐  │
│  │ config (JSON) or skip if not used │  │──┐
│  └────────────────────────────────────┘  │  │
└──────────────────────────────────────────┘  │
                                              │
         ┌────────────────────────────────────┘
         │
         ↓
┌──────────────────────────────────────────────────┐
│  3. MultiSourceDataFetcher                       │
│  ┌────────────────────────────────────────────┐  │
│  │ tenant_id  ◄───────────────────────────────┼──┘ (from Component 1)
│  │ agent_type: "seo"                          │  │
│  │ user_config (optional)                     │  │
│  └────────────────────────────────────────────┘  │
│         ↓                                        │
│  [Fetch from Microservice API]                   │
│  [Fetch from BigQuery] (if enabled)              │
│  [Fetch from ZeroDB] (if enabled)                │
│         ↓                                        │
│  ┌────────────────────────────────────────────┐  │
│  │ aggregated_data: {                         │  │
│  │   microservice: {...},                     │  │
│  │   bigquery: [...],                         │  │
│  │   zerodb: [...]                            │  │─┐
│  │ }                                          │  │ │
│  └────────────────────────────────────────────┘  │ │
└──────────────────────────────────────────────────┘ │
                                                     │
         ┌───────────────────────────────────────────┘
         │
         ↓
┌──────────────────────────────────────────────────────┐
│  4. AIAnalyzer                                       │
│  ┌────────────────────────────────────────────────┐  │
│  │ aggregated_data  ◄─────────────────────────────┼──┘
│  │ tenant_id  ◄───────────────────────────────────┼─── (from Component 1)
│  │ agent_type: "seo"                              │  │
│  │ user_config (optional)                         │  │
│  └────────────────────────────────────────────────┘  │
│         ↓                                            │
│  [Build Prompt Template for agent_type]              │
│  [Add user's custom_prompt_additions if provided]    │
│  [Call AI: OpenAI GPT-4 or Meta Llama via Together] │
│  [Parse AI Response to JSON]                         │
│         ↓                                            │
│  ┌────────────────────────────────────────────────┐  │
│  │ suggestions_json: [                            │  │
│  │   {type: "keyword_opportunity", ...},          │  │
│  │   {type: "content_gap", ...},                  │  │─┐
│  │   {type: "technical_seo", ...}                 │  │ │
│  │ ]                                              │  │ │
│  └────────────────────────────────────────────────┘  │ │
└──────────────────────────────────────────────────────┘ │
                                                         │
         ┌───────────────────────────────────────────────┘
         │
         ↓
┌──────────────────────────────────────────────────────────┐
│  5. WalkerAgentAPIComponent                              │
│  ┌────────────────────────────────────────────────────┐  │
│  │ suggestions  ◄─────────────────────────────────────┼──┘
│  │ api_url: ${ENGARDE_API_URL}                       │  │
│  │ api_key: ${WALKER_AGENT_API_KEY_ONSIDE_SEO}       │  │
│  │ agent_type: "seo"                                 │  │
│  │ tenant_id  ◄───────────────────────────────────────── (from Component 1)
│  │ priority: "high"                                  │  │
│  └────────────────────────────────────────────────────┘  │
│         ↓                                                │
│  POST /api/v1/walker-agents/suggestions                  │
│  [Retry: 3 attempts with exponential backoff]            │
│  [Store in PostgreSQL + ZeroDB cache]                    │
│         ↓                                                │
│  ┌────────────────────────────────────────────────────┐  │
│  │ response: {                                        │  │
│  │   success: true,                                   │  │
│  │   batch_id: "uuid",                                │  │─┐
│  │   suggestions_stored: 5                            │  │ │
│  │ }                                                  │  │ │
│  └────────────────────────────────────────────────────┘  │ │
└──────────────────────────────────────────────────────────┘ │
                                                             │
         ┌───────────────────────────────────────────────────┘
         │
         ↓
┌──────────────────────────────────────────────────────────────┐
│  6. NotificationAgentComponent                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ api_url: ${ENGARDE_API_URL}                           │  │
│  │ api_key: ${WALKER_AGENT_API_KEY_ONSIDE_SEO}           │  │
│  │ tenant_id  ◄───────────────────────────────────────────── (from Component 1)
│  │ message: "You have 5 new SEO suggestions"             │  │
│  │ channel: "all" (email + whatsapp + in_app)            │  │
│  │ batch_id  ◄─────────────────────────────────────────── (from Component 5)
│  │ suggestions_count: 5                                  │  │
│  └────────────────────────────────────────────────────────┘  │
│         ↓                                                    │
│  POST /api/v1/notifications/send                             │
│  [Email via Brevo with action buttons]                       │
│  [WhatsApp via Twilio with reply prompts]                    │
│  [In-App via WebSocket]                                      │
│         ↓                                                    │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ notification_result: {                                 │  │
│  │   success: true,                                       │  │
│  │   channels_sent: ["email", "whatsapp", "in_app"]      │  │
│  │ }                                                      │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

---

## 🔧 Missing Components to Create

### 1. MultiSourceDataFetcher Component ❌

**File**: `engarde_components/multi_source_data_fetcher.py`

**Implementation Priority**: HIGH (required for flow to work)

**Responsibilities**:
- Read user_config to determine enabled data sources (or use defaults)
- Fetch from microservice API (endpoint varies by agent_type)
- Conditionally fetch from BigQuery (if configured)
- Conditionally fetch from ZeroDB (if configured)
- Merge all data into single JSON structure
- Handle errors gracefully (return partial data if some sources fail)

**Microservice Endpoints**:
```python
ENDPOINTS = {
    "seo": f"{BASE_URL}/api/seo/analysis?tenant_id={tenant_id}",
    "content": f"{BASE_URL}/api/content/performance?tenant_id={tenant_id}",
    "paid_ads": f"{BASE_URL}/api/ads/metrics?tenant_id={tenant_id}",
    "audience_intelligence": f"{BASE_URL}/api/audience/insights?tenant_id={tenant_id}"
}
```

### 2. AIAnalyzer Component ❌

**File**: `engarde_components/ai_analyzer.py`

**Implementation Priority**: HIGH (required for flow to work)

**Responsibilities**:
- Build prompt template based on agent_type
- Inject user's custom_prompt_additions from config (if provided)
- Include aggregated_data in prompt
- Call AI model (OpenAI GPT-4 or Meta Llama via Together AI)
- Parse AI response (expect JSON array of suggestions)
- Validate suggestion structure
- Return suggestions as JSON array

**AI Model Configuration**:
```python
# Option 1: OpenAI GPT-4
import openai
openai.api_key = os.getenv("OPENAI_API_KEY")
model = "gpt-4-turbo-preview"

# Option 2: Meta Llama via Together AI
import together
together.api_key = os.getenv("META_LLAMA_API_KEY")
model = "meta-llama/Llama-3.1-70B-Instruct-Turbo"
```

**Prompt Templates by Agent Type**:
- SEO: "Analyze this SEO data and suggest keyword opportunities, technical improvements, and content gaps..."
- Content: "Review this content performance data and suggest topics, formats, and optimization strategies..."
- Paid Ads: "Examine this ad campaign data and recommend budget adjustments, targeting changes, and creative tests..."
- Audience Intelligence: "Study this audience behavior data and identify segments, trends, and engagement opportunities..."

---

## 📝 Step-by-Step Assembly in Langflow UI

### Step 1: Add CurrentBrandTenantComponent **[REQUIRED FIRST]**
1. Drag "Current Brand Tenant" component to canvas
2. Set inputs:
   - api_url: `${ENGARDE_API_URL}` or `https://api.engarde.media`
   - api_key: User's JWT token (from login or hardcode for testing)
3. **Save the tenant_id output** - you'll wire it to multiple components

### Step 2: Add LoadUserConfig **[OPTIONAL]**
1. Drag "Load User Config" component to canvas
2. Connect CurrentBrandTenantComponent's `tenant_id` output → LoadUserConfig's `tenant_id` input
3. Set inputs:
   - agent_type: `seo`
   - flow_version: `1.0.0`
4. **Skip this step if not using custom user configurations**

### Step 3: Add MultiSourceDataFetcher
1. Drag "Multi Source Data Fetcher" component to canvas
2. Connect CurrentBrandTenantComponent's `tenant_id` output → MultiSourceDataFetcher's `tenant_id` input
3. If using LoadUserConfig: Connect its `config` output → MultiSourceDataFetcher's `user_config` input
4. Set inputs:
   - agent_type: `seo`

### Step 4: Add AIAnalyzer
1. Drag "AI Analyzer" component to canvas
2. Connect MultiSourceDataFetcher's `aggregated_data` output → AIAnalyzer's `data` input
3. Connect CurrentBrandTenantComponent's `tenant_id` output → AIAnalyzer's `tenant_id` input
4. If using LoadUserConfig: Connect its `config` output → AIAnalyzer's `user_config` input
5. Set inputs:
   - agent_type: `seo`

### Step 5: Add WalkerAgentAPIComponent
1. Drag "Walker Agent API" component to canvas
2. Connect AIAnalyzer's `suggestions_json` output → WalkerAgentAPIComponent's `suggestions` input
3. Connect CurrentBrandTenantComponent's `tenant_id` output → WalkerAgentAPIComponent's `tenant_id` input
4. Set inputs:
   - api_url: `${ENGARDE_API_URL}` or `https://api.engarde.media`
   - api_key: `${WALKER_AGENT_API_KEY_ONSIDE_SEO}` (or appropriate key)
   - agent_type: `seo`
   - priority: `high`

### Step 6: Add NotificationAgentComponent
1. Drag "Notification Agent" component to canvas
2. Connect CurrentBrandTenantComponent's `tenant_id` output → NotificationAgentComponent's `tenant_id` input
3. Connect WalkerAgentAPIComponent's `batch_id` output → NotificationAgentComponent's `batch_id` input
4. Connect WalkerAgentAPIComponent's `suggestions_stored` output → NotificationAgentComponent's `suggestions_count` input
5. Set inputs:
   - api_url: Same as Step 5
   - api_key: Same as Step 5
   - message: "You have new SEO suggestions ready for review"
   - channel: `all` (or specific: email, whatsapp, in_app)

### Step 7: Save Flow
1. Click "Save Flow"
2. Name: `SEO Walker Agent - Production v1.0.0`
3. Description: "Automated SEO analysis and suggestion generation with multi-channel notifications"
4. Tags: `walker-agent`, `seo`, `production`
5. Note the flow ID for scheduling

---

## 🎯 Reusable Aspects

### What's Reusable Across All 4 Walker Agents:
- ✅ CurrentBrandTenantComponent (same component for all)
- ✅ LoadUserConfig (same component, different agent_type input)
- ✅ MultiSourceDataFetcher (same component, different microservice endpoint)
- ✅ AIAnalyzer (same component, different prompts based on agent_type)
- ✅ WalkerAgentAPIComponent (same component, different API key)
- ✅ NotificationAgentComponent (same component)

### What Changes Per Agent:
1. `agent_type` input value: `seo`, `content`, `paid_ads`, or `audience_intelligence`
2. `api_key` environment variable: Different key per agent
   - SEO: `${WALKER_AGENT_API_KEY_ONSIDE_SEO}`
   - Content: `${WALKER_AGENT_API_KEY_ONSIDE_CONTENT}`
   - Paid Ads: `${WALKER_AGENT_API_KEY_SANKORE_PAID_ADS}`
   - Audience Intelligence: `${WALKER_AGENT_API_KEY_MADAN_SARA_AUDIENCE}`
3. AI prompt template inside AIAnalyzer (auto-selected based on agent_type)
4. Microservice endpoint inside MultiSourceDataFetcher (auto-selected based on agent_type)
5. Notification message wording (adjust per agent type)

### How to Create All 4 Walker Agents:
1. Build the flow once for SEO (follow steps above)
2. Test SEO flow end-to-end
3. Duplicate flow 3 times
4. For each duplicate:
   - Change `agent_type` dropdown to: content, paid_ads, or audience_intelligence
   - Change `api_key` reference in WalkerAgentAPIComponent
   - Update notification message to match agent type
   - Save with unique name:
     - `Content Walker Agent - Production v1.0.0`
     - `Paid Ads Walker Agent - Production v1.0.0`
     - `Audience Intelligence Walker Agent - Production v1.0.0`

---

## 🚀 Quick Start Checklist

### Backend (Production Ready ✅)
- [x] Database tables created
- [x] API endpoints deployed
- [x] Environment variables configured
- [x] Service classes restored (ZeroDBService, TwilioService)
- [x] Walker Agent functions added
- [x] Email/WhatsApp notification services operational

### Langflow Components
- [x] Component 1: CurrentBrandTenantComponent ✅ (exists in engarde_components/)
- [x] Component 2: LoadUserConfig ✅ (exists)
- [ ] Component 3: MultiSourceDataFetcher ❌ (need to create)
- [ ] Component 4: AIAnalyzer ❌ (need to create)
- [x] Component 5: WalkerAgentAPIComponent ✅ (exists and updated)
- [x] Component 6: NotificationAgentComponent ✅ (exists)

### Deployment Steps
- [ ] Create MultiSourceDataFetcher component
- [ ] Create AIAnalyzer component
- [ ] Copy all components to Langflow custom_components directory
- [ ] Restart Langflow service
- [ ] Build SEO Walker flow in UI (follow steps above)
- [ ] Test flow execution with real tenant_id
- [ ] Verify suggestions appear in PostgreSQL database
- [ ] Verify notifications sent via email/WhatsApp
- [ ] Duplicate for other 3 agent types
- [ ] Schedule flows to run on intervals (daily/weekly)

---

## 🎨 Frontend Access & User Interface

### How Users Interact with Walker Agents

Once your Langflow flows are running and generating suggestions, users access them through the EnGarde production frontend:

#### 1. **Setup Wizard** (First-Time Users)
**Access**: Automatic prompt on first visit or via `/walker-agents` page

**Features**:
- Brand selection dropdown
- Channel preferences configuration:
  - Preferred channel (Email, WhatsApp, In-App, All)
  - Notification frequency (Real-time, Daily Digest, Weekly Summary)
  - Quiet hours settings (start time, end time, timezone)
  - Per-agent toggles (SEO, Content, Paid Ads, Audience Intelligence)

**API**: `POST /api/v1/walker-agents/notification-preferences`

---

#### 2. **Walker Agent Dashboard**
**URL**: `https://your-frontend-url.railway.app/walker-agents`

**Features**:
- View all pending suggestions
- Filter by status (Pending, Approved, Executing, Executed, Paused, Rejected)
- Stats dashboard:
  - Total suggestions count
  - Estimated revenue impact
  - Average AI confidence score
- **Suggestion Cards** showing:
  - Agent type badge (SEO, Content, etc.)
  - Priority level (High, Medium, Low)
  - Title and description
  - Estimated revenue and confidence score
  - Status badge
- **Action Buttons** (for pending suggestions):
  - Execute (green) - Approve and execute
  - Pause (orange) - Pause for later
  - Reject (red) - Dismiss suggestion
- **Batch Actions**:
  - Select multiple suggestions with checkboxes
  - "Select All" functionality
  - Batch Execute/Pause/Reject with confirmation modal

**APIs Used**:
- `GET /api/v1/walker-agents/suggestions?tenant_id={id}&status={status}&limit=50`
- `POST /api/v1/walker-agents/responses` (for actions)

---

#### 3. **Analytics Dashboard**
**URL**: `https://your-frontend-url.railway.app/walker-agents/analytics`

**Features**:
- **Time Range Filter**: Last 7 days, 30 days, 90 days, or All time
- **Key Metrics Cards**:
  - Total Suggestions (with pending count)
  - Acceptance Rate (with executed count)
  - Total Revenue Impact (with executed revenue)
  - Average Confidence Score
- **Status Distribution**:
  - Progress bars for Executed, Pending, Rejected, Paused
  - Shows count and percentage for each status
- **Performance by Agent Type**:
  - 4 cards for SEO, Content, Paid Ads, Audience Intelligence
  - Shows count, total revenue, average confidence
  - Color-coded by agent type
- **Timeline Visualization**:
  - Last 7 days of suggestion activity
  - Daily breakdown of total, executed, and rejected

**API Used**:
- `GET /api/v1/walker-agents/analytics?tenant_id={id}&time_range={range}`

**Response Data Structure**:
```json
{
  "total_suggestions": 142,
  "pending_count": 23,
  "executed_count": 89,
  "rejected_count": 18,
  "paused_count": 12,
  "total_revenue_estimate": 485000.0,
  "executed_revenue": 312000.0,
  "avg_confidence": 0.78,
  "acceptance_rate": 0.83,
  "by_agent_type": [...],
  "by_priority": [...],
  "timeline": [...]
}
```

---

#### 4. **Settings Page**
**URL**: `https://your-frontend-url.railway.app/walker-agents/settings`

**Features**:
- Update notification preferences without going through setup wizard
- Same configuration options as setup wizard
- Saves changes immediately to database

**APIs Used**:
- `GET /api/v1/walker-agents/notification-preferences?tenant_id={id}&user_id={id}`
- `PUT /api/v1/walker-agents/notification-preferences?tenant_id={id}&user_id={id}`

---

#### 5. **Notification Bell** (Header Icon)
**Location**: Top navigation bar (next to standard notifications)

**Features**:
- Real-time unread count badge (updates every 30 seconds via polling)
- Popover with last 5 pending suggestions
- Inline action buttons (Execute/Pause/Reject)
- "View All Suggestions" link to full dashboard
- Auto-updates when WebSocket receives new suggestions

**APIs Used**:
- `GET /api/v1/walker-agents/suggestions?tenant_id={id}&status=pending&limit=10` (polling)
- `POST /api/v1/walker-agents/responses` (inline actions)

**WebSocket Integration**:
- Connects to: `wss://your-backend-url.railway.app/api/v1/walker-agents/ws/{tenant_id}`
- Receives real-time notifications when new suggestions arrive
- Auto-reconnects on disconnect (5-second delay)

---

#### 6. **In-Chat Suggestions** (ChatWindow)
**Location**: Any chat interface using ChatWindow component

**Features**:
- Walker Agent suggestions rendered inline as rich cards
- Same card UI as dashboard (title, description, metrics, actions)
- Seamlessly integrated into conversation flow

**Usage in Chat**:
```tsx
<ChatWindow
  agentId="walker-agent-seo"
  agentName="SEO Walker Agent"
  onSuggestionAction={(suggestionId, action) => {
    // Handle suggestion action
  }}
/>
```

---

### Real-time Notifications (WebSocket)

**Connection URL**: `wss://backend-url.railway.app/api/v1/walker-agents/ws/{tenant_id}`

**Message Types**:

1. **new_suggestion** - Sent when Langflow flow creates new suggestions
```json
{
  "type": "new_suggestion",
  "data": {
    "suggestion_id": "uuid",
    "batch_id": "uuid",
    "agent_type": "seo",
    "title": "Optimize Product Pages",
    "description": "...",
    "estimated_revenue": 5000.0,
    "confidence_score": 0.85,
    "priority": "high",
    "status": "pending"
  }
}
```

2. **suggestion_update** - Sent when user takes action on suggestion
```json
{
  "type": "suggestion_update",
  "data": {
    "suggestion_id": "uuid",
    "status": "executed",
    "action": "execute"
  }
}
```

3. **notification** - General notifications
```json
{
  "type": "notification",
  "data": {
    "message": "Connected to Walker Agent notifications",
    "tenant_id": "uuid",
    "timestamp": "2026-01-17T03:00:00.000Z"
  }
}
```

**Frontend Hook**: `useWalkerAgentWebSocket`
```tsx
import { useWalkerAgentWebSocket } from '@/hooks/useWalkerAgentWebSocket';

const { isConnected, connectionStatus, send } = useWalkerAgentWebSocket({
  onNewSuggestion: (data) => {
    console.log('New suggestion:', data);
    // Update UI, show toast notification, etc.
  },
  onSuggestionUpdate: (data) => {
    console.log('Suggestion updated:', data);
    // Refresh suggestion list
  },
  onNotification: (data) => {
    console.log('Notification:', data);
  },
  autoReconnect: true,
});
```

---

### User Flow Example

**1. Setup** (First-time user)
- User logs into EnGarde dashboard
- Navigates to `/walker-agents`
- Setup wizard appears
- User selects brand and configures notification preferences
- Preferences saved to `walker_agent_notification_preferences` table

**2. Background** (Automated)
- Langflow SEO Walker flow runs (scheduled or triggered)
- Flow generates 3 suggestions
- WalkerAgentAPIComponent posts to `POST /api/v1/walker-agents/suggestions`
- Backend stores in database
- Backend broadcasts via WebSocket to user's tenant
- Backend sends email/WhatsApp notifications (based on preferences)

**3. Notification** (Real-time)
- User's browser receives WebSocket message
- Notification bell badge updates from 0 to 3
- User sees desktop notification (if enabled)
- User clicks notification bell
- Popover shows 3 new suggestions with inline actions

**4. Action** (User decision)
- User reviews first suggestion
- Clicks "Execute" button
- Frontend calls `POST /api/v1/walker-agents/responses`
- Backend updates suggestion status to "approved"
- Backend broadcasts status update via WebSocket
- Notification bell badge decrements to 2

**5. Dashboard** (Monitoring)
- User navigates to `/walker-agents/analytics`
- Sees acceptance rate: 33% (1 executed out of 3)
- Sees estimated revenue: $5,000 from executed suggestion
- Sees timeline chart with today's activity

---

## 🔍 Testing Checklist

### End-to-End Flow Test
1. **Tenant Fetch**: CurrentBrandTenantComponent successfully returns tenant_id
2. **Data Fetch**: MultiSourceDataFetcher retrieves data from microservice
3. **AI Analysis**: AIAnalyzer generates valid JSON suggestions
4. **API Storage**: WalkerAgentAPIComponent stores suggestions in database
5. **WebSocket Broadcast**: New suggestions broadcasted to connected clients ✅ NEW
6. **Notifications**: NotificationAgentComponent sends email/WhatsApp
7. **User Response**: User can reply to WhatsApp or click email buttons (or use in-app UI)
8. **Response Capture**: Webhook records user action (execute/pause/reject)
9. **Status Update**: Suggestion status updates in database
10. **WebSocket Update**: Status changes broadcasted to connected clients ✅ NEW

### Frontend Testing
1. **Setup Wizard**: User can complete first-time setup and save preferences
2. **Dashboard Access**: User can view suggestions at `/walker-agents`
3. **Filtering**: Status filter dropdown works (Pending, Executed, etc.)
4. **Action Buttons**: Execute/Pause/Reject buttons update suggestion status
5. **Batch Actions**: Multi-select checkboxes and batch operations work
6. **Analytics Dashboard**: Real data loads at `/walker-agents/analytics`
7. **Time Range Filter**: 7d, 30d, 90d, all filters update analytics data
8. **Settings Page**: User can update preferences at `/walker-agents/settings`
9. **Notification Bell**: Bell icon shows unread count and opens popover
10. **WebSocket Connection**: Real-time updates appear without page refresh
11. **ChatWindow Integration**: Suggestions render correctly in chat interface

### WebSocket Testing ✅ NEW
1. **Connection**: Frontend successfully connects to `ws://backend/api/v1/walker-agents/ws/{tenant_id}`
2. **Initial Message**: Server sends connection confirmation on connect
3. **New Suggestion**: When Langflow creates suggestion, WebSocket receives `new_suggestion` message
4. **Status Update**: When user takes action, WebSocket receives `suggestion_update` message
5. **Auto-reconnect**: Connection automatically re-establishes after disconnect
6. **Multiple Clients**: Multiple browser tabs/users receive same tenant messages
7. **Tenant Isolation**: Users only receive messages for their tenant_id

### Analytics API Testing ✅ NEW
1. **Endpoint Accessible**: `GET /api/v1/walker-agents/analytics?tenant_id={id}&time_range=30d` returns 200
2. **Data Structure**: Response includes all 12 required fields
3. **Time Range 7d**: Returns only last 7 days of data
4. **Time Range 30d**: Returns only last 30 days of data
5. **Time Range 90d**: Returns only last 90 days of data
6. **Time Range all**: Returns all historical data
7. **Empty State**: Returns zeros when no suggestions exist
8. **Aggregations**: SQL aggregations calculate correctly (SUM, AVG, COUNT)
9. **Timeline Data**: Returns daily breakdown for last 7 days
10. **Agent Type Breakdown**: Groups by agent_type correctly

### Database Verification
```sql
-- Check suggestions were created
SELECT COUNT(*) FROM walker_agent_suggestions
WHERE tenant_id = 'your-tenant-id'
AND created_at > NOW() - INTERVAL '1 hour';

-- Check notifications sent
SELECT * FROM walker_agent_responses
WHERE batch_id = 'your-batch-id';

-- Check user preferences
SELECT * FROM walker_agent_notification_preferences
WHERE tenant_id = 'your-tenant-id';
```

---

## 📚 Related Documentation

- **Backend Implementation**: `/Users/cope/EnGardeHQ/production-backend/WALKER_AGENT_ACTIVATION_COMPLETE.md`
- **Service Fixes**: `/Users/cope/EnGardeHQ/production-backend/ZERODB_SERVICE_FIX.md`
- **Langflow Deployment**: `/Users/cope/EnGardeHQ/LANGFLOW_DEPLOYMENT_VERIFICATION.md`
- **Component Implementation**: Next → Create missing components (MultiSourceDataFetcher, AIAnalyzer)

---

**Last Updated**: January 16, 2026
**Status**: Backend deployed ✅ | Missing 2 Langflow components ❌
**Next Step**: Create MultiSourceDataFetcher and AIAnalyzer components
