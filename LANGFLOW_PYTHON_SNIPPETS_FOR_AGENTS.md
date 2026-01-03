# Langflow Python Snippets - Copy & Paste Ready

**Simple Python code to paste into Langflow Python Function nodes**

These snippets are designed to be **copied and pasted directly** into Python Function nodes in the Langflow UI.

---

## How to Use These Snippets

1. **Create a new flow** in Langflow
2. **Add a "Python Function" node** (or "Custom Python" node)
3. **Copy the code** from below
4. **Paste it** into the Python Function node
5. **Configure inputs** as needed
6. **Run the flow**

---

## Walker Agent Snippets

### 1. SEO Walker Agent (Complete Flow)

**Copy this into a Python Function node:**

```python
import httpx
import json
import os
from datetime import datetime
import uuid

def run(tenant_id: str) -> dict:
    """
    SEO Walker Agent - Sends SEO suggestions to EnGarde backend

    Args:
        tenant_id: UUID of the tenant to analyze

    Returns:
        dict: API response from backend
    """

    # Build suggestion
    suggestion = {
        "id": str(uuid.uuid4()),
        "type": "keyword_opportunity",
        "title": "High-value SEO opportunity identified",
        "description": "Our analysis shows potential for keyword optimization in your content strategy. Focus on long-tail keywords with high search volume and low competition.",
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
            "generated_at": datetime.utcnow().isoformat() + "Z",
            "source": "langflow_seo_walker"
        }
    }

    # Build API payload
    payload = {
        "agent_type": "seo",
        "tenant_id": tenant_id,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "priority": "high",
        "suggestions": [suggestion]
    }

    # Get environment variables
    api_url = os.getenv("ENGARDE_API_URL", "https://api.engarde.media")
    api_key = os.getenv("WALKER_AGENT_API_KEY_ONSIDE_SEO")

    # Send to backend API
    endpoint = f"{api_url}/api/v1/walker-agents/suggestions"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    try:
        with httpx.Client(timeout=30) as client:
            response = client.post(endpoint, json=payload, headers=headers)

            if response.status_code in [200, 201]:
                return response.json()
            else:
                return {
                    "success": False,
                    "error": f"HTTP {response.status_code}: {response.text}"
                }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }
```

**Inputs to configure in Langflow:**
- `tenant_id` (string): Tenant UUID from database

**Output:** JSON response from API

---

### 2. Paid Ads Walker Agent

```python
import httpx
import json
import os
from datetime import datetime
import uuid

def run(tenant_id: str) -> dict:
    """Paid Ads Walker Agent"""

    suggestion = {
        "id": str(uuid.uuid4()),
        "type": "campaign_optimization",
        "title": "Paid ads campaign optimization opportunity",
        "description": "Analysis shows potential to improve ROAS through campaign adjustments and budget reallocation.",
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
            "generated_at": datetime.utcnow().isoformat() + "Z",
            "source": "langflow_paid_ads_walker"
        }
    }

    payload = {
        "agent_type": "paid_ads",
        "tenant_id": tenant_id,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "priority": "high",
        "suggestions": [suggestion]
    }

    api_url = os.getenv("ENGARDE_API_URL", "https://api.engarde.media")
    api_key = os.getenv("WALKER_AGENT_API_KEY_SANKORE_PAID_ADS")

    endpoint = f"{api_url}/api/v1/walker-agents/suggestions"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    try:
        with httpx.Client(timeout=30) as client:
            response = client.post(endpoint, json=payload, headers=headers)
            return response.json() if response.status_code in [200, 201] else {
                "success": False,
                "error": response.text
            }
    except Exception as e:
        return {"success": False, "error": str(e)}
```

---

### 3. Content Walker Agent

