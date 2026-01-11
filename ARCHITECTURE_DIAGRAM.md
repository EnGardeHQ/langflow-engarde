# EnGarde Langflow Integration Architecture

**Visual System Architecture and Data Flow**

---

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         EnGarde Platform                             │
│  ┌──────────────────┐              ┌──────────────────┐             │
│  │                  │              │                  │             │
│  │  Frontend (Next) │◄────────────►│ Backend (FastAPI)│             │
│  │                  │   REST API   │                  │             │
│  └────────┬─────────┘              └────────┬─────────┘             │
│           │                                 │                        │
│           │ Iframe                          │ SSO Token              │
│           │ Embed                           │ Generation             │
│           ▼                                 ▼                        │
└───────────┼─────────────────────────────────┼────────────────────────┘
            │                                 │
            │                                 │
            ▼                                 ▼
┌───────────────────────────────────────────────────────────────────────┐
│                      Langflow (Customized Fork)                       │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │                       Frontend (React)                            │ │
│  │  ┌────────────┐  ┌──────────────┐  ┌─────────────────┐          │ │
│  │  │ EnGarde    │  │ EnGarde      │  │ Component       │          │ │
│  │  │ Logo       │  │ Footer       │  │ Palette         │          │ │
│  │  └────────────┘  └──────────────┘  └─────────────────┘          │ │
│  └──────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │                       Backend (FastAPI)                           │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │ │
│  │  │ SSO Login    │  │ Flow API     │  │ Component    │           │ │
│  │  │ Endpoint     │  │ Endpoints    │  │ Registry     │           │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘           │ │
│  └──────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │                    Custom Components                              │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │ │
│  │  │ SEO Walker   │  │ Paid Ads     │  │ Content      │           │ │
│  │  │ Agent        │  │ Walker       │  │ Walker       │           │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘           │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │ │
│  │  │ Audience     │  │ Tenant ID    │  │ Walker API   │           │ │
│  │  │ Intelligence │  │ Input        │  │ Component    │           │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘           │ │
│  │  ... (8 more agents)                                             │ │
│  └──────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │                      Database (PostgreSQL)                        │ │
│  │  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐    │ │
│  │  │ users  │  │ flows  │  │ folders│  │ api_key│  │messages│    │ │
│  │  └────────┘  └────────┘  └────────┘  └────────┘  └────────┘    │ │
│  └──────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────┘
```

---

## SSO Authentication Flow

```
┌────────┐                  ┌─────────┐                ┌──────────┐
│ User   │                  │EnGarde  │                │ Langflow │
│        │                  │Backend  │                │ Backend  │
└───┬────┘                  └────┬────┘                └────┬─────┘
    │                            │                          │
    │ 1. Click "Agent Suite"     │                          │
    ├────────────────────────────►                          │
    │                            │                          │
    │ 2. Call /api/v1/sso/langflow                         │
    ├────────────────────────────►                          │
    │                            │                          │
    │                        3. Query user info             │
    │                        from database                  │
    │                            ├─────────┐                │
    │                            │         │                │
    │                            ◄─────────┘                │
    │                            │                          │
    │                        4. Generate JWT                │
    │                        {                              │
    │                          email,                       │
    │                          tenant_id,                   │
    │                          role,                        │
    │                          subscription_tier            │
    │                        }                              │
    │                            │                          │
    │ 5. Return SSO URL          │                          │
    │ { sso_url: "..." }         │                          │
    ◄────────────────────────────┤                          │
    │                            │                          │
    │ 6. Redirect browser to SSO URL                        │
    ├───────────────────────────────────────────────────────►
    │                            │                          │
    │                            │     7. Validate JWT      │
    │                            │        Decode token      │
    │                            │                          ├─────┐
    │                            │                          │     │
    │                            │                          ◄─────┘
    │                            │                          │
    │                            │     8. Get or create user│
    │                            │        based on email    │
    │                            │                          ├─────┐
    │                            │                          │     │
    │                            │                          ◄─────┘
    │                            │                          │
    │                            │     9. Set permissions   │
    │                            │        is_superuser =    │
    │                            │        role in [admin,   │
    │                            │        superuser]        │
    │                            │                          │
    │                            │     10. Create folder    │
    │                            │         for user         │
    │                            │                          │
    │                            │     11. Generate         │
    │                            │         session token    │
    │                            │         (30 days)        │
    │                            │                          │
    │ 12. Redirect to dashboard with cookies                │
    │     Set-Cookie: access_token_lf=...                   │
    ◄────────────────────────────────────────────────────────┤
    │                            │                          │
    │ 13. User sees authenticated Langflow                  │
    │                            │                          │
