# Railway Environment Variables Configuration for SignUp_Sync Funnel Scheduler

**Created:** January 22, 2026
**Service:** Main (production-backend)
**Purpose:** Configure the funnel sync scheduler to automatically sync leads from EasyAppointments and other sources

---

## Current Status

### Already Configured ✅

These environment variables are **already set** in the "Main" service on Railway:

```bash
SIGNUP_SYNC_SERVICE_URL=https://signup-sync-service-production.up.railway.app
SIGNUP_SYNC_SERVICE_TOKEN=a2a278b63efe89893977f1a1ac7b8cb79ce653efea4b6d13d39d655d0bf7a79c
```

The SignUp_Sync microservice is deployed and accessible at:
- **Internal URL:** `signup-sync-service.railway.internal`
- **Public URL:** `https://signup-sync-service-production.up.railway.app`

### Missing Variables ⚠️

These environment variables need to be set to enable the funnel sync scheduler:

| Variable | Required Value | Purpose |
|----------|---------------|---------|
| `FUNNEL_SYNC_ENABLED` | `true` | Enable the automatic funnel sync scheduler |
| `FUNNEL_SYNC_CRON` | `30 18 * * *` | Schedule sync at 6:30 PM UTC daily (configurable) |

### Optional Platform User Variables (Not Required for Scheduler)

These variables are for the platform user feature and are **optional**:

```bash
PLATFORM_USER_EMAIL=admin@engarde.platform
PLATFORM_TENANT_ID=00000000-0000-0000-0000-000000000002
```

---

## How to Set Environment Variables in Railway

### Option 1: Using Railway CLI (Recommended)

From your terminal in the `/Users/cope/EnGardeHQ/production-backend` directory:

```bash
# Link to the Main service (if not already linked)
cd /Users/cope/EnGardeHQ/production-backend
railway link

# Set the environment variables
railway variables set FUNNEL_SYNC_ENABLED=true
railway variables set FUNNEL_SYNC_CRON="30 18 * * *"
```

### Option 2: Using Railway Dashboard

1. Go to https://railway.app
2. Select the "EnGarde Suite" project
3. Select the "Main" service
4. Click on "Variables" tab
5. Click "New Variable"
6. Add each variable:
   - Name: `FUNNEL_SYNC_ENABLED`, Value: `true`
   - Name: `FUNNEL_SYNC_CRON`, Value: `30 18 * * *`
7. Click "Deploy" to apply the changes

---

## Environment Variable Explanations

### FUNNEL_SYNC_ENABLED
- **Type:** Boolean (string)
- **Default:** `true`
- **Description:** Master switch to enable/disable the funnel sync scheduler
- **Values:**
  - `true` - Scheduler runs and syncs on schedule
  - `false` - Scheduler is disabled, no automatic syncs

### FUNNEL_SYNC_CRON
- **Type:** Cron expression (string)
- **Default:** `30 18 * * *`
- **Description:** Cron schedule for when to sync funnel data
- **Format:** `minute hour day month weekday`
- **Examples:**
  - `30 18 * * *` - Daily at 6:30 PM UTC
  - `0 2 * * *` - Daily at 2:00 AM UTC
  - `0 */6 * * *` - Every 6 hours
  - `0 0 * * 0` - Weekly on Sunday at midnight

**Cron Expression Reference:**
```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (Sunday to Saturday)
│ │ │ │ │
* * * * *
```

### SIGNUP_SYNC_SERVICE_URL (Already Set ✅)
- **Current Value:** `https://signup-sync-service-production.up.railway.app`
- **Description:** URL of the SignUp_Sync microservice
- **Note:** Uses Railway's internal domain for faster communication

### SIGNUP_SYNC_SERVICE_TOKEN (Already Set ✅)
- **Current Value:** `a2a278b63efe89893977f1a1ac7b8cb79ce653efea4b6d13d39d655d0bf7a79c`
- **Description:** Bearer token for authenticating with the SignUp_Sync service
- **Security:** Should be a secure random token (64+ characters)

---

## Scheduler Implementation Details

The funnel sync scheduler is **already implemented** in the production backend:

### Code Location
- **Service:** `/Users/cope/EnGardeHQ/production-backend/app/services/funnel_sync_scheduler.py`
- **Integration:** `/Users/cope/EnGardeHQ/production-backend/app/main.py` (lines 82-87, 94-99)

### How It Works

1. **Startup:** The scheduler starts automatically when the backend service boots up
2. **Schedule:** Uses APScheduler with a cron trigger (configurable via `FUNNEL_SYNC_CRON`)
3. **Execution:** At the scheduled time, it calls the SignUp_Sync microservice
4. **Endpoint:** Makes a POST request to `/sync/easyappointments` endpoint
5. **Authentication:** Uses the `SIGNUP_SYNC_SERVICE_TOKEN` for authorization
6. **Logging:** All sync operations are logged with detailed results

