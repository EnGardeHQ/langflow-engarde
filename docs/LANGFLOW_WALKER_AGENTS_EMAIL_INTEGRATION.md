# Langflow Walker Agents - Brevo Email Integration

## Overview

En Garde's Walker Agents are built using **Langflow**, a visual flow-based AI agent builder. All Walker Agents utilize the **Brevo (formerly Sendinblue)** transactional email service for sending campaign suggestions and notifications to users.

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
│                  Langflow Output Node                       │
│                  (HTTP Request / API Call)                  │
└────────────────────────────┼──────────────────────────────┘
                             │
                             │ POST /api/v1/walker-agents/suggestions
                             ▼
┌────────────────────────────────────────────────────────────┐
│         En Garde Production Backend API                     │
│                                                             │
│  Walker Agent Suggestion Endpoint                          │
│  - Receives suggestions from Langflow agents               │
│  - Validates and stores in PostgreSQL                      │
│  - Triggers EmailService (Brevo integration)               │
└────────────────────────────┬──────────────────────────────┘
                             │
                             │ Uses EmailService
                             ▼
┌────────────────────────────────────────────────────────────┐
│  EmailService (app/services/email_service.py)              │
│                                                             │
│  - Brevo API integration (sib-api-v3-sdk)                 │
│  - API Key: settings.BREVO_API_KEY                        │
│  - Endpoint: https://api.brevo.com/v3/smtp/email          │
│  - Branded email templates with En Garde logo             │
└────────────────────────────┬──────────────────────────────┘
                             │
                             │ HTTPS POST
                             ▼
                    ┌────────────────┐
                    │  Brevo Cloud   │
                    │  Email Service │
                    └────────┬───────┘
                             │
                             │ SMTP Delivery
                             ▼
                       ┌──────────┐
                       │   User   │
                       │ Inbox    │
                       └──────────┘
```

## Current Status

### ✅ Backend Email Service - CONFIGURED

The production backend already has Brevo fully integrated:

**File**: `app/services/email_service.py`

```python
class EmailService:
    def __init__(self):
        self.api_key = settings.BREVO_API_KEY
        self.api_url = "https://api.brevo.com/v3/smtp/email"
        self.headers = {
            "accept": "application/json",
            "content-type": "application/json",
            "api-key": self.api_key or ""
        }

    def send_email(
        self,
        to_email: str,
        to_name: str,
        subject: str,
        html_content: str,
        sender_email: str = "noreply@engarde.media",
        sender_name: str = "EnGarde"
    ) -> bool:
        """
        Send a transactional email using Brevo.
        """
        # ... implementation using Brevo API
```

**Configuration** (`app/core/config.py`):
```python
# Email settings (Brevo)
BREVO_API_KEY: str = os.getenv("BREVO_API_KEY", "")
```

**Features**:
- ✅ Branded HTML email templates with En Garde logo
- ✅ Automatic template wrapping for consistent branding
- ✅ Click tracking and open tracking support
- ✅ Error handling and logging
- ✅ Admin notification support

### ⚠️ Langflow Walker Agents - REQUIRES CONFIGURATION

Langflow Walker Agents need to be configured to call the backend API endpoint that uses Brevo:

**Required Configuration**:

1. **Langflow HTTP Request Node** (Output)
   - **URL**: `https://api.engarde.media/api/v1/walker-agents/suggestions`
   - **Method**: POST
   - **Headers**:
     ```json
     {
       "Authorization": "Bearer {WALKER_AGENT_API_KEY}",
       "Content-Type": "application/json"
     }
     ```
   - **Body Template**:
     ```json
     {
       "agent_type": "seo|content|paid_ads|audience_intelligence",
       "tenant_id": "{tenant_uuid}",
       "timestamp": "{current_timestamp}",
       "priority": "high|medium|low",
       "suggestions": [
         {
           "id": "{unique_suggestion_id}",
           "type": "{suggestion_type}",
           "title": "{suggestion_title}",
           "description": "{suggestion_description}",
           "impact": {
             "estimated_revenue_increase": 0,
             "confidence_score": 0.85
           },
           "actions": [],
           "cta_url": "https://app.engarde.media/..."
         }
       ]
     }
     ```

2. **Environment Variables** (Langflow)
   ```bash
   WALKER_AGENT_API_KEY=wa_onside_production_xxxxx
   ENGARDE_API_URL=https://api.engarde.media
   BREVO_API_KEY=xkeysib-xxxxx  # Already configured in backend
   ```

