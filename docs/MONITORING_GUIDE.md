# EnGarde Frontend - Monitoring Guide
## Real-Time Monitoring for AuthContext Fix Deployment

This guide provides comprehensive information about monitoring the AuthContext initialization fix deployment, including dashboard setup, alert configuration, and metric interpretation.

---

## Table of Contents

1. [Overview](#overview)
2. [Monitoring Stack](#monitoring-stack)
3. [Key Metrics](#key-metrics)
4. [Dashboard Setup](#dashboard-setup)
5. [Alert Configuration](#alert-configuration)
6. [Metric Interpretation](#metric-interpretation)
7. [Troubleshooting](#troubleshooting)

---

## Overview

### Monitoring Objectives

1. **Ensure deployment safety** - Detect issues before they impact users
2. **Track performance** - Measure improvements in login and dashboard load times
3. **Enable quick rollback** - Provide data for rollback decisions
4. **Continuous improvement** - Identify optimization opportunities

### Monitoring Tools

| Tool | Purpose | Dashboard URL |
|------|---------|---------------|
| **Sentry** | Error tracking, performance monitoring | https://sentry.io/organizations/engarde/ |
| **DataDog RUM** | Real User Monitoring, custom metrics | https://app.datadoghq.com/ |
| **Application Logs** | Structured logging, debugging | /Users/cope/EnGardeHQ/logs/ |
| **Health Checks** | System availability | https://app.engarde.com/api/health |

---

## Monitoring Stack

### Sentry Configuration

#### Setup

```typescript
// /Users/cope/EnGardeHQ/production-frontend/lib/config/monitoring.ts
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: 'production',

  // Performance monitoring
  tracesSampleRate: 0.1,  // 10% of transactions

  // Session replay
  replaysSessionSampleRate: 0.1,  // 10% of sessions
  replaysOnErrorSampleRate: 1.0,  // 100% when errors occur

  // Filtering
  beforeSend(event) {
    // Remove sensitive data
    if (event.request?.headers) {
      delete event.request.headers['authorization'];
      delete event.request.headers['cookie'];
    }
    return event;
  },

  // Ignore benign errors
  ignoreErrors: [
    'ResizeObserver loop limit exceeded',
    'NetworkError',
    'Load failed',
  ],
});
```

#### Custom Tags

Add custom tags to Sentry events for better filtering:

```typescript
Sentry.setTag('deployment_version', process.env.NEXT_PUBLIC_BUILD_ID);
Sentry.setTag('auth_fix_enabled', process.env.NEXT_PUBLIC_ENABLE_AUTH_INIT_FIX);
Sentry.setTag('rollout_percentage', process.env.NEXT_PUBLIC_AUTH_FIX_ROLLOUT_PERCENTAGE);
```

---

### DataDog RUM Configuration

#### Setup

```typescript
// /Users/cope/EnGardeHQ/production-frontend/pages/_app.tsx
import { datadogRum } from '@datadog/browser-rum';

datadogRum.init({
  applicationId: process.env.NEXT_PUBLIC_DATADOG_APPLICATION_ID!,
  clientToken: process.env.NEXT_PUBLIC_DATADOG_CLIENT_TOKEN!,
  site: 'datadoghq.com',
  service: 'engarde-frontend',
  env: 'production',

  sessionSampleRate: 100,
  sessionReplaySampleRate: 20,
  trackUserInteractions: true,
  trackResources: true,
  trackLongTasks: true,
  defaultPrivacyLevel: 'mask-user-input',
});
```

#### Custom Metrics

Track custom metrics in DataDog:

```typescript
import { datadogRum } from '@datadog/browser-rum';

// Track login attempt
datadogRum.addAction('auth.login.attempt', {
  success: true,
  duration: 1234,
  userType: 'advertiser',
});

// Track initialization
datadogRum.addAction('auth.init.complete', {
  duration: 567,
  cached: true,
  skippedReinit: true,
});
```

---

## Key Metrics

### 1. Login Flow Metrics

#### Login Success Rate

**Description**: Percentage of successful login attempts

**Formula**: `(successful_logins / total_login_attempts) * 100`

**Targets**:
- Baseline: > 95%
- Warning: < 90%
- Critical: < 85%

**Sentry Query**:
```
transaction.op:navigation AND transaction:/login
status:ok
```

**DataDog Query**:
```
sum:engarde.frontend.auth.login.success{*} / sum:engarde.frontend.auth.login.attempt{*}
```

---

#### Login Duration (P50, P95, P99)

**Description**: Time from login button click to dashboard load

**Targets**:
- P50: < 1500ms
- P95: < 3000ms
- P99: < 5000ms

**Sentry Query**:
```
transaction.op:navigation
transaction:/login
measurements.duration
```

**DataDog Query**:
```
p50:engarde.frontend.auth.login.duration{*}
p95:engarde.frontend.auth.login.duration{*}
p99:engarde.frontend.auth.login.duration{*}
```

---

#### Login Error Rate

**Description**: Percentage of login attempts resulting in errors

**Formula**: `(failed_logins / total_login_attempts) * 100`

**Targets**:
- Baseline: < 1%
- Warning: > 2%
- Critical: > 5%

**Sentry Query**:
```
event.type:error
tags.component:AuthContext
tags.event:login_failed
```

---

### 2. Dashboard Load Metrics

#### Time to Dashboard (TTD)

**Description**: Time from successful login to dashboard fully loaded

**Targets**:
- P50: < 1000ms
- P95: < 2000ms
- P99: < 3000ms

**Measurement Points**:
1. Login success (t0)
2. Redirect initiated (t1)
3. Dashboard route loaded (t2)
4. Dashboard data fetched (t3)
5. Dashboard interactive (t4)

**DataDog Query**:
```
avg:engarde.frontend.dashboard.load_time{*}
p95:engarde.frontend.dashboard.load_time{*}
```

---

#### Dashboard Load Error Rate

**Description**: Percentage of dashboard loads that fail

**Targets**:
- Baseline: < 0.5%
- Warning: > 1%
- Critical: > 2%

**Sentry Query**:
```
event.type:error
transaction:/dashboard
```

---

### 3. Initialization Metrics

#### Initialization Duration

**Description**: Time taken for AuthContext to initialize

**Targets**:
- P50: < 500ms
- P95: < 1000ms
- P99: < 2000ms

**DataDog Query**:
```
avg:engarde.frontend.auth.init.duration{*}
p95:engarde.frontend.auth.init.duration{*}
```

---

#### Initialization Timeout Rate

**Description**: Percentage of initializations that timeout

**Targets**:
- Baseline: < 5%
- Warning: > 10%
- Critical: > 15%

**Sentry Query**:
```
message:"Initialization timeout"
level:warning
```

---

#### Re-initialization Skip Rate

**Description**: Percentage of times re-initialization is skipped (fix working)

**Targets**:
- Expected: 80-95% (higher is better - means fix is working)
- Warning: < 50% (fix may not be working)

**DataDog Query**:
```
sum:engarde.frontend.auth.reinit.skip{*} / sum:engarde.frontend.auth.init.attempt{*}
```

**Note**: High skip rate is GOOD - it means the fix is preventing unnecessary re-initializations.

---

### 4. Error Metrics

#### Overall Error Rate

**Description**: Application-wide error rate

**Targets**:
- Baseline: < 1%
- Warning: > 2%
- Critical: > 5%

**Sentry Query**:
```
event.type:error
level:error OR level:fatal
```

---

#### Auth-Specific Errors

**Description**: Errors in authentication flow

**Key Error Types**:
- `AUTH_INIT_TIMEOUT`: Initialization timeout
- `AUTH_FETCH_FAILED`: User fetch failed
- `AUTH_TOKEN_INVALID`: Invalid or expired token
- `AUTH_REDIRECT_LOOP`: Redirect loop detected

**Sentry Query**:
```
event.type:error
tags.component:AuthContext
```

---

## Dashboard Setup

### Sentry Dashboard

#### Create Custom Dashboard

1. Navigate to https://sentry.io/organizations/engarde/dashboards/
2. Click "Create Dashboard"
3. Name: "Auth Context Deployment Monitoring"
4. Add the following widgets:

**Widget 1: Login Success Rate**
```
Type: Line Chart
Query: transaction:/login
Grouping: status
Y-Axis: count()
```

**Widget 2: Login Duration P95**
```
Type: Line Chart
Query: transaction:/login
Y-Axis: p95(measurements.duration)
```

**Widget 3: Auth Errors**
```
Type: Table
Query: event.type:error tags.component:AuthContext
Columns: timestamp, message, count
Sort: count DESC
```

**Widget 4: Dashboard Load Time**
```
Type: Line Chart
Query: transaction:/dashboard
Y-Axis: p95(measurements.lcp)
```

**Widget 5: Initialization Metrics**
```
Type: Big Number
Query: message:"Initialization completed successfully"
Display: count()
```

---

### DataDog Dashboard

#### Create Custom Dashboard

Create a new dashboard at https://app.datadoghq.com/dashboard/

**Dashboard JSON** (import this):

```json
{
  "title": "EnGarde Auth Context Deployment",
  "description": "Monitoring for AuthContext initialization fix deployment",
  "widgets": [
    {
      "id": 1,
      "definition": {
        "title": "Login Success Rate",
        "type": "timeseries",
        "requests": [
          {
            "q": "sum:engarde.frontend.auth.login.success{*}.as_rate() / sum:engarde.frontend.auth.login.attempt{*}.as_rate() * 100",
            "display_type": "line",
            "style": {
              "palette": "dog_classic",
              "line_type": "solid",
              "line_width": "normal"
            }
          }
        ],
        "yaxis": {
          "min": "0",
          "max": "100",
          "label": "Success Rate (%)"
        },
        "markers": [
          {
            "value": "y = 95",
            "display_type": "error dashed"
          },
          {
            "value": "y = 85",
            "display_type": "error solid"
          }
        ]
      }
    },
    {
      "id": 2,
      "definition": {
        "title": "Login Duration Percentiles",
        "type": "timeseries",
        "requests": [
          {
            "q": "p50:engarde.frontend.auth.login.duration{*}",
            "display_type": "line"
          },
          {
            "q": "p95:engarde.frontend.auth.login.duration{*}",
            "display_type": "line"
          },
          {
            "q": "p99:engarde.frontend.auth.login.duration{*}",
            "display_type": "line"
          }
        ],
        "yaxis": {
          "label": "Duration (ms)"
        },
        "markers": [
          {
            "value": "y = 3000",
            "display_type": "warning dashed"
          }
        ]
      }
    },
    {
      "id": 3,
      "definition": {
        "title": "Error Rate",
        "type": "query_value",
        "requests": [
          {
            "q": "sum:engarde.frontend.auth.error{*}.as_rate() / sum:engarde.frontend.auth.attempt{*}.as_rate() * 100",
            "aggregator": "avg"
          }
        ],
        "precision": 2,
        "custom_unit": "%",
        "conditional_formats": [
          {
            "comparator": "<",
            "value": 1,
            "palette": "white_on_green"
          },
          {
            "comparator": ">=",
            "value": 5,
            "palette": "white_on_red"
          },
          {
            "comparator": ">=",
            "value": 2,
            "palette": "white_on_yellow"
          }
        ]
      }
    },
    {
      "id": 4,
      "definition": {
        "title": "Re-initialization Skip Rate (Higher is Better)",
        "type": "query_value",
        "requests": [
          {
            "q": "sum:engarde.frontend.auth.reinit.skip{*} / sum:engarde.frontend.auth.init.attempt{*} * 100"
          }
        ],
        "precision": 1,
        "custom_unit": "%",
        "conditional_formats": [
          {
            "comparator": ">",
            "value": 80,
            "palette": "white_on_green"
          },
          {
            "comparator": "<",
            "value": 50,
            "palette": "white_on_yellow"
          }
        ]
      }
    },
    {
      "id": 5,
      "definition": {
        "title": "Dashboard Load Time (P95)",
        "type": "timeseries",
        "requests": [
          {
            "q": "p95:engarde.frontend.dashboard.load_time{*}",
            "display_type": "line"
          }
        ],
        "yaxis": {
          "label": "Duration (ms)"
        },
        "markers": [
          {
            "value": "y = 2000",
            "display_type": "error dashed",
            "label": "Target"
          },
          {
            "value": "y = 5000",
            "display_type": "error solid",
            "label": "Critical"
          }
        ]
      }
    },
    {
      "id": 6,
      "definition": {
        "title": "Initialization Timeout Rate",
        "type": "timeseries",
        "requests": [
          {
            "q": "sum:engarde.frontend.auth.init.timeout{*}.as_rate() / sum:engarde.frontend.auth.init.attempt{*}.as_rate() * 100",
            "display_type": "bars"
          }
        ],
        "yaxis": {
          "min": "0",
          "max": "20",
          "label": "Timeout Rate (%)"
        }
      }
    }
  ],
  "template_variables": [
    {
      "name": "environment",
      "default": "production",
      "prefix": "env"
    },
    {
      "name": "version",
      "default": "*",
      "prefix": "version"
    }
  ],
  "layout_type": "ordered",
  "is_read_only": false,
  "notify_list": [],
  "reflow_type": "fixed"
}
```

---

## Alert Configuration

### Sentry Alerts

#### Alert 1: Critical - Login Success Rate Drop

```yaml
name: "Critical: Login Success Rate Below 85%"
project: engarde-frontend
conditions:
  - metric: transaction.duration
    filter: "transaction:/login AND status:ok"
    comparison_type: percent
    value: < 85
    time_window: 5
actions:
  - PagerDuty: engarde-critical
  - Slack: #engarde-alerts
  - Webhook: https://automation.engarde.com/rollback
```

**Create via Sentry UI**:
1. Navigate to Alerts > Create Alert Rule
2. Choose "Metric Alert"
3. Set conditions as above
4. Configure notifications

---

#### Alert 2: Warning - Slow Login Performance

```yaml
name: "Warning: Login P95 Duration > 5s"
project: engarde-frontend
conditions:
  - metric: transaction.duration
    filter: "transaction:/login"
    comparison_type: p95
    value: > 5000
    time_window: 10
actions:
  - Slack: #engarde-alerts
  - Email: engineering@engarde.com
```

---

#### Alert 3: Critical - High Auth Error Rate

```yaml
name: "Critical: Auth Error Rate > 5%"
project: engarde-frontend
conditions:
  - metric: error.count
    filter: "tags.component:AuthContext"
    comparison_type: percent
    value: > 5
    time_window: 5
actions:
  - PagerDuty: engarde-critical
  - Slack: #engarde-alerts
  - Webhook: https://automation.engarde.com/rollback
```

---

### DataDog Monitors

#### Monitor 1: Login Success Rate

```yaml
name: "EnGarde - Login Success Rate Alert"
type: metric alert
query: |
  sum(last_5m):sum:engarde.frontend.auth.login.success{*}.as_count() /
  sum:engarde.frontend.auth.login.attempt{*}.as_count() * 100 < 85
message: |
  {{#is_alert}}
  🔴 CRITICAL: Login success rate dropped to {{value}}%

  Threshold: 85%
  Time window: Last 5 minutes

  **Action Required**: Investigate immediately and consider rollback

  Dashboard: https://app.datadoghq.com/dashboard/auth-context
  Runbook: https://github.com/engarde/docs/INCIDENT_RESPONSE.md

  @pagerduty-engarde-critical
  @slack-engarde-alerts
  {{/is_alert}}

  {{#is_warning}}
  ⚠️ WARNING: Login success rate at {{value}}%

  Threshold: 90%
  Monitor closely for degradation
  {{/is_warning}}

  {{#is_recovery}}
  ✅ RECOVERED: Login success rate back to {{value}}%
  {{/is_recovery}}
thresholds:
  critical: 85
  warning: 90
  recovery: 95
```

---

#### Monitor 2: Dashboard Load Time

```yaml
name: "EnGarde - Dashboard Load Time P95"
type: metric alert
query: "avg(last_10m):p95:engarde.frontend.dashboard.load_time{*} > 5000"
message: |
  Dashboard load time P95 is {{value}}ms

  Target: < 2000ms
  Warning: > 3000ms
  Critical: > 5000ms

  @slack-engarde-alerts
thresholds:
  critical: 5000
  warning: 3000
```

---

#### Monitor 3: Initialization Timeout Rate

```yaml
name: "EnGarde - Initialization Timeout Rate"
type: metric alert
query: |
  sum(last_10m):sum:engarde.frontend.auth.init.timeout{*}.as_count() /
  sum:engarde.frontend.auth.init.attempt{*}.as_count() * 100 > 15
message: |
  Initialization timeout rate is {{value}}%

  This indicates users are experiencing slow auth initialization.

  Check:
  - API response times
  - Database connectivity
  - Network latency

  @slack-engarde-alerts
thresholds:
  critical: 15
  warning: 10
```

---

## Metric Interpretation

### Healthy Metrics

**Indicators of successful deployment**:

✅ **Login success rate**: > 95%
✅ **Login duration P95**: < 3s
✅ **Dashboard load time P95**: < 2s
✅ **Error rate**: < 1%
✅ **Re-init skip rate**: > 80%
✅ **Init timeout rate**: < 5%

**Example healthy dashboard**:
```
Login Success Rate: 97.5%
Login Duration P95: 1.8s
Dashboard Load P95: 1.5s
Error Rate: 0.3%
Re-init Skip Rate: 92%
Init Timeout Rate: 2%
```

---

### Warning Metrics

**Indicators requiring attention**:

⚠️ **Login success rate**: 90-95%
⚠️ **Login duration P95**: 3-5s
⚠️ **Dashboard load time P95**: 2-3s
⚠️ **Error rate**: 1-2%
⚠️ **Re-init skip rate**: 50-80%
⚠️ **Init timeout rate**: 5-10%

**Actions**:
1. Monitor closely for trends
2. Review error logs
3. Check for patterns
4. Prepare for potential rollback

---

### Critical Metrics

**Indicators requiring immediate action**:

🔴 **Login success rate**: < 90%
🔴 **Login duration P95**: > 5s
🔴 **Dashboard load time P95**: > 3s
🔴 **Error rate**: > 2%
🔴 **Re-init skip rate**: < 50%
🔴 **Init timeout rate**: > 10%

**Actions**:
1. **Immediate**: Notify on-call engineer
2. **Within 5 min**: Assess rollback decision
3. **Within 15 min**: Execute rollback if not improving
4. **Post-incident**: Root cause analysis

---

## Troubleshooting

### High Error Rate

**Diagnosis Steps**:

1. **Check Sentry for error patterns**
```
Query: event.type:error tags.component:AuthContext
Group by: error.type
Time range: Last 1 hour
```

2. **Identify most common errors**
- Check error messages
- Review stack traces
- Identify affected user segments

3. **Check correlations**
- Does it correlate with deployment?
- Specific browser/device?
- Specific user type?

---

### Slow Performance

**Diagnosis Steps**:

1. **Check performance traces in Sentry**
```
Query: transaction.op:navigation transaction:/login
Sort by: duration DESC
Limit: 100
```

2. **Identify bottlenecks**
- API response time
- Frontend initialization time
- Network latency
- Database queries

3. **Compare with baseline**
```bash
# Generate performance comparison report
node scripts/compare-performance.js --baseline 2025-10-08 --current now
```

---

### Low Re-init Skip Rate

**Diagnosis**: Fix may not be working correctly

**Steps**:

1. **Check feature flag**
```bash
curl -s https://app.engarde.com/ | grep "ENABLE_AUTH_INIT_FIX"
```

2. **Review application logs**
```bash
grep "justLoggedIn" /var/log/frontend/app.log | tail -50
```

3. **Check Sentry for re-initialization events**
```
Query: message:"Skipping re-initialization after successful login"
Expected: High count (80-95% of logins)
```

---

## Monitoring Checklist

### Daily Monitoring (During Rollout)

- [ ] Check login success rate
- [ ] Review error trends
- [ ] Verify performance metrics
- [ ] Check alert status
- [ ] Review support tickets
- [ ] Update stakeholders

### Weekly Monitoring (Post-Rollout)

- [ ] Generate weekly metrics report
- [ ] Compare with baseline
- [ ] Review optimization opportunities
- [ ] Update documentation
- [ ] Team review meeting

---

## Additional Resources

- [Sentry Documentation](https://docs.sentry.io/)
- [DataDog RUM Documentation](https://docs.datadoghq.com/real_user_monitoring/)
- [Deployment Guide](./DEPLOYMENT_GUIDE.md)
- [Rollback Procedure](./ROLLBACK_PROCEDURE.md)
- [Incident Response](./INCIDENT_RESPONSE.md)

---

**Document Version**: 1.0
**Last Updated**: 2025-10-09
**Next Review**: After 100% rollout
