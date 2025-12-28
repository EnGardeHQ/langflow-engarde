# Walker Agents Campaign Suggestion System

## Overview

The Walker Agents Campaign Suggestion System is En Garde's unified notification and recommendation delivery infrastructure that enables autonomous AI agents (Walker Agents) across all microservices to proactively deliver actionable marketing insights and campaign recommendations to users via email, WhatsApp, and in-platform chat.

## Architecture

```
┌───────────────────────────────────────────────────────────────┐
│                    Walker Agent Microservices                  │
├───────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │   OnSide     │  │   Sankore    │  │  MadanSara   │        │
│  │              │  │              │  │              │        │
│  │ • SEO Agent  │  │ • Paid Ads   │  │ • Audience   │        │
│  │ • Content    │  │   Agent      │  │   Intel      │        │
│  │   Agent      │  │              │  │   Agent      │        │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘        │
│         │                  │                  │                 │
│         └──────────────────┼──────────────────┘                │
│                            │                                    │
│                            │ POST /walker-agent/suggestions    │
│                            │ {                                 │
│                            │   "agent_type": "...",            │
│                            │   "suggestions": [...],           │
│                            │   "priority": "high"              │
│                            │ }                                 │
└────────────────────────────┼──────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────┐
│      En Garde Production Backend - Walker Agent API         │
│                                                              │
│  POST /api/v1/walker-agents/campaign-suggestions           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Campaign Suggestion Controller                       │  │
│  │  - Validates Walker Agent auth token                  │  │
│  │  - Stores suggestion in PostgreSQL                    │  │
│  │  - Enriches with user preferences                     │  │
│  │  - Routes to notification dispatcher                  │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Multi-Channel Notification Dispatcher               │  │
│  │  - Determines user's preferred channels              │  │
│  │  - Formats suggestions per channel                   │  │
│  │  - Handles delivery retries                          │  │
│  │  - Tracks notification status                        │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────┬─────────────────────────────────────────┘
                     │
        ┌────────────┼────────────┬────────────────┐
        ▼            ▼            ▼                ▼
  ┌──────────┐ ┌──────────┐ ┌──────────┐   ┌──────────┐
  │  Email   │ │ WhatsApp │ │   Chat   │   │   Push   │
  │ Service  │ │ Service  │ │ Service  │   │ Notif.   │
  │          │ │          │ │          │   │          │
  │  Brevo   │ │  Twilio  │ │ WebSocket│   │ Firebase │
  └──────────┘ └──────────┘ └──────────┘   └──────────┘
        │            │            │                │
        └────────────┴────────────┴────────────────┘
                     │
                     ▼
            ┌────────────────┐
            │  End User      │
            │  - Email inbox │
            │  - WhatsApp    │
            │  - Platform UI │
            │  - Mobile app  │
            └────────────────┘
```

## Unified Suggestion Payload Format

All Walker Agents send suggestions using this standardized format:

```typescript
interface WalkerAgentSuggestion {
  // Agent identification
  agent_type: "seo" | "content" | "paid_ads" | "audience_intelligence";
  tenant_id: string; // UUID
  timestamp: string; // ISO 8601

  // Priority and categorization
  priority: "low" | "medium" | "high" | "urgent";
  category: string; // "optimization" | "opportunity" | "alert" | "insight"

  // Suggestions array
  suggestions: Suggestion[];

  // Summary metrics
  summary: {
    total_suggestions: number;
    high_priority: number;
    medium_priority: number;
    low_priority: number;
    total_estimated_impact: ImpactMetrics;
  };
}

interface Suggestion {
  id: string; // Unique suggestion ID
  type: string; // Suggestion type (varies by agent)
  title: string; // User-facing title
  description: string; // Detailed explanation
  priority: "low" | "medium" | "high" | "urgent";

  // Impact metrics
  impact: {
    estimated_revenue_increase?: number;
    estimated_cost_savings?: number;
    estimated_traffic_increase?: number;
    estimated_engagement_increase?: number;
    confidence_score: number; // 0-1
    timeframe?: string; // "immediate" | "7_days" | "30_days" | "90_days"
  };

  // Actionable items
  actions: Action[];

  // Deep link to take action
  cta_url: string;

  // Optional: Preview data
  preview_data?: any;
}

interface Action {
  action_type: string;
  label: string;
  description?: string;
  estimated_effort?: string; // "1_click" | "5_mins" | "15_mins" | "1_hour"
  [key: string]: any; // Action-specific data
}
```

