# Walker Agent Channels - Quick Start Guide

## Setup (5 minutes)

### 1. Configure Environment Variables

Add to your `.env` file:

```bash
# Twilio Configuration
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
```

### 2. Configure Twilio Webhook

In Twilio Console → Messaging → WhatsApp → Sandbox Settings:

```
Webhook URL: https://your-domain.com/api/v1/channels/whatsapp/webhook
Method: POST
```

### 3. Test the Setup

```bash
# Send a test message
curl -X POST https://your-domain.com/api/v1/channels/whatsapp/send \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "+1234567890",
    "message": "Test from Walker Agent!",
    "tenant_id": "your-tenant-uuid"
  }'
```

---

## Key API Endpoints

### WhatsApp

**Send Message:**
```bash
POST /api/v1/channels/whatsapp/send
{
  "to": "+1234567890",
  "message": "Your message here",
  "tenant_id": "tenant-uuid",
  "agent_id": "optional-agent-id"
}
```

**Webhook (for Twilio):**
```bash
POST /api/v1/channels/whatsapp/webhook
# Receives Twilio form data automatically
```

### Email

**Send Daily Brief:**
```bash
POST /api/v1/channels/email/send-daily-brief
{
  "user_id": "user-uuid",
  "tenant_id": "tenant-uuid",
  "recipient_email": "user@example.com",
  "include_analytics": true,
  "include_campaign_updates": true,
  "include_recommendations": true
}
```

**Send Custom Email:**
```bash
POST /api/v1/channels/email/send
{
  "to": "recipient@example.com",
  "subject": "Subject line",
  "body": "Email body",
  "tenant_id": "tenant-uuid"
}
```

### Admin Monitoring

**View Conversations:**
```bash
GET /api/v1/admin/conversations/whatsapp?start_date=2024-12-01&limit=100
```

**Get Statistics:**
```bash
GET /api/v1/admin/conversations/stats?days=30
```

**Walker Agent Analytics:**
```bash
GET /api/v1/admin/analytics/walker-agents?start_date=2024-12-01
```

**HITL Review Queue:**
```bash
GET /api/v1/admin/hitl/review-queue?status_filter=pending
```

---

## Architecture Overview

```
┌─────────────┐
│   Twilio    │
│  (WhatsApp) │
└──────┬──────┘
       │ Webhook
       ▼
┌─────────────────────────────────────┐
│  WhatsApp Router                    │
│  - Signature verification           │
│  - Parse message                    │
│  - Map to tenant                    │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  Walker Agent (Langflow)            │
│  - Process message                  │
│  - Generate response                │
│  - Return confidence score          │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  HITL Check                         │
│  - If confidence < 0.6:             │
│    → Create HITLApproval            │
│    → Send holding message           │
│  - Else: Send AI response           │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  Conversation Logging               │
│  - Log to PlatformEventLog          │
│  - Track metrics                    │
│  - Ensure tenant isolation          │
└─────────────────────────────────────┘
```

---

## Code Examples

### Send WhatsApp Message (Python)

```python
from app.services.twilio_service import twilio_service

result = await twilio_service.send_whatsapp_message(
    to="+1234567890",
    body="Hello from Walker Agent!"
)

if result["success"]:
    print(f"✓ Message sent! SID: {result['data']['sid']}")
else:
    print(f"✗ Failed: {result['error']}")
```

### Log Conversation

```python
from app.routers.channels.whatsapp import log_conversation

await log_conversation(
    db=db,
    tenant_id="tenant-uuid",
    direction="outbound",
    phone_number="+1234567890",
    message_body="Response text",
    message_sid="SM123456",
    response_time_ms=250.5,
    metadata={
        "confidence_score": 0.85,
        "agent_id": "whatsapp_handler"
    }
)
```

### Create HITL Approval for Low Confidence

