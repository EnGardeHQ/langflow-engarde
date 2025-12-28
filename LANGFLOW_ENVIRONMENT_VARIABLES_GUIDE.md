# Langflow Environment Variables - Complete Guide

**Date**: December 28, 2025
**Status**: ✅ Core variables already set | ⚠️ Optional additions recommended

---

## Current Status

### ✅ Already Configured (Verified)

These variables are **already set** in your Railway Langflow service:

| Variable | Value | Purpose |
|----------|-------|---------|
| `ENGARDE_API_URL` | `https://api.engarde.media` | Backend API endpoint |
| `WALKER_AGENT_API_KEY_ONSIDE_SEO` | `wa_onside_production_...` | SEO Walker authentication |
| `WALKER_AGENT_API_KEY_ONSIDE_CONTENT` | `wa_onside_production_...` | Content Walker authentication |
| `WALKER_AGENT_API_KEY_SANKORE_PAID_ADS` | `wa_sankore_production_...` | Paid Ads Walker authentication |
| `WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE` | `wa_madansara_production_...` | Audience Intel Walker authentication |

**Status**: ✅ **READY TO BUILD FLOWS** - All required variables are set!

---

## Recommended Additional Variables

While the core Walker Agent variables are set, here are additional variables that will make your flows more powerful and flexible:

### 1. AI Provider API Keys 🤖

If you want to use AI/LLM nodes in your flows for dynamic suggestion generation:

```bash
# OpenAI (for GPT-4, GPT-3.5-turbo)
railway variables set OPENAI_API_KEY="sk-..."

# Anthropic (for Claude models)
railway variables set ANTHROPIC_API_KEY="sk-ant-..."

# Google (for Gemini/PaLM)
railway variables set GOOGLE_API_KEY="..."

# Cohere (for embeddings, reranking)
railway variables set COHERE_API_KEY="..."
```

**Why needed?**
- Generate dynamic, AI-powered suggestions instead of templates
- Analyze campaign data with LLMs
- Create personalized recommendation content

**Cost impact**: ~$2-5 per 1,000 suggestions (GPT-4 Turbo)

### 2. Database Access (Optional) 💾

If you want Langflow to query your database directly (for advanced flows):

```bash
# Already set for Langflow's own DB, but you might want production-backend DB
railway variables set PRODUCTION_DATABASE_URL="postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"
```

**Why needed?**
- Fetch real campaign data for analysis
- Query historical performance metrics
- Get tenant information dynamically

**Security note**: Use read-only credentials if possible!

### 3. Tenant Configuration 🏢

Default tenant IDs for testing and development:

```bash
# Default tenant IDs (get from database)
railway variables set DEFAULT_TENANT_ONSIDE="uuid-for-onside"
railway variables set DEFAULT_TENANT_SANKORE="uuid-for-sankore"
railway variables set DEFAULT_TENANT_MADANSARA="uuid-for-madansara"
```

**Why needed?**
- Quick testing without manual tenant ID input
- Scheduled flows can use default tenants
- Easier flow development

**How to get tenant IDs**:
```sql
psql "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway" \
  -c "SELECT id, name FROM tenants;"
```

### 4. Analytics & Monitoring 📊

For tracking and debugging:

```bash
# Langflow logging level (already set)
railway variables set LANGFLOW_LOG_LEVEL="DEBUG"  # Change from INFO for more details

# Sentry for error tracking (optional)
railway variables set SENTRY_DSN="https://...@sentry.io/..."

# Custom monitoring
railway variables set MONITORING_WEBHOOK_URL="https://your-monitoring-service.com/webhook"
```

**Why needed?**
- More detailed logs for troubleshooting
- Error tracking and alerts
- Performance monitoring

### 5. Scheduling Configuration ⏰

Timezone and scheduling settings:

```bash
# Timezone for cron schedules
railway variables set TZ="UTC"

# Or use your local timezone
railway variables set TZ="America/New_York"

# Enable/disable auto-scheduling
railway variables set ENABLE_AUTO_SCHEDULING="true"
```

**Why needed?**
- Ensure cron jobs run at expected times
- Consistency across deployments
- Daylight saving time handling

### 6. Rate Limiting & Retry Configuration 🔄

Control API behavior:

```bash
# HTTP request timeouts (seconds)
railway variables set HTTP_TIMEOUT="60"

# Max retries for failed API calls
railway variables set MAX_RETRIES="3"

# Retry delay (seconds)
railway variables set RETRY_DELAY="5"

# Rate limit per minute (for AI APIs)
railway variables set RATE_LIMIT_PER_MINUTE="60"
```

