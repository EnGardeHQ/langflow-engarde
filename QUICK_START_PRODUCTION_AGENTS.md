# Quick Start: Deploy Production Agents (30 Minutes)

**Fast deployment guide for all 10 production-ready agents**

---

## Prerequisites (5 min)

### 1. Get a Test Tenant ID

```bash
railway run --service Main -- python3 -c "
import os, psycopg2
conn = psycopg2.connect(os.getenv('DATABASE_PUBLIC_URL'))
cur = conn.cursor()
cur.execute('SELECT id, name FROM tenants LIMIT 1')
tenant = cur.fetchone()
print(f'Tenant: {tenant[1]}')
print(f'ID: {tenant[0]}')
"
```

Copy the ID (UUID format).

### 2. Verify Langflow is Running

Visit: https://langflow.engarde.media

Should load without errors.

---

## Deploy Agents (25 min)

### Quick Deploy Template

For each agent, follow this exact pattern:

1. **Open Langflow** → Click **"New Flow"**
2. **Search** for "Python Function" in left panel
3. **Drag** Python Function node to canvas
4. **Click** on the node to open editor
5. **Copy** agent code from files below
6. **Paste** into the code editor
7. **Search** for "Text Input" in left panel
8. **Drag** Text Input to canvas
9. **Configure** Text Input:
   - Name: `tenant_id`
   - Value: `<paste your tenant UUID>`
10. **Connect** Text Input output → Python Function `tenant_id` input
11. **Click "Run"** (play button on Python Function)
12. **Verify** success in output
13. **Click "Save"** and name the flow
14. **Next agent!**

---

## Agent 1: SEO Walker (3 min)

**Code Source**: `PRODUCTION_READY_LANGFLOW_AGENTS.md` lines 56-685

**Flow Name**: `SEO Walker Agent`

**Test Output Should Contain**:
```json
{
  "success": true,
  "suggestions_generated": 6,
  "suggestions_stored": 6
}
```

---

## Agent 2: Paid Ads Walker (3 min)

**Code Source**: `PRODUCTION_READY_LANGFLOW_AGENTS.md` lines 693-1076

**Flow Name**: `Paid Ads Walker Agent`

**Test Output Should Contain**:
```json
{
  "success": true,
  "agent_type": "paid_ads_optimization",
  "suggestions_generated": 5
}
```

---

## Agent 3: Content Walker (3 min)

**Code Source**: `PRODUCTION_AGENTS_PART2.md` lines 11-384

**Flow Name**: `Content Walker Agent`

**Test Output Should Contain**:
```json
{
  "success": true,
  "agent_type": "content_strategy",
  "suggestions_generated": 6
}
```

---

## Agent 4: Audience Intelligence Walker (3 min)

**Code Source**: `PRODUCTION_AGENTS_PART2.md` lines 392-791

**Flow Name**: `Audience Intelligence Walker Agent`

**Test Output Should Contain**:
```json
{
  "success": true,
  "agent_type": "audience_intelligence",
  "suggestions_generated": 6
}
```

---

## Agent 5: Campaign Creation (3 min)

**Code Source**: `PRODUCTION_AGENTS_PART3_ENGARDE.md` lines 11-217

**Flow Name**: `Campaign Creation Agent`

**Inputs**:
- `tenant_id` (Text Input)
- `campaign_name` (Text Input) - Optional, set to "Test Campaign"
- `campaign_type` (Text Input) - Set to "email"

**Test Output Should Contain**:
```json
{
  "success": true,
  "campaign_id": "<uuid>",
  "status": "draft"
}
```

---

## Agent 6: Analytics Report (3 min)

**Code Source**: `PRODUCTION_AGENTS_PART3_ENGARDE.md` lines 225-492

**Flow Name**: `Analytics Report Agent`

**Inputs**:
- `tenant_id` (Text Input)
- `report_type` (Text Input) - Set to "monthly"
- `days_back` (Number Input) - Set to 30

**Test Output Should Contain**:
```json
{
  "success": true,
  "executive_summary": {
    "total_marketing_spend": 0,
    "overall_roi": 0
  }
}
```

---

## Agent 7: Content Approval (2 min)

**Code Source**: `PRODUCTION_AGENTS_FINAL_COMPLETE.md` lines 11-91

**Flow Name**: `Content Approval Agent`

**Inputs**:
- `tenant_id` (Text Input)
- `content_id` (Text Input) - Use a test UUID or create content first
- `auto_approve_threshold` (Number Input) - Set to 0.85

**Test Output Should Contain**:
```json
{
  "success": true,
  "decision": "approved" | "rejected" | "pending_review",
  "quality_score": 0.85
}
```

---

## Agent 8: Campaign Launcher (2 min)

**Code Source**: `PRODUCTION_AGENTS_FINAL_COMPLETE.md` lines 99-236

**Flow Name**: `Campaign Launcher Agent`