3. **Backend API Endpoint** (Already Implemented)
   ```python
   @router.post("/api/v1/walker-agents/suggestions")
   async def receive_walker_agent_suggestions(
       suggestion_batch: WalkerAgentSuggestionBatch,
       api_key: str = Depends(validate_walker_agent_auth)
   ):
       """
       Receives suggestions from Langflow Walker Agents
       and triggers Brevo email notifications
       """
       # Store suggestions
       await store_suggestions(suggestion_batch)

       # Get user preferences
       user = await get_user(suggestion_batch.tenant_id)
       prefs = await get_notification_preferences(user.id)

       # Send via Brevo if email enabled
       if prefs.email.enabled:
           email_service = EmailService()
           email_service.send_email(
               to_email=user.email,
               to_name=user.first_name,
               subject=f"Walker Agent: {len(suggestion_batch.suggestions)} new opportunities",
               html_content=render_template(suggestion_batch)
           )
   ```

## Langflow Flow Configuration

### Example: SEO Walker Agent Flow

```
[Trigger Node]
    ↓
[Data Source: PostgreSQL]
    ↓ (Fetch SERP data, PageSpeed metrics)
[LLM Analysis: Claude/GPT-4]
    ↓ (Analyze SEO opportunities)
[Conditional Logic]
    ↓ (If opportunities found)
[Format Suggestions JSON]
    ↓
[HTTP Request Node]
    URL: https://api.engarde.media/api/v1/walker-agents/suggestions
    Method: POST
    Headers: {"Authorization": "Bearer {API_KEY}"}
    Body: {suggestions payload}
    ↓
[Backend receives → Triggers Brevo email]
```

### Langflow Node Configuration Details

**HTTP Request Node Settings**:
```yaml
node_type: HTTPRequest
configuration:
  url: ${ENGARDE_API_URL}/api/v1/walker-agents/suggestions
  method: POST
  headers:
    Authorization: Bearer ${WALKER_AGENT_API_KEY}
    Content-Type: application/json
  body_template: |
    {
      "agent_type": "seo",
      "tenant_id": "{{tenant_id}}",
      "timestamp": "{{timestamp}}",
      "priority": "{{priority}}",
      "suggestions": {{suggestions_json}}
    }
  timeout: 30
  retry_count: 3
  retry_delay: 5
```

## Email Template Flow

When a Langflow Walker Agent sends suggestions:

1. **Langflow Agent** completes analysis
2. **HTTP Request Node** POSTs to `/api/v1/walker-agents/suggestions`
3. **Backend API** receives and validates
4. **EmailService** is triggered with Brevo
5. **Brevo API** sends transactional email
6. **User receives** branded notification email

## Email Template Example

The backend's `EmailService` automatically wraps content in branded template:

```html
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { text-align: center; padding: 20px 0; }
        .logo { max-height: 50px; }
        .content { padding: 30px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <img src="https://app.engarde.media/engarde-logo-color.png"
                 alt="En Garde Logo" class="logo">
        </div>
        <div class="content">
            <!-- Walker Agent suggestion content injected here -->
            <h2>SEO Walker Agent: 3 New Opportunities</h2>
            <p>Your SEO analysis is complete...</p>
            <!-- ... -->
        </div>
        <div class="footer">
            © En Garde. All rights reserved.
        </div>
    </div>
</body>
</html>
```

## Configuration Checklist

### ✅ Already Configured

- [x] Backend Brevo API integration (`email_service.py`)
- [x] Brevo API key in environment variables
- [x] Walker Agent API endpoint (`/api/v1/walker-agents/suggestions`)
- [x] Email template system with branding
- [x] Webhook security for Brevo webhooks
- [x] Database schema for storing suggestions
- [x] Notification preferences system

### ⚠️ Needs Configuration (Langflow)

- [ ] **Langflow HTTP Request nodes** configured with backend API URL
- [ ] **Walker Agent API keys** set in Langflow environment variables
- [ ] **Suggestion payload formatting** in Langflow output nodes
- [ ] **Error handling** in Langflow flows for failed API calls
- [ ] **Retry logic** for network failures
- [ ] **Testing** each Walker Agent flow end-to-end

## How to Configure Langflow Walker Agents

### Step 1: Access Langflow Dashboard