```python
import httpx
import json
import os
from datetime import datetime
import uuid

def run(tenant_id: str) -> dict:
    """Content Walker Agent"""

    suggestion = {
        "id": str(uuid.uuid4()),
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
            "generated_at": datetime.utcnow().isoformat() + "Z",
            "source": "langflow_content_walker"
        }
    }

    payload = {
        "agent_type": "content",
        "tenant_id": tenant_id,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "priority": "medium",
        "suggestions": [suggestion]
    }

    api_url = os.getenv("ENGARDE_API_URL", "https://api.engarde.media")
    api_key = os.getenv("WALKER_AGENT_API_KEY_ONSIDE_CONTENT")

    endpoint = f"{api_url}/api/v1/walker-agents/suggestions"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    try:
        with httpx.Client(timeout=30) as client:
            response = client.post(endpoint, json=payload, headers=headers)
            return response.json() if response.status_code in [200, 201] else {
                "success": False,
                "error": response.text
            }
    except Exception as e:
        return {"success": False, "error": str(e)}
```

---

### 4. Audience Intelligence Walker Agent

```python
import httpx
import json
import os
from datetime import datetime
import uuid

def run(tenant_id: str) -> dict:
    """Audience Intelligence Walker Agent"""

    suggestion = {
        "id": str(uuid.uuid4()),
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
            "generated_at": datetime.utcnow().isoformat() + "Z",
            "source": "langflow_audience_intelligence_walker"
        }
    }

    payload = {
        "agent_type": "audience_intelligence",
        "tenant_id": tenant_id,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "priority": "medium",
        "suggestions": [suggestion]
    }

    api_url = os.getenv("ENGARDE_API_URL", "https://api.engarde.media")
    api_key = os.getenv("WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE")

    endpoint = f"{api_url}/api/v1/walker-agents/suggestions"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    try:
        with httpx.Client(timeout=30) as client:
            response = client.post(endpoint, json=payload, headers=headers)
            return response.json() if response.status_code in [200, 201] else {
                "success": False,
                "error": response.text
            }
    except Exception as e:
        return {"success": False, "error": str(e)}
```

---

## En Garde Agent Workflows

**These are the broader marketing automation agents (not just suggestion-based)**

### 5. Campaign Creation Agent

```python
import httpx
import json
import os
from datetime import datetime

def run(tenant_id: str, campaign_name: str, campaign_type: str) -> dict:
    """
    En Garde Campaign Creation Agent

    Automatically creates a new campaign in the EnGarde platform

    Args:
        tenant_id: Tenant UUID
        campaign_name: Name for the new campaign
        campaign_type: Type of campaign (seo, paid_ads, content, social)
    """

    api_url = os.getenv("ENGARDE_API_URL", "https://api.engarde.media")
    # Use main backend API key or user token
    api_token = os.getenv("ENGARDE_API_TOKEN")

    payload = {
        "name": campaign_name,
        "type": campaign_type,
        "tenant_id": tenant_id,
        "status": "draft",
        "created_at": datetime.utcnow().isoformat() + "Z",
        "metadata": {
            "created_by": "langflow_agent",
            "automation": True
        }
    }

    endpoint = f"{api_url}/api/v1/campaigns"
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }

    try:
        with httpx.Client(timeout=30) as client:
            response = client.post(endpoint, json=payload, headers=headers)
            return response.json() if response.status_code in [200, 201] else {
                "success": False,
                "error": response.text
            }
    except Exception as e:
        return {"success": False, "error": str(e)}
```

---

### 6. Analytics Report Agent

```python
import httpx
import json
import os
from datetime import datetime, timedelta

def run(tenant_id: str, campaign_id: str = None, days: int = 7) -> dict:
    """
    En Garde Analytics Report Agent

    Fetches analytics data and generates insights

    Args:
        tenant_id: Tenant UUID
        campaign_id: Optional campaign ID to analyze
        days: Number of days to analyze (default: 7)
    """

    api_url = os.getenv("ENGARDE_API_URL", "https://api.engarde.media")
    api_token = os.getenv("ENGARDE_API_TOKEN")

    # Calculate date range
    end_date = datetime.utcnow()
    start_date = end_date - timedelta(days=days)

    params = {
        "tenant_id": tenant_id,
        "start_date": start_date.isoformat(),
        "end_date": end_date.isoformat()
    }

    if campaign_id:
        params["campaign_id"] = campaign_id

    endpoint = f"{api_url}/api/v1/analytics/summary"
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }

    try:
        with httpx.Client(timeout=30) as client:
            response = client.get(endpoint, params=params, headers=headers)

            if response.status_code == 200:
                data = response.json()

                # Generate insights
                insights = {
                    "period": f"Last {days} days",
                    "data": data,
                    "insights": [
                        f"Total campaigns: {data.get('total_campaigns', 0)}",
                        f"Active campaigns: {data.get('active_campaigns', 0)}",
                        f"Total revenue: ${data.get('total_revenue', 0):,.2f}"
                    ]
                }

                return insights
            else:
                return {
                    "success": False,
                    "error": response.text
                }
    except Exception as e:
        return {"success": False, "error": str(e)}
```

