# Walker Agents - Quick Start Guide

**Goal**: Get your first Walker Agent running in Langflow in under 10 minutes

---

## ⚡ Fastest Path (Right Now)

### Step 1: Get a Tenant ID (30 seconds)

```bash
railway run --service Main -- python3 -c "
import os, psycopg2
conn = psycopg2.connect(os.getenv('DATABASE_PUBLIC_URL'))
cur = conn.cursor()
cur.execute('SELECT id, name FROM tenants LIMIT 3')
for row in cur.fetchall():
    print(f'{row[1]}: {row[0]}')
"
```

Copy one of the UUIDs shown.

---

### Step 2: Open Langflow (10 seconds)

Go to: https://langflow.engarde.media

Click "New Flow"

---

### Step 3: Add Python Function Node (20 seconds)

1. Look for **"Python Function"**, **"Custom Python"**, or **"Code"** in the left panel
2. Drag it onto the canvas
3. Click on it to open the editor

---

### Step 4: Paste SEO Walker Agent Code (30 seconds)

Copy this entire block and paste into the Python Function node:

```python
import httpx
import os
from datetime import datetime
import uuid

def run(tenant_id: str) -> dict:
    """SEO Walker Agent - Sends SEO suggestions to EnGarde backend"""
    
    suggestion = {
        "id": str(uuid.uuid4()),
        "type": "keyword_opportunity",
        "title": "High-value SEO opportunity identified",
        "description": "Our analysis shows potential for keyword optimization in your content strategy. Focus on long-tail keywords with high search volume and low competition.",
        "impact": {
            "estimated_revenue_increase": 5000.0,
            "confidence_score": 0.85
        },
        "actions": [{
            "action_type": "create_content",
            "description": "Create targeted content for identified keyword opportunities",
            "cta_text": "Start Optimizing",
            "cta_url": "https://app.engarde.media/campaigns/create"
        }],
        "metadata": {
            "generated_at": datetime.utcnow().isoformat() + "Z",
            "source": "langflow_seo_walker",
            "keywords_analyzed": 250,
            "top_opportunity": "long-tail keywords"
        }
    }

    payload = {
        "agent_type": "seo",
        "tenant_id": tenant_id,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "priority": "high",
        "suggestions": [suggestion]
    }

    api_url = os.getenv("ENGARDE_API_URL", "https://api.engarde.media")
    api_key = os.getenv("WALKER_AGENT_API_KEY_ONSIDE_SEO")
    
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
        return {"success": False, "error": str(e)}
```

---

### Step 5: Add Input Node (30 seconds)

1. Find **"Text Input"** in the left panel
2. Drag it onto the canvas
3. Click on it
4. Set the **value** to the tenant UUID you copied in Step 1
5. Connect the Text Input node to the Python Function node's `tenant_id` parameter (drag from one to the other)

---

### Step 6: Run! (10 seconds)

1. Click the **"Run"** or **"Play"** button
2. Wait for execution (5-10 seconds)
3. Check the output

---

## ✅ Expected Output

If everything works, you should see:

```json
{
  "success": true,
  "batch_id": "some-uuid-here",
  "suggestions_received": 1,
  "suggestions_stored": 1,
  "notifications_sent": {
    "email": true
  }
}
```

---

## 🎉 Success! What Just Happened?

1. **Langflow ran your Python code** with the tenant ID
2. **Built a suggestion** with SEO optimization recommendations
3. **Sent it to your backend API** at `https://api.engarde.media`
4. **Backend stored it** in the `walker_agent_suggestions` table
5. **Email was sent** to the tenant user with the suggestion

---

## 🔍 Verify It Worked

### Check Database

```bash
railway run --service Main -- python3 -c "
import os, psycopg2
conn = psycopg2.connect(os.getenv('DATABASE_PUBLIC_URL'))
cur = conn.cursor()
cur.execute('SELECT id, title, created_at FROM walker_agent_suggestions ORDER BY created_at DESC LIMIT 1')
print(cur.fetchone())
"
```

You should see your suggestion!

### Check Email

The tenant user should receive an email from "Walker Agents" with the SEO suggestion.

---

## 🚀 What's Next?

### Try Other Agents

Open `LANGFLOW_PYTHON_SNIPPETS_FOR_AGENTS.md` and try:
- **Paid Ads Walker Agent** - Campaign optimization
- **Content Walker Agent** - Content gap analysis
- **Audience Intelligence Walker Agent** - Audience segmentation

### Set Up Scheduling

1. In Langflow, look for **"Cron Schedule"** or **"Scheduler"** node
2. Set it to run daily at 9 AM
3. Connect: Cron → Text Input → Python Function

### Add AI

Want dynamic suggestions? Add OpenAI:
1. Set `OPENAI_API_KEY` in Railway
2. Add **"OpenAI"** node before Python Function
3. Generate suggestions with AI!

---

## 🆘 Troubleshooting

### "Python Function node not found"

Try searching for:
- "Custom Python"
- "Code"
- "Python Code"

### "httpx module not found"

Replace `httpx` with `requests`:

```python
import requests

response = requests.post(endpoint, json=payload, headers=headers, timeout=30)
```

### "success: false" in output

Check the error message in the output. Common issues:
- Invalid tenant_id (use a real UUID from your database)
- API key not set (verify in Railway variables)
- Backend not accessible (check `https://api.engarde.media/health`)

---

## 📚 Full Documentation

- **Python Snippets**: `LANGFLOW_PYTHON_SNIPPETS_FOR_AGENTS.md`
- **Deployment Guide**: `WALKER_AGENTS_LANGFLOW_DEPLOYMENT_GUIDE.md`
- **Environment Variables**: `LANGFLOW_ENVIRONMENT_VARIABLES_GUIDE.md`
- **Architecture**: `WALKER_AGENTS_ARCHITECTURE_RATIONALE.md`

---

**Time to complete**: 5-10 minutes
**Difficulty**: Easy
**Next step**: Build the other 3 Walker Agents!