```bash
# Langflow is deployed at:
https://langflow.engarde.media

# Or locally:
docker exec -it langflow-container bash
```

### Step 2: Edit Walker Agent Flows

For each Walker Agent (SEO, Paid Ads, Content, Audience Intelligence):

1. Open the flow in Langflow visual editor
2. Locate the **Output Node** or add **HTTP Request Node**
3. Configure with:
   - **URL**: `https://api.engarde.media/api/v1/walker-agents/suggestions`
   - **Method**: `POST`
   - **Headers**: `Authorization: Bearer {API_KEY}`
   - **Body**: JSON payload with suggestions

### Step 3: Set Environment Variables

In Langflow environment or `.env` file:

```bash
# Backend API
ENGARDE_API_URL=https://api.engarde.media

# Walker Agent Authentication
WALKER_AGENT_API_KEY_ONSIDE=wa_onside_production_xxxxx
WALKER_AGENT_API_KEY_SANKORE=wa_sankore_production_xxxxx
WALKER_AGENT_API_KEY_MADANSARA=wa_madansara_production_xxxxx

# Brevo (already in backend, but may be needed for direct sends)
BREVO_API_KEY=xkeysib-xxxxx
```

### Step 4: Test the Flow

1. Trigger the Langflow agent manually
2. Check backend logs for API request receipt
3. Verify Brevo email was sent (check Brevo dashboard)
4. Confirm user received email in inbox

### Step 5: Enable Scheduled Runs

Configure Langflow to run Walker Agents on schedule:

- **SEO Agent**: Daily at 5 AM
- **Paid Ads Agent**: Daily at 6 AM
- **Content Agent**: Daily at 6 AM
- **Audience Intelligence Agent**: Daily at 8 AM

## Monitoring

### Backend Logs

```bash
# Check if Walker Agent suggestions are being received
docker logs production-backend | grep "walker-agents/suggestions"

# Check Brevo email sends
docker logs production-backend | grep "Email sent to"
```

### Brevo Dashboard

- **Transactional Emails**: https://app.brevo.com/email/campaign/type/transactional
- **Email Statistics**: Open rates, click rates, bounces
- **API Logs**: Failed sends, rate limits

### Langflow Logs

```bash
# Check Langflow execution logs
docker logs langflow-container | grep "HTTP Request"
```

## Troubleshooting

### Issue: Emails Not Sending

**Check**:
1. `BREVO_API_KEY` is set in backend environment
2. Brevo account is active and has sending quota
3. Backend API endpoint is reachable from Langflow
4. Walker Agent API key is valid

**Debug**:
```bash
# Test Brevo API directly
curl -X POST https://api.brevo.com/v3/smtp/email \
  -H "api-key: ${BREVO_API_KEY}" \
  -H "content-type: application/json" \
  -d '{
    "sender": {"name": "Test", "email": "noreply@engarde.media"},
    "to": [{"email": "test@example.com"}],
    "subject": "Test",
    "htmlContent": "<p>Test email</p>"
  }'
```

### Issue: Langflow Can't Reach Backend

**Check**:
1. Backend API is running and healthy
2. Langflow has network access to backend
3. API URL is correct in Langflow configuration
4. Firewall/security groups allow traffic

**Debug**:
```bash
# From Langflow container
docker exec langflow-container curl https://api.engarde.media/health
```

### Issue: Invalid API Key

**Check**:
1. Walker Agent API key is correct format: `wa_{microservice}_{env}_{random}`
2. API key is not revoked in database
3. API key has correct permissions

**Debug**:
```python
# Check API key in database
from app.models import WalkerAgentAPIKey
key = WalkerAgentAPIKey.query.filter_by(
    key_hash=hash_api_key("wa_onside_production_xxxxx")
).first()
print(f"Active: {not key.revoked}, Permissions: {key.permissions}")
```

## Summary

✅ **Backend is ready** - Brevo email service is fully integrated
⚠️ **Langflow needs configuration** - HTTP Request nodes must be set up to call backend API
📧 **Email flow works** - Backend → Brevo → User inbox
🔧 **Next step** - Configure Langflow Walker Agent flows to POST to `/api/v1/walker-agents/suggestions`

Once Langflow agents are configured to call the backend API, the entire email notification system will work end-to-end using Brevo for transactional emails.

---

**Document Version**: 1.0
**Last Updated**: December 28, 2025
**Status**: Backend Ready, Langflow Configuration Needed
