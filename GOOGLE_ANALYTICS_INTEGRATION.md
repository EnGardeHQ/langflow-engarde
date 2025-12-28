# Google Analytics 4 Real-Time Dashboard Integration

## Overview

The admin dashboard now displays **real-time Google Analytics 4 (GA4) data** that isn't tracked in the En Garde database. This provides comprehensive insights into user behavior, traffic sources, and site performance directly from Google Analytics.

## What's Displayed

The integration shows analytics data that Google tracks but En Garde doesn't store:

### Real-Time Metrics
- ✅ **Active Users Right Now** - Live count of users currently on the site
- ✅ **Active Users by Device** - Desktop, mobile, tablet breakdown
- ✅ **Active Users by Location** - Top countries and cities

### Overview Statistics (Configurable Period)
- ✅ **Total Users** - Unique visitors
- ✅ **New Users** - First-time visitors
- ✅ **Sessions** - Total sessions
- ✅ **Average Session Duration** - How long users stay
- ✅ **Bounce Rate** - Percentage of single-page sessions
- ✅ **Pageviews** - Total page views

### Traffic Sources
- ✅ **Source/Medium Breakdown** - Where traffic comes from
  - Organic search (google/organic)
  - Direct traffic (direct/none)
  - Social media (facebook/social, twitter/social)
  - Referrals (external-site/referral)
  - Email campaigns (email/email)
- ✅ **Sessions per Source** - Volume from each source
- ✅ **New Users per Source** - User acquisition by channel

### Top Pages
- ✅ **Most Viewed Pages** - Popular content
- ✅ **Pageviews per Page**
- ✅ **Average Session Duration per Page**
- ✅ **Bounce Rate per Page**

### User Demographics
- ✅ **Top Countries** - Geographic distribution
- ✅ **Device Breakdown** - Desktop vs Mobile vs Tablet
- ✅ **Browser Usage** - Chrome, Safari, Firefox, etc.

### Auto-Refresh
- ✅ Updates automatically every 60 seconds
- ✅ Real-time badge showing last update time
- ✅ Configurable time period (24h, 7d, 30d, 90d)

---

## Setup Instructions

### Prerequisites
1. Google Analytics 4 (GA4) property set up for your website
2. Google Cloud Platform (GCP) account
3. Admin access to Google Analytics

### Step 1: Create Google Cloud Project

1. Go to https://console.cloud.google.com/
2. Click **"Create Project"** or select existing project
3. Name: "En Garde Analytics"
4. Click **"Create"**

### Step 2: Enable Google Analytics Data API

1. In Google Cloud Console, go to **"APIs & Services"** → **"Library"**
2. Search for **"Google Analytics Data API"**
3. Click on it
4. Click **"Enable"**
5. Wait 1-2 minutes for API to be fully enabled

### Step 3: Create Service Account

1. Go to **"APIs & Services"** → **"Credentials"**
2. Click **"Create Credentials"** → **"Service Account"**
3. Fill in:
   - **Service account name:** `en-garde-analytics`
   - **Service account ID:** (auto-generated)
   - **Description:** `Service account for En Garde Google Analytics access`
4. Click **"Create and Continue"**
5. **Grant this service account access to project** (optional - skip)
6. Click **"Done"**

### Step 4: Generate Service Account Key (JSON)

1. Click on the created service account (`en-garde-analytics@...`)
2. Go to **"Keys"** tab
3. Click **"Add Key"** → **"Create new key"**
4. Select **"JSON"** format
5. Click **"Create"**
6. **Save the downloaded JSON file** securely (e.g., `en-garde-ga4-key.json`)

**⚠️ Security Warning:**
- Never commit this JSON file to version control
- Store it securely (use secrets manager in production)
- This key has access to your analytics data

### Step 5: Grant Service Account Access to Google Analytics

1. Copy the service account email from the JSON file:
   ```json
   "client_email": "en-garde-analytics@your-project.iam.gserviceaccount.com"
   ```

