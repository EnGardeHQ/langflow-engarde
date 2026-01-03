# Final Answers and Instructions - Langflow Agent Deployment

**Complete answers to all questions + deployment guide**

---

## ✅ Your Questions Answered

### Question 1: Production Microservice URLs

**Issue:** Files reference `localhost` instead of production endpoints

**Answer:**

The production microservice URLs are:

```bash
# Production URLs (use these)
ONSIDE_API_URL=https://onside-production.up.railway.app
SANKORE_API_URL=https://sankore-production.up.railway.app
MADANSARA_API_URL=https://madansara-production.up.railway.app

# Local development URLs (only if running locally)
ONSIDE_API_URL=http://localhost:8000
SANKORE_API_URL=http://localhost:8001
MADANSARA_API_URL=http://localhost:8002
```

**What to do:**

When you set environment variables in Railway, use the production URLs:

```bash
railway variables --service langflow-server --set ONSIDE_API_URL=https://onside-production.up.railway.app
railway variables --service langflow-server --set SANKORE_API_URL=https://sankore-production.up.railway.app
railway variables --service langflow-server --set MADANSARA_API_URL=https://madansara-production.up.railway.app
```

The agent code uses `os.getenv("ONSIDE_API_URL", "default")` so it will automatically use whatever you set in Railway environment variables.

---

### Question 2: Where to Paste Code in Python Function Modal

**The Python Function Modal shows this template:**

```python
from langflow.custom import Component
from langflow.custom.utils import get_function
from langflow.io import CodeInput, Output
from langflow.schema import Data, dotdict
from langflow.schema.message import Message


class PythonFunctionComponent(Component):
    display_name = "Python Function"
    description = "Define and execute a Python function..."

    inputs = [
        CodeInput(
            name="function_code",          # ← PASTE HERE!
            display_name="Function Code",
            info="The code for the function.",
        ),
    ]

    # ... rest of the class
```

**✅ CORRECT - What to Paste:**

Look for the field labeled **"Function Code"** in the Langflow UI.

Paste **ONLY** the function definition:

```python
def run(tenant_id: str) -> dict:
    """
    SEO Walker Agent
    """
    import os
    import httpx
    # ... rest of function ...
    return {
        "success": True,
        # ...
    }
```

**❌ INCORRECT - Do NOT Paste:**

