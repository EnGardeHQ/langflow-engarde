# Walker Agents Langflow Deployment Guide

**Problem**: Custom components in `production-backend` can't be accessed by `langflow-server` (separate Railway service)

**Solution**: Choose one of the three deployment methods below

---

## 🎯 Recommended Approach: Python Function Nodes (Immediate)

**Best for**: Getting started quickly, testing, and simple flows

### Why This Works

- ✅ **No deployment needed** - Just copy/paste code
- ✅ **Works immediately** - No file system access required
- ✅ **Easy to update** - Just edit the code in the UI
- ✅ **All agents available** - 10 ready-to-use snippets

### Steps

1. **Open the snippets file**: `LANGFLOW_PYTHON_SNIPPETS_FOR_AGENTS.md`

2. **Open Langflow**: https://langflow.engarde.media

3. **Create a new flow** in Langflow

4. **Add a Python Function node**:
   - Look for "Python Function", "Custom Python", or "Code" in the components panel
   - Drag it onto the canvas

5. **Copy/paste an agent**:
   - Choose any agent from the snippets file (e.g., SEO Walker Agent)
   - Copy the entire code block
   - Paste into the Python Function node

6. **Add an Input node** (for tenant_id):
   - Drag a "Text Input" node
   - Connect it to the Python Function node's `tenant_id` parameter

7. **Run the flow**!

### Available Agents

**Walker Agents**:
- SEO Walker Agent
- Paid Ads Walker Agent
- Content Walker Agent
- Audience Intelligence Walker Agent

**EnGarde Agents**:
- Campaign Creation Agent
- Analytics Report Agent
- Content Approval Workflow Agent
- Scheduled Campaign Launcher
- Multi-Channel Notification Agent
- Performance Monitoring Agent

---

## 🔧 Advanced Approach: Custom Components (Better UX)

**Best for**: Production use, reusable flows, cleaner UI

This requires adding the custom components files to the Langflow service itself.

### Option A: Add to Langflow GitHub Source (Recommended)

If your Langflow service is deployed from a GitHub repository:

1. **Clone your Langflow repo** (or fork official Langflow):
   ```bash
   git clone YOUR_LANGFLOW_REPO_URL
   cd langflow
   ```

2. **Copy Walker Agent components**:
   ```bash
   # From EnGardeHQ directory
   cp -r production-backend/langflow/custom_components/walker_agents \
     YOUR_LANGFLOW_REPO/src/backend/base/langflow/components/
   ```

3. **Commit and push**:
   ```bash
   git add .
   git commit -m "Add Walker Agent custom components"
   git push
   ```

4. **Redeploy in Railway**:
   - Railway will auto-deploy from your updated repo
   - Components will be available after restart

### Option B: Use Railway Dockerfile

If Langflow is deployed via Dockerfile:

1. **Create a custom Dockerfile** that extends Langflow:
   ```dockerfile
   FROM langflowai/langflow:latest

   # Copy custom components
   COPY production-backend/langflow/custom_components/walker_agents \
     /app/langflow/components/walker_agents/

   # Set environment variable
   ENV LANGFLOW_COMPONENTS_PATH=/app/langflow/components
   ```

2. **Deploy custom Dockerfile in Railway**:
   - Update Railway service to use this Dockerfile
   - Redeploy

### Option C: Railway Volume Mount

If Railway supports volume mounting for your plan:

1. **Create persistent volume** in Railway dashboard:
   - Service: langflow-server
   - Mount path: `/app/custom_components`

2. **Upload components to volume**:
   ```bash
   # You'll need direct access to the volume
   # This may require using Railway shell or FTP
   ```

3. **Set environment variable**:
   ```bash
   railway variables --set "LANGFLOW_COMPONENTS_PATH=/app/custom_components" \
     --service langflow-server
   ```

4. **Restart Langflow**:
   ```bash
   railway restart --service langflow-server
   ```

---

## 🚫 Why Current Setup Doesn't Work

The issue you encountered:

```bash
LANGFLOW_COMPONENTS_PATH="/app/production-backend/langflow/custom_components"
```