**Why needed?**
- Prevent timeout errors on slow operations
- Handle transient API failures gracefully
- Avoid hitting rate limits

### 7. Feature Flags 🚩

Enable/disable experimental features:

```bash
# Enable advanced analytics
railway variables set FEATURE_ADVANCED_ANALYTICS="true"

# Enable A/B testing framework
railway variables set FEATURE_AB_TESTING="true"

# Enable custom component loading
railway variables set FEATURE_CUSTOM_COMPONENTS="true"
```

**Why needed?**
- Test new features without affecting production
- Gradual rollout of changes
- Easy rollback if issues occur

---

## Recommended Setup Commands

### Minimal Setup (Just AI Provider)

If you want to add AI-powered dynamic suggestions:

```bash
# Most common: Add OpenAI for GPT-4
railway variables set OPENAI_API_KEY="sk-proj-your-key-here"

# Restart Langflow
railway restart --service langflow-server
```

### Recommended Setup (AI + Monitoring)

For production-ready configuration:

```bash
# AI Provider
railway variables set OPENAI_API_KEY="sk-proj-..."

# Tenant defaults for easy testing
railway variables set DEFAULT_TENANT_ONSIDE="tenant-uuid-1"
railway variables set DEFAULT_TENANT_SANKORE="tenant-uuid-2"
railway variables set DEFAULT_TENANT_MADANSARA="tenant-uuid-3"

# Better logging
railway variables set LANGFLOW_LOG_LEVEL="DEBUG"

# Timezone
railway variables set TZ="UTC"

# Restart Langflow
railway restart --service langflow-server
```

### Full Setup (Everything)

For maximum flexibility and control:

```bash
# AI Providers
railway variables set OPENAI_API_KEY="sk-proj-..."
railway variables set ANTHROPIC_API_KEY="sk-ant-..."

# Database access
railway variables set PRODUCTION_DATABASE_URL="postgresql://..."

# Tenant defaults
railway variables set DEFAULT_TENANT_ONSIDE="..."
railway variables set DEFAULT_TENANT_SANKORE="..."
railway variables set DEFAULT_TENANT_MADANSARA="..."

# Monitoring
railway variables set LANGFLOW_LOG_LEVEL="DEBUG"
railway variables set SENTRY_DSN="https://...@sentry.io/..."

# Scheduling
railway variables set TZ="UTC"

# Rate limiting
railway variables set HTTP_TIMEOUT="60"
railway variables set MAX_RETRIES="3"
railway variables set RETRY_DELAY="5"

# Restart Langflow
railway restart --service langflow-server
```

---

## How to Use These Variables in Langflow Flows

### Example 1: Using OpenAI API Key

When you add an **OpenAI** node in Langflow:

1. Drag **OpenAI** component onto canvas
2. In the configuration panel:
   - **API Key**: `${OPENAI_API_KEY}` ← Uses environment variable
   - **Model**: `gpt-4-turbo`
   - **Temperature**: `0.3`

Langflow automatically substitutes `${OPENAI_API_KEY}` with the actual key!

### Example 2: Using Tenant Default

In an **Input** node:

1. Add **Text Input** component
2. Configure:
   - **Name**: `Tenant ID`
   - **Default Value**: `${DEFAULT_TENANT_ONSIDE}` ← Uses env variable
   - **Is Required**: `false` (uses default if not provided)

### Example 3: Using Custom Timeout

In an **HTTP Request** node:

1. Add **HTTP Request** component
2. Configure:
   - **URL**: `${ENGARDE_API_URL}/api/v1/walker-agents/suggestions`
   - **Timeout**: `${HTTP_TIMEOUT}` ← Uses env variable (60 seconds)
   - **Max Retries**: `${MAX_RETRIES}` ← Uses env variable (3 retries)

---

## Global Variables in Langflow UI

Langflow may also have **Global Variables** settings in the UI:

### How to Access (if available)

1. Open Langflow: https://langflow.engarde.media
2. Click **Settings** or **⚙️** icon (top right)
3. Look for **Global Variables** or **Environment** section
4. Add variables here as an alternative to Railway

### When to Use UI vs Railway

| Scenario | Use Railway | Use Langflow UI |
|----------|-------------|-----------------|
| **Production secrets** (API keys) | ✅ Yes | ❌ No |
| **Deployment-wide settings** | ✅ Yes | ❌ No |
| **Flow-specific constants** | ❌ No | ✅ Yes |
| **Testing/development values** | ❌ No | ✅ Yes |

**Best Practice**: Keep secrets in Railway, use Langflow UI for non-sensitive flow parameters.

---

## Priority Recommendations

### Must Have (Do This First) 🔴

