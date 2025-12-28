# Langflow Walker Agents - Step-by-Step Setup Instructions

**Date**: December 28, 2025
**Status**: Backend LIVE ✅ | Langflow Configuration Required ⏳

---

## Prerequisites Checklist

Before starting, verify:

- [x] Backend deployed and accessible at `https://api.engarde.media`
- [x] Walker Agents endpoint returns 422 validation error (not 404)
- [x] 4 API keys generated and stored in `WALKER_AGENTS_DEPLOYMENT_CREDENTIALS.md`
- [x] Database migration completed (3 tables created)
- [x] Brevo API key configured in Railway

---

## Phase 1: Access Langflow Dashboard

### Step 1.1: Find Langflow URL

Your Langflow instance should be running on Railway. To find the URL:

```bash
# Check Railway services
railway status

# Look for "langflow-server" service
# The URL should be listed under "Domains"
```

**Expected URLs** (one of these):
- `https://langflow.engarde.media` (if custom domain configured)
- `https://langflow-server-production.up.railway.app` (Railway default)
- Check Railway dashboard: Project → Services → langflow-server → Settings → Domains

### Step 1.2: Access Langflow

1. Open the Langflow URL in your browser
2. You should see the Langflow dashboard
3. If prompted to login, use your Langflow credentials

