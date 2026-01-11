# Walker Agent Flow Assembly - Visual Guide

## Component Chain Overview

This guide shows you exactly how to connect custom components in Langflow to build a complete Walker agent flow.

---

## 🔗 Complete Component Chain (5 Components)

```
┌─────────────────────────────────────────────────────────────────┐
│                    WALKER AGENT FLOW                            │
└─────────────────────────────────────────────────────────────────┘

1. LoadUserConfig              [NEW COMPONENT]
   ↓ (outputs: user_config)

2. MultiSourceDataFetcher      [NEW COMPONENT - TO CREATE]
   ↓ (outputs: aggregated_data)

3. AIAnalyzer                  [NEW COMPONENT - TO CREATE]
   ↓ (outputs: suggestions_json)

4. WalkerSuggestionBuilder     [EXISTING COMPONENT]
   ↓ (outputs: formatted_suggestions)

5. WalkerAgentAPI              [EXISTING COMPONENT]
   ↓ (outputs: api_response)
```

---

## 📋 Component-by-Component Assembly

### Component 1: LoadUserConfig
**Status**: ✅ Created (load_user_config.py)

**Purpose**: Load user's custom configuration from database

**Inputs**:
- tenant_id (text)
- agent_type (dropdown: seo, content, paid_ads, audience_intelligence)
- flow_version (text, e.g., "1.0.0")

**Outputs**:
- config (JSON object)

**Connection**: Wire output to Component 2's `user_config` input

---

### Component 2: MultiSourceDataFetcher
**Status**: ❌ MISSING - Need to create

**Purpose**: Fetch data from multiple sources (Microservice, BigQuery, ZeroDB)

**Inputs**:
- user_config (from Component 1)
- tenant_id (from Component 1 or direct input)
- agent_type (from Component 1 or direct input)

**Outputs**:
- aggregated_data (JSON object with all data sources)

**What it does**:
1. Reads user_config to see which data sources are enabled
2. Fetches from microservice API (OnSide/Sankore/MadanSara)
3. Fetches from BigQuery (if enabled in config)
4. Fetches from ZeroDB (if enabled in config)
5. Merges all data into single JSON

**Connection**: Wire output to Component 3's `data` input

---

### Component 3: AIAnalyzer
**Status**: ❌ MISSING - Need to create

**Purpose**: Analyze data using AI and generate suggestions

**Inputs**:
- aggregated_data (from Component 2)
- user_config (from Component 1)
- agent_type (dropdown)

**Outputs**:
- suggestions_json (JSON array of suggestions)

**What it does**:
1. Builds prompt from agent type + user's custom_prompt_additions
2. Calls OpenAI GPT-4 with data + prompt
3. Parses AI response into structured suggestions
4. Returns JSON array of suggestions

**Connection**: Wire output to Component 4's input

---

### Component 4: WalkerSuggestionBuilder
**Status**: ✅ Exists (walker_agent_components.py)

**Purpose**: Format each suggestion into proper schema

**Inputs**:
- suggestion_type (dropdown)
- title (text)
- description (multiline)
- estimated_revenue (float)
- confidence_score (float)
- action_description (text)
- cta_url (text)

**Outputs**:
- suggestion (JSON object)

**Issue**: This component is designed for **single suggestion**, but we need **batch processing**

**Solution**: Create a wrapper component or modify to accept JSON array

**Connection**: Wire output to Component 5's `suggestions` input

---

### Component 5: WalkerAgentAPI
**Status**: ✅ Exists (walker_agent_components.py)

**Purpose**: Submit suggestions to backend API

**Inputs**:
- api_url (secret)
- api_key (secret)
- agent_type (dropdown)
- tenant_id (text)
- priority (dropdown)
- suggestions (JSON array)

**Outputs**:
- response (JSON with success/error)

**Connection**: Final component - no further wiring

---

## 🎨 Visual Flow Diagram

