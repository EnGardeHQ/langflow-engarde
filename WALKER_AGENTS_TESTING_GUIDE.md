# Walker Agents - Testing & Verification Guide

**Production Deployment Status**: ✅ READY FOR TESTING
**Date**: December 28, 2025

---

## Deployment Status

### Backend Deployment
- **Latest Commit**: `527babc` - "Fix: Update import path for get_current_user in walker_agents router"
- **Deployed**: December 28, 2025 08:09:55 PST
- **Status**: Import error fixed, awaiting Railway automatic deployment
- **Expected URL**: `https://api.engarde.media`

### Database Migration
- **Status**: ✅ COMPLETE
- **Tables Created**:
  - `walker_agent_api_keys` (4 active keys)
  - `walker_agent_suggestions` (ready for data)
  - `walker_agent_notification_preferences` (ready for user preferences)

### API Keys Generated
- ✅ OnSide SEO Walker Agent
- ✅ OnSide Content Walker Agent
- ✅ Sankore Paid Ads Walker Agent
- ✅ MadanSara Audience Intelligence Walker Agent

**Location**: See `WALKER_AGENTS_DEPLOYMENT_CREDENTIALS.md` (CONFIDENTIAL)

---

## Step 1: Verify Backend Deployment

### Check Railway Deployment Status

```bash
# Monitor Railway deployment logs
railway logs --service production-backend --tail

# Expected success messages:
# ✅ FastAPI application instance created
# ✅ Core routers included (including walker_agents)
# ✅ Application initialization complete
```

### Test Health Endpoint

```bash
# Basic health check
curl https://api.engarde.media/health

# Expected response:
{
  "status": "healthy",
  "timestamp": "2025-12-28T...",
  "version": "2.0.0"
}
```

### Test Walker Agents Endpoint (Should Return 401)

```bash
# Test without API key (should fail with 401)
curl -X POST https://api.engarde.media/api/v1/walker-agents/suggestions \
  -H "Content-Type: application/json" \
  -d '{}'

# Expected response:
{
  "detail": "Invalid authorization header format. Expected: Bearer {API_KEY}"
}
```

If you receive the 401 error, the endpoint is working correctly.

---

## Step 2: Test API Key Authentication

### Test with Valid API Key

```bash
# Replace with actual API key from WALKER_AGENTS_DEPLOYMENT_CREDENTIALS.md
API_KEY="wa_onside_production_tvKoJ-yGxSzPkmJ9vAxgnvsdGd_zUPBLDCYVYQg_GDc"

# Test authentication (should fail with 422 due to missing fields, but auth passes)
curl -X POST https://api.engarde.media/api/v1/walker-agents/suggestions \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected**: 422 Validation Error (not 401) - This confirms authentication works.

---

## Step 3: Test Complete Suggestion Submission

### Prepare Test Payload

Get a valid tenant ID from the database:

```bash
# Connect to database
railway connect production-backend

# Or use direct connection
psql "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"

# Get tenant ID
SELECT id, name FROM tenants LIMIT 1;
```

### Submit Test Suggestion

```bash
# Replace TENANT_ID with actual UUID from database
TENANT_ID="your-tenant-uuid-here"
API_KEY="wa_onside_production_tvKoJ-yGxSzPkmJ9vAxgnvsdGd_zUPBLDCYVYQg_GDc"

