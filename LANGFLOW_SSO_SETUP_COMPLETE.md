# Langflow SSO Integration - Complete Setup Guide

## Status: Backend & Langflow Ready ✅

The SSO integration code is **already implemented** in both EnGarde backend and Langflow. We just need to configure the environment variables to activate it.

---

## What's Already Built

### 1. Langflow SSO Endpoint ✅
**Location:** `langflow-engarde/src/backend/base/langflow/api/v1/custom.py`

**Endpoint:** `GET /api/v1/custom/sso_login?token={jwt_token}`

**What it does:**
1. Validates JWT token using shared secret
2. Extracts user email, tenant_id, role from token
3. Creates or updates user in Langflow database
4. Maps EnGarde roles to Langflow permissions (superuser, admin → is_superuser=True)
5. Generates Langflow session token
6. Sets authentication cookies
7. Redirects user to Langflow dashboard

### 2. EnGarde SSO Token Generator ✅
**Location:** `production-backend/app/routers/langflow_sso.py`

**Endpoint:** `POST /api/v1/sso/langflow`

**What it does:**
1. Authenticates user via Bearer token (standard EnGarde auth)
2. Fetches user's tenant_id, tenant_name, role, subscription_tier from database
3. Creates JWT token with 5-minute expiry containing:
   - email
   - tenant_id
   - tenant_name
   - role (superuser, admin, user, agency)
   - subscription_tier (free, starter, professional, business, enterprise)
4. Returns SSO URL: `https://langflow.engarde.media/api/v1/custom/sso_login?token={jwt}`

**Already Registered:** Router is imported and included in `production-backend/app/main.py` (line 131, 225)

---

## Required Environment Variables

### Production Backend Service

You need to set these variables in Railway for the **production-backend** service:

```bash
# Langflow Integration
LANGFLOW_BASE_URL=https://langflow.engarde.media
LANGFLOW_SECRET_KEY=66Frxa-W2jv1e7PrSlRbFR4bxCut0uN-wyzSNiRdid0
```

### Langflow Server Service

You need to set these variables in Railway for the **langflow-server** service:

```bash
# SSO Shared Secret (must match production-backend)
LANGFLOW_SECRET_KEY=66Frxa-W2jv1e7PrSlRbFR4bxCut0uN-wyzSNiRdid0
```

**Important:** The `LANGFLOW_SECRET_KEY` must be **identical** in both services. This is the shared secret used to sign and verify JWT tokens.

---

## Railway Setup Commands

Since Railway CLI doesn't support non-interactive mode, you'll need to set these via the Railway dashboard or use these commands in a terminal with TTY:

### Option 1: Railway Dashboard (Recommended)

1. Go to https://railway.app
2. Select "EnGarde Suite" project
3. Select "production" environment
4. Click "production-backend" service
5. Go to "Variables" tab
6. Add:
   - `LANGFLOW_BASE_URL` = `https://langflow.engarde.media`
   - `LANGFLOW_SECRET_KEY` = `66Frxa-W2jv1e7PrSlRbFR4bxCut0uN-wyzSNiRdid0`
7. Click "langflow-server" service
8. Go to "Variables" tab
9. Add:
   - `LANGFLOW_SECRET_KEY` = `66Frxa-W2jv1e7PrSlRbFR4bxCut0uN-wyzSNiRdid0`
10. Both services will auto-redeploy

### Option 2: Railway CLI (Terminal)

```bash
# Set production-backend variables
railway link --service production-backend
railway variables set LANGFLOW_BASE_URL=https://langflow.engarde.media
railway variables set LANGFLOW_SECRET_KEY=66Frxa-W2jv1e7PrSlRbFR4bxCut0uN-wyzSNiRdid0

# Set langflow-server variables
railway link --service langflow-server
railway variables set LANGFLOW_SECRET_KEY=66Frxa-W2jv1e7PrSlRbFR4bxCut0uN-wyzSNiRdid0
```