- Do NOT paste the entire `PythonFunctionComponent` class
- Do NOT paste the imports at the top (`from langflow.custom import Component`)
- Do NOT paste markdown code blocks (```python)
- Do NOT paste anything except the `def run(...)` function

---

### Question 3: Visual Guide - Where to Paste

```
┌──────────────────────────────────────────────────────────────┐
│ Langflow UI - Python Function Node                           │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Node Name: [Python Function                            ]    │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Function Code                                        │    │
│  │ ┌───────────────────────────────────────────────┐   │    │
│  │ │ def run(tenant_id: str) -> dict:              │   │    │
│  │ │     """                                       │   │    │
│  │ │     SEO Walker Agent                          │   │    │
│  │ │     """                                       │   │    │
│  │ │     import os                                 │   │    │
│  │ │     import httpx                              │   │    │
│  │ │     import json                               │ ← PASTE│
│  │ │     from datetime import datetime             │   HERE │
│  │ │     from google.cloud import bigquery         │   │    │
│  │ │                                               │   │    │
│  │ │     # Configuration                           │   │    │
│  │ │     onside_url = os.getenv("ONSIDE_API_URL")  │   │    │
│  │ │                                               │   │    │
│  │ │     # ... rest of your code ...               │   │    │
│  │ │                                               │   │    │
│  │ │     return {                                  │   │    │
│  │ │         "success": True,                      │   │    │
│  │ │         # ...                                 │   │    │
│  │ │     }                                         │   │    │
│  │ └───────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                               │
│  [Check & Save]                                               │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

### Question 4: Removing DataStax/Langflow Logo

**The logo appears in the lower-left corner of the Langflow UI.**

#### Option 1: Browser Console (Quick, Temporary)

1. Press `F12` to open Developer Tools
2. Go to "Console" tab
3. Paste this code:

```javascript
// Hide DataStax logo
const style = document.createElement('style');
style.textContent = `
  .langflow-logo,
  [class*="langflow-logo"],
  [class*="datastax"],
  footer img,
  footer svg,
  footer a[href*="datastax"],
  footer a[href*="langflow"] {
    display: none !important;
  }
`;
document.head.appendChild(style);
```

4. Press Enter
5. Logo disappears (until you refresh the page)

---

#### Option 2: Browser Extension (Persistent)

**Install Stylus Extension:**

1. **Chrome:** https://chrome.google.com/webstore/detail/stylus/clngdbkpkpeebahjckkjfobafhncgmne
2. **Firefox:** https://addons.mozilla.org/en-US/firefox/addon/styl-us/

**Add Custom Style:**

1. Install Stylus extension
2. Click Stylus icon → "Write style for: langflow.engarde.media"
3. Paste this CSS:

```css
/* Hide DataStax/Langflow logo */
.langflow-logo,
[class*="langflow-logo"],
[class*="datastax"],
footer img,
footer svg,
footer a[href*="datastax"],
footer a[href*="langflow"],
footer {
  display: none !important;
}
```

4. Save
5. Logo will be hidden every time you visit Langflow

---

#### Option 3: Custom Docker Image (Permanent, All Users)

**Build custom Langflow image:**

1. **Clone Langflow:**

```bash
git clone https://github.com/logspace-ai/langflow.git
cd langflow
```

2. **Find and edit footer component:**

```bash
# Find footer files
find src/frontend -name "*Footer*" -o -name "*Logo*" | grep -E "\.(tsx|jsx)$"

# Example: Edit footer
nano src/frontend/src/components/Footer/index.tsx
```

3. **Comment out logo:**

```tsx
// Before:
<a href="https://datastax.com">
  <img src={logo} alt="DataStax" />
</a>

// After:
{/* Logo removed for EnGarde branding */}
```

4. **Build and deploy:**

```bash
# Build frontend
cd src/frontend
npm install
npm run build

# Build Docker image
cd ../..
docker build -t langflow-engarde:latest .

# Tag for Railway
docker tag langflow-engarde:latest registry.railway.app/your-project/langflow-server:latest

# Push to Railway
docker push registry.railway.app/your-project/langflow-server:latest

# Redeploy in Railway dashboard
```

---

## 📋 Complete Deployment Checklist

### 1. Set Environment Variables in Railway

```bash
# Check current variables
railway variables --service langflow-server

# Set production microservice URLs
railway variables --service langflow-server --set ONSIDE_API_URL=https://onside-production.up.railway.app
railway variables --service langflow-server --set SANKORE_API_URL=https://sankore-production.up.railway.app
railway variables --service langflow-server --set MADANSARA_API_URL=https://madansara-production.up.railway.app

# Verify
railway variables --service langflow-server | grep "ONSIDE\|SANKORE\|MADANSARA"
```

**Expected output:**
```
ONSIDE_API_URL=https://onside-production.up.railway.app
SANKORE_API_URL=https://sankore-production.up.railway.app
MADANSARA_API_URL=https://madansara-production.up.railway.app
```

---

### 2. Deploy Each Agent to Langflow

**For each agent (1-10):**

#### Step 1: Open Langflow
Navigate to https://langflow.engarde.media

#### Step 2: Create New Flow
Click "New Flow" → Name it (e.g., "SEO Walker Agent")

#### Step 3: Add Text Input Node
1. Search for "Text Input"
2. Drag to canvas
3. Configure:
   - Name: `tenant_id`
   - Value: Leave empty or paste test UUID

#### Step 4: Add Python Function Node
1. Search for "Python Function"
2. Drag to canvas
3. Click on node to open editor

#### Step 5: Copy Agent Code
- **Walker Agents (1-4):** Open `FINAL_WALKER_AGENTS_COMPLETE.md`
- **EnGarde Agents (5-10):** Open `FINAL_ENGARDE_AGENTS_COMPLETE.md`

Find the agent section, copy **ONLY** the `def run(...)` function

#### Step 6: Paste Code
1. Click "Function Code" field in Langflow
2. Select all existing text (Cmd+A / Ctrl+A)
3. Paste your copied function (Cmd+V / Ctrl+V)

#### Step 7: Connect Nodes
Drag from Text Input output → Python Function `tenant_id` input

#### Step 8: Test
1. Set `tenant_id` to real UUID (from your `tenants` table)
2. Click "Run" button
3. Check output shows `"success": true`

#### Step 9: Save
Click "Save" in top toolbar

#### Step 10: Repeat
Repeat for all 10 agents

---

### 3. Verify Deployment

**Check Walker Suggestions in Database:**

```bash
railway run --service Main -- python3 -c "
import os, psycopg2
conn = psycopg2.connect(os.getenv('DATABASE_PUBLIC_URL'))
cur = conn.cursor()
cur.execute('''
    SELECT agent_type, COUNT(*), MAX(created_at)
    FROM walker_agent_suggestions
    WHERE created_at >= NOW() - INTERVAL '1 hour'
    GROUP BY agent_type
''')
print('Recent Walker Suggestions:')
for row in cur.fetchall():
    print(f'  {row[0]}: {row[1]} suggestions (latest: {row[2]})')
"
```

**Check EnGarde Operations:**

```bash
railway run --service Main -- python3 -c "
import os, psycopg2
conn = psycopg2.connect(os.getenv('DATABASE_PUBLIC_URL'))
cur = conn.cursor()

# Campaigns
cur.execute('SELECT COUNT(*) FROM campaigns WHERE created_at >= NOW() - INTERVAL \'1 hour\'')
print(f'New campaigns: {cur.fetchone()[0]}')

# Reports
cur.execute('SELECT COUNT(*) FROM analytics_reports WHERE generated_at >= NOW() - INTERVAL \'1 hour\'')
print(f'New reports: {cur.fetchone()[0]}')
"
```

---

## 📁 Updated File Structure

```
/Users/cope/EnGardeHQ/
│
├── README_LANGFLOW_AGENTS.md ⭐ START HERE
├── LANGFLOW_AGENTS_INDEX.md ⭐ Navigation
├── QUICK_DEPLOYMENT_CARD.md ⭐ 30-min guide
├── DEPLOYMENT_READY_SUMMARY.md ⭐ Complete reference
├── ARCHITECTURE_VISUAL_SUMMARY.md ⭐ Architecture
│
├── FINAL_WALKER_AGENTS_COMPLETE.md ⭐ Agents 1-4 code
├── FINAL_ENGARDE_AGENTS_COMPLETE.md ⭐ Agents 5-10 code
├── FINAL_COMPLETE_MASTER_GUIDE.md ⭐ Environment reference
│
├── LANGFLOW_COPY_PASTE_GUIDE.md ⭐ Copy-paste instructions (NEW)
├── PRODUCTION_ENVIRONMENT_VARIABLES.md ⭐ Production URLs (NEW)
├── FINAL_ANSWERS_AND_INSTRUCTIONS.md ⭐ This file (NEW)
│
└── COMPLETION_SUMMARY.md ⭐ Project summary
```

---

## 🎯 Quick Start (Right Now)

### 5-Minute Setup

**1. Set environment variables:**
```bash
railway variables --service langflow-server --set ONSIDE_API_URL=https://onside-production.up.railway.app
railway variables --service langflow-server --set SANKORE_API_URL=https://sankore-production.up.railway.app
railway variables --service langflow-server --set MADANSARA_API_URL=https://madansara-production.up.railway.app
```

**2. Open Langflow:**
```
https://langflow.engarde.media
```

**3. Create first agent (SEO Walker):**
- New Flow → Name: "SEO Walker"
- Add Text Input (name: `tenant_id`)
- Add Python Function
- Open `FINAL_WALKER_AGENTS_COMPLETE.md`
- Copy Agent 1 code (from `def run...` to final `}`)
- Paste into "Function Code" field
- Connect Text Input → Python Function
- Test with real tenant_id
- Save

**4. Verify:**
```bash
railway run --service Main -- python3 -c "
import os, psycopg2
conn = psycopg2.connect(os.getenv('DATABASE_PUBLIC_URL'))
cur = conn.cursor()
cur.execute('SELECT COUNT(*) FROM walker_agent_suggestions WHERE agent_type = \\'seo\\' AND created_at >= NOW() - INTERVAL \\'10 minutes\\'')
print(f'New SEO suggestions: {cur.fetchone()[0]}')
"
```

**5. Repeat for agents 2-10**

---

## ✅ Final Checklist

Before going live:

- [ ] All 16 environment variables set in Railway (check `PRODUCTION_ENVIRONMENT_VARIABLES.md`)
- [ ] Production microservice URLs configured (https://*, not http://localhost)
- [ ] All 10 agents deployed to Langflow
- [ ] Each agent tested with real tenant_id
- [ ] Database verification shows data being stored
- [ ] Langflow logo removed (optional, use browser extension method)
- [ ] Cron schedules configured for automated runs
- [ ] Monitoring set up (Railway logs)

---

## 🚀 You're Ready!

**What you have:**
- ✅ 10 production-ready agents
- ✅ Complete documentation (11 files)
- ✅ Production URLs configured
- ✅ Copy-paste instructions
- ✅ Logo removal guide

**What to do next:**
1. Set production URLs in Railway
2. Deploy agents to Langflow (3 min each = 30 min total)
3. Test and verify
4. Schedule automated runs
5. Monitor and enjoy! 🎉

---

**Questions? All answers are in the documentation files!**

**Start with:** `README_LANGFLOW_AGENTS.md` → `LANGFLOW_COPY_PASTE_GUIDE.md` → Deploy!