```

---

## Walker Agent Flow Execution

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌─────────┐
│ Langflow │     │ Custom   │     │ Walker   │     │EnGarde  │
│   UI     │     │Component │     │Agent API │     │Backend  │
└────┬─────┘     └────┬─────┘     └────┬─────┘     └────┬────┘
     │                │                │                │
     │ 1. User builds flow              │                │
     ├───────────────►│                │                │
     │ - Tenant ID Input                │                │
     │ - SEO Walker Agent               │                │
     │                │                │                │
     │ 2. Click "Run" │                │                │
     ├───────────────►│                │                │
     │                │                │                │
     │            3. Execute            │                │
     │               tenant_id_input    │                │
     │                ├────────┐        │                │
     │                │        │        │                │
     │                ◄────────┘        │                │
     │                │                │                │
     │            4. Build suggestion   │                │
     │               object              │                │
     │                ├────────┐        │                │
     │                │        │        │                │
     │                ◄────────┘        │                │
     │                │                │                │
     │            5. Call Walker API    │                │
     │               Component          │                │
     │                ├────────────────►│                │
     │                │                │                │
     │                │            6. Send to backend    │
     │                │                ├───────────────►│
     │                │                │  POST /walker- │
     │                │                │  agents/       │
     │                │                │  suggestions   │
     │                │                │                │
     │                │                │  {             │
     │                │                │    agent_type, │
     │                │                │    tenant_id,  │
     │                │                │    suggestions │
     │                │                │  }             │
     │                │                │                │
     │                │                │     7. Store in│
     │                │                │        database │
     │                │                │                ├──┐
     │                │                │                │  │
     │                │                │                ◄──┘
     │                │                │                │
     │                │                │     8. Send    │
     │                │                │        notifications
     │                │                │                │
     │                │            9. Return success     │
     │                │                ◄────────────────┤
     │                │                │  {             │
     │                │                │    success,    │
     │                │                │    batch_id    │
     │                │                │  }             │
     │                │                │                │
     │            10. Return result     │                │
     │                ◄────────────────┤                │
     │                │                │                │
     │ 11. Display    │                │                │
     │     result     │                │                │
     ◄────────────────┤                │                │
     │                │                │                │
```

---

## Component Loading Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Langflow Startup                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  1. Read LANGFLOW_COMPONENTS_PATH environment variable       │
│     Default: /app/components                                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Scan directory for .py files                             │
│     /app/components/                                         │
│     └── En Garde Components/                                 │
│         ├── seo_walker_agent.py                             │
│         ├── paid_ads_walker_agent.py                        │
│         └── ... (12 more)                                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Import each Python module                                │
│     import En_Garde_Components.seo_walker_agent              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Find classes inheriting from Component                   │
│     class SEOWalkerAgent(Component):                         │
│         display_name = "SEO Walker Agent (Complete)"         │
│         ...                                                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  5. Register component in ComponentRegistry                  │
│     registry["custom"]["SEOWalkerAgent"] = SEOWalkerAgent    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  6. Components appear in UI                                  │
│     Component Palette → Custom → SEO Walker Agent            │
└─────────────────────────────────────────────────────────────┘
```

---

## Database Schema

```
┌─────────────────────────────────────────────────────────────┐
│                   Langflow Database                          │
└─────────────────────────────────────────────────────────────┘