### What Gets Synced

The scheduler syncs the following data from EasyAppointments:

- **Appointments** → **Funnel Events** (type: `appointment_booked`)
- **Customer Info** → **Lead Data** (email, name, phone)
- **Service Details** → **Event Metadata** (service type, date/time)
- **Status Updates** → **Conversion Tracking** (completed, cancelled, no-show)

---

## Deployment & Verification Steps

### Step 1: Set Environment Variables

Use either the Railway CLI or Dashboard (see above) to set:
```bash
FUNNEL_SYNC_ENABLED=true
FUNNEL_SYNC_CRON="30 18 * * *"
```

### Step 2: Redeploy the Service

After setting the variables, Railway will automatically redeploy. If not:

```bash
# Using Railway CLI
railway up

# Or trigger redeploy from Railway Dashboard
# Service → Settings → Click "Redeploy"
```

### Step 3: Verify Scheduler Started

Check the deployment logs for the startup message:

```bash
# View logs using Railway CLI
railway logs --service Main

# Look for these log messages:
# ✅ Funnel sync scheduler started
# Funnel sync scheduler started. EasyAppointments sync scheduled with cron: 30 18 * * *
```

**Expected Log Output:**
```
2026-01-22 12:00:00 - app.main - INFO - 🚀 Application startup...
2026-01-22 12:00:00 - app.main - INFO - ✅ Application marked as ready
2026-01-22 12:00:00 - app.services.funnel_sync_scheduler - INFO - ✅ Funnel sync scheduler started
2026-01-22 12:00:00 - app.services.funnel_sync_scheduler - INFO - Funnel sync scheduler started. EasyAppointments sync scheduled with cron: 30 18 * * *
```

### Step 4: Test Manual Sync (Optional)

You can manually trigger a sync to verify everything works before waiting for the scheduled time:

```bash
# Trigger a manual sync via the SignUp_Sync service directly
curl -X POST https://signup-sync-service-production.up.railway.app/sync/easyappointments \
  -H "Authorization: Bearer a2a278b63efe89893977f1a1ac7b8cb79ce653efea4b6d13d39d655d0bf7a79c" \
  -H "Content-Type: application/json"

# Expected response:
# {
#   "status": "success",
#   "source_type": "easyappointments",
#   "leads_created": 10,
#   "leads_updated": 5,
#   "leads_skipped": 2,
#   "sync_time": "2026-01-22T18:30:00Z"
# }
```

### Step 5: Monitor Scheduled Syncs

At 6:30 PM UTC (or your configured time), check the logs to verify the sync runs:

```bash
railway logs --service Main --filter "sync"

# Look for:
# Starting scheduled EasyAppointments sync...
# EasyAppointments sync completed successfully: 10 created, 5 updated, 2 skipped
```

---

## Troubleshooting

### Issue: Scheduler doesn't start

**Symptoms:** No log messages about scheduler starting

**Solutions:**
1. Verify `FUNNEL_SYNC_ENABLED=true` is set (check `railway variables`)
2. Check for errors in startup logs: `railway logs --service Main`
3. Verify the scheduler service file exists at `/app/services/funnel_sync_scheduler.py`

### Issue: Sync fails with authentication error

**Symptoms:** Logs show "401 Unauthorized" or "403 Forbidden"

**Solutions:**
1. Verify `SIGNUP_SYNC_SERVICE_TOKEN` matches between both services:
   - Main service: Should have the token
   - signup-sync-service: Should accept the same token
2. Check if the token in signup-sync-service environment matches:
   ```bash
   railway variables --service signup-sync-service | grep TOKEN
   ```

### Issue: Sync times out

**Symptoms:** Logs show "EasyAppointments sync timed out after 5 minutes"

**Solutions:**
1. Check EasyAppointments database connection (EASYAPPOINTMENTS_MYSQL_* variables)
2. Verify the signup-sync-service is healthy: `railway logs --service signup-sync-service`
3. Check if there's a large backlog of data to sync (increase timeout if needed)

### Issue: Sync runs but no data is synced

**Symptoms:** Logs show "0 created, 0 updated, X skipped"

**Solutions:**
1. Verify EasyAppointments has new appointments since last sync
2. Check the `funnel_sync_log` table in the database for errors
3. Check that funnel source is active in database:
   ```sql
   SELECT * FROM funnel_sources WHERE source_type = 'easyappointments' AND is_active = true;
   ```
4. Verify EasyAppointments database credentials are correct

### Issue: Scheduler runs at wrong time

**Symptoms:** Sync happens at unexpected times

