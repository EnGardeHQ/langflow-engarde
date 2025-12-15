# EnGarde Frontend - Incident Response Guide
## AuthContext Fix Deployment Incident Response

This guide provides procedures for responding to incidents during the AuthContext fix deployment.

---

## Table of Contents

1. [Incident Severity Levels](#incident-severity-levels)
2. [Incident Response Team](#incident-response-team)
3. [Response Procedures](#response-procedures)
4. [Communication Templates](#communication-templates)
5. [Post-Incident Process](#post-incident-process)

---

## Incident Severity Levels

### SEV-1: Critical

**Impact**: Complete service outage or severe degradation

**Examples**:
- Login completely broken for all users
- Application not loading
- Data loss or corruption
- Security breach

**Response Time**: < 5 minutes
**Escalation**: Immediate - Page CTO and engineering lead
**Communication**: Every 15 minutes until resolved

---

### SEV-2: High

**Impact**: Major feature broken, affecting many users

**Examples**:
- Login success rate < 85%
- Dashboard not loading for some users
- Critical workflow broken
- Performance degraded > 200%

**Response Time**: < 15 minutes
**Escalation**: Engineering lead within 15 minutes
**Communication**: Every 30 minutes until resolved

---

### SEV-3: Medium

**Impact**: Moderate issue affecting some users

**Examples**:
- Login success rate 85-90%
- Slow performance (2-5s response times)
- Non-critical feature broken
- Elevated error rate (2-5%)

**Response Time**: < 1 hour
**Escalation**: Engineering team notification
**Communication**: Hourly updates

---

### SEV-4: Low

**Impact**: Minor issue, limited user impact

**Examples**:
- Cosmetic issues
- Performance slightly degraded
- Low error rate (1-2%)
- Edge case bugs

**Response Time**: < 4 hours
**Escalation**: Bug report, address in sprint
**Communication**: Daily summary

---

## Incident Response Team

### Roles and Responsibilities

#### Incident Commander

**Primary**: On-call engineer
**Backup**: Engineering lead

**Responsibilities**:
- Assess incident severity
- Coordinate response team
- Make rollback decisions
- Lead incident communication
- Declare incident resolved

---

#### Technical Lead

**Primary**: Engineering lead
**Backup**: Senior engineer

**Responsibilities**:
- Technical investigation
- Implement fixes or workarounds
- Review rollback decisions
- Post-incident analysis

---

#### Communications Lead

**Primary**: Product manager
**Backup**: Customer success manager

**Responsibilities**:
- Internal stakeholder updates
- Customer communication
- Status page updates
- Social media monitoring

---

#### Support Lead

**Primary**: Support manager
**Backup**: Senior support engineer

**Responsibilities**:
- Monitor support tickets
- Triage user reports
- Provide workarounds to users
- Track affected customers

---

## Response Procedures

### SEV-1 Response Procedure

#### Phase 1: Detection and Assessment (0-5 minutes)

1. **Detect incident**
   - Monitoring alert triggered
   - Support ticket influx
   - User reports

2. **Assess severity**
   ```bash
   # Quick health check
   bash scripts/health-check.sh

   # Check key metrics
   curl -s https://app.engarde.com/api/metrics | jq .
   ```

3. **Declare SEV-1**
   ```bash
   # Post to Slack
   /incident declare sev-1 "Login completely broken"
   ```

4. **Page response team**
   - PagerDuty: engarde-critical
   - Slack: @channel in #engarde-incidents
   - Phone: Call engineering lead

---

#### Phase 2: Immediate Response (5-15 minutes)

1. **Establish war room**
   - Zoom/Slack huddle
   - Designate incident commander
   - Assign roles

2. **Start incident timeline**
   ```markdown
   ## Incident Timeline

   **10:05** - Monitoring alert: Login success rate 0%
   **10:07** - SEV-1 declared
   **10:08** - War room established
   **10:10** - Investigating...
   ```

3. **Quick diagnostics**
   ```bash
   # Check application status
   docker ps | grep engarde_frontend

   # Check logs
   docker logs engarde_frontend --tail 100

   # Check database
   psql -U engarde_user -d engarde -c "SELECT 1;"

   # Check API connectivity
   curl -f https://api.engarde.com/health
   ```

4. **Rollback decision**
   - If unclear cause → **ROLLBACK IMMEDIATELY**
   - If quick fix available → Attempt fix (5 min max)
   - If no improvement → **ROLLBACK**

5. **Execute rollback**
   ```bash
   cd /Users/cope/EnGardeHQ
   bash scripts/rollback.sh "sev1_critical_incident"
   ```

---

#### Phase 3: Communication (Concurrent)

1. **Internal communication**
   ```
   Slack #engarde-incidents:
   ---
   🔴 SEV-1 INCIDENT DECLARED

   **Summary**: Login functionality completely broken
   **Impact**: All users unable to log in
   **Started**: 10:05 AM PST
   **Status**: Rollback in progress

   **War Room**: [Zoom Link]
   **Incident Commander**: @john.doe

   Updates every 15 minutes.
   ---
   ```

2. **Status page update**
   ```
   Title: Service Disruption - Login Issues
   Status: Investigating
   Message: We are aware of login issues affecting all users.
   Our team is actively working on a resolution. We will
   provide updates every 15 minutes.
   ```

3. **Customer communication** (if > 15 min)
   - Email to affected customers
   - In-app notification
   - Social media acknowledgment

---

#### Phase 4: Resolution and Recovery (15-30 minutes)

1. **Verify rollback success**
   ```bash
   bash scripts/verify.sh production https://app.engarde.com
   ```

2. **Monitor recovery**
   - Login success rate returns to > 95%
   - Error rate drops to < 1%
   - Support ticket rate normalizes

3. **Declare resolved**
   ```
   Slack #engarde-incidents:
   ---
   ✅ INCIDENT RESOLVED

   **Duration**: 25 minutes (10:05 - 10:30 AM PST)
   **Resolution**: Rollback completed, service restored
   **Impact**: ~1,500 users affected

   **Next Steps**:
   - Root cause analysis: Tomorrow 9 AM
   - Postmortem document: EOD today
   - Customer communication: In progress

   Thank you to the response team!
   ---
   ```

4. **Update status page**
   ```
   Status: Resolved
   Message: The login issue has been resolved. All systems
   are operating normally. We apologize for the inconvenience.
   A detailed postmortem will be published within 48 hours.
   ```

---

### SEV-2/3 Response Procedure (Abbreviated)

**Similar to SEV-1 but with adjusted timelines**:

- SEV-2: 15-minute detection, 30-minute updates, 1-hour resolution target
- SEV-3: 1-hour detection, hourly updates, 4-hour resolution target

**Key difference**: More time for investigation before rollback

---

## Communication Templates

### Internal Alert Template

```markdown
**Severity**: [SEV-1 / SEV-2 / SEV-3 / SEV-4]
**Title**: [Brief description]
**Impact**: [User impact description]
**Started**: [Timestamp]
**Status**: [Investigating / Identified / Resolving / Resolved]

**Symptoms**:
- [Symptom 1]
- [Symptom 2]

**Current Actions**:
- [Action 1]
- [Action 2]

**Updates**: Every [15 / 30 / 60] minutes

**War Room**: [Link if applicable]
**Incident Commander**: @[username]
**Dashboard**: [Monitoring dashboard link]
```

---

### Customer Communication Template

**Subject**: Service Disruption - [Date]

```
Dear EnGarde User,

We experienced a service disruption today between [START TIME] and
[END TIME] that affected [FUNCTIONALITY].

What happened:
[Brief, non-technical explanation]

Impact:
- Affected users: [NUMBER or PERCENTAGE]
- Duration: [DURATION]
- Data safety: [Confirm no data loss]

What we did:
[Brief explanation of resolution]

What we're doing to prevent this:
[Prevention measures]

We sincerely apologize for any inconvenience this caused. If you
continue to experience issues or have questions, please contact
support@engarde.com.

Best regards,
The EnGarde Team
```

---

### Status Page Template

**Investigating**:
```
We are investigating reports of [ISSUE]. Our team is actively
working to identify the cause. We will provide updates as more
information becomes available.

Posted: [TIMESTAMP]
```

**Identified**:
```
We have identified the cause of [ISSUE] and are implementing a fix.
We expect the issue to be resolved within [TIMEFRAME].

Posted: [TIMESTAMP]
```

**Monitoring**:
```
A fix has been implemented and we are monitoring the results. All
systems appear to be operating normally.

Posted: [TIMESTAMP]
```

**Resolved**:
```
The issue has been fully resolved. All systems are operating normally.
We apologize for the inconvenience. A detailed postmortem will be
available within 48 hours.

Posted: [TIMESTAMP]
```

---

### Social Media Template

**Twitter/X**:
```
We're aware of login issues affecting some users. Our team is
actively investigating. Follow this thread for updates.

[Time stamp]
```

**Update**:
```
Update: We've identified the issue and implemented a fix. Services
are being restored. Thank you for your patience.

[Time stamp]
```

**Resolved**:
```
All systems are now operating normally. We apologize for the
disruption and appreciate your patience. Details: [link to blog post]

[Time stamp]
```

---

## Post-Incident Process

### Immediate (< 2 hours after resolution)

1. **Document timeline**
   - All key events
   - Actions taken
   - Decisions made

2. **Collect metrics**
   ```bash
   # Generate incident report
   node scripts/generate-incident-report.js \
     --start "[START_TIME]" \
     --end "[END_TIME]"
   ```

3. **Preserve evidence**
   - Save logs
   - Export metrics
   - Screenshot dashboards
   - Save chat transcripts

---

### Short-term (< 24 hours)

1. **Draft incident report**

```markdown
# Incident Report: [TITLE]

**Incident ID**: INC-2025-XXX
**Severity**: SEV-X
**Date**: [DATE]
**Duration**: [DURATION]
**Impact**: [USER IMPACT]

## Executive Summary
[2-3 sentence summary]

## Timeline
- **[TIME]** - [Event]
- **[TIME]** - [Event]
- **[TIME]** - [Event]

## Root Cause
[Detailed technical explanation]

## Impact Analysis
- **Users Affected**: [NUMBER]
- **Duration**: [TIME]
- **Support Tickets**: [NUMBER]
- **Revenue Impact**: [$AMOUNT or N/A]

## Resolution
[What was done to resolve]

## Contributing Factors
- [Factor 1]
- [Factor 2]

## What Went Well
- [Positive 1]
- [Positive 2]

## What Could Be Improved
- [Improvement 1]
- [Improvement 2]

## Action Items
| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
| [Action 1] | @owner | [Date] | Open |
| [Action 2] | @owner | [Date] | Open |

## Prevention Measures
[Long-term prevention steps]
```

2. **Customer communication**
   - Send follow-up email
   - Offer compensation if applicable
   - Provide direct support contact

---

### Medium-term (< 48 hours)

1. **Postmortem meeting**

**Agenda**:
- Timeline review (15 min)
- Root cause analysis (20 min)
- What went well (10 min)
- What could improve (15 min)
- Action items assignment (10 min)

**Attendees**:
- Incident response team
- Engineering leadership
- Product management
- Support team lead

2. **Publish postmortem**
   - Internal wiki
   - Public blog post (if significant)
   - Status page update

3. **Update runbooks**
   - Document new procedures
   - Update incident response guide
   - Improve monitoring alerts

---

### Long-term (< 1 week)

1. **Complete action items**
   - Implement fixes
   - Add tests
   - Update documentation

2. **Review and improve**
   - Update deployment procedures
   - Enhance monitoring
   - Improve alerting
   - Add automation

3. **Team retrospective**
   - Share learnings
   - Celebrate what went well
   - Commit to improvements

---

## Incident Response Checklist

### During Incident

- [ ] Severity assessed and declared
- [ ] Response team notified
- [ ] Incident commander assigned
- [ ] War room established (if SEV-1/2)
- [ ] Timeline documentation started
- [ ] Initial diagnostics completed
- [ ] Rollback decision made
- [ ] Internal communication sent
- [ ] Status page updated
- [ ] Customer communication sent (if applicable)

### After Resolution

- [ ] Resolution verified
- [ ] Monitoring confirms stability
- [ ] Incident declared resolved
- [ ] Internal notification sent
- [ ] Status page updated to resolved
- [ ] Customer follow-up sent
- [ ] Logs and metrics preserved
- [ ] Incident report drafted
- [ ] Postmortem meeting scheduled
- [ ] Action items assigned

### Follow-up

- [ ] Postmortem published
- [ ] Action items completed
- [ ] Runbooks updated
- [ ] Monitoring improved
- [ ] Team retrospective held

---

## Emergency Contacts

### Critical Response Team

| Role | Primary | Backup | Contact |
|------|---------|--------|---------|
| Incident Commander | On-call Engineer | Engineering Lead | PagerDuty |
| Technical Lead | Engineering Lead | Senior Engineer | [Phone] |
| Communications | Product Manager | CS Manager | [Phone] |
| Executive Escalation | CTO | CEO | [Phone] |

### External Contacts

| Service | Contact | Purpose |
|---------|---------|---------|
| Cloud Provider (AWS/GCP) | Support Portal | Infrastructure issues |
| CDN Provider | Support Email | CDN issues |
| Database Provider | Support Phone | Database issues |
| Monitoring (Sentry) | support@sentry.io | Monitoring issues |

---

## Incident Metrics

Track these metrics for continuous improvement:

- **MTTD** (Mean Time To Detect): How quickly we detect incidents
- **MTTR** (Mean Time To Resolve): How quickly we resolve incidents
- **MTTC** (Mean Time To Communicate): How quickly we communicate
- **Incident Frequency**: Number of incidents per month
- **User Impact**: Number of users affected per incident

**Monthly Review**: Analyze trends and improve processes

---

## Additional Resources

- [Deployment Guide](./DEPLOYMENT_GUIDE.md)
- [Rollback Procedure](./ROLLBACK_PROCEDURE.md)
- [Monitoring Guide](./MONITORING_GUIDE.md)
- [On-Call Runbook](./ONCALL_RUNBOOK.md)
- [PagerDuty Escalation Policy](https://engarde.pagerduty.com/escalation_policies)

---

**Document Version**: 1.0
**Last Updated**: 2025-10-09
**Next Review**: After any SEV-1 or SEV-2 incident