**Problem**: This path points to the `production-backend` service files, which are NOT accessible to `langflow-server` service.

**Why**: Each Railway service has its own isolated filesystem. Files in `production-backend` (Main service) cannot be read by `langflow-server` service.

**Fix**: Components must be:
1. IN the langflow-server service filesystem, OR
2. Pasted as Python code (Python Function nodes), OR
3. Mounted via shared volume

---

## 📊 Comparison: Which Approach to Use?

| Approach | Ease | Maintenance | UX | Best For |
|----------|------|-------------|----|----|
| **Python Function Nodes** | ⭐⭐⭐⭐⭐ Easy | ⭐⭐⭐ Medium | ⭐⭐⭐ Good | Testing, quick start |
| **Custom Components** | ⭐⭐ Complex | ⭐⭐⭐⭐⭐ Easy | ⭐⭐⭐⭐⭐ Excellent | Production, reusability |
| **Volume Mount** | ⭐ Very Complex | ⭐⭐ Hard | ⭐⭐⭐⭐ Very Good | Special requirements |

---

## 🎯 My Recommendation

**Start with Python Function Nodes** (Option 1), then migrate to Custom Components (Option 2A) once you've tested the flows and confirmed they work.

### Phase 1: Testing (This Week)
- Use Python Function nodes with snippets from `LANGFLOW_PYTHON_SNIPPETS_FOR_AGENTS.md`
- Build and test all 4 Walker Agent flows
- Verify API integration works
- Check email notifications
- Monitor database

### Phase 2: Production (Next Week)
- Fork Langflow or use your Langflow repo
- Add custom components to the fork
- Deploy fork to Railway
- Rebuild flows using drag-and-drop components
- Set up cron schedules

---

## 📝 Quick Start (Right Now)

Try this immediately to test if Langflow works:

1. Open: https://langflow.engarde.media
2. Create new flow
3. Add "Python Function" node
4. Paste this test code:

```python
import httpx
import os
from datetime import datetime

def run(tenant_id: str) -> dict:
    """Test Walker Agent Connection"""

    api_url = os.getenv("ENGARDE_API_URL", "https://api.engarde.media")
    api_key = os.getenv("WALKER_AGENT_API_KEY_ONSIDE_SEO")

    return {
        "success": True,
        "tenant_id": tenant_id,
        "api_url": api_url,
        "api_key_set": bool(api_key),
        "timestamp": datetime.utcnow().isoformat()
    }
```

5. Add "Text Input" node, set value to a tenant UUID
6. Connect Input → Python Function
7. Run!

**Expected output**:
```json
{
  "success": true,
  "tenant_id": "your-uuid-here",
  "api_url": "https://api.engarde.media",
  "api_key_set": true,
  "timestamp": "2025-12-28T21:30:00.000000"
}
```

If this works, you can proceed with the full agents from `LANGFLOW_PYTHON_SNIPPETS_FOR_AGENTS.md`!

---

## 🆘 Troubleshooting

### "Python Function node not found"

Try these node names:
- "Python Function"
- "Custom Python"
- "Code"
- "Python Code"

### "Environment variables not accessible"

Check if Langflow can access env vars:

```python
def run() -> dict:
    import os
    return {
        "all_vars": list(os.environ.keys())
    }
```

If `ENGARDE_API_URL` is in the list, you're good!

### "httpx module not found"

Langflow may not have `httpx` installed. Try `requests` instead:

```python
import requests  # instead of httpx

response = requests.post(endpoint, json=payload, headers=headers, timeout=30)
```

---

## 📚 Sources

- [Create custom Python components | Langflow Documentation](https://docs.langflow.org/components-custom-components)
- [Components overview | Langflow Documentation](https://docs.langflow.org/concepts-components)
- [Building Custom Components in Langflow 🛠️](https://alain-airom.medium.com/building-custom-components-in-langflow-️-def27d0c913a)

---

**Created**: December 28, 2025
**Status**: Ready to deploy
**Recommended**: Start with Python Function nodes (immediate) → Migrate to custom components (production)
