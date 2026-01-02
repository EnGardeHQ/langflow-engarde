# Walker Agent Custom Components for Langflow

**Ready-to-use Langflow components for EnGarde Walker Agents**

These custom components provide a plug-and-play solution for building Walker Agent flows in Langflow without writing code in the UI.

---

## 📦 What's Included

### Complete Agent Components (Easiest)

**Just drag, configure tenant ID, and run!**

1. **SEO Walker Agent (Complete)** - Full SEO analysis and suggestion generation
2. **Paid Ads Walker Agent (Complete)** - Campaign optimization suggestions
3. **Content Walker Agent (Complete)** - Content gap analysis
4. **Audience Intelligence Walker Agent (Complete)** - Audience segmentation

### Building Block Components (Advanced)

For custom flows:

5. **Tenant ID Input** - Input component for tenant UUID
6. **Walker Suggestion Builder** - Build custom suggestion objects
7. **Walker Agent API Request** - Send suggestions to backend API

---

## ⚠️ IMPORTANT: Deployment Requirements

**These custom components are in the `production-backend` repository, but Langflow runs as a SEPARATE Railway service.**

❌ **This WILL NOT work**:
```bash
railway variables set LANGFLOW_COMPONENTS_PATH="/app/production-backend/..."
```

**Why**: Railway services have isolated filesystems. Langflow cannot access files from production-backend.

✅ **What WILL work**:
1. **Python Function Nodes** (easiest) - See `LANGFLOW_PYTHON_SNIPPETS_FOR_AGENTS.md`
2. **Add to Langflow repository** (best for production) - See `WALKER_AGENTS_LANGFLOW_DEPLOYMENT_GUIDE.md`
3. **Railway Volume Mount** (advanced) - See deployment guide

**👉 Read `WALKER_AGENTS_LANGFLOW_DEPLOYMENT_GUIDE.md` for complete instructions.**

---

## 🚀 Quick Start (Assuming Components Are Already Deployed)

If you've successfully deployed these components to your Langflow service:

### Step 2: Verify Components Loaded

1. Open Langflow: https://langflow.engarde.media
2. Create a new flow
3. Look in the components panel (left side)
4. You should see a new category: **"Custom"** or **"Walker Agents"**
5. Expand it - you should see all 7 components!

### Step 3: Build Your First Flow (2 Minutes!)

**Using the Complete Component**:

1. Drag **"SEO Walker Agent (Complete)"** onto the canvas
2. Click on the component to configure:
   - **Tenant ID**: Enter a tenant UUID from your database
   - **API URL**: Should already be `${ENGARDE_API_URL}` (uses env variable)
   - **API Key**: Should already be `${WALKER_AGENT_API_KEY_ONSIDE_SEO}` (uses env variable)
3. Click **"Run"** button
4. Check the output - should show `"success": true`!

**That's it!** You've just sent a suggestion to the backend.

---

## 📖 Component Reference

### 1. SEO Walker Agent (Complete)

**Simplest way to build an SEO Walker Agent flow.**

**Inputs**:
- `tenant_id` (required): UUID of tenant to analyze
- `api_url` (auto-filled): Backend API URL
- `api_key` (auto-filled): SEO Walker API key

**Outputs**:
- `result`: JSON response from backend API

**Example Flow**:
```
[SEO Walker Agent (Complete)]
    ↓
[Text Output] (to see the result)
```

**Usage**:
```python
# In Langflow UI:
1. Drag "SEO Walker Agent (Complete)" to canvas
2. Set tenant_id: "123e4567-e89b-12d3-a456-426614174000"
3. Run
4. Output shows:
{
  "success": true,
  "batch_id": "uuid",
  "suggestions_received": 1,
  "suggestions_stored": 1,
  "notifications_sent": {
    "email": true
  }
}
```

### 2. Paid Ads Walker Agent (Complete)

**Same as SEO, but for paid advertising optimization.**

**Uses**: `${WALKER_AGENT_API_KEY_SANKORE_PAID_ADS}`

### 3. Content Walker Agent (Complete)

**Content gap analysis and recommendations.**

**Uses**: `${WALKER_AGENT_API_KEY_ONSIDE_CONTENT}`

### 4. Audience Intelligence Walker Agent (Complete)

**Audience segmentation and targeting suggestions.**

