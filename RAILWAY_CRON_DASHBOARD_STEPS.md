# Railway Dashboard Configuration for demo-data-cron

## Quick Setup Checklist

Follow these steps in the Railway dashboard to complete the cron job setup:

### ✅ Step 1: Open Railway Dashboard
1. Go to https://railway.app
2. Navigate to **EnGarde Suite** project
3. Click on **demo-data-cron** service

### ✅ Step 2: Configure the Service
Go to **Settings** and configure the following sections:

#### Build Settings
- **Settings → Build → Builder**: `DOCKERFILE`
- **Settings → Build → Dockerfile Path**: `Dockerfile.optimized`
- **Settings → Build → Root Directory**: `/` (default)

#### Deploy Settings
- **Settings → Deploy → Start Command**:
  ```
  python scripts/generate_demo_data.py
  ```
- **Settings → Deploy → Restart Policy**: `NEVER`
- **Settings → Deploy → Health Check**: Disable (toggle off)

#### Cron Settings ⏰
- **Settings → Cron → Enable Cron Jobs**: Toggle ON
- **Settings → Cron → Cron Expression**: `0 2 * * *`
  - This runs daily at 2:00 AM UTC
- **Settings → Cron → Timezone**: `UTC`

### ✅ Step 3: Verify Environment Variables
Go to **Settings → Variables** and confirm these variables exist:

| Variable | Value |
|----------|-------|
| `DATABASE_URL` | postgresql://postgres:***@postgres.railway.internal:5432/railway |
| `ENVIRONMENT` | production |
| `LOG_LEVEL` | info |
| `PYTHONUNBUFFERED` | 1 |

These were already set via Railway MCP ✅

### ✅ Step 4: Deploy the Service
1. Click **Deploy** (or wait for auto-deploy)
2. Monitor the build logs
3. Verify successful deployment

### ✅ Step 5: Test the Configuration

#### Option A: Manual Test Run
1. Go to **Deployments** tab
2. Click **Trigger Deploy**
3. Wait for build to complete
4. Check logs for "SUCCESS" message

#### Option B: Using Railway CLI
```bash
# From your terminal
cd /Users/cope/EnGardeHQ
./test_demo_data_cron.sh
```

Or manually:
```bash
cd /Users/cope/EnGardeHQ/production-backend
railway link -s demo-data-cron
railway run python scripts/generate_demo_data.py
```

### ✅ Step 6: Monitor Logs
Go to **Logs** tab to see:
- Cron execution logs
- Script output
- Success/failure messages
- Any errors

---

## Understanding the Cron Schedule

Current schedule: `0 2 * * *`

```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (Sunday to Saturday)
│ │ │ │ │
│ │ │ │ │
0 2 * * *
```

This means: **Every day at 2:00 AM UTC**

### Other Useful Schedules
- `0 */6 * * *` - Every 6 hours
- `0 0 * * 0` - Weekly (Sunday at midnight)
- `0 3 * * 1-5` - Weekdays at 3 AM
- `*/15 * * * *` - Every 15 minutes (testing)

Use https://crontab.guru/ to test cron expressions.

---

## What Happens When the Cron Runs?

1. **At 2:00 AM UTC daily**, Railway automatically:
   - Starts the demo-data-cron service
   - Runs `python scripts/generate_demo_data.py`
   - Waits for the script to complete
   - Stops the service (restartPolicyType = NEVER)

2. **The script**:
   - Connects to the production database
   - Checks if demo data exists
   - If first run: Generates 30 days of historical data
   - If daily run: Adds 1 new day of data
   - Cleans up data older than 60 days
   - Exits with code 0 (success) or non-zero (failure)

3. **Railway**:
   - Logs all output
   - Waits for next scheduled run (next day at 2 AM)

---

## Troubleshooting

### Service Not Building
- Check Dockerfile.optimized exists in repository
- Verify build logs for errors
- Ensure railway-demo-data-cron.toml is valid

### Cron Not Running
- Verify "Enable Cron Jobs" is toggled ON
- Check cron expression syntax
- Ensure service is not in sleep mode (Railway Pro required)
- Review Railway plan limits

### Script Errors
- Check environment variables are set correctly
- Verify database connection (DATABASE_URL)
- Review application logs for Python errors
- Ensure database schema is current

### Database Connection Failed
- Verify Postgres service is running
- Check DATABASE_URL format
- Test connection manually: `railway run python -c "import os; print(os.getenv('DATABASE_URL'))"`

---

## Next Steps

1. **Monitor First Run**: Check logs after setup to ensure it works
2. **Verify Data**: Connect to database and verify demo data was created
3. **Set Alerts**: Configure Railway notifications for failures
4. **Document**: Keep this config documented for team reference

---

## Resources

- 📖 **Setup Guide**: `production-backend/DEMO_DATA_CRON_SETUP.md`
- 🧪 **Test Script**: `test_demo_data_cron.sh`
- ⚙️ **Config File**: `production-backend/railway-demo-data-cron.toml`
- 🐍 **Script**: `production-backend/scripts/generate_demo_data.py`
- 🌐 **Railway Docs**: https://docs.railway.app/reference/cron-jobs
- ⏰ **Cron Helper**: https://crontab.guru/

---

## Support

For issues:
- Railway Discord: https://discord.gg/railway
- Railway Support: support@railway.app
- Check Railway status: https://status.railway.app/