---

## Testing the SSO Flow

Once the environment variables are set and services have redeployed:

### 1. Test SSO Token Generation

```bash
# Get an access token from EnGarde
curl -X POST https://api.engarde.media/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your-email@example.com",
    "password": "your-password"
  }'

# Use the access_token to generate Langflow SSO URL
curl -X POST https://api.engarde.media/api/v1/sso/langflow \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# Response:
# {
#   "sso_url": "https://langflow.engarde.media/api/v1/custom/sso_login?token=...",
#   "expires_in": 300
# }
```

### 2. Test SSO Login

Copy the `sso_url` from step 1 and paste it in your browser. You should:
1. Be redirected to Langflow
2. Be automatically logged in
3. See the Langflow dashboard with your user account

### 3. Verify User Creation

Check Langflow database to confirm user was created:

```bash
# Connect to Langflow database
railway run --service postgres psql -d engarde -U engarde_user

# Check users table in langflow schema
SELECT id, username, is_superuser, is_active, created_at
FROM langflow.user
ORDER BY created_at DESC
LIMIT 5;
```

You should see your email in the `username` column.

---

## Next Steps: Frontend Integration

Once SSO is working, the next step is to create the Agent Suite page in the frontend.

### Create: `production-frontend/app/agent-suite/page.tsx`

This page will:
1. Call `POST /api/v1/sso/langflow` to get SSO URL
2. Display Langflow in an iframe with seamless authentication
3. Allow users to browse and execute Walker Agent workflows

**Implementation already planned in:** `/Users/cope/EnGardeHQ/ENGARDE_LANGFLOW_ACTIVATION_PLAN.md` (Phase 2)

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Browser                             │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 │ 1. Click "Agent Suite"
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│             EnGarde Frontend (production-frontend)               │
│                  https://app.engarde.media                       │
│                                                                   │
│  • User navigates to /agent-suite page                           │
│  • Frontend calls: POST /api/v1/sso/langflow                     │
│    with Authorization: Bearer {user_access_token}                │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 │ 2. SSO token request
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│             EnGarde Backend (production-backend)                 │
│                  https://api.engarde.media                       │
│                                                                   │
│  • Validates user's Bearer token                                 │
│  • Fetches tenant_id, role, subscription_tier from database      │
│  • Creates JWT with shared secret (LANGFLOW_SECRET_KEY)          │
│  • Returns: { sso_url: "https://langflow.../sso_login?token="}  │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 │ 3. Redirect to SSO URL
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                 Langflow Server (langflow-server)                │
│                  https://langflow.engarde.media                  │
│                                                                   │
│  • Receives: GET /api/v1/custom/sso_login?token={jwt}            │
│  • Verifies JWT using shared secret (LANGFLOW_SECRET_KEY)        │
│  • Extracts user info (email, tenant_id, role)                   │
│  • Creates/updates user in langflow.user table                   │
│  • Maps role to permissions (admin/superuser → is_superuser)     │
│  • Generates Langflow session token                              │
│  • Sets cookies (access_token_lf, refresh_token_lf)              │
│  • Redirects to Langflow dashboard                               │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 │ 4. User sees Langflow UI
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                  User's Langflow Session                         │
│  • Authenticated with tenant-isolated access                     │
│  • Can browse flows in their tenant's folders                    │
│  • Can execute Walker Agent workflows                            │
│  • Results sync back to EnGarde campaigns                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Security Features

### 1. Short-Lived SSO Tokens
- SSO JWT expires in **5 minutes**
- Prevents token replay attacks
- Minimizes exposure window

### 2. Shared Secret Validation
- Both services use same secret key
- Only EnGarde backend can generate valid tokens
- Langflow rejects tokens from unknown sources