---

### 7. Content Approval Workflow Agent

```python
import httpx
import json
import os
from datetime import datetime

def run(tenant_id: str, content_id: str, action: str, notes: str = "") -> dict:
    """
    En Garde Content Approval Workflow Agent

    Handles content approval/rejection workflow

    Args:
        tenant_id: Tenant UUID
        content_id: Content item ID to approve/reject
        action: "approve" or "reject"
        notes: Optional notes for approval/rejection
    """

    api_url = os.getenv("ENGARDE_API_URL", "https://api.engarde.media")
    api_token = os.getenv("ENGARDE_API_TOKEN")

    payload = {
        "content_id": content_id,
        "action": action,
        "notes": notes,
        "reviewed_at": datetime.utcnow().isoformat() + "Z",
        "reviewed_by": "langflow_agent"
    }

    endpoint = f"{api_url}/api/v1/content/{content_id}/review"
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }

    try:
        with httpx.Client(timeout=30) as client:
            response = client.post(endpoint, json=payload, headers=headers)
            return response.json() if response.status_code in [200, 201] else {
                "success": False,
                "error": response.text
            }
    except Exception as e:
        return {"success": False, "error": str(e)}
```

---

### 8. Scheduled Campaign Launcher

```python
import httpx
import json
import os
from datetime import datetime

def run(tenant_id: str, campaign_id: str, launch_immediately: bool = True) -> dict:
    """
    En Garde Scheduled Campaign Launcher

    Launches a campaign that was previously created in draft mode

    Args:
        tenant_id: Tenant UUID
        campaign_id: Campaign ID to launch
        launch_immediately: If True, launch now. If False, schedule for later
    """

    api_url = os.getenv("ENGARDE_API_URL", "https://api.engarde.media")
    api_token = os.getenv("ENGARDE_API_TOKEN")

    payload = {
        "status": "active",
        "launched_at": datetime.utcnow().isoformat() + "Z" if launch_immediately else None,
        "launched_by": "langflow_agent"
    }

    endpoint = f"{api_url}/api/v1/campaigns/{campaign_id}"
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }

    try:
        with httpx.Client(timeout=30) as client:
            response = client.patch(endpoint, json=payload, headers=headers)
            return response.json() if response.status_code == 200 else {
                "success": False,
                "error": response.text
            }
    except Exception as e:
        return {"success": False, "error": str(e)}
```

---

### 9. Multi-Channel Notification Agent

```python
import httpx
import json
import os
from datetime import datetime

def run(tenant_id: str, message: str, channels: list = None) -> dict:
    """
    En Garde Multi-Channel Notification Agent

    Sends notifications via multiple channels (email, WhatsApp, in-app)

    Args:
        tenant_id: Tenant UUID
        message: Notification message
        channels: List of channels ("email", "whatsapp", "in_app")
    """

    if channels is None:
        channels = ["email", "in_app"]

    api_url = os.getenv("ENGARDE_API_URL", "https://api.engarde.media")
    api_token = os.getenv("ENGARDE_API_TOKEN")

    payload = {
        "tenant_id": tenant_id,
        "message": message,
        "channels": channels,
        "sent_at": datetime.utcnow().isoformat() + "Z",
        "sent_by": "langflow_agent"
    }

    endpoint = f"{api_url}/api/v1/notifications/send"
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }

    try:
        with httpx.Client(timeout=30) as client:
            response = client.post(endpoint, json=payload, headers=headers)
            return response.json() if response.status_code in [200, 201] else {
                "success": False,
                "error": response.text
            }
    except Exception as e:
        return {"success": False, "error": str(e)}
```

