# Walker Agent Feedback Collection - Deployment Checklist

## Pre-Deployment Checklist

### Environment Setup
- [ ] `DATABASE_PUBLIC_URL` environment variable is set
- [ ] Database user has CREATE, ALTER, INSERT, UPDATE permissions
- [ ] Backend service can connect to database
- [ ] Frontend can reach backend API endpoints

### Code Review
- [ ] All files present (see File Locations section)
- [ ] No merge conflicts
- [ ] Code follows project style guidelines
- [ ] TypeScript types are correct
- [ ] Python type hints are present

---

## Database Deployment

### Step 1: Backup Current Database
```bash
# Create backup before migration
pg_dump $DATABASE_PUBLIC_URL > backup_before_feedback_$(date +%Y%m%d_%H%M%S).sql
```

### Step 2: Run Migration
```bash
# Make script executable
chmod +x run-feedback-migration.sh

# Run migration
./run-feedback-migration.sh
```

Or manually:
```bash
psql $DATABASE_PUBLIC_URL -f database-setup/walker_feedback_enhancements.sql
```

### Step 3: Verify Migration
```sql
-- Check new columns exist
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'chat_sessions'
AND column_name IN ('feedback_requested_at', 'feedback_submitted_at', 'conversation_rating', 'conversation_feedback');

-- Expected: 4 rows returned

-- Check views exist
SELECT table_name FROM information_schema.views
WHERE table_name IN ('conversation_feedback_metrics', 'agent_performance_with_feedback');

-- Expected: 2 rows returned

-- Check functions exist
SELECT proname FROM pg_proc
WHERE proname IN ('should_prompt_feedback', 'request_conversation_feedback', 'link_satisfaction_to_conversation');

-- Expected: 3 rows returned

-- Check triggers exist
SELECT trigger_name, event_object_table
FROM information_schema.triggers
WHERE trigger_name IN ('trigger_request_conversation_feedback', 'trigger_link_satisfaction_to_conversation');

-- Expected: 2 rows returned
```

### Step 4: Test Database Functions
```sql
-- Test eligibility check function
-- Replace with actual tenant_id and conversation_id from your database
SELECT * FROM should_prompt_feedback(
    'your-tenant-id'::varchar,
    'your-conversation-id'::varchar
);

-- Expected: Returns row with should_prompt, reason, etc.
```

**Database Deployment**: ✅ Complete

---

## Backend Deployment

### Step 1: Update Backend Code

Edit `production-backend/app/main.py`:

```python
# Add import at top of file
from app.routers import walker_feedback

# Add router registration (after other routers)
app.include_router(walker_feedback.router)
```

### Step 2: Verify Backend Files
```bash
# Check that new router exists
ls -la production-backend/app/routers/walker_feedback.py

# Check existing satisfaction router (used by new router)
ls -la production-backend/app/routers/customer_satisfaction.py
```

### Step 3: Install Dependencies (if any new ones)
```bash
cd production-backend
pip install -r requirements.txt  # Should have no new dependencies
```

### Step 4: Restart Backend
```bash
# Development
cd production-backend
uvicorn app.main:app --reload

# Production (Docker)
docker-compose restart backend

# Production (Railway/other)
# Deploy via your CI/CD pipeline
```

### Step 5: Verify Backend is Running
```bash
# Check health endpoint
curl http://localhost:8000/health

# Check API docs
curl http://localhost:8000/docs

# Look for new endpoints:
# - POST /api/walker/feedback/conversation/should-prompt
# - POST /api/walker/feedback/conversation/submit
# - POST /api/walker/feedback/conversation/log-request
# - GET  /api/walker/feedback/conversation/{id}/stats
# - GET  /api/walker/feedback/analytics/overview
```

### Step 6: Test Backend Endpoints

#### Test 1: Check Eligibility
```bash
curl -X POST http://localhost:8000/api/walker/feedback/conversation/should-prompt \
  -H "Content-Type: application/json" \
  -d '{
    "conversation_id": "test-conversation-id",
    "tenant_id": "test-tenant-id"
  }'

# Expected: JSON response with should_prompt, reason, etc.
```

#### Test 2: Submit Feedback
```bash
curl -X POST http://localhost:8000/api/walker/feedback/conversation/submit \
  -H "Content-Type: application/json" \
  -d '{
    "conversation_id": "test-conversation-id",
    "rating": 5,
    "comment": "Test feedback",
    "channel": "web_chat"
  }'

# Expected: { "success": true, "feedback_id": "...", ... }
```

**Backend Deployment**: ✅ Complete