curl -X POST https://api.engarde.media/api/v1/walker-agents/suggestions \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "agent_type": "seo",
    "tenant_id": "'"$TENANT_ID"'",
    "timestamp": "2025-12-28T10:00:00Z",
    "priority": "high",
    "suggestions": [
      {
        "id": "test-suggestion-001",
        "type": "keyword_opportunity",
        "title": "Target high-value keyword: AI marketing automation",
        "description": "Our analysis shows you are missing a critical keyword opportunity. The term 'AI marketing automation' has 12,000 monthly searches with low competition (difficulty: 35/100). Your competitors rank for this term, but you do not have any content targeting it. Creating a comprehensive guide could drive an estimated 2,000+ monthly visitors.",
        "impact": {
          "estimated_revenue_increase": 5000.0,
          "confidence_score": 0.85
        },
        "actions": [
          {
            "action_type": "create_content",
            "description": "Create a 2,500-word comprehensive guide on AI marketing automation targeting the keyword naturally"
          },
          {
            "action_type": "optimize_metadata",
            "description": "Optimize title tag and meta description to include target keyword"
          }
        ],
        "cta_url": "https://app.engarde.media/campaigns/create?suggestion_id=test-suggestion-001",
        "metadata": {
          "keyword": "AI marketing automation",
          "search_volume": 12000,
          "difficulty": 35,
          "current_rank": null
        }
      }
    ]
  }'