---

### 10. Performance Monitoring Agent

```python
import httpx
import json
import os
from datetime import datetime

def run(tenant_id: str, campaign_id: str, threshold_type: str = "revenue", threshold_value: float = 1000.0) -> dict:
    """
    En Garde Performance Monitoring Agent

    Monitors campaign performance and triggers alerts when thresholds are met

    Args:
        tenant_id: Tenant UUID
        campaign_id: Campaign to monitor
        threshold_type: Type of threshold ("revenue", "conversions", "roi")
        threshold_value: Threshold value to trigger alert
    """

    api_url = os.getenv("ENGARDE_API_URL", "https://api.engarde.media")
    api_token = os.getenv("ENGARDE_API_TOKEN")

    # Get campaign performance
    endpoint = f"{api_url}/api/v1/campaigns/{campaign_id}/performance"
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }

    try:
        with httpx.Client(timeout=30) as client:
            response = client.get(endpoint, headers=headers)

            if response.status_code == 200:
                performance = response.json()
                current_value = performance.get(threshold_type, 0)

                # Check if threshold exceeded
                threshold_met = current_value >= threshold_value

                result = {
                    "campaign_id": campaign_id,
                    "threshold_type": threshold_type,
                    "threshold_value": threshold_value,
                    "current_value": current_value,
                    "threshold_met": threshold_met,
                    "alert": f"Threshold {'EXCEEDED' if threshold_met else 'not met'}"
                }

                # Optionally send notification if threshold met
                if threshold_met:
                    result["notification_sent"] = True
                    # You could trigger another agent here to send notification

                return result
            else:
                return {
                    "success": False,
                    "error": response.text
                }
    except Exception as e:
        return {"success": False, "error": str(e)}
```

---

## How to Create a Flow in Langflow UI

### Step-by-Step Example: SEO Walker Agent

1. **Open Langflow**: https://langflow.engarde.media

2. **Create New Flow**: Click "New Flow" button

3. **Add Text Input Node**:
   - Drag "Text Input" to canvas
   - Name it: "Tenant ID"
   - Set default value: (your tenant UUID from database)

4. **Add Python Function Node**:
   - Drag "Python Function" to canvas
   - **Copy the entire SEO Walker Agent code from above**
   - **Paste it** into the Python Function node's code editor
   - Connect "Tenant ID" output to Python Function input

5. **Add Output Node**:
   - Drag "Text Output" to canvas
   - Connect Python Function output to Text Output input

6. **Save Flow**:
   - Click "Save"
   - Name: "SEO Walker Agent"

7. **Test**:
   - Click "Run"
   - Check output for `"success": true`

Your flow should look like:
```
[Tenant ID Input] → [Python Function (SEO code)] → [Text Output]
```

---

## Tips for Copy-Paste

### ✅ DO
- Copy the **entire function** including imports
- Make sure to include all imports at the top
- Use the `run()` function name (Langflow expects this)
- Test with a valid tenant_id first

### ❌ DON'T
- Modify the function signature `def run(...)`
- Remove the imports
- Change environment variable names
- Hardcode API keys (use env variables)

---

## Saving Your Flows

**IMPORTANT**: Langflow flows are **stored in Langflow's database**, NOT as files!

To export/backup your flows:

1. **In Langflow UI**: Click on flow → Export → Download JSON
2. **Save the JSON** file somewhere safe
3. **To restore**: Import the JSON file back into Langflow

**Recommended**: Export all flows weekly and store in git:
```bash
# Create a directory for flow backups
mkdir -p production-backend/langflow/flows/backups

# Save exported JSONs here
# Commit to git for version control
```

---

## Next Steps

1. **Test each snippet** individually in Langflow
2. **Export working flows** as JSON backups
3. **Add cron triggers** for automated execution
4. **Monitor results** in database and logs

---

**Created**: December 28, 2025
**Format**: Copy-paste ready Python for Langflow Python Function nodes