**Solutions:**
1. Check the `FUNNEL_SYNC_CRON` value: `railway variables | grep CRON`
2. Verify timezone (scheduler uses UTC, not local time)
3. Use a cron expression tester: https://crontab.guru/

---

## Database Verification

To verify the scheduler is working, check the database tables:

### Check Funnel Sources
```sql
SELECT
    id,
    source_type,
    name,
    is_active,
    last_sync_at,
    sync_frequency_minutes
FROM funnel_sources
WHERE source_type = 'easyappointments';
```

### Check Sync Logs
```sql
SELECT
    id,
    source_id,
    sync_started_at,
    sync_completed_at,
    status,
    records_processed,
    records_created,
    records_updated,
    error_message
FROM funnel_sync_log
ORDER BY sync_started_at DESC
LIMIT 10;
```

### Check Funnel Events
```sql
SELECT
    id,
    source_id,
    event_type,
    email,
    first_name,
    last_name,
    created_at
FROM funnel_events
WHERE source_id = (SELECT id FROM funnel_sources WHERE source_type = 'easyappointments')
ORDER BY created_at DESC
LIMIT 20;
```

---

## Service Health Checks

### Check SignUp_Sync Service Health
```bash
curl https://signup-sync-service-production.up.railway.app/health

# Expected response:
# {
#   "status": "healthy",
#   "service": "signup-sync",
#   "timestamp": "2026-01-22T12:00:00Z",
#   "database": "connected"
# }
```

### Check Main Service Health
```bash
curl https://api.engarde.media/health

# Expected response:
# {
#   "status": "healthy",
#   "timestamp": "2026-01-22T12:00:00Z"
# }
```

### Check Service Connectivity
```bash
# Test that Main service can reach SignUp_Sync service
curl -X POST https://signup-sync-service-production.up.railway.app/sync/status/easyappointments \
  -H "Authorization: Bearer a2a278b63efe89893977f1a1ac7b8cb79ce653efea4b6d13d39d655d0bf7a79c"

# Expected response:
# {
#   "source_type": "easyappointments",
#   "last_sync": "2026-01-22T18:30:00Z",
#   "status": "success",
#   "next_sync": "2026-01-23T18:30:00Z"
# }
```

---

## Quick Command Reference

```bash
# Set environment variables
railway variables set FUNNEL_SYNC_ENABLED=true
railway variables set FUNNEL_SYNC_CRON="30 18 * * *"

# View all variables
railway variables --service Main

# View logs
railway logs --service Main
railway logs --service signup-sync-service

# Trigger manual sync
curl -X POST https://signup-sync-service-production.up.railway.app/sync/easyappointments \
  -H "Authorization: Bearer a2a278b63efe89893977f1a1ac7b8cb79ce653efea4b6d13d39d655d0bf7a79c"

# Check sync status
curl https://signup-sync-service-production.up.railway.app/sync/status/easyappointments \
  -H "Authorization: Bearer a2a278b63efe89893977f1a1ac7b8cb79ce653efea4b6d13d39d655d0bf7a79c"

# Redeploy service
railway up --service Main
```

---

## Next Steps After Configuration

1. **Set the variables** using Railway CLI or Dashboard
2. **Monitor the first scheduled sync** at 6:30 PM UTC
3. **Review the sync logs** to ensure data is flowing correctly
4. **Check the database** to verify funnel events are being created
5. **Adjust the schedule** if needed (e.g., sync more frequently during business hours)

---

## Related Documentation

- **Implementation Guide:** `/Users/cope/EnGardeHQ/SIGNUP_SYNC_AND_PLATFORM_USER_IMPLEMENTATION_GUIDE.md`
- **Scheduler Service:** `/Users/cope/EnGardeHQ/production-backend/app/services/funnel_sync_scheduler.py`
- **Main App Integration:** `/Users/cope/EnGardeHQ/production-backend/app/main.py`
- **SignUp_Sync Service:** `/Users/cope/EnGardeHQ/signup-sync-service/`

---

## Support & Questions

If you encounter any issues:
1. Check the troubleshooting section above
2. Review Railway logs for error messages
3. Verify all environment variables are set correctly
4. Test the SignUp_Sync service health endpoint
5. Check database connectivity and credentials

---

**Configuration Summary:**

✅ **Already Configured:**
- SIGNUP_SYNC_SERVICE_URL
- SIGNUP_SYNC_SERVICE_TOKEN
- Scheduler code is implemented and integrated

⚠️ **Need to Set:**
- FUNNEL_SYNC_ENABLED=true
- FUNNEL_SYNC_CRON=30 18 * * *

🎯 **Expected Outcome:**
After setting these variables, the scheduler will automatically sync EasyAppointments data to funnel events daily at 6:30 PM UTC.
