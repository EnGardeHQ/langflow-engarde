# Walker Agents - Final Setup with Python Snippets

**Status**: Langflow reverted to Docker image ✅
**Approach**: Use Python Function nodes with copy-paste code

---

## ✅ Ready to Use

All code is in: `LANGFLOW_PYTHON_SNIPPETS_FOR_AGENTS.md`

- 4 Walker Agents (SEO, Paid Ads, Content, Audience Intelligence)
- 6 EnGarde Agents (Campaign, Analytics, Approval, Launcher, Notifications, Monitoring)

---

## 🚀 Quick Start (5 Minutes)

### 1. Get a Tenant ID

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

### 2. Open Langflow

Go to: https://langflow.engarde.media

### 3. Create First Flow

1. Click **"New Flow"**
2. Find **"Python Function"** or **"Code"** node in left panel
3. Drag onto canvas
4. Open `LANGFLOW_PYTHON_SNIPPETS_FOR_AGENTS.md`
5. Copy the SEO Walker Agent code (lines 26-91)
6. Paste into Python Function node
7. Add **"Text Input"** node
8. Set value to tenant UUID
9. Connect Text Input → Python Function (tenant_id parameter)
10. Click **"Run"**

### 4. Verify Success

Check output for:
```json
{
  "success": true,
  "batch_id": "...",
  "suggestions_received": 1,
  "suggestions_stored": 1
}
```

---

## 📋 All Available Agents

### Walker Agents
1. **SEO Walker** - Lines 26-91 in snippets file
2. **Paid Ads Walker** - Lines 99-164
3. **Content Walker** - Lines 172-236
4. **Audience Intelligence Walker** - Lines 244-311

### EnGarde Agents
5. **Campaign Creation** - Lines 323-385
6. **Analytics Report** - Lines 393-452
7. **Content Approval** - Lines 460-515
8. **Campaign Launcher** - Lines 523-578
9. **Notifications** - Lines 586-643
10. **Performance Monitoring** - Lines 651-714

---

## 🔧 Environment Variables (Already Set)

All required variables are configured in Railway:

```
✅ ENGARDE_API_URL = https://api.engarde.media
✅ WALKER_AGENT_API_KEY_ONSIDE_SEO
✅ WALKER_AGENT_API_KEY_ONSIDE_CONTENT
✅ WALKER_AGENT_API_KEY_SANKORE_PAID_ADS
✅ WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE
```

No additional configuration needed!

---

## 💡 Tips

### Save Flows for Reuse

After creating a flow:
1. Click **"Save"** button
2. Name it (e.g., "SEO Walker Agent")
3. Reuse in other flows

### Schedule Daily Runs

1. Add **"Cron Schedule"** or **"Scheduler"** node
2. Set schedule: `0 9 * * *` (daily at 9 AM)
3. Connect: Cron → Text Input → Python Function

### Test All Agents

Create one flow per agent type to test:
- SEO suggestions
- Paid ads optimization
- Content gap analysis
- Audience segmentation

---

## 🎯 Next Steps

1. ✅ Test SEO Walker Agent (5 min)
2. Build Paid Ads Walker Agent flow (5 min)
3. Build Content Walker Agent flow (5 min)
4. Build Audience Intelligence Walker Agent flow (5 min)
5. Set up cron schedules for daily runs
6. Monitor database for suggestions
7. Check email notifications

---

## 📚 Documentation

- **Python Snippets**: `LANGFLOW_PYTHON_SNIPPETS_FOR_AGENTS.md`
- **Quick Start**: `WALKER_AGENTS_QUICK_START.md`
- **Architecture**: `WALKER_AGENTS_ARCHITECTURE_RATIONALE.md`
- **Environment Variables**: `LANGFLOW_ENVIRONMENT_VARIABLES_GUIDE.md`

---

## Summary

**Langflow**: ✅ Running on Docker image
**Components**: ✅ 10 Python snippets ready
**Environment**: ✅ All variables configured
**Status**: ✅ Ready to build flows

**Time to first working agent**: 5 minutes

---

**Last Updated**: December 28, 2025
**Next**: Open Langflow and build first flow