---

## Frontend Deployment

### Step 1: Verify Frontend Files
```bash
# Check new files exist
ls -la production-frontend/components/walker/ConversationFeedbackModal.tsx
ls -la production-frontend/components/walker/ChatWithFeedback.tsx
ls -la production-frontend/hooks/useConversationFeedback.ts
```

### Step 2: Install Dependencies (if any new ones)
```bash
cd production-frontend
npm install  # Should have no new dependencies (uses existing Headless UI, Heroicons)
```

### Step 3: Choose Integration Method

**Option A: Use Complete Component** (Recommended for new implementations)
```tsx
// In your page/component file
import ChatWithFeedback from '@/components/walker/ChatWithFeedback';

export default function ChatPage() {
  return (
    <ChatWithFeedback
      conversationId={currentConversationId}
      agentName="Walker Analytics Agent"
      sessionType="analytics"
      tenantId={currentUser.tenantId}
      onConversationEnd={() => {
        console.log('Conversation ended');
      }}
    />
  );
}
```

**Option B: Integrate into Existing Chat** (For existing chat implementations)
```tsx
// In your existing chat component
import ConversationFeedbackModal from '@/components/walker/ConversationFeedbackModal';
import { useConversationFeedback } from '@/hooks/useConversationFeedback';

// Add to your component
const {
  isFeedbackModalOpen,
  closeFeedbackModal,
  markFeedbackSubmitted
} = useConversationFeedback({
  conversationId,
  isConversationActive,
  autoCheck: true
});

// Add to JSX (near end of component)
<ConversationFeedbackModal
  isOpen={isFeedbackModalOpen}
  onClose={closeFeedbackModal}
  conversationId={conversationId}
  agentName="Your Agent Name"
  sessionType="analytics"
  onSubmitSuccess={markFeedbackSubmitted}
/>
```

### Step 4: Build Frontend
```bash
cd production-frontend
npm run build

# Check for build errors
# Expected: Build completes successfully
```

### Step 5: Deploy Frontend
```bash
# Development
npm run dev

# Production (Docker)
docker-compose restart frontend

# Production (Vercel/Netlify/Railway)
# Deploy via your CI/CD pipeline
```

### Step 6: Verify Frontend is Running
```bash
# Check frontend is accessible
curl http://localhost:3000

# Open in browser and verify:
# - No console errors
# - Components load correctly
# - Chat interface works
```

**Frontend Deployment**: ✅ Complete

---

## End-to-End Testing

### Test 1: Happy Path (Complete Feedback Flow)

1. **Start Conversation**
   - [ ] Navigate to Walker Agent chat
   - [ ] Verify chat interface loads
   - [ ] No console errors

2. **Exchange Messages**
   - [ ] Send user message
   - [ ] Receive agent response
   - [ ] Repeat at least 2 times (4+ total messages)

3. **End Conversation**
   - [ ] Click "End Conversation" button
   - [ ] Verify conversation state updates (is_active = false)

4. **Feedback Modal Appears**
   - [ ] Modal automatically opens within 1-2 seconds
   - [ ] Modal displays correctly
   - [ ] All form fields present

5. **Submit Feedback**
   - [ ] Click on 5 stars for rating
   - [ ] Optionally fill other fields
   - [ ] Click "Submit Feedback"
   - [ ] Success message appears
   - [ ] Modal auto-closes after 2 seconds

6. **Verify Database**
   ```sql
   SELECT
     cs.id,
     cs.conversation_rating,
     cs.conversation_feedback,
     cs.feedback_requested_at,
     cs.feedback_submitted_at,
     csf.rating,
     csf.comment
   FROM chat_sessions cs
   LEFT JOIN customer_satisfaction_feedback csf
     ON csf.conversation_id = cs.id::uuid
   WHERE cs.id = 'your-conversation-id';
   ```
   - [ ] conversation_rating = 5
   - [ ] feedback_submitted_at is set
   - [ ] customer_satisfaction_feedback record created

### Test 2: Skip Feedback

1. **Start and end conversation** (as above)
2. **Modal appears**
3. **Click "Skip" button**
   - [ ] Modal closes immediately
   - [ ] No errors in console
   - [ ] No database record created

### Test 3: Low Rating Flow

1. **Start and end conversation** (as above)
2. **Click 2 stars**
   - [ ] Issue category dropdown appears
   - [ ] All issue categories listed
3. **Select issue and submit**
   - [ ] Submission succeeds
   - [ ] issue_category saved to database

### Test 4: Spam Prevention