## En Garde Backend API Endpoints

### 1. Receive Walker Agent Suggestions

```http
POST /api/v1/walker-agents/campaign-suggestions
Content-Type: application/json
Authorization: Bearer <WALKER_AGENT_API_KEY>

{
  "agent_type": "paid_ads",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2025-12-28T06:00:00Z",
  "priority": "high",
  "suggestions": [...]
}
```

**Response**:
```json
{
  "status": "success",
  "suggestion_batch_id": "batch_abc123",
  "notifications_scheduled": {
    "email": "scheduled",
    "whatsapp": "scheduled",
    "chat": "sent",
    "push": "sent"
  },
  "delivery_estimates": {
    "email": "2025-12-28T06:01:00Z",
    "whatsapp": "2025-12-28T06:00:15Z",
    "chat": "immediate",
    "push": "immediate"
  }
}
```

### 2. User Notification Preferences

```http
GET /api/v1/users/{user_id}/walker-agent-preferences
```

**Response**:
```json
{
  "user_id": "user_123",
  "email": {
    "enabled": true,
    "frequency": "daily_digest", // "immediate" | "hourly" | "daily_digest"
    "min_priority": "medium"
  },
  "whatsapp": {
    "enabled": true,
    "frequency": "immediate",
    "min_priority": "high",
    "quiet_hours": {
      "enabled": true,
      "start": "22:00",
      "end": "08:00",
      "timezone": "America/New_York"
    }
  },
  "chat": {
    "enabled": true,
    "frequency": "immediate",
    "min_priority": "low"
  },
  "push": {
    "enabled": true,
    "frequency": "immediate",
    "min_priority": "high"
  }
}
```

### 3. Suggestion Action Tracking

```http
POST /api/v1/walker-agents/suggestions/{suggestion_id}/actions
Content-Type: application/json

{
  "action": "applied" | "dismissed" | "snoozed" | "clicked",
  "timestamp": "2025-12-28T06:15:00Z",
  "metadata": {
    "action_type": "increase_budget",
    "applied_value": 1300
  }
}
```

**Response**:
```json
{
  "status": "success",
  "suggestion_id": "sg_12345",
  "action_recorded": "applied",
  "feedback_sent_to_agent": true,
  "learning_loop_updated": true
}
```

## Database Schema (Production Backend)