**Screenshot of what you should see**:
- Langflow logo in top left
- "New Flow" button
- "Import Flow" button (you'll need this!)
- List of existing flows (if any)

---

## Phase 2: Configure Environment Variables

Before importing flows, set up the environment variables that the flows will use.

### Step 2.1: Prepare API Keys

Open the credentials file to copy the API keys:

```bash
# View the credentials (DO NOT share these!)
cat WALKER_AGENTS_DEPLOYMENT_CREDENTIALS.md

# Or open in your editor
code WALKER_AGENTS_DEPLOYMENT_CREDENTIALS.md
```

You'll need these 5 values:

1. `ENGARDE_API_URL` = `https://api.engarde.media`
2. `WALKER_AGENT_API_KEY_ONSIDE_SEO` = `wa_onside_production_tvKoJ-yGxSzPkmJ9vAxgnvsdGd_zUPBLDCYVYQg_GDc`
3. `WALKER_AGENT_API_KEY_ONSIDE_CONTENT` = `wa_onside_production_1-oq6OFlu0Pb3kvVHlNeiTcbe8S6u1CMbzmc8ppfxP4`
4. `WALKER_AGENT_API_KEY_SANKORE_PAID_ADS` = `wa_sankore_production_sBhmczd9F_nN_PY94H8TJuS9e7-jZqp5l7rwrQSOscc`
5. `WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE` = `wa_madansara_production_k6XDe6dbAU-JD5zVxOWr8zsPjI-h6OyQAfh1jtRAn5g`

### Step 2.2: Set Variables in Railway

**Option A: Using Railway CLI**

```bash
# Make sure you're in the correct project/service
railway status

# Link to langflow-server service
railway link

# When prompted:
# - Select project: "EnGarde Suite"
# - Select environment: "production"
# - Select service: "langflow-server"

# Set each environment variable
railway variables set ENGARDE_API_URL="https://api.engarde.media"

railway variables set WALKER_AGENT_API_KEY_ONSIDE_SEO="wa_onside_production_tvKoJ-yGxSzPkmJ9vAxgnvsdGd_zUPBLDCYVYQg_GDc"

railway variables set WALKER_AGENT_API_KEY_ONSIDE_CONTENT="wa_onside_production_1-oq6OFlu0Pb3kvVHlNeiTcbe8S6u1CMbzmc8ppfxP4"

railway variables set WALKER_AGENT_API_KEY_SANKORE_PAID_ADS="wa_sankore_production_sBhmczd9F_nN_PY94H8TJuS9e7-jZqp5l7rwrQSOscc"

railway variables set WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE="wa_madansara_production_k6XDe6dbAU-JD5zVxOWr8zsPjI-h6OyQAfh1jtRAn5g"

# Verify variables were set
railway variables | grep -E "ENGARDE|WALKER"
```

**Option B: Using Railway Dashboard**

1. Go to https://railway.app
2. Navigate to your project: **EnGarde Suite**
3. Click on the **langflow-server** service
4. Click **Variables** tab
5. Click **New Variable** for each:

| Variable Name | Value |
|---------------|-------|
| `ENGARDE_API_URL` | `https://api.engarde.media` |
| `WALKER_AGENT_API_KEY_ONSIDE_SEO` | `wa_onside_production_tvKoJ-yGxSzPkmJ9vAxgnvsdGd_zUPBLDCYVYQg_GDc` |
| `WALKER_AGENT_API_KEY_ONSIDE_CONTENT` | `wa_onside_production_1-oq6OFlu0Pb3kvVHlNeiTcbe8S6u1CMbzmc8ppfxP4` |
| `WALKER_AGENT_API_KEY_SANKORE_PAID_ADS` | `wa_sankore_production_sBhmczd9F_nN_PY94H8TJuS9e7-jZqp5l7rwrQSOscc` |
| `WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE` | `wa_madansara_production_k6XDe6dbAU-JD5zVxOWr8zsPjI-h6OyQAfh1jtRAn5g` |

6. Click **Save** or **Add** for each variable

### Step 2.3: Restart Langflow (Important!)

After setting environment variables, you MUST restart Langflow for them to take effect:

**Via Railway CLI**:
```bash
railway restart --service langflow-server
```

**Via Railway Dashboard**:
1. Go to langflow-server service
2. Click **Deployments** tab
3. Click the three dots menu on the latest deployment
4. Click **Restart**

**Wait** for Langflow to restart (30-60 seconds), then verify:
```bash
# Check if Langflow is accessible
curl -I https://langflow.engarde.media
# Or your Langflow URL

# Should return HTTP 200 OK
```

---

## Phase 3: Import Langflow Flows

### Step 3.1: Locate the Flow JSON Files

The flow files are in your `production-backend` repository:

```bash
# Navigate to the flows directory
cd /Users/cope/EnGardeHQ/production-backend/langflow/flows

# List the flow files
ls -lh

# You should see:
# seo_walker_agent_with_backend_integration.json
# paid_ads_walker_agent_with_backend_integration.json
# content_walker_agent_with_backend_integration.json
# audience_intelligence_walker_agent_with_backend_integration.json
```

**Absolute paths** (copy these for easy access):
```
/Users/cope/EnGardeHQ/production-backend/langflow/flows/seo_walker_agent_with_backend_integration.json
/Users/cope/EnGardeHQ/production-backend/langflow/flows/paid_ads_walker_agent_with_backend_integration.json
/Users/cope/EnGardeHQ/production-backend/langflow/flows/content_walker_agent_with_backend_integration.json
/Users/cope/EnGardeHQ/production-backend/langflow/flows/audience_intelligence_walker_agent_with_backend_integration.json
```

### Step 3.2: Import SEO Walker Agent Flow

1. **Open Langflow dashboard** in browser
2. Click **"Import Flow"** button (usually in top right or main dashboard)
3. Click **"Upload JSON"** or **"Browse Files"**
4. Navigate to: `/Users/cope/EnGardeHQ/production-backend/langflow/flows/`
5. Select: `seo_walker_agent_with_backend_integration.json`
6. Click **"Open"** or **"Import"**
7. Wait for flow to load in the editor

**What you should see**:
- Flow name: "SEO Walker Agent with Backend Integration"
- Multiple nodes connected by lines
- Schedule Trigger node (left side)
- HTTP Request node (right side)
- Various processing nodes in between

### Step 3.3: Verify HTTP Request Node Configuration

This is **CRITICAL** - verify the HTTP Request node is configured correctly:

1. In the flow editor, click on the **"HTTP Request"** node (usually on the right side)
2. Check the configuration panel (should open on the right):

**Verify these settings**:

| Setting | Expected Value | How to Check |
|---------|----------------|--------------|
| **URL** | `${ENGARDE_API_URL}/api/v1/walker-agents/suggestions` | Should show the variable syntax |
| **Method** | `POST` | Dropdown should show POST |
| **Authorization Header** | `Bearer ${WALKER_AGENT_API_KEY_ONSIDE_SEO}` | Should reference the env variable |
| **Content-Type Header** | `application/json` | Should be set |

**IMPORTANT**: The values should use `${VARIABLE_NAME}` syntax, NOT the actual API key!

**If incorrect**, fix it:
- Click on the field
- Type: `${ENGARDE_API_URL}/api/v1/walker-agents/suggestions` for URL
- Type: `Bearer ${WALKER_AGENT_API_KEY_ONSIDE_SEO}` for Authorization
- Save changes

### Step 3.4: Save the SEO Flow

1. Click **"Save"** or **"Update Flow"** button (top right)
2. Flow name should be: "SEO Walker Agent with Backend Integration"
3. Confirm save
4. You should see a success message

### Step 3.5: Repeat for Other Flows

Repeat Steps 3.2-3.4 for the remaining 3 flows:

**Flow 2: Paid Ads Walker Agent**
- File: `paid_ads_walker_agent_with_backend_integration.json`
- HTTP Request Authorization: `Bearer ${WALKER_AGENT_API_KEY_SANKORE_PAID_ADS}`
- Flow name: "Paid Ads Walker Agent with Backend Integration"

**Flow 3: Content Walker Agent**
- File: `content_walker_agent_with_backend_integration.json`
- HTTP Request Authorization: `Bearer ${WALKER_AGENT_API_KEY_ONSIDE_CONTENT}`
- Flow name: "Content Walker Agent with Backend Integration"

**Flow 4: Audience Intelligence Walker Agent**
- File: `audience_intelligence_walker_agent_with_backend_integration.json`
- HTTP Request Authorization: `Bearer ${WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE}`
- Flow name: "Audience Intelligence Walker Agent with Backend Integration"

**After importing all 4 flows**, you should see them listed in your Langflow dashboard:
- SEO Walker Agent with Backend Integration
- Paid Ads Walker Agent with Backend Integration
- Content Walker Agent with Backend Integration
- Audience Intelligence Walker Agent with Backend Integration

---

## Phase 4: Test Each Flow Manually

Before setting up cron jobs, test each flow to ensure it works correctly.

### Step 4.1: Get a Test Tenant ID

You need a valid tenant ID from your database:

```bash
# Connect to database
psql "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"

# Get a tenant ID
SELECT id, name FROM tenants LIMIT 1;

# Example output:
#                  id                  |  name
# ------------------------------------+--------
# 123e4567-e89b-12d3-a456-426614174000 | OnSide

# Copy the tenant ID (UUID format)
```

**Copy the tenant ID** - you'll need it for testing!

### Step 4.2: Test SEO Walker Agent Flow

1. **Open the SEO flow** in Langflow editor
2. Look for any **input nodes** or **parameters** that need values
3. If there's a `tenant_id` parameter:
   - Click on the input node
   - Paste your tenant ID: `123e4567-e89b-12d3-a456-426614174000`

4. **Run the flow**:
   - Click the **"Play"** or **"Run"** button (usually top right)
   - OR click **"Test"** button

5. **Monitor execution**:
   - Watch the nodes light up as they execute
   - Check for errors (red nodes or error messages)
   - HTTP Request node should turn green when successful

6. **Check the HTTP Request node output**:
   - Click on the HTTP Request node
   - Look for the response in the output panel
   - **Expected successful response**:
   ```json
   {
     "success": true,
     "batch_id": "uuid-here",
     "suggestions_received": 1,
     "suggestions_stored": 1,
     "notifications_sent": {
       "email": true,
       "whatsapp": false,
       "chat": false
     },
     "message": "Successfully processed 1 suggestions"
   }
   ```

7. **If you see `"success": true` and `"email": true"`** - GREAT! ✅

### Step 4.3: Verify in Database

After successful test run, verify the suggestion was stored:

```sql
-- Check latest suggestion
SELECT
  id,
  agent_type,
  priority,
  title,
  email_sent,
  email_sent_at,
  created_at
FROM walker_agent_suggestions
ORDER BY created_at DESC
LIMIT 1;

-- Expected output:
-- agent_type: seo
-- email_sent: true
-- email_sent_at: [recent timestamp]
-- title: [suggestion title from flow]
```

### Step 4.4: Check Email Delivery

1. **Get the user's email**:
```sql
SELECT u.email, u.first_name
FROM users u
JOIN tenant_users tu ON tu.user_id = u.id
WHERE tu.tenant_id = '123e4567-e89b-12d3-a456-426614174000'
LIMIT 1;
```

2. **Check the user's inbox** for email with:
   - Subject: "Walker Agent: X new SEO opportunity"
   - From: Walker Agents (via Brevo)
   - Branded template with purple gradient header

3. **Check Brevo dashboard** (optional):
   - Login: https://app.brevo.com
   - Go to **Transactional** → **Emails**
   - Filter by today
   - Verify delivery status

### Step 4.5: Test Remaining Flows

Repeat Steps 4.2-4.4 for:
- **Paid Ads Walker Agent** (should create `agent_type: paid_ads`)
- **Content Walker Agent** (should create `agent_type: content`)
- **Audience Intelligence Walker Agent** (should create `agent_type: audience_intelligence`)

**After testing all 4 flows**, verify:

```sql
-- Should see 4 suggestions (one from each agent type)
SELECT agent_type, COUNT(*) FROM walker_agent_suggestions
GROUP BY agent_type;

-- Expected output:
-- seo                      | 1
-- content                  | 1
-- paid_ads                 | 1
-- audience_intelligence    | 1
```

---

## Phase 5: Set Up Cron Job Schedules

Now that all flows are tested and working, configure them to run automatically on a schedule.

### Step 5.1: Understanding Cron Syntax

Cron expressions use 5 fields:

```
* * * * *
│ │ │ │ │
│ │ │ │ └─── Day of week (0-7, 0=Sunday, 7=Sunday)
│ │ │ └───── Month (1-12)
│ │ └─────── Day of month (1-31)
│ └───────── Hour (0-23)
└─────────── Minute (0-59)
```

**Examples**:
- `0 5 * * *` = Every day at 5:00 AM
- `0 6 * * *` = Every day at 6:00 AM
- `0 8 * * *` = Every day at 8:00 AM
- `0 */2 * * *` = Every 2 hours
- `*/30 * * * *` = Every 30 minutes

**Recommended schedules** (staggered to avoid overload):

| Flow | Schedule | Cron Expression | Time (UTC) |
|------|----------|-----------------|------------|
| SEO Walker Agent | Daily at 5:00 AM | `0 5 * * *` | 05:00 |
| Paid Ads Walker Agent | Daily at 6:00 AM | `0 6 * * *` | 06:00 |
| Content Walker Agent | Daily at 6:00 AM | `0 6 * * *` | 06:00 |
| Audience Intelligence | Daily at 8:00 AM | `0 8 * * *` | 08:00 |

**Note**: Times are in UTC. Adjust if you need a different timezone.

### Step 5.2: Configure SEO Walker Agent Schedule

**Method depends on your Langflow version. Try these methods:**

**Method A: Using Schedule Trigger Node**

1. Open **SEO Walker Agent** flow in editor
2. Find the **"Schedule Trigger"** node (should be the first node on the left)
3. Click on it to open configuration panel
4. Look for **"Schedule"** or **"Cron Expression"** field
5. Enter: `0 5 * * *`
6. Verify:
   - Name: "Daily SEO Analysis Trigger"
   - Description: "Trigger SEO analysis daily at 5:00 AM"
7. Click **Save** or **Update**

**Method B: Using Flow Settings**

1. Open **SEO Walker Agent** flow
2. Click **"Settings"** or **"Flow Settings"** (gear icon or three dots menu)
3. Look for **"Schedule"** tab or section
4. Enable scheduling: Toggle **"Enable Schedule"** to ON
5. Set cron expression: `0 5 * * *`
6. Set timezone (if available): `UTC` or your preferred timezone
7. Click **"Save"** or **"Apply"**

**Method C: Using Deployment Configuration**

If Langflow doesn't have built-in scheduling, you may need to use external tools:

1. **Option 1: Railway Cron Jobs**
   - Check if Railway supports cron jobs for your service
   - Configure a cron job to trigger the Langflow API

2. **Option 2: External Scheduler** (GitHub Actions, AWS EventBridge, etc.)
   - Create a scheduled job to call Langflow's API endpoint
   - The endpoint would trigger the flow

**For this guide, we'll assume Langflow has built-in scheduling (Method A or B).**

### Step 5.3: Configure Remaining Flow Schedules

Repeat Step 5.2 for each flow:

**Paid Ads Walker Agent**:
- Schedule: `0 6 * * *`
- Description: "Daily at 6:00 AM"

**Content Walker Agent**:
- Schedule: `0 6 * * *`
- Description: "Daily at 6:00 AM"

**Audience Intelligence Walker Agent**:
- Schedule: `0 8 * * *`
- Description: "Daily at 8:00 AM"

### Step 5.4: Verify Scheduled Runs

After configuring all schedules:

1. **Check the Langflow dashboard**
2. Look for a **"Scheduled Flows"** section or **"Cron Jobs"** tab
3. You should see all 4 flows listed with their schedules:

| Flow Name | Schedule | Next Run |
|-----------|----------|----------|
| SEO Walker Agent | `0 5 * * *` | Tomorrow at 05:00 UTC |
| Paid Ads Walker Agent | `0 6 * * *` | Tomorrow at 06:00 UTC |
| Content Walker Agent | `0 6 * * *` | Tomorrow at 06:00 UTC |
| Audience Intelligence | `0 8 * * *` | Tomorrow at 08:00 UTC |

4. **Enable each schedule** if they're not auto-enabled
5. Verify status shows **"Active"** or **"Enabled"**

---

## Phase 6: Monitor First Automated Run

### Step 6.1: Wait for First Scheduled Run

The first automated run will happen at the scheduled time. To test without waiting:

**Option A: Trigger Manually (Recommended for Testing)**

1. Go to Langflow dashboard
2. Find the flow you want to test
3. Click **"Run Now"** or **"Trigger Manually"** button
4. This will execute the flow immediately without waiting for the cron schedule

**Option B: Wait for Scheduled Time**

If it's close to the scheduled time (e.g., 5:00 AM UTC for SEO), just wait.

### Step 6.2: Monitor Execution Logs

**In Langflow**:
1. Open the flow that should have run
2. Look for **"Execution History"** or **"Logs"** tab
3. Check the latest execution:
   - Status: Success ✅ or Failed ❌
   - Duration: How long it took
   - Output: HTTP response from backend

**In Railway Backend Logs**:
```bash
# Monitor backend logs for incoming suggestions
railway logs --service Main --filter "walker-agents/suggestions"

# Expected log entry:
# [INFO] POST /api/v1/walker-agents/suggestions - 200 OK
```

### Step 6.3: Verify Database

After each scheduled run, check the database:

```sql
-- View suggestions from today
SELECT
  agent_type,
  title,
  priority,
  email_sent,
  created_at
FROM walker_agent_suggestions
WHERE created_at::date = CURRENT_DATE
ORDER BY created_at DESC;

-- Count suggestions by agent type (today)
SELECT agent_type, COUNT(*) as count
FROM walker_agent_suggestions
WHERE created_at::date = CURRENT_DATE
GROUP BY agent_type;
```

### Step 6.4: Check Email Delivery

```sql
-- Email delivery rate for today
SELECT
  COUNT(*) as total,
  SUM(CASE WHEN email_sent THEN 1 ELSE 0 END) as delivered,
  ROUND(100.0 * SUM(CASE WHEN email_sent THEN 1 ELSE 0 END) / COUNT(*), 2) as rate_pct
FROM walker_agent_suggestions
WHERE created_at::date = CURRENT_DATE;

-- Expected: rate_pct should be 100% or close to it
```

---

## Phase 7: Set Up Monitoring & Alerts

### Step 7.1: Create Database Views for Easy Monitoring

```sql
-- Create a view for daily summary
CREATE OR REPLACE VIEW walker_agent_daily_summary AS
SELECT
  created_at::date as date,
  agent_type,
  COUNT(*) as suggestions_count,
  SUM(CASE WHEN email_sent THEN 1 ELSE 0 END) as emails_sent,
  ROUND(AVG(confidence_score), 2) as avg_confidence,
  ROUND(AVG(estimated_revenue_increase), 2) as avg_revenue_impact
FROM walker_agent_suggestions
GROUP BY created_at::date, agent_type
ORDER BY created_at::date DESC, agent_type;

-- Use the view
SELECT * FROM walker_agent_daily_summary
WHERE date = CURRENT_DATE;
```

### Step 7.2: Set Up Railway Alerts (Optional)

In Railway dashboard:
1. Go to **langflow-server** service
2. Click **"Alerts"** or **"Notifications"**
3. Configure alerts for:
   - Service crashes or restarts
   - High error rates
   - Resource usage spikes

### Step 7.3: Create a Daily Monitoring Script

Save this as `scripts/check_walker_agents_daily.sh`:

```bash
#!/bin/bash

# Walker Agents Daily Monitoring Script
# Run this daily to check if all agents executed successfully

DATABASE_URL="postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"

echo "Walker Agents Daily Summary - $(date)"
echo "=========================================="

# Check suggestions for today
psql "$DATABASE_URL" <<EOF
SELECT
  agent_type,
  COUNT(*) as count,
  SUM(CASE WHEN email_sent THEN 1 ELSE 0 END) as emails_sent
FROM walker_agent_suggestions
WHERE created_at::date = CURRENT_DATE
GROUP BY agent_type;

-- Email delivery rate
SELECT
  COUNT(*) as total_suggestions,
  SUM(CASE WHEN email_sent THEN 1 ELSE 0 END) as emails_delivered,
  ROUND(100.0 * SUM(CASE WHEN email_sent THEN 1 ELSE 0 END) / COUNT(*), 2) as delivery_rate_pct
FROM walker_agent_suggestions
WHERE created_at::date = CURRENT_DATE;
EOF

echo ""
echo "Expected: 4 suggestions (seo, content, paid_ads, audience_intelligence)"
echo "Expected: 100% email delivery rate"
```

Make it executable and run daily:
```bash
chmod +x scripts/check_walker_agents_daily.sh

# Run it
./scripts/check_walker_agents_daily.sh
```

---

## Troubleshooting Guide

### Issue 1: "Environment variable not found"

**Symptom**: Flow fails with error about missing `ENGARDE_API_URL` or `WALKER_AGENT_API_KEY_*`

**Solution**:
1. Verify variables are set in Railway:
   ```bash
   railway variables | grep -E "ENGARDE|WALKER"
   ```
2. Restart Langflow service:
   ```bash
   railway restart --service langflow-server
   ```
3. Wait 60 seconds for restart to complete
4. Try running the flow again

### Issue 2: HTTP Request Returns 401 Unauthorized

**Symptom**: Flow executes but HTTP Request node shows 401 error

**Causes**:
- API key incorrect or not in environment variable
- Authorization header format wrong

**Solution**:
1. Check HTTP Request node configuration:
   - Authorization should be: `Bearer ${WALKER_AGENT_API_KEY_ONSIDE_SEO}`
   - NOT: `Bearer WALKER_AGENT_API_KEY_ONSIDE_SEO` (missing `${}`)
   - NOT: The actual API key value (should use variable)

2. Test API key manually:
   ```bash
   API_KEY="wa_onside_production_tvKoJ-yGxSzPkmJ9vAxgnvsdGd_zUPBLDCYVYQg_GDc"

   curl -X POST https://api.engarde.media/api/v1/walker-agents/suggestions \
     -H "Authorization: Bearer $API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "agent_type": "seo",
       "tenant_id": "123e4567-e89b-12d3-a456-426614174000",
       "timestamp": "2025-12-28T17:00:00Z",
       "priority": "high",
       "suggestions": []
     }'

   # Should return 422 (validation error for empty suggestions array)
   # NOT 401
   ```

3. If manual test works but Langflow fails:
   - Re-set environment variables in Railway
   - Restart Langflow
   - Re-import the flow

### Issue 3: HTTP Request Returns 422 Validation Error

**Symptom**: Error about missing required fields (`tenant_id`, `agent_type`, etc.)

**Cause**: Request body is malformed or missing required fields

**Solution**:
1. Check the HTTP Request node's **Body Template**
2. Verify it includes all required fields:
   ```json
   {
     "agent_type": "seo",
     "tenant_id": "{{tenant_id}}",
     "timestamp": "{{current_timestamp}}",
     "priority": "high",
     "suggestions": "{{suggestions_array}}"
   }
   ```
3. Verify the nodes BEFORE the HTTP Request are providing the required data
4. Check that `tenant_id` is a valid UUID from your database

### Issue 4: Email Not Sent

**Symptom**: Suggestion stored in database but `email_sent = false`

**Causes**:
1. User has no email address
2. User notification preferences disabled
3. Brevo API error

**Solutions**:

```sql
-- Check user has email
SELECT u.id, u.email, tu.tenant_id
FROM users u
JOIN tenant_users tu ON tu.user_id = u.id
WHERE tu.tenant_id = 'your-tenant-id';

-- Check notification preferences
SELECT * FROM walker_agent_notification_preferences
WHERE user_id = 'user-id-from-above';

-- If no preferences exist, they'll be created with defaults (all enabled)
```

Check backend logs:
```bash
railway logs --service Main --filter "Email sent to"
# OR
railway logs --service Main --filter "Error sending email"
```

### Issue 5: Cron Schedule Not Triggering

**Symptom**: Scheduled time passes but flow doesn't run

**Solutions**:
1. Check schedule is enabled in Langflow
2. Verify cron expression is correct (use https://crontab.guru to test)
3. Check Langflow execution logs for errors
4. Verify Langflow service is running:
   ```bash
   railway status
   # langflow-server should show "RUNNING"
   ```
5. Check Railway logs:
   ```bash
   railway logs --service langflow-server
   ```

### Issue 6: Flow Takes Too Long / Timeout

**Symptom**: Flow execution times out before completing

**Solutions**:
1. Increase timeout in HTTP Request node (if available)
2. Check backend logs for slow database queries
3. Optimize the flow (reduce unnecessary processing)
4. Consider splitting into smaller flows

---

## Success Checklist

After completing all phases, verify:

- [ ] All 4 flows imported into Langflow
- [ ] All 5 environment variables set in Railway
- [ ] Langflow service restarted after setting variables
- [ ] All 4 flows tested manually and succeeded
- [ ] Database shows test suggestions from all 4 agent types
- [ ] Test emails received for all 4 agent types
- [ ] Cron schedules configured for all 4 flows
- [ ] Schedules are enabled/active
- [ ] First automated run successful
- [ ] Monitoring script created and tested
- [ ] Daily verification process established

---

## Next Steps After Setup

1. **Monitor for 7 days**
   - Check database daily for new suggestions
   - Verify email delivery rates stay above 95%
   - Watch for any failed executions

2. **Optimize based on performance**
   - Adjust schedules if needed (avoid peak traffic times)
   - Fine-tune suggestion generation prompts
   - Adjust confidence thresholds

3. **Expand functionality**
   - Add WhatsApp notifications (Twilio)
   - Add in-platform chat notifications (WebSocket)
   - Build frontend UI for suggestion management

4. **User training**
   - Notify users about Walker Agent suggestions
   - Create user guide for reviewing suggestions
   - Gather feedback on suggestion quality

---

## Quick Reference: Important URLs & Commands

**Langflow Dashboard**:
- https://langflow.engarde.media (or your Railway URL)

**Backend API**:
- Health: https://api.engarde.media/health
- Suggestions: https://api.engarde.media/api/v1/walker-agents/suggestions

**Database Connection**:
```bash
psql "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"
```

**Check Daily Suggestions**:
```sql
SELECT agent_type, COUNT(*) FROM walker_agent_suggestions
WHERE created_at::date = CURRENT_DATE
GROUP BY agent_type;
```

**Check Email Delivery**:
```sql
SELECT
  SUM(CASE WHEN email_sent THEN 1 ELSE 0 END)::float / COUNT(*) * 100 as delivery_rate_pct
FROM walker_agent_suggestions
WHERE created_at::date = CURRENT_DATE;
```

**Restart Langflow**:
```bash
railway restart --service langflow-server
```

**View Backend Logs**:
```bash
railway logs --service Main --filter "walker-agents"
```

---

## Support

For issues or questions:
1. Check this guide's Troubleshooting section
2. Review `WALKER_AGENTS_TESTING_GUIDE.md`
3. Check Railway deployment logs
4. Verify database state with SQL queries above

---

**Setup Time Estimate**: 30-60 minutes for first-time setup

**Last Updated**: December 28, 2025
**Version**: 1.0.0
