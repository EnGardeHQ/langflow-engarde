# Walker Agents Flow Import - Visual Guide

**Quick Start**: The flow files are already open in Finder! Just drag and drop into Langflow.

---

## Method 1: Automated Import Tool (Recommended) 🚀

The easiest way to import flows:

```bash
cd /Users/cope/EnGardeHQ/production-backend

# Run the import tool (opens Finder automatically)
python3 scripts/import_walker_agent_flows.py --manual
```

**What it does**:
- ✅ Verifies all 4 flow files exist
- ✅ Opens the flows folder in Finder
- ✅ Shows step-by-step instructions
- ✅ Creates a printable checklist

---

## Method 2: Manual Drag-and-Drop (Easiest) 🎯

### Step 1: Open Langflow

```bash
# Open Langflow in your default browser
open https://langflow.engarde.media
```

### Step 2: Open Flows Folder

The folder should already be open from running the script. If not:

```bash
# Open flows folder in Finder
open /Users/cope/EnGardeHQ/production-backend/langflow/flows
```

You should see 4 files:
```
seo_walker_agent_with_backend_integration.json
paid_ads_walker_agent_with_backend_integration.json
content_walker_agent_with_backend_integration.json
audience_intelligence_walker_agent_with_backend_integration.json
```

### Step 3: Import Flows

**Option A: Drag and Drop** (if Langflow supports it)

1. Arrange your windows so you can see both:
   - Finder window with flow files
   - Langflow dashboard in browser

2. Drag `seo_walker_agent_with_backend_integration.json` from Finder
3. Drop it onto the Langflow dashboard
4. Flow should appear in the editor
5. Click "Save" or "Update Flow"
6. Repeat for other 3 files

**Option B: Click to Upload**

1. In Langflow dashboard, click **"Import Flow"** button
   - Usually in top right corner
   - May be labeled "+ New Flow" → "Import"

2. Click **"Upload JSON"** or **"Browse Files"**

3. File picker dialog opens
   - Navigate to: `/Users/cope/EnGardeHQ/production-backend/langflow/flows`
   - OR if Finder is open, the dialog may start in that folder

4. Select `seo_walker_agent_with_backend_integration.json`

5. Click **"Open"** or **"Import"**

6. Flow loads in editor
   - You should see connected nodes
   - Schedule Trigger → Processing nodes → HTTP Request

7. Click **"Save"**

8. Return to dashboard

9. **Repeat for remaining 3 flows**

---

## Step 4: Verify Each Flow

For each imported flow, verify the HTTP Request node:

### What to Check

1. **Click on the HTTP Request node** (usually on the right side)

2. **Configuration panel opens** (on the right)

3. **Verify these settings**:

| Setting | Expected Value | Notes |
|---------|----------------|-------|
| **URL** | `${ENGARDE_API_URL}/api/v1/walker-agents/suggestions` | Uses variable syntax |
| **Method** | `POST` | From dropdown |
| **Headers** | See below | Multiple headers |

**Headers should include**:
```json
{
  "Authorization": "Bearer ${WALKER_AGENT_API_KEY_XXXX}",
  "Content-Type": "application/json"
}
```

**CRITICAL**: The API key should reference the **environment variable**, not the actual key value!

**Correct**: `Bearer ${WALKER_AGENT_API_KEY_ONSIDE_SEO}`
**WRONG**: `Bearer wa_onside_production_abc123...` (hardcoded key)

### API Key Variables by Flow

| Flow Name | Authorization Header |
|-----------|---------------------|
| SEO Walker Agent | `Bearer ${WALKER_AGENT_API_KEY_ONSIDE_SEO}` |
| Paid Ads Walker Agent | `Bearer ${WALKER_AGENT_API_KEY_SANKORE_PAID_ADS}` |
| Content Walker Agent | `Bearer ${WALKER_AGENT_API_KEY_ONSIDE_CONTENT}` |
| Audience Intelligence | `Bearer ${WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE}` |

---

## Step 5: Configure Cron Schedules

After importing all flows, set up automatic execution.

### For Each Flow:

1. **Open the flow** in Langflow editor

2. **Find the Schedule Trigger node** (first node on the left)

3. **Click on it** to open configuration

4. **Set the schedule**:

| Flow | Cron Expression | Time (UTC) |
|------|-----------------|------------|
| SEO Walker Agent | `0 5 * * *` | 5:00 AM |
| Paid Ads Walker Agent | `0 6 * * *` | 6:00 AM |
| Content Walker Agent | `0 6 * * *` | 6:00 AM |
| Audience Intelligence | `0 8 * * *` | 8:00 AM |

