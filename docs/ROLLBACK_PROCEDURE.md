# EnGarde Frontend - Rollback Procedure
## Emergency Rollback for AuthContext Fix Deployment

This document provides step-by-step instructions for rolling back the AuthContext initialization fix deployment in case of critical issues.

---

## Table of Contents

1. [When to Rollback](#when-to-rollback)
2. [Rollback Decision Matrix](#rollback-decision-matrix)
3. [Rollback Procedures](#rollback-procedures)
4. [Post-Rollback Steps](#post-rollback-steps)
5. [Rollback Scenarios](#rollback-scenarios)

---

## When to Rollback

### Automatic Rollback Triggers

The system should automatically trigger a rollback if:

1. **Login Success Rate** drops below 85% for 5 consecutive minutes
2. **Error Rate** exceeds 5% for 5 consecutive minutes
3. **Critical Errors** exceed 10 instances in 5 minutes
4. **Circuit Breaker** threshold exceeded (5 consecutive auth errors)

### Manual Rollback Triggers

Consider manual rollback if:

1. **User Impact**
   - Multiple high-priority support tickets
   - Executive escalation
   - Social media complaints

2. **System Stability**
   - Dashboard load time P95 > 5 seconds
   - Initialization timeout rate > 15%
   - Database connection issues

3. **Business Impact**
   - Revenue-impacting issues
   - SLA violations
   - Customer churn risk

---

## Rollback Decision Matrix

| Severity | Login Success Rate | Error Rate | Dashboard Load (P95) | Action | Timeline |
|----------|-------------------|------------|---------------------|--------|----------|
| **Critical** | < 85% | > 5% | > 5s | Immediate rollback | 0-5 min |
| **High** | 85-90% | 2-5% | 3-5s | Rollback if no improvement in 15min | 15-30 min |
| **Medium** | 90-95% | 1-2% | 2-3s | Monitor closely, rollback if worsens | 30-60 min |
| **Low** | > 95% | < 1% | < 2s | Continue monitoring | N/A |

---

## Rollback Procedures

### Method 1: Feature Flag Rollback (Fastest - 2 minutes)

This is the **fastest** method as it only requires disabling the feature flag without rebuilding.

#### Step 1: Disable Feature Flag

```bash
cd /Users/cope/EnGardeHQ/production-frontend

# Backup current configuration
cp .env.production ".env.production.before-rollback.$(date +%Y%m%d-%H%M%S)"

# Disable feature flag
sed -i.bak 's/^NEXT_PUBLIC_ENABLE_AUTH_INIT_FIX=true/NEXT_PUBLIC_ENABLE_AUTH_INIT_FIX=false/' .env.production
sed -i.bak 's/^NEXT_PUBLIC_AUTH_FIX_ROLLOUT_PERCENTAGE=.*/NEXT_PUBLIC_AUTH_FIX_ROLLOUT_PERCENTAGE=0/' .env.production

# Verify changes
grep "ENABLE_AUTH_INIT_FIX" .env.production
grep "ROLLOUT_PERCENTAGE" .env.production
```

#### Step 2: Restart Application (if using PM2/systemd)

```bash
# For PM2
pm2 reload engarde-frontend

# For systemd
sudo systemctl restart engarde-frontend

# For Docker
docker-compose restart frontend
```

#### Step 3: Verify Rollback

```bash
# Check application health
curl -f https://app.engarde.com/api/health

# Check feature flag status
curl -s https://app.engarde.com/ | grep "ENABLE_AUTH_INIT_FIX"
```

**Timeline**: 2-3 minutes

---

### Method 2: Automated Script Rollback (Recommended - 5 minutes)

Use the automated rollback script for a complete rollback with verification.

#### Step 1: Execute Rollback Script

```bash
cd /Users/cope/EnGardeHQ

# Run rollback script with reason
bash scripts/rollback.sh "high_error_rate"

# Or for urgent manual rollback
bash scripts/rollback.sh "manual_urgent"
```

#### Step 2: Monitor Rollback Progress

The script will automatically:
1. Disable feature flags
2. Restore previous configuration
3. Rebuild application
4. Rebuild Docker image (if applicable)
5. Verify rollback success
6. Send notifications

#### Step 3: Verify Rollback

```bash
# Run verification script
bash scripts/verify.sh production https://app.engarde.com

# Check logs
tail -f /Users/cope/EnGardeHQ/logs/rollback-*.log
```

**Timeline**: 5-10 minutes

---

### Method 3: Full Deployment Rollback (10+ minutes)

If Methods 1 and 2 fail, perform a full rollback to the previous deployment.

#### Step 1: Identify Previous Deployment

```bash
cd /Users/cope/EnGardeHQ

# List previous deployments
ls -lt logs/deploy-*.log

# Identify last successful deployment before current
PREVIOUS_BUILD_ID="20251008-143022"  # Example
```

#### Step 2: Checkout Previous Version (if using Git tags)

```bash
# List tags
git tag -l "deploy-*"

# Checkout previous tag
git checkout deploy-${PREVIOUS_BUILD_ID}
```

#### Step 3: Rebuild and Redeploy

```bash
# Rebuild application
npm run build

# Rebuild Docker image
docker build -t engarde-frontend:rollback-$(date +%Y%m%d-%H%M%S) .

# Restart services
docker-compose down
docker-compose up -d
```

#### Step 4: Verify Rollback

```bash
bash scripts/verify.sh production https://app.engarde.com
```

**Timeline**: 10-20 minutes

---

### Method 4: Database Rollback (if applicable)

If database migrations were part of the deployment, roll those back as well.

#### Step 1: Identify Migrations

```bash
# List recent migrations
cd /Users/cope/EnGardeHQ/production-backend
python manage.py showmigrations

# Or for Node.js/Prisma
npx prisma migrate status
```

#### Step 2: Rollback Migrations

```bash
# Python/Django
python manage.py migrate <app_name> <previous_migration>

# Node.js/Prisma
npx prisma migrate resolve --rolled-back <migration_name>

# Or restore from backup
psql -U engarde_user -d engarde < backup-20251008.sql
```

**Timeline**: 5-15 minutes (depending on data size)

---

## Post-Rollback Steps

### Immediate Actions (0-30 minutes)

#### 1. Verify System Stability

```bash
# Check all health endpoints
bash scripts/health-check.sh

# Monitor key metrics
watch -n 5 'curl -s https://app.engarde.com/api/metrics'
```

#### 2. Confirm Metrics Recovery

Monitor these metrics for 30 minutes:

- **Login success rate** returning to baseline (> 95%)
- **Error rate** decreasing to normal (< 1%)
- **Dashboard load time** returning to target (< 2s P95)
- **Support tickets** rate stabilizing

#### 3. Notify Stakeholders

```bash
# Send notification via Slack
curl -X POST $SLACK_WEBHOOK_URL \
  -H 'Content-Type: application/json' \
  -d '{
    "text": "🔴 ROLLBACK COMPLETED - EnGarde Frontend\n\nReason: High error rate\nTimestamp: '$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'\nStatus: System stable\nNext steps: Investigation in progress"
  }'
```

#### 4. Update Status Page

Update your status page (e.g., status.engarde.com) with:
- Incident description
- Timeline of events
- Current status: Resolved
- Next steps

---

### Short-term Actions (1-4 hours)

#### 1. Root Cause Analysis

Create incident report with:

```markdown
## Incident Report: AuthContext Fix Rollback

**Incident ID**: INC-2025-XXX
**Date**: 2025-10-09
**Duration**: X hours
**Severity**: [Critical/High/Medium]

### Timeline
- HH:MM - Deployment started
- HH:MM - First error detected
- HH:MM - Rollback initiated
- HH:MM - Rollback completed
- HH:MM - System stable

### Impact
- Users affected: X%
- Duration of impact: X minutes
- Support tickets: X
- Revenue impact: $X (if applicable)

### Root Cause
[Detailed explanation of what went wrong]

### Resolution
[What was done to resolve the issue]

### Action Items
1. [ ] Fix identified issue
2. [ ] Add additional tests
3. [ ] Update deployment procedure
4. [ ] Schedule postmortem meeting
```

#### 2. Review Monitoring Alerts

```bash
# Generate monitoring report for incident period
node scripts/generate-incident-report.js \
  --start "2025-10-09T10:00:00Z" \
  --end "2025-10-09T12:00:00Z"
```

#### 3. Customer Communication

Prepare customer communication:

**For Affected Users**:
```
Subject: Service Disruption - Resolved

Dear [Customer],

We experienced a brief service disruption today between [TIME] and [TIME]
that may have affected your ability to log in. The issue has been fully
resolved, and all systems are operating normally.

What happened:
- [Brief explanation]

What we did:
- [Resolution steps]

We sincerely apologize for any inconvenience this may have caused.

If you continue to experience any issues, please contact support at
support@engarde.com.

Best regards,
The EnGarde Team
```

---

### Long-term Actions (1-7 days)

#### 1. Postmortem Meeting

Schedule within 24-48 hours with:
- Engineering team
- DevOps team
- Product management
- Support team

**Agenda**:
1. Timeline review
2. Root cause analysis
3. What went well
4. What could be improved
5. Action items and owners

#### 2. Fix the Issue

```bash
# Create fix branch
git checkout -b fix/auth-context-rollback-issues

# Implement fixes
# - Add additional error handling
# - Improve logging
# - Add more comprehensive tests

# Submit for review
git push origin fix/auth-context-rollback-issues
```

#### 3. Update Procedures

Update documentation:
- [ ] Deployment checklist
- [ ] Testing procedures
- [ ] Monitoring thresholds
- [ ] Rollback procedures (this document)

#### 4. Schedule Retry

Once fixes are ready:
1. Test thoroughly in staging
2. Run extended E2E tests
3. Get approval from team
4. Schedule new deployment attempt

---

## Rollback Scenarios

### Scenario 1: High Error Rate During 10% Rollout

**Symptoms**:
- Error rate jumps to 8%
- Sentry shows auth initialization errors
- Support tickets increasing

**Decision**: Immediate rollback

**Steps**:
```bash
# Method 2: Automated rollback
bash scripts/rollback.sh "high_error_rate_10pct"

# Verify
bash scripts/verify.sh production https://app.engarde.com

# Monitor for 30 minutes
watch -n 60 'curl -s https://app.engarde.com/api/metrics | jq .error_rate'
```

**Expected Timeline**: 5 minutes

---

### Scenario 2: Slow Dashboard Load at 50% Rollout

**Symptoms**:
- Dashboard load time P95 increases to 4s
- No errors, but performance degraded
- User complaints about slow loading

**Decision**: Rollback within 30 minutes if no improvement

**Steps**:
```bash
# First, try reducing rollout to 10%
bash scripts/deploy.sh 10 production

# Monitor for 15 minutes
# If no improvement, full rollback
bash scripts/rollback.sh "performance_degradation"
```

**Expected Timeline**: 15-30 minutes

---

### Scenario 3: Login Redirect Loop for Specific User Segment

**Symptoms**:
- Specific user type (e.g., advertisers) experiencing issues
- Other users unaffected
- Redirect loop between /login and /dashboard

**Decision**: Immediate rollback

**Steps**:
```bash
# Immediate rollback
bash scripts/rollback.sh "user_segment_redirect_loop"

# Investigate user segment specifics
# - Check user type logic
# - Review role-based authentication
# - Test with affected user accounts
```

**Expected Timeline**: 5 minutes

---

### Scenario 4: Database Connection Timeout

**Symptoms**:
- Authentication timeouts
- Database connection errors
- Sentry shows "User fetch timeout" errors

**Decision**: Investigate for 15 minutes, rollback if not resolved

**Steps**:
```bash
# Check database status
psql -U engarde_user -d engarde -c "SELECT 1;"

# Check connection pool
# Monitor database connections
docker exec -it engarde_postgres psql -U engarde_user -d engarde \
  -c "SELECT count(*) FROM pg_stat_activity;"

# If database is fine, rollback application
bash scripts/rollback.sh "db_timeout_errors"
```

**Expected Timeline**: 15-20 minutes

---

## Rollback Verification Checklist

After any rollback, verify:

### Critical Checks

- [ ] Application responds to HTTP requests (200 OK)
- [ ] Login page accessible
- [ ] Login with valid credentials works
- [ ] Dashboard loads successfully
- [ ] No error spike in Sentry
- [ ] Error rate below 1%
- [ ] Login success rate above 95%

### Performance Checks

- [ ] Dashboard load time P95 < 2s
- [ ] Login duration < 3s
- [ ] API response time < 500ms
- [ ] Time to interactive < 3s

### Business Checks

- [ ] Support ticket rate normalized
- [ ] No new critical issues reported
- [ ] Key customer accounts verified
- [ ] Executive team notified

---

## Emergency Contacts

### Rollback Decision Makers

| Role | Name | Contact | Authority |
|------|------|---------|-----------|
| Engineering Lead | [Name] | [Phone/Slack] | Approve rollback |
| CTO | [Name] | [Phone] | Final authority |
| On-Call Engineer | [Rotation] | [PagerDuty] | Execute rollback |

### Communication Chain

1. **Detect Issue** → On-call engineer
2. **Assess Severity** → Engineering lead
3. **Decide Rollback** → Engineering lead or CTO
4. **Execute Rollback** → On-call engineer + DevOps
5. **Communicate Status** → Product manager → Customers

---

## Rollback Automation

### Automated Monitoring Rollback

Set up automated rollback triggers in your monitoring system:

**DataDog Monitor Example**:
```yaml
name: "Auto-rollback on high error rate"
type: metric alert
query: "avg(last_5m):sum:engarde.frontend.errors{*} > 100"
message: |
  @pagerduty-engarde-critical
  High error rate detected. Automatic rollback initiated.

  Error count: {{value}}
  Threshold: 100

  Rollback command executed:
  bash /Users/cope/EnGardeHQ/scripts/rollback.sh "auto_high_error_rate"
thresholds:
  critical: 100
  warning: 50
```

**Sentry Alert Rule**:
```yaml
name: "Critical auth errors - auto rollback"
conditions:
  - event.type: error
  - event.tags.component: AuthContext
  - event.count: "> 10"
  - time_window: 5 minutes
actions:
  - trigger_webhook:
      url: https://your-automation-server.com/rollback
      method: POST
      body:
        reason: "critical_auth_errors"
        threshold_exceeded: true
```

---

## Rollback Testing

### Test Rollback Procedure in Staging

Schedule regular rollback drills:

```bash
# Monthly rollback drill
cd /Users/cope/EnGardeHQ

# 1. Deploy to staging
bash scripts/deploy.sh 100 staging

# 2. Execute rollback
bash scripts/rollback.sh "drill"

# 3. Verify rollback
bash scripts/verify.sh staging http://staging.engarde.app

# 4. Document time taken and issues
```

---

## Additional Resources

- [Deployment Guide](./DEPLOYMENT_GUIDE.md)
- [Monitoring Guide](./MONITORING_GUIDE.md)
- [Incident Response](./INCIDENT_RESPONSE.md)
- [On-Call Runbook](./ONCALL_RUNBOOK.md)

---

**Document Version**: 1.0
**Last Updated**: 2025-10-09
**Next Review**: After any rollback event