```sql
-- Walker Agent Suggestions Table
CREATE TABLE walker_agent_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    agent_type VARCHAR(50) NOT NULL,
    suggestion_batch_id VARCHAR(255),
    suggestion_id VARCHAR(255) UNIQUE NOT NULL,
    suggestion_type VARCHAR(100),
    title VARCHAR(500),
    description TEXT,
    priority VARCHAR(20),
    impact_metrics JSONB,
    actions JSONB,
    cta_url TEXT,
    preview_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    status VARCHAR(50) DEFAULT 'pending',
    INDEX idx_tenant_agent (tenant_id, agent_type),
    INDEX idx_priority (priority, created_at),
    INDEX idx_status (status, created_at)
);

-- Suggestion Actions Tracking
CREATE TABLE suggestion_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    suggestion_id VARCHAR(255) REFERENCES walker_agent_suggestions(suggestion_id),
    user_id UUID NOT NULL REFERENCES users(id),
    action_type VARCHAR(100) NOT NULL,
    action_metadata JSONB,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_suggestion (suggestion_id),
    INDEX idx_user (user_id, timestamp)
);

-- Notification Delivery Tracking
CREATE TABLE notification_deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    suggestion_batch_id VARCHAR(255),
    channel VARCHAR(50) NOT NULL,
    recipient_id VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    opened_at TIMESTAMP,
    clicked_at TIMESTAMP,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_batch_channel (suggestion_batch_id, channel),
    INDEX idx_status (status, created_at)
);

-- User Walker Agent Preferences
CREATE TABLE user_walker_agent_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id),
    email_preferences JSONB,
    whatsapp_preferences JSONB,
    chat_preferences JSONB,
    push_preferences JSONB,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Multi-Channel Notification Flow

### Email Delivery (Brevo)

**Service**: `NotificationService.sendEmail()`

```javascript
async function sendWalkerAgentEmailNotification(suggestion_batch) {
  const user = await getUser(suggestion_batch.tenant_id);
  const prefs = await getUserPreferences(user.id);

  // Check email enabled and priority threshold
  if (!prefs.email.enabled) return;
  if (!meetsPriorityThreshold(suggestion_batch.priority, prefs.email.min_priority)) return;

  // Aggregate suggestions if daily digest
  const suggestions = prefs.email.frequency === 'daily_digest'
    ? await aggregateDailySuggestions(user.id)
    : suggestion_batch.suggestions;

  // Render email template
  const html = await renderEmailTemplate('walker_agent_digest', {
    user_name: user.first_name,
    agent_type: suggestion_batch.agent_type,
    suggestions: suggestions,
    total_impact: calculateTotalImpact(suggestions),
    cta_links: generateCTALinks(suggestions)
  });

  // Send via Brevo (formerly Sendinblue)
  const result = await brevo.sendTransacEmail({
    sender: { name: 'En Garde Walker Agents', email: 'walker-agents@engarde.media' },
    to: [{ email: user.email, name: `${user.first_name} ${user.last_name}` }],
    subject: generateSubjectLine(suggestion_batch),
    htmlContent: html,
    params: {
      FIRSTNAME: user.first_name
    }
  });

  // Track delivery
  await trackNotificationDelivery({
    suggestion_batch_id: suggestion_batch.id,
    channel: 'email',
    recipient_id: user.email,
    status: 'sent',
    sent_at: new Date()
  });

  return result;
}
```

### WhatsApp Delivery (Twilio)

**Service**: `NotificationService.sendWhatsApp()`

```javascript
async function sendWalkerAgentWhatsAppNotification(suggestion_batch) {
  const user = await getUser(suggestion_batch.tenant_id);
  const prefs = await getUserPreferences(user.id);

  // Check WhatsApp enabled and quiet hours
  if (!prefs.whatsapp.enabled) return;
  if (isQuietHours(prefs.whatsapp.quiet_hours)) return;
  if (!meetsPriorityThreshold(suggestion_batch.priority, prefs.whatsapp.min_priority)) return;

  // Format for WhatsApp (plain text, emoji-friendly)
  const message = formatWhatsAppMessage(suggestion_batch);

  // Send via Twilio WhatsApp Business API
  const result = await twilio.messages.create({
    from: 'whatsapp:+14155238886', // Twilio WhatsApp number
    to: `whatsapp:${user.phone_number}`,
    body: message
  });

  // Track delivery
  await trackNotificationDelivery({
    suggestion_batch_id: suggestion_batch.id,
    channel: 'whatsapp',
    recipient_id: user.phone_number,
    status: 'sent',
    sent_at: new Date(),
    message_sid: result.sid
  });

  return result;
}