2. Go to https://analytics.google.com/
3. Navigate to **Admin** (⚙️ icon in bottom left)
4. In the **Property** column, click **"Property Access Management"**
5. Click **"+"** (Add users) → **"Add users"**
6. Enter the service account email
7. Select role: **"Viewer"** (read-only access)
8. Uncheck **"Notify new users by email"**
9. Click **"Add"**

**Wait 5-10 minutes** for permissions to propagate.

### Step 6: Get Your GA4 Property ID

1. In Google Analytics, go to **Admin** → **Property Settings**
2. Find **"Property ID"** at the top
3. Copy the numeric ID (e.g., `123456789`)

**Note:** This is different from the Measurement ID (G-XXXXXXXXXX)

### Step 7: Configure En Garde Backend

Add environment variables to `/production-backend/.env`:

**Option A: Using JSON File Path (Development)**

```bash
# Google Analytics 4
GA4_PROPERTY_ID=123456789
GA4_SERVICE_ACCOUNT_PATH=/path/to/en-garde-ga4-key.json
```

**Option B: Using JSON String (Production - Recommended)**

```bash
# Google Analytics 4
GA4_PROPERTY_ID=123456789
GA4_SERVICE_ACCOUNT_JSON='{"type":"service_account","project_id":"your-project","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"en-garde-analytics@your-project.iam.gserviceaccount.com","client_id":"...","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"..."}'
```

**To convert JSON file to string:**
```bash
cat en-garde-ga4-key.json | jq -c '.'
```

### Step 8: Install Python Dependencies

```bash
cd production-backend
pip install google-analytics-data google-auth
```

Or add to `requirements.txt`:
```
google-analytics-data>=0.17.0
google-auth>=2.23.0
```

### Step 9: Restart Backend

```bash
cd production-backend
# If using uvicorn
uvicorn app.main:app --reload

# If using Docker
docker-compose restart backend
```

### Step 10: Test the Integration

