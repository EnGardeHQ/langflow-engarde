# Walker Agents Communication Channels - System Architecture & Data Flow

**Version:** 1.0
**Last Updated:** December 25, 2025

---

## Table of Contents

1. [System Architecture Overview](#system-architecture-overview)
2. [Database Schema Diagrams](#database-schema-diagrams)
3. [Sequence Diagrams](#sequence-diagrams)
4. [Data Flow Diagrams](#data-flow-diagrams)
5. [Privacy & Security Architecture](#privacy--security-architecture)
6. [Deployment Architecture](#deployment-architecture)

---

## System Architecture Overview

### High-Level System Architecture

```mermaid
graph TB
    subgraph "User Channels"
        WA[WhatsApp<br/>Twilio]
        EM[Email<br/>SendGrid]
        CH[Chat UI<br/>WebSocket]
    end

    subgraph "API Gateway Layer"
        API[FastAPI Backend<br/>Port 8000]
    end

    subgraph "Channel Routers"
        WAR[WhatsApp Router<br/>/channels/whatsapp]
        EMR[Email Router<br/>/channels/email]
        CHR[Chat WebSocket<br/>/ws/chat]
    end

    subgraph "Intelligence Layer"
        LF[Langflow<br/>Orchestrator]
        WA1[Walker Agent:<br/>Paid Ads]
        WA2[Walker Agent:<br/>SEO]
        WA3[Walker Agent:<br/>Content Gen]
        WA4[Walker Agent:<br/>Audience Intel]
    end

    subgraph "Business Logic"
        HITL[HITL Service<br/>Approval Engine]
        NOTIF[Notification<br/>Service]
        ANALY[Analytics<br/>Service]
    end

    subgraph "Data Layer"
        PG[(PostgreSQL<br/>Conversations<br/>HITL Queue)]
        BQ[(BigQuery<br/>Analytics<br/>Event Logs)]
        REDIS[(Redis<br/>Cache<br/>Sessions)]
    end

    subgraph "Admin Interface"
        ADMIN[Admin Dashboard<br/>React UI]
        MONITOR[Conversation<br/>Monitoring]
        QUEUE[HITL Queue<br/>Management]
    end

    WA --> API
    EM --> API
    CH --> API

    API --> WAR
    API --> EMR
    API --> CHR

    WAR --> LF
    EMR --> LF
    CHR --> LF

    LF --> WA1
    LF --> WA2
    LF --> WA3
    LF --> WA4

    WA1 --> HITL
    WA2 --> HITL
    WA3 --> HITL
    WA4 --> HITL

    HITL --> NOTIF
    HITL --> PG

    WAR --> PG
    EMR --> PG
    CHR --> PG

    PG --> ANALY
    ANALY --> BQ

    CHR --> REDIS

    ADMIN --> API
    MONITOR --> API
    QUEUE --> API

    style WA fill:#25D366
    style EM fill:#0078D4
    style CH fill:#00B2FF
    style LF fill:#FFB800
    style WA1 fill:#9C27B0
    style WA2 fill:#2196F3
    style WA3 fill:#4CAF50
    style WA4 fill:#FF9800
    style HITL fill:#F44336
    style PG fill:#336791
    style BQ fill:#4285F4
```

### Component Interaction Architecture

```mermaid
graph LR
    subgraph "External Services"
        TWILIO[Twilio<br/>WhatsApp API]
        SENDGRID[SendGrid<br/>Email API]
        META[Meta Ads<br/>API]
        GOOGLE[Google Ads<br/>API]
    end

    subgraph "En Garde Backend"
        API[FastAPI<br/>Application]
        SERVICES[Business<br/>Services]
        DB[Database<br/>Layer]
    end

    subgraph "Langflow System"
        LF_API[Langflow<br/>API]
        LF_WF[Workflow<br/>Instances]
        LF_NODES[AI Nodes<br/>GPT-4, Claude]
    end

    subgraph "Monitoring & Logging"
        LOGS[Event Logging]
        METRICS[Metrics<br/>Collection]
        ALERTS[Alerting<br/>System]
    end

    TWILIO <-->|Webhooks<br/>SMS API| API
    SENDGRID <-->|Email API| API
    META <-->|Campaign Data| SERVICES
    GOOGLE <-->|Ad Performance| SERVICES

    API --> SERVICES
    SERVICES --> DB
    SERVICES --> LF_API
    LF_API --> LF_WF
    LF_WF --> LF_NODES

    API --> LOGS
    SERVICES --> LOGS
    LOGS --> METRICS
    METRICS --> ALERTS
```

---

## Database Schema Diagrams

### Core Tables Entity Relationship

```mermaid
erDiagram
    TENANTS ||--o{ USERS : contains
    TENANTS ||--o{ AI_AGENTS : owns
    TENANTS ||--o{ CONVERSATIONAL_LOGS : generates
    TENANTS ||--o{ HITL_APPROVALS : requests

    USERS ||--o{ CONVERSATIONAL_LOGS : participates
    USERS ||--o{ HITL_APPROVALS : requests
    USERS ||--o{ USER_PHONE_NUMBERS : has
    USERS ||--o{ USER_EMAIL_PREFERENCES : configures

    AI_AGENTS ||--o{ CONVERSATIONAL_LOGS : handles
    AI_AGENTS ||--o{ HITL_APPROVALS : generates

    CONVERSATIONAL_LOGS ||--o{ PLATFORM_EVENT_LOG : logs
    HITL_APPROVALS ||--o{ HITL_APPROVAL_HISTORY : tracks
    HITL_APPROVALS ||--o{ HITL_NOTIFICATIONS : sends

    HITL_WORKFLOWS ||--o{ HITL_APPROVALS : governs

    TENANTS {
        uuid id PK
        string name
        string subscription_tier
        timestamp created_at
    }

    USERS {
        uuid id PK
        uuid tenant_id FK
        string email
        string first_name
        string last_name
        string role
        timestamp created_at
    }

    AI_AGENTS {
        uuid id PK
        uuid tenant_id FK
        string name
        string agent_type
        string agent_category
        boolean is_system_agent
        json configuration
        timestamp created_at
    }

    USER_PHONE_NUMBERS {
        uuid id PK
        uuid user_id FK
        string phone_number
        boolean verified
        boolean primary
        timestamp created_at
    }

    USER_EMAIL_PREFERENCES {
        uuid id PK
        uuid user_id FK
        boolean enabled
        string delivery_time
        string timezone
        json include_sections
        timestamp created_at
    }

    CONVERSATIONAL_LOGS {
        uuid id PK
        uuid tenant_id FK
        uuid user_id FK
        string session_id
        string channel
        text query
        json response
        timestamp created_at
    }

    HITL_APPROVALS {
        uuid id PK
        uuid tenant_id FK
        uuid agent_id FK
        uuid workflow_id FK
        string action_type
        json action_data
        string risk_level
        float risk_score
        string status
        uuid requested_by FK
        uuid approved_by FK
        timestamp requested_at
        timestamp approved_at
        timestamp sla_deadline
        boolean sla_breached
    }

    HITL_WORKFLOWS {
        uuid id PK
        uuid tenant_id FK
        string name
        json approval_levels
        integer sla_hours
        boolean is_active
        timestamp created_at
    }

    HITL_APPROVAL_HISTORY {
        uuid id PK
        uuid approval_id FK
        string event_type
        uuid actor_id FK
        string previous_status
        string new_status
        json changes
        timestamp timestamp
    }

    HITL_NOTIFICATIONS {
        uuid id PK
        uuid approval_id FK
        string channel
        uuid recipient_id FK
        string status
        timestamp sent_at
        timestamp delivered_at
    }

    PLATFORM_EVENT_LOG {
        uuid id PK
        uuid tenant_id FK
        uuid user_id FK
        string event_type
        json metadata
        timestamp created_at
    }
```

### Conversational Analytics Schema

```mermaid
erDiagram
    CONVERSATIONAL_ANALYTICS_LOG {
        uuid id PK
        string tenant_id FK
        string user_id FK
        string session_id
        text query
        json response
        timestamp created_at
    }

    CONVERSATION_METRICS {
        uuid id PK
        string session_id FK
        string channel
        string agent_type
        integer message_count
        integer duration_seconds
        float avg_response_time_ms
        integer user_satisfaction_score
        boolean issue_resolved
        boolean escalated_to_human
        integer hitl_approvals_count
        timestamp started_at
        timestamp ended_at
    }

    USER_PHONE_NUMBERS {
        uuid id PK
        string user_id FK
        string phone_number
        boolean verified
        boolean primary
        timestamp created_at
    }

    EMAIL_DELIVERY_LOG {
        uuid id PK
        string user_id FK
        string email_type
        string subject
        string status
        string message_id
        timestamp sent_at
        timestamp opened_at
        timestamp clicked_at
    }

    CONVERSATIONAL_ANALYTICS_LOG ||--o{ CONVERSATION_METRICS : aggregates
    USER_PHONE_NUMBERS ||--o{ CONVERSATIONAL_ANALYTICS_LOG : identifies
```

### HITL System Schema Detail

```mermaid
erDiagram
    HITL_APPROVALS ||--o{ HITL_APPROVAL_HISTORY : tracks
    HITL_APPROVALS ||--o{ HITL_NOTIFICATIONS : sends
    HITL_WORKFLOWS ||--o{ HITL_APPROVALS : governs
    HITL_APPROVALS ||--o{ HITL_ANALYTICS : aggregates

    HITL_APPROVALS {
        string id PK
        string tenant_id FK
        string agent_id FK
        string agent_type
        enum action_type
        json action_data
        text action_summary
        string action_preview_url
        float estimated_cost
        integer estimated_reach
        enum risk_level
        float risk_score
        json risk_factors
        string workflow_id FK
        integer approval_level
        integer required_approvals
        integer received_approvals
        enum status
        integer priority
        string requested_by FK
        timestamp requested_at
        text request_notes
        string assigned_to FK
        string approved_by FK
        timestamp approved_at
        text approval_notes
        string rejected_by FK
        timestamp rejected_at
        text rejection_reason
        timestamp resolved_at
        timestamp sla_deadline
        boolean sla_breached
        integer sla_breach_duration_minutes
        timestamp escalated_at
        string escalated_to FK
        text escalation_reason
        json notifications_sent
        integer reminder_count
        timestamp last_reminder_at
        timestamp executed_at
        string execution_status
        json execution_result
        text execution_error
        string ip_address
        string user_agent
        json compliance_flags
        json audit_log
        json tags
        json custom_fields
        timestamp created_at
        timestamp updated_at
    }

    HITL_WORKFLOWS {
        string id PK
        string tenant_id FK
        string name
        text description
        boolean is_active
        boolean is_default
        json action_types
        json risk_levels
        float min_cost_threshold
        float max_cost_threshold
        json approval_levels
        boolean parallel_approval
        boolean unanimous_required
        integer sla_hours
        integer escalation_hours
        integer auto_approve_hours
        json notification_channels
        integer reminder_frequency_hours
        integer max_reminders
        json auto_approve_conditions
        json auto_reject_conditions
        json custom_rules
        string created_by FK
        timestamp created_at
        timestamp updated_at
    }

    HITL_APPROVAL_HISTORY {
        string id PK
        string approval_id FK
        string tenant_id FK
        string event_type
        text event_description
        string actor_id FK
        string actor_role
        string actor_ip
        string previous_status
        string new_status
        json changes
        timestamp timestamp
        json event_metadata
    }

    HITL_NOTIFICATIONS {
        string id PK
        string approval_id FK
        string tenant_id FK
        enum channel
        string recipient_id FK
        string recipient_email
        string recipient_phone
        string subject
        text message
        string template_id
        json template_vars
        string status
        timestamp sent_at
        timestamp delivered_at
        timestamp failed_at
        text failure_reason
        string provider
        string provider_message_id
        json provider_response
        boolean is_reminder
        integer reminder_number
        timestamp created_at
    }

    HITL_ANALYTICS {
        string id PK
        string tenant_id FK
        timestamp date
        string period_type
        integer total_requests
        integer total_approved
        integer total_rejected
        integer total_expired
        float avg_approval_time_minutes
        float median_approval_time_minutes
        float sla_compliance_rate
        integer low_risk_count
        integer medium_risk_count
        integer high_risk_count
        integer critical_risk_count
        json action_type_breakdown
        float total_estimated_cost_approved
        float total_estimated_cost_rejected
        json top_approvers
        timestamp computed_at
    }
```

---

## Sequence Diagrams

### WhatsApp Message Flow

```mermaid
sequenceDiagram
    participant User as 📱 User
    participant Twilio
    participant Backend as FastAPI
    participant Router as WhatsApp Router
    participant DB as PostgreSQL
    participant Langflow
    participant Agent as Walker Agent
    participant HITL as HITL Service
    participant Notif as Notification

    User->>Twilio: Sends WhatsApp message
    Twilio->>Backend: POST /channels/whatsapp/webhook
    Backend->>Router: Route to WhatsApp handler

    Router->>DB: Get user by phone number
    DB-->>Router: User data + tenant_id

    Router->>DB: Get/create conversation session
    DB-->>Router: Session ID

    Router->>Langflow: Execute Walker Agent workflow
    Note over Langflow: Identify agent from context<br/>(Paid Ads, SEO, etc.)

    Langflow->>Agent: Execute agent logic
    Agent->>Agent: Process query, fetch data

    alt High-Risk Action Required
        Agent->>HITL: Create approval request
        HITL->>DB: Save HITL approval
        HITL->>Notif: Notify approver
        Notif-->>HITL: Notification sent
        Agent-->>Langflow: Response: "Approval required"
    else Safe Action
        Agent-->>Langflow: Response: Direct answer
    end

    Langflow-->>Router: Return response

    Router->>DB: Log conversation
    DB-->>Router: Logged

    Router->>Twilio: Send WhatsApp response
    Twilio->>User: Delivers message

    opt If HITL approval
        Note over HITL: Admin approves via dashboard
        HITL->>Agent: Execute approved action
        Agent->>Notif: Notify user of result
        Notif->>Twilio: Send WhatsApp notification
        Twilio->>User: "Your request was approved"
    end
```

### Email Daily Brief Generation

```mermaid
sequenceDiagram
    participant Cron as Scheduler<br/>(Celery Beat)
    participant Email as Email Service
    participant DB as PostgreSQL
    participant Langflow
    participant Agents as Walker Agents
    participant SendGrid
    participant User as 📧 User

    Cron->>Email: Trigger daily briefs (8 AM)
    Email->>DB: Get users with email prefs enabled

    loop For each user
        DB-->>Email: User preferences

        Email->>Langflow: Execute "daily_brief" workflow
        Langflow->>Agents: Gather data from all agents

        par Parallel Data Collection
            Agents->>Agents: Paid Ads: Fetch campaign data
            Agents->>Agents: SEO: Fetch ranking changes
            Agents->>Agents: Content: Fetch performance
            Agents->>Agents: Audience: Fetch insights
        end

        Agents-->>Langflow: Aggregated brief data
        Langflow->>Langflow: Generate personalized brief
        Langflow-->>Email: Brief content + recommendations

        Email->>Email: Render HTML template
        Email->>SendGrid: Send email via API
        SendGrid-->>Email: Message ID

        Email->>DB: Log email delivery
        SendGrid->>User: Delivers email

        opt User clicks action button
            User->>SendGrid: Clicks "Approve Budget"
            SendGrid->>Email: Webhook: Click event
            Email->>Langflow: Execute action
            Langflow-->>User: Redirect to dashboard
        end
    end
```

### Chat UI Real-Time Messaging

```mermaid
sequenceDiagram
    participant User as 💻 User Browser
    participant WS as WebSocket Server
    participant Backend as FastAPI
    participant Langflow
    participant Agent as Walker Agent
    participant HITL
    participant DB as PostgreSQL
    participant Redis

    User->>WS: Connect WebSocket (JWT auth)
    WS->>Backend: Authenticate user
    Backend-->>WS: Auth successful
    WS-->>User: Connection established

    User->>WS: emit('send_message', {message, agent})
    WS->>Redis: Store session state
    WS->>User: emit('message_received')

    WS->>Backend: Process message
    Backend->>Langflow: Execute agent workflow
    WS->>User: emit('agent_typing', true)

    Langflow->>Agent: Run agent logic
    Agent->>Agent: Process query

    alt Requires HITL
        Agent->>HITL: Create approval
        HITL->>DB: Save request
        HITL-->>Agent: Approval pending
        Agent-->>Langflow: "Requires approval" response
    else Direct response
        Agent-->>Langflow: Direct answer
    end

    Langflow-->>Backend: Response data
    Backend->>DB: Log conversation
    Backend->>WS: Send response

    WS->>User: emit('agent_typing', false)
    WS->>User: emit('agent_response', {content})

    User->>User: Display message in chat

    opt User disconnects
        User->>WS: disconnect()
        WS->>Redis: Clear session
        WS-->>User: Connection closed
    end
```

### HITL Approval Process Flow

```mermaid
sequenceDiagram
    participant Agent as Walker Agent
    participant HITL as HITL Service
    participant Risk as Risk Engine
    participant Workflow as Workflow Matcher
    participant DB as PostgreSQL
    participant Notif as Notification Service
    participant Admin as 👔 Admin
    participant User as 👤 User

    Agent->>HITL: Request approval for action
    HITL->>Risk: Calculate risk score
    Risk->>Risk: Analyze: budget, reach, history
    Risk-->>HITL: Risk score: 75 (High)

    HITL->>Workflow: Match to approval workflow
    Workflow->>DB: Find workflow by action type + risk
    DB-->>Workflow: Workflow: 2-level approval
    Workflow-->>HITL: Approval config

    HITL->>DB: Create HITL approval record
    DB-->>HITL: Approval ID: #BR-12345

    HITL->>DB: Calculate SLA deadline
    HITL->>Notif: Notify assigned approver

    par Notification Channels
        Notif->>Admin: Email notification
        Notif->>Admin: In-app notification
        Notif->>Admin: Slack notification (optional)
    end

    Admin->>Admin: Reviews in HITL Queue
    Admin->>HITL: POST /hitl/{id}/approve

    HITL->>DB: Update approval status
    DB-->>HITL: Updated

    HITL->>Agent: Execute approved action
    Agent->>Agent: Perform action (e.g., increase budget)
    Agent-->>HITL: Execution result

    HITL->>DB: Log execution result
    HITL->>Notif: Notify user of approval

    Notif->>User: "Your request was approved!"
    User-->>Notif: Acknowledgment

    HITL->>DB: Create audit trail entry
    DB-->>HITL: Audit logged
```

### Admin Conversation Monitoring Flow

```mermaid
sequenceDiagram
    participant Admin as 👔 Admin
    participant UI as Admin Dashboard
    participant API as FastAPI Backend
    participant Auth as Auth Service
    participant Privacy as Privacy Service
    participant DB as PostgreSQL
    participant Audit as Audit Logger

    Admin->>UI: Access monitoring dashboard
    UI->>API: GET /admin/conversations (JWT)

    API->>Auth: Validate admin permissions
    Auth->>Auth: Check role: admin, support, compliance
    Auth-->>API: Authorized

    API->>DB: Query conversations (filtered)
    DB-->>API: Conversation list

    API->>Privacy: Check PII access permissions
    Privacy->>Privacy: Admin role: support_admin<br/>PII access: False
    Privacy-->>API: Mask PII

    API->>Privacy: Mask email, phone, sensitive data
    Privacy-->>API: Masked data

    API-->>UI: Return masked conversations
    UI-->>Admin: Display conversation list

    Admin->>UI: Click "View" on conversation
    UI->>API: GET /admin/conversations/{id}

    API->>Auth: Validate permissions
    Auth-->>API: Authorized

    API->>DB: Fetch full conversation
    DB-->>API: Conversation data

    API->>Privacy: Apply masking
    Privacy-->>API: Masked conversation

    API->>Audit: Log admin access
    Audit->>DB: Save audit record
    Note over Audit: Logs: admin_id, resource_id,<br/>timestamp, IP, action

    API-->>UI: Return conversation detail
    UI-->>Admin: Display messages

    opt Admin has "view_pii" permission
        Admin->>UI: Toggle "Show Full PII"
        UI->>API: GET /admin/conversations/{id}?show_pii=true

        API->>Auth: Check "view_pii" permission
        Auth-->>API: Permission granted

        API->>Audit: Log PII access (high sensitivity)
        Audit->>DB: Audit: PII_ACCESSED

        API->>DB: Fetch unmasked data
        DB-->>API: Full PII data

        API-->>UI: Return unmasked conversation
        UI-->>Admin: Display full details
    end
```

---

## Data Flow Diagrams

### Multi-Channel Message Processing Data Flow

```mermaid
graph TD
    subgraph "Input Channels"
        WA[WhatsApp Message]
        EM[Email Query]
        CH[Chat Message]
    end

    subgraph "Ingestion Layer"
        WAI[Twilio Webhook<br/>Parser]
        EMI[Email Command<br/>Parser]
        CHI[WebSocket<br/>Handler]
    end

    subgraph "Routing & Context"
        ROUTE[Message Router]
        CTX[Context Builder]
        SESS[Session Manager]
    end

    subgraph "Intelligence Processing"
        LF[Langflow Orchestrator]
        AGT[Walker Agent Selection]
        EXEC[Workflow Execution]
    end

    subgraph "Decision Engine"
        RISK[Risk Assessment]
        HITL{HITL Required?}
        EXEC2[Direct Execution]
    end

    subgraph "Response Generation"
        RESP[Response Formatter]
        CHAN[Channel Adapter]
    end

    subgraph "Data Persistence"
        CONVDB[Conversation Log]
        EVENTDB[Platform Events]
        HITLDB[HITL Queue]
    end

    subgraph "Output Channels"
        WAO[WhatsApp Response]
        EMO[Email Response]
        CHO[Chat Response]
    end

    WA --> WAI
    EM --> EMI
    CH --> CHI

    WAI --> ROUTE
    EMI --> ROUTE
    CHI --> ROUTE

    ROUTE --> CTX
    CTX --> SESS
    SESS --> LF

    LF --> AGT
    AGT --> EXEC

    EXEC --> RISK
    RISK --> HITL

    HITL -->|Yes| HITLDB
    HITL -->|No| EXEC2

    EXEC2 --> RESP
    RESP --> CHAN

    CHAN --> WAO
    CHAN --> EMO
    CHAN --> CHO

    ROUTE --> CONVDB
    EXEC --> EVENTDB
    RESP --> CONVDB

    style HITL fill:#FFD700
    style RISK fill:#FF6B6B
    style LF fill:#4ECDC4
```

### HITL Approval Data Flow

```mermaid
graph TD
    subgraph "Trigger"
        ACT[Agent Action Request]
    end

    subgraph "Risk Analysis"
        CALC[Calculate Risk Score]
        FACTOR[Risk Factors:<br/>- Budget impact<br/>- Reach<br/>- Action type<br/>- User history]
        SCORE[Risk Score: 0-100]
    end

    subgraph "Workflow Matching"
        MATCH[Match Workflow]
        RULES[Matching Rules:<br/>- Action type<br/>- Risk level<br/>- Tenant config]
        WF[Selected Workflow]
    end

    subgraph "Approval Creation"
        CREATE[Create Approval Record]
        SLA[Calculate SLA Deadline]
        ASSIGN[Assign Approver]
    end

    subgraph "Notification"
        NOTIF[Notification Service]
        EMAIL[Email Notification]
        INAPP[In-App Alert]
        SLACK[Slack Message]
    end

    subgraph "Database"
        HITLDB[(HITL Approvals)]
        WFDB[(Workflows)]
        USERDB[(Users)]
    end

    subgraph "Admin Action"
        QUEUE[HITL Queue UI]
        REVIEW[Admin Reviews]
        DECISION{Decision}
    end

    subgraph "Execution"
        APPROVE[Execute Action]
        REJECT[Reject & Notify]
        RESULT[Log Result]
    end

    subgraph "Audit"
        AUDIT[Audit Trail]
        HISTORY[Approval History]
    end

    ACT --> CALC
    CALC --> FACTOR
    FACTOR --> SCORE

    SCORE --> MATCH
    MATCH --> RULES
    RULES --> WF

    WF --> CREATE
    CREATE --> SLA
    SLA --> ASSIGN
    ASSIGN --> HITLDB

    HITLDB --> NOTIF
    NOTIF --> EMAIL
    NOTIF --> INAPP
    NOTIF --> SLACK

    HITLDB --> QUEUE
    QUEUE --> REVIEW
    REVIEW --> DECISION

    DECISION -->|Approve| APPROVE
    DECISION -->|Reject| REJECT
    DECISION -->|Escalate| ASSIGN

    APPROVE --> RESULT
    REJECT --> RESULT
    RESULT --> AUDIT
    AUDIT --> HISTORY

    MATCH --> WFDB
    ASSIGN --> USERDB

    style DECISION fill:#FFD700
    style SCORE fill:#FF6B6B
```

### Analytics Aggregation Pipeline

```mermaid
graph LR
    subgraph "Real-Time Events"
        CONV[Conversation Events]
        HITL[HITL Events]
        EXEC[Execution Events]
    end

    subgraph "Event Stream"
        STREAM[Event Stream<br/>Kafka/Redis]
    end

    subgraph "Raw Storage"
        PGLOG[PostgreSQL<br/>Event Logs]
        BQRAW[BigQuery<br/>Raw Events]
    end

    subgraph "Processing"
        ETL[ETL Pipeline<br/>Celery Jobs]
        AGG[Aggregation<br/>Functions]
    end

    subgraph "Aggregated Data"
        METRICS[Conversation Metrics]
        HITLAGG[HITL Analytics]
        PERF[Performance Stats]
    end

    subgraph "Serving Layer"
        CACHE[Redis Cache]
        API[Analytics API]
    end

    subgraph "Consumption"
        DASH[Admin Dashboard]
        EXPORT[Data Export]
        ALERTS[Alerting System]
    end

    CONV --> STREAM
    HITL --> STREAM
    EXEC --> STREAM

    STREAM --> PGLOG
    STREAM --> BQRAW

    PGLOG --> ETL
    BQRAW --> ETL

    ETL --> AGG
    AGG --> METRICS
    AGG --> HITLAGG
    AGG --> PERF

    METRICS --> CACHE
    HITLAGG --> CACHE
    PERF --> CACHE

    CACHE --> API
    API --> DASH
    API --> EXPORT
    PERF --> ALERTS

    style ETL fill:#4ECDC4
    style AGG fill:#95E1D3
```

---

## Privacy & Security Architecture

### Data Privacy Layers

```mermaid
graph TD
    subgraph "Data Collection"
        INPUT[User Input]
        PII[PII Detection]
        ENCRYPT[Encryption<br/>AES-256]
    end

    subgraph "Storage Layer"
        DB[(Database<br/>Encrypted at Rest)]
        VAULT[(Key Vault<br/>Encryption Keys)]
    end

    subgraph "Access Control"
        RBAC[Role-Based<br/>Access Control]
        PERM[Permission Check]
        MASK[Data Masking<br/>Service]
    end

    subgraph "Audit & Compliance"
        AUDIT[Access Audit Log]
        RETAIN[Retention Policy<br/>Enforcement]
        GDPR[GDPR Compliance<br/>Controls]
    end

    subgraph "Data Retrieval"
        QUERY[Data Query]
        DECRYPT{Authorized<br/>Decryption?}
        MASKED[Masked Data]
        FULL[Full Data]
    end

    INPUT --> PII
    PII --> ENCRYPT
    ENCRYPT --> DB
    ENCRYPT --> VAULT

    QUERY --> RBAC
    RBAC --> PERM
    PERM --> MASK

    MASK --> DECRYPT
    DECRYPT -->|No| MASKED
    DECRYPT -->|Yes| FULL
    FULL --> AUDIT

    DB --> RETAIN
    DB --> GDPR

    style ENCRYPT fill:#FF6B6B
    style DECRYPT fill:#FFD700
    style AUDIT fill:#4ECDC4
```

### Security Architecture

```mermaid
graph TB
    subgraph "External Access"
        INTERNET[Internet]
        CDN[CloudFlare CDN<br/>DDoS Protection]
    end

    subgraph "API Gateway"
        LB[Load Balancer<br/>SSL Termination]
        WAF[Web Application<br/>Firewall]
        RATE[Rate Limiting]
    end

    subgraph "Authentication"
        JWT[JWT Validation]
        OAUTH[OAuth Provider]
        MFA[MFA Service]
    end

    subgraph "Authorization"
        RBAC[RBAC Engine]
        PERM[Permission Matrix]
        TENANT[Tenant Isolation]
    end

    subgraph "Application"
        API[FastAPI Backend]
        VALID[Input Validation]
        SANITIZE[SQL Injection<br/>Prevention]
    end

    subgraph "Data Access"
        DB[(PostgreSQL)]
        ENCRYPT[Encryption Layer]
        AUDIT[Audit Logger]
    end

    subgraph "Monitoring"
        IDS[Intrusion Detection]
        SIEM[Security Info &<br/>Event Management]
        ALERT[Alert System]
    end

    INTERNET --> CDN
    CDN --> LB
    LB --> WAF
    WAF --> RATE

    RATE --> JWT
    JWT --> OAUTH
    OAUTH --> MFA

    MFA --> RBAC
    RBAC --> PERM
    PERM --> TENANT

    TENANT --> API
    API --> VALID
    VALID --> SANITIZE

    SANITIZE --> DB
    DB --> ENCRYPT
    DB --> AUDIT

    WAF --> IDS
    RATE --> IDS
    AUDIT --> SIEM
    IDS --> SIEM
    SIEM --> ALERT

    style ENCRYPT fill:#FF6B6B
    style MFA fill:#FFD700
    style TENANT fill:#4ECDC4
```

---

## Deployment Architecture

### Production Deployment (Kubernetes)

```mermaid
graph TB
    subgraph "External"
        USER[Users]
        ADMIN[Admins]
    end

    subgraph "Edge Layer"
        CF[CloudFlare]
        DNS[DNS]
    end

    subgraph "Ingress"
        INGRESS[Ingress Controller<br/>nginx]
    end

    subgraph "Kubernetes Cluster"
        subgraph "API Pods"
            API1[API Pod 1]
            API2[API Pod 2]
            API3[API Pod 3]
        end

        subgraph "WebSocket Pods"
            WS1[WebSocket Pod 1]
            WS2[WebSocket Pod 2]
        end

        subgraph "Worker Pods"
            WORKER1[Celery Worker 1]
            WORKER2[Celery Worker 2]
        end

        subgraph "Scheduler"
            BEAT[Celery Beat]
        end

        subgraph "Services"
            APISVC[API Service<br/>LoadBalancer]
            WSSVC[WebSocket Service]
        end
    end

    subgraph "Data Layer"
        PG[(PostgreSQL<br/>Managed)]
        REDIS[(Redis<br/>Managed)]
        BQ[(BigQuery)]
    end

    subgraph "External Services"
        TWILIO[Twilio]
        SENDGRID[SendGrid]
        LANGFLOW[Langflow API]
    end

    USER --> CF
    ADMIN --> CF
    CF --> DNS
    DNS --> INGRESS

    INGRESS --> APISVC
    INGRESS --> WSSVC

    APISVC --> API1
    APISVC --> API2
    APISVC --> API3

    WSSVC --> WS1
    WSSVC --> WS2

    API1 --> PG
    API2 --> PG
    API3 --> PG

    API1 --> REDIS
    WS1 --> REDIS
    WS2 --> REDIS

    API1 --> BQ
    API2 --> BQ

    WORKER1 --> PG
    WORKER2 --> PG
    BEAT --> REDIS

    API1 --> TWILIO
    API2 --> SENDGRID
    API3 --> LANGFLOW

    style INGRESS fill:#4ECDC4
    style PG fill:#336791
    style REDIS fill:#DC382D
```

### Service Dependencies

```mermaid
graph LR
    subgraph "Core Services"
        API[FastAPI Backend]
        WS[WebSocket Server]
        WORKER[Celery Workers]
    end

    subgraph "Data Stores"
        PG[(PostgreSQL)]
        REDIS[(Redis)]
        BQ[(BigQuery)]
    end

    subgraph "External APIs"
        TWILIO[Twilio<br/>WhatsApp]
        SENDGRID[SendGrid<br/>Email]
        LANGFLOW[Langflow<br/>AI Workflows]
    end

    subgraph "Infrastructure"
        K8S[Kubernetes]
        PROM[Prometheus<br/>Monitoring]
        GRAFANA[Grafana<br/>Dashboards]
    end

    API --> PG
    API --> REDIS
    API --> BQ
    API --> TWILIO
    API --> SENDGRID
    API --> LANGFLOW

    WS --> REDIS
    WS --> PG

    WORKER --> PG
    WORKER --> REDIS
    WORKER --> SENDGRID
    WORKER --> LANGFLOW

    K8S --> API
    K8S --> WS
    K8S --> WORKER

    PROM --> API
    PROM --> WS
    PROM --> WORKER
    GRAFANA --> PROM

    style PG fill:#336791
    style REDIS fill:#DC382D
    style LANGFLOW fill:#FFB800
```

---

**Document Version:** 1.0
**Last Updated:** December 25, 2025
**Next Review:** January 25, 2026
**Maintained By:** Architecture & Engineering Team