```

### Expected Successful Response

```json
{
  "success": true,
  "batch_id": "uuid-of-batch",
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

---

## Step 4: Verify Data in Database

### Check Suggestions Table

```sql
-- Connect to database
psql "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"

-- View stored suggestions
SELECT
  id,
  agent_type,
  priority,
  status,
  title,
  email_sent,
  email_sent_at,
  created_at
FROM walker_agent_suggestions
ORDER BY created_at DESC
LIMIT 5;

-- Expected output:
-- Should show your test suggestion with email_sent = true
```

### Check API Key Usage

```sql
-- Verify API key was used
SELECT
  id,
  microservice,
  agent_type,
  is_active,
  usage_count,
  last_used_at
FROM walker_agent_api_keys
WHERE microservice = 'onside'
ORDER BY last_used_at DESC;

-- Expected: usage_count incremented, last_used_at updated
```

---

## Step 5: Verify Email Delivery

### Check Backend Logs

```bash
# Monitor email sending
railway logs --service production-backend --filter "Email sent to"

# Expected log entry:
# Email sent to user@example.com for batch uuid-of-batch
```

### Check User Inbox

1. Find email address of tenant user:
```sql
SELECT u.email, u.first_name
FROM users u
JOIN tenant_users tu ON tu.user_id = u.id
WHERE tu.tenant_id = 'your-tenant-uuid'
LIMIT 1;
```

2. Check inbox for email with subject:
   - "Walker Agent: 1 new SEO opportunity"
   - From: Walker Agents (via Brevo)
   - Should contain:
     - Branded email template with purple gradient header
     - Suggestion title and description
     - Estimated revenue impact
     - "View All Suggestions" CTA button

### Check Brevo Dashboard

1. Login to Brevo: https://app.brevo.com
2. Navigate to **Transactional** → **Emails**
3. Filter by date: Today
4. Look for email sent to test user
5. Verify:
   - ✅ Delivered
   - ✅ Opened (if user opened it)
   - ✅ Clicked (if user clicked CTA)

---

## Step 6: Test User-Facing API

### List Suggestions (Frontend Testing)

First, get a user access token:

```bash
# Login as user (replace with actual credentials)
curl -X POST https://api.engarde.media/api/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=user@example.com&password=password123"

# Response will include access_token
```

Then list suggestions:

```bash
# Replace with actual access token
USER_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# List all suggestions
curl -X GET "https://api.engarde.media/api/v1/walker-agents/suggestions" \
  -H "Authorization: Bearer $USER_TOKEN"

# Filter by agent type
curl -X GET "https://api.engarde.media/api/v1/walker-agents/suggestions?agent_type=seo" \
  -H "Authorization: Bearer $USER_TOKEN"

# Filter by status
curl -X GET "https://api.engarde.media/api/v1/walker-agents/suggestions?status=pending" \
  -H "Authorization: Bearer $USER_TOKEN"
```

### Submit Feedback on Suggestion

```bash
# Get suggestion ID from previous response
SUGGESTION_ID="uuid-of-suggestion"
USER_TOKEN="your-access-token"

# Mark suggestion as approved
curl -X POST "https://api.engarde.media/api/v1/walker-agents/suggestions/$SUGGESTION_ID/feedback" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "approved",
    "feedback": "Great suggestion! Will implement this week."
  }'

# Expected response:
{
  "success": true,
  "message": "Feedback submitted successfully",
  "suggestion_id": "uuid-of-suggestion",
  "new_status": "approved"
}
```

---

## Step 7: Configure Langflow Integration

### Set Environment Variables in Langflow

If using Railway for Langflow:

```bash
# Set backend URL
railway variables set ENGARDE_API_URL="https://api.engarde.media"

# Set API keys (one for each Walker Agent)
railway variables set WALKER_AGENT_API_KEY_ONSIDE_SEO="wa_onside_production_tvKoJ-yGxSzPkmJ9vAxgnvsdGd_zUPBLDCYVYQg_GDc"
railway variables set WALKER_AGENT_API_KEY_ONSIDE_CONTENT="wa_onside_production_1-oq6OFlu0Pb3kvVHlNeiTcbe8S6u1CMbzmc8ppfxP4"
railway variables set WALKER_AGENT_API_KEY_SANKORE_PAID_ADS="wa_sankore_production_sBhmczd9F_nN_PY94H8TJuS9e7-jZqp5l7rwrQSOscc"
railway variables set WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE="wa_madansara_production_k6XDe6dbAU-JD5zVxOWr8zsPjI-h6OyQAfh1jtRAn5g"
```

### Import Flows

1. Access Langflow: `https://langflow.engarde.media`
2. Click **Import Flow**
3. Import each flow from `production-backend/langflow/flows/`:
   - `seo_walker_agent_with_backend_integration.json`
   - `paid_ads_walker_agent_with_backend_integration.json`
   - `content_walker_agent_with_backend_integration.json`
   - `audience_intelligence_walker_agent_with_backend_integration.json`

### Test Each Flow Manually

1. Open flow in Langflow
2. Click **Run** or **Test**
3. Provide test inputs:
   - `tenant_id`: Use valid UUID from database
   - Any other required parameters
4. Monitor execution
5. Verify:
   - ✅ HTTP Request node executes successfully
   - ✅ Response shows `"success": true`
   - ✅ Backend logs show suggestion received
   - ✅ Database shows new suggestion
   - ✅ Email sent to user

### Schedule Automated Runs

Configure cron schedules in Langflow:

| Walker Agent | Schedule | Cron Expression |
|--------------|----------|-----------------|
| SEO | Daily at 5:00 AM | `0 5 * * *` |
| Paid Ads | Daily at 6:00 AM | `0 6 * * *` |
| Content | Daily at 6:00 AM | `0 6 * * *` |
| Audience Intelligence | Daily at 8:00 AM | `0 8 * * *` |

---

## Step 8: Monitor Production Usage

### Backend Monitoring

```bash
# Watch Walker Agent suggestions in real-time
railway logs --service production-backend --filter "walker-agents/suggestions" --tail

# Monitor email delivery
railway logs --service production-backend --filter "Email sent to" --tail

# Check for errors
railway logs --service production-backend --filter "ERROR" --tail
```

### Database Analytics

```sql
-- Suggestions by agent type (last 7 days)
SELECT
  agent_type,
  COUNT(*) as total,
  SUM(CASE WHEN email_sent THEN 1 ELSE 0 END) as emails_sent,
  ROUND(100.0 * SUM(CASE WHEN email_sent THEN 1 ELSE 0 END) / COUNT(*), 2) as email_rate_pct
FROM walker_agent_suggestions
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY agent_type
ORDER BY total DESC;

-- Suggestion status breakdown
SELECT
  status,
  COUNT(*) as count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) as percentage
FROM walker_agent_suggestions
GROUP BY status
ORDER BY count DESC;

-- Average estimated revenue impact
SELECT
  agent_type,
  ROUND(AVG(estimated_revenue_increase), 2) as avg_revenue_impact,
  ROUND(AVG(confidence_score), 2) as avg_confidence
FROM walker_agent_suggestions
WHERE estimated_revenue_increase > 0
GROUP BY agent_type;

-- User engagement (feedback submission rate)
SELECT
  COUNT(*) as total_suggestions,
  SUM(CASE WHEN reviewed_at IS NOT NULL THEN 1 ELSE 0 END) as reviewed,
  ROUND(100.0 * SUM(CASE WHEN reviewed_at IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) as review_rate_pct
FROM walker_agent_suggestions;
```

---

## Troubleshooting

### Issue: 401 Unauthorized

**Symptoms**:
```json
{"detail": "Invalid or revoked API key"}
```

**Causes**:
1. API key format incorrect (should start with `wa_`)
2. API key not in database
3. API key marked as revoked

**Solution**:
```sql
-- Check API key status
SELECT id, microservice, is_active, revoked, usage_count
FROM walker_agent_api_keys
WHERE key_hash = encode(digest('YOUR_API_KEY', 'sha256'), 'hex');

-- If revoked, activate it
UPDATE walker_agent_api_keys
SET revoked = false, is_active = true
WHERE id = 'key-uuid';
```

### Issue: 404 Tenant Not Found

**Symptoms**:
```json
{"detail": "Tenant xxx not found"}
```

**Solution**:
```sql
-- List available tenants
SELECT id, name FROM tenants;

-- Use a valid tenant ID in your request
```

### Issue: Email Not Sent

**Symptoms**: `email_sent = false` in database

**Causes**:
1. User notification preferences disabled
2. User has no email address
3. Brevo API key not configured
4. Brevo API error

**Solutions**:

```sql
-- Check user notification preferences
SELECT * FROM walker_agent_notification_preferences
WHERE user_id = 'user-uuid';

-- Enable notifications if disabled
UPDATE walker_agent_notification_preferences
SET email_enabled = true, seo_notifications = true
WHERE user_id = 'user-uuid';

-- Check user has email
SELECT id, email FROM users WHERE id = 'user-uuid';
```

Check backend environment variables:
```bash
railway variables | grep BREVO
# Should show BREVO_API_KEY
```

### Issue: Langflow HTTP Request Fails

**Symptoms**: Langflow shows connection error

**Solutions**:

1. Test connectivity from Langflow container:
```bash
curl https://api.engarde.media/health
```

2. Verify environment variables are set:
```bash
echo $ENGARDE_API_URL
echo $WALKER_AGENT_API_KEY_ONSIDE_SEO
```

3. Check Langflow logs for errors

4. Verify API key format in HTTP Request node:
   - Authorization header: `Bearer ${WALKER_AGENT_API_KEY_ONSIDE_SEO}`
   - NOT: `Bearer WALKER_AGENT_API_KEY_ONSIDE_SEO` (missing $)

---

## Success Criteria

The Walker Agent integration is considered fully operational when:

- ✅ Backend API responds to `/api/v1/walker-agents/suggestions` endpoint
- ✅ API key authentication works correctly
- ✅ Suggestions are stored in database with correct data
- ✅ Emails are sent via Brevo to tenant users
- ✅ Users can list suggestions via GET endpoint
- ✅ Users can submit feedback on suggestions
- ✅ Langflow flows can submit suggestions successfully
- ✅ Scheduled runs execute automatically
- ✅ No errors in production logs

---

## Next Steps After Testing

Once testing is complete:

1. **Production Monitoring Setup**:
   - Configure alerts for failed suggestions
   - Set up weekly analytics reports
   - Monitor email delivery rates

2. **User Onboarding**:
   - Notify users about Walker Agent suggestions
   - Add in-app notifications for new suggestions
   - Create user guide for managing suggestions

3. **Langflow Optimization**:
   - Fine-tune suggestion generation prompts
   - Adjust confidence thresholds
   - Optimize scheduling based on user engagement

4. **Feature Enhancements**:
   - Implement WhatsApp notifications via Twilio
   - Add in-platform chat notifications via WebSocket
   - Build frontend UI for suggestion management

---

**Last Updated**: December 28, 2025
**Version**: 1.0.0
**Status**: Ready for Testing