5. **Alternative**: Some Langflow versions have Flow Settings
   - Click gear icon or three dots menu
   - Go to "Schedule" tab
   - Enable scheduling
   - Enter cron expression
   - Set timezone to UTC

6. **Save the flow**

---

## Troubleshooting

### "Import Flow" Button Not Found

**Try these locations**:
- Top right corner of dashboard
- Main menu → Flows → Import
- "+" button → Import from JSON
- File menu → Import

### Flow Doesn't Load After Import

**Check**:
1. JSON file is valid (open in text editor, should start with `{`)
2. File size is reasonable (should be 3-5 KB)
3. Try re-downloading or re-creating the file

**Re-download**:
```bash
# Files are in the repo at:
ls -lh /Users/cope/EnGardeHQ/production-backend/langflow/flows/

# If corrupted, they can be regenerated
```

### HTTP Request Node Shows Error

**Common issues**:
1. Environment variables not set in Railway
2. Langflow not restarted after setting variables
3. Variable syntax incorrect (should be `${VAR_NAME}`)

**Fix**:
```bash
# Verify variables in Railway
railway variables | grep -E "ENGARDE|WALKER"

# Restart Langflow
railway restart --service langflow-server

# Wait 60 seconds, then try again
```

### Schedule Not Triggering

**Check**:
1. Schedule is enabled (toggle should be ON)
2. Cron expression is valid (use https://crontab.guru to test)
3. Langflow service is running
4. Check Langflow logs for errors

**Verify**:
```bash
# Check Langflow status
railway status

# View logs
railway logs --service langflow-server
```

---

## Quick Verification Commands

After importing, verify everything:

```bash
# 1. Check Langflow is accessible
curl -I https://langflow.engarde.media
# Should return HTTP 200

# 2. Check backend endpoint
curl -X POST https://api.engarde.media/api/v1/walker-agents/suggestions \
  -H "Content-Type: application/json" \
  -d '{}'
# Should return 422 (validation error - expected!)

# 3. Check database has API keys ready
psql "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway" \
  -c "SELECT COUNT(*) FROM walker_agent_api_keys WHERE is_active = true;"
# Should return 4

# 4. Run full verification
python3 scripts/verify_walker_agents_deployment.py
# Should show 4/5 checks passing (email check may fail locally)
```

---

## Success Criteria

You've successfully imported the flows when:

- [ ] All 4 flows visible in Langflow dashboard
- [ ] Each flow opens without errors
- [ ] HTTP Request nodes have correct URL and headers
- [ ] Authorization uses environment variables (not hardcoded keys)
- [ ] All 4 cron schedules configured
- [ ] Schedules are enabled/active
- [ ] First manual test succeeds for each flow

---

## Next Steps

After importing:

1. **Test each flow manually** (see `WALKER_AGENTS_TESTING_GUIDE.md`)
2. **Monitor first scheduled run** (tomorrow at scheduled times)
3. **Verify database** gets new suggestions daily
4. **Check email delivery** via Brevo dashboard

---

## File Locations Reference

**Flow JSON Files**:
```
/Users/cope/EnGardeHQ/production-backend/langflow/flows/
├── seo_walker_agent_with_backend_integration.json
├── paid_ads_walker_agent_with_backend_integration.json
├── content_walker_agent_with_backend_integration.json
└── audience_intelligence_walker_agent_with_backend_integration.json
```

**Import Tool**:
```bash
/Users/cope/EnGardeHQ/production-backend/scripts/import_walker_agent_flows.py
```

**Checklist**:
```
/Users/cope/EnGardeHQ/production-backend/WALKER_AGENTS_IMPORT_CHECKLIST.md
```

**Documentation**:
```
/Users/cope/EnGardeHQ/LANGFLOW_WALKER_AGENTS_SETUP_INSTRUCTIONS.md
/Users/cope/EnGardeHQ/WALKER_AGENTS_TESTING_GUIDE.md
```

---

## Support

If you run into issues:

1. Check the Troubleshooting section above
2. Review `LANGFLOW_WALKER_AGENTS_SETUP_INSTRUCTIONS.md`
3. Run the verification script: `python3 scripts/verify_walker_agents_deployment.py`
4. Check Railway logs: `railway logs --service langflow-server`

---

**Estimated Time**: 10-15 minutes for all 4 flows

**Last Updated**: December 28, 2025