```bash
# Add OpenAI for dynamic suggestions
railway variables set OPENAI_API_KEY="sk-proj-..."

# Restart
railway restart --service langflow-server
```

**Why**: Enables AI-powered suggestion generation instead of static templates.

### Should Have (Do This Soon) 🟡

```bash
# Add tenant defaults for easier testing
railway variables set DEFAULT_TENANT_ONSIDE="uuid-from-db"
railway variables set DEFAULT_TENANT_SANKORE="uuid-from-db"
railway variables set DEFAULT_TENANT_MADANSARA="uuid-from-db"

# Better logging for debugging
railway variables set LANGFLOW_LOG_LEVEL="DEBUG"

# Restart
railway restart --service langflow-server
```

**Why**: Makes testing flows much easier and provides better debugging.

### Nice to Have (Optional) 🟢

```bash
# Additional AI providers for flexibility
railway variables set ANTHROPIC_API_KEY="sk-ant-..."

# Error tracking
railway variables set SENTRY_DSN="https://...@sentry.io/..."

# Custom rate limiting
railway variables set HTTP_TIMEOUT="90"
railway variables set MAX_RETRIES="5"
```

**Why**: Adds flexibility and better monitoring, but not required initially.

---

## Verification

After adding variables, verify they're accessible in Langflow:

### Method 1: Railway CLI

```bash
# Check all variables are set
railway variables --service langflow-server | grep -E "OPENAI|WALKER|ENGARDE|TENANT"
```

### Method 2: Test in Langflow Flow

1. Create a new flow
2. Add **Python Function** node
3. Add this code:
```python
import os

def test_env_vars():
    return {
        "engarde_api": os.getenv("ENGARDE_API_URL"),
        "openai_key": "Set" if os.getenv("OPENAI_API_KEY") else "Not set",
        "walker_seo": "Set" if os.getenv("WALKER_AGENT_API_KEY_ONSIDE_SEO") else "Not set"
    }
```
4. Run the flow
5. Check output - should show all variables are "Set"

---

## Troubleshooting

### Variables Not Found in Langflow

**Problem**: Flow fails with "Environment variable not found"

**Solutions**:

1. **Verify variable is set in Railway**:
   ```bash
   railway variables --service langflow-server | grep VARIABLE_NAME
   ```

2. **Check spelling** (case-sensitive!):
   - Correct: `${OPENAI_API_KEY}`
   - Wrong: `${openai_api_key}` ❌
   - Wrong: `${OPENAI_API_KEY }` ❌ (extra space)

3. **Restart Langflow** after adding variables:
   ```bash
   railway restart --service langflow-server
   # Wait 60 seconds for full restart
   ```

4. **Check variable syntax in flow**:
   - Correct: `${VARIABLE_NAME}`
   - Wrong: `$VARIABLE_NAME` ❌ (missing braces)
   - Wrong: `{VARIABLE_NAME}` ❌ (missing $)

### Variables Work in Railway but Not Langflow

**Problem**: Railway shows variable, but Langflow can't access it

**Cause**: Langflow may have a separate environment configuration

**Solution**:

1. Check if Langflow has internal env file:
   ```bash
   railway run --service langflow-server env | grep VARIABLE_NAME
   ```

2. Try setting in Langflow UI (Settings → Global Variables)

3. Check Langflow version compatibility

---

## Security Best Practices

### ✅ DO

- Store API keys in Railway environment variables
- Use `${VAR_NAME}` syntax in flows (never hardcode)
- Rotate API keys periodically
- Use read-only database credentials when possible
- Enable Railway's secret scanning

### ❌ DON'T

- Hardcode API keys in flows
- Commit `.env` files to git
- Share API keys in screenshots or documentation
- Use production keys in development flows
- Store keys in Langflow UI (use Railway instead)

---

## Summary

### Current Status ✅

You're **ready to start building flows** with these already configured:
- `ENGARDE_API_URL`
- All 4 Walker Agent API keys

### Recommended Next Step 🎯

Add OpenAI API key for dynamic AI-powered suggestions:

```bash
railway variables set OPENAI_API_KEY="sk-proj-your-key-here"
railway restart --service langflow-server
```

Then you can build flows that:
- ✅ Send suggestions to backend (already possible)
- ✅ Generate dynamic AI content (with OpenAI key)
- ✅ Analyze campaign data intelligently
- ✅ Create personalized recommendations

### Optional Enhancements 🚀

After basic flows are working, consider adding:
- Tenant default IDs (easier testing)
- Debug logging (better troubleshooting)
- Additional AI providers (more flexibility)

---

**Last Updated**: December 28, 2025
**Next**: Build your first flow in Langflow!