**Inputs**:
- `tenant_id` (Text Input)
- `campaign_id` (Text Input) - Use campaign_id from Agent 5
- `launch_mode` (Text Input) - Set to "scheduled"

**Test Output Should Contain**:
```json
{
  "success": true,
  "status": "launched",
  "all_checks_passed": true
}
```

---

## Agent 9: Notification (2 min)

**Code Source**: `PRODUCTION_AGENTS_FINAL_COMPLETE.md` lines 244-358

**Flow Name**: `Notification Agent`

**Inputs**:
- `tenant_id` (Text Input)
- `notification_type` (Text Input) - Set to "walker_suggestions"
- `channel` (Text Input) - Set to "email"

**Test Output Should Contain**:
```json
{
  "success": true,
  "notifications_sent": 1,
  "recipients_targeted": 1
}
```

---

## Agent 10: Performance Monitoring (2 min)

**Code Source**: `PRODUCTION_AGENTS_FINAL_COMPLETE.md` lines 366-519

**Flow Name**: `Performance Monitoring Agent`

**Inputs**:
- `tenant_id` (Text Input)
- `monitor_mode` (Text Input) - Set to "campaigns"

**Test Output Should Contain**:
```json
{
  "success": true,
  "alerts_triggered": 0,
  "message": "All metrics within normal thresholds"
}
```

---

## Verification (5 min)

### 1. Check All Flows Saved

In Langflow, you should see 10 flows:
- SEO Walker Agent
- Paid Ads Walker Agent
- Content Walker Agent
- Audience Intelligence Walker Agent
- Campaign Creation Agent
- Analytics Report Agent
- Content Approval Agent
- Campaign Launcher Agent
- Notification Agent
- Performance Monitoring Agent

### 2. Verify Database Updates

```bash
railway run --service Main -- python3 -c "
import os, psycopg2
conn = psycopg2.connect(os.getenv('DATABASE_PUBLIC_URL'))
cur = conn.cursor()

# Check Walker suggestions
cur.execute('SELECT COUNT(*) FROM walker_agent_suggestions')
print(f'Walker Suggestions: {cur.fetchone()[0]}')

# Check campaigns
cur.execute('SELECT COUNT(*) FROM campaigns')
print(f'Campaigns: {cur.fetchone()[0]}')
"
```

Should show new rows created.

### 3. Check Email Notifications

Check inbox for notification emails sent by Agent 9.

---

## Schedule Daily Runs (Optional, 10 min)

For each Walker Agent (Agents 1-4):

1. **Open the flow** in Langflow
2. **Add Cron Schedule** node from left panel
3. **Configure schedule**:
   - Pattern: `0 9 * * *` (9 AM daily)
   - Or use visual cron editor
4. **Connect**: Cron Schedule → Text Input
5. **Save flow**

The agents will now run automatically every day at 9 AM.

---

## Troubleshooting

### Error: "Module 'httpx' not found"

Langflow Docker image should include httpx. If not:
1. Check Railway logs
2. May need to add httpx to Langflow requirements

### Error: "Environment variable X not set"

1. Go to Railway → langflow-server → Settings → Environment Variables
2. Add missing variable
3. Restart langflow-server

### Error: "API returned 401 Unauthorized"

1. Verify API keys are correct
2. Check keys haven't expired
3. Test API endpoint manually with curl

### Error: "No data returned from lakehouse/BigQuery/ZeroDB"

This is expected if:
- Tenant is new (no historical data)
- Services aren't deployed yet (lakehouse, ZeroDB)

Agents will still run but generate fewer/no suggestions.

---

## Success Checklist

- [ ] All 10 flows created in Langflow
- [ ] All 10 flows tested with real tenant_id
- [ ] All flows return `"success": true`
- [ ] Walker suggestions visible in database
- [ ] Campaigns created in database
- [ ] Email notifications received
- [ ] (Optional) Cron schedules set for daily runs

---

## What You Built

You now have:

- **4 Walker Agents** generating marketing suggestions daily
- **6 EnGarde Agents** automating marketing workflows
- **Full data integration** with lakehouse, BigQuery, ZeroDB
- **Dynamic multi-tenant** support (duplicate flows with new tenant_id)
- **Production-ready** code with error handling
- **Automated scheduling** (if configured)

**Estimated Time Saved**: 20-40 hours/week per tenant in manual marketing analysis and optimization

**ROI**: $327,600/year through batched agent processing vs real-time (per architecture doc)

---

## Next Steps

1. **Deploy to additional tenants**: Duplicate flows, change tenant_id
2. **Monitor performance**: Check logs daily for errors
3. **Iterate based on feedback**: Improve suggestions based on user actions
4. **Add more agents**: Follow same pattern for custom use cases
5. **Scale infrastructure**: Add lakehouse/ZeroDB as usage grows

---

**Deployment Time**: ~30 minutes
**Difficulty**: Easy (copy-paste + configure)
**Maintenance**: Low (automated daily runs)

You're ready to go! 🚀

