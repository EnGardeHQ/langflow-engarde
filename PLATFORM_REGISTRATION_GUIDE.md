# Platform-Level Integration Registration Guide

## Overview: Two-Level Integration Architecture

Event platform integrations (Eventbrite, Zoom) require **TWO levels** of setup:

### Level 1: Platform-Level Registration (ONE TIME)
**Who:** En Garde platform administrator
**What:** Register En Garde as an OAuth application with Eventbrite and Zoom
**Result:** Global credentials that allow En Garde to act as OAuth provider

### Level 2: Tenant-Level Authorization (PER TENANT)
**Who:** Each individual tenant/brand
**What:** Authorize En Garde to access their Eventbrite/Zoom account
**Result:** Per-tenant access tokens stored in database

---

## Level 1: Platform-Level Registration

These steps are done **ONCE** by the En Garde platform administrator.

### Eventbrite Platform Registration

#### Step 1: Create En Garde OAuth App

1. Go to https://www.eventbrite.com/account-settings/apps (using En Garde's Eventbrite account)
2. Click **"Create New App"**
3. Fill in details:
   ```
   App Name: En Garde Platform
   Company: En Garde
   Description: En Garde marketing and event management platform
   Application URL: https://app.engarde.media
   OAuth Redirect URI: https://api.engarde.media/api/platform-integrations/oauth/callback
   ```
4. Click **"Create App"**

#### Step 2: Collect Platform Credentials

From the app details page, collect:

1. **API Key** (also called "Client Key" or "App Key")
   - This identifies En Garde's application
   - Used in OAuth authorization URLs

2. **Client Secret** (also called "OAuth Secret")
   - **IMPORTANT:** Shown only once - save immediately!
   - Used to exchange authorization codes for access tokens
   - Keep this secret secure!

3. **Public Token** (if available)
   - Optional: Used for read-only public operations

#### Step 3: Add to Environment Variables

Add these to `/production-backend/.env`:

```bash
# Eventbrite Platform-Level Credentials (Global)
EVENTBRITE_APP_KEY=your_api_key_from_step_2
EVENTBRITE_CLIENT_SECRET=your_client_secret_from_step_2
EVENTBRITE_OAUTH_REDIRECT_URI=https://api.engarde.media/api/platform-integrations/oauth/callback
```

**These credentials are GLOBAL** - shared across all tenants for OAuth authorization.

---

### Zoom Platform Registration

#### Step 1: Create En Garde Server-to-Server OAuth App

1. Go to https://marketplace.zoom.us/
2. Click **"Develop"** → **"Build App"**
3. Choose **"Server-to-Server OAuth"**
4. Fill in details:
   ```
   App Name: En Garde Platform
   Company Name: En Garde
   Developer Contact: admin@engarde.media
   Description: En Garde marketing and event management platform
   ```
5. Click **"Create"**

#### Step 2: Configure Scopes

Add required scopes:
- ✅ `meeting:read:admin` - Read meeting details
- ✅ `meeting:write:admin` - Create/update meetings
- ✅ `webinar:read:admin` - Read webinar details
- ✅ `webinar:write:admin` - Create/update webinars
- ✅ `user:read:admin` - Read user information
- ✅ `recording:read:admin` - Access recordings (optional)

#### Step 3: Collect Platform Credentials

From the App Credentials page:

1. **Account ID**
   - Your Zoom account identifier
   - Used for Server-to-Server OAuth

2. **Client ID**
   - Identifies En Garde's application
   - Used in OAuth token requests

3. **Client Secret**
   - **IMPORTANT:** Save securely!
   - Used to authenticate token requests

#### Step 4: Activate App

1. Review app information
2. Click **"Activate your app"**
3. App status should show "Activated"

#### Step 5: Add to Environment Variables

**IMPORTANT:** For Zoom, each tenant needs their OWN Zoom app because Server-to-Server OAuth is account-specific.

So there are two approaches:

**Approach A: Per-Tenant Zoom Apps (Recommended)**
Each tenant creates their own Zoom app and provides credentials to En Garde.
```bash
# No global Zoom credentials needed
# Each tenant's credentials stored in database
```

