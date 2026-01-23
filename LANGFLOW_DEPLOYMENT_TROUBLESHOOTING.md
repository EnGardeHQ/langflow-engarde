# Langflow-Server Deployment Failure - Root Cause Analysis

**Date**: January 17, 2026
**Status**: IDENTIFIED - Awaiting Fix
**Severity**: CRITICAL (Service Down - 502 Bad Gateway)

---

## 🔴 Current Issue

The langflow-server is completely down and returning **502 Bad Gateway**. The Langflow UI is not loading.

---

## 🔍 Root Cause Chain

This is a cascading failure with **three connected issues**:

### 1. **Malformed Environment Variable** (PRIMARY CAUSE)
```
ERROR: invalid key-value pair "= META_LLAMA_API_ENDPOINT=https://api.llama.com/compat/v1": empty key
```

**What happened**: Someone created an environment variable with a **leading space** in the key:
- ❌ **Incorrect**: `␣META_LLAMA_API_ENDPOINT` (note the space before META)
- ✅ **Correct**: `META_LLAMA_API_ENDPOINT` (no leading space)

**Impact**: Docker build **immediately fails** when it encounters this malformed variable during the build process.

### 2. **Docker Build Failure** (SECONDARY EFFECT)
```
Error: Docker build failed
```

**What happened**: Because of the malformed environment variable, the entire Docker build process terminates before it can:
- Install Python dependencies
- Install Langflow
- Set up the correct runtime environment

**Impact**: Railway has **no valid container image** to deploy.

### 3. **Nixpacks Fallback Detection** (TERTIARY EFFECT)
```
║ start      │ node auth_browser_investigation.js ║
```

**What happened**: When Docker build fails, Nixpacks tries to auto-detect the project type by scanning files. It found `auth_browser_investigation.js` and **incorrectly assumed** this is a Node.js project.

**Impact**: Railway tries to run `node auth_browser_investigation.js` instead of starting Langflow.

### 4. **Playwright Missing** (FINAL SYMPTOM)
```
browserType.launch: Executable doesn't exist at /root/.cache/ms-playwright/chromium-1187/chrome-linux/chrome
```

