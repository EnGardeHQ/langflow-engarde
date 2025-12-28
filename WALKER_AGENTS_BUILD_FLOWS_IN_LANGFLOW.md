# Walker Agents - Build Flows in Langflow Guide

**Issue**: Pre-made JSON files show "Invalid flow data" because Langflow's JSON format is version-specific.

**Solution**: Build the flows directly in Langflow using this step-by-step guide.

**Time Required**: 20-30 minutes for all 4 flows

---

## Why Build Instead of Import?

The flow JSON files we created are conceptual schemas that show the **desired structure**, but Langflow requires a specific format that varies by version. Building flows in Langflow ensures compatibility.

**Good news**: Once you build one flow, the others follow the same pattern!

---

## Prerequisites

Before starting:

- [ ] Langflow accessible at https://langflow.engarde.media
- [ ] Environment variables set in Railway (5 variables - see below)
- [ ] Langflow service restarted after setting variables
- [ ] Backend API live at https://api.engarde.media

### Verify Environment Variables

First, ensure all variables are set:

```bash
# Check Railway variables
railway variables | grep -E "ENGARDE|WALKER"

# Should show:
# ENGARDE_API_URL
# WALKER_AGENT_API_KEY_ONSIDE_SEO
# WALKER_AGENT_API_KEY_ONSIDE_CONTENT
# WALKER_AGENT_API_KEY_SANKORE_PAID_ADS
# WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE
```

If missing, set them:

```bash
railway variables set ENGARDE_API_URL="https://api.engarde.media"
railway variables set WALKER_AGENT_API_KEY_ONSIDE_SEO="wa_onside_production_tvKoJ-yGxSzPkmJ9vAxgnvsdGd_zUPBLDCYVYQg_GDc"
railway variables set WALKER_AGENT_API_KEY_ONSIDE_CONTENT="wa_onside_production_1-oq6OFlu0Pb3kvVHlNeiTcbe8S6u1CMbzmc8ppfxP4"
railway variables set WALKER_AGENT_API_KEY_SANKORE_PAID_ADS="wa_sankore_production_sBhmczd9F_nN_PY94H8TJuS9e7-jZqp5l7rwrQSOscc"
railway variables set WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE="wa_madansara_production_k6XDe6dbAU-JD5zVxOWr8zsPjI-h6OyQAfh1jtRAn5g"

# Restart Langflow for variables to take effect
railway restart --service langflow-server

# Wait 60 seconds
sleep 60
```

---

## Flow 1: SEO Walker Agent (Build Step-by-Step)

Let's build the first flow together. Once you understand the pattern, the other 3 flows will be quick.

### Step 1: Create New Flow

1. Open Langflow: https://langflow.engarde.media
2. Click **"New Flow"** or **"Create Flow"** or **"+"** button
3. You should see an empty canvas

### Step 2: Add Input Node (Tenant ID)

We need to provide a tenant ID as input.