function formatWhatsAppMessage(suggestion_batch) {
  const emoji_map = {
    'seo': '🔍',
    'content': '✍️',
    'paid_ads': '🎯',
    'audience_intelligence': '🎯'
  };

  let message = `${emoji_map[suggestion_batch.agent_type]} *${getAgentName(suggestion_batch.agent_type)} Walker Agent*\n\n`;

  // Add high-priority suggestions first
  const high_priority = suggestion_batch.suggestions.filter(s => s.priority === 'high');
  const other = suggestion_batch.suggestions.filter(s => s.priority !== 'high');

  high_priority.forEach(s => {
    message += `🚨 *${s.priority.toUpperCase()}*\n`;
    message += `*${s.title}*\n\n`;
    message += `${s.description}\n\n`;
    message += formatImpactMetrics(s.impact);
    message += `\n👉 Take action: ${shortenURL(s.cta_url)}\n\n`;
    message += `━━━━━━━━━━━━━━━━\n\n`;
  });

  other.forEach(s => {
    message += `*${s.title}*\n`;
    message += `${s.description.substring(0, 100)}...\n`;
    message += `👉 ${shortenURL(s.cta_url)}\n\n`;
  });

  message += `View dashboard: ${shortenURL('https://app.engarde.media/walker-agents')}`;

  return message;
}
```

### In-Platform Chat Delivery

**Service**: `NotificationService.sendPlatformChat()`

```javascript
async function sendWalkerAgentChatNotification(suggestion_batch) {
  const user = await getUser(suggestion_batch.tenant_id);

  // Send via WebSocket to active sessions
  const active_sessions = await getActiveUserSessions(user.id);

  const chat_payload = {
    notification_type: 'walker_agent_suggestion',
    agent: suggestion_batch.agent_type,
    priority: suggestion_batch.priority,
    message: {
      type: 'interactive_card',
      content: {
        header: {
          icon: getAgentIcon(suggestion_batch.agent_type),
          title: getAgentName(suggestion_batch.agent_type),
          subtitle: `${suggestion_batch.suggestions.length} new ${suggestion_batch.suggestions.length === 1 ? 'opportunity' : 'opportunities'} detected`
        },
        summary: {
          total_impact: formatImpact(suggestion_batch.summary.total_estimated_impact),
          priority_level: suggestion_batch.priority,
          suggestions_count: suggestion_batch.suggestions.length
        },
        quick_actions: suggestion_batch.suggestions.slice(0, 3).map(s => ({
          label: s.title.substring(0, 40),
          action: 'open_suggestion',
          suggestion_id: s.id,
          badge: getPriorityBadge(s.priority)
        })),
        preview_suggestions: suggestion_batch.suggestions.slice(0, 3)
      }
    },
    timestamp: new Date().toISOString(),
    read: false,
    actions_available: true
  };

  // Broadcast to all active sessions
  for (const session of active_sessions) {
    await websocket.send(session.socket_id, chat_payload);
  }

  // Also store in chat history for offline retrieval
  await storeChatMessage(user.id, chat_payload);

  // Track delivery
  await trackNotificationDelivery({
    suggestion_batch_id: suggestion_batch.id,
    channel: 'chat',
    recipient_id: user.id,
    status: 'sent',
    sent_at: new Date()
  });
}
```

### Push Notification Delivery (Firebase)

**Service**: `NotificationService.sendPushNotification()`

```javascript
async function sendWalkerAgentPushNotification(suggestion_batch) {
  const user = await getUser(suggestion_batch.tenant_id);
  const prefs = await getUserPreferences(user.id);
  const devices = await getUserDevices(user.id);

  if (!prefs.push.enabled || devices.length === 0) return;
  if (!meetsPriorityThreshold(suggestion_batch.priority, prefs.push.min_priority)) return;

  // Get highest priority suggestion for push notification
  const top_suggestion = suggestion_batch.suggestions
    .sort((a, b) => getPriorityScore(b.priority) - getPriorityScore(a.priority))[0];

  const push_payload = {
    notification: {
      title: `${getAgentName(suggestion_batch.agent_type)} Alert`,
      body: top_suggestion.title,
      icon: getAgentIcon(suggestion_batch.agent_type),
      badge: suggestion_batch.suggestions.length
    },
    data: {
      type: 'walker_agent_suggestion',
      agent_type: suggestion_batch.agent_type,
      suggestion_id: top_suggestion.id,
      cta_url: top_suggestion.cta_url,
      priority: top_suggestion.priority
    },
    android: {
      priority: suggestion_batch.priority === 'urgent' ? 'high' : 'normal',
      notification: {
        color: getPriorityColor(top_suggestion.priority)
      }
    },
    apns: {
      payload: {
        aps: {
          sound: suggestion_batch.priority === 'urgent' ? 'default' : 'none',
          badge: suggestion_batch.suggestions.length
        }
      }
    }
  };

  // Send to all registered devices
  const results = await Promise.all(
    devices.map(device => firebase.messaging().sendToDevice(device.fcm_token, push_payload))
  );

  // Track delivery
  await trackNotificationDelivery({
    suggestion_batch_id: suggestion_batch.id,
    channel: 'push',
    recipient_id: user.id,
    status: 'sent',
    sent_at: new Date()
  });

  return results;
}
```

## Walker Agent Authentication

All Walker Agent requests must include a valid API key:

```http
Authorization: Bearer <WALKER_AGENT_API_KEY>
```

**API Key Format**:
```
wa_<microservice>_<environment>_<random>
Examples:
- wa_onside_production_k8s9d2h4f7
- wa_sankore_production_m3n7p1q5r8
- wa_madansara_production_x2y6z4w9v5
```

**Validation**:
```javascript
async function validateWalkerAgentAuth(api_key) {
  const [prefix, microservice, environment, random] = api_key.split('_');

  if (prefix !== 'wa') {
    throw new Error('Invalid API key format');
  }

  const key_record = await db.query(
    'SELECT * FROM walker_agent_api_keys WHERE key_hash = $1 AND revoked = false',
    [hashAPIKey(api_key)]
  );

  if (!key_record) {
    throw new Error('Invalid or revoked API key');
  }

  // Update last_used timestamp
  await db.query(
    'UPDATE walker_agent_api_keys SET last_used_at = NOW() WHERE id = $1',
    [key_record.id]
  );

  return {
    microservice: key_record.microservice,
    permissions: key_record.permissions,
    rate_limit: key_record.rate_limit
  };
}
```

## Rate Limiting

Walker Agents are rate-limited to prevent notification spam:

**Limits**:
- **Per Agent**: 1000 suggestions/day
- **Per Tenant**: 100 suggestions/day across all agents
- **Per Channel**:
  - Email: 10/day
  - WhatsApp: 20/day
  - Chat: Unlimited
  - Push: 50/day

**Implementation**:
```javascript
async function checkRateLimit(agent_type, tenant_id, channel) {
  const today = new Date().toISOString().split('T')[0];

  const count = await redis.get(`rate_limit:${agent_type}:${tenant_id}:${channel}:${today}`);

  const limits = {
    email: 10,
    whatsapp: 20,
    push: 50
  };

  if (count >= limits[channel]) {
    throw new Error(`Rate limit exceeded for ${channel}`);
  }

  await redis.incr(`rate_limit:${agent_type}:${tenant_id}:${channel}:${today}`);
  await redis.expire(`rate_limit:${agent_type}:${tenant_id}:${channel}:${today}`, 86400); // 24 hours
}
```

## Suggestion Lifecycle

```
1. Walker Agent generates suggestion
   ↓