```
┌──────────────────────┐
│  1. LoadUserConfig   │
│  ┌────────────────┐  │
│  │ tenant_id      │  │ ◄── Manual input or from schedule trigger
│  │ agent_type     │  │
│  │ flow_version   │  │
│  └────────────────┘  │
│         ↓            │
│  ┌────────────────┐  │
│  │ config (JSON)  │  │─────┐
│  └────────────────┘  │     │
└──────────────────────┘     │
                             │
                             ↓
┌──────────────────────────────────────────────────┐
│  2. MultiSourceDataFetcher                       │
│  ┌────────────────────────────────────────────┐  │
│  │ user_config  ◄─────────────────────────────┼──┘
│  │ tenant_id                                  │  │
│  │ agent_type                                 │  │
│  └────────────────────────────────────────────┘  │
│         ↓                                        │
│  [Fetch from Microservice API]                   │
│  [Fetch from BigQuery] (if enabled)              │
│  [Fetch from ZeroDB] (if enabled)                │
│  [Fetch from PostgreSQL Cache] (if enabled)      │
│         ↓                                        │
│  ┌────────────────────────────────────────────┐  │
│  │ aggregated_data: {                         │  │
│  │   microservice: {...},                     │  │
│  │   bigquery: [...],                         │  │
│  │   zerodb: [...],                           │  │
│  │   cache: [...]                             │  │
│  │ }                                          │  │─┐
│  └────────────────────────────────────────────┘  │ │
└──────────────────────────────────────────────────┘ │
                                                     │
                                                     ↓
┌──────────────────────────────────────────────────────┐
│  3. AIAnalyzer                                       │
│  ┌────────────────────────────────────────────────┐  │
│  │ aggregated_data  ◄─────────────────────────────┼──┘
│  │ user_config                                    │  │
│  │ agent_type                                     │  │
│  └────────────────────────────────────────────────┘  │
│         ↓                                            │
│  [Build Prompt Template]                             │
│  [Add user's custom_prompt_additions]                │
│  [Call OpenAI GPT-4]                                 │
│  [Parse AI Response]                                 │
│         ↓                                            │
│  ┌────────────────────────────────────────────────┐  │
│  │ suggestions_json: [                            │  │
│  │   {type: "keyword_opportunity", ...},          │  │
│  │   {type: "content_gap", ...},                  │  │
│  │   {type: "technical_seo", ...}                 │  │─┐
│  │ ]                                              │  │ │
│  └────────────────────────────────────────────────┘  │ │
└──────────────────────────────────────────────────────┘ │
                                                         │
                                                         ↓
┌──────────────────────────────────────────────────────────┐
│  4. SuggestionArrayFormatter (NEW - wrapper)             │
│  ┌────────────────────────────────────────────────────┐  │
│  │ suggestions_json  ◄────────────────────────────────┼──┘
│  └────────────────────────────────────────────────────┘  │
│         ↓                                                │
│  [Loop through each suggestion]                          │
│  [Format with WalkerSuggestionBuilder logic]             │
│  [Add metadata, IDs, timestamps]                         │
│         ↓                                                │
│  ┌────────────────────────────────────────────────────┐  │
│  │ formatted_suggestions: [                           │  │
│  │   {id: "uuid", type: "...", title: "...", ...},    │  │─┐
│  │   {...}                                            │  │ │
│  │ ]                                                  │  │ │
│  └────────────────────────────────────────────────────┘  │ │
└──────────────────────────────────────────────────────────┘ │
                                                             │
                                                             ↓
┌──────────────────────────────────────────────────────────────┐
│  5. WalkerAgentAPI                                           │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ formatted_suggestions  ◄───────────────────────────────┼──┘
│  │ api_url (${ENGARDE_API_URL})                          │  │
│  │ api_key (${WALKER_AGENT_API_KEY_...})                 │  │
│  │ agent_type                                            │  │
│  │ tenant_id                                             │  │
│  │ priority (high/medium/low)                            │  │
│  └────────────────────────────────────────────────────────┘  │
│         ↓                                                    │
│  [POST to /api/v1/walker-agents/suggestions]                 │
│  [Retry logic: 3 attempts with exponential backoff]          │
│         ↓                                                    │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ api_response: {                                        │  │
│  │   success: true,                                       │  │
│  │   suggestions_created: 5,                              │  │
│  │   batch_id: "uuid"                                     │  │
│  │ }                                                      │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

---

## 🔧 Missing Components to Create

### 1. MultiSourceDataFetcher Component

**File**: `multi_source_data_fetcher.py`

**Responsibilities**:
- Read user_config to determine which data sources are enabled
- Fetch from microservice API (different endpoint per agent type)
- Conditionally fetch from BigQuery (if enabled)
- Conditionally fetch from ZeroDB (if enabled)
- Conditionally fetch from PostgreSQL cache (if enabled)
- Merge all data into single JSON structure
- Handle errors gracefully (return partial data if some sources fail)

### 2. AIAnalyzer Component

**File**: `ai_analyzer.py`

**Responsibilities**:
- Build prompt template based on agent_type
- Inject user's custom_prompt_additions from config
- Include aggregated_data in prompt
- Call OpenAI GPT-4 API
- Parse AI response (expect JSON array of suggestions)
- Validate suggestion structure
- Return suggestions as JSON array

### 3. SuggestionArrayFormatter Component

**File**: `suggestion_array_formatter.py`

**Responsibilities**:
- Accept JSON array from AIAnalyzer
- Loop through each suggestion
- Apply formatting (add UUIDs, timestamps, metadata)
- Validate required fields (title, description, etc.)
- Calculate priority based on confidence + revenue
- Output formatted array ready for API submission

---

## 📝 Step-by-Step Assembly in Langflow UI

### Step 1: Add LoadUserConfig
1. Drag "Load User Config" component to canvas
2. Set inputs:
   - tenant_id: `${tenant_id}` (from flow input or hardcode for testing)
   - agent_type: `seo`
   - flow_version: `1.0.0`

### Step 2: Add MultiSourceDataFetcher
1. Drag "Multi Source Data Fetcher" component to canvas
2. Connect LoadUserConfig's `config` output → MultiSourceDataFetcher's `user_config` input
3. Set inputs:
   - tenant_id: Same as Step 1
   - agent_type: Same as Step 1

### Step 3: Add AIAnalyzer
1. Drag "AI Analyzer" component to canvas
2. Connect MultiSourceDataFetcher's `aggregated_data` output → AIAnalyzer's `data` input
3. Connect LoadUserConfig's `config` output → AIAnalyzer's `user_config` input
4. Set inputs:
   - agent_type: Same as Step 1

### Step 4: Add SuggestionArrayFormatter
1. Drag "Suggestion Array Formatter" component to canvas
2. Connect AIAnalyzer's `suggestions_json` output → SuggestionArrayFormatter's `suggestions` input

### Step 5: Add WalkerAgentAPI
1. Drag "Walker Agent API" component to canvas
2. Connect SuggestionArrayFormatter's `formatted_suggestions` output → WalkerAgentAPI's `suggestions` input
3. Set inputs:
   - api_url: `${ENGARDE_API_URL}`
   - api_key: `${WALKER_AGENT_API_KEY_ONSIDE_SEO}` (or appropriate key for agent type)
   - agent_type: Same as Step 1
   - tenant_id: Same as Step 1
   - priority: `high`

### Step 6: Save Flow
1. Click "Save Flow"
2. Name: `SEO Walker Agent - Production v1.0.0`
3. Note the flow ID

---

## 🎯 Reusable Aspects

### What's Reusable Across All 4 Walker Agents:
- ✅ LoadUserConfig (same component, different agent_type input)
- ✅ MultiSourceDataFetcher (same component, different microservice endpoint based on agent_type)
- ✅ AIAnalyzer (same component, different prompts based on agent_type)
- ✅ SuggestionArrayFormatter (same component)
- ✅ WalkerAgentAPI (same component, different API key based on agent_type)

### What Changes Per Agent:
- `agent_type` input value: `seo`, `content`, `paid_ads`, or `audience_intelligence`
- `api_key` environment variable: Different key per agent
- AI prompt template inside AIAnalyzer (selected based on agent_type)
- Microservice endpoint inside MultiSourceDataFetcher (selected based on agent_type)

### How to Create 4 Walker Agents:
1. Build the flow once for SEO
2. Duplicate flow 3 times
3. Change `agent_type` dropdown in each duplicate
4. Change `api_key` reference in WalkerAgentAPI component
5. Save each with unique name:
   - `SEO Walker Agent - Production v1.0.0`
   - `Content Walker Agent - Production v1.0.0`
   - `Paid Ads Walker Agent - Production v1.0.0`
   - `Audience Intelligence Walker Agent - Production v1.0.0`

---

## 🚀 Quick Start Checklist

- [ ] Component 1: LoadUserConfig ✅ (already created)
- [ ] Component 2: MultiSourceDataFetcher ❌ (need to create)
- [ ] Component 3: AIAnalyzer ❌ (need to create)
- [ ] Component 4: SuggestionArrayFormatter ❌ (need to create)
- [ ] Component 5: WalkerAgentAPI ✅ (already exists)
- [ ] Copy all components to Langflow custom_components directory
- [ ] Restart Langflow
- [ ] Build SEO Walker flow in UI (follow steps above)
- [ ] Test flow execution
- [ ] Duplicate for other 3 agent types

---

## 📚 Next Document

See next: **MISSING_COMPONENTS_IMPLEMENTATION.md** for code to create the 3 missing components.
