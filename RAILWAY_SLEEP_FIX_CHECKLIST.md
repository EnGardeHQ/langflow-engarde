# Railway Sleep Fix - Step-by-Step Checklist

## ✅ Step 1: Diagnose the Issue (2 minutes)

- [ ] Open Railway Dashboard: https://railway.app
- [ ] Navigate to your project → Service
- [ ] Check status:
  - 🟢 **Active** = Running (may still sleep on free tier)
  - 🟡 **Sleeping** = Inactive (free tier behavior)
  - 🔴 **Failed** = Error (see logs)

- [ ] Check logs:
  ```bash
  railway logs --tail 50
  ```
  - Look for: "sleeping", "timeout", "error", "killed"

- [ ] Test health endpoint:
  ```bash
  curl https://your-app.up.railway.app/health
  ```
  - Expected: `{"status":"healthy",...}`

**Result:** If status is "Sleeping" and health endpoint works → Free tier inactivity (normal)

---

## ✅ Step 2: Set Up Keep-Alive Monitoring (5 minutes)

### Option A: UptimeRobot (Recommended)

- [ ] Go to: https://uptimerobot.com
- [ ] Sign up / Log in
- [ ] Click "Add New Monitor"
- [ ] Configure:
  - **Monitor Type:** HTTP(s)
  - **Friendly Name:** EnGarde Backend Health
  - **URL:** `https://your-app.up.railway.app/health`
  - **Monitoring Interval:** 5 minutes
  - **Status:** Enabled
- [ ] Click "Create Monitor"
- [ ] Verify monitor shows "UP" status

**Done!** Your service will stay awake.

### Option B: Cron-Job.org (Alternative)

- [ ] Go to: https://cron-job.org
- [ ] Sign up / Log in
- [ ] Click "Create Cronjob"
- [ ] Configure:
  - **Title:** EnGarde Keep-Alive
  - **URL:** `https://your-app.up.railway.app/health`
  - **Schedule:** `*/5 * * * *` (every 5 minutes)
  - **Request Method:** GET
- [ ] Click "Create"
- [ ] Verify cronjob is active

---

## ✅ Step 3: Verify Fix (2 minutes)

- [ ] Wait 10 minutes after setting up monitoring
- [ ] Check Railway Dashboard:
  - Status should show "Active" (not "Sleeping")
- [ ] Test health endpoint:
  ```bash
  curl https://your-app.up.railway.app/health
  ```
  - Should respond quickly (<1 second)
- [ ] Check monitoring service:
  - UptimeRobot: Should show "UP" status
  - Cron-Job: Should show successful runs

**Success Criteria:**
- ✅ Railway status: "Active"
- ✅ Health endpoint: Responds quickly
- ✅ Monitoring: Shows successful pings

---

## ✅ Step 4: Set Up Alerts (Optional, 5 minutes)

### Railway Alerts

- [ ] Railway Dashboard → Service → Settings → Notifications
- [ ] Enable:
  - ✅ Deployment failed
  - ✅ Service crashed
  - ✅ Health check failed
- [ ] Add email/Slack webhook (optional)

### External Monitoring Alerts

- [ ] UptimeRobot → Monitor → Edit
- [ ] Set up alert contacts:
  - Email notifications
  - SMS (if available)
  - Webhook (Slack/Discord)

---

## ✅ Step 5: Verify Configuration (3 minutes)

- [ ] Check `railway.toml`:
  ```bash
  cat production-backend/railway.toml | grep -A 3 "healthcheckPath"
  ```
  - Should show: `healthcheckPath = "/health"`

- [ ] Check Railway Dashboard:
  - Service → Settings → Start Command
  - Should be **BLANK** (uses railway.toml)

- [ ] Verify environment variables:
  ```bash
  railway variables
  ```
  - Should include: `PORT=8080`

- [ ] Test health endpoint locally (if possible):
  ```bash
  # If you have local access
  curl http://localhost:8080/health
  ```

---

## ✅ Step 6: Monitor for 24 Hours

- [ ] Check Railway Dashboard daily:
  - Status should remain "Active"
  - No unexpected restarts

- [ ] Check monitoring service:
  - UptimeRobot: Uptime should be 100%
  - No downtime alerts

- [ ] Review logs weekly:
  ```bash
  railway logs --tail 100 | grep -i "error\|timeout"
  ```

---

## Troubleshooting

### Service Still Sleeping?

- [ ] Verify monitoring is active:
  - Check UptimeRobot dashboard
  - Verify cronjob is running (Cron-Job.org)

- [ ] Test health endpoint manually:
  ```bash
  curl -v https://your-app.up.railway.app/health
  ```

- [ ] Check Railway logs:
  ```bash
  railway logs | grep -i "health\|sleep\|timeout"
  ```

- [ ] Verify configuration:
  - `healthcheckPath` in `railway.toml`
  - `PORT` environment variable
  - Health endpoint exists in code

### Health Check Failing?

- [ ] Check if service is running:
  ```bash
  railway ssh "ps aux | grep gunicorn"
  ```

- [ ] Check if port is listening:
  ```bash
  railway ssh "netstat -tlnp | grep 8080"
  ```

- [ ] Review startup logs:
  ```bash
  railway logs | grep -i "startup\|listening\|ready"
  ```

- [ ] See detailed troubleshooting: `RAILWAY_SLEEP_DIAGNOSIS.md`

---

## Success Criteria

After completing this checklist:

- ✅ Railway status: "Active" (not "Sleeping")
- ✅ Health endpoint: Responds quickly (<1 second)
- ✅ Monitoring: Active and pinging every 5 minutes
- ✅ Alerts: Configured (optional but recommended)
- ✅ Configuration: Verified and correct
- ✅ No unexpected downtime

---

## Quick Reference

### Commands

```bash
# Test health endpoint
curl https://your-app.up.railway.app/health

# Check Railway status
railway status

# View logs
railway logs --tail 100

# Check configuration
cat production-backend/railway.toml
```

### Links

- **Railway Dashboard:** https://railway.app
- **UptimeRobot:** https://uptimerobot.com
- **Cron-Job.org:** https://cron-job.org
- **Railway Docs:** https://docs.railway.app

### Documentation

- **Comprehensive Guide:** `RAILWAY_SLEEP_DIAGNOSIS.md`
- **Quick Fix:** `RAILWAY_SLEEP_QUICK_FIX.md`
- **Summary:** `RAILWAY_SLEEP_PREVENTION_SUMMARY.md`

---

**Estimated Time:** 15 minutes total  
**Difficulty:** Easy  
**Cost:** Free (using external monitoring)