```python
from app.services.hitl_service import HITLService

hitl_service = HITLService(db)

approval = await hitl_service.create_approval_request(
    tenant_id="tenant-uuid",
    agent_id="whatsapp_handler",
    agent_type="walker_agent",
    action_type="content_review",
    action_data={
        "message_from": "+1234567890",
        "message_body": "User's question",
        "proposed_response": "AI's low-confidence response",
        "confidence_score": 0.45
    },
    action_summary="Low-confidence WhatsApp response",
    requested_by="user-uuid",
    risk_level="medium",
    risk_score=0.5,
    risk_factors=["low_confidence_score"]
)
```

---

## Testing

### Run Unit Tests

```bash
cd /Users/cope/EnGardeHQ/production-backend
pytest tests/test_twilio_service.py -v
```

### Run Integration Tests

```bash
pytest tests/integration/test_walker_agent_channels.py -v
```

### Run with Coverage

```bash
pytest tests/ --cov=app.services.twilio_service --cov=app.routers.channels -v
```

---

## Common Issues & Solutions

### Issue: "Invalid webhook signature"

**Solution:** Verify TWILIO_AUTH_TOKEN matches your Twilio account and webhook URL is exact.

### Issue: "Tenant not found"

**Solution:** Implement phone number to tenant mapping, or ensure default tenant exists.

### Issue: No conversation logs appearing

**Solution:** Check that PlatformEventLog entries are being created and tenant_id is correct.

### Issue: HITL approvals not triggering

**Solution:** Verify confidence threshold (0.6) and ensure tenant has users associated.

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `/app/services/twilio_service.py` | Twilio API integration |
| `/app/routers/channels/whatsapp.py` | WhatsApp webhook & API |
| `/app/routers/channels/email.py` | Email workflows |
| `/app/routers/channels/admin_monitoring.py` | Admin monitoring APIs |
| `/tests/test_twilio_service.py` | Unit tests |
| `/tests/integration/test_walker_agent_channels.py` | Integration tests |

---

## Monitoring Dashboards

### Key Metrics to Monitor

1. **Response Time:** Average latency per message
2. **Confidence Scores:** Distribution and trends
3. **HITL Rate:** % requiring manual review
4. **Success Rate:** % of successful deliveries
5. **Error Rate:** Failed messages and reasons
6. **Volume:** Messages per hour/day
7. **Unique Users:** Active conversation participants

### Query Examples

**Get average response time (last 7 days):**
```sql
SELECT AVG((event_data->>'response_time_ms')::float) as avg_response_time
FROM platform_event_logs
WHERE platform = 'whatsapp'
  AND event_type = 'message_outbound'
  AND event_timestamp > NOW() - INTERVAL '7 days';
```

**Get HITL escalation rate:**
```sql
SELECT
  COUNT(*) FILTER (WHERE (event_data->>'requires_hitl')::boolean = true) * 100.0 / COUNT(*) as hitl_rate
FROM platform_event_logs
WHERE platform = 'whatsapp'
  AND event_type = 'message_outbound';
```

---

## Security Checklist

- [x] Webhook signature verification enabled
- [x] Phone numbers anonymized in admin endpoints
- [x] Tenant isolation enforced
- [x] Admin endpoints require superuser
- [x] Input validation via Pydantic
- [x] HTTPS enforced for webhooks
- [x] Rate limiting (implement if needed)
- [x] Audit logging enabled

---

## Next Steps

1. **Configure Twilio** - Add credentials to environment
2. **Set Webhook URL** - Point Twilio to your endpoint
3. **Test Integration** - Send test message via API
4. **Monitor Logs** - Watch application logs for activity
5. **Review HITL Queue** - Check admin endpoint for low-confidence items
6. **Set Up Alerts** - Configure monitoring for errors/performance

---

**For detailed information, see:** `WALKER_AGENT_CHANNELS_IMPLEMENTATION.md`

**API Documentation:** `https://your-domain.com/docs`