**Test API Endpoint:**
```bash
curl -X GET http://localhost:8000/api/admin/analytics/realtime \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

**Expected Response:**
```json
{
  "status": "success",
  "data": {
    "status": "success",
    "total_active_users": 5,
    "by_country": [
      ["United States", 3],
      ["United Kingdom", 2]
    ],
    "by_device": {
      "desktop": 3,
      "mobile": 2
    },
    "timestamp": "2025-01-20T10:30:00.000Z"
  }
}
```

**Test in Admin Dashboard:**
1. Log in as admin
2. Navigate to `/admin`
3. Scroll down to **"Google Analytics (Real-Time)"** section
4. Should see live data with green "Live" badge

---

## Files Created

### Backend

**Service:**
- `/production-backend/app/services/analytics/google_analytics_service.py`
  - GoogleAnalyticsService class
  - Methods for fetching realtime, overview, traffic, demographics
  - GA4 Data API integration

**Router:**
- `/production-backend/app/routers/admin_analytics.py`
  - Admin-only endpoints
  - `/api/admin/analytics/realtime` - Live active users
  - `/api/admin/analytics/overview` - Overview stats
  - `/api/admin/analytics/traffic-sources` - Traffic breakdown
  - `/api/admin/analytics/top-pages` - Page performance
  - `/api/admin/analytics/demographics` - User demographics
  - `/api/admin/analytics/dashboard` - All data combined

### Frontend

**Component:**
- `/production-frontend/components/admin/GoogleAnalyticsWidget.tsx`
  - Real-time display widget
  - Auto-refreshing every 60 seconds
  - Tabbed interface for different metrics
  - Period selector (24h, 7d, 30d, 90d)

**Integration:**
- `/production-frontend/app/admin/page.tsx`
  - Added GoogleAnalyticsWidget to admin dashboard
  - Displays after Recent Activity section

---

## API Endpoints

All endpoints require admin authentication.

### GET /api/admin/analytics/realtime

Get real-time active users.

**Response:**
```json
{
  "status": "success",
  "data": {
    "total_active_users": 12,
    "by_country": [["US", 8], ["UK", 4]],
    "by_device": {"desktop": 7, "mobile": 5},
    "by_city": [["New York, US", 3], ["London, UK", 2]],
    "timestamp": "2025-01-20T10:30:00Z"
  }
}
```

### GET /api/admin/analytics/overview?days=30

Get overview statistics.

**Query Parameters:**
- `days` (int, 1-365): Period to analyze (default: 30)

**Response:**
```json
{
  "status": "success",
  "data": {
    "period_days": 30,
    "total_users": 1250,
    "new_users": 780,
    "sessions": 3400,
    "avg_session_duration": 145.5,
    "bounce_rate": 42.3,
    "pageviews": 8900
  }
}
```

### GET /api/admin/analytics/traffic-sources?days=7

Get traffic source breakdown.

**Response:**
```json
{
  "status": "success",
  "data": {
    "total_sessions": 3400,
    "sources": [
      {
        "source": "google",
        "medium": "organic",
        "sessions": 1200,
        "users": 900,
        "new_users": 500
      },
      {
        "source": "(direct)",
        "medium": "(none)",
        "sessions": 800,
        "users": 600,
        "new_users": 200
      }
    ]
  }
}
```

### GET /api/admin/analytics/top-pages?days=7

Get top performing pages.

**Response:**
```json
{
  "status": "success",
  "data": {
    "total_pageviews": 8900,
    "pages": [
      {
        "path": "/",
        "title": "Home Page",
        "pageviews": 2500,
        "avg_session_duration": 180.5,
        "bounce_rate": 35.2
      }
    ]
  }
}
```

### GET /api/admin/analytics/demographics?days=30

Get user demographics.

**Response:**
```json
{
  "status": "success",
  "data": {
    "top_countries": [
      {
        "country": "United States",
        "users": 800,
        "sessions": 2000
      }
    ],
    "devices": [
      {
        "device": "desktop",
        "users": 700,
        "sessions": 1800
      },
      {
        "device": "mobile",
        "users": 500,
        "sessions": 1500
      }
    ],
    "browsers": [
      {
        "browser": "Chrome",
        "users": 600,
        "sessions": 1500
      }
    ]
  }
}
```

### GET /api/admin/analytics/dashboard?days=7

Get all dashboard data in one call.

**Response:** Combined data from all endpoints above.

---

## Security Best Practices

### Production Deployment

1. **Use Secrets Manager:**
   ```bash
   # AWS Secrets Manager
   GA4_SERVICE_ACCOUNT_JSON=$(aws secretsmanager get-secret-value \
     --secret-id en-garde/ga4-credentials \
     --query SecretString \
     --output text)
   ```

2. **Rotate Service Account Keys:**
   - Create new key every 90 days
   - Delete old keys after rotation
   - Update environment variables

3. **Least Privilege:**
   - Service account has only "Viewer" role
   - Cannot modify analytics data
   - Read-only access

4. **Environment Separation:**
   - Different service accounts for dev/staging/prod
   - Different GA4 properties for each environment

5. **Access Control:**
   - Analytics endpoints require admin authentication
   - Only admins can view GA data
   - No tenant-level access to analytics

### Never Do This

❌ Commit service account JSON to git
❌ Share service account keys via email/slack
❌ Grant "Editor" or "Admin" role to service account
❌ Use same service account across environments
❌ Store keys in plain text files

---

## Troubleshooting

### Error: "Google Analytics service not configured"

**Cause:** Missing environment variables

**Solution:**
1. Verify `GA4_PROPERTY_ID` is set
2. Verify `GA4_SERVICE_ACCOUNT_JSON` or `GA4_SERVICE_ACCOUNT_PATH` is set
3. Restart backend after adding env vars

### Error: "Permission denied" / 403 Forbidden

**Cause:** Service account doesn't have access to GA4 property

**Solution:**
1. Verify service account email in Google Analytics Property Access Management
2. Ensure role is "Viewer" or higher
3. Wait 5-10 minutes for permissions to propagate
4. Check you're using correct GA4 property ID

### Error: "Property not found" / 404

**Cause:** Invalid GA4 property ID

**Solution:**
1. Verify property ID is numeric only (e.g., `123456789`)
2. Don't include "properties/" prefix
3. Don't use Measurement ID (G-XXXXXXXXXX)
4. Ensure using GA4 property, not Universal Analytics

### Error: "API not enabled"

**Cause:** Google Analytics Data API not enabled in Google Cloud

**Solution:**
1. Go to Google Cloud Console → APIs & Services → Library
2. Search "Google Analytics Data API"
3. Click "Enable"
4. Wait 1-2 minutes

### Widget Shows "Failed to load Google Analytics data"

**Cause:** Backend error or API call failed

**Solution:**
1. Check backend logs for detailed error
2. Test API endpoint directly:
   ```bash
   curl http://localhost:8000/api/admin/analytics/realtime -H "Authorization: Bearer TOKEN"
   ```
3. Verify backend is running
4. Check browser console for errors

### Real-Time Shows 0 Users (But There Are Visitors)

**Cause:** GA4 real-time data can have slight delay

**Solution:**
1. Wait 1-2 minutes for data to appear
2. Verify GA4 is tracking properly (check in Google Analytics)
3. Check GA4 data stream is active
4. Verify gtag.js or GA4 SDK is installed on website

---

## Dashboard Display

### Admin Dashboard View

The Google Analytics widget appears in the admin dashboard (`/admin`) below the Recent Activity section.

**Features:**
- **Live Badge:** Shows "Live • Updated [time]" with green badge
- **Period Selector:** Dropdown to choose 24h, 7d, 30d, or 90d
- **Real-Time Card:**
  - Large green number showing current active users
  - Breakdown by device (desktop, mobile, tablet)
  - Top 5 locations
- **Overview Stats Grid:**
  - Total Users (with new users badge)
  - Sessions (with avg duration)
  - Pageviews (with bounce rate)
- **Tabbed Details:**
  - **Traffic Sources:** Source/medium breakdown table
  - **Top Pages:** Page performance with metrics
  - **Demographics:** Countries and devices with progress bars

### Auto-Refresh

- Automatically refreshes every 60 seconds
- Shows timestamp of last update
- Can be toggled off if needed

---

## Environment Variables Summary

```bash
# Required
GA4_PROPERTY_ID=123456789