**Approach B: Single Zoom Account for All (Not Recommended)**
Use one Zoom account for all tenants (no multi-tenant support).
```bash
# Global Zoom credentials (single account)
ZOOM_ACCOUNT_ID=your_account_id
ZOOM_CLIENT_ID=your_client_id
ZOOM_CLIENT_SECRET=your_client_secret
```

**Recommendation:** Use Approach A for true multi-tenant support.

---

## Level 2: Tenant-Level Authorization

After platform-level registration, each tenant authorizes En Garde to access their account.

### Eventbrite Tenant Authorization Flow

**For Each Tenant:**

#### Option A: Private Token (Simple but Limited)

1. Tenant visits https://www.eventbrite.com/account-settings/apps
2. Clicks **"Create Private Token"**
3. Names it: "En Garde Integration"
4. Copies token
5. Pastes into En Garde → Integrations → Eventbrite
6. Token stored in database: `platform_connections.auth_data.private_token`

**Pros:** Quick setup
**Cons:** No OAuth, token manually managed, no automatic refresh

#### Option B: OAuth 2.0 Flow (Recommended for Production)

1. **Tenant initiates:** Clicks "Connect Eventbrite" in En Garde platform
2. **En Garde redirects** tenant to Eventbrite authorization URL:
   ```
   https://www.eventbrite.com/oauth/authorize?response_type=code&client_id={EVENTBRITE_APP_KEY}&redirect_uri={REDIRECT_URI}&state={TENANT_ID_ENCRYPTED}
   ```
3. **Tenant authorizes:** Logs into their Eventbrite account and clicks "Authorize"
4. **Eventbrite redirects** back to En Garde with authorization code:
   ```
   https://api.engarde.media/api/platform-integrations/oauth/callback?code={AUTH_CODE}&state={TENANT_ID_ENCRYPTED}
   ```
5. **En Garde exchanges** authorization code for access token:
   ```python
   POST https://www.eventbrite.com/oauth/token
   {
     "grant_type": "authorization_code",
     "client_id": EVENTBRITE_APP_KEY,
     "client_secret": EVENTBRITE_CLIENT_SECRET,
     "code": AUTH_CODE,
     "redirect_uri": REDIRECT_URI
   }
   ```
6. **En Garde stores** access token in database:
   ```python
   platform_connections.auth_data = {
     "access_token": "...",
     "refresh_token": "...",
     "token_type": "bearer",
     "expires_at": "2025-..."
   }
   ```

**Pros:** Proper OAuth, automatic token refresh, secure
**Cons:** More complex setup

---

### Zoom Tenant Authorization

**For Each Tenant:**

#### Step 1: Tenant Creates Zoom App

Each tenant must create their own Zoom Server-to-Server OAuth app:

1. Tenant visits https://marketplace.zoom.us/
2. Creates new **Server-to-Server OAuth** app
3. Adds required scopes (same as platform-level)
4. Activates app
5. Copies Account ID, Client ID, Client Secret

#### Step 2: Tenant Provides Credentials

1. Tenant goes to En Garde → Integrations → Zoom
2. Enters their three credentials:
   - Account ID
   - Client ID
   - Client Secret
3. Clicks "Connect"

#### Step 3: En Garde Stores Credentials

```python
platform_connections.auth_data = {
  "account_id": "tenant_zoom_account_id",
  "client_id": "tenant_zoom_client_id",
  "client_secret": "tenant_zoom_client_secret"
}
```

#### Step 4: En Garde Gets Access Token

When making API calls, En Garde automatically gets access token:
```python
POST https://zoom.us/oauth/token
params: grant_type=account_credentials&account_id={ACCOUNT_ID}
auth: Basic {base64(client_id:client_secret)}
```

---

## Summary: Environment Variables

### Platform-Level (Global - in .env)

```bash
# ============================================
# EVENTBRITE - Platform Registration
# ============================================
# En Garde's Eventbrite OAuth app credentials
EVENTBRITE_APP_KEY=your_eventbrite_api_key
EVENTBRITE_CLIENT_SECRET=your_eventbrite_client_secret
EVENTBRITE_OAUTH_REDIRECT_URI=https://api.engarde.media/api/platform-integrations/oauth/callback

# ============================================
# ZOOM - Platform Registration (OPTIONAL)
# ============================================
# Only if using single shared Zoom account (not recommended for multi-tenant)
# ZOOM_ACCOUNT_ID=shared_account_id
# ZOOM_CLIENT_ID=shared_client_id
# ZOOM_CLIENT_SECRET=shared_client_secret

# ============================================
# POSH.VIP - No Platform Registration Needed
# ============================================
# Posh.VIP uses webhooks only - each tenant configures their own webhook
```

