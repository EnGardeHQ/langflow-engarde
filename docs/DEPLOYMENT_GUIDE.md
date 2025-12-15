# EnGarde Frontend - Deployment Guide
## AuthContext Initialization Fix Deployment

This guide provides comprehensive instructions for deploying the AuthContext initialization fix to production with progressive rollout, monitoring, and safety mechanisms.

---

## Table of Contents

1. [Overview](#overview)
2. [Pre-Deployment Checklist](#pre-deployment-checklist)
3. [Deployment Process](#deployment-process)
4. [Rollout Strategy](#rollout-strategy)
5. [Monitoring](#monitoring)
6. [Troubleshooting](#troubleshooting)
7. [Contact Information](#contact-information)

---

## Overview

### What's Being Deployed

The AuthContext initialization fix addresses critical authentication issues:
- **Issue**: Re-initialization after successful login causing infinite redirect loops
- **Fix**: Implements `justLoggedIn` flag to prevent re-initialization after login
- **Impact**: Improves login reliability and dashboard load time

### Key Features

- **Progressive Rollout**: Deploy to 10% → 50% → 100% of users
- **Feature Flags**: Instant enable/disable without redeployment
- **Circuit Breaker**: Automatic fallback if error threshold exceeded
- **Comprehensive Monitoring**: Real-time metrics via Sentry and DataDog
- **Instant Rollback**: One-command rollback capability

---

## Pre-Deployment Checklist

### 1. Development Environment

- [ ] All unit tests passing (`npm run test:ci`)
- [ ] All E2E tests passing (`npm run test:e2e`)
- [ ] Type checks passing (`npm run type-check`)
- [ ] Linter passing (`npm run lint`)
- [ ] Code reviewed and approved
- [ ] Changes committed to version control

### 2. Staging Environment

- [ ] Deployed to staging environment
- [ ] Staging tests completed successfully
- [ ] Performance benchmarks recorded
  - [ ] Login flow duration
  - [ ] Dashboard load time
  - [ ] Time to interactive
- [ ] QA team approval obtained
- [ ] No breaking changes identified

### 3. Production Preparation

- [ ] Monitoring dashboards configured
  - [ ] Sentry project created
  - [ ] DataDog RUM enabled
  - [ ] Alert rules configured
- [ ] Rollback procedure tested in staging
- [ ] Team members notified of deployment
- [ ] Support team briefed on changes
- [ ] Incident response team on standby

### 4. Configuration Verification

```bash
# Verify environment configuration
cd /Users/cope/EnGardeHQ/production-frontend

# Check feature flags
grep "NEXT_PUBLIC_ENABLE_AUTH_INIT_FIX" .env.production
grep "NEXT_PUBLIC_AUTH_FIX_ROLLOUT_PERCENTAGE" .env.production

# Check monitoring configuration
grep "NEXT_PUBLIC_SENTRY_DSN" .env.production
grep "NEXT_PUBLIC_DATADOG" .env.production
```

### 5. Backup and Recovery

- [ ] Database backup completed (if applicable)
- [ ] Previous deployment artifacts archived
- [ ] Environment configuration backed up
- [ ] Rollback script tested and ready

---

## Deployment Process

### Timeline

**Total Duration**: 4 days
- **Day 1**: Deploy to staging, validate
- **Day 2**: Deploy to 10% production
- **Day 3**: Increase to 50% if stable
- **Day 4**: Increase to 100% if stable

### Day 1: Staging Deployment

#### 1. Deploy to Staging

```bash
cd /Users/cope/EnGardeHQ

# Run deployment script for staging
bash scripts/deploy.sh 100 staging

# Verify deployment
bash scripts/verify.sh staging http://staging.engarde.app
```

#### 2. Run Comprehensive Tests

```bash
# Unit tests
npm run test:ci

# E2E tests
npm run test:e2e

# Performance tests
npm run test:performance
```

#### 3. Manual Testing Checklist

- [ ] Login with valid credentials works
- [ ] Login with invalid credentials shows error
- [ ] Dashboard loads correctly after login
- [ ] No infinite redirect loops
- [ ] Session persists across page refreshes
- [ ] Logout works correctly
- [ ] Re-login after logout works
- [ ] Password reset flow works
- [ ] OAuth login flows work (if applicable)

#### 4. Performance Benchmarks

Record baseline metrics:

```bash
# Login flow duration
Target: < 3 seconds

# Dashboard load time
Target: < 2 seconds (P95)

# Initialization time
Target: < 1 second
```

#### 5. Sign-Off

- [ ] Engineering lead approval
- [ ] QA lead approval
- [ ] Product manager approval

---

### Day 2: 10% Production Rollout

#### 1. Pre-Deployment Brief

**Time**: 09:00 AM
**Attendees**: Engineering, DevOps, Support

**Agenda**:
- Review deployment plan
- Confirm monitoring setup
- Review rollback procedure
- Establish communication channels

#### 2. Deploy to Production (10%)

```bash
cd /Users/cope/EnGardeHQ

# Deploy with 10% rollout
bash scripts/deploy.sh 10 production

# Verify deployment
bash scripts/verify.sh production https://app.engarde.com
```

#### 3. Monitoring Period (4 hours minimum)

Monitor the following metrics in real-time:

**Login Metrics**:
- Login success rate (target: > 95%)
- Login duration (target: < 3s)
- Login errors (target: < 1%)

**Dashboard Metrics**:
- Dashboard load time P95 (target: < 2s)
- Dashboard load time P99 (target: < 5s)
- Time to interactive (target: < 3s)

**Error Metrics**:
- Error rate (target: < 1%)
- Initialization timeouts (target: < 5%)
- Re-initialization skip rate (target: < 10%)

**Access Dashboards**:
- Sentry: https://sentry.io/organizations/engarde/issues/
- DataDog: https://app.datadoghq.com/dashboard/xxx-xxx-xxx

#### 4. Rollback Triggers

**Automatic Rollback** if any of the following occur:
- Login success rate drops > 5% below baseline
- Error rate increases > 1% above baseline
- Dashboard load time P95 increases > 2s above baseline
- More than 10 critical errors in 5 minutes

**Manual Rollback** considerations:
- User complaints increase significantly
- Support tickets related to login issues
- Unusual patterns in monitoring data

#### 5. End-of-Day Review

**Time**: 05:00 PM

- [ ] Review metrics collected
- [ ] Check error logs
- [ ] Review support tickets
- [ ] Make go/no-go decision for 50% rollout

---

### Day 3: 50% Production Rollout

#### 1. Pre-Deployment Review

**Time**: 09:00 AM

- [ ] Day 2 metrics reviewed
- [ ] No critical issues identified
- [ ] Support team feedback positive
- [ ] Team agrees to proceed

#### 2. Deploy to Production (50%)

```bash
cd /Users/cope/EnGardeHQ

# Deploy with 50% rollout
bash scripts/deploy.sh 50 production

# Verify deployment
bash scripts/verify.sh production https://app.engarde.com
```

#### 3. Monitoring Period (6 hours minimum)

Continue monitoring all metrics with increased scrutiny:

**Key Metrics to Watch**:
- Comparative analysis: 50% rollout group vs. control group
- Error rate trends
- Performance percentiles (P50, P95, P99)
- User behavior patterns

**Tools**:
```bash
# Generate monitoring report
node scripts/generate-metrics-report.js

# Check alert status
bash scripts/check-alerts.sh
```

#### 4. End-of-Day Review

**Time**: 05:00 PM

- [ ] Compare 50% cohort vs. 50% control group
- [ ] Verify metrics are stable or improved
- [ ] Check support ticket trends
- [ ] Make go/no-go decision for 100% rollout

---

### Day 4: 100% Production Rollout

#### 1. Pre-Deployment Review

**Time**: 09:00 AM

- [ ] Days 2-3 metrics reviewed
- [ ] No degradation observed
- [ ] Positive trends confirmed
- [ ] Team agrees to proceed to 100%

#### 2. Deploy to Production (100%)

```bash
cd /Users/cope/EnGardeHQ

# Deploy with 100% rollout
bash scripts/deploy.sh 100 production

# Verify deployment
bash scripts/verify.sh production https://app.engarde.com
```

#### 3. Extended Monitoring (24 hours)

Monitor for the next 24 hours with regular check-ins:

**Check-in Schedule**:
- Hour 1: Continuous monitoring
- Hour 4: First review
- Hour 8: Second review
- Hour 24: Final review

#### 4. Post-Deployment Review

**Time**: Day 5, 09:00 AM

- [ ] Final metrics analysis
- [ ] Support ticket review
- [ ] User feedback assessment
- [ ] Performance comparison with baseline
- [ ] Lessons learned documentation

---

## Rollout Strategy

### Feature Flag Configuration

The rollout is controlled by environment variables in `.env.production`:

```env
# Enable/disable the fix entirely
NEXT_PUBLIC_ENABLE_AUTH_INIT_FIX=true

# Percentage of users receiving the fix (0-100)
NEXT_PUBLIC_AUTH_FIX_ROLLOUT_PERCENTAGE=10

# Circuit breaker threshold
NEXT_PUBLIC_AUTH_CIRCUIT_BREAKER_THRESHOLD=5

# Enable monitoring
NEXT_PUBLIC_ENABLE_AUTH_MONITORING=true
```

### Rollout Percentages

| Day | Percentage | Duration | Decision Point |
|-----|-----------|----------|----------------|
| 1   | Staging (100%) | Full day | End of day |
| 2   | Production 10% | 4+ hours | End of day |
| 3   | Production 50% | 6+ hours | End of day |
| 4   | Production 100% | 24 hours | Next day |

### Circuit Breaker Logic

The circuit breaker automatically disables the fix if:
- Error count exceeds threshold (default: 5 consecutive errors)
- System falls back to previous behavior
- Monitoring alerts are triggered
- Manual intervention can override

---

## Monitoring

### Key Performance Indicators (KPIs)

#### Login Flow Metrics

1. **Login Success Rate**
   - **Baseline**: > 95%
   - **Alert Threshold**: < 90%
   - **Critical Threshold**: < 85%

2. **Login Duration (P95)**
   - **Target**: < 3000ms
   - **Alert Threshold**: > 5000ms
   - **Critical Threshold**: > 10000ms

3. **Login Error Rate**
   - **Baseline**: < 1%
   - **Alert Threshold**: > 2%
   - **Critical Threshold**: > 5%

#### Dashboard Load Metrics

1. **Time to Dashboard (P95)**
   - **Target**: < 2000ms
   - **Alert Threshold**: > 3000ms
   - **Critical Threshold**: > 5000ms

2. **Time to Interactive (P95)**
   - **Target**: < 3000ms
   - **Alert Threshold**: > 5000ms
   - **Critical Threshold**: > 8000ms

#### Error Metrics

1. **Initialization Timeout Rate**
   - **Target**: < 5%
   - **Alert Threshold**: > 10%
   - **Critical Threshold**: > 15%

2. **Re-initialization Skip Rate**
   - **Expected**: 80-95% (this is good - means fix is working)
   - **Alert Threshold**: < 50% (fix may not be working)

### Monitoring Dashboards

#### Sentry Configuration

```typescript
// /Users/cope/EnGardeHQ/production-frontend/lib/config/monitoring.ts
export const sentryConfig = {
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: 'production',
  tracesSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
};
```

**Key Sentry Views**:
- Issues filtered by `component:AuthContext`
- Performance transactions for `/login` and `/dashboard`
- Custom breadcrumbs for auth events

#### DataDog RUM Configuration

```typescript
export const datadogConfig = {
  applicationId: process.env.NEXT_PUBLIC_DATADOG_APPLICATION_ID,
  clientToken: process.env.NEXT_PUBLIC_DATADOG_CLIENT_TOKEN,
  service: 'engarde-frontend',
  env: 'production',
};
```

**Key DataDog Views**:
- Custom dashboard: "Auth Context Deployment"
- RUM sessions filtered by version
- Custom metrics for auth flow timing

### Alert Rules

Create the following alerts:

1. **Critical: Login Success Rate Drop**
   ```yaml
   condition: login_success_rate < 90%
   duration: 5 minutes
   action: Page on-call engineer + auto-rollback
   ```

2. **Warning: Slow Dashboard Load**
   ```yaml
   condition: dashboard_load_p95 > 3000ms
   duration: 10 minutes
   action: Notify engineering channel
   ```

3. **Critical: High Error Rate**
   ```yaml
   condition: error_rate > 5%
   duration: 5 minutes
   action: Page on-call engineer + auto-rollback
   ```

4. **Info: High Re-init Skip Rate**
   ```yaml
   condition: reinit_skip_rate > 90%
   duration: 15 minutes
   action: Log success metric
   ```

---

## Troubleshooting

### Common Issues

#### Issue 1: Login Redirect Loop

**Symptoms**:
- Users redirected between `/login` and `/dashboard` repeatedly
- Sentry shows multiple `INIT_START` events

**Diagnosis**:
```bash
# Check logs for re-initialization events
grep "justLoggedIn" /var/log/frontend/app.log

# Check Sentry for patterns
# Search: "Skipping re-initialization after successful login"
```

**Resolution**:
1. Verify `justLoggedIn` flag is being set correctly
2. Check for competing useEffect dependencies
3. If widespread: Execute rollback immediately

#### Issue 2: Slow Initialization

**Symptoms**:
- Dashboard takes > 5 seconds to load
- Timeout warnings in Sentry

**Diagnosis**:
```bash
# Check performance metrics
# DataDog: Filter by "auth.init.duration"
```

**Resolution**:
1. Verify network connectivity to API
2. Check API response times
3. Consider adjusting timeout thresholds
4. If persistent: Rollback and investigate

#### Issue 3: Feature Flag Not Working

**Symptoms**:
- Rollout percentage not affecting users
- All users seeing new behavior or old behavior

**Diagnosis**:
```bash
# Verify environment variables
grep "AUTH_FIX" .env.production

# Check build includes correct config
cat .next/server/pages/_app.js | grep "ENABLE_AUTH_INIT_FIX"
```

**Resolution**:
1. Rebuild application with correct environment variables
2. Verify Next.js is reading NEXT_PUBLIC_ variables
3. Check browser console for feature flag logs

### Emergency Contacts

| Role | Name | Contact | Responsibility |
|------|------|---------|----------------|
| Engineering Lead | [Name] | [Phone/Slack] | Technical decisions |
| DevOps Engineer | [Name] | [Phone/Slack] | Infrastructure, deployment |
| On-Call Engineer | [Rotation] | [PagerDuty] | Incident response |
| Product Manager | [Name] | [Phone/Slack] | Business decisions |
| Support Lead | [Name] | [Phone/Slack] | Customer communication |

### Escalation Path

1. **Level 1** (0-15 min): On-call engineer investigates
2. **Level 2** (15-30 min): Engineering lead engaged
3. **Level 3** (30+ min): Executive team notified

---

## Commands Reference

### Deployment

```bash
# Deploy with specific rollout percentage
bash scripts/deploy.sh <percentage> <environment>

# Examples
bash scripts/deploy.sh 10 production   # 10% rollout
bash scripts/deploy.sh 50 production   # 50% rollout
bash scripts/deploy.sh 100 production  # 100% rollout
```

### Verification

```bash
# Verify deployment
bash scripts/verify.sh <environment> <url>

# Example
bash scripts/verify.sh production https://app.engarde.com
```

### Rollback

```bash
# Emergency rollback
bash scripts/rollback.sh <reason>

# Example
bash scripts/rollback.sh "high_error_rate"
```

### Monitoring

```bash
# Generate metrics report
node scripts/generate-metrics-report.js

# Check alert status
bash scripts/check-alerts.sh

# View real-time logs
tail -f /Users/cope/EnGardeHQ/logs/deploy-*.log
```

---

## Post-Deployment Tasks

### Immediate (Day 1)

- [ ] Verify all monitoring alerts are functioning
- [ ] Confirm metrics are being collected
- [ ] Brief support team on changes
- [ ] Monitor support ticket trends

### Short-term (Week 1)

- [ ] Analyze performance improvements
- [ ] Review error patterns
- [ ] Collect user feedback
- [ ] Document lessons learned

### Long-term (Month 1)

- [ ] Remove feature flags (if stable)
- [ ] Update documentation
- [ ] Share results with team
- [ ] Plan next improvements

---

## Additional Resources

- [Rollback Procedure](./ROLLBACK_PROCEDURE.md)
- [Monitoring Guide](./MONITORING_GUIDE.md)
- [Incident Response](./INCIDENT_RESPONSE.md)
- [AuthContext Technical Documentation](../production-frontend/contexts/AuthContext.tsx)

---

**Document Version**: 1.0
**Last Updated**: 2025-10-09
**Next Review**: After successful 100% rollout