# Choose one:
GA4_SERVICE_ACCOUNT_PATH=/path/to/service-account-key.json
# OR
GA4_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
```

---

## Benefits

### Data Not Tracked in En Garde
- ✅ Real-time active users
- ✅ Geographic distribution
- ✅ Device/browser breakdown
- ✅ Traffic source attribution
- ✅ Page-level performance
- ✅ Bounce rates
- ✅ Session durations

### Why This Matters
- **No Database Impact:** Data comes directly from Google, no storage needed
- **Real-Time Insights:** See who's on site right now
- **Traffic Attribution:** Understand where users come from
- **Performance Tracking:** Monitor page performance and engagement
- **User Behavior:** Analyze how users interact with the site
- **Comprehensive View:** Combine En Garde app data with Google Analytics web data

---

## Next Steps

1. ✅ Set up Google Cloud project and service account
2. ✅ Grant service account access to GA4 property
3. ✅ Configure environment variables
4. ✅ Install dependencies and restart backend
5. ✅ Test API endpoints
6. ✅ View real-time data in admin dashboard
7. ✅ Monitor and analyze user behavior

## Success! 🎉

The admin dashboard now displays comprehensive Google Analytics data that complements the En Garde application data. You can see real-time user activity, traffic sources, popular pages, and user demographics - all without storing any of it in your database!