**Uses**: `${WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE}`

---

### 5. Tenant ID Input (Building Block)

**Get tenant ID from user input or default value.**

**Inputs**:
- `tenant_id`: The tenant UUID

**Outputs**:
- `tenant_id`: Tenant UUID as text

**Usage**:
```
[Tenant ID Input] → [SEO Walker Agent API]
```

### 6. Walker Suggestion Builder (Building Block)

**Build a custom suggestion object with your own data.**

**Inputs**:
- `suggestion_type`: Type of suggestion (dropdown)
- `title`: Suggestion title
- `description`: Detailed description
- `estimated_revenue`: Estimated $ impact
- `confidence_score`: 0.0 to 1.0
- `action_description`: What action to take
- `cta_url`: Link for user to take action

**Outputs**:
- `suggestion`: JSON suggestion object

**Usage**:
```
[OpenAI] → [Walker Suggestion Builder] → [Walker Agent API]
    ↑                                           ↑
Generate AI content        →      Send to backend
```

### 7. Walker Agent API Request (Building Block)

**Send suggestions to the backend API.**

**Inputs**:
- `api_url`: Backend URL
- `api_key`: Walker Agent API key
- `agent_type`: seo / content / paid_ads / audience_intelligence
- `tenant_id`: Tenant UUID
- `priority`: high / medium / low
- `suggestions`: JSON array of suggestions
- `timeout`: Request timeout (seconds)
- `max_retries`: Retry attempts

**Outputs**:
- `response`: API response JSON

**Usage**:
```
[Tenant ID Input] → [Walker Agent API] → [Text Output]
        ↓
[Suggestion Builder] →
```

---

## 🏗️ Example Flows

### Flow 1: Simple (Using Complete Components)

**Just runs and sends a template suggestion:**

```
[SEO Walker Agent (Complete)]
         ↓
    [Output]
```

**Steps**:
1. Drag "SEO Walker Agent (Complete)"
2. Enter tenant_id
3. Run
4. Done!

---

### Flow 2: Advanced (AI-Powered Suggestions)

**Uses OpenAI to generate dynamic suggestions:**

```
[Tenant ID Input]
         ↓
    [OpenAI] (prompt: "Analyze SEO for tenant...")
         ↓
[Walker Suggestion Builder] (parse OpenAI output)
         ↓
[Walker Agent API Request]
         ↓
    [Output]
```

**Steps**:
1. Drag "Tenant ID Input" → set tenant UUID
2. Drag "OpenAI" component:
   - Model: gpt-4-turbo
   - Prompt: "Analyze SEO opportunities for this tenant and provide 3 suggestions..."
3. Drag "Walker Suggestion Builder":
   - Connect OpenAI output to title
   - Connect OpenAI output to description
   - Set other fields
4. Drag "Walker Agent API Request":
   - Connect Tenant ID to tenant_id
   - Connect Suggestion Builder to suggestions
   - Set agent_type to "seo"
5. Run!

---

### Flow 3: Multi-Suggestion (Batch Processing)

**Send multiple suggestions at once:**

```
[Tenant ID Input]
         ↓
    [OpenAI] → [Parse JSON]
         ↓
[Walker Agent API] (accepts array)
         ↓
    [Output]
```

**OpenAI Prompt**:
```
Analyze SEO for this tenant and provide 3-5 suggestions in this exact JSON format:

[
  {
    "type": "keyword_opportunity",
    "title": "...",
    "description": "...",
    "estimated_revenue_increase": 5000.0,
    "confidence_score": 0.85,
    "action_description": "..."
  },
  ...
]
```

Then pass the parsed array directly to Walker Agent API component!

---

## 🔧 Customization

### Modify Template Suggestions

Each "Complete" component has a hardcoded template suggestion. To customize:

1. **Option A**: Edit the component code (recommended for developers)
   - Open `walker_agent_components.py`
   - Find the `execute()` method in the component
   - Modify the `suggestion` dictionary
   - Save and restart Langflow

2. **Option B**: Build your own flow
   - Use the building block components
   - Create custom logic for suggestion generation
   - More flexible but more complex

### Add Dynamic Data Fetching

To fetch real campaign data from the database:

