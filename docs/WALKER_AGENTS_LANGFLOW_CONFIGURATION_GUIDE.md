# Walker Agents Langflow Configuration Guide

Complete guide for configuring Langflow Walker Agents to send campaign suggestions to the EnGarde backend via Brevo email notifications.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Step 1: Generate API Keys](#step-1-generate-api-keys)
5. [Step 2: Configure Langflow Environment](#step-2-configure-langflow-environment)
6. [Step 3: Add HTTP Request Node to Workflows](#step-3-add-http-request-node-to-workflows)
7. [Step 4: Test the Integration](#step-4-test-the-integration)
8. [Step 5: Schedule Walker Agent Runs](#step-5-schedule-walker-agent-runs)
9. [Troubleshooting](#troubleshooting)

---

## Overview

Walker Agents are autonomous AI agents built in Langflow that analyze campaigns and send suggestions to users via email (Brevo), WhatsApp (Twilio), and in-platform chat.

**Flow**: Langflow Agent → Backend API → EmailService (Brevo) → User Inbox

---

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│              Langflow Walker Agents                         │
│  (Visual Flow Builder - No Code Configuration)             │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │  SEO Agent   │  │ Paid Ads     │  │  Content     │    │
│  │  (OnSide)    │  │ Agent        │  │  Agent       │    │
│  │              │  │ (Sankore)    │  │  (OnSide)    │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
│         │                  │                  │             │
│         └──────────────────┼──────────────────┘            │
│                            │                                │
│                  [HTTP Request Node]                        │
│                  POST /api/v1/walker-agents/suggestions     │
│                  Authorization: Bearer {API_KEY}            │
└────────────────────────────┼──────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────┐
│         EnGarde Production Backend API                     │
│                                                             │
│  /api/v1/walker-agents/suggestions                         │
│  - Validates API key                                        │
│  - Stores suggestions in PostgreSQL                        │
│  - Triggers EmailService (Brevo)                           │
└────────────────────────────┬──────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────┐
│  EmailService (app/services/email_service.py)              │
│  - Brevo API integration                                   │
│  - Branded email templates                                 │
└────────────────────────────┬──────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │  Brevo Cloud   │
                    │  Email Service │
                    └────────┬───────┘
                             │
                             ▼
                       ┌──────────┐
                       │   User   │
                       │ Inbox    │
                       └──────────┘
```

---

## Prerequisites

✅ **Backend**:
- EnGarde production-backend deployed and running
- Brevo API key configured (`BREVO_API_KEY` in environment)
- PostgreSQL database with Walker Agent tables migrated

✅ **Langflow**:
- Langflow instance deployed and accessible
- Walker Agent flows created

✅ **Network**:
- Langflow can reach the backend API at `https://api.engarde.media`

---

## Step 1: Generate API Keys

Run the API key generation script to create authentication keys for each Walker Agent:

```bash
cd /Users/cope/EnGardeHQ/production-backend

# Generate production API keys
python scripts/generate_walker_agent_api_keys.py --environment production
```

**Output**:
```
================================================================================
🔑 Generating Walker Agent API Keys (production)
================================================================================

✅ Created API key for OnSide SEO Walker Agent
   Microservice: onside
   Agent Type: seo
   Environment: production
   Key ID: 123e4567-e89b-12d3-a456-426614174000

✅ Created API key for OnSide Content Walker Agent
   Microservice: onside
   Agent Type: content
   Environment: production
   Key ID: 234e5678-e89b-12d3-a456-426614174001

✅ Created API key for Sankore Paid Ads Walker Agent
   Microservice: sankore
   Agent Type: paid_ads
   Environment: production
   Key ID: 345e6789-e89b-12d3-a456-426614174002

✅ Created API key for MadanSara Audience Intelligence Walker Agent
   Microservice: madansara
   Agent Type: audience_intelligence
   Environment: production
   Key ID: 456e7890-e89b-12d3-a456-426614174003

================================================================================
🔐 API Keys Generated
================================================================================

⚠️  IMPORTANT: Save these API keys securely!
   They will not be shown again.

Add these to your Langflow environment variables:

# OnSide SEO Walker Agent
WALKER_AGENT_API_KEY_ONSIDE_SEO="wa_onside_production_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# OnSide Content Walker Agent
WALKER_AGENT_API_KEY_ONSIDE_CONTENT="wa_onside_production_yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"

# Sankore Paid Ads Walker Agent
WALKER_AGENT_API_KEY_SANKORE_PAID_ADS="wa_sankore_production_zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"

# MadanSara Audience Intelligence Walker Agent
WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE="wa_madansara_production_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
```

⚠️ **CRITICAL**: Copy these API keys immediately. They cannot be retrieved later.

---

## Step 2: Configure Langflow Environment

Add the API keys and backend URL to Langflow's environment configuration.

### Option A: Environment Variables File

Create or edit `.env` file in your Langflow deployment:

```bash
# Langflow .env file

# Backend API Configuration
ENGARDE_API_URL=https://api.engarde.media

# Walker Agent API Keys
WALKER_AGENT_API_KEY_ONSIDE_SEO="wa_onside_production_xxxxxxxx"
WALKER_AGENT_API_KEY_ONSIDE_CONTENT="wa_onside_production_yyyyyyyy"
WALKER_AGENT_API_KEY_SANKORE_PAID_ADS="wa_sankore_production_zzzzzzzz"
WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE="wa_madansara_production_aaaaaaaa"
```

### Option B: Railway/Docker Environment Variables

If using Railway or Docker, set these as environment variables:

**Railway**:
```bash
railway variables set ENGARDE_API_URL="https://api.engarde.media"
railway variables set WALKER_AGENT_API_KEY_ONSIDE_SEO="wa_onside_production_xxx"
# ... etc
```

**Docker Compose**:
```yaml
services:
  langflow:
    environment:
      - ENGARDE_API_URL=https://api.engarde.media
      - WALKER_AGENT_API_KEY_ONSIDE_SEO=wa_onside_production_xxx
      # ... etc
```

---

## Step 3: Add HTTP Request Node to Workflows

For each Walker Agent flow in Langflow, add an HTTP Request node at the end to POST suggestions to the backend.

### 3.1 Open Walker Agent Flow

1. Access Langflow dashboard
2. Navigate to **Flows**
3. Open the Walker Agent flow (e.g., "SEO Walker Agent")

### 3.2 Add HTTP Request Node

1. In the flow editor, click **Add Component**
2. Search for **HTTP Request**
3. Drag the **HTTP Request** node to the canvas
4. Place it after your analysis/suggestion generation nodes

### 3.3 Configure HTTP Request Node

**Node Settings**:

| Setting | Value |
|---------|-------|
| **URL** | `${ENGARDE_API_URL}/api/v1/walker-agents/suggestions` |
| **Method** | `POST` |
| **Headers** | See below |
| **Body** | See below |
| **Timeout** | `30` seconds |
| **Retry Count** | `3` |
| **Retry Delay** | `5` seconds |

**Headers**:
```json
{
  "Authorization": "Bearer ${WALKER_AGENT_API_KEY_ONSIDE_SEO}",
  "Content-Type": "application/json"
}
```

**Body Template** (for SEO Agent):
```json
{
  "agent_type": "seo",
  "tenant_id": "{{tenant_id}}",
  "timestamp": "{{timestamp}}",
  "priority": "{{priority}}",
  "suggestions": {{suggestions_json}}
}
```

### 3.4 Connect Suggestion Data

Connect the output of your suggestion generation nodes to the HTTP Request node's body inputs:

```
[Suggestion Generator Node]
        ↓ (suggestions_json)
[HTTP Request Node]
```

### 3.5 Format Suggestions JSON

Ensure your suggestions are formatted according to the API schema:

```json
{
  "agent_type": "seo",
  "tenant_id": "tenant-uuid-here",
  "timestamp": "2025-12-28T10:00:00Z",
  "priority": "high",
  "suggestions": [
    {
      "id": "suggestion-001",
      "type": "keyword_opportunity",
      "title": "Target high-value keyword 'AI marketing automation'",
      "description": "Analysis shows 12,000 monthly searches with low competition...",
      "impact": {
        "estimated_revenue_increase": 5000.0,
        "confidence_score": 0.85
      },
      "actions": [
        {
          "action_type": "create_content",
          "description": "Create comprehensive blog post targeting this keyword",
          "estimated_effort": "2 hours",
          "priority": 1
        }
      ],
      "cta_url": "https://app.engarde.media/campaigns/create?keyword=ai-marketing-automation",
      "metadata": {
        "keyword": "AI marketing automation",
        "search_volume": 12000,
        "competition": "low",
        "cpc": 8.50
      }
    }
  ]
}
```

---

## Step 4: Test the Integration

### 4.1 Test in Langflow

1. Open your configured Walker Agent flow
2. Click **Run** or **Test**
3. Provide test inputs (or use scheduled trigger)
4. Monitor the flow execution
5. Check the HTTP Request node output

**Expected Success Response**:
```json
{
  "success": true,
  "batch_id": "550e8400-e29b-41d4-a716-446655440000",
  "suggestions_received": 1,
  "suggestions_stored": 1,
  "notifications_sent": {
    "email": true,
    "whatsapp": false,
    "chat": false
  },
  "message": "Successfully processed 1 suggestions",
  "errors": []
}
```

### 4.2 Check Backend Logs

```bash
# If using Docker
docker logs production-backend | grep "walker-agents/suggestions"

# Check for successful processing
docker logs production-backend | grep "Email sent to"
```

### 4.3 Verify Database

```sql
-- Check suggestions were stored
SELECT id, agent_type, title, created_at, email_sent
FROM walker_agent_suggestions
ORDER BY created_at DESC
LIMIT 10;

-- Check notification preferences
SELECT user_id, email_enabled, seo_notifications
FROM walker_agent_notification_preferences;
```

### 4.4 Check Brevo Dashboard

1. Go to https://app.brevo.com
2. Navigate to **Transactional** → **Email**
3. Verify email was sent
4. Check delivery status

### 4.5 Verify User Inbox

Check the tenant user's email inbox for the suggestion notification.

---

## Step 5: Schedule Walker Agent Runs

Configure each Walker Agent to run on a schedule.

### Option A: Langflow Built-in Scheduler

1. Open Walker Agent flow in Langflow
2. Click **Settings** → **Schedule**
3. Configure schedule:
   - **SEO Agent**: Daily at 5:00 AM
   - **Paid Ads Agent**: Daily at 6:00 AM
   - **Content Agent**: Daily at 6:00 AM
   - **Audience Intelligence**: Daily at 8:00 AM

### Option B: External Cron Job

Create a cron job that triggers Langflow flows via API:

```bash
# Crontab entry
0 5 * * * curl -X POST https://langflow.engarde.media/api/v1/run/seo-walker-agent \
  -H "Authorization: Bearer $LANGFLOW_API_KEY"
```

### Option C: Airflow Integration

If using Apache Airflow for orchestration:

```python
from airflow import DAG
from airflow.operators.http_operator import SimpleHttpOperator
from datetime import datetime, timedelta

dag = DAG(
    'walker_agents_daily',
    schedule_interval='0 5 * * *',
    start_date=datetime(2025, 1, 1)
)

run_seo_agent = SimpleHttpOperator(
    task_id='run_seo_walker_agent',
    http_conn_id='langflow',
    endpoint='/api/v1/run/seo-walker-agent',
    method='POST',
    dag=dag
)
```

---

## Troubleshooting

### Issue 1: 401 Unauthorized Error

**Symptom**:
```json
{
  "detail": "Invalid or revoked API key"
}
```

**Solution**:
1. Verify API key is correctly copied to Langflow environment
2. Check API key hasn't been revoked:
   ```sql
   SELECT * FROM walker_agent_api_keys WHERE is_active = true AND revoked = false;
   ```
3. Ensure Authorization header format is correct: `Bearer wa_xxx`

---

### Issue 2: Emails Not Sending

**Symptom**: Backend returns success but no email received

**Check**:
1. **Brevo API Key**: Verify `BREVO_API_KEY` is set in backend
   ```bash
   echo $BREVO_API_KEY
   ```

2. **Notification Preferences**: Check user has email enabled
   ```sql
   SELECT * FROM walker_agent_notification_preferences WHERE user_id = 'your-user-id';
   ```

3. **Brevo Account**: Verify Brevo account has sending quota remaining

4. **Backend Logs**:
   ```bash
   docker logs production-backend | grep "Error sending email"
   ```

---

### Issue 3: Network Connection Failed

**Symptom**:
```
Error: Connection refused to https://api.engarde.media
```

**Solution**:
1. Verify Langflow can reach backend:
   ```bash
   docker exec langflow-container curl https://api.engarde.media/health
   ```

2. Check firewall rules allow traffic from Langflow to backend

3. Verify `ENGARDE_API_URL` environment variable is set correctly

---

### Issue 4: Invalid Request Body

**Symptom**:
```json
{
  "detail": "Validation error: field required"
}
```

**Solution**:
1. Ensure all required fields are provided:
   - `agent_type`
   - `tenant_id`
   - `suggestions` (array with at least 1 item)

2. Validate JSON structure matches schema

3. Check `timestamp` is in ISO 8601 format: `2025-12-28T10:00:00Z`

---

### Issue 5: Suggestions Not Visible in UI

**Symptom**: Suggestions stored in database but not showing in UI

**Check**:
1. **Tenant ID**: Verify `tenant_id` in request matches user's tenant:
   ```sql
   SELECT tenant_id FROM tenant_users WHERE user_id = 'your-user-id';
   ```

2. **Status Filter**: Check UI isn't filtering out pending suggestions

3. **Frontend API Call**: Verify frontend is calling `/api/v1/walker-agents/suggestions`

---

## Complete Example: SEO Walker Agent

Here's a complete example configuration for the SEO Walker Agent:

### Langflow Flow Structure

```
[Trigger: Schedule] → Daily at 5:00 AM
        ↓
[Get Tenant Data]
        ↓
[SEO Analysis Node]
        ↓
[Generate Suggestions]
        ↓
[Format JSON]
        ↓
[HTTP Request Node]
        ↓ (on success)
[Log Success]
```

### HTTP Request Node Configuration

**URL**:
```
${ENGARDE_API_URL}/api/v1/walker-agents/suggestions
```

**Method**: `POST`

**Headers**:
```json
{
  "Authorization": "Bearer ${WALKER_AGENT_API_KEY_ONSIDE_SEO}",
  "Content-Type": "application/json"
}
```

**Body**:
```json
{
  "agent_type": "seo",
  "tenant_id": "{{tenant_id}}",
  "timestamp": "{{current_timestamp}}",
  "priority": "high",
  "suggestions": [
    {
      "id": "{{uuid}}",
      "type": "keyword_opportunity",
      "title": "{{suggestion_title}}",
      "description": "{{suggestion_description}}",
      "impact": {
        "estimated_revenue_increase": {{revenue_estimate}},
        "confidence_score": {{confidence}}
      },
      "actions": {{actions_array}},
      "cta_url": "https://app.engarde.media/seo/keywords",
      "metadata": {{metadata_json}}
    }
  ]
}
```

---

## Next Steps

After completing this configuration:

1. ✅ Monitor first scheduled runs
2. ✅ Review email templates and adjust branding if needed
3. ✅ Set up WhatsApp notifications (Twilio integration)
4. ✅ Configure WebSocket for real-time chat notifications
5. ✅ Add analytics tracking for suggestion acceptance rates
6. ✅ Create dashboard views for suggestion management

---

**Document Version**: 1.0
**Last Updated**: December 28, 2025
**Status**: Ready for Implementation