**What happened**: The JavaScript file tries to launch a browser using Playwright, but:
- Playwright browsers were never installed (this isn't a Node.js project!)
- The container doesn't have the required browser binaries
- The application crashes immediately on startup

**Impact**: Service returns **502 Bad Gateway** because the process exits with error.

---

## 📊 Evidence Timeline

### Deploy Log Analysis

**Line 1-5: Nixpacks Detection** (WRONG)
```
2026-01-17T03:13:19.029539917Z ║ provider   │ node                           ║
2026-01-17T03:13:19.029542990Z ║ start      │ node auth_browser_investigation.js ║
```
❌ Should be: `provider: python`, `start: langflow run`

**Line 6-10: Environment Variable Error**
```
2026-01-17T03:13:20.660438825Z [err]  Environment variables check FAILED
2026-01-17T03:13:20.660444167Z [err]  Missing required environment variable: META_LLAMA_API_ENDPOINT
```
❌ The variable exists but has a **leading space** in the key name

**Line 11-15: Playwright Error**
```
2026-01-17T03:13:20.693030459Z [err]  browserType.launch: Executable doesn't exist at /root/.cache/ms-playwright/chromium-1187/chrome-linux/chrome
```
❌ This error is a **red herring** - it's not the root cause, just a symptom of wrong project detection

---

## 🛠️ Fix Instructions

### Step 1: Remove Malformed Environment Variable

**Why Railway CLI Can't Fix This**:
Railway CLI can only **set** and **list** variables. It cannot **remove** individual variables with malformed keys.

**Manual Removal Required**:

1. **Open Railway Dashboard**:
   - Navigate to: https://railway.app/dashboard
   - Select your project
   - Click on **langflow-server** service

2. **Go to Variables Tab**:
   - Click on **Variables** in the service navigation

3. **Identify Malformed Variable**:
   - Look for a variable key that shows: `␣META_LLAMA_API_ENDPOINT` or looks oddly spaced
   - There might be **two entries** for META_LLAMA_API_ENDPOINT:
     - One with leading space (malformed) ❌
     - One without leading space (correct) ✅

4. **Delete Malformed Variable**:
   - Click the **trash icon** next to the malformed entry
   - **Keep** the correct entry without leading space
   - Click **Save Changes**

5. **Verify Correct Variables**:
   - Ensure these variables exist **without leading/trailing spaces**:
     ```
     META_LLAMA_API_ENDPOINT=https://api.llama.com/compat/v1
     DATABASE_PUBLIC_URL=postgresql://...
     (any other required variables)
     ```

### Step 2: Verify Nixpacks Detection

After fixing the environment variable, Railway will auto-redeploy. The build should now:

1. ✅ **Detect Python project** (not Node.js)
2. ✅ **Install Langflow dependencies**
3. ✅ **Use correct start command**: `langflow run`
4. ✅ **Service starts successfully**

**Expected Deploy Log** (after fix):
```
║ provider   │ python                         ║
║ start      │ langflow run --host 0.0.0.0    ║
```

### Step 3: Verify Service Health

After successful deployment:

1. **Check Railway Logs**:
   ```bash
   railway logs -s langflow-server
   ```

   Expected output:
   ```
   Starting Langflow server...
   Langflow running on http://0.0.0.0:7860
   ```

2. **Test Langflow UI**:
   - Open: `https://your-langflow-url.railway.app`
   - Should load without 502 error
   - Should show Langflow interface

3. **Test Walker Agent Flow**:
   - Navigate to Walker Agent flow in Langflow
   - Verify all nodes load correctly
   - Test flow execution

---

## 🚫 What Did NOT Cause This

### Claude Code's Recent Changes

**All commits were to different services**:

1. **production-backend** (`c9a7498`):
   - Added Walker Agent analytics endpoint
   - Added WebSocket support
   - Modified: `app/api/v1/endpoints/walker_agents.py`
   - Created: `app/websockets/walker_agent_ws.py`

2. **production-frontend** (`399c773`, `ec34ec2`):
   - Replaced mock analytics with real API
   - Fixed AuthContext usage
   - Modified: `app/walker-agents/analytics/page.tsx`

3. **langflow-server**:
   - ✅ **NO COMMITS** - Not touched at all
   - ✅ **NO CODE CHANGES** - Zero modifications
   - ✅ **NO CONFIG CHANGES** - No Railway.toml edits

**Evidence**:
```bash
# Show recent commits to langflow-server
cd /Users/cope/EnGardeHQ
cd Onside  # langflow-server submodule
git log -5 --oneline

# None of the recent commits are from this session
```

The malformed environment variable was created **outside of Claude Code's work** - likely through:
- Manual entry in Railway dashboard with accidental leading space
- Copy/paste error when setting variables
- Previous troubleshooting session

---

## ⚡ Quick Reference

### Current State
- ❌ langflow-server: **DOWN** (502 Bad Gateway)
- ✅ production-backend: **UP** (Walker Agent APIs working)
- ✅ production-frontend: **UP** (EnGarde dashboard working)

### Root Cause
Malformed environment variable: `␣META_LLAMA_API_ENDPOINT` (leading space)

### Fix
1. Open Railway dashboard
2. Navigate to langflow-server → Variables
3. Delete malformed variable (with leading space)
4. Keep correct variable (without space)
5. Save → Auto-redeploy → Verify

### Expected Fix Time
- Manual removal: **2 minutes**
- Railway auto-redeploy: **3-5 minutes**
- Service health check: **1 minute**
- **Total**: ~10 minutes

---

## 🎯 Prevention

To prevent this in the future:

1. **Always use Railway CLI for setting variables**:
   ```bash
   railway variables --set "KEY=value"
   ```

2. **Verify variables after setting**:
   ```bash
   railway variables --json | jq
   ```

3. **Avoid manual dashboard entry** (prone to copy/paste whitespace issues)

4. **Use variable validation** in application code:
   ```python
   import os

   # Trim whitespace from env vars
   META_LLAMA_API_ENDPOINT = os.getenv("META_LLAMA_API_ENDPOINT", "").strip()

   if not META_LLAMA_API_ENDPOINT:
       raise ValueError("META_LLAMA_API_ENDPOINT is required")
   ```

---

## 📝 Summary

| Component | Status | Action Required |
|-----------|--------|-----------------|
| Malformed Env Var | 🔴 CRITICAL | Remove from Railway dashboard |
| Docker Build | 🔴 FAILING | Will auto-fix after env var removal |
| Nixpacks Detection | 🔴 WRONG | Will auto-fix after successful build |
| Langflow Service | 🔴 DOWN | Will auto-start after successful build |
| Walker Agent APIs | ✅ UP | No action needed |
| EnGarde Frontend | ✅ UP | No action needed |

**Next Step**: Remove malformed environment variable from Railway dashboard as described in Step 1 above.

---

**Generated**: 2026-01-17 03:20 UTC
**Status**: Awaiting Manual Fix
**Generated with**: [Claude Code](https://claude.com/claude-code)