### Tenant-Level (Stored in Database)

```python
# platform_connections table
{
  "tenant_id": "uuid",
  "platform_name": "eventbrite",
  "auth_data": {
    # Option A: Private Token
    "private_token": "tenant_private_token",

    # Option B: OAuth Token
    "access_token": "tenant_oauth_access_token",
    "refresh_token": "tenant_oauth_refresh_token",
    "expires_at": "2025-12-31T23:59:59Z"
  }
}

{
  "tenant_id": "uuid",
  "platform_name": "zoom",
  "auth_data": {
    "account_id": "tenant_zoom_account",
    "client_id": "tenant_zoom_client",
    "client_secret": "tenant_zoom_secret"
  }
}

{
  "tenant_id": "uuid",
  "platform_name": "poshvip",
  "auth_data": {
    "webhook_secret": "tenant_webhook_secret"
  }
}
```

---

## Implementation Checklist

### For En Garde Platform Administrator:

#### Eventbrite:
- [ ] Create En Garde OAuth app at Eventbrite
- [ ] Copy API Key and Client Secret
- [ ] Add to `/production-backend/.env`:
  - `EVENTBRITE_APP_KEY`
  - `EVENTBRITE_CLIENT_SECRET`
  - `EVENTBRITE_OAUTH_REDIRECT_URI`
- [ ] Restart backend service
- [ ] Test OAuth flow with test tenant

#### Zoom:
- [ ] Decide: Per-tenant apps or shared account?
- [ ] If shared: Create Zoom app, add credentials to .env
- [ ] If per-tenant: Document process for tenants
- [ ] Test connection

#### Posh.VIP:
- [ ] No platform registration needed
- [ ] Document webhook setup for tenants

### For Each Tenant:

#### Eventbrite:
- [ ] Choose: Private Token or OAuth?
- [ ] If Private Token: Create token, paste in En Garde
- [ ] If OAuth: Click "Connect" and authorize
- [ ] Test connection (view events)

#### Zoom:
- [ ] Create own Zoom Server-to-Server OAuth app
- [ ] Copy Account ID, Client ID, Client Secret
- [ ] Enter in En Garde → Zoom integration
- [ ] Test connection (list meetings)

#### Posh.VIP:
- [ ] Get unique webhook URL from En Garde
- [ ] Add webhook in Posh.VIP dashboard
- [ ] Copy webhook secret from Posh.VIP
- [ ] Paste in En Garde
- [ ] Test with sample event

---

## Security Best Practices

### Platform-Level Credentials:
- ✅ Store in environment variables (not code)
- ✅ Use different credentials for dev/staging/production
- ✅ Rotate secrets periodically
- ✅ Limit access to production .env file
- ✅ Use secret management service (AWS Secrets Manager, etc.)

### Tenant-Level Tokens:
- ✅ Encrypt at rest in database
- ✅ Never expose in API responses
- ✅ Implement token refresh before expiry
- ✅ Revoke on disconnect
- ✅ Log all token usage with tenant context

### OAuth Security:
- ✅ Use HTTPS for all OAuth redirects
- ✅ Validate state parameter (prevents CSRF)
- ✅ Use short-lived authorization codes
- ✅ Implement PKCE for additional security
- ✅ Log all authorization attempts

---

## Next Steps

1. **Complete Platform-Level Registration:**
   - Register En Garde with Eventbrite
   - Add credentials to production .env
   - Test OAuth flow

2. **Update Backend Code:**
   - Ensure OAuth callback endpoint exists
   - Implement token refresh logic
   - Add per-tenant credential storage

3. **Update Frontend:**
   - Add "Connect with OAuth" buttons
   - Implement OAuth redirect flow
   - Show connection status

4. **Documentation:**
   - Create tenant onboarding guides
   - Document troubleshooting steps
   - Add video walkthroughs

5. **Testing:**
   - Test with multiple tenants
   - Verify token isolation
   - Test token refresh
   - Test disconnection/reconnection