┌──────────────┐
│    user      │
├──────────────┤
│ id (PK)      │───────┐
│ username     │       │
│ password     │       │
│ is_active    │       │
│ is_superuser │       │
│ created_at   │       │
│ last_login_at│       │
└──────────────┘       │
                       │
                       │    ┌──────────────┐
                       │    │    flow      │
                       │    ├──────────────┤
                       │    │ id (PK)      │
                       └───►│ user_id (FK) │
                            │ name         │
                            │ description  │
                            │ data (JSON)  │
                            │ folder_id(FK)│───┐
                            │ created_at   │   │
                            │ updated_at   │   │
                            └──────────────┘   │
                                               │
                       ┌───────────────────────┘
                       │
                       │    ┌──────────────┐
                       │    │   folder     │
                       │    ├──────────────┤
                       │    │ id (PK)      │
                       └───►│ name         │
                            │ user_id (FK) │───┐
                            │ created_at   │   │
                            └──────────────┘   │
                                               │
                       ┌───────────────────────┘
                       │
                       │    ┌──────────────┐
                       │    │  api_key     │
                       │    ├──────────────┤
                       │    │ id (PK)      │
                       └───►│ user_id (FK) │
                            │ api_key      │
                            │ name         │
                            │ created_at   │
                            └──────────────┘

┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│   message    │       │   variable   │       │  file        │
├──────────────┤       ├──────────────┤       ├──────────────┤
│ id (PK)      │       │ id (PK)      │       │ id (PK)      │
│ flow_id (FK) │       │ name         │       │ flow_id (FK) │
│ sender       │       │ value        │       │ name         │
│ text         │       │ type         │       │ data         │
│ timestamp    │       │ user_id (FK) │       │ created_at   │
└──────────────┘       └──────────────┘       └──────────────┘
```

---

## Deployment Architecture (Railway)

```
┌───────────────────────────────────────────────────────────────┐
│                         Railway Project                        │
│                        (engarde-platform)                      │
└───────────────────────────────────────────────────────────────┘
                                │
                ┌───────────────┼───────────────┐
                │               │               │
                ▼               ▼               ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│  Service: Main   │ │Service: Langflow │ │Service: Postgres │
│  (EnGarde)       │ │                  │ │                  │
├──────────────────┤ ├──────────────────┤ ├──────────────────┤
│ FastAPI Backend  │ │ Custom Langflow  │ │ PostgreSQL 14    │
│                  │ │                  │ │                  │
│ Port: 8000       │ │ Port: 7860       │ │ Port: 5432       │
│                  │ │                  │ │                  │
│ Domain:          │ │ Domain:          │ │ Internal:        │
│ api.engarde      │ │ langflow.engarde │ │ postgres.railway │
│ .media           │ │ .media           │ │ .internal        │
│                  │ │                  │ │                  │
│ Env:             │ │ Env:             │ │ Database:        │
│ - DATABASE_URL   │ │ - DATABASE_URL───┼─┼─►engarde_db     │
│ - LANGFLOW_BASE  │ │ - SECRET_KEY     │ │   langflow_db    │
│   _URL           │ │ - COMPONENTS     │ │                  │
│ - LANGFLOW_      │ │   _PATH          │ │                  │
│   SECRET_KEY     │ │                  │ │                  │
└──────────────────┘ └──────────────────┘ └──────────────────┘
         │                     │
         │                     │
         └─────────┬───────────┘
                   │
                   │ Shared Secret Key (JWT)
                   │ LANGFLOW_SECRET_KEY
                   │
```

---

## Docker Build Process

```
┌─────────────────────────────────────────────────────────────┐
│              Dockerfile.engarde (Multi-stage)                │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Stage 1: Builder                                             │
│ FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │ Install system dependencies  │
        │ - build-essential            │
        │ - git                        │
        │ - npm                        │
        │ - gcc                        │
        └──────────────┬───────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │ Install Python dependencies  │
        │ - uv sync --extra postgresql │
        └──────────────┬───────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │ Copy source code             │
        │ - /src/backend               │
        │ - /src/frontend              │
        │ - /En Garde Components       │
        └──────────────┬───────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │ Build frontend with branding │
        │ 1. Update index.html         │
        │ 2. Update manifest.json      │
        │ 3. Copy EnGarde assets       │
        │ 4. npm ci && npm run build   │
        └──────────────┬───────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ Stage 2: Runtime                                             │