1. **Look for the Components panel** (usually on the left)
2. Find **"Text Input"** or **"Input"** component
3. **Drag it onto the canvas**
4. **Click on the node** to configure:
   - **Name**: `Tenant ID`
   - **Field Name**: `tenant_id`
   - **Value**: *(leave empty for now - we'll provide during testing)*
   - **Is Required**: `true`

### Step 3: Add HTTP Request Node

This is the critical node that sends data to our backend.

1. Find **"HTTP Request"** or **"API Request"** in components
2. **Drag it onto the canvas**
3. **Connect** the Tenant ID output to HTTP Request input (drag from one node's handle to the other)
4. **Click HTTP Request node** to configure:

**Configuration**:

| Field | Value |
|-------|-------|
| **Name** | `Send to Backend API` |
| **URL** | `${ENGARDE_API_URL}/api/v1/walker-agents/suggestions` |
| **Method** | `POST` |
| **Headers** | See below |
| **Body** | See below |
| **Timeout** | `30` |

**Headers** (click Add Header for each):

```json
{
  "Authorization": "Bearer ${WALKER_AGENT_API_KEY_ONSIDE_SEO}",
  "Content-Type": "application/json"
}
```

**CRITICAL**: Use the `${}` syntax for environment variables!

**Body Template**:

```json
{
  "agent_type": "seo",
  "tenant_id": "{tenant_id}",
  "timestamp": "{current_timestamp}",
  "priority": "high",
  "suggestions": [
    {
      "id": "seo-001",
      "type": "keyword_opportunity",
      "title": "High-value SEO opportunity identified",
      "description": "Our analysis shows potential for keyword optimization in your content strategy.",
      "impact": {
        "estimated_revenue_increase": 5000.0,
        "confidence_score": 0.85
      },
      "actions": [
        {
          "action_type": "create_content",
          "description": "Create targeted content for identified keyword opportunities"
        }
      ],
      "cta_url": "https://app.engarde.media/campaigns/create",
      "metadata": {
        "source": "langflow_seo_walker"
      }
    }
  ]
}
```

**Important**:
- The `{tenant_id}` will be replaced with the input value
- The `{current_timestamp}` will be auto-generated (or use Langflow's timestamp function)
- You can add a **Python Function** node before HTTP Request to generate dynamic suggestions

### Step 4: Add Output Node

1. Find **"Text Output"** or **"Output"** component
2. Drag it onto the canvas
3. Connect HTTP Request's output to this node
4. Configure:
   - **Name**: `API Response`

### Step 5: Save the Flow

1. Click **"Save"** button (top right)
2. **Name**: `SEO Walker Agent`
3. **Description**: `SEO analysis agent that sends suggestions to backend`
4. Click **Save**

### Step 6: Test the Flow

Before scheduling, test it manually:

1. **Get a tenant ID** from database:
   ```sql
   psql "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway" \
     -c "SELECT id FROM tenants LIMIT 1;"
   ```

2. **In Langflow**:
   - Enter the tenant ID in the Tenant ID input field
   - Click **"Run"** or **"Play"** button

3. **Expected result**:
   - HTTP Request node turns green
   - Output shows: `{"success": true, "batch_id": "...", ...}`
   - No errors

4. **Verify in database**:
   ```sql
   SELECT * FROM walker_agent_suggestions ORDER BY created_at DESC LIMIT 1;
   ```
   Should show the new suggestion!

5. **Check email** was sent to tenant users

### Step 7: Add Schedule (Optional but Recommended)

**Method A: Using Timer/Scheduler Node**

1. Find **"Timer"** or **"Scheduler"** component
2. Drag it to the left of Tenant ID
3. Configure:
   - **Cron Expression**: `0 5 * * *`
   - **Timezone**: `UTC`
4. Connect Timer → Tenant ID (or Timer → HTTP Request)

**Method B: External Cron Job**

If Langflow doesn't have built-in scheduling, you'll need to trigger it externally:

```bash
# Create a cron job that calls Langflow API
# We'll provide a script for this later
```

---

## Flow 2: Paid Ads Walker Agent (Quick Build)

Now that you understand the pattern, build the Paid Ads flow:

### Differences from SEO Flow:

1. **Flow Name**: `Paid Ads Walker Agent`
2. **HTTP Request Configuration**:
   - **Authorization**: `Bearer ${WALKER_AGENT_API_KEY_SANKORE_PAID_ADS}`
   - **Body**: Change `"agent_type": "paid_ads"`
   - **Suggestion content**: Customize for paid ads insights
3. **Schedule**: `0 6 * * *` (6:00 AM UTC)

### Quick Copy-Paste Body:

```json
{
  "agent_type": "paid_ads",
  "tenant_id": "{tenant_id}",
  "timestamp": "{current_timestamp}",
  "priority": "high",
  "suggestions": [
    {
      "id": "ads-001",
      "type": "campaign_optimization",
      "title": "Paid ads campaign optimization opportunity",
      "description": "Analysis shows potential to improve ROAS through campaign adjustments.",
      "impact": {
        "estimated_revenue_increase": 8000.0,
        "confidence_score": 0.90
      },
      "actions": [
        {
          "action_type": "adjust_bidding",
          "description": "Optimize bidding strategy for better performance"
        }
      ],
      "cta_url": "https://app.engarde.media/campaigns/create",
      "metadata": {
        "source": "langflow_paid_ads_walker"
      }
    }
  ]
}
```

---

## Flow 3: Content Walker Agent

### Differences from SEO Flow:

1. **Flow Name**: `Content Walker Agent`
2. **HTTP Request Configuration**:
   - **Authorization**: `Bearer ${WALKER_AGENT_API_KEY_ONSIDE_CONTENT}`
   - **Body**: Change `"agent_type": "content"`
3. **Schedule**: `0 6 * * *` (6:00 AM UTC)

### Quick Copy-Paste Body:

```json
{
  "agent_type": "content",
  "tenant_id": "{tenant_id}",
  "timestamp": "{current_timestamp}",
  "priority": "medium",
  "suggestions": [
    {
      "id": "content-001",
      "type": "content_gap",
      "title": "Content gap analysis reveals opportunities",
      "description": "Identified content topics with high engagement potential for your audience.",
      "impact": {
        "estimated_revenue_increase": 4000.0,
        "confidence_score": 0.75
      },
      "actions": [
        {
          "action_type": "create_content",
          "description": "Develop content for identified topic opportunities"
        }
      ],
      "cta_url": "https://app.engarde.media/campaigns/create",
      "metadata": {
        "source": "langflow_content_walker"
      }
    }
  ]
}
```

---

## Flow 4: Audience Intelligence Walker Agent

### Differences from SEO Flow:

1. **Flow Name**: `Audience Intelligence Walker Agent`
2. **HTTP Request Configuration**:
   - **Authorization**: `Bearer ${WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE}`
   - **Body**: Change `"agent_type": "audience_intelligence"`
3. **Schedule**: `0 8 * * *` (8:00 AM UTC)

### Quick Copy-Paste Body:

```json
{
  "agent_type": "audience_intelligence",
  "tenant_id": "{tenant_id}",
  "timestamp": "{current_timestamp}",
  "priority": "medium",
  "suggestions": [
    {
      "id": "audience-001",
      "type": "segmentation_opportunity",
      "title": "New audience segment identified",
      "description": "ML analysis revealed a high-value audience segment with strong conversion potential.",
      "impact": {
        "estimated_revenue_increase": 6000.0,
        "confidence_score": 0.82
      },
      "actions": [
        {
          "action_type": "create_campaign",
          "description": "Launch targeted campaign for newly identified segment"
        }
      ],
      "cta_url": "https://app.engarde.media/campaigns/create",
      "metadata": {
        "source": "langflow_audience_intelligence_walker"
      }
    }
  ]
}
```

---

## Advanced: Adding Dynamic Suggestions (Optional)

For more sophisticated flows, add a **Python Function** node before HTTP Request:

### Python Function Example:

```python
from datetime import datetime
import json

def generate_suggestions(tenant_id: str) -> dict:
    """
    Generate dynamic suggestions based on analysis

    In production, this would:
    1. Fetch tenant data from database
    2. Analyze metrics
    3. Generate AI-powered suggestions

    For now, we'll use a template
    """

    return {
        "agent_type": "seo",
        "tenant_id": tenant_id,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "priority": "high",
        "suggestions": [
            {
                "id": f"seo-{datetime.now().timestamp()}",
                "type": "keyword_opportunity",
                "title": "High-value SEO opportunity identified",
                "description": "Our analysis shows potential for keyword optimization.",
                "impact": {
                    "estimated_revenue_increase": 5000.0,
                    "confidence_score": 0.85
                },
                "actions": [
                    {
                        "action_type": "create_content",
                        "description": "Create targeted content"
                    }
                ],
                "cta_url": "https://app.engarde.media/campaigns/create",
                "metadata": {
                    "source": "langflow_seo_walker",
                    "generated_at": datetime.utcnow().isoformat()
                }
            }
        ]
    }
```

**Flow structure with Python**:
```
Tenant ID → Python Function → HTTP Request → Output
```

---

## Troubleshooting

### Issue: "Environment variable not found"

**Cause**: Variables not set or Langflow not restarted

**Fix**:
```bash
# Verify in Railway
railway variables | grep ENGARDE

# Restart Langflow
railway restart --service langflow-server

# Wait 60 seconds
```

### Issue: HTTP Request returns 401

**Cause**: API key incorrect or wrong variable name

**Fix**:
1. Check Authorization header uses: `Bearer ${WALKER_AGENT_API_KEY_ONSIDE_SEO}`
2. NOT: `Bearer WALKER_AGENT_API_KEY_ONSIDE_SEO` (missing `${}`)
3. NOT: Hardcoded key value

### Issue: HTTP Request returns 422

**Cause**: Request body validation failed

**Fix**:
1. Verify tenant_id is a valid UUID from database
2. Check JSON format is correct
3. Ensure all required fields present:
   - `agent_type`
   - `tenant_id`
   - `timestamp`
   - `suggestions` (array)

### Issue: HTTP Request returns 500

**Cause**: Backend error

**Fix**:
```bash
# Check backend logs
railway logs --service Main --filter "walker-agents"

# Look for error messages
```

---

## Testing Checklist

After building all 4 flows:

- [ ] SEO flow runs successfully
- [ ] Paid Ads flow runs successfully
- [ ] Content flow runs successfully
- [ ] Audience Intelligence flow runs successfully
- [ ] Database shows 4 suggestions (one from each agent type)
- [ ] Emails sent to tenant users (check Brevo dashboard)
- [ ] All schedules configured (if using Langflow scheduler)

---

## Alternative: Trigger Flows Externally

If Langflow doesn't have built-in scheduling, you can trigger flows via API from an external cron job:

### Step 1: Get Flow IDs

In Langflow, note the Flow ID for each flow (usually shown in URL or flow settings)

### Step 2: Create Trigger Script

```python
#!/usr/bin/env python3
"""
Trigger Walker Agent flows via Langflow API
Run this as a cron job
"""

import requests
import os
from datetime import datetime

LANGFLOW_URL = "https://langflow.engarde.media"
LANGFLOW_API_KEY = os.getenv("LANGFLOW_API_KEY", "")

FLOWS = {
    "seo": "FLOW_ID_FOR_SEO",
    "paid_ads": "FLOW_ID_FOR_PAID_ADS",
    "content": "FLOW_ID_FOR_CONTENT",
    "audience_intelligence": "FLOW_ID_FOR_AUDIENCE_INTELLIGENCE"
}

def trigger_flow(flow_id, tenant_id):
    """Trigger a Langflow flow"""
    headers = {}
    if LANGFLOW_API_KEY:
        headers["Authorization"] = f"Bearer {LANGFLOW_API_KEY}"

    response = requests.post(
        f"{LANGFLOW_URL}/api/v1/run/{flow_id}",
        headers=headers,
        json={"tenant_id": tenant_id},
        timeout=60
    )

    return response.status_code == 200

# Trigger all flows
for agent_type, flow_id in FLOWS.items():
    print(f"Triggering {agent_type} walker agent...")
    success = trigger_flow(flow_id, "YOUR_TENANT_ID")
    print(f"  {'✅ Success' if success else '❌ Failed'}")
```

### Step 3: Set up Cron Job

```bash
# Edit crontab
crontab -e

# Add these lines:
0 5 * * * python3 /path/to/trigger_seo_walker.py
0 6 * * * python3 /path/to/trigger_paid_ads_walker.py
0 6 * * * python3 /path/to/trigger_content_walker.py
0 8 * * * python3 /path/to/trigger_audience_walker.py
```

---

## Summary

**Why build instead of import?**
- Langflow's JSON format is version-specific
- Building in UI ensures compatibility
- More flexibility for customization

**Pattern for each flow**:
1. Input node (Tenant ID)
2. HTTP Request node (configured with environment variables)
3. Output node
4. Optional: Python Function for dynamic suggestions
5. Optional: Scheduler/Timer for automation

**Time to build**: 20-30 minutes for all 4 flows

**Next**: Test each flow, verify database/email delivery, then set schedules!

---

**Last Updated**: December 28, 2025
