# Demo Data Cron Job - Final Verification

## ✅ Configuration Complete

The `demo-data-cron` Railway service is now fully configured with intelligent backfill logic.

## What Happens When the Cron Runs

### Execution: Daily at 2 AM UTC

**Command**: `python scripts/generate_demo_data.py`

### Step-by-Step Process

1. **Database Connection**
   - Connects to PostgreSQL via `DATABASE_URL`
   - Verifies connection is healthy

2. **One-Time Setup** (First run only)
   - Creates demo users if they don't exist:
     - `demo@engarde.com` (primary demo user)
     - `agency@engarde.com` (agency user with clients)
   - Creates demo tenants and brands
   - Creates Walker AI agents (4 system agents)
   - Creates audience segments and interests
   - Sets up platform integrations
   - Creates workspaces, subscriptions, etc.

3. **Intelligent Backfill** (Every run)
   - Calculates 60-day window: `today - 59 days` to `today`
   - Queries existing campaigns in that window
   - Identifies missing dates
   - Generates data ONLY for missing dates

4. **Data Generation** (Per missing date)
   For each missing day, generates:
   - 1-2 campaigns
   - 1-3 HITL approvals
   - 2-3 content items
   - 10-20 analytics data points
   - Audience demographics
   - Behavioral analytics
   - Session analytics
   - Dashboard metrics
   - Automated insights

5. **Cleanup** (Every run)
   - Removes campaigns older than 60 days
   - Removes associated approvals and analytics
   - Keeps database size manageable

6. **BigQuery Integration** (Every run)
   - Runs `seed_bigquery_comprehensive_demo_data.py`
   - Generates third-party integration data:
     - Customers (Shopify, Stripe, etc.)
     - Products and orders
     - Meta and Google Ads data
     - Analytics data

7. **Walker Conversations** (Every run)
   - Generates AI agent conversations
   - Creates realistic chat history

8. **Exit**
   - Commits all changes to database
   - Exits with code 0 (success)
   - Railway waits until next scheduled run

## Execution Scenarios

### Scenario 1: First Deployment (Brand New)
**Expected**:
```
🚀 Starting COMPREHENSIVE demo data generation...
👥 PART 0: Ensuring demo users and agency setup exist...
   🔧 Creating primary demo user and tenant...
   🔧 Creating agency user and organization...

📦 PART 1: Processing individual demo brand users...
  👤 Processing user: demo@engarde.com
     📦 Processing brand: Demo Brand
      🌱 Initial data generation (60 days backfill)
      ✨ Generated data for 60 days
      📊 Created 120 campaigns, 1200 analytics, 180 approvals, 180 content, 60 insights

✅ SUCCESS! Generated data for 4 brands
```

**Result**: Full 60-day dataset created for all demo users

---

### Scenario 2: Normal Daily Run (Day 2)
**Expected**:
```
🚀 Starting COMPREHENSIVE demo data generation...
👥 PART 0: Ensuring demo users and agency setup exist...
   ✅ Users already exist

📦 PART 1: Processing individual demo brand users...
  👤 Processing user: demo@engarde.com
     📦 Processing brand: Demo Brand
      📈 Backfill mode: Found 1 missing days to fill (last: 2026-01-28)
      ✨ Generated data for 1 days
      📊 Created 2 campaigns, 15 analytics, 2 approvals, 3 content, 1 insights

✅ SUCCESS! Generated data for 4 brands
```

**Result**: Only today's data added, oldest day removed

---

### Scenario 3: Cron Missed 5 Days (Recovery)
**Expected**:
```
🚀 Starting COMPREHENSIVE demo data generation...
👥 PART 0: Ensuring demo users and agency setup exist...
   ✅ Users already exist

📦 PART 1: Processing individual demo brand users...
  👤 Processing user: demo@engarde.com
     📦 Processing brand: Demo Brand
      📈 Backfill mode: Found 5 missing days to fill (last: 2026-01-24)
      ✨ Generated data for 5 days
      📊 Created 10 campaigns, 75 analytics, 15 approvals, 15 content, 5 insights

✅ SUCCESS! Generated data for 4 brands
```