│ FROM python:3.12.3-slim                                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │ Install runtime dependencies │
        │ - curl, git, libpq5, nodejs  │
        └──────────────┬───────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │ Copy from builder            │
        │ - .venv (Python packages)    │
        │ - src (application code)     │
        │ - components (custom)        │
        │ - frontend (built)           │
        └──────────────┬───────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │ Set environment variables    │
        │ - LANGFLOW_HOST=0.0.0.0      │
        │ - COMPONENTS_PATH=/app/...   │
        └──────────────┬───────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │ Create startup script        │
        │ - Handle Railway PORT var    │
        │ - Run langflow               │
        └──────────────┬───────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ Final Image: cope84/engarde-langflow:latest                 │
│ Size: ~5.33GB                                                │
└─────────────────────────────────────────────────────────────┘
```

---

## Frontend Integration Flow

```
┌──────────────────────────────────────────────────────────────┐
│           EnGarde Frontend (Next.js/React)                    │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │ app/agent-suite/page.tsx      │
        │                               │
        │ - Imports AuthenticatedIframe │
        │ - Renders with sidebar/header │
        └───────────┬───────────────────┘
                    │
                    ▼
        ┌───────────────────────────────┐
        │ components/workflow/          │
        │ AuthenticatedLangflowIframe   │
        │                               │
        │ 1. Check user authenticated   │
        │ 2. Call /api/v1/sso/langflow  │
        │ 3. Get sso_url                │
        │ 4. Load in iframe             │
        │ 5. Handle loading states      │
        └───────────┬───────────────────┘
                    │
                    ▼
        ┌───────────────────────────────┐
        │ services/langflow.service.ts  │
        │                               │
        │ - API client for Langflow     │
        │ - getFlows()                  │
        │ - runFlow()                   │
        │ - buildFlow()                 │
        └───────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                 Langflow Frontend (React)                     │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │ App.tsx                       │
        │                               │
        │ - Renders main layout         │
        │ - Includes EnGardeFooter      │
        └───────────┬───────────────────┘
                    │
                    ▼
        ┌───────────────────────────────┐
        │ components/core/              │
        │                               │
        │ - appHeaderComponent          │
        │   (EnGarde logo)              │
        │ - engardeFooter               │
        │   (EnGarde footer)            │
        └───────────────────────────────┘
```

---

## Security Flow

```
┌──────────────────────────────────────────────────────────────┐
│                      Security Layers                          │
└──────────────────────────────────────────────────────────────┘

Layer 1: EnGarde Authentication
┌────────────────────────────────┐
│ User logs into EnGarde         │
│ - Email/password               │
│ - OAuth providers              │
│ - Gets EnGarde access token    │
└────────────────┬───────────────┘
                 │
                 ▼
Layer 2: SSO Token Generation
┌────────────────────────────────┐
│ EnGarde backend validates user │
│ - Checks access token          │
│ - Queries user permissions     │
│ - Gets tenant information      │
│ - Creates JWT for Langflow     │
│   Signed with shared secret    │
└────────────────┬───────────────┘
                 │
                 ▼
Layer 3: Langflow SSO Validation
┌────────────────────────────────┐
│ Langflow validates JWT         │
│ - Verifies signature           │
│ - Checks expiration (5 min)    │
│ - Extracts user info           │
└────────────────┬───────────────┘
                 │
                 ▼
Layer 4: User Provisioning
┌────────────────────────────────┐
│ Create/update Langflow user    │
│ - Uses email as identifier     │
│ - Sets permissions from role   │
│ - Creates user workspace       │
└────────────────┬───────────────┘
                 │
                 ▼
Layer 5: Session Management
┌────────────────────────────────┐
│ Generate Langflow session      │
│ - 30-day access token          │
│ - HttpOnly cookies             │
│ - SameSite=Strict              │
│ - Secure (HTTPS only)          │
└────────────────────────────────┘

Shared Secret (Critical!)
┌────────────────────────────────┐
│ LANGFLOW_SECRET_KEY            │
│ - Min 32 characters            │
│ - Must match in both services  │
│ - Stored as env variable       │
│ - Never in code                │
└────────────────────────────────┘
```

---

**End of Architecture Diagrams**

For detailed implementation, see `ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md`