1. **Complete feedback once** (as Test 1)
2. **Try to submit again**
   - Method 1: Manually call `/should-prompt` API
   ```bash
   curl -X POST http://localhost:8000/api/walker/feedback/conversation/should-prompt \
     -H "Content-Type: application/json" \
     -d '{"conversation_id": "same-conversation-id"}'
   ```
   - [ ] Response: `should_prompt = false`
   - [ ] Reason: "Feedback already submitted"

3. **Try via UI** (if you added manual trigger button)
   - [ ] Modal doesn't appear
   - [ ] Console shows eligibility reason

### Test 5: Insufficient Messages

1. **Start conversation**
2. **Send only 1-2 messages** (less than 4 total)
3. **End conversation**
   - [ ] Modal does NOT appear
   - [ ] Console log shows: "Conversation too short"

### Test 6: Analytics

```sql
-- Check overall stats
SELECT * FROM conversation_feedback_metrics;

-- Expected: Your test feedback is included

-- Check agent performance
SELECT * FROM agent_performance_with_feedback
WHERE agent_name LIKE '%Walker%';

-- Expected: Shows feedback metrics for your agent
```

**End-to-End Testing**: ✅ Complete

---

## Performance Testing

### Database Performance
```sql
-- Test index usage
EXPLAIN ANALYZE
SELECT * FROM should_prompt_feedback('tenant-id', 'conversation-id');

-- Expected: Uses indexes, execution time < 50ms

-- Test view performance
EXPLAIN ANALYZE
SELECT * FROM conversation_feedback_metrics
WHERE tenant_id = 'your-tenant-id';

-- Expected: Uses indexes, execution time < 100ms
```

### API Performance
```bash
# Test endpoint response time
time curl -X POST http://localhost:8000/api/walker/feedback/conversation/should-prompt \
  -H "Content-Type: application/json" \
  -d '{"conversation_id": "test-id"}'

# Expected: < 200ms
```

### Frontend Performance
- [ ] Modal opens quickly (< 1 second)
- [ ] No lag when typing in comment field
- [ ] Smooth star rating animations
- [ ] Fast submission (< 2 seconds)

**Performance Testing**: ✅ Complete

---

## Security Testing

### Authentication
```bash
# Test that analytics endpoints require auth
curl -X GET http://localhost:8000/api/walker/feedback/analytics/overview

# Expected: 401 Unauthorized (or redirect to login)

# Test that submit endpoint works without auth (anonymous)
curl -X POST http://localhost:8000/api/walker/feedback/conversation/submit \
  -H "Content-Type: application/json" \
  -d '{"conversation_id": "test", "rating": 5}'

# Expected: 200 OK (anonymous feedback allowed)
```

### Tenant Isolation
```sql
-- Create test data for two different tenants
-- Verify tenant A cannot see tenant B's feedback

SELECT * FROM should_prompt_feedback('tenant-a-id', 'tenant-b-conversation-id');

-- Expected: Returns "Conversation not found"
```

### Input Validation
```bash
# Test invalid rating (> 5)
curl -X POST http://localhost:8000/api/walker/feedback/conversation/submit \
  -H "Content-Type: application/json" \
  -d '{"conversation_id": "test", "rating": 10}'

# Expected: 422 Validation Error

# Test invalid rating (< 1)
curl -X POST http://localhost:8000/api/walker/feedback/conversation/submit \
  -H "Content-Type: application/json" \
  -d '{"conversation_id": "test", "rating": 0}'

# Expected: 422 Validation Error
```

**Security Testing**: ✅ Complete

---

## Monitoring Setup

### Backend Logs
```bash
# Monitor backend logs for feedback-related activity
tail -f production-backend/logs/app.log | grep feedback

# Look for:
# - Feedback submission events
# - Eligibility checks
# - Any errors
```

### Database Monitoring
```sql
-- Create monitoring query for daily stats
SELECT
  DATE(created_at) as date,
  COUNT(*) as feedback_count,
  ROUND(AVG(rating), 2) as avg_rating
FROM customer_satisfaction_feedback
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Set up as scheduled query or dashboard widget
```

### Error Tracking
```python
# Verify Sentry/error tracking includes new endpoints
# Check that exceptions are caught and logged
```

**Monitoring Setup**: ✅ Complete

---

## Rollback Plan

### If Issues Occur During Deployment