2. POST to En Garde Backend API
   ↓
3. Validate API key & rate limits
   ↓
4. Store in database (walker_agent_suggestions table)
   ↓
5. Check user notification preferences
   ↓
6. Route to appropriate channels
   ↓
7. Format per channel (email, WhatsApp, chat, push)
   ↓
8. Send notifications
   ↓
9. Track delivery status
   ↓
10. User views/acts on suggestion
   ↓
11. Record action (applied/dismissed/snoozed)
   ↓
12. Send feedback to Walker Agent
   ↓
13. Update ML models (learning loop)
   ↓
14. Expire suggestion after timeframe or action
```

## Monitoring & Analytics

**Key Metrics**:
- Suggestions sent per agent per day
- Notification delivery rates by channel
- Open rates (email, push)
- Click-through rates
- Action taken rates (applied/dismissed/snoozed)
- Time to action
- Estimated value delivered
- User engagement by agent type

**Dashboards**:
- Walker Agent performance dashboard
- Channel effectiveness comparison
- User engagement heatmap
- Suggestion impact tracking

## Conclusion

The Walker Agents Campaign Suggestion System provides a unified, multi-channel notification infrastructure that enables all En Garde Walker Agents to deliver timely, actionable marketing insights directly to users via their preferred communication channels. By standardizing the suggestion format, delivery mechanisms, and user feedback loops, the system ensures consistent, high-quality user experiences while enabling continuous improvement of Walker Agent recommendations through learning loops.

---

**Document Version**: 1.0
**Last Updated**: December 28, 2025
**Maintained By**: En Garde Engineering Team