**Result**: Automatically backfills all 5 missing days

---

### Scenario 4: Already Ran Today
**Expected**:
```
🚀 Starting COMPREHENSIVE demo data generation...
👥 PART 0: Ensuring demo users and agency setup exist...
   ✅ Users already exist

📦 PART 1: Processing individual demo brand users...
  👤 Processing user: demo@engarde.com
     📦 Processing brand: Demo Brand
      ✅ All days up to date (last: 2026-01-29)
      ✨ Generated data for 0 days
      📊 Created 0 campaigns, 0 analytics, 0 approvals, 0 content, 0 insights

✅ SUCCESS! Generated data for 4 brands
```

**Result**: No duplicate data created (idempotent)

## Data Verification

### How to Verify the Cron Job is Working

#### 1. Check Railway Logs
```bash
# View logs for demo-data-cron service
railway logs --service demo-data-cron

# Or use Railway MCP
# (Already configured in your setup)
```

**Success Indicators**:
- ✅ `SUCCESS!` message appears
- ✅ Exit code 0
- ✅ No error stack traces
- ✅ Campaigns, analytics, approvals created

**Failure Indicators**:
- ❌ `Error generating demo data:` message
- ❌ Exit code non-zero
- ❌ Python exception stack traces
- ❌ Database connection errors

#### 2. Check Database Directly
```sql
-- Check total campaigns for demo user
SELECT COUNT(*) as total_campaigns
FROM campaigns c
JOIN brands b ON c.brand_id = b.id
JOIN tenants t ON b.tenant_id = t.id
JOIN tenant_users tu ON t.id = tu.tenant_id
JOIN users u ON tu.user_id = u.id
WHERE u.email = 'demo@engarde.com';

-- Should return: ~120-240 campaigns (60 days × 1-2 per day × multiple brands)

-- Check date range of campaigns
SELECT
  MIN(DATE(created_at)) as oldest_campaign,
  MAX(DATE(created_at)) as newest_campaign,
  COUNT(DISTINCT DATE(created_at)) as days_with_data
FROM campaigns c
JOIN brands b ON c.brand_id = b.id
JOIN tenants t ON b.tenant_id = t.id
JOIN tenant_users tu ON t.id = tu.tenant_id
JOIN users u ON tu.user_id = u.id
WHERE u.email = 'demo@engarde.com';

-- Should return:
-- oldest_campaign: ~60 days ago
-- newest_campaign: today
-- days_with_data: 60 (or close to 60)

-- Check for missing dates
WITH RECURSIVE date_range AS (
  SELECT CURRENT_DATE - INTERVAL '59 days' as day
  UNION ALL
  SELECT day + INTERVAL '1 day'
  FROM date_range
  WHERE day < CURRENT_DATE
)
SELECT dr.day
FROM date_range dr
LEFT JOIN (
  SELECT DISTINCT DATE(created_at) as campaign_date
  FROM campaigns c
  JOIN brands b ON c.brand_id = b.id
  JOIN tenants t ON b.tenant_id = t.id
  JOIN tenant_users tu ON t.id = tu.tenant_id
  JOIN users u ON tu.user_id = u.id
  WHERE u.email = 'demo@engarde.com'
) c ON dr.day = c.campaign_date
WHERE c.campaign_date IS NULL
ORDER BY dr.day;

-- Should return: Empty result set (no missing dates)
```

#### 3. Test via Frontend
1. Log into demo account:
   - Email: `demo@engarde.com`
   - Password: `demo123`

2. Check Dashboard:
   - Should see campaigns, analytics, metrics
   - Date range should show last 60 days
   - No gaps in timeline

3. Check Campaigns Page:
   - Should see ~60-120 campaigns
   - Dates should be continuous
   - Recent campaigns should include today

