# Walker Agent Feedback - Quick Start Guide

## 3-Step Implementation

### Step 1: Database Setup (5 minutes)

Run the SQL migration:

```bash
psql $DATABASE_PUBLIC_URL -f database-setup/walker_feedback_enhancements.sql
```

Verify:
```sql
SELECT * FROM should_prompt_feedback('tenant-id', 'conversation-id');
```

### Step 2: Backend Setup (2 minutes)

Add to `production-backend/app/main.py`:

```python
from app.routers import walker_feedback

app.include_router(walker_feedback.router)
```

Restart backend:
```bash
cd production-backend && python -m uvicorn app.main:app --reload
```

### Step 3: Frontend Setup (5 minutes)

Replace your chat component with the integrated version:

```tsx
import ChatWithFeedback from '@/components/walker/ChatWithFeedback';

export default function ChatPage() {
  return (
    <ChatWithFeedback
      conversationId={sessionId}
      agentName="Walker Agent"
      sessionType="analytics"
      tenantId={currentTenant.id}
    />
  );
}
```

**Done!** Feedback will now automatically appear when conversations end.

---

## Quick Test

1. Start a conversation
2. Exchange at least 4 messages
3. End the conversation
4. Feedback modal should appear automatically
5. Submit a rating
6. Check database:

```sql
SELECT conversation_rating, conversation_feedback
FROM chat_sessions
WHERE id = 'your-conversation-id';
```

---

## API Endpoints

| Endpoint | Purpose |
|----------|---------|
| `POST /api/walker/feedback/conversation/should-prompt` | Check if feedback should be shown |
| `POST /api/walker/feedback/conversation/submit` | Submit feedback |
| `POST /api/walker/feedback/conversation/log-request` | Log that prompt was shown |
| `GET /api/walker/feedback/analytics/overview` | Get feedback analytics |

---

## Key Files

- **Migration**: `database-setup/walker_feedback_enhancements.sql`
- **Backend**: `production-backend/app/routers/walker_feedback.py`
- **Component**: `production-frontend/components/walker/ConversationFeedbackModal.tsx`
- **Hook**: `production-frontend/hooks/useConversationFeedback.ts`
- **Example**: `production-frontend/components/walker/ChatWithFeedback.tsx`

---

## Troubleshooting

**Modal doesn't appear?**
```javascript
const { eligibilityReason } = useConversationFeedback({...});
console.log(eligibilityReason); // Check why not eligible
```

**Submission fails?**
```bash
# Check API
curl -X POST http://localhost:8000/api/walker/feedback/conversation/submit \
  -H "Content-Type: application/json" \
  -d '{"conversation_id": "...", "rating": 5}'
```

**Database issues?**
```sql
-- Check conversation state
SELECT id, is_active, message_count, feedback_requested_at
FROM chat_sessions
WHERE id = 'your-conversation-id';
```

---

## Analytics Query

Quick feedback summary:

```sql
SELECT
  COUNT(*) as total_conversations,
  COUNT(feedback_submitted_at) as feedback_count,
  ROUND(AVG(conversation_rating), 2) as avg_rating
FROM chat_sessions
WHERE created_at > NOW() - INTERVAL '7 days'
AND is_active = false;
```

---

For complete documentation, see: `WALKER_FEEDBACK_IMPLEMENTATION_GUIDE.md`
