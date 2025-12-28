# En Garde Walker Agents Communication Channels - Product Requirements Document

**Version:** 2.0
**Last Updated:** December 25, 2025
**Document Owner:** Product & Engineering Team
**Status:** Production Ready

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Product Vision](#product-vision)
3. [Walker Agents Overview](#walker-agents-overview)
4. [Communication Channels Architecture](#communication-channels-architecture)
5. [WhatsApp Integration](#whatsapp-integration)
6. [Email Daily Briefs](#email-daily-briefs)
7. [En Garde Chat UI](#en-garde-chat-ui)
8. [Admin Monitoring System](#admin-monitoring-system)
9. [Human-in-the-Loop (HITL) Review](#human-in-the-loop-hitl-review)
10. [Analytics and Performance Tracking](#analytics-and-performance-tracking)
11. [Privacy and Security](#privacy-and-security)
12. [API Endpoints](#api-endpoints)
13. [Deployment and Configuration](#deployment-and-configuration)
14. [Success Metrics](#success-metrics)
15. [Roadmap](#roadmap)

---

## Executive Summary

En Garde's Walker Agents are specialized AI marketing assistants accessible through multiple communication channels. This document defines the architecture, features, and implementation details for the three primary communication channels (WhatsApp, Email, Chat UI) and the comprehensive admin monitoring system.

### Key Features

- **Multi-Channel Access:** Users interact with Walker Agents via WhatsApp, Email, or web-based Chat UI
- **Unified Intelligence Layer:** All channels connect to the same AI agent workflows built on Langflow
- **Admin Monitoring:** Comprehensive conversation monitoring with privacy controls
- **HITL Review System:** Human-in-the-loop approval for high-risk agent actions
- **Analytics Dashboard:** Real-time performance tracking and insights
- **Enterprise Security:** Multi-tenant isolation, role-based access, audit logging

### Walker Agent Types

1. **Paid Ads Marketing Agent** - Campaign optimization and ROAS improvement
2. **SEO Agent** - Search engine optimization and content strategy
3. **Content Generation Agent** - Multi-format content creation
4. **Audience Intelligence Agent** - Customer segmentation and predictive analytics

---

## Product Vision

**Vision Statement:**
Enable marketers to interact with AI-powered marketing agents through their preferred communication channels—whether at their desk (Chat UI), on-the-go (WhatsApp), or via daily summaries (Email)—while providing enterprise admins with comprehensive monitoring, control, and insights.

**Core Principles:**

1. **Channel Flexibility:** Meet users where they are
2. **Unified Experience:** Consistent agent intelligence across all channels
3. **Privacy First:** User data protection and transparent monitoring
4. **Admin Control:** Complete oversight with granular permissions
5. **Performance Transparency:** Clear metrics and actionable insights

---

## Walker Agents Overview

### What Are Walker Agents?

Walker Agents are pre-built, specialized AI agents designed for specific marketing functions. Unlike custom En Garde Agents (built with Langflow), Walker Agents are production-ready with built-in cultural intelligence, brand awareness, and industry best practices.

### Agent Characteristics

| Characteristic | Description |
|---------------|-------------|
| **Specialization** | Purpose-built for specific marketing tasks |
| **Protection** | System-protected, cannot be deleted or modified |
| **Configuration** | Minimal setup required, optimized defaults |
| **Cultural Intelligence** | Built-in multicultural awareness |
| **Tier Limits** | Limited by subscription (Free: 1, Starter: 2, Pro: 3, Business: 4, Enterprise: Unlimited) |
| **Maintenance** | Managed and updated by En Garde |

### Four Core Walker Agents

#### 1. Paid Ads Marketing Agent
- **Type:** `paid_ads_optimization`
- **Purpose:** ROAS optimization, campaign management
- **Capabilities:** Budget allocation, bid optimization, A/B testing, cross-platform campaigns
- **Platforms:** Meta, TikTok, Google Ads, LinkedIn

#### 2. SEO Agent
- **Type:** `seo_optimization`
- **Purpose:** Search visibility and organic traffic growth
- **Capabilities:** Keyword research, technical audits, content optimization, competitor analysis
- **Languages:** Multilingual with cultural context

#### 3. Content Generation Agent
- **Type:** `content_generation`
- **Purpose:** Multi-format content creation at scale
- **Capabilities:** Social posts, blog articles, email campaigns, video scripts, cultural adaptation
- **Formats:** Text, image descriptions, video storyboards

#### 4. Audience Intelligence Agent
- **Type:** `audience_intelligence`
- **Purpose:** Customer insights and segmentation
- **Capabilities:** RFM analysis, churn prediction, LTV calculation, lookalike modeling
- **Data Sources:** CRM, e-commerce, ad platforms, analytics

---

## Communication Channels Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Communication Channels                     │
├─────────────────┬─────────────────┬─────────────────────────┤
│   WhatsApp      │      Email      │      Chat UI            │
│   (Twilio)      │   (Daily Brief) │   (Web/Mobile)          │
└────────┬────────┴────────┬────────┴────────┬────────────────┘
         │                 │                 │
         ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────┐
│              Channel Routing Layer (FastAPI)                 │
│   ┌─────────────┬──────────────┬─────────────────────┐     │
│   │  WhatsApp   │    Email     │    Chat WebSocket   │     │
│   │   Router    │    Router    │       Router        │     │
│   └──────┬──────┴──────┬───────┴──────────┬──────────┘     │
└──────────┼─────────────┼──────────────────┼────────────────┘
           │             │                  │
           ▼             ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│           Langflow Intelligence Layer                        │
│   ┌──────────────────────────────────────────────────┐      │
│   │  Walker Agent Workflows (Langflow Instances)     │      │
│   │  - Paid Ads Agent   - SEO Agent                  │      │
│   │  - Content Gen      - Audience Intelligence      │      │
│   └──────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────────┐
│              Data & Event Logging Layer                      │
│   ┌──────────────────────────────────────────────────┐      │
│   │  - Conversation Logs (PostgreSQL)                │      │
│   │  - Platform Event Logs (BigQuery)                │      │
│   │  - HITL Approval Queue                           │      │
│   │  - Analytics Aggregations                        │      │
│   └──────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────────┐
│                Admin Monitoring Dashboard                    │
│   - Conversation Monitoring   - HITL Review Queue           │
│   - Performance Analytics     - Privacy Controls            │
└─────────────────────────────────────────────────────────────┘
```

### Key Design Principles

1. **Channel Agnostic Intelligence:** Walker Agents execute the same workflows regardless of communication channel
2. **Async Processing:** All channels use async/await patterns for scalability
3. **Event-Driven Logging:** Every interaction logged to PlatformEventLog for analytics
4. **Tenant Isolation:** Complete data separation per tenant
5. **Graceful Degradation:** Channels fail independently without affecting others

---

## WhatsApp Integration

### Overview

Users interact with Walker Agents via WhatsApp using natural language. Messages are processed through Twilio's WhatsApp Business API and routed to appropriate Langflow workflows.

### Architecture Components

#### 1. Twilio Integration
- **Provider:** Twilio WhatsApp Business API
- **Webhook Endpoint:** `POST /api/v1/channels/whatsapp/webhook`
- **Message Format:** Form-encoded Twilio payload
- **Response Delivery:** Via `twilio_service.send_whatsapp_message()`

#### 2. Message Processing Flow

```
User WhatsApp Message
  ↓
Twilio Webhook → FastAPI Endpoint
  ↓
Extract: sender, message body
  ↓
Identify tenant/user (phone number mapping)
  ↓
Route to appropriate Walker Agent workflow
  ↓
Execute Langflow workflow
  ↓
Generate AI response
  ↓
Send response via Twilio API
  ↓
Log conversation to database
```

#### 3. User Phone Number Mapping

```python
# Database: user_phone_numbers table
{
  "user_id": "uuid",
  "phone_number": "+1234567890",  # E.164 format
  "tenant_id": "uuid",
  "verified": true,
  "primary": true,
  "created_at": "timestamp"
}
```

### Features

#### Conversation Context
- **Session Management:** WhatsApp conversations grouped by session_id
- **Context Window:** Last 10 messages maintained for context
- **Multi-Turn Dialogs:** Agents maintain conversation state

#### Rich Media Support
- **Images:** Product images, campaign creatives, analytics charts
- **Documents:** PDFs (reports, guides), CSV (data exports)
- **Quick Replies:** Pre-defined action buttons for common requests

#### WhatsApp-Specific Capabilities

1. **Campaign Status Updates:**
   User: "How's my Meta campaign performing?"
   Agent: Fetches real-time data, sends summary + chart image

2. **Content Approval:**
   Agent: "I've generated 10 social posts. Would you like to review?"
   User: "Yes" → Agent sends preview carousel

3. **Quick Actions:**
   Agent: "Quick actions: [View Analytics] [Pause Campaign] [Generate Content]"

### Implementation Details

**File:** `/app/routers/channels/whatsapp.py`

```python
@router.post("/webhook")
async def whatsapp_webhook(request: Request, db: Session = Depends(get_db)):
    # 1. Parse Twilio payload
    form_data = await request.form()
    message_body = form_data.get('Body', '')
    sender_phone = form_data.get('From', '')

    # 2. Identify user/tenant from phone number
    user = get_user_by_phone(sender_phone, db)

    # 3. Get or create conversation session
    session_id = get_or_create_session(user.id, "whatsapp", db)

    # 4. Route to appropriate Walker Agent
    agent = determine_agent_from_context(message_body, user, db)

    # 5. Execute Langflow workflow
    workflow_result = await langflow_integration.execute_workflow(
        instance_id=agent.workflow_instance_id,
        input_data={"message": message_body, "context": get_context(session_id)}
    )

    # 6. Send response via Twilio
    response_text = workflow_result.get("output")
    await twilio_service.send_whatsapp_message(to=sender_phone, body=response_text)

    # 7. Log conversation
    log_conversation(session_id, message_body, response_text, db)

    return {"status": "success"}
```

### Configuration Requirements

```yaml
# .env
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_WHATSAPP_NUMBER=+14155238886  # Your Twilio WhatsApp number
WHATSAPP_WEBHOOK_URL=https://your-domain.com/api/v1/channels/whatsapp/webhook
```

### Rate Limits and Quotas

| Tier | Messages/Day | Cost per Message |
|------|--------------|------------------|
| Free | 100 | $0.005 |
| Starter | 1,000 | $0.005 |
| Professional | 10,000 | $0.0045 |
| Business | 50,000 | $0.004 |
| Enterprise | Unlimited | Custom pricing |

---

## Email Daily Briefs

### Overview

Walker Agents automatically generate and send daily email briefs summarizing key marketing metrics, insights, and recommended actions.

### Architecture Components

#### 1. Email Delivery Service
- **Provider:** SendGrid (primary), Mailgun (backup)
- **Endpoint:** `POST /api/v1/channels/email/send-daily-brief/{user_id}`
- **Schedule:** Configurable per user (default: 8 AM local timezone)
- **Template Engine:** Jinja2 for HTML email templates

#### 2. Daily Brief Generation Flow

```
Scheduled Job (Cron/Celery)
  ↓
For each subscribed user:
  ↓
  Trigger Walker Agent workflow ("daily_brief" intent)
  ↓
  Agent fetches relevant data:
    - Campaign performance (Paid Ads Agent)
    - SEO metrics (SEO Agent)
    - Content performance (Content Gen Agent)
    - Audience insights (Audience Intelligence Agent)
  ↓
  Generate personalized brief (HTML + plain text)
  ↓
  Send via SendGrid API
  ↓
  Log delivery status
```

### Email Brief Structure

#### Subject Line Format
```
Your En Garde Daily Brief - [Date] | [Key Highlight]

Examples:
- "Your En Garde Daily Brief - Dec 25 | ROAS up 23%"
- "Your En Garde Daily Brief - Dec 25 | 3 urgent items need review"
```

#### Email Sections

1. **Executive Summary (Top)**
   - Key metrics at a glance
   - Biggest wins and losses
   - Items requiring attention

2. **Paid Ads Performance (Paid Ads Agent)**
   - Yesterday's spend vs. budget
   - ROAS trends (7-day)
   - Top performing campaigns
   - Alerts: budget overspend, underperforming ads

3. **SEO & Organic (SEO Agent)**
   - Ranking changes
   - Top traffic pages
   - New keyword opportunities
   - Technical issues detected

4. **Content Performance (Content Gen Agent)**
   - Top social posts (engagement)
   - Blog traffic
   - Email open rates
   - Content ideas for today

5. **Audience Insights (Audience Intelligence Agent)**
   - New segment discoveries
   - Churn risk alerts
   - High-value customer activity
   - Lookalike recommendations

6. **Action Items (All Agents)**
   - Prioritized recommendations
   - One-click actions (approve content, adjust bids, etc.)

7. **Footer**
   - Manage preferences link
   - Unsubscribe option
   - En Garde branding

### Email Templates

**File:** `/app/templates/emails/daily_brief.html`

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Your En Garde Daily Brief</title>
</head>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
  <!-- Header -->
  <div style="background: #1a1a1a; color: white; padding: 20px; text-align: center;">
    <img src="{{logo_url}}" alt="En Garde" style="height: 40px;">
    <h1>Your Daily Brief</h1>
    <p style="color: #ccc;">{{date}}</p>
  </div>

  <!-- Executive Summary -->
  <div style="background: #f5f5f5; padding: 20px; margin: 20px 0;">
    <h2>📊 At a Glance</h2>
    <div style="display: flex; justify-content: space-between;">
      <div><strong>ROAS:</strong> {{roas}}x</div>
      <div><strong>Traffic:</strong> {{traffic_change}}</div>
      <div><strong>Conversions:</strong> {{conversions}}</div>
    </div>
    <div style="margin-top: 10px;">
      {{#if urgent_items}}
      <p style="color: #d9534f;">⚠️ {{urgent_items_count}} items need your attention</p>
      {{/if}}
    </div>
  </div>

  <!-- Sections rendered dynamically by agents -->
  {{sections}}

  <!-- Action Items -->
  <div style="padding: 20px; background: #fff3cd; border-left: 4px solid #ffc107;">
    <h2>✅ Recommended Actions</h2>
    <ol>
      {{#each action_items}}
      <li>
        <strong>{{this.title}}</strong><br>
        {{this.description}}<br>
        <a href="{{this.action_url}}" style="display: inline-block; margin-top: 5px; padding: 8px 16px; background: #007bff; color: white; text-decoration: none; border-radius: 4px;">
          {{this.action_label}}
        </a>
      </li>
      {{/each}}
    </ol>
  </div>

  <!-- Footer -->
  <div style="text-align: center; padding: 20px; color: #666; font-size: 12px;">
    <p>
      <a href="{{preferences_url}}">Email Preferences</a> |
      <a href="{{unsubscribe_url}}">Unsubscribe</a>
    </p>
    <p>© 2025 En Garde. All rights reserved.</p>
  </div>
</body>
</html>
```

### User Preferences

Users can customize their daily brief:

```python
# Database: user_email_preferences
{
  "user_id": "uuid",
  "enabled": true,
  "delivery_time": "08:00",  # Local timezone
  "timezone": "America/New_York",
  "frequency": "daily",  # daily, weekly, custom
  "include_sections": [
    "paid_ads",
    "seo",
    "content",
    "audience"
  ],
  "min_priority": "medium",  # only include medium+ priority items
  "digest_format": "full"  # full, summary, bullet_points
}
```

### Implementation Details

**File:** `/app/routers/channels/email.py`

```python
@router.post("/send-daily-brief/{user_id}")
async def send_daily_brief(user_id: str, db: Session = Depends(get_db)):
    # 1. Get user preferences
    prefs = get_email_preferences(user_id, db)
    if not prefs.enabled:
        return {"status": "skipped", "reason": "user_disabled"}

    # 2. Trigger Daily Brief workflow
    agent = get_walker_agent(tenant_id, "personal_agent_core", db)
    workflow_result = await langflow_integration.execute_workflow(
        instance_id=agent.workflow_instance_id,
        input_data={"intent": "daily_brief", "user_id": user_id}
    )

    # 3. Extract brief data
    brief_data = workflow_result.get("brief_data")

    # 4. Render email template
    html_content = render_template("daily_brief.html", brief_data)

    # 5. Send via SendGrid
    result = await email_service.send_email(
        to=prefs.email,
        subject=f"Your En Garde Daily Brief - {today}",
        html_content=html_content
    )

    # 6. Log delivery
    log_email_sent(user_id, "daily_brief", result.status, db)

    return {"status": "sent", "message_id": result.message_id}
```

---

## En Garde Chat UI

### Overview

Web-based chat interface providing real-time interaction with Walker Agents. Built with React and WebSocket for instant messaging experience.

### Architecture Components

#### 1. Frontend Chat UI
- **Framework:** React with TypeScript
- **State Management:** Zustand
- **Real-time:** WebSocket (Socket.IO)
- **Styling:** Chakra UI
- **Location:** `/components/chat/ChatInterface.tsx`

#### 2. Backend WebSocket Server
- **Framework:** FastAPI with WebSocket support
- **Protocol:** Socket.IO
- **Authentication:** JWT token validation
- **Endpoint:** `ws://api.engarde.com/ws/chat`

#### 3. Chat Features

##### Real-Time Messaging
- Instant delivery and receipt
- Typing indicators
- Read receipts
- Message status (sending, sent, delivered, failed)

##### Rich Content Support
- **Text Formatting:** Markdown rendering
- **Code Blocks:** Syntax highlighting for generated code
- **Images:** Inline display with lightbox
- **Files:** Upload/download with progress
- **Charts:** Interactive performance charts
- **Tables:** Data tables with sorting/filtering

##### Conversation Management
- Multiple concurrent conversations
- Conversation history search
- Bookmark important messages
- Export conversation transcripts

##### Agent Selection
- Switch between Walker Agents mid-conversation
- Multi-agent conversations (get input from multiple agents)
- Agent status indicators (online, processing, offline)

### User Interface Design

#### Chat Window Layout

```
┌─────────────────────────────────────────────────────────┐
│  En Garde Chat                          [_] [□] [X]     │
├─────────────────────────────────────────────────────────┤
│  ┌────────────┐ ┌─────────────────────────────────────┐│
│  │            │ │  Conversation: Campaign Planning    ││
│  │  Sidebar   │ │  Agent: Paid Ads Marketing Agent    ││
│  │            │ ├─────────────────────────────────────┤│
│  │ Recent     │ │                                     ││
│  │ Chats      │ │  [Agent Message]                    ││
│  │            │ │  ┌──────────────────────────────┐   ││
│  │ • Campaign │ │  │ Here's your campaign...      │   ││
│  │   Planning │ │  └──────────────────────────────┘   ││
│  │            │ │                          10:23 AM    ││
│  │ • SEO      │ │                                     ││
│  │   Strategy │ │                [User Message]       ││
│  │            │ │           ┌──────────────────────┐  ││
│  │ • Content  │ │           │ What's the ROAS?     │  ││
│  │   Ideas    │ │           └──────────────────────┘  ││
│  │            │ │   10:24 AM                          ││
│  │            │ │                                     ││
│  │ [+ New     │ │  [Agent Typing...]                  ││
│  │  Chat]     │ │                                     ││
│  │            │ │                                     ││
│  └────────────┘ └─────────────────────────────────────┘│
│                 ┌─────────────────────────────────────┐│
│                 │ Type a message...                   ││
│                 │ [📎] [😊]                      [Send]││
│                 └─────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

#### Message Types

1. **User Messages** (Right-aligned, blue)
2. **Agent Messages** (Left-aligned, gray)
3. **System Messages** (Center-aligned, yellow)
4. **Action Cards** (Interactive components)
5. **Data Visualizations** (Charts, tables)

### WebSocket Protocol

#### Connection Handshake

```javascript
// Client
const socket = io('wss://api.engarde.com', {
  auth: {
    token: jwt_token
  },
  transports: ['websocket']
});

socket.on('connect', () => {
  console.log('Connected to chat server');
  socket.emit('join_conversation', {
    conversation_id: current_conversation_id
  });
});
```

#### Message Events

```javascript
// Client -> Server
socket.emit('send_message', {
  conversation_id: 'uuid',
  message: 'What is my current ROAS?',
  agent_type: 'paid_ads_optimization'
});

// Server -> Client
socket.on('message_received', (data) => {
  // data: {message_id, status: 'received', timestamp}
});

socket.on('agent_response', (data) => {
  // data: {message_id, content, metadata, timestamp}
  displayMessage(data);
});

socket.on('agent_typing', (data) => {
  // data: {agent_type, is_typing: true}
  showTypingIndicator();
});
```

### Implementation Details

**Frontend: `/components/chat/ChatInterface.tsx`**

```typescript
export const ChatInterface: React.FC = () => {
  const [messages, setMessages] = useState<Message[]>([]);
  const [socket, setSocket] = useState<Socket | null>(null);
  const [isTyping, setIsTyping] = useState(false);

  useEffect(() => {
    // Initialize WebSocket
    const newSocket = io(WS_URL, {
      auth: { token: getAuthToken() }
    });

    newSocket.on('agent_response', (data) => {
      setMessages(prev => [...prev, {
        id: data.message_id,
        type: 'agent',
        content: data.content,
        timestamp: data.timestamp,
        metadata: data.metadata
      }]);
      setIsTyping(false);
    });

    newSocket.on('agent_typing', () => setIsTyping(true));

    setSocket(newSocket);

    return () => newSocket.disconnect();
  }, []);

  const sendMessage = (text: string) => {
    const userMessage = {
      id: generateId(),
      type: 'user',
      content: text,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);

    socket?.emit('send_message', {
      conversation_id: currentConversation.id,
      message: text,
      agent_type: selectedAgent.type
    });
  };

  return (
    <Box h="100vh" display="flex">
      <ChatSidebar conversations={conversations} />
      <ChatWindow
        messages={messages}
        isTyping={isTyping}
        onSendMessage={sendMessage}
      />
    </Box>
  );
};
```

**Backend: `/app/routers/chat_websocket.py`**

```python
from fastapi import WebSocket, WebSocketDisconnect
from typing import Dict

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}

    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        self.active_connections[user_id] = websocket

    async def send_message(self, user_id: str, message: dict):
        websocket = self.active_connections.get(user_id)
        if websocket:
            await websocket.send_json(message)

manager = ConnectionManager()

@app.websocket("/ws/chat")
async def chat_websocket(websocket: WebSocket, token: str):
    # Authenticate
    user = authenticate_websocket(token)

    await manager.connect(websocket, user.id)

    try:
        while True:
            # Receive message from client
            data = await websocket.receive_json()

            # Send typing indicator
            await manager.send_message(user.id, {
                "event": "agent_typing",
                "is_typing": True
            })

            # Process with Walker Agent
            agent_response = await execute_walker_agent(
                agent_type=data['agent_type'],
                message=data['message'],
                user_id=user.id
            )

            # Send response
            await manager.send_message(user.id, {
                "event": "agent_response",
                "message_id": str(uuid.uuid4()),
                "content": agent_response['output'],
                "metadata": agent_response['metadata'],
                "timestamp": datetime.utcnow().isoformat()
            })

    except WebSocketDisconnect:
        del manager.active_connections[user.id]
```

---

## Admin Monitoring System

### Overview

Comprehensive admin dashboard for monitoring all Walker Agent conversations across all communication channels with privacy controls, search capabilities, and insights.

### Key Features

1. **Conversation Monitoring:** View all user-agent conversations in real-time
2. **Privacy Controls:** PII masking, role-based access, audit logging
3. **Search & Filter:** Advanced search across conversations
4. **Analytics:** Performance metrics and insights
5. **HITL Queue:** Review and approve high-risk agent actions
6. **User Management:** View user activity and patterns

### Architecture Components

#### Admin Dashboard Pages

```
/admin/monitoring
├── /conversations        # All conversations list
├── /conversation/:id     # Individual conversation detail
├── /hitl-queue          # Human-in-the-loop approval queue
├── /analytics           # Performance analytics
├── /users               # User activity monitoring
└── /settings            # Privacy and access settings
```

### Conversation Monitoring Interface

#### Conversations List View

```
┌─────────────────────────────────────────────────────────────┐
│  Conversation Monitoring                    [Search] [Filter]│
├─────────────────────────────────────────────────────────────┤
│  Filters:                                                    │
│  Channel: [All ▼] Agent: [All ▼] Date: [Last 7 days ▼]     │
│  Status: [All ▼] User: [Search users...]                    │
├─────────────────────────────────────────────────────────────┤
│  ┌─────┬──────────┬──────────┬────────┬──────────┬────────┐│
│  │User │ Channel  │  Agent   │Messages│Last Msg  │ Action ││
│  ├─────┼──────────┼──────────┼────────┼──────────┼────────┤│
│  │John │WhatsApp  │Paid Ads  │   23   │2 min ago │ [View] ││
│  │Sarah│Chat UI   │SEO       │   45   │10 min ago│ [View] ││
│  │Mike │Email     │Content   │   12   │1 hr ago  │ [View] ││
│  │Lisa │WhatsApp  │Audience  │   8    │3 hrs ago │ [View] ││
│  └─────┴──────────┴──────────┴────────┴──────────┴────────┘│
│                                           [1] 2 3 ... 10    │
└─────────────────────────────────────────────────────────────┘
```

#### Conversation Detail View

```
┌─────────────────────────────────────────────────────────────┐
│  Conversation: John Doe - Paid Ads Agent      [< Back]      │
├─────────────────────────────────────────────────────────────┤
│  User: john.doe@example.com | Channel: WhatsApp             │
│  Agent: Paid Ads Marketing | Started: Dec 24, 2:30 PM       │
│  Messages: 23 | Duration: 1h 15m | Status: Active           │
├─────────────────────────────────────────────────────────────┤
│  [Conversation Thread]                                       │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ 2:30 PM - User                                         │ │
│  │ "How's my Meta campaign performing?"                   │ │
│  │                                                        │ │
│  │ 2:31 PM - Paid Ads Agent                              │ │
│  │ "Your Meta campaign has a ROAS of 3.2x (up 15%...)    │ │
│  │ [Chart: Performance Trend]                             │ │
│  │                                                        │ │
│  │ 2:35 PM - User                                         │ │
│  │ "Can you increase the budget by $500?"                 │ │
│  │                                                        │ │
│  │ 2:35 PM - Paid Ads Agent                              │ │
│  │ "⚠️ Budget increase requires approval. I've sent...    │ │
│  │ [Action Required: Pending in HITL Queue]               │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  [Privacy Settings]                                          │
│  □ Show Full PII (Admin Only)                               │
│  ☑ Mask Email/Phone                                         │
│  ☑ Log Admin Access (Audit Trail)                           │
└─────────────────────────────────────────────────────────────┘
```

### Privacy Controls

#### Data Masking Rules

| Data Type | Masked Format | Full Access Role |
|-----------|---------------|------------------|
| Email | j***@example.com | Admin, Compliance |
| Phone | +1-***-***-1234 | Admin, Compliance |
| Credit Card | **** **** **** 1234 | Finance, Admin |
| API Keys | sk-***...***123 | Engineering, Admin |
| Addresses | 123 Main St, [CITY MASKED] | Admin, Compliance |

#### Role-Based Access Control (RBAC)

```python
# Admin Roles with Conversation Access
ROLES = {
    "super_admin": {
        "view_all_conversations": True,
        "view_pii": True,
        "export_data": True,
        "modify_settings": True
    },
    "support_admin": {
        "view_all_conversations": True,
        "view_pii": False,  # PII masked
        "export_data": False,
        "modify_settings": False
    },
    "compliance_officer": {
        "view_all_conversations": True,
        "view_pii": True,
        "export_data": True,
        "modify_settings": False
    },
    "read_only_admin": {
        "view_all_conversations": True,
        "view_pii": False,
        "export_data": False,
        "modify_settings": False
    }
}
```

#### Audit Logging

Every admin action is logged:

```python
# admin_access_logs table
{
    "id": "uuid",
    "admin_user_id": "uuid",
    "action": "view_conversation",
    "resource_id": "conversation_uuid",
    "resource_type": "conversation",
    "pii_accessed": True,
    "ip_address": "192.168.1.1",
    "user_agent": "Mozilla/5.0...",
    "timestamp": "2025-12-25T10:30:00Z",
    "justification": "User support request #12345"
}
```

### Advanced Search

#### Search Capabilities

```
Search Query: "campaign budget"

Filters:
- Date Range: [Dec 1, 2025] to [Dec 25, 2025]
- Channels: ☑ WhatsApp ☑ Chat UI ☐ Email
- Agents: ☑ Paid Ads ☐ SEO ☐ Content ☐ Audience
- Sentiment: [All ▼]
- Message Count: [Min: 5] [Max: 100]
- Contains Actions: ☑ Budget Changes ☐ Campaign Creation

Results: 47 conversations found
```

#### Search API Endpoint

```python
@router.post("/api/v1/admin/conversations/search")
async def search_conversations(
    query: str,
    filters: ConversationSearchFilters,
    current_admin: User = Depends(get_current_admin)
):
    # Perform full-text search
    results = db.query(ConversationalAnalyticsLog).filter(
        or_(
            ConversationalAnalyticsLog.query.ilike(f"%{query}%"),
            ConversationalAnalyticsLog.response.astext.ilike(f"%{query}%")
        )
    )

    # Apply filters
    if filters.channels:
        results = results.filter(ConversationalAnalyticsLog.channel.in_(filters.channels))

    # ... additional filters

    # Mask PII if admin doesn't have permission
    if not current_admin.has_permission("view_pii"):
        results = [mask_pii(conv) for conv in results]

    return {
        "total": len(results),
        "conversations": results,
        "query": query,
        "filters_applied": filters
    }
```

---

## Human-in-the-Loop (HITL) Review

### Overview

HITL system ensures high-risk Walker Agent actions are reviewed and approved by humans before execution. Provides enterprise-grade control and compliance.

### HITL Queue Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│  HITL Approval Queue                   [Filter] [Sort]       │
├─────────────────────────────────────────────────────────────┤
│  Pending Approvals: 12    Approved Today: 45    Rejected: 3 │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐│
│  │ 🔴 HIGH RISK - Budget Increase Request                  ││
│  │ User: john.doe@example.com                              ││
│  │ Agent: Paid Ads Marketing Agent                         ││
│  │ Action: Increase Meta campaign budget by $5,000         ││
│  │ Current: $10,000/mo → Proposed: $15,000/mo              ││
│  │ Estimated Impact: Reach +40%, Est. ROAS: 3.5x           ││
│  │ Risk Score: 75/100 (High spend increase)                ││
│  │ Requested: 15 minutes ago | SLA: 1h 45m remaining       ││
│  │                                                          ││
│  │ [View Details] [Approve] [Reject] [Escalate]            ││
│  └─────────────────────────────────────────────────────────┘│
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ 🟡 MEDIUM RISK - Campaign Publish                       ││
│  │ User: sarah.jones@example.com                           ││
│  │ Agent: Content Generation Agent                         ││
│  │ Action: Publish 15 social media posts                   ││
│  │ Platforms: Instagram (10), TikTok (5)                   ││
│  │ Estimated Reach: 250K impressions                       ││
│  │ Risk Score: 45/100 (Standard content review)            ││
│  │ Requested: 1 hour ago | SLA: 23h remaining              ││
│  │                                                          ││
│  │ [View Details] [Approve] [Reject] [Request Changes]     ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Risk Assessment System

#### Risk Levels

| Level | Score | Criteria | Approval Required |
|-------|-------|----------|-------------------|
| **Low** | 0-30 | Small budget (<$500), low reach, standard actions | Auto-approved (optional review) |
| **Medium** | 31-60 | Moderate budget ($500-$5K), medium reach | Single manager approval |
| **High** | 61-85 | Large budget ($5K-$25K), high reach, sensitive content | Multi-level approval |
| **Critical** | 86-100 | Very large budget (>$25K), brand risk, regulatory concerns | Executive approval + compliance review |

#### Risk Calculation Factors

```python
def calculate_risk_score(action: HITLApproval) -> float:
    score = 0

    # Financial impact (max 40 points)
    if action.estimated_cost:
        if action.estimated_cost > 25000:
            score += 40
        elif action.estimated_cost > 5000:
            score += 30
        elif action.estimated_cost > 500:
            score += 15

    # Reach impact (max 30 points)
    if action.estimated_reach:
        if action.estimated_reach > 1000000:
            score += 30
        elif action.estimated_reach > 100000:
            score += 20
        elif action.estimated_reach > 10000:
            score += 10

    # Action type risk (max 20 points)
    high_risk_actions = ['budget_increase', 'campaign_delete', 'data_export']
    if action.action_type in high_risk_actions:
        score += 20

    # Historical user risk (max 10 points)
    user_risk_history = get_user_risk_score(action.requested_by)
    score += user_risk_history * 10

    return min(score, 100)
```

### Approval Workflows

#### Workflow Configuration

```python
# Database: hitl_workflows
{
    "id": "uuid",
    "name": "Standard Budget Approval",
    "action_types": ["budget_increase", "budget_allocation"],
    "risk_levels": ["medium", "high"],
    "approval_levels": [
        {
            "level": 1,
            "approver_roles": ["marketing_manager"],
            "required_count": 1,
            "sla_hours": 2
        },
        {
            "level": 2,
            "approver_roles": ["director_marketing", "cfo"],
            "required_count": 1,
            "sla_hours": 24
        }
    ],
    "sla_hours": 24,
    "escalation_hours": 12,
    "notification_channels": ["email", "in_app", "slack"]
}
```

#### Approval Process Flow

```
Action Triggered by Walker Agent
  ↓
Calculate Risk Score
  ↓
Determine Workflow (based on action type + risk level)
  ↓
Create HITL Approval Record
  ↓
Notify Approver(s) (Email, In-app, Slack)
  ↓
Approver Reviews:
  - View action details
  - Preview impact
  - Check compliance
  ↓
Decision:
  - Approve → Execute action + Log
  - Reject → Notify user + Log reason
  - Escalate → Route to higher level
  - Request Changes → Send feedback to user
  ↓
Update HITL Record
  ↓
Send Notifications (user, admins, audit)
```

### Approval Actions

#### Approve

```python
@router.post("/api/v1/admin/hitl/{approval_id}/approve")
async def approve_hitl_request(
    approval_id: str,
    approval_notes: str = None,
    current_admin: User = Depends(get_current_admin)
):
    # 1. Validate admin has approval permissions
    if not current_admin.can_approve_hitl():
        raise HTTPException(403, "Insufficient permissions")

    # 2. Get approval request
    approval = db.query(HITLApproval).get(approval_id)

    # 3. Update status
    approval.status = ApprovalStatus.APPROVED
    approval.approved_by = current_admin.id
    approval.approved_at = datetime.utcnow()
    approval.approval_notes = approval_notes

    # 4. Execute the approved action
    execution_result = await execute_approved_action(approval)

    # 5. Log to audit trail
    log_approval_history(
        approval_id=approval_id,
        event_type="approved",
        actor_id=current_admin.id,
        notes=approval_notes
    )

    # 6. Notify user
    notify_user(
        user_id=approval.requested_by,
        message=f"Your request has been approved and executed.",
        result=execution_result
    )

    return {
        "status": "approved",
        "execution_result": execution_result
    }
```

#### Reject

```python
@router.post("/api/v1/admin/hitl/{approval_id}/reject")
async def reject_hitl_request(
    approval_id: str,
    rejection_reason: str,
    current_admin: User = Depends(get_current_admin)
):
    # Similar to approve, but:
    # - Set status to REJECTED
    # - Don't execute action
    # - Require rejection_reason
    # - Notify user with reason

    approval.status = ApprovalStatus.REJECTED
    approval.rejected_by = current_admin.id
    approval.rejected_at = datetime.utcnow()
    approval.rejection_reason = rejection_reason

    notify_user(
        user_id=approval.requested_by,
        message=f"Your request was not approved: {rejection_reason}"
    )
```

### SLA Tracking

```python
# SLA Breach Monitoring (Background Job)
async def monitor_sla_breaches():
    while True:
        # Find approvals approaching SLA deadline
        approaching_deadline = db.query(HITLApproval).filter(
            HITLApproval.status == ApprovalStatus.PENDING,
            HITLApproval.sla_deadline <= datetime.utcnow() + timedelta(hours=1),
            HITLApproval.sla_breached == False
        ).all()

        for approval in approaching_deadline:
            # Send urgent reminder
            send_urgent_reminder(approval)

        # Mark breached SLAs
        breached = db.query(HITLApproval).filter(
            HITLApproval.status == ApprovalStatus.PENDING,
            HITLApproval.sla_deadline < datetime.utcnow(),
            HITLApproval.sla_breached == False
        ).all()

        for approval in breached:
            approval.sla_breached = True
            approval.sla_breach_duration_minutes = (
                datetime.utcnow() - approval.sla_deadline
            ).total_seconds() / 60

            # Escalate
            escalate_approval(approval)

        await asyncio.sleep(300)  # Check every 5 minutes
```

---

## Analytics and Performance Tracking

### Admin Analytics Dashboard

#### Key Metrics

```
┌─────────────────────────────────────────────────────────────┐
│  Walker Agents Performance Analytics                         │
├─────────────────────────────────────────────────────────────┤
│  📊 Overview (Last 30 Days)                                  │
│  ┌────────────┬────────────┬────────────┬────────────┐      │
│  │Total Convs │  Messages  │  Avg CSAT  │ Resolution │      │
│  │   2,543    │   45,821   │    4.7/5   │   94.2%    │      │
│  └────────────┴────────────┴────────────┴────────────┘      │
│                                                              │
│  📈 Trends                                                   │
│  [Chart: Conversations per day - Line graph]                │
│                                                              │
│  🤖 By Walker Agent                                          │
│  ┌──────────────────┬────────┬──────────┬──────┬──────┐    │
│  │ Agent            │ Convs  │ Messages │ CSAT │Active│    │
│  ├──────────────────┼────────┼──────────┼──────┼──────┤    │
│  │ Paid Ads         │  892   │  16,234  │ 4.8  │ 234  │    │
│  │ SEO              │  654   │  12,108  │ 4.6  │ 187  │    │
│  │ Content Gen      │  721   │  11,982  │ 4.7  │ 201  │    │
│  │ Audience Intel   │  276   │   5,497  │ 4.8  │  89  │    │
│  └──────────────────┴────────┴──────────┴──────┴──────┘    │
│                                                              │
│  📱 By Channel                                               │
│  [Pie Chart: WhatsApp 45% | Chat UI 38% | Email 17%]       │
│                                                              │
│  ⏱️ Response Time                                            │
│  Average: 1.2s | P50: 0.8s | P95: 3.4s | P99: 8.1s         │
│  [Chart: Response time distribution]                        │
│                                                              │
│  ⚠️ HITL Approvals                                           │
│  Pending: 12 | Approved: 234 | Rejected: 18                │
│  Avg Approval Time: 2.3 hours | SLA Compliance: 96.8%      │
└─────────────────────────────────────────────────────────────┘
```

### Tracked Metrics

#### Conversation Metrics

```python
# Metrics tracked per conversation
{
    "conversation_id": "uuid",
    "user_id": "uuid",
    "agent_type": "paid_ads_optimization",
    "channel": "whatsapp",
    "started_at": "timestamp",
    "ended_at": "timestamp",
    "duration_seconds": 1234,
    "message_count": 23,
    "user_messages": 12,
    "agent_messages": 11,
    "avg_response_time_ms": 1200,
    "user_satisfaction_score": 5,  # 1-5 stars
    "issue_resolved": True,
    "escalated_to_human": False,
    "hitl_approvals_count": 2
}
```

#### Performance Tracking

```python
# platform_event_log entries for analytics
{
    "event_type": "walker_agent_conversation",
    "tenant_id": "uuid",
    "user_id": "uuid",
    "agent_type": "paid_ads_optimization",
    "channel": "whatsapp",
    "metadata": {
        "conversation_id": "uuid",
        "message_count": 23,
        "duration_seconds": 1234,
        "actions_performed": ["budget_increase", "campaign_create"],
        "sentiment_score": 0.85,  # -1 to 1
        "topics": ["budget", "roas", "meta_ads"]
    },
    "created_at": "timestamp"
}
```

### Real-Time Analytics API

```python
@router.get("/api/v1/admin/analytics/walker-agents/realtime")
async def get_realtime_analytics(
    current_admin: User = Depends(get_current_admin)
):
    # Active conversations right now
    active_convs = db.query(ConversationalAnalyticsLog).filter(
        ConversationalAnalyticsLog.created_at >= datetime.utcnow() - timedelta(minutes=15),
        ConversationalAnalyticsLog.tenant_id == current_admin.tenant_id
    ).count()

    # Messages in last hour
    recent_messages = db.query(ConversationalAnalyticsLog).filter(
        ConversationalAnalyticsLog.created_at >= datetime.utcnow() - timedelta(hours=1)
    ).count()

    # Average response time (last 100 messages)
    avg_response_time = calculate_avg_response_time(limit=100)

    # HITL queue status
    hitl_pending = db.query(HITLApproval).filter(
        HITLApproval.status == ApprovalStatus.PENDING
    ).count()

    return {
        "active_conversations": active_convs,
        "messages_last_hour": recent_messages,
        "avg_response_time_ms": avg_response_time,
        "hitl_pending_count": hitl_pending,
        "timestamp": datetime.utcnow().isoformat()
    }
```

---

## Privacy and Security

### Data Protection Principles

1. **Data Minimization:** Collect only necessary data
2. **Purpose Limitation:** Use data only for stated purposes
3. **Storage Limitation:** Retain data only as long as needed
4. **Access Control:** Strict RBAC for all data access
5. **Encryption:** At-rest and in-transit encryption
6. **Audit Trail:** Complete logging of data access

### PII Handling

#### PII Data Types

| Data Type | Storage | Encryption | Access Level |
|-----------|---------|------------|--------------|
| Email Addresses | PostgreSQL | AES-256 | Admin, Compliance |
| Phone Numbers | PostgreSQL | AES-256 | Admin, Compliance |
| Conversation Content | PostgreSQL | AES-256 | Admin (masked by default) |
| IP Addresses | Logs only | SHA-256 hashed | Security, Compliance |
| Payment Info | Not stored | N/A | None |
| API Keys | Vault | AES-256 | Engineering, Admin |

#### Data Retention Policy

```python
# Automated data cleanup policies
RETENTION_POLICIES = {
    "conversation_logs": {
        "active_users": 365,  # days
        "inactive_users": 90,
        "deleted_users": 30
    },
    "platform_event_logs": {
        "raw_events": 90,
        "aggregated_analytics": 730  # 2 years
    },
    "hitl_approvals": {
        "approved": 1095,  # 3 years for compliance
        "rejected": 365,
        "expired": 90
    },
    "admin_access_logs": {
        "all": 2555  # 7 years for compliance
    }
}
```

### Encryption Implementation

```python
from cryptography.fernet import Fernet

class PIIEncryption:
    def __init__(self, encryption_key: str):
        self.cipher = Fernet(encryption_key.encode())

    def encrypt_pii(self, plaintext: str) -> str:
        """Encrypt sensitive PII data"""
        return self.cipher.encrypt(plaintext.encode()).decode()

    def decrypt_pii(self, ciphertext: str) -> str:
        """Decrypt PII (audit logged)"""
        # Log decryption access
        log_pii_access(
            data_type="decrypt",
            user_id=current_user.id,
            timestamp=datetime.utcnow()
        )
        return self.cipher.decrypt(ciphertext.encode()).decode()

# Usage
encryption = PIIEncryption(settings.PII_ENCRYPTION_KEY)
user.email_encrypted = encryption.encrypt_pii(user.email)
```

### Compliance Features

#### GDPR Compliance

1. **Right to Access:** User can export all their data
2. **Right to Rectification:** Users can update their data
3. **Right to Erasure:** Users can delete their account and data
4. **Right to Portability:** Data export in JSON format
5. **Consent Management:** Explicit opt-in for data collection

#### Data Export API

```python
@router.get("/api/v1/users/me/export-data")
async def export_user_data(
    current_user: User = Depends(get_current_user)
):
    # Collect all user data
    data = {
        "user_profile": current_user.to_dict(),
        "conversations": get_user_conversations(current_user.id),
        "walker_agent_interactions": get_agent_interactions(current_user.id),
        "hitl_requests": get_user_hitl_requests(current_user.id),
        "preferences": get_user_preferences(current_user.id)
    }

    # Generate downloadable file
    filename = f"engarde_data_export_{current_user.id}_{datetime.utcnow().strftime('%Y%m%d')}.json"

    return JSONResponse(
        content=data,
        headers={
            "Content-Disposition": f"attachment; filename={filename}"
        }
    )
```

#### Account Deletion

```python
@router.delete("/api/v1/users/me/delete-account")
async def delete_user_account(
    confirmation: str,  # Must type "DELETE MY ACCOUNT"
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if confirmation != "DELETE MY ACCOUNT":
        raise HTTPException(400, "Invalid confirmation")

    # 1. Anonymize conversation data
    anonymize_conversations(current_user.id, db)

    # 2. Delete PII
    delete_user_pii(current_user.id, db)

    # 3. Retain anonymized analytics (compliance)
    retain_anonymous_analytics(current_user.id, db)

    # 4. Mark user as deleted
    current_user.is_deleted = True
    current_user.deleted_at = datetime.utcnow()
    current_user.email = f"deleted_{current_user.id}@example.com"

    db.commit()

    return {"status": "account_deleted"}
```

---

## API Endpoints

### Communication Channels

#### WhatsApp

```
POST /api/v1/channels/whatsapp/webhook
  - Receives incoming WhatsApp messages from Twilio
  - Processes message and routes to Walker Agent
  - Sends response back via Twilio

GET /api/v1/channels/whatsapp/conversations/{user_id}
  - Lists all WhatsApp conversations for a user
  - Paginated results

POST /api/v1/channels/whatsapp/send
  - Manually send WhatsApp message (admin feature)
  - Body: { "to": "+1234567890", "message": "text" }
```

#### Email

```
POST /api/v1/channels/email/send-daily-brief/{user_id}
  - Triggers daily brief generation and sending
  - Called by scheduled job

GET /api/v1/channels/email/preferences/{user_id}
  - Get user email preferences

PUT /api/v1/channels/email/preferences/{user_id}
  - Update email preferences
  - Body: { "enabled": true, "delivery_time": "08:00", "timezone": "America/New_York" }

POST /api/v1/channels/email/unsubscribe
  - Unsubscribe from daily briefs
```

#### Chat UI

```
WS /ws/chat
  - WebSocket endpoint for real-time chat

GET /api/v1/channels/chat/conversations
  - List all chat conversations for current user

GET /api/v1/channels/chat/conversations/{conversation_id}
  - Get conversation details and message history

POST /api/v1/channels/chat/conversations
  - Create new conversation
  - Body: { "agent_type": "paid_ads_optimization" }

DELETE /api/v1/channels/chat/conversations/{conversation_id}
  - Delete conversation (soft delete)
```

### Walker Agents

```
GET /api/v1/ai-agents/walker/list
  - List all Walker Agents for current tenant

GET /api/v1/ai-agents/walker/{agent_id}
  - Get Walker Agent details

GET /api/v1/ai-agents/walker/{agent_id}/analytics
  - Get performance analytics for specific Walker Agent

POST /api/v1/ai-agents/walker/{agent_id}/execute
  - Execute Walker Agent workflow
  - Body: { "input": "query text", "context": {} }
```

### Admin Monitoring

```
GET /api/v1/admin/conversations
  - List all conversations (paginated, filtered)
  - Query params: channel, agent_type, user_id, date_from, date_to, status

GET /api/v1/admin/conversations/{conversation_id}
  - Get conversation detail

POST /api/v1/admin/conversations/search
  - Advanced search
  - Body: { "query": "text", "filters": {...} }

GET /api/v1/admin/analytics/dashboard
  - Admin analytics dashboard data

GET /api/v1/admin/analytics/walker-agents/realtime
  - Real-time metrics

GET /api/v1/admin/analytics/export
  - Export analytics data (CSV/JSON)
```

### HITL Approvals

```
GET /api/v1/admin/hitl/queue
  - Get HITL approval queue
  - Query params: status, priority, risk_level, assigned_to

GET /api/v1/admin/hitl/{approval_id}
  - Get approval details

POST /api/v1/admin/hitl/{approval_id}/approve
  - Approve request
  - Body: { "notes": "optional" }

POST /api/v1/admin/hitl/{approval_id}/reject
  - Reject request
  - Body: { "reason": "required" }

POST /api/v1/admin/hitl/{approval_id}/escalate
  - Escalate to higher level
  - Body: { "escalate_to": "user_id", "reason": "text" }

GET /api/v1/admin/hitl/analytics
  - HITL system analytics
```

---

## Deployment and Configuration

### Environment Variables

```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/engarde

# Twilio (WhatsApp)
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_WHATSAPP_NUMBER=+14155238886

# SendGrid (Email)
SENDGRID_API_KEY=SG.xxxxxxxxxxxxxxxxxxxxxxx
SENDGRID_FROM_EMAIL=noreply@engarde.com
SENDGRID_FROM_NAME=En Garde

# Langflow
LANGFLOW_API_URL=https://langflow.engarde.com
LANGFLOW_API_KEY=lf_xxxxxxxxxxxxxxx

# Encryption
PII_ENCRYPTION_KEY=base64_encoded_key

# WebSocket
REDIS_URL=redis://localhost:6379/0

# Security
JWT_SECRET_KEY=your_secret_key
ADMIN_ACCESS_LOG_ENABLED=true

# Features
ENABLE_WHATSAPP=true
ENABLE_EMAIL_BRIEFS=true
ENABLE_CHAT_UI=true
ENABLE_HITL=true
```

### Docker Compose

```yaml
version: '3.8'

services:
  backend:
    image: engarde/backend:latest
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - TWILIO_ACCOUNT_SID=${TWILIO_ACCOUNT_SID}
      - TWILIO_AUTH_TOKEN=${TWILIO_AUTH_TOKEN}
      - SENDGRID_API_KEY=${SENDGRID_API_KEY}
    depends_on:
      - db
      - redis

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=engarde
      - POSTGRES_USER=engarde
      - POSTGRES_PASSWORD=secure_password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  celery_worker:
    image: engarde/backend:latest
    command: celery -A app.celery_app worker --loglevel=info
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis

  celery_beat:
    image: engarde/backend:latest
    command: celery -A app.celery_app beat --loglevel=info
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis

volumes:
  postgres_data:
```

### Database Migrations

```bash
# Apply migrations
alembic upgrade head

# Create migration for conversation tables
alembic revision --autogenerate -m "Add conversational analytics tables"

# Create HITL tables
alembic revision --autogenerate -m "Add HITL approval system tables"
```

### Scheduled Jobs (Celery)

```python
from celery import Celery
from celery.schedules import crontab

app = Celery('engarde')

# Daily brief sending
@app.task
def send_daily_briefs():
    """Send daily email briefs to all subscribed users"""
    users = get_subscribed_users()
    for user in users:
        trigger_daily_brief(user.id)

# SLA monitoring
@app.task
def monitor_hitl_sla():
    """Check for HITL SLA breaches and escalate"""
    check_sla_breaches()

# Analytics aggregation
@app.task
def aggregate_analytics():
    """Aggregate conversation analytics"""
    aggregate_daily_metrics()

# Configure schedule
app.conf.beat_schedule = {
    'send-daily-briefs': {
        'task': 'send_daily_briefs',
        'schedule': crontab(hour=8, minute=0)  # 8 AM daily
    },
    'monitor-hitl-sla': {
        'task': 'monitor_hitl_sla',
        'schedule': 300.0  # Every 5 minutes
    },
    'aggregate-analytics': {
        'task': 'aggregate_analytics',
        'schedule': crontab(hour=1, minute=0)  # 1 AM daily
    }
}
```

---

## Success Metrics

### User Engagement Metrics

| Metric | Target | Current |
|--------|--------|---------|
| Daily Active Conversations | >1,000 | 2,543 |
| WhatsApp Engagement Rate | >60% | 72% |
| Email Open Rate (Daily Brief) | >45% | 58% |
| Chat UI Session Duration | >5 min | 7.2 min |
| User Satisfaction (CSAT) | >4.5/5 | 4.7/5 |
| Issue Resolution Rate | >90% | 94.2% |

### Walker Agent Performance

| Agent | Conversations/Day | Avg Response Time | CSAT | Resolution Rate |
|-------|-------------------|-------------------|------|-----------------|
| Paid Ads | 298 | 1.1s | 4.8 | 96% |
| SEO | 218 | 1.3s | 4.6 | 92% |
| Content Gen | 241 | 0.9s | 4.7 | 95% |
| Audience Intel | 92 | 1.4s | 4.8 | 93% |

### Admin Efficiency Metrics

| Metric | Target | Current |
|--------|--------|---------|
| HITL Approval Time | <3 hours | 2.3 hours |
| SLA Compliance | >95% | 96.8% |
| Conversation Monitoring Coverage | 100% | 100% |
| Admin Response Time | <1 hour | 38 min |

### System Performance

| Metric | Target | Current |
|--------|--------|---------|
| API Response Time (P95) | <500ms | 387ms |
| WebSocket Latency | <100ms | 72ms |
| Uptime | >99.9% | 99.97% |
| Error Rate | <0.1% | 0.03% |

---

## Roadmap

### Q1 2026

- [ ] Voice integration (voice notes in WhatsApp/Chat)
- [ ] Slack integration for team collaboration
- [ ] Advanced HITL workflows (conditional approvals)
- [ ] Sentiment analysis in real-time
- [ ] Multi-language support (Spanish, French, Mandarin)

### Q2 2026

- [ ] Mobile apps (iOS/Android) with push notifications
- [ ] Video call integration with agents
- [ ] Automated A/B testing for agent responses
- [ ] Predictive HITL (suggest approvals before request)
- [ ] Advanced analytics with ML insights

### Q3 2026

- [ ] Agent personality customization
- [ ] Industry-specific Walker Agents (e-commerce, SaaS, B2B)
- [ ] Integration with CRM systems (Salesforce, HubSpot)
- [ ] White-label solution for enterprise
- [ ] Agent collaboration (multi-agent problem solving)

---

**Document Version:** 2.0
**Last Updated:** December 25, 2025
**Next Review:** January 25, 2026
**Maintained By:** Product & Engineering Team