```python
# Add to component's execute() method:
import psycopg2

# Connect to database
conn = psycopg2.connect(os.getenv("PRODUCTION_DATABASE_URL"))
cur = conn.cursor()

# Fetch campaign data for tenant
cur.execute("""
    SELECT name, metrics FROM campaigns
    WHERE tenant_id = %s AND status = 'active'
    LIMIT 10
""", (self.tenant_id,))

campaigns = cur.fetchall()

# Use campaigns data to generate suggestions
suggestion_title = f"Optimize {len(campaigns)} active campaigns"
# ... rest of logic
```

### Add AI-Powered Analysis

To use OpenAI for dynamic suggestions:

```python
from openai import OpenAI

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

response = client.chat.completions.create(
    model="gpt-4-turbo",
    messages=[
        {"role": "system", "content": "You are an SEO expert..."},
        {"role": "user", "content": f"Analyze these campaigns: {campaigns_data}"}
    ]
)

suggestion_text = response.choices[0].message.content
```

---

## 🐛 Troubleshooting

### Components Don't Appear in Langflow

**Problem**: Can't see custom components in the UI

**Solutions**:
1. Verify `LANGFLOW_COMPONENTS_PATH` is set:
   ```bash
   railway variables --service langflow-server | grep COMPONENTS_PATH
   ```
2. Restart Langflow:
   ```bash
   railway restart --service langflow-server
   ```
3. Check Langflow logs for component loading errors:
   ```bash
   railway logs --service langflow-server | grep -i "component\|custom"
   ```

### "Module not found: httpx"

**Problem**: Component fails with missing module error

**Solution**: Ensure `httpx` is installed in Langflow environment
```bash
# In Langflow container
pip install httpx
```

Or add to Langflow's `requirements.txt`:
```
httpx>=0.25.0
```

### API Key Not Found

**Problem**: Component fails with "Environment variable not found"

**Solution**: Ensure environment variables are set:
```bash
railway variables set WALKER_AGENT_API_KEY_ONSIDE_SEO="wa_onside_production_..."
railway restart --service langflow-server
```

### "Invalid tenant_id format"

**Problem**: Backend returns 422 validation error

**Solution**: Ensure tenant_id is a valid UUID:
```sql
-- Get valid tenant IDs from database
SELECT id, name FROM tenants;
```

---

## 📝 Testing Your Components

### Test 1: Verify Component Loads

1. Open Langflow
2. Create new flow
3. Search for "Walker" in components panel
4. You should see 7 components

**Expected**: All components visible ✅

### Test 2: Run Simple Flow

1. Drag "SEO Walker Agent (Complete)" to canvas
2. Get a tenant ID from database:
   ```sql
   SELECT id FROM tenants LIMIT 1;
   ```
3. Enter tenant ID in component
4. Click "Run"
5. Check output

**Expected**:
```json
{
  "success": true,
  "batch_id": "...",
  "suggestions_received": 1,
  "suggestions_stored": 1
}
```

### Test 3: Verify Database

```sql
SELECT * FROM walker_agent_suggestions
ORDER BY created_at DESC
LIMIT 1;
```

**Expected**: New suggestion row with your tenant_id ✅

### Test 4: Verify Email

Check tenant user's inbox for email from Walker Agents ✅

---

## 🎯 Next Steps

After installing and testing the components:

1. **Schedule Flows**: Set up cron triggers for daily execution
2. **Add AI**: Integrate OpenAI for dynamic suggestions
3. **Customize**: Modify templates to match your use case
4. **Monitor**: Check database and logs daily
5. **Iterate**: Improve suggestions based on user feedback

---

## 📚 Additional Resources

- **Main Documentation**: `WALKER_AGENTS_BUILD_FLOWS_IN_LANGFLOW.md`
- **Environment Variables**: `LANGFLOW_ENVIRONMENT_VARIABLES_GUIDE.md`
- **Testing Guide**: `WALKER_AGENTS_TESTING_GUIDE.md`
- **Architecture**: `WALKER_AGENTS_ARCHITECTURE_RATIONALE.md`

---

## 🆘 Support

If you encounter issues:

1. Check component logs in Langflow
2. Verify environment variables are set
3. Test API endpoint manually with `curl`
4. Review backend logs: `railway logs --service Main`

---

**Created**: December 28, 2025
**Version**: 1.0.0
**License**: Private - EnGarde Internal Use
