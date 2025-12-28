# Eventbrite Credentials Update

## IMPORTANT CORRECTION

Eventbrite requires **THREE separate credentials** (not Client ID/OAuth flow as initially documented):

### Required Credentials:

1. **API Key**
2. **Client Secret** (also called "OAuth Secret")
3. **Private Token**

### How to Obtain:

#### Step 1: Access Eventbrite Apps
Visit: https://www.eventbrite.com/account-settings/apps

#### Step 2: Create or Select Your App
- Click "Create New App" or select existing app
- Fill in:
  - App Name: "En Garde - {Your Brand Name}"
  - Application URL: Your website
  - OAuth Redirect URI: `https://api.engarde.media/api/platform-integrations/oauth/callback`

#### Step 3: Get API Key
- In your app details page
- Find "API Key" section
- Copy and save securely

#### Step 4: Get Client Secret
- In same app details page
- Find "Client Secret" or "OAuth Secret"
- **IMPORTANT:** Shown only once - save immediately!

#### Step 5: Create Private Token
- Go to https://www.eventbrite.com/account-settings/apps
- Click "Create Private Token"
- Name it: "En Garde Integration"
- **IMPORTANT:** Copy immediately - shown only once!

### Storage:

All three credentials are stored **per tenant** in the database:
```
platform_connections.auth_data = {
  "api_key": "your_api_key",
  "client_secret": "your_client_secret",
  "private_token": "your_private_token"
}
```

### Environment Variables:

**Per-Tenant (Database Storage - Recommended):**
No environment variables needed. Each tenant's credentials stored in their `platform_connections` record.

**Optional Global Defaults (.env):**
```bash
# Eventbrite Credentials (NOT recommended for multi-tenant)
EVENTBRITE_API_KEY=your_api_key
EVENTBRITE_CLIENT_SECRET=your_client_secret
EVENTBRITE_PRIVATE_TOKEN=your_private_token
```

### Frontend Component Updates:

The `EventPlatformSetup` component now has three fields for Eventbrite:
- API Key (password field)
- Client Secret (password field)
- Private Token (password field)

### Backend Connector Updates:

The `EventbriteConnector` class now accepts:
```python
EventbriteConnector(
    api_key="your_api_key",
    client_secret="your_client_secret",
    private_token="your_private_token"
)
```

The Private Token is used for Bearer authentication in API requests.

### Migration:

If you have existing Eventbrite integrations using `oauth_token`:
```python
# Old way (still supported for backward compatibility)
EventbriteConnector(oauth_token="token")

# New way (recommended)
EventbriteConnector(private_token="token", api_key="key", client_secret="secret")
```

---

## Summary

❌ **Incorrect (Previous):**
- Client ID
- OAuth Token

✅ **Correct (Now):**
- API Key
- Client Secret
- Private Token