#### 4. Manual Test Run
```bash
cd /Users/cope/EnGardeHQ/production-backend
./test_demo_data_generation.sh
```

Or manually:
```bash
DATABASE_URL="postgresql://..." python3 scripts/generate_demo_data.py
```

## Key Configuration Files

### 1. Railway Cron Config
**File**: `railway-demo-data-cron.toml`
```toml
[deploy]
startCommand = "python scripts/generate_demo_data.py"
cronSchedule = "0 2 * * *"
restartPolicyType = "NEVER"
```

**Status**: ✅ Committed and pushed

### 2. Environment Variables
**Set via Railway MCP**:
- `DATABASE_URL` - PostgreSQL connection
- `ENVIRONMENT=production`
- `LOG_LEVEL=info`
- `PYTHONUNBUFFERED=1`

**Status**: ✅ Configured

### 3. Railway Dashboard
**Required Setting**:
- Settings → Deploy → Config File Path: `railway-demo-data-cron.toml`

**Status**: ⏳ Awaiting your configuration

## Success Criteria

After the cron job runs successfully:

### ✅ Database
- [ ] Demo user `demo@engarde.com` exists
- [ ] Agency user `agency@engarde.com` exists
- [ ] At least 120 campaigns exist for demo users
- [ ] Campaigns span exactly 60 days (no gaps)
- [ ] Latest campaign is from today
- [ ] Oldest campaign is from 60 days ago

### ✅ Data Completeness
- [ ] All 60 days have data (no missing dates)
- [ ] Each day has 1-2 campaigns
- [ ] Analytics data exists for all campaigns
- [ ] HITL approvals exist
- [ ] Content items exist
- [ ] Dashboard metrics exist

### ✅ Logs
- [ ] Cron job completes successfully (exit code 0)
- [ ] "SUCCESS!" message in logs
- [ ] No error stack traces
- [ ] Shows correct number of days generated

### ✅ Frontend
- [ ] Can log in as `demo@engarde.com`
- [ ] Dashboard shows metrics and charts
- [ ] Campaigns page shows continuous data
- [ ] Analytics page shows trend data
- [ ] No error messages

## Next Steps

1. **Complete Railway Dashboard Setup**
   - Set Config File Path to `railway-demo-data-cron.toml`
   - Verify cron schedule shows `0 2 * * *`

2. **Wait for First Scheduled Run**
   - Cron will run at 2 AM UTC tomorrow
   - Or manually trigger a deployment to test now

3. **Verify Results**
   - Check logs after 2:05 AM UTC
   - Query database to verify data
   - Test frontend demo account

4. **Monitor Daily**
   - Check logs weekly to ensure cron is running
   - Verify no errors in Railway dashboard
   - Spot-check demo data completeness

## Troubleshooting

### Cron Not Running
- Verify `railway-demo-data-cron.toml` is set as config file
- Check cron schedule is enabled in Railway dashboard
- Ensure service is not sleeping (Railway Pro required)

### Data Not Generating
- Check DATABASE_URL is correct
- Verify database connectivity
- Review error logs for specific issues

### Duplicate Data
- Should not happen with new backfill logic
- If it does, report as a bug

### Missing Days
- Script should auto-recover on next run
- Manually run script if needed: `railway run python scripts/generate_demo_data.py`

## Documentation

- **Backfill Logic**: `DEMO_DATA_BACKFILL_LOGIC.md`
- **Setup Guide**: `DEMO_DATA_CRON_SETUP.md`
- **Dashboard Steps**: `RAILWAY_CRON_DASHBOARD_STEPS.md`
- **Quick Summary**: `CRON_SETUP_SUMMARY.md`
- **Checklist**: `RAILWAY_CRON_CHECKLIST.txt`

---

**Status**: ✅ Code complete, ⏳ Awaiting Railway dashboard config
**Last Updated**: 2026-01-29
**Cron Schedule**: `0 2 * * *` (Daily at 2 AM UTC)