#### Rollback Database
```bash
# Restore from backup
psql $DATABASE_PUBLIC_URL < backup_before_feedback_YYYYMMDD_HHMMSS.sql

# Or remove specific changes
psql $DATABASE_PUBLIC_URL -c "
ALTER TABLE chat_sessions DROP COLUMN IF EXISTS feedback_requested_at;
ALTER TABLE chat_sessions DROP COLUMN IF EXISTS feedback_submitted_at;
ALTER TABLE chat_sessions DROP COLUMN IF EXISTS conversation_rating;
ALTER TABLE chat_sessions DROP COLUMN IF EXISTS conversation_feedback;
DROP VIEW IF EXISTS conversation_feedback_metrics;
DROP VIEW IF EXISTS agent_performance_with_feedback;
DROP FUNCTION IF EXISTS should_prompt_feedback;
DROP FUNCTION IF EXISTS request_conversation_feedback;
DROP FUNCTION IF EXISTS link_satisfaction_to_conversation;
"
```

#### Rollback Backend
```python
# Remove from production-backend/app/main.py
# app.include_router(walker_feedback.router)

# Restart backend
docker-compose restart backend
```

#### Rollback Frontend
```bash
# Revert changes to chat components
git revert <commit-hash>

# Rebuild and deploy
npm run build
```

---

## Post-Deployment Monitoring

### Week 1 Checklist

#### Daily Checks
- [ ] Monitor feedback submission rate
- [ ] Check for any error logs
- [ ] Verify database performance
- [ ] Review user feedback comments

#### Metrics to Track
```sql
-- Daily feedback volume
SELECT
  DATE(created_at) as date,
  COUNT(*) as submissions,
  ROUND(AVG(rating), 2) as avg_rating
FROM customer_satisfaction_feedback
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at);

-- Response rate trend
SELECT
  DATE(feedback_requested_at) as date,
  COUNT(*) FILTER (WHERE feedback_requested_at IS NOT NULL) as requested,
  COUNT(*) FILTER (WHERE feedback_submitted_at IS NOT NULL) as submitted,
  ROUND(
    COUNT(*) FILTER (WHERE feedback_submitted_at IS NOT NULL)::NUMERIC /
    COUNT(*) FILTER (WHERE feedback_requested_at IS NOT NULL) * 100,
    2
  ) as response_rate
FROM chat_sessions
WHERE feedback_requested_at > NOW() - INTERVAL '7 days'
GROUP BY DATE(feedback_requested_at);
```

### Week 2-4: Optimization

- [ ] Review common issues in low-rating feedback
- [ ] Analyze response rate by agent type
- [ ] Identify any UX improvements needed
- [ ] Consider A/B testing different prompts

### Month 1: Analysis

- [ ] Generate comprehensive analytics report
- [ ] Present findings to stakeholders
- [ ] Plan agent improvements based on feedback
- [ ] Consider implementing Phase 2 features

---

## Success Criteria

### Deployment is Successful When:

✅ Database migration completed without errors
✅ All triggers and functions working
✅ Backend API endpoints responding correctly
✅ Frontend modal displays and functions properly
✅ End-to-end test passes (conversation → feedback → database)
✅ No console errors in browser
✅ No errors in backend logs
✅ Performance metrics are acceptable (<100ms DB, <200ms API)
✅ Security tests pass
✅ Analytics views return data

### Production Ready When:

✅ Response rate > 20% (aim for 30-50%)
✅ Average rating tracked (aim for 4.0+)
✅ No P0/P1 bugs reported
✅ Monitoring dashboards set up
✅ Team trained on using analytics
✅ Documentation reviewed and approved

---

## Deployment Sign-Off

### Database Team
- [ ] Migration tested in staging
- [ ] Performance impact assessed
- [ ] Backup verified
- [ ] Rollback plan tested
- Signed: _________________ Date: _______

### Backend Team
- [ ] Code reviewed
- [ ] API tested
- [ ] Error handling verified
- [ ] Documentation updated
- Signed: _________________ Date: _______

### Frontend Team
- [ ] Components tested
- [ ] Browser compatibility checked
- [ ] Accessibility verified
- [ ] UX approved
- Signed: _________________ Date: _______

### QA Team
- [ ] All tests passed
- [ ] Edge cases covered
- [ ] Performance acceptable
- [ ] Security validated
- Signed: _________________ Date: _______

### Product Owner
- [ ] Acceptance criteria met
- [ ] User stories completed
- [ ] Analytics plan approved
- [ ] Go-live approved
- Signed: _________________ Date: _______

---

## Ready to Deploy! 🚀

Once all checkboxes are complete and sign-offs obtained, you're ready to deploy the Walker Agent Feedback Collection system to production!

**Deployment Date**: __________
**Deployed By**: __________
**Deployment Notes**: ___________________________________