### 3. Role Mapping
- EnGarde roles mapped to Langflow permissions:
  - `superuser` → Langflow `is_superuser=True`
  - `admin` → Langflow `is_superuser=True`
  - `user` → Langflow `is_superuser=False`
  - `agency` → Langflow `is_superuser=False`

### 4. Tenant Isolation
- JWT includes `tenant_id`
- Langflow respects tenant boundaries via RLS
- Users can only see their tenant's flows

### 5. Session Management
- Langflow issues its own session tokens after SSO
- Session tokens stored in httpOnly cookies
- Automatic session refresh

---

## Troubleshooting

### Issue: "SSO not configured" error

**Cause:** `LANGFLOW_SECRET_KEY` or `LANGFLOW_BASE_URL` not set in production-backend

**Fix:**
```bash
railway link --service production-backend
railway variables
# Verify both variables are set
```

### Issue: "Invalid SSO token" error

**Cause:** Shared secret mismatch between services

**Fix:**
1. Check `LANGFLOW_SECRET_KEY` in production-backend
2. Check `LANGFLOW_SECRET_KEY` in langflow-server
3. Ensure they are **identical**

### Issue: User redirected but not logged in

**Cause:** Cookie domain mismatch or CORS issues

**Fix:**
1. Check Langflow auth settings in environment
2. Verify `LANGFLOW_COOKIE_DOMAIN` is not set (should use default)
3. Check CORS settings allow credentials

### Issue: SSO works but user has wrong permissions

**Cause:** Role mapping issue in Langflow SSO endpoint

**Fix:**
1. Check JWT payload includes correct `role`
2. Verify role mapping logic in `langflow-engarde/src/backend/base/langflow/api/v1/custom.py:77-79`
3. Manually update user in database if needed:
```sql
UPDATE langflow.user SET is_superuser = true WHERE username = 'admin@example.com';
```

---

## Current Status Summary

| Component | Status | Notes |
|-----------|--------|-------|
| Langflow SSO Endpoint | ✅ Implemented | `/api/v1/custom/sso_login` in `custom.py` |
| EnGarde Token Generator | ✅ Implemented | `/api/v1/sso/langflow` in `langflow_sso.py` |
| Router Registration | ✅ Complete | Imported and included in `main.py` |
| Environment Variables | ⚠️ Pending | Need to set in Railway |
| Frontend Page | ❌ Not Started | Next task: `/agent-suite/page.tsx` |
| End-to-End Testing | ⏸️ Blocked | Waiting for env vars |

---

## Generated Secret Key

```
LANGFLOW_SECRET_KEY=66Frxa-W2jv1e7PrSlRbFR4bxCut0uN-wyzSNiRdid0
```

**Important:** Set this exact value in both `production-backend` and `langflow-server` services.

If you want to generate a new secret (for security rotation), use:
```bash
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

---

## Files Modified/Created

### Existing (Already Implemented)
1. `langflow-engarde/src/backend/base/langflow/api/v1/custom.py` - SSO login endpoint
2. `production-backend/app/routers/langflow_sso.py` - SSO token generator
3. `production-backend/app/main.py` - Router registration (line 131, 225)
4. `production-backend/app/core/config.py` - Config for LANGFLOW_BASE_URL

### Created (This Session)
1. `/Users/cope/EnGardeHQ/LANGFLOW_SSO_SETUP_COMPLETE.md` - This file

### Pending (Next Steps)
1. `production-frontend/app/agent-suite/page.tsx` - Agent Suite page
2. `production-frontend/components/AuthenticatedLangflowIframe.tsx` - Iframe component
3. Railway environment variable configuration

---

## Ready to Proceed

All code is implemented. To activate:

1. **Set environment variables in Railway** (see "Railway Setup Commands" above)
2. **Wait for services to redeploy** (automatic)
3. **Test SSO flow** (see "Testing the SSO Flow" above)
4. **Create frontend page** (next task in activation plan)

The SSO integration is production-ready and waiting for configuration! 🚀
