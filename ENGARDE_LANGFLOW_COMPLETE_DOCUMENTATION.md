# EnGarde Langflow - Complete Installation & Configuration Guide

**Version:** 1.0.0
**Last Updated:** January 10, 2026
**Purpose:** Complete documentation for reinstalling and reconfiguring Langflow from scratch with all EnGarde customizations

---

## Table of Contents

1. [Overview](#overview)
2. [Custom Modifications Summary](#custom-modifications-summary)
3. [SSO Integration](#sso-integration)
4. [Subscription Tier Synchronization](#subscription-tier-synchronization)
5. [Custom Components](#custom-components)
6. [User Synchronization](#user-synchronization)
7. [Database Configuration](#database-configuration)
8. [Environment Variables](#environment-variables)
9. [Dockerfile Configuration](#dockerfile-configuration)
10. [Deployment Steps](#deployment-steps)
11. [Local Development Setup](#local-development-setup)
12. [Testing the Installation](#testing-the-installation)

---

## Overview

### What is Langflow?

Langflow is a low-code visual builder for creating AI agent workflows and flows. It's based on LangChain and provides a drag-and-drop interface for building complex AI pipelines.

### How Langflow Integrates with EnGarde

EnGarde uses a **customized fork of Langflow** that includes:

1. **Custom Branding** - EnGarde logo, colors, and footer
2. **SSO Authentication** - Seamless login from EnGarde dashboard
3. **Custom Components** - 14 pre-built Walker Agent components
4. **Multi-tenant Support** - Tenant isolation via JWT tokens
5. **Subscription Tier Sync** - Plan tier passed from EnGarde to Langflow
6. **Embedded Integration** - Iframe embedding in EnGarde frontend

**Repository:** `https://github.com/EnGardeHQ/langflow-engarde`
**Based On:** Official Langflow v1.7.1
**Deployment:** Railway (separate service from main backend)

---

## Custom Modifications Summary

### 1. Backend Customizations

#### a) Custom SSO Endpoint (`/api/v1/custom/sso_login`)

**File:** `/src/backend/base/langflow/api/v1/custom.py`

**Purpose:** Accept JWT token from EnGarde backend, create/update user, and redirect to authenticated Langflow session.

**Key Features:**
- JWT token validation using shared secret
- Automatic user creation/update
- Role mapping (superuser, admin, user, agency)
- Tenant-specific folder creation
- 30-day session tokens

**Router Registration:** The custom endpoint is embedded in `login.py` (not as a separate router)

**Location in codebase:**
```python
# /src/backend/base/langflow/api/v1/login.py
@router.get("/custom/sso_login")
async def sso_login(token: str, request: Request):
    # SSO implementation
```

#### b) Modified Login Router

**File:** `/src/backend/base/langflow/api/v1/login.py`

**Changes:**
- Added SSO endpoint at `/custom/sso_login`
- JWT decoding with tenant/role extraction
- Automatic user provisioning
- Folder creation for new users

### 2. Frontend Customizations

#### a) EnGarde Branding

**Modified Files:**

1. **Header Component**
   - **File:** `/src/frontend/src/components/core/appHeaderComponent/index.tsx`
   - **Changes:** Replaced Langflow logo with EnGarde logo
   - **Asset:** `/src/frontend/src/assets/EnGardeIcon.svg`

2. **Footer Component**
   - **File:** `/src/frontend/src/components/core/engardeFooter/index.tsx`
   - **Content:** "Made by EnGarde with ❤️"
   - **Asset:** `/src/frontend/src/assets/EGMBlackIcon.svg`

3. **Page Title**
   - **File:** `/src/frontend/index.html`
   - **Change:** `<title>EnGarde - AI Campaign Builder</title>`

4. **Manifest**
   - **File:** `/src/frontend/public/manifest.json`
   - **Changes:**
     - `"name": "EnGarde"`
     - `"short_name": "EnGarde"`
     - `"description": "EnGarde - AI-powered social media campaign builder"`

5. **Favicon**
   - **File:** `/src/frontend/public/favicon.ico`
   - **Source:** `/engarde-branding/favicon.ico`

6. **Welcome Message**
   - **File:** `/src/frontend/src/pages/MainPage/pages/empty-page.tsx`
   - **Change:** "Welcome to EnGarde's Agent Suite"

#### b) Feature Flags

**File:** `/src/frontend/src/customization/feature-flags.ts` (implied)

```typescript
export const ENABLE_DATASTAX_LANGFLOW = false; // DataStax branding disabled
```

### 3. Custom Components (Walker Agents)

**Directory:** `/En Garde Components/` (root level)

**14 Custom Components:**

1. `analytics_report_agent.py` - Analytics and reporting
2. `audience_intelligence_walker_agent.py` - Audience segmentation
3. `campaign_creation_agent.py` - Campaign creation flows
4. `campaign_launcher_agent.py` - Campaign launch automation
5. `content_approval_agent.py` - Content approval workflows
6. `content_walker_agent.py` - Content gap analysis
7. `notification_agent.py` - Notification handling
8. `paid_ads_walker_agent.py` - Paid advertising optimization
9. `performance_monitoring_agent.py` - Performance tracking
10. `seo_walker_agent.py` - SEO analysis and suggestions
11. `tenant_id_input.py` - Tenant ID input component
12. `walker_agent_api.py` - API integration component
13. `walker_suggestion_builder.py` - Suggestion builder
14. `README.md` - Component documentation

**How They Work:**
- Built using Langflow's custom component API
- Installed in `/app/components/En Garde Components/`
- Auto-discovered by Langflow on startup
- Appear in component palette under "Custom" category

### 4. Docker Build Customizations

**Two Dockerfiles:**

1. **Dockerfile.engarde** - Full build from source (5.33GB)
   - Multi-stage build
   - Frontend built with npm
   - All branding applied during build
   - **Use for:** Production deployments

2. **Dockerfile.railway-final** - Lightweight (uses pre-built image)
   - Based on `cope84/engarde-langflow-flattened:temp`
   - Quick deployment
   - **Use for:** Testing/staging

---

## SSO Integration

### Architecture Overview

```
EnGarde Frontend (React)
    ↓
    Calls: POST /api/v1/sso/langflow
    ↓
EnGarde Backend (FastAPI)
    ↓
    Generates JWT with tenant info
    ↓
    Returns: { sso_url: "https://langflow.../api/v1/custom/sso_login?token=..." }
    ↓
EnGarde Frontend redirects browser to sso_url
    ↓
Langflow Backend (/api/v1/custom/sso_login)
    ↓
    Validates JWT
    Creates/updates user
    Generates Langflow session token
    Sets cookies
    Redirects to Langflow dashboard
    ↓
User sees authenticated Langflow session
```

### Step-by-Step Implementation

#### Step 1: Backend SSO Token Generation

**File:** `/production-backend/app/routers/langflow_sso.py` (EnGarde main backend)

```python
@router.post("/langflow")
async def generate_langflow_sso_token(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Get shared secret
    secret_key = os.getenv("LANGFLOW_SECRET_KEY")

    # Get Langflow URL
    langflow_url = settings.LANGFLOW_BASE_URL

    # Extract tenant info
    tenant_id = str(current_user.tenant_id)
    tenant = db.query(Tenant).filter(Tenant.id == tenant_id).first()

    # Get user role
    user_role = "user"  # admin, superuser, user, agency

    # Get subscription tier
    subscription_tier = tenant.plan_tier  # free, starter, business, enterprise

    # Create JWT payload
    payload = {
        "email": current_user.email,
        "sub": str(current_user.id),
        "tenant_id": tenant_id,
        "tenant_name": tenant.name,
        "role": user_role,
        "subscription_tier": subscription_tier,
        "exp": datetime.utcnow() + timedelta(minutes=5),  # 5-minute expiry
        "iat": datetime.utcnow(),
    }

    # Sign token
    token = jwt.encode(payload, secret_key, algorithm="HS256")

    # Return SSO URL
    sso_url = f"{langflow_url}/api/v1/custom/sso_login?token={token}"

    return {
        "sso_url": sso_url,
        "expires_in": 300
    }
```

#### Step 2: Langflow SSO Endpoint

**File:** `/src/backend/base/langflow/api/v1/custom.py` (Langflow backend)

**Note:** The SSO endpoint is actually in `/login.py`, not a separate `custom.py` file.

```python
@router.get("/custom/sso_login")
async def sso_login(
    token: str,
    request: Request,
    response: Response,
):
    # Validate JWT
    secret_key = os.getenv("LANGFLOW_SECRET_KEY")
    payload = jwt.decode(token, secret_key, algorithms=["HS256"])

    # Extract user info
    email = payload.get("email")
    tenant_id = payload.get("tenant_id")
    tenant_name = payload.get("tenant_name")
    user_role = payload.get("role")
    subscription_tier = payload.get("subscription_tier")

    # Map role to Langflow permissions
    is_superuser = user_role in ["superuser", "admin"]

    # Create or update user
    async with session_scope() as session:
        user = await get_user_by_username(session, email)

        if not user:
            user = User(
                username=email,
                password=email,  # Dummy password (hashed automatically)
                is_active=True,
                is_superuser=is_superuser,
            )
            session.add(user)
            await session.commit()
        else:
            # Update permissions if changed
            user.is_superuser = is_superuser
            session.add(user)
            await session.commit()

        # Generate Langflow session token (30-day expiry)
        access_token = create_token(
            data={"sub": str(user.id), "type": "access"},
            expires_delta=timedelta(days=30)
        )

        # Create default folder for user
        _ = await get_or_create_default_folder(session, user.id)

    # Redirect to Langflow dashboard
    redirect_url = f"{request.base_url}/"
    redirect_response = RedirectResponse(url=redirect_url)

    # Set authentication cookies
    auth_settings = get_settings_service().auth_settings

    redirect_response.set_cookie(
        "access_token_lf",
        access_token,
        httponly=auth_settings.ACCESS_HTTPONLY,
        samesite=auth_settings.ACCESS_SAME_SITE,
        secure=auth_settings.ACCESS_SECURE,
        max_age=60 * 60 * 24 * 30,  # 30 days
        domain=auth_settings.COOKIE_DOMAIN,
    )

    return redirect_response
```

#### Step 3: Frontend Integration

**File:** `/production-frontend/components/workflow/AuthenticatedLangflowIframe.tsx`

```typescript
const setupAuthenticatedIframe = async () => {
  // Get EnGarde access token
  const token = authService.getAccessToken();

  // Call EnGarde backend to get SSO URL
  const apiUrl = process.env.NEXT_PUBLIC_API_URL;
  const ssoResponse = await fetch(`${apiUrl}/api/v1/sso/langflow`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  });

  const ssoData = await ssoResponse.json();
  const ssoUrl = ssoData.sso_url;

  // Load SSO URL in iframe
  setIframeUrl(ssoUrl);
};
```

**Usage in Page:**

```typescript
// /production-frontend/app/agent-suite/page.tsx
import { AuthenticatedLangflowIframe } from '@/components/workflow/AuthenticatedLangflowIframe';

export default function AgentSuitePage() {
  return (
    <Box>
      <AuthenticatedLangflowIframe />
    </Box>
  );
}
```

### JWT Token Structure

```json
{
  "email": "user@example.com",
  "sub": "user-uuid",
  "tenant_id": "tenant-uuid",
  "tenant_name": "Acme Corp",
  "role": "admin",
  "subscription_tier": "business",
  "exp": 1704996000,
  "iat": 1704995700
}
```

### Role Mapping

| EnGarde Role | Langflow `is_superuser` | Description |
|--------------|-------------------------|-------------|
| `superuser` | `true` | Full system access |
| `admin` | `true` | Tenant admin access |
| `user` | `false` | Standard user |
| `agency` | `false` | Agency user |

---

## Subscription Tier Synchronization

### Overview

Subscription tier information flows from EnGarde to Langflow via JWT token but is **not currently stored** in Langflow's database. This is passed for future feature gating.

### Subscription Tiers

| Tier | Description | Potential Features |
|------|-------------|-------------------|
| `free` | Free tier | Limited flows, basic components |
| `starter` | Starter plan | More flows, standard components |
| `professional` | Professional plan | Advanced components, API access |
| `business` | Business plan | Custom components, webhooks |
| `enterprise` | Enterprise plan | White-label, dedicated support |

### Current Implementation

**JWT Payload:**
```json
{
  "subscription_tier": "business"
}
```

**Langflow Handling:**
```python
# Tier is received but not yet used
subscription_tier = payload.get("subscription_tier", "starter")
# Future: Use for feature gating
```

### Future Enhancement Ideas

1. **Component Filtering**
   - Free tier: Only basic components visible
   - Business tier: All components including custom

2. **Flow Limits**
   - Free: 5 flows max
   - Starter: 25 flows
   - Business: Unlimited

3. **API Rate Limiting**
   - Based on subscription tier

4. **Storage Quotas**
   - Different database storage limits per tier

### Implementation Location (for future)

**File to modify:** `/src/backend/base/langflow/api/v1/endpoints.py`

```python
# Example: Filter components by tier
def get_available_components(user: User):
    tier = user.subscription_tier  # Would need to add this field

    all_components = load_all_components()

    if tier == "free":
        # Return only basic components
        return filter_basic_components(all_components)
    elif tier in ["business", "enterprise"]:
        # Return all components
        return all_components
    else:
        # Return standard components
        return filter_standard_components(all_components)
```

---

## Custom Components

### Directory Structure

```
langflow-engarde/
├── En Garde Components/          # Custom components (root level)
│   ├── README.md                 # Component documentation
│   ├── tenant_id_input.py        # Tenant ID input component
│   ├── walker_suggestion_builder.py  # Suggestion builder
│   ├── walker_agent_api.py       # API integration component
│   ├── seo_walker_agent.py       # SEO Walker (complete)
│   ├── paid_ads_walker_agent.py  # Paid Ads Walker (complete)
│   ├── content_walker_agent.py   # Content Walker (complete)
│   ├── audience_intelligence_walker_agent.py  # Audience Walker
│   ├── campaign_creation_agent.py
│   ├── campaign_launcher_agent.py
│   ├── content_approval_agent.py
│   ├── notification_agent.py
│   ├── performance_monitoring_agent.py
│   └── analytics_report_agent.py
```

### Component Installation

**During Docker Build:**

```dockerfile
# Dockerfile.engarde
COPY ["En Garde Components", "/app/components/En Garde Components"]
```

**Environment Variable:**

```bash
LANGFLOW_COMPONENTS_PATH="/app/components"
```

**How Langflow Discovers Components:**

1. On startup, Langflow scans `LANGFLOW_COMPONENTS_PATH`
2. Finds all `.py` files
3. Imports classes inheriting from `Component`
4. Registers them in the component registry
5. They appear in the UI under "Custom" category

### Component Example: Tenant ID Input

**File:** `/En Garde Components/tenant_id_input.py`

```python
from langflow.base.io.text import TextComponent
from langflow.io import MessageTextInput, Output
from langflow.schema.message import Message

class TenantIDInputComponent(TextComponent):
    display_name = "Tenant ID Input"
    description = "Provide the tenant UUID for Walker Agent analysis"
    icon = "user"
    name = "TenantIDInput"

    inputs = [
        MessageTextInput(
            name="tenant_id",
            display_name="Tenant ID",
            info="UUID of the tenant to analyze",
            required=True,
            placeholder="e.g., 123e4567-e89b-12d3-a456-426614174000",
        ),
    ]

    outputs = [
        Output(display_name="Tenant ID", name="tenant_id", method="get_tenant_id"),
    ]

    def get_tenant_id(self) -> Message:
        return Message(text=self.tenant_id)
```

### Component Example: Walker Agent API

**File:** `/En Garde Components/walker_agent_api.py`

```python
from langflow.custom import Component
from langflow.io import SecretStrInput, DropdownInput, MessageTextInput, MultilineInput
import httpx
import json

class WalkerAgentAPIComponent(Component):
    display_name = "Walker Agent API Request"
    description = "Send suggestions to EnGarde backend API"

    inputs = [
        SecretStrInput(
            name="api_url",
            display_name="API URL",
            value="${ENGARDE_API_URL}",
        ),
        SecretStrInput(
            name="api_key",
            display_name="API Key",
            placeholder="${WALKER_AGENT_API_KEY_ONSIDE_SEO}",
        ),
        DropdownInput(
            name="agent_type",
            options=["seo", "content", "paid_ads", "audience_intelligence"],
            value="seo",
        ),
        MessageTextInput(
            name="tenant_id",
            display_name="Tenant ID",
        ),
        MultilineInput(
            name="suggestions",
            display_name="Suggestions (JSON Array)",
        ),
    ]

    def send_to_api(self) -> Message:
        payload = {
            "agent_type": self.agent_type,
            "tenant_id": self.tenant_id,
            "suggestions": json.loads(self.suggestions),
        }

        with httpx.Client() as client:
            response = client.post(
                f"{self.api_url}/api/v1/walker-agents/suggestions",
                json=payload,
                headers={"Authorization": f"Bearer {self.api_key}"},
            )

        return Message(text=json.dumps(response.json(), indent=2))
```

### Component Naming Convention

**Pattern:** `{agent_type}_walker_agent.py` or `{function}_agent.py`

**Examples:**
- `seo_walker_agent.py` - SEO analysis agent
- `notification_agent.py` - Notification handler
- `tenant_id_input.py` - Input component

### Loading Components in Langflow

**Verification:**

```bash
# Check if components are loaded
docker exec -it langflow-container ls -la /app/components/En\ Garde\ Components/

# Check Langflow logs for component loading
docker logs langflow-container | grep -i "component\|custom"
```

**Expected Output:**
```
INFO: Loading custom components from /app/components
INFO: Discovered 14 custom components
INFO: Registered component: TenantIDInput
INFO: Registered component: WalkerAgentAPI
...
```

---

## User Synchronization

### User Creation Flow

```
1. User logs into EnGarde dashboard
2. User clicks "Agent Suite" menu item
3. Frontend calls POST /api/v1/sso/langflow
4. Backend generates JWT with user email + tenant info
5. Frontend redirects to Langflow SSO endpoint
6. Langflow checks if user exists:
   - If NO: Create new user with email as username
   - If YES: Update user permissions (if role changed)
7. User is logged into Langflow with 30-day session
```

### User Table Mapping

| EnGarde User Field | Langflow User Field | Notes |
|--------------------|---------------------|-------|
| `email` | `username` | Used as primary identifier |
| `id` (UUID) | N/A | Not stored in Langflow |
| `tenant_id` | N/A | Passed via JWT, not stored |
| `role` (admin/user) | `is_superuser` | Mapped during SSO |
| `is_active` | `is_active` | Always `true` for SSO users |

### Langflow User Model

**File:** `/src/backend/base/langflow/services/database/models/user/model.py`

```python
class User(SQLModel, table=True):
    id: UUID = Field(default_factory=uuid4, primary_key=True)
    username: str = Field(index=True, unique=True)
    password: str  # Hashed (not used for SSO)
    is_active: bool = Field(default=True)
    is_superuser: bool = Field(default=False)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    last_login_at: Optional[datetime] = None
    store_api_key: Optional[UUID] = None
```

### User Provisioning Code

**Location:** `/src/backend/base/langflow/api/v1/login.py` (SSO endpoint)

```python
# Create user
user = User(
    username=email,  # EnGarde email
    password=email,  # Dummy password (gets hashed)
    is_active=True,
    is_superuser=is_superuser,  # Based on role
)
session.add(user)
await session.commit()
```

### Folder Creation

Each user gets a default folder (workspace):

```python
folder = await get_or_create_default_folder(session, user.id)
# Creates folder named "My Folder" or similar
```

### Multi-Tenant Isolation

**Current State:**
- Langflow does NOT enforce tenant isolation at database level
- All users share the same Langflow database
- Users can see each other's flows (if not private)

**Recommendation for Future:**

Add tenant-based Row-Level Security (RLS):

```sql
-- Add tenant_id to flows table
ALTER TABLE flow ADD COLUMN tenant_id UUID;

-- Create RLS policy
CREATE POLICY tenant_isolation ON flow
  USING (tenant_id = current_setting('app.current_tenant')::UUID);
```

**Implementation:**

```python
# Set tenant context before queries
async with session_scope() as session:
    await session.execute(
        text("SET app.current_tenant = :tenant_id"),
        {"tenant_id": tenant_id}
    )
    # Now all queries are filtered by tenant
```

---

## Database Configuration

### Database Schema

Langflow uses **PostgreSQL** for production (SQLite for dev).

**Connection String Format:**
```
postgresql://user:password@host:port/database
```

### Database Tables

**Core Tables:**

1. **user** - User accounts
2. **flow** - Workflow definitions
3. **folder** - User workspaces/folders
4. **api_key** - API keys for flow execution
5. **variable** - Global variables
6. **vertex_builds** - Component build cache
7. **message** - Chat/execution messages
8. **file** - Uploaded files
9. **transactions** - Execution history

**Database Schema Location:**
```
/src/backend/base/langflow/services/database/models/
├── user/
│   ├── model.py
│   └── crud.py
├── flow/
│   ├── model.py
│   └── crud.py
├── folder/
│   ├── model.py
│   └── crud.py
└── ...
```

### Database Configuration

**Environment Variables:**

```bash
# PostgreSQL (Production)
LANGFLOW_DATABASE_URL=postgresql://langflow_user:password@db.railway.internal:5432/langflow_db

# Connection Pool
LANGFLOW_DATABASE_CONNECTION_RETRY=true

# Alembic Migrations
LANGFLOW_ALEMBIC_LOG_TO_STDOUT=true
```

### Shared Database vs Separate Database

**Current Setup:** Separate Langflow database

**Alternative:** Share EnGarde database with separate schema

```sql
-- Create langflow schema in EnGarde database
CREATE SCHEMA langflow;

-- Set search path
SET search_path TO langflow, public;
```

**Environment Variable:**
```bash
LANGFLOW_DATABASE_URL=postgresql://user:pass@host:5432/engarde_db?options=-c%20search_path=langflow
```

### Migrations

**Alembic Migration Files:**
```
/src/backend/base/langflow/alembic/
├── alembic.ini
├── env.py
└── versions/
    ├── xxx_initial_migration.py
    ├── xxx_add_user_fields.py
    └── ...
```

**Run Migrations:**

```bash
# Inside container
alembic upgrade head

# Via Docker
docker exec -it langflow-container alembic upgrade head
```

### Database Initialization

**On First Startup:**

1. Langflow creates all tables via Alembic
2. Creates default admin user (if `LANGFLOW_AUTO_LOGIN=false`)
3. Loads component registry
4. Ready to accept connections

**Startup Script Location:** `/src/backend/base/langflow/__main__.py`

---

## Environment Variables

### Required Variables

#### Langflow Configuration

```bash
# Host and Port
LANGFLOW_HOST=0.0.0.0
LANGFLOW_PORT=7860  # Or use Railway's PORT variable

# Database
LANGFLOW_DATABASE_URL=postgresql://user:pass@host:5432/langflow_db

# Components Path
LANGFLOW_COMPONENTS_PATH=/app/components

# Authentication
LANGFLOW_AUTO_LOGIN=false  # Must be false for SSO
LANGFLOW_SECRET_KEY=your-shared-secret-key-min-32-chars

# Logging
LANGFLOW_LOG_LEVEL=info
LANGFLOW_ALEMBIC_LOG_TO_STDOUT=true
```

#### SSO Integration

```bash
# Shared secret for JWT validation (MUST match EnGarde backend)
LANGFLOW_SECRET_KEY=abc123xyz789secretkey123456789

# Cookie configuration
LANGFLOW_COOKIE_DOMAIN=.engarde.media  # For subdomain sharing
```

#### EnGarde Backend (for reference)

```bash
# Langflow URL
LANGFLOW_BASE_URL=https://langflow.engarde.media

# Same secret as Langflow
LANGFLOW_SECRET_KEY=abc123xyz789secretkey123456789
```

### Optional Variables

```bash
# Frontend Build
LANGFLOW_FRONTEND_PATH=/app/src/backend/base/langflow/frontend

# Cache
LANGFLOW_CACHE_TYPE=memory  # or redis
LANGFLOW_REDIS_HOST=redis
LANGFLOW_REDIS_PORT=6379

# Workers (for Gunicorn)
LANGFLOW_WORKERS=4

# Browser auto-open (disable for production)
LANGFLOW_OPEN_BROWSER=false

# API Keys
LANGFLOW_REMOVE_API_KEYS=false
LANGFLOW_API_KEY_SOURCE=db  # or env

# Feature Flags
LANGFLOW_STORE_ENVIRONMENT_VARIABLES=true
LANGFLOW_MCP_COMPOSER_ENABLED=true
```

### EnGarde-Specific Variables

```bash
# Backend API URLs (for Walker Agent components)
ENGARDE_API_URL=https://api.engarde.media

# Walker Agent API Keys
WALKER_AGENT_API_KEY_ONSIDE_SEO=wa_onside_production_seo_xxx
WALKER_AGENT_API_KEY_ONSIDE_CONTENT=wa_onside_production_content_xxx
WALKER_AGENT_API_KEY_SANKORE_PAID_ADS=wa_sankore_production_paid_ads_xxx
WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE=wa_madansara_production_audience_xxx
```

### Railway-Specific Variables

```bash
# Railway provides PORT automatically
PORT=7860

# Railway internal DNS
DATABASE_URL=postgresql://postgres:password@postgres.railway.internal:5432/langflow

# Railway domain
RAILWAY_STATIC_URL=langflow-production.up.railway.app
```

### Environment Variable Precedence

1. Railway service variables (highest priority)
2. `.env` file in container
3. Dockerfile `ENV` statements
4. Langflow defaults (lowest priority)

### Setting Variables in Railway

**Via CLI:**
```bash
railway variables set LANGFLOW_SECRET_KEY="your-secret-key"
railway variables set LANGFLOW_DATABASE_URL="postgresql://..."
```

**Via Dashboard:**
1. Go to Railway project
2. Select `langflow-server` service
3. Variables tab
4. Add variable
5. Click "Deploy" to apply

---

## Dockerfile Configuration

### Overview

There are **two Dockerfiles** for different use cases:

1. **Dockerfile.engarde** - Full build from source (recommended for production)
2. **Dockerfile.railway-final** - Lightweight using pre-built image (quick testing)

### Dockerfile.engarde (Production Build)

**Size:** ~5.33GB
**Build Time:** 25-30 minutes
**Use Case:** Production deployment with full customization

**Structure:**

```dockerfile
# Stage 1: Builder
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    npm \
    gcc

# Copy dependency files
COPY ./uv.lock /app/uv.lock
COPY ./pyproject.toml /app/pyproject.toml

# Install Python dependencies
RUN uv sync --no-install-project --no-editable --extra postgresql

# Copy source code
COPY ./src /app/src

# Copy custom components
COPY ["En Garde Components", "/app/components/En Garde Components"]

# Build frontend with branding
COPY src/frontend /tmp/src/frontend
COPY engarde-branding /tmp/engarde-branding

WORKDIR /tmp/src/frontend

# Apply branding changes
RUN sed -i 's/<title>Langflow<\/title>/<title>EnGarde - AI Campaign Builder<\/title>/g' index.html
RUN sed -i 's/"name": "Langflow"/"name": "EnGarde"/g' public/manifest.json
RUN cp /tmp/engarde-branding/logo.png src/assets/logo_dark.png
RUN cp /tmp/engarde-branding/favicon.ico public/favicon.ico

# Build frontend
RUN npm ci && \
    NODE_OPTIONS="--max-old-space-size=12288" npm run build && \
    cp -r build/* /app/src/backend/base/langflow/frontend/

# Final Python sync
WORKDIR /app
RUN uv sync --no-editable --extra postgresql

# Stage 2: Runtime
FROM python:3.12.3-slim AS runtime

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y curl git libpq5 nodejs && \
    useradd user -u 1000 -g 0 --no-create-home

# Copy from builder
COPY --from=builder --chown=1000 /app/.venv /app/.venv
COPY --from=builder --chown=1000 /app/src /app/src
COPY --from=builder --chown=1000 ["/app/components/En Garde Components", "/app/components/En Garde Components"]

# Set PATH
ENV PATH="/app/.venv/bin:$PATH"

# Create startup script
RUN echo '#!/bin/bash\n\
    PORT=${PORT:-7860}\n\
    exec langflow run --host 0.0.0.0 --port $PORT' > /app/start.sh && \
    chmod +x /app/start.sh

USER user
WORKDIR /app

# Environment variables
ENV LANGFLOW_HOST=0.0.0.0
ENV LANGFLOW_COMPONENTS_PATH="/app/components"
ENV LANGFLOW_AUTO_LOGIN=false
ENV LANGFLOW_SECRET_KEY=""

EXPOSE 7860

CMD ["/app/start.sh"]
```

**Key Features:**
- Multi-stage build (reduces final image size)
- Frontend built from source with branding applied
- Custom components included
- Dynamic PORT handling for Railway
- Proper permissions for non-root user

### Dockerfile.railway-final (Lightweight)

**Size:** ~1.5GB
**Build Time:** 5 minutes
**Use Case:** Quick testing, staging

```dockerfile
FROM cope84/engarde-langflow-flattened:temp

# Metadata
LABEL maintainer="EnGarde <support@engarde.media>"
LABEL org.opencontainers.image.title="EnGarde - AI Campaign Builder"

USER user
WORKDIR /app

# Environment variables
ENV LANGFLOW_HOST=0.0.0.0
ENV LANGFLOW_PORT=7860
ENV LANGFLOW_COMPONENTS_PATH="/app/components"
ENV LANGFLOW_AUTO_LOGIN=false
ENV LANGFLOW_SECRET_KEY=""

EXPOSE 7860

CMD ["langflow", "run", "--host", "0.0.0.0", "--port", "7860"]
```

**Note:** Requires pre-built base image `cope84/engarde-langflow-flattened:temp`

### Build Commands

**Build Dockerfile.engarde:**
```bash
cd /path/to/langflow-engarde

docker build \
  -f Dockerfile.engarde \
  -t cope84/engarde-langflow:latest \
  .
```

**Build Dockerfile.railway-final:**
```bash
docker build \
  -f Dockerfile.railway-final \
  -t cope84/engarde-langflow-railway:latest \
  .
```

### Push to Docker Hub

```bash
# Login
docker login

# Push
docker push cope84/engarde-langflow:latest
docker push cope84/engarde-langflow:1.0.0
```

### Which Dockerfile to Use?

| Scenario | Dockerfile | Reason |
|----------|-----------|---------|
| Production deployment | `Dockerfile.engarde` | Full control, all customizations |
| Development | `Dockerfile.engarde` | Can modify source easily |
| Quick testing | `Dockerfile.railway-final` | Faster builds |
| CI/CD pipeline | `Dockerfile.engarde` | Reproducible builds |
| Railway free tier | `Dockerfile.railway-final` | Smaller image, faster deploy |

---

## Deployment Steps

### Prerequisites

1. Railway account
2. GitHub repository with Langflow code
3. PostgreSQL database (Railway provides this)
4. Docker Hub account (optional, for pre-built images)

### Option 1: Deploy from GitHub (Recommended)

**Step 1: Push Code to GitHub**

```bash
cd /path/to/langflow-engarde
git remote add origin https://github.com/EnGardeHQ/langflow-engarde.git
git add .
git commit -m "Initial commit with EnGarde customizations"
git push -u origin main
```

**Step 2: Create Railway Service**

```bash
# Install Railway CLI
npm i -g @railway/cli

# Login
railway login

# Link to project
railway link

# Create new service
railway service create langflow-server

# Set source to GitHub
railway service set-source --repo EnGardeHQ/langflow-engarde --branch main
```

**Step 3: Configure Build Settings**

In Railway dashboard:
1. Go to `langflow-server` service
2. Settings → Build
3. **Builder:** Dockerfile
4. **Dockerfile Path:** `Dockerfile.engarde`
5. **Build Command:** (leave empty)
6. Save

**Step 4: Set Environment Variables**

```bash
railway variables set LANGFLOW_SECRET_KEY="your-shared-secret-key-32-chars-min"
railway variables set LANGFLOW_DATABASE_URL="${{Postgres.DATABASE_URL}}"
railway variables set LANGFLOW_AUTO_LOGIN="false"
railway variables set LANGFLOW_COMPONENTS_PATH="/app/components"
railway variables set LANGFLOW_HOST="0.0.0.0"
```

**Step 5: Deploy**

```bash
railway up
```

**Step 6: Add Custom Domain**

```bash
railway domain add langflow.engarde.media
```

Or via dashboard:
1. Settings → Networking
2. Add custom domain
3. Configure DNS: `CNAME langflow.engarde.media → langflow-production.up.railway.app`

### Option 2: Deploy from Docker Hub

**Step 1: Build and Push Image**

```bash
docker build -f Dockerfile.engarde -t cope84/engarde-langflow:latest .
docker push cope84/engarde-langflow:latest
```

**Step 2: Create Railway Service from Image**

```bash
railway service create langflow-server
railway service set-image cope84/engarde-langflow:latest
```

**Step 3: Set Variables and Deploy**

Same as Option 1, steps 4-6.

### Option 3: Railway Template (Future)

Create `railway.json`:

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile.engarde"
  },
  "deploy": {
    "startCommand": "/app/start.sh",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

Then use "Deploy from Template" button on Railway.

### Post-Deployment Steps

**1. Verify Deployment**

```bash
# Check service status
railway status

# View logs
railway logs --service langflow-server

# Test endpoint
curl https://langflow.engarde.media/health_check
```

**2. Test SSO Integration**

```bash
# Generate SSO token from EnGarde backend
curl -X POST https://api.engarde.media/api/v1/sso/langflow \
  -H "Authorization: Bearer YOUR_ENGARDE_TOKEN"

# Response:
# {
#   "sso_url": "https://langflow.engarde.media/api/v1/custom/sso_login?token=..."
# }

# Open sso_url in browser - should redirect to authenticated Langflow
```

**3. Verify Components Loaded**

```bash
# SSH into Railway container
railway shell

# Check components directory
ls -la /app/components/En\ Garde\ Components/

# Check Langflow logs
cat logs/langflow.log | grep -i component
```

**4. Test Custom Component**

1. Open https://langflow.engarde.media
2. Create new flow
3. Look for "Custom" category in components
4. Drag "Tenant ID Input" component
5. Should appear and be functional

### Troubleshooting Deployment

**Issue: Build fails with "No space left on device"**

**Solution:** Use Railway Pro plan or pre-build image locally

**Issue: SSO not working**

**Solution:**
1. Check `LANGFLOW_SECRET_KEY` matches in both services
2. Verify `LANGFLOW_AUTO_LOGIN=false`
3. Check logs for JWT validation errors

**Issue: Components not loading**

**Solution:**
1. Verify `LANGFLOW_COMPONENTS_PATH=/app/components`
2. Check components were copied in Dockerfile
3. Restart service: `railway restart --service langflow-server`

**Issue: Database connection fails**

**Solution:**
1. Ensure PostgreSQL service is running
2. Check `LANGFLOW_DATABASE_URL` format
3. Test connection: `railway run psql $DATABASE_URL`

---

## Local Development Setup

### Prerequisites

- Python 3.12
- Node.js 18+
- PostgreSQL 14+
- uv (Python package manager)
- Git

### Step 1: Clone Repository

```bash
git clone https://github.com/EnGardeHQ/langflow-engarde.git
cd langflow-engarde
```

### Step 2: Install Dependencies

**Backend:**

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Python dependencies
uv sync --extra postgresql

# Activate virtual environment
source .venv/bin/activate  # Linux/Mac
# or
.venv\Scripts\activate  # Windows
```

**Frontend:**

```bash
cd src/frontend
npm install
```

### Step 3: Configure Database

**Create PostgreSQL Database:**

```sql
CREATE DATABASE langflow_dev;
CREATE USER langflow_user WITH PASSWORD 'langflow_pass';
GRANT ALL PRIVILEGES ON DATABASE langflow_dev TO langflow_user;
```

**Create `.env` file:**

```bash
cd /path/to/langflow-engarde
cat > .env << EOF
# Database
LANGFLOW_DATABASE_URL=postgresql://langflow_user:langflow_pass@localhost:5432/langflow_dev

# Server
LANGFLOW_HOST=0.0.0.0
LANGFLOW_PORT=7860

# Auth
LANGFLOW_AUTO_LOGIN=false
LANGFLOW_SECRET_KEY=dev-secret-key-change-in-production-min-32-chars

# Components
LANGFLOW_COMPONENTS_PATH=/absolute/path/to/langflow-engarde/En Garde Components

# Logging
LANGFLOW_LOG_LEVEL=debug
EOF
```

### Step 4: Run Database Migrations

```bash
cd src/backend/base
alembic upgrade head
```

### Step 5: Start Backend

```bash
# From langflow-engarde root
langflow run --host 0.0.0.0 --port 7860

# Or with hot reload for development
uvicorn langflow.main:create_app --reload --host 0.0.0.0 --port 7860
```

### Step 6: Start Frontend (Optional, for development)

**Option A: Use Pre-built Frontend**

Frontend is already built and served by Langflow backend at `http://localhost:7860`

**Option B: Run Frontend Dev Server (for customization)**

```bash
cd src/frontend
npm run dev  # Runs on http://localhost:3000
```

**Configure API proxy:**

Edit `src/frontend/vite.config.ts`:

```typescript
export default defineConfig({
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:7860',
        changeOrigin: true,
      },
    },
  },
});
```

### Step 7: Test SSO Locally

**Terminal 1 - Start EnGarde Backend (mock):**

```bash
# Create simple FastAPI app for testing
cat > test_sso_backend.py << 'EOF'
from fastapi import FastAPI
from jose import jwt
from datetime import datetime, timedelta

app = FastAPI()

@app.post("/api/v1/sso/langflow")
async def generate_sso_token():
    secret_key = "dev-secret-key-change-in-production-min-32-chars"

    payload = {
        "email": "test@example.com",
        "sub": "test-user-id",
        "tenant_id": "test-tenant-id",
        "tenant_name": "Test Tenant",
        "role": "admin",
        "subscription_tier": "business",
        "exp": datetime.utcnow() + timedelta(minutes=5),
        "iat": datetime.utcnow(),
    }

    token = jwt.encode(payload, secret_key, algorithm="HS256")
    sso_url = f"http://localhost:7860/api/v1/custom/sso_login?token={token}"

    return {"sso_url": sso_url, "expires_in": 300}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF

python test_sso_backend.py
```

**Terminal 2 - Test SSO:**

```bash
# Generate SSO URL
curl -X POST http://localhost:8000/api/v1/sso/langflow

# Copy sso_url from response and open in browser
# Should redirect to Langflow dashboard with authenticated session
```

### Step 8: Verify Custom Components

```bash
# Check components are discovered
ls -la "En Garde Components/"

# Langflow should log on startup:
# INFO: Loading custom components from /path/to/En Garde Components
# INFO: Discovered 14 custom components
```

### Development Workflow

**Making Backend Changes:**

1. Edit files in `/src/backend/base/langflow/`
2. Save
3. Langflow auto-reloads (if using `--reload`)
4. Test at `http://localhost:7860`

**Making Frontend Changes:**

1. Edit files in `/src/frontend/src/`
2. Rebuild frontend:
   ```bash
   cd src/frontend
   npm run build
   cp -r build/* ../backend/base/langflow/frontend/
   ```
3. Restart Langflow backend
4. Refresh browser

**Adding Custom Components:**

1. Create new Python file in `/En Garde Components/`
2. Implement component class
3. Restart Langflow
4. Component appears in UI

**Example:**

```python
# En Garde Components/my_custom_component.py
from langflow.custom import Component
from langflow.io import MessageTextInput, Output
from langflow.schema.message import Message

class MyCustomComponent(Component):
    display_name = "My Custom Component"
    description = "Does something cool"

    inputs = [
        MessageTextInput(
            name="input_text",
            display_name="Input",
        ),
    ]

    outputs = [
        Output(name="output", method="process"),
    ]

    def process(self) -> Message:
        result = f"Processed: {self.input_text}"
        return Message(text=result)
```

---

## Testing the Installation

### 1. Health Check

**Test Langflow is Running:**

```bash
curl https://langflow.engarde.media/health_check
```

**Expected Response:**
```json
{
  "status": "ok",
  "version": "1.7.1"
}
```

### 2. SSO Authentication Test

**Step 1: Generate SSO Token**

```bash
# From EnGarde frontend or via API
curl -X POST https://api.engarde.media/api/v1/sso/langflow \
  -H "Authorization: Bearer YOUR_ENGARDE_TOKEN" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "sso_url": "https://langflow.engarde.media/api/v1/custom/sso_login?token=eyJ...",
  "expires_in": 300
}
```

**Step 2: Test SSO Login**

1. Open `sso_url` in browser
2. Should redirect to Langflow dashboard
3. Should be logged in (no login page)
4. Check browser cookies: should have `access_token_lf`

**Step 3: Verify User Created**

```sql
-- Connect to Langflow database
SELECT * FROM "user" WHERE username = 'your-email@example.com';
```

**Expected:**
| id | username | is_active | is_superuser | created_at |
|----|----------|-----------|--------------|------------|
| uuid | your-email@example.com | true | true/false | timestamp |

### 3. Custom Components Test

**Step 1: Check Components Load**

1. Open Langflow: https://langflow.engarde.media
2. Click "New Flow"
3. Look at left sidebar components
4. Search for "Tenant" or "Walker"

**Expected:**
- See "Custom" category
- See "Tenant ID Input"
- See "Walker Agent API Request"
- See "SEO Walker Agent (Complete)"
- etc.

**Step 2: Test Component Functionality**

1. Drag "Tenant ID Input" to canvas
2. Enter a tenant UUID: `123e4567-e89b-12d3-a456-426614174000`
3. Click "Run" button
4. Should execute without errors
5. Check output: should show the UUID

**Step 3: Test Walker Agent API**

1. Create flow with:
   - Tenant ID Input
   - SEO Walker Agent (Complete)
   - Text Output
2. Connect components
3. Enter valid tenant ID
4. Click "Run"
5. Check output

**Expected Response:**
```json
{
  "success": true,
  "batch_id": "...",
  "suggestions_received": 1,
  "suggestions_stored": 1
}
```

### 4. Database Test

**Check User Table:**

```sql
SELECT id, username, is_active, is_superuser, created_at
FROM "user"
ORDER BY created_at DESC
LIMIT 10;
```

**Check Flows Table:**

```sql
SELECT id, name, user_id, created_at
FROM flow
ORDER BY created_at DESC
LIMIT 10;
```

**Check Folders Table:**

```sql
SELECT id, name, user_id, created_at
FROM folder
ORDER BY created_at DESC
LIMIT 10;
```

### 5. API Endpoint Tests

**Test Flow Execution API:**

```bash
# Get a flow ID from database or UI
FLOW_ID="your-flow-uuid"

# Execute flow
curl -X POST "https://langflow.engarde.media/api/v1/run/${FLOW_ID}" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_LANGFLOW_API_KEY" \
  -d '{
    "input_value": "test input",
    "input_type": "text",
    "output_type": "text"
  }'
```

**Test Component List API:**

```bash
curl https://langflow.engarde.media/api/v1/all
```

**Expected:** JSON with all available components including custom ones.

### 6. Branding Verification

**Visual Check:**

1. Open https://langflow.engarde.media
2. Verify:
   - ✅ EnGarde logo in top-left header (not Langflow logo)
   - ✅ Page title: "EnGarde - AI Campaign Builder"
   - ✅ Footer: "Made by EnGarde with ❤️"
   - ❌ No Langflow branding visible
   - ❌ No DataStax branding visible

**Code Check:**

```bash
# Check favicon
curl -I https://langflow.engarde.media/favicon.ico

# Check manifest
curl https://langflow.engarde.media/manifest.json | jq .name
# Expected: "EnGarde"

# Check page title
curl https://langflow.engarde.media | grep "<title>"
# Expected: <title>EnGarde - AI Campaign Builder</title>
```

### 7. Integration Test (End-to-End)

**Full SSO Flow:**

1. Log into EnGarde dashboard at https://app.engarde.media
2. Click "Agent Suite" in sidebar
3. Should load Langflow in iframe
4. Should be automatically authenticated
5. Create a new flow
6. Add custom "SEO Walker Agent" component
7. Enter tenant ID from EnGarde
8. Run flow
9. Verify suggestion appears in EnGarde dashboard

**Expected Result:** Seamless experience, no login required, all components functional.

### 8. Performance Test

**Load Testing:**

```bash
# Install k6
brew install k6  # or download from k6.io

# Create test script
cat > load_test.js << 'EOF'
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  vus: 10,  // 10 virtual users
  duration: '30s',
};

export default function() {
  let res = http.get('https://langflow.engarde.media/health_check');
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
}
EOF

# Run test
k6 run load_test.js
```

**Expected:**
- All requests succeed
- Average response time < 500ms
- No errors

### 9. Error Handling Test

**Test Invalid SSO Token:**

```bash
# Invalid token
curl "https://langflow.engarde.media/api/v1/custom/sso_login?token=invalid"
```

**Expected:** HTTP 401 error with "Invalid SSO token" message

**Test Expired Token:**

Generate token with past expiration, should get "SSO token expired"

### 10. Rollback Test

**Test Rollback to Previous Deployment:**

```bash
# Railway CLI
railway rollback

# Or via dashboard:
# Deployments tab → Click on previous deployment → Redeploy
```

**Expected:** Previous version loads successfully

---

## Appendix A: File Locations Quick Reference

### Backend Files

| File | Path | Purpose |
|------|------|---------|
| SSO Endpoint | `/src/backend/base/langflow/api/v1/login.py` | Handles SSO login |
| Custom Endpoint (alternate) | `/src/backend/base/langflow/api/v1/custom.py` | Custom endpoints |
| Router Registration | `/src/backend/base/langflow/api/router.py` | API routing |
| User Model | `/src/backend/base/langflow/services/database/models/user/model.py` | User database model |
| Auth Utils | `/src/backend/base/langflow/services/auth/utils.py` | Token creation |

### Frontend Files

| File | Path | Purpose |
|------|------|---------|
| Header | `/src/frontend/src/components/core/appHeaderComponent/index.tsx` | EnGarde logo |
| Footer | `/src/frontend/src/components/core/engardeFooter/index.tsx` | EnGarde footer |
| App Root | `/src/frontend/src/App.tsx` | Main app component |
| Index HTML | `/src/frontend/index.html` | Page title |
| Manifest | `/src/frontend/public/manifest.json` | PWA manifest |
| Favicon | `/src/frontend/public/favicon.ico` | Browser icon |

### Custom Components

| File | Path | Purpose |
|------|------|---------|
| All Components | `/En Garde Components/` | Walker agent components |
| Tenant Input | `/En Garde Components/tenant_id_input.py` | Tenant ID component |
| API Component | `/En Garde Components/walker_agent_api.py` | API integration |
| SEO Walker | `/En Garde Components/seo_walker_agent.py` | SEO agent |

### Configuration Files

| File | Path | Purpose |
|------|------|---------|
| Dockerfile (prod) | `/Dockerfile.engarde` | Production build |
| Dockerfile (test) | `/Dockerfile.railway-final` | Quick testing |
| Python Deps | `/pyproject.toml` | Python dependencies |
| Railway Config | `/railway.toml` | Railway settings |
| Environment Example | `/.env.example` | Environment variables |

### EnGarde Integration (External)

| File | Path | Purpose |
|------|------|---------|
| SSO Backend | `/production-backend/app/routers/langflow_sso.py` | Generate SSO tokens |
| SSO Frontend | `/production-frontend/components/workflow/AuthenticatedLangflowIframe.tsx` | Iframe integration |
| Langflow Service | `/production-frontend/services/langflow.service.ts` | API client |

---

## Appendix B: Common Commands Cheat Sheet

### Docker Commands

```bash
# Build image
docker build -f Dockerfile.engarde -t engarde-langflow .

# Run container
docker run -p 7860:7860 -e DATABASE_URL=... engarde-langflow

# Push to Docker Hub
docker push cope84/engarde-langflow:latest

# View logs
docker logs -f container-id

# Shell into container
docker exec -it container-id /bin/bash
```

### Railway Commands

```bash
# Deploy
railway up

# View logs
railway logs --service langflow-server

# Set variable
railway variables set KEY=value

# Restart service
railway restart --service langflow-server

# Shell access
railway shell

# Rollback
railway rollback
```

### Database Commands

```bash
# Connect to database
psql $LANGFLOW_DATABASE_URL

# Run migrations
alembic upgrade head

# Rollback migration
alembic downgrade -1

# Create migration
alembic revision -m "description"
```

### Component Development

```bash
# Test component loading
ls -la /app/components/En\ Garde\ Components/

# Restart Langflow to reload components
pkill -f langflow && langflow run

# Check component logs
grep -i component logs/langflow.log
```

---

## Appendix C: Troubleshooting Guide

### Issue: SSO Login Fails

**Symptoms:**
- "Invalid SSO token" error
- Redirects to login page
- JWT validation error in logs

**Solutions:**

1. **Check shared secret matches:**
   ```bash
   # EnGarde backend
   echo $LANGFLOW_SECRET_KEY

   # Langflow
   railway variables --service langflow-server | grep SECRET_KEY
   ```

2. **Verify token not expired:**
   - SSO tokens expire in 5 minutes
   - Generate new token and try immediately

3. **Check LANGFLOW_AUTO_LOGIN is false:**
   ```bash
   railway variables --service langflow-server | grep AUTO_LOGIN
   # Should be: LANGFLOW_AUTO_LOGIN=false
   ```

4. **Inspect JWT payload:**
   ```bash
   # Decode JWT (without verification)
   echo "YOUR_TOKEN" | cut -d. -f2 | base64 -d | jq
   ```

### Issue: Components Not Loading

**Symptoms:**
- Custom components don't appear in UI
- "Custom" category missing
- Component import errors in logs

**Solutions:**

1. **Verify components path:**
   ```bash
   railway shell
   echo $LANGFLOW_COMPONENTS_PATH
   ls -la $LANGFLOW_COMPONENTS_PATH
   ```

2. **Check components directory structure:**
   ```bash
   ls -la "/app/components/En Garde Components/"
   # Should see all .py files
   ```

3. **Look for import errors:**
   ```bash
   railway logs | grep -i "error\|import\|component"
   ```

4. **Verify dependencies installed:**
   ```bash
   railway shell
   python -c "import httpx; print(httpx.__version__)"
   ```

5. **Restart service:**
   ```bash
   railway restart --service langflow-server
   ```

### Issue: Database Connection Fails

**Symptoms:**
- "Connection refused" errors
- "Could not connect to server" in logs
- 500 errors on API calls

**Solutions:**

1. **Check DATABASE_URL format:**
   ```bash
   railway variables --service langflow-server | grep DATABASE_URL
   # Should be: postgresql://user:pass@host:port/db
   ```

2. **Test connection manually:**
   ```bash
   railway shell
   psql $LANGFLOW_DATABASE_URL -c "SELECT 1;"
   ```

3. **Verify PostgreSQL service is running:**
   ```bash
   railway status
   ```

4. **Check database exists:**
   ```sql
   \l  -- List all databases
   ```

5. **Run migrations:**
   ```bash
   railway shell
   alembic upgrade head
   ```

### Issue: Build Fails

**Symptoms:**
- Docker build errors
- "No space left on device"
- npm build failures

**Solutions:**

1. **Free up disk space:**
   ```bash
   docker system prune -af --volumes
   ```

2. **Increase Docker memory:**
   - Docker Desktop → Settings → Resources
   - Set Memory to 8GB+

3. **Use pre-built image:**
   ```bash
   # Switch to Dockerfile.railway-final
   railway service set-dockerfile Dockerfile.railway-final
   ```

4. **Build locally and push:**
   ```bash
   docker build -f Dockerfile.engarde -t cope84/engarde-langflow:latest .
   docker push cope84/engarde-langflow:latest
   railway service set-image cope84/engarde-langflow:latest
   ```

### Issue: Branding Not Appearing

**Symptoms:**
- Still seeing Langflow logo
- EnGarde footer missing
- Old page title

**Solutions:**

1. **Hard refresh browser:**
   - Chrome/Firefox: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
   - Clear browser cache

2. **Verify correct image deployed:**
   ```bash
   railway logs | grep "Starting"
   # Check image name in logs
   ```

3. **Check frontend files:**
   ```bash
   railway shell
   cat /app/src/backend/base/langflow/frontend/index.html | grep title
   # Should see: EnGarde - AI Campaign Builder
   ```

4. **Rebuild from source:**
   ```bash
   railway service trigger-deploy --force
   ```

---

## Appendix D: Migration Guide (Fresh Install)

### Scenario: Installing Langflow from Scratch

If you need to completely recreate the Langflow deployment:

**Step 1: Clone Repository**

```bash
git clone https://github.com/EnGardeHQ/langflow-engarde.git
cd langflow-engarde
```

**Step 2: Review Custom Changes**

```bash
# Backend SSO endpoint
cat src/backend/base/langflow/api/v1/login.py | grep -A 50 "sso_login"

# Frontend branding
cat src/frontend/src/components/core/appHeaderComponent/index.tsx | grep "EnGarde"

# Custom components
ls -la "En Garde Components/"
```

**Step 3: Build Docker Image**

```bash
docker build -f Dockerfile.engarde -t cope84/engarde-langflow:latest .
```

**Step 4: Push to Docker Hub**

```bash
docker login
docker push cope84/engarde-langflow:latest
```

**Step 5: Create Railway Service**

```bash
railway service create langflow-server
railway service set-image cope84/engarde-langflow:latest
```

**Step 6: Set Environment Variables**

```bash
# Copy from .env.example or existing deployment
railway variables set LANGFLOW_SECRET_KEY="..."
railway variables set LANGFLOW_DATABASE_URL="${{Postgres.DATABASE_URL}}"
railway variables set LANGFLOW_AUTO_LOGIN="false"
railway variables set LANGFLOW_COMPONENTS_PATH="/app/components"
railway variables set LANGFLOW_HOST="0.0.0.0"
railway variables set ENGARDE_API_URL="https://api.engarde.media"
railway variables set WALKER_AGENT_API_KEY_ONSIDE_SEO="wa_..."
# ... (set all Walker Agent API keys)
```

**Step 7: Deploy**

```bash
railway up
```

**Step 8: Verify Deployment**

```bash
# Health check
curl https://langflow.engarde.media/health_check

# SSO test
curl -X POST https://api.engarde.media/api/v1/sso/langflow \
  -H "Authorization: Bearer YOUR_TOKEN"

# Open returned sso_url in browser
```

**Step 9: Configure EnGarde Backend**

Update EnGarde backend environment:

```bash
# In production-backend service
railway variables set LANGFLOW_BASE_URL="https://langflow.engarde.media"
railway variables set LANGFLOW_SECRET_KEY="same-as-langflow-secret"
```

**Step 10: Test Integration**

1. Log into EnGarde dashboard
2. Navigate to Agent Suite page
3. Should see Langflow embedded
4. Create test flow
5. Verify everything works

---

## Appendix E: Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | Jan 10, 2026 | Initial documentation created |
| | | - SSO integration documented |
| | | - Custom components documented |
| | | - Deployment steps documented |

---

## Support & Maintenance

**Repository:** https://github.com/EnGardeHQ/langflow-engarde
**Based On:** Langflow v1.7.1 (https://github.com/langflow-ai/langflow)
**Maintainer:** EnGarde Development Team
**Contact:** support@engarde.media

**Regular Maintenance Tasks:**

1. **Weekly:** Check Railway logs for errors
2. **Monthly:** Review Langflow for new upstream releases
3. **Quarterly:** Update dependencies (uv sync)
4. **Yearly:** Rotate LANGFLOW_SECRET_KEY

**Updating to New Langflow Version:**

```bash
# 1. Add official Langflow as upstream
git remote add upstream https://github.com/langflow-ai/langflow.git

# 2. Fetch latest
git fetch upstream

# 3. Create update branch
git checkout -b update-langflow-v1.8.0

# 4. Merge (will have conflicts)
git merge upstream/main

# 5. Resolve conflicts (carefully preserve customizations)
# - SSO endpoint in login.py
# - Frontend branding files
# - Custom components

# 6. Test locally
langflow run

# 7. Deploy to staging
railway deploy --environment staging

# 8. Test thoroughly
# 9. Deploy to production
railway deploy --environment production
```

---

**End of Documentation**

This guide should allow any developer to completely recreate the EnGarde Langflow deployment from scratch, understanding all customizations and integration points.
