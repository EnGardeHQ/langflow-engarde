# Walker Agents Communication Channels - API Documentation

**Version:** 1.0
**Last Updated:** December 25, 2025
**Base URL:** `https://api.engarde.com/api/v1`

---

## Table of Contents

1. [Authentication](#authentication)
2. [Communication Channels APIs](#communication-channels-apis)
3. [Walker Agents APIs](#walker-agents-apis)
4. [Admin Monitoring APIs](#admin-monitoring-apis)
5. [HITL Approval APIs](#hitl-approval-apis)
6. [Analytics APIs](#analytics-apis)
7. [WebSocket Protocol](#websocket-protocol)
8. [Error Handling](#error-handling)
9. [Rate Limits](#rate-limits)

---

## Authentication

All API requests require authentication using JWT Bearer tokens.

### Headers

```http
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

### Get Access Token

```http
POST /auth/login
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "secure_password"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "role": "admin",
    "tenant_id": "123e4567-e89b-12d3-a456-426614174000"
  }
}
```

---

## Communication Channels APIs

### WhatsApp Channel

#### Receive WhatsApp Message (Webhook)

```http
POST /channels/whatsapp/webhook
```

This endpoint receives incoming WhatsApp messages from Twilio.

**Request (Form Data from Twilio):**
```
Body=How's my Meta campaign?
From=+14155551234
To=+14155238886
MessageSid=SM1234567890abcdef
```

**Response:**
```json
{
  "status": "success",
  "response": "Your Meta campaign has a ROAS of 3.2x...",
  "twilio_status": "sent"
}
```

**Error Response:**
```json
{
  "status": "error",
  "message": "User not found for phone number",
  "error_code": "USER_NOT_FOUND"
}
```

---

#### List WhatsApp Conversations

```http
GET /channels/whatsapp/conversations/{user_id}
```

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| page | integer | No | Page number (default: 1) |
| limit | integer | No | Items per page (default: 20, max: 100) |
| start_date | string | No | Filter by start date (ISO 8601) |
| end_date | string | No | Filter by end date (ISO 8601) |

**Response:**
```json
{
  "conversations": [
    {
      "session_id": "sess_12345",
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "agent_type": "paid_ads_optimization",
      "message_count": 23,
      "started_at": "2025-12-24T14:30:00Z",
      "ended_at": "2025-12-24T15:45:00Z",
      "duration_seconds": 4500,
      "channel": "whatsapp",
      "status": "completed"
    }
  ],
  "total": 45,
  "page": 1,
  "limit": 20,
  "pages": 3
}
```

---

### Email Channel

#### Trigger Daily Brief

```http
POST /channels/email/send-daily-brief/{user_id}
```

**Path Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| user_id | string (UUID) | Yes | User ID to send brief to |

**Response:**
```json
{
  "status": "sent",
  "message_id": "msg_abc123",
  "workflow_id": "wf_456def",
  "sent_at": "2025-12-25T08:00:00Z"
}
```

**Error Response:**
```json
{
  "status": "skipped",
  "reason": "user_disabled",
  "message": "User has disabled daily briefs"
}
```

---

#### Get Email Preferences

```http
GET /channels/email/preferences/{user_id}
```

**Response:**
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "enabled": true,
  "delivery_time": "08:00",
  "timezone": "America/New_York",
  "frequency": "daily",
  "include_sections": [
    "paid_ads",
    "seo",
    "content",
    "audience"
  ],
  "min_priority": "medium",
  "digest_format": "full"
}
```

---

#### Update Email Preferences

```http
PUT /channels/email/preferences/{user_id}
```

**Request Body:**
```json
{
  "enabled": true,
  "delivery_time": "09:00",
  "timezone": "America/Los_Angeles",
  "include_sections": ["paid_ads", "seo"],
  "min_priority": "high"
}
```

**Response:**
```json
{
  "message": "Preferences updated successfully",
  "preferences": {
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "enabled": true,
    "delivery_time": "09:00",
    "timezone": "America/Los_Angeles",
    "include_sections": ["paid_ads", "seo"],
    "min_priority": "high"
  }
}
```

---

### Chat Channel

#### Create Conversation

```http
POST /channels/chat/conversations
```

**Request Body:**
```json
{
  "agent_type": "paid_ads_optimization",
  "initial_message": "I need help with my Meta campaign"
}
```

**Response:**
```json
{
  "conversation_id": "conv_789ghi",
  "session_id": "sess_12345",
  "agent_type": "paid_ads_optimization",
  "created_at": "2025-12-25T10:30:00Z",
  "websocket_url": "wss://api.engarde.com/ws/chat"
}
```

---

#### Get Conversation History

```http
GET /channels/chat/conversations/{conversation_id}
```

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| limit | integer | No | Number of messages (default: 50) |
| before | string | No | Cursor for pagination (message ID) |

**Response:**
```json
{
  "conversation_id": "conv_789ghi",
  "session_id": "sess_12345",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "agent_type": "paid_ads_optimization",
  "started_at": "2025-12-25T10:30:00Z",
  "messages": [
    {
      "id": "msg_001",
      "type": "user",
      "content": "I need help with my Meta campaign",
      "timestamp": "2025-12-25T10:30:15Z"
    },
    {
      "id": "msg_002",
      "type": "agent",
      "content": "I'd be happy to help! Let me check your campaign performance...",
      "timestamp": "2025-12-25T10:30:18Z",
      "metadata": {
        "response_time_ms": 1234
      }
    }
  ],
  "has_more": false
}
```

---

#### Delete Conversation

```http
DELETE /channels/chat/conversations/{conversation_id}
```

**Response:**
```json
{
  "message": "Conversation deleted successfully",
  "conversation_id": "conv_789ghi",
  "deleted_at": "2025-12-25T11:00:00Z"
}
```

---

## Walker Agents APIs

### List Walker Agents

```http
GET /ai-agents/walker/list
```

Returns all Walker Agents for the current tenant.

**Response:**
```json
{
  "success": true,
  "agents": [
    {
      "id": "agent_001",
      "name": "Paid Ads Marketing",
      "agent_type": "paid_ads_optimization",
      "agent_category": "walker",
      "is_system_agent": true,
      "status": "active",
      "version": "2.1.0",
      "capabilities": [
        "Campaign performance analysis",
        "Bid strategy optimization",
        "Audience targeting",
        "ROAS improvement"
      ],
      "configuration": {
        "optimization_goal": "maximize_roas",
        "min_roas_target": 2.0,
        "auto_bid_adjustment": true
      },
      "requires_api_key": true,
      "created_at": "2025-01-01T00:00:00Z"
    },
    {
      "id": "agent_002",
      "name": "SEO",
      "agent_type": "seo_optimization",
      "agent_category": "walker",
      "is_system_agent": true,
      "status": "active",
      "version": "1.8.5",
      "capabilities": [
        "Technical SEO audit",
        "Keyword research",
        "Content optimization"
      ],
      "requires_api_key": false
    }
  ],
  "count": 4,
  "agent_category": "walker"
}
```

---

### Get Walker Agent Details

```http
GET /ai-agents/walker/{agent_id}
```

**Response:**
```json
{
  "id": "agent_001",
  "name": "Paid Ads Marketing",
  "agent_type": "paid_ads_optimization",
  "agent_category": "walker",
  "is_system_agent": true,
  "status": "active",
  "version": "2.1.0",
  "description": "Intelligent paid advertising campaign optimization focused on increasing ROAS",
  "capabilities": [
    "Campaign performance analysis",
    "Bid strategy optimization",
    "Audience targeting",
    "ROAS improvement",
    "Budget allocation",
    "Ad creative testing"
  ],
  "supported_platforms": [
    "Meta (Facebook/Instagram)",
    "TikTok",
    "Google Ads",
    "LinkedIn"
  ],
  "configuration": {
    "optimization_goal": "maximize_roas",
    "min_roas_target": 2.0,
    "auto_bid_adjustment": true,
    "budget_pacing": "even"
  },
  "performance_stats": {
    "total_executions": 1234,
    "avg_response_time_ms": 1156,
    "success_rate": 0.987,
    "avg_csat": 4.8
  }
}
```

---

### Execute Walker Agent

```http
POST /ai-agents/walker/{agent_id}/execute
```

**Request Body:**
```json
{
  "input": "What's my current ROAS across all platforms?",
  "context": {
    "conversation_id": "conv_789ghi",
    "user_preferences": {
      "include_charts": true
    }
  }
}
```

**Response:**
```json
{
  "execution_id": "exec_12345",
  "agent_id": "agent_001",
  "status": "completed",
  "output": "Your overall ROAS across platforms: Meta 3.2x, Google Ads 2.8x, TikTok 4.1x, LinkedIn 1.9x",
  "metadata": {
    "execution_time_ms": 1234,
    "workflow_instance_id": "wf_inst_456",
    "data_sources": ["meta_api", "google_ads_api", "tiktok_api"]
  },
  "actions_required": null,
  "completed_at": "2025-12-25T10:35:18Z"
}
```

**Response (HITL Required):**
```json
{
  "execution_id": "exec_12345",
  "agent_id": "agent_001",
  "status": "pending_approval",
  "output": "Budget increase requires approval. I've created an approval request.",
  "approval_request": {
    "approval_id": "BR-12345",
    "action_type": "budget_increase",
    "estimated_impact": {
      "cost": 5000,
      "reach_increase": "40%"
    },
    "approver": "jane.smith@acme.com",
    "estimated_approval_time": "2 hours"
  },
  "completed_at": "2025-12-25T10:35:20Z"
}
```

---

### Get Walker Agent Analytics

```http
GET /ai-agents/walker/{agent_id}/analytics
```

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| start_date | string | No | Start date (ISO 8601) |
| end_date | string | No | End date (ISO 8601) |
| metrics | string[] | No | Specific metrics to return |

**Response:**
```json
{
  "agent_id": "agent_001",
  "agent_name": "Paid Ads Marketing",
  "period": {
    "start": "2025-11-25T00:00:00Z",
    "end": "2025-12-25T23:59:59Z"
  },
  "metrics": {
    "total_conversations": 892,
    "total_messages": 16234,
    "avg_messages_per_conversation": 18.2,
    "avg_response_time_ms": 1156,
    "median_response_time_ms": 890,
    "p95_response_time_ms": 3421,
    "user_satisfaction_avg": 4.8,
    "issue_resolution_rate": 0.96,
    "hitl_approval_count": 67,
    "hitl_approval_rate": 0.95
  },
  "trends": {
    "conversations_per_day": [
      {"date": "2025-12-24", "count": 34},
      {"date": "2025-12-25", "count": 29}
    ],
    "satisfaction_trend": [
      {"date": "2025-12-24", "score": 4.7},
      {"date": "2025-12-25", "score": 4.8}
    ]
  },
  "top_queries": [
    {"query": "What's my ROAS?", "count": 123},
    {"query": "Increase budget", "count": 89},
    {"query": "Campaign performance", "count": 76}
  ]
}
```

---

## Admin Monitoring APIs

### List All Conversations

```http
GET /admin/conversations
```

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| page | integer | No | Page number (default: 1) |
| limit | integer | No | Items per page (default: 20) |
| channel | string | No | Filter by channel (whatsapp, email, chat) |
| agent_type | string | No | Filter by agent type |
| user_id | string | No | Filter by user ID |
| date_from | string | No | Start date (ISO 8601) |
| date_to | string | No | End date (ISO 8601) |
| status | string | No | Filter by status (active, completed, archived) |

**Response:**
```json
{
  "conversations": [
    {
      "session_id": "sess_12345",
      "user": {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "name": "John Doe",
        "email": "j***@example.com"
      },
      "channel": "whatsapp",
      "agent_type": "paid_ads_optimization",
      "message_count": 23,
      "started_at": "2025-12-24T14:30:00Z",
      "last_message_at": "2025-12-24T15:45:00Z",
      "duration_seconds": 4500,
      "status": "completed",
      "csat_score": 5
    }
  ],
  "total": 234,
  "page": 1,
  "limit": 20,
  "pages": 12
}
```

---

### Get Conversation Details

```http
GET /admin/conversations/{conversation_id}
```

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| show_pii | boolean | No | Show unmasked PII (requires permission) |

**Response:**
```json
{
  "conversation_id": "conv_789ghi",
  "session_id": "sess_12345",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "John Doe",
    "email": "john.doe@example.com",
    "phone": "+14155551234",
    "tenant": "Acme Corp"
  },
  "channel": "whatsapp",
  "agent_type": "paid_ads_optimization",
  "started_at": "2025-12-24T14:30:00Z",
  "ended_at": "2025-12-24T15:45:00Z",
  "duration_seconds": 4500,
  "message_count": 23,
  "status": "completed",
  "csat_score": 5,
  "messages": [
    {
      "id": "msg_001",
      "type": "user",
      "content": "How's my Meta campaign performing?",
      "timestamp": "2025-12-24T14:30:00Z"
    },
    {
      "id": "msg_002",
      "type": "agent",
      "content": "Your Meta campaign has a ROAS of 3.2x...",
      "timestamp": "2025-12-24T14:30:03Z",
      "metadata": {
        "response_time_ms": 1234,
        "workflow_id": "wf_456"
      }
    }
  ],
  "actions_performed": [
    {
      "action_type": "budget_increase",
      "action_data": {"from": 10000, "to": 15000},
      "status": "approved",
      "approval_id": "BR-12345"
    }
  ],
  "audit_log": [
    {
      "timestamp": "2025-12-24T14:30:00Z",
      "event": "conversation_started"
    },
    {
      "timestamp": "2025-12-24T14:35:12Z",
      "event": "hitl_approval_created",
      "approval_id": "BR-12345"
    },
    {
      "timestamp": "2025-12-25T10:30:00Z",
      "event": "admin_view",
      "admin_id": "admin_001"
    }
  ]
}
```

---

### Search Conversations

```http
POST /admin/conversations/search
```

**Request Body:**
```json
{
  "query": "campaign budget",
  "filters": {
    "channels": ["whatsapp", "chat"],
    "agent_types": ["paid_ads_optimization"],
    "date_range": {
      "start": "2025-12-01T00:00:00Z",
      "end": "2025-12-25T23:59:59Z"
    },
    "min_messages": 5,
    "max_messages": 100,
    "sentiment": "positive",
    "contains_actions": ["budget_increase"]
  },
  "page": 1,
  "limit": 20
}
```

**Response:**
```json
{
  "results": [
    {
      "conversation_id": "conv_789ghi",
      "session_id": "sess_12345",
      "user_name": "John Doe",
      "channel": "whatsapp",
      "agent_type": "paid_ads_optimization",
      "message_count": 23,
      "started_at": "2025-12-24T14:30:00Z",
      "relevance_score": 0.95,
      "matched_content": "...increase campaign budget by $5,000..."
    }
  ],
  "total": 47,
  "query": "campaign budget",
  "page": 1,
  "pages": 3
}
```

---

### Get Real-Time Analytics

```http
GET /admin/analytics/walker-agents/realtime
```

**Response:**
```json
{
  "active_conversations": 234,
  "messages_last_hour": 1523,
  "avg_response_time_ms": 1156,
  "hitl_pending_count": 12,
  "timestamp": "2025-12-25T10:30:00Z",
  "by_channel": {
    "whatsapp": 105,
    "chat": 89,
    "email": 40
  },
  "by_agent": {
    "paid_ads_optimization": 98,
    "seo_optimization": 67,
    "content_generation": 45,
    "audience_intelligence": 24
  }
}
```

---

## HITL Approval APIs

### Get HITL Queue

```http
GET /admin/hitl/queue
```

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| status | string | No | Filter by status (pending, approved, rejected) |
| priority | string | No | Filter by priority (1-10) |
| risk_level | string | No | Filter by risk (low, medium, high, critical) |
| assigned_to | string | No | Filter by assigned admin ID |
| page | integer | No | Page number |
| limit | integer | No | Items per page |

**Response:**
```json
{
  "approvals": [
    {
      "id": "BR-12345",
      "tenant_id": "123e4567-e89b-12d3-a456-426614174000",
      "agent_id": "agent_001",
      "agent_type": "paid_ads_optimization",
      "action_type": "budget_increase",
      "action_summary": "Increase Meta Ads budget from $10,000 to $15,000/month",
      "risk_level": "high",
      "risk_score": 75,
      "status": "pending",
      "priority": 8,
      "requested_by": {
        "id": "user_001",
        "name": "John Doe",
        "email": "john.doe@example.com"
      },
      "requested_at": "2025-12-25T10:20:00Z",
      "assigned_to": {
        "id": "admin_001",
        "name": "Jane Smith",
        "email": "jane.smith@acme.com"
      },
      "sla_deadline": "2025-12-25T12:20:00Z",
      "sla_remaining_minutes": 105,
      "estimated_impact": {
        "cost": 5000,
        "reach_increase": "40%",
        "projected_roas": 3.5
      }
    }
  ],
  "summary": {
    "pending": 12,
    "approved_today": 45,
    "rejected_today": 3,
    "sla_compliance_rate": 0.968
  },
  "total": 12,
  "page": 1,
  "pages": 1
}
```

---

### Get Approval Details

```http
GET /admin/hitl/{approval_id}
```

**Response:**
```json
{
  "id": "BR-12345",
  "tenant_id": "123e4567-e89b-12d3-a456-426614174000",
  "agent_id": "agent_001",
  "agent_type": "paid_ads_optimization",
  "action_type": "budget_increase",
  "action_data": {
    "platform": "meta_ads",
    "current_budget": 10000,
    "proposed_budget": 15000,
    "increase_amount": 5000,
    "increase_percentage": 50
  },
  "action_summary": "Increase Meta Ads budget from $10,000 to $15,000/month",
  "action_preview_url": "https://app.engarde.com/campaigns/preview/12345",
  "estimated_cost": 5000,
  "estimated_reach": 343000,
  "risk_level": "high",
  "risk_score": 75,
  "risk_factors": [
    "Large budget increase (50% jump)",
    "Mid-month change may affect planning"
  ],
  "status": "pending",
  "priority": 8,
  "requested_by": {
    "id": "user_001",
    "name": "John Doe",
    "email": "john.doe@example.com",
    "role": "marketing_manager",
    "previous_requests": {
      "total": 23,
      "approved": 21,
      "rejected": 2
    }
  },
  "requested_at": "2025-12-25T10:20:00Z",
  "request_notes": "Holiday campaign performing well, want to scale while opportunity is hot",
  "assigned_to": {
    "id": "admin_001",
    "name": "Jane Smith",
    "email": "jane.smith@acme.com",
    "role": "marketing_director"
  },
  "workflow": {
    "id": "wf_001",
    "name": "Standard Budget Approval",
    "approval_levels": [
      {
        "level": 1,
        "approver_roles": ["marketing_manager"],
        "status": "completed"
      },
      {
        "level": 2,
        "approver_roles": ["marketing_director"],
        "status": "pending"
      }
    ]
  },
  "sla_deadline": "2025-12-25T12:20:00Z",
  "sla_remaining_minutes": 105,
  "compliance_checks": {
    "within_budget_authority": true,
    "no_regulatory_concerns": true,
    "brand_guidelines_compliance": true,
    "requires_director_approval": true
  },
  "estimated_impact": {
    "monthly_spend": {
      "current": 10000,
      "projected": 15000,
      "increase": 5000
    },
    "reach": {
      "current": 245000,
      "projected": 343000,
      "increase_percentage": 40
    },
    "conversions": {
      "current": 156,
      "projected": 234,
      "increase": 78
    },
    "roas": {
      "current": 3.2,
      "projected": 3.5,
      "improvement": 0.3
    },
    "roi_calculation": {
      "additional_revenue": 20500,
      "additional_spend": 5000,
      "roi": 4.1,
      "payback_period_days": 7
    }
  }
}
```

---

### Approve Request

```http
POST /admin/hitl/{approval_id}/approve
```

**Request Body:**
```json
{
  "notes": "Approved. Strong performance justifies scaling. Monitor daily for first week."
}
```

**Response:**
```json
{
  "status": "approved",
  "approval_id": "BR-12345",
  "approved_by": {
    "id": "admin_001",
    "name": "Jane Smith"
  },
  "approved_at": "2025-12-25T10:45:00Z",
  "execution_result": {
    "status": "success",
    "action_executed": true,
    "execution_details": {
      "budget_updated": true,
      "new_budget": 15000,
      "effective_date": "2025-12-25T10:45:30Z"
    }
  },
  "notifications_sent": [
    {
      "recipient": "john.doe@example.com",
      "channel": "email",
      "status": "sent"
    },
    {
      "recipient": "john.doe@example.com",
      "channel": "in_app",
      "status": "delivered"
    }
  ]
}
```

---

### Reject Request

```http
POST /admin/hitl/{approval_id}/reject
```

**Request Body:**
```json
{
  "reason": "Budget increase too large for mid-month. Please resubmit at beginning of next month with detailed forecast."
}
```

**Response:**
```json
{
  "status": "rejected",
  "approval_id": "BR-12345",
  "rejected_by": {
    "id": "admin_001",
    "name": "Jane Smith"
  },
  "rejected_at": "2025-12-25T10:45:00Z",
  "rejection_reason": "Budget increase too large for mid-month...",
  "notifications_sent": [
    {
      "recipient": "john.doe@example.com",
      "channel": "email",
      "status": "sent"
    }
  ]
}
```

---

### Escalate Request

```http
POST /admin/hitl/{approval_id}/escalate
```

**Request Body:**
```json
{
  "escalate_to": "cfo_user_id",
  "reason": "Budget increase exceeds my approval authority. Escalating to CFO."
}
```

**Response:**
```json
{
  "status": "escalated",
  "approval_id": "BR-12345",
  "escalated_by": {
    "id": "admin_001",
    "name": "Jane Smith"
  },
  "escalated_to": {
    "id": "cfo_001",
    "name": "Robert Johnson",
    "role": "cfo"
  },
  "escalated_at": "2025-12-25T10:45:00Z",
  "escalation_reason": "Budget increase exceeds my approval authority..."
}
```

---

## Analytics APIs

### Get Dashboard Analytics

```http
GET /admin/analytics/dashboard
```

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| start_date | string | No | Start date (ISO 8601) |
| end_date | string | No | End date (ISO 8601) |
| granularity | string | No | Data granularity (hour, day, week, month) |

**Response:**
```json
{
  "period": {
    "start": "2025-11-25T00:00:00Z",
    "end": "2025-12-25T23:59:59Z",
    "days": 30
  },
  "overview": {
    "total_conversations": 2543,
    "total_messages": 45821,
    "avg_response_time_ms": 1200,
    "avg_csat": 4.7,
    "issue_resolution_rate": 0.942
  },
  "by_channel": {
    "whatsapp": {
      "conversations": 1144,
      "messages": 20620,
      "percentage": 45
    },
    "chat": {
      "conversations": 966,
      "messages": 17412,
      "percentage": 38
    },
    "email": {
      "conversations": 433,
      "messages": 7789,
      "percentage": 17
    }
  },
  "by_agent": [
    {
      "agent_type": "paid_ads_optimization",
      "name": "Paid Ads Marketing",
      "conversations": 892,
      "messages": 16234,
      "avg_csat": 4.8,
      "active_users": 234
    },
    {
      "agent_type": "seo_optimization",
      "name": "SEO",
      "conversations": 654,
      "messages": 12108,
      "avg_csat": 4.6,
      "active_users": 187
    }
  ],
  "trends": {
    "conversations_per_day": [
      {"date": "2025-12-24", "count": 89},
      {"date": "2025-12-25", "count": 78}
    ],
    "response_time_trend": [
      {"date": "2025-12-24", "avg_ms": 1250},
      {"date": "2025-12-25", "avg_ms": 1150}
    ]
  },
  "hitl_summary": {
    "pending": 12,
    "approved_in_period": 234,
    "rejected_in_period": 18,
    "avg_approval_time_hours": 2.3,
    "sla_compliance_rate": 0.968
  }
}
```

---

## WebSocket Protocol

### Connect to Chat WebSocket

```
wss://api.engarde.com/ws/chat
```

**Authentication:**
```javascript
const socket = io('wss://api.engarde.com', {
  auth: {
    token: 'your_jwt_token'
  },
  transports: ['websocket']
});
```

### Client Events

#### Join Conversation

```javascript
socket.emit('join_conversation', {
  conversation_id: 'conv_789ghi'
});
```

#### Send Message

```javascript
socket.emit('send_message', {
  conversation_id: 'conv_789ghi',
  message: 'What is my current ROAS?',
  agent_type: 'paid_ads_optimization'
});
```

### Server Events

#### Message Received

```javascript
socket.on('message_received', (data) => {
  // data: {message_id, status: 'received', timestamp}
});
```

#### Agent Typing

```javascript
socket.on('agent_typing', (data) => {
  // data: {agent_type, is_typing: true}
});
```

#### Agent Response

```javascript
socket.on('agent_response', (data) => {
  /*
  data: {
    message_id: 'msg_002',
    content: 'Your overall ROAS is...',
    metadata: {
      response_time_ms: 1234,
      workflow_id: 'wf_456'
    },
    timestamp: '2025-12-25T10:35:18Z'
  }
  */
});
```

#### Error

```javascript
socket.on('error', (data) => {
  // data: {error_code, message}
});
```

---

## Error Handling

### Standard Error Response

```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid or expired authentication token",
    "details": {
      "reason": "token_expired",
      "expired_at": "2025-12-25T09:00:00Z"
    }
  },
  "request_id": "req_abc123",
  "timestamp": "2025-12-25T10:30:00Z"
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| UNAUTHORIZED | 401 | Invalid or missing authentication |
| FORBIDDEN | 403 | Insufficient permissions |
| NOT_FOUND | 404 | Resource not found |
| VALIDATION_ERROR | 422 | Invalid request data |
| RATE_LIMIT_EXCEEDED | 429 | Too many requests |
| INTERNAL_SERVER_ERROR | 500 | Server error |
| SERVICE_UNAVAILABLE | 503 | Service temporarily unavailable |

---

## Rate Limits

### Limits by Tier

| Tier | Requests/Minute | Requests/Hour | Requests/Day |
|------|-----------------|---------------|--------------|
| Free | 10 | 100 | 1,000 |
| Starter | 30 | 500 | 10,000 |
| Professional | 100 | 2,000 | 50,000 |
| Business | 300 | 10,000 | 200,000 |
| Enterprise | Custom | Custom | Custom |

### Rate Limit Headers

```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1640438400
```

### Rate Limit Exceeded Response

```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded. Please try again in 45 seconds.",
    "details": {
      "limit": 100,
      "window": "60s",
      "retry_after": 45
    }
  }
}
```

---

**Document Version:** 1.0
**Last Updated:** December 25, 2025
**Maintained By:** API Team
**Support:** api-support@engarde.com
