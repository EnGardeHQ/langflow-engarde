# Quick Start - AuthContext Fix Deployment

This is your quick reference guide to start the deployment immediately.

---

## Prerequisites

1. All tests passing
2. Code reviewed and approved
3. Team briefed on deployment plan

---

## Step 1: Configure Environment Variables

Edit `/Users/cope/EnGardeHQ/.env` and add:

```env
# Monitoring (REQUIRED)
NEXT_PUBLIC_SENTRY_DSN=your-sentry-dsn-here
DATADOG_APPLICATION_ID=your-datadog-app-id
DATADOG_CLIENT_TOKEN=your-datadog-client-token

# Notifications (OPTIONAL)
SLACK_WEBHOOK_URL=your-slack-webhook-url
```

---

## Step 2: Deploy to Staging

```bash
cd /Users/cope/EnGardeHQ

# Deploy to staging with 100% rollout
bash scripts/deploy.sh 100 staging

# Verify deployment
bash scripts/verify.sh staging http://staging.engarde.app
```

Wait for approval before proceeding to production.

---

## Step 3: Production Rollout (Day 1 - 10%)

```bash
# Deploy to production with 10% rollout
bash scripts/deploy.sh 10 production

# Verify deployment
bash scripts/verify.sh production https://app.engarde.com

# Monitor dashboards (keep open)
open https://sentry.io/organizations/engarde/
open https://app.datadoghq.com/dashboard/auth-context
```

**Monitor for 4+ hours. Check these metrics:**
- Login success rate: Should stay > 95%
- Error rate: Should stay < 1%
- Dashboard load time P95: Should stay < 2s

---

## Step 4: Production Rollout (Day 2 - 50%)

If Day 1 metrics are healthy:

```bash
# Increase to 50% rollout
bash scripts/deploy.sh 50 production

# Verify
bash scripts/verify.sh production https://app.engarde.com
```

**Monitor for 6+ hours.**

---

## Step 5: Production Rollout (Day 3 - 100%)

If Day 2 metrics are healthy:

```bash
# Increase to 100% rollout
bash scripts/deploy.sh 100 production

# Verify
bash scripts/verify.sh production https://app.engarde.com
```

**Monitor for 24 hours.**

---

## Emergency Rollback

If issues occur at ANY stage:

```bash
# Immediate rollback
bash scripts/rollback.sh "high_error_rate"

# Verify rollback
bash scripts/verify.sh production https://app.engarde.com
```

---

## Key Monitoring Metrics

### Healthy Deployment Indicators

✅ Login success rate: > 95%
✅ Login duration P95: < 3s
✅ Dashboard load time P95: < 2s
✅ Error rate: < 1%
✅ Re-init skip rate: > 80%

### Rollback Triggers

🔴 Login success rate: < 85%
🔴 Error rate: > 5%
🔴 Dashboard load time P95: > 5s
🔴 Critical errors: > 10 in 5 minutes

---

## Support

### Monitoring Dashboards

- **Sentry**: https://sentry.io/organizations/engarde/
- **DataDog**: https://app.datadoghq.com/
- **Logs**: /Users/cope/EnGardeHQ/logs/

### Documentation

- [Deployment Guide](./docs/DEPLOYMENT_GUIDE.md) - Full procedures
- [Rollback Procedure](./docs/ROLLBACK_PROCEDURE.md) - Emergency rollback
- [Monitoring Guide](./docs/MONITORING_GUIDE.md) - Dashboard setup
- [Incident Response](./docs/INCIDENT_RESPONSE.md) - Incident handling
- [Summary](./docs/DEPLOYMENT_PLAN_SUMMARY.md) - Complete overview

### Emergency Contacts

- Engineering Lead: [Contact]
- DevOps Engineer: [Contact]
- On-Call: [PagerDuty]

---

## Quick Commands

```bash
# Deploy
bash scripts/deploy.sh <percentage> production

# Verify
bash scripts/verify.sh production https://app.engarde.com

# Rollback
bash scripts/rollback.sh "reason"

# Check logs
tail -f /Users/cope/EnGardeHQ/logs/deploy-*.log

# Docker restart
docker-compose restart frontend
```

---

**Ready to deploy? Start with Step 1!**
