# Railway Sleep Issue - Quick Fix Guide

## Problem
Your Railway deployment is "sleeping" - service appears inactive after periods of no traffic.

## Root Cause
**Railway Free Tier** automatically sleeps services after ~5-15 minutes of inactivity. This is **normal behavior**, not a bug.

## Quick Fix (5 Minutes)

### Option 1: External Monitoring (Recommended - Easiest)

**UptimeRobot** (Free, 5-minute intervals):

1. Sign up: https://uptimerobot.com
2. Add Monitor:
   - **Type:** HTTP(s)
   - **URL:** `https://your-app.up.railway.app/health`
   - **Interval:** 5 minutes
   - **Status:** Enabled
3. Save

**Done!** Your service will stay awake.

---

### Option 2: Cron-Job.org (Free, Custom Schedule)

1. Sign up: https://cron-job.org
2. Create Cron Job:
   - **URL:** `https://your-app.up.railway.app/health`
   - **Schedule:** `*/5 * * * *` (every 5 minutes)
   - **Method:** GET
3. Save

---

### Option 3: Railway Keep-Alive Service (Self-Hosted)

**Step 1:** Create new Railway service called "keep-alive"

**Step 2:** Set environment variable:
```
RAILWAY_PUBLIC_DOMAIN=https://your-app.up.railway.app
```

**Step 3:** Deploy with keep-alive script:
```bash
cd production-backend
railway link --service keep-alive
railway up --config railway-keepalive.toml
```

**Note:** This uses Railway resources. External monitoring (Option 1) is recommended.

---

## Verify Fix

After setting up keep-alive:

```bash
# Test health endpoint
curl https://your-app.up.railway.app/health

# Check Railway dashboard - should show "Active" not "Sleeping"
```

---

## Why This Happens

- **Free Tier:** Services sleep after inactivity to save resources
- **First Request:** Takes 30-60 seconds (cold start) after sleep
- **Solution:** Periodic pings keep service awake

---

## Long-Term Solutions

1. **Keep Monitoring** (Free) - Continue using UptimeRobot/Cron-Job
2. **Upgrade to Pro** (~$20/month) - "Always On" feature prevents sleep
3. **Optimize Startup** - Faster startup = better health checks

---

## Troubleshooting

**Service still sleeping?**
- Verify monitoring is active (check UptimeRobot dashboard)
- Test health endpoint manually: `curl https://your-app.up.railway.app/health`
- Check Railway logs: `railway logs`

**Health check failing?**
- See `RAILWAY_SLEEP_DIAGNOSIS.md` for detailed troubleshooting

---

**Recommended:** Use Option 1 (UptimeRobot) - it's free, reliable, and requires no Railway resources.
