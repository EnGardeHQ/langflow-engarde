# EnGarde Development Rules & Standards

**Version:** 2.0.0
**Last Updated:** 2026-01-25
**Status:** MANDATORY - All developers and AI coding agents MUST follow these rules

---

## 🚨 CRITICAL: READ THIS FIRST

This document contains the **complete set of development rules** for the EnGarde platform. It covers:

1. **Frontend Development** - UI components, styling, data retrieval
2. **Backend Development** - API design, database models, services
3. **Third-Party Integrations** - External APIs and services
4. **RESTful API Standards** - EnGarde API conventions
5. **Security & Compliance** - SOC II, data protection, audit

**All pull requests violating these rules will be automatically rejected.**

---

# PART 1: FRONTEND DEVELOPMENT RULES

## 1.1 UI Component Abstractions (MANDATORY)

### Rule: NO Direct Chakra UI Imports

**The frontend MUST use UI component abstractions to enable future library replacement.**

```typescript
// ❌ WRONG - WILL BE REJECTED
import { Button, Box, Card } from '@chakra-ui/react'

// ✅ CORRECT - Use abstractions
import { Button } from '@/components/ui/button'
import { Card, CardBody, CardHeader } from '@/components/ui/card'
import { Container, VStack, HStack } from '@/components/ui/layout'
import { Heading, Text } from '@/components/ui/typography'
```

**Why:** This allows replacing Chakra UI with shadcn/ui, MUI, Mantine, or any other library without rewriting feature code.

### UI Component Hierarchy

```
Feature Components (your code)
       ↓
  UI Abstractions (/components/ui/*)
       ↓
   Chakra UI (current - replaceable)
```

---

## 1.2 Color System (NO Hardcoded Colors)

### Rule: Use Semantic Color Tokens

```typescript
// ❌ WRONG - Hardcoded hex colors
<Box bg="#3182CE" color="#718096">

// ✅ CORRECT - Semantic tokens
<Box bg="blue.500" color="gray.600">

// ✅ CORRECT - Theme-aware dark mode
const bgColor = useColorModeValue('white', 'gray.800')
const textColor = useColorModeValue('gray.900', 'white')
```

**Approved Color Tokens:**
- `gray.50-900` - Backgrounds, text
- `blue.500` - Primary actions
- `red.500` - Errors, danger
- `green.500` - Success
- `yellow.500` - Warnings
- `purple.500` - Info, accents

---

## 1.3 Spacing System (NO Pixel Values)

### Rule: Use Spacing Tokens

```typescript
// ❌ WRONG - Pixel values
<Box padding="16px" margin="24px">

// ✅ CORRECT - Spacing tokens
<Box p={4} m={6}>

// Spacing scale
p={1}  // 4px
p={2}  // 8px
p={4}  // 16px
p={6}  // 24px
p={8}  // 32px
p={12} // 48px
```

---

## 1.4 Responsive Design (MANDATORY)

### Rule: Mobile-First Responsive Props

```typescript
// ✅ CORRECT - Responsive design
<Box
  w={{ base: '100%', md: '50%', lg: '33.333%' }}
  p={{ base: 4, md: 6, lg: 8 }}
  display={{ base: 'block', md: 'flex' }}
>
```

**Breakpoints:**
- `base`: 0px (mobile)
- `md`: 768px (tablet)
- `lg`: 992px (desktop)
- `xl`: 1280px (large desktop)

---

## 1.5 Data Retrieval Patterns

### Rule: Use AuthContext and React Query

```typescript
// ✅ CORRECT - Auth data
import { useAuth } from '@/contexts/AuthContext'

const { state } = useAuth()
const tenantId = state.user?.tenant_id
const isAuthLoading = state.loading || state.initializing

// ✅ CORRECT - API queries
import { useQuery } from '@tanstack/react-query'
import { apiClient } from '@/lib/api/client'

const { data, isLoading } = useQuery({
  queryKey: ['campaigns', tenantId],
  queryFn: () => apiClient.get(`/campaigns?tenant_id=${tenantId}`),
  enabled: !!tenantId && !isAuthLoading
})
```

### Rule: ALWAYS Include tenant_id

```typescript
// ❌ WRONG - Missing tenant_id
await apiClient.get('/campaigns')

// ✅ CORRECT - Tenant-scoped
await apiClient.get(`/campaigns?tenant_id=${tenantId}`)
```

---

## 1.6 Component Structure Template

```typescript
'use client' // Only for client components

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useAuth } from '@/contexts/AuthContext'
import { useColorModeValue } from '@chakra-ui/react'

// ✅ Import UI abstractions
import { Card, CardBody, CardHeader } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Heading, Text } from '@/components/ui/typography'

interface MyComponentProps {
  id: string
  onComplete?: () => void
}

export function MyComponent({ id, onComplete }: MyComponentProps) {
  // 1. Hooks
  const { state } = useAuth()
  const bgColor = useColorModeValue('white', 'gray.800')

  // 2. Queries
  const { data, isLoading } = useQuery({
    queryKey: ['data', id],
    queryFn: () => fetchData(id)
  })

  // 3. Handlers
  const handleSubmit = async () => {
    // Implementation
  }

  // 4. Render
  if (isLoading) return <Spinner />

  return (
    <Card bg={bgColor}>
      <CardHeader>
        <Heading size="md">{data?.title}</Heading>
      </CardHeader>
      <CardBody>
        <Button onClick={handleSubmit} colorScheme="blue">
          Submit
        </Button>
      </CardBody>
    </Card>
  )
}
```

---

## 1.7 Component Creation Checklist

Before submitting frontend code:

- [ ] No direct `@chakra-ui/react` imports
- [ ] All colors use theme tokens (no hex codes)
- [ ] All spacing uses token scale (no px values)
- [ ] Responsive design implemented (base, md, lg)
- [ ] Dark mode supported (useColorModeValue)
- [ ] Auth loading states handled
- [ ] Tenant ID included in queries
- [ ] TypeScript types defined
- [ ] Accessibility (aria-labels, keyboard nav)
- [ ] Loading states handled
- [ ] Error states handled

**Reference:** `/production-frontend/FRONTEND_STYLE_GUIDE.md` for complete patterns

---

# PART 2: BACKEND DEVELOPMENT RULES

## 2.1 RESTful API Standards

### Rule: Consistent Endpoint Structure

```
GET    /api/{resource}              - List all (paginated)
GET    /api/{resource}/{id}         - Get one
POST   /api/{resource}              - Create
PUT    /api/{resource}/{id}         - Update (full)
PATCH  /api/{resource}/{id}         - Update (partial)
DELETE /api/{resource}/{id}         - Delete

// Nested resources
GET    /api/{resource}/{id}/{nested}
POST   /api/{resource}/{id}/{nested}
```

### Rule: Tenant Isolation (MANDATORY)

**ALL endpoints MUST enforce tenant isolation:**

```python
# ✅ CORRECT - Tenant scoped
@router.get("/campaigns")
async def list_campaigns(
    tenant_id: str = Query(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Verify user belongs to tenant
    if current_user.tenant_id != tenant_id:
        raise HTTPException(status_code=403, detail="Access denied")

    campaigns = db.query(Campaign).filter(
        Campaign.tenant_id == tenant_id
    ).all()

    return campaigns
```

### Rule: Standard Response Format

```python
# Success response
{
  "data": { ... },
  "message": "Operation successful",
  "timestamp": "2026-01-25T10:30:00Z"
}

# List response (paginated)
{
  "items": [ ... ],
  "total": 100,
  "page": 1,
  "page_size": 20,
  "total_pages": 5
}

# Error response
{
  "detail": "Resource not found",
  "error_code": "RESOURCE_NOT_FOUND",
  "timestamp": "2026-01-25T10:30:00Z"
}
```

---

## 2.2 Database Models (SQLAlchemy)

### Rule: Model Structure

```python
from sqlalchemy import Column, String, DateTime, ForeignKey, Index
from app.database import Base
from datetime import datetime
import uuid

class MyModel(Base):
    """Model description"""
    __tablename__ = "my_models"

    # Primary key
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))

    # Tenant isolation (MANDATORY)
    tenant_id = Column(String(36), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)

    # Fields
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)

    # Audit timestamps (MANDATORY)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Indexes
    __table_args__ = (
        Index('idx_mymodel_tenant', 'tenant_id'),
        Index('idx_mymodel_created', 'created_at'),
    )
```

### Rule: ALWAYS Include

1. **tenant_id** - For multi-tenancy
2. **created_at** - Audit trail
3. **updated_at** - Audit trail
4. **Indexes** - On foreign keys and query fields

---

## 2.3 Service Layer Pattern

### Rule: Business Logic in Services

```python
# app/services/my_service.py

class MyService:
    """Service for business logic"""

    @staticmethod
    def create_resource(
        db: Session,
        tenant_id: str,
        data: dict
    ) -> MyModel:
        """Create resource with validation"""

        # 1. Validate
        if not data.get('name'):
            raise ValueError("Name is required")

        # 2. Create
        resource = MyModel(
            tenant_id=tenant_id,
            name=data['name'],
            description=data.get('description')
        )

        db.add(resource)
        db.commit()
        db.refresh(resource)

        # 3. Return
        return resource
```

### Rule: Routers Call Services

```python
# app/routers/my_router.py

from app.services.my_service import MyService

@router.post("/resources")
async def create_resource(
    data: ResourceCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    resource = MyService.create_resource(
        db=db,
        tenant_id=current_user.tenant_id,
        data=data.dict()
    )

    return resource
```

---

## 2.4 Authentication & Authorization

### Rule: JWT Token Authentication

```python
from app.routers.auth import get_current_user
from app.models.core import User

@router.get("/protected")
async def protected_route(
    current_user: User = Depends(get_current_user)
):
    # current_user is authenticated
    # current_user.tenant_id available
    return {"user": current_user.email}
```

### Rule: Admin Protection

```python
from app.routers.auth import require_admin

@router.get("/admin/resource", dependencies=[Depends(require_admin)])
async def admin_only_route(
    current_user: User = Depends(get_current_user)
):
    # Only admins can access
    return {"data": "sensitive"}
```

---

## 2.5 Error Handling

### Rule: HTTP Exceptions

```python
from fastapi import HTTPException, status

# 400 - Bad Request
if not data.valid():
    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail="Invalid data provided"
    )

# 403 - Forbidden
if user.tenant_id != resource.tenant_id:
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Access denied"
    )

# 404 - Not Found
if not resource:
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="Resource not found"
    )

# 409 - Conflict
if existing_resource:
    raise HTTPException(
        status_code=status.HTTP_409_CONFLICT,
        detail="Resource already exists"
    )
```

---

## 2.6 Database Migrations

### Rule: SQL Migration Files

```sql
-- migrations/versions/add_my_feature.sql

-- Create table
CREATE TABLE IF NOT EXISTS my_models (
    id VARCHAR(36) PRIMARY KEY,
    tenant_id VARCHAR(36) NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_mymodel_tenant ON my_models(tenant_id);
CREATE INDEX IF NOT EXISTS idx_mymodel_created ON my_models(created_at);

-- Create update trigger
CREATE OR REPLACE FUNCTION update_my_model_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER my_model_updated_at
    BEFORE UPDATE ON my_models
    FOR EACH ROW
    EXECUTE FUNCTION update_my_model_updated_at();
```

### Rule: Run Migrations via Direct SQL

```bash
# Use DATABASE_PUBLIC_URL for migrations
psql "$DATABASE_PUBLIC_URL" -f migrations/versions/add_my_feature.sql
```

---

## 2.7 Logging & Monitoring

### Rule: Structured Logging

```python
import logging

logger = logging.getLogger(__name__)

# Info level
logger.info(f"Campaign created: {campaign.id} for tenant {tenant_id}")

# Warning level
logger.warning(f"Rate limit approaching for tenant {tenant_id}")

# Error level (with context)
logger.error(
    f"Failed to create campaign for tenant {tenant_id}",
    exc_info=True,
    extra={"tenant_id": tenant_id, "data": data}
)

# NEVER log sensitive data
# ❌ WRONG
logger.info(f"User password: {password}")

# ✅ CORRECT
logger.info(f"User authentication attempted: {email}")
```

---

# PART 3: THIRD-PARTY INTEGRATIONS

## 3.1 Integration Partner Categories

### AI & ML Services

**Required API Keys:**
- `OPENAI_API_KEY` - GPT-4 text generation
- `ANTHROPIC_API_KEY` - Claude reasoning
- `GOOGLE_AI_API_KEY` - Gemini multimodal
- `LANGFLOW_API_KEY` - AI workflow orchestration

**Usage Pattern:**
```python
from app.services.ai_service_wrapper import AIServiceWrapper

ai_service = AIServiceWrapper()
response = await ai_service.generate_content(
    prompt="Generate campaign copy",
    model="gpt-4"
)
```

### Social Media Platforms

**Required API Keys:**
- `META_APP_ID`, `META_APP_SECRET` - Facebook/Instagram
- `TIKTOK_APP_ID`, `TIKTOK_APP_SECRET` - TikTok Ads
- `YOUTUBE_API_KEY` - YouTube Data API
- `LINKEDIN_CLIENT_ID`, `LINKEDIN_CLIENT_SECRET` - LinkedIn

**OAuth Flow:**
```python
@router.get("/oauth/{platform}/callback")
async def oauth_callback(
    platform: str,
    code: str,
    state: str,
    current_user: User = Depends(get_current_user)
):
    # Exchange code for token
    token = await exchange_oauth_code(platform, code)

    # Store encrypted token
    await store_integration_token(
        user_id=current_user.id,
        platform=platform,
        access_token=token.access_token,
        refresh_token=token.refresh_token
    )

    return {"success": True}
```

### E-commerce & CRM

**Required API Keys:**
- `SHOPIFY_API_KEY`, `SHOPIFY_API_SECRET` - Shopify
- `STRIPE_SECRET_KEY` - Payment processing
- `MAILCHIMP_API_KEY` - Email marketing
- `HUBSPOT_API_KEY` - CRM integration

### Communication Channels

**Required API Keys:**
- `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN` - SMS/WhatsApp
- `SENDGRID_API_KEY` - Email delivery
- `MAILGUN_API_KEY` - Transactional email

---

## 3.2 Integration Security Rules

### Rule: Encrypted Credential Storage

```python
from cryptography.fernet import Fernet

# NEVER store plaintext credentials
# ❌ WRONG
integration.api_key = api_key

# ✅ CORRECT - Encrypt before storage
encrypted_key = encrypt_credential(api_key)
integration.encrypted_api_key = encrypted_key
```

### Rule: Credential Rotation

```python
# Check token expiry
if integration.token_expires_at < datetime.utcnow():
    # Refresh token
    new_token = await refresh_oauth_token(
        platform=integration.platform,
        refresh_token=integration.refresh_token
    )

    # Update
    integration.access_token = encrypt_credential(new_token.access_token)
    integration.token_expires_at = new_token.expires_at
```

### Rule: Rate Limiting

```python
from app.services.rate_limiter import RateLimiter

rate_limiter = RateLimiter(
    key=f"integration:{platform}:{tenant_id}",
    max_requests=100,
    window_seconds=60
)

if not await rate_limiter.allow():
    raise HTTPException(
        status_code=429,
        detail="Rate limit exceeded"
    )
```

---

## 3.3 Webhook Handling

### Rule: Webhook Signature Verification

```python
import hmac
import hashlib

@router.post("/webhooks/{platform}")
async def handle_webhook(
    platform: str,
    request: Request
):
    # 1. Verify signature
    body = await request.body()
    signature = request.headers.get("X-Signature")

    expected_signature = hmac.new(
        WEBHOOK_SECRET.encode(),
        body,
        hashlib.sha256
    ).hexdigest()

    if not hmac.compare_digest(signature, expected_signature):
        raise HTTPException(status_code=401, detail="Invalid signature")

    # 2. Process webhook
    data = await request.json()
    await process_webhook_event(platform, data)

    return {"success": True}
```

---

# PART 4: SECURITY & COMPLIANCE

## 4.1 SOC II Compliance Requirements

### Rule: Data Protection

**Admin users CANNOT access user message content:**

```python
# ✅ CORRECT - Admin sees metadata only
@router.get("/admin/conversations/{id}")
async def get_conversation_metadata(
    conversation_id: str,
    current_user: User = Depends(require_admin)
):
    # Return metrics, NOT content
    return {
        "id": conversation.id,
        "channel": conversation.channel,
        "message_count": conversation.message_count,
        "failed_message_count": conversation.failed_message_count,
        # NO message content
        "note": "Message content not accessible for SOC II compliance"
    }
```

### Rule: Audit Logging

```python
# Log ALL admin access
conversation_service.log_access(
    db=db,
    conversation_id=conversation_id,
    action="admin_viewed_metadata",
    user=current_user,
    ip_address=request.client.host,
    user_agent=request.headers.get("user-agent"),
    reason="Admin operational monitoring - no content access"
)
```

---

## 4.2 PII Protection

### Rule: PII Redaction

```python
# NEVER store raw PII
# ✅ CORRECT - Hash and redact
user_id_hash = hashlib.sha256(user_identifier.encode()).hexdigest()
display_name = f"User-{user_id_hash[:8].upper()}"

# Store anonymized version
message.content_anonymized = redact_pii(message.content)
message.user_id_hash = user_id_hash
```

### Rule: PII in Logs

```python
# ❌ NEVER log PII
logger.info(f"User {email} logged in with password {password}")

# ✅ CORRECT - Log without PII
logger.info(f"User authentication successful: {user_id_hash}")
```

---

## 4.3 Input Validation

### Rule: Validate ALL Input

```python
from pydantic import BaseModel, validator, EmailStr

class UserCreate(BaseModel):
    email: EmailStr
    name: str
    age: int

    @validator('name')
    def name_must_be_valid(cls, v):
        if len(v) < 2 or len(v) > 100:
            raise ValueError('Name must be 2-100 characters')
        return v

    @validator('age')
    def age_must_be_valid(cls, v):
        if v < 18 or v > 120:
            raise ValueError('Age must be 18-120')
        return v
```

---

## 4.4 SQL Injection Prevention

### Rule: ALWAYS Use Parameterized Queries

```python
# ❌ WRONG - SQL Injection risk
query = f"SELECT * FROM users WHERE email = '{email}'"
db.execute(query)

# ✅ CORRECT - Parameterized
query = db.query(User).filter(User.email == email)
```

---

# PART 5: TDD/BDD & TESTING

## 5.1 Test-Driven Development

### Rule: Red → Green → Refactor

```python
# 1. RED - Write failing test first
def test_create_campaign():
    """Test campaign creation"""
    campaign = CampaignService.create_campaign(
        db=db,
        tenant_id="test-tenant",
        data={"name": "Test Campaign"}
    )

    assert campaign.name == "Test Campaign"
    assert campaign.tenant_id == "test-tenant"

# 2. GREEN - Minimal code to pass
def create_campaign(db, tenant_id, data):
    campaign = Campaign(
        tenant_id=tenant_id,
        name=data['name']
    )
    db.add(campaign)
    db.commit()
    return campaign

# 3. REFACTOR - Improve while keeping tests green
```

---

## 5.2 BDD Test Structure

### Rule: Given/When/Then

```python
def test_user_can_create_campaign():
    """
    Given a logged-in user with valid tenant
    When they create a campaign with valid data
    Then the campaign is created and saved to database
    """
    # Given
    user = create_test_user(tenant_id="test-tenant")
    campaign_data = {"name": "New Campaign"}

    # When
    campaign = CampaignService.create_campaign(
        db=db,
        tenant_id=user.tenant_id,
        data=campaign_data
    )

    # Then
    assert campaign.id is not None
    assert campaign.name == "New Campaign"
    assert campaign.tenant_id == user.tenant_id
```

---

# PART 6: GIT & PR WORKFLOW

## 6.1 Branch Naming

```
feature/{shortcut-id}-{slug}    - New features
fix/{shortcut-id}-{slug}        - Bug fixes
refactor/{shortcut-id}-{slug}   - Code refactoring
docs/{slug}                     - Documentation
```

## 6.2 Commit Messages

```
feat: Add conversation monitoring system
fix: Resolve approval card risk score rounding
refactor: Abstract Chakra UI components
docs: Update API documentation
test: Add tests for campaign creation
chore: Update dependencies
```

## 6.3 Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Checklist
- [ ] Read ENGARDE_DEVELOPMENT_RULES.md
- [ ] Followed frontend style guide (if frontend)
- [ ] Followed backend patterns (if backend)
- [ ] Used UI component abstractions (no direct Chakra imports)
- [ ] Included tenant_id in queries
- [ ] Added/updated tests
- [ ] Tests passing locally
- [ ] Ran linter and type checker
- [ ] SOC II compliance verified
- [ ] No PII in logs or code
- [ ] Security considerations addressed

## Test Plan
Commands run and results

## Screenshots (if UI changes)
Attach screenshots

## Risk & Rollback
Potential risks and rollback plan
```

---

# PART 7: ENFORCEMENT & VERIFICATION

## 7.1 Automated Checks

### Frontend
- ESLint rules prevent direct Chakra imports
- TypeScript compiler catches type errors
- Pre-commit hooks run linter and tests

### Backend
- mypy for type checking
- pytest for tests
- Black for code formatting
- flake8 for linting

## 7.2 Code Review Checklist

**Reviewers MUST verify:**

- [ ] Follows ENGARDE_DEVELOPMENT_RULES.md
- [ ] No hardcoded colors or pixel values (frontend)
- [ ] UI component abstractions used (frontend)
- [ ] Responsive design implemented (frontend)
- [ ] Tenant isolation enforced (backend)
- [ ] Audit logging present (backend)
- [ ] PII protection implemented
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No security vulnerabilities
- [ ] SOC II compliance maintained

---

# PART 8: QUICK REFERENCE

## Frontend Anti-Patterns

```typescript
// ❌ WRONG
import { Button } from '@chakra-ui/react'
<Box bg="#3182CE" padding="16px">
await apiClient.get('/campaigns') // Missing tenant_id

// ✅ CORRECT
import { Button } from '@/components/ui/button'
<Box bg="blue.500" p={4}>
await apiClient.get(`/campaigns?tenant_id=${tenantId}`)
```

## Backend Anti-Patterns

```python
# ❌ WRONG
@router.get("/campaigns")
async def list_campaigns(db: Session = Depends(get_db)):
    return db.query(Campaign).all()  # No tenant isolation!

# ✅ CORRECT
@router.get("/campaigns")
async def list_campaigns(
    tenant_id: str = Query(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.tenant_id != tenant_id:
        raise HTTPException(status_code=403)

    return db.query(Campaign).filter(
        Campaign.tenant_id == tenant_id
    ).all()
```

---

## Resources

**Frontend:**
- `/production-frontend/FRONTEND_STYLE_GUIDE.md` - Complete UI guide
- `/production-frontend/DATA_RETRIEVAL_RULES.md` - Data patterns
- `/production-frontend/.ai-rules.md` - AI agent rules

**Backend:**
- `/production-backend/.claude/rules.md` - TDD/BDD workflow
- `/production-backend/integrationpartners.md` - Third-party APIs
- `/production-backend/docs/` - Additional documentation

**This Document:**
- `/ENGARDE_DEVELOPMENT_RULES.md` - **YOU ARE HERE**

---

## Questions?

1. Check this document first
2. Search existing code for examples
3. Review referenced documentation
4. Ask in team chat

**Remember: Consistency > Cleverness. Follow established patterns.**

---

# PART 9: NO HARDCODED STUB DATA

## 🚨 CRITICAL RULE: PRODUCTION-READY DATA ONLY

### The Problem

Hardcoded stub data creates a false sense of completeness. Pages appear to work in development but display fake data in production, misleading users and undermining trust in the platform.

**NEVER create pages or components with hardcoded stub data.**

---

## 9.1 Prohibited Patterns

### ❌ ABSOLUTELY FORBIDDEN

```typescript
// ❌ WRONG - Hardcoded user data
const sampleUsers = [
  { id: '1', name: 'Sarah Chen', email: 'sarah.chen@company.com' },
  { id: '2', name: 'Mike Johnson', email: 'mike.johnson@company.com' },
];

// ❌ WRONG - Hardcoded billing data
const billingHistory = [
  { date: '2024-01-01', amount: '$99.00', status: 'Paid' },
  { date: '2024-02-01', amount: '$99.00', status: 'Paid' },
];

// ❌ WRONG - Hardcoded company info
const profileData = {
  firstName: "John",
  lastName: "Doe",
  company: "Acme Corp",
  phone: "+1 (555) 123-4567"
};
```

### ✅ CORRECT PATTERNS

```typescript
// ✅ CORRECT - Fetch from API
const { data: users = [], isLoading } = useQuery({
  queryKey: ['users'],
  queryFn: async () => {
    const response = await apiClient.get('/workspaces/current/members');
    return response.data;
  },
});

// ✅ CORRECT - Show loading state
{isLoading ? (
  <Spinner />
) : users.length === 0 ? (
  <Text>No users found</Text>
) : (
  users.map(user => <UserCard key={user.id} user={user} />)
)}
```

---

## 9.2 Three-Confirmation Process

Before creating ANY new page or component that displays data, you MUST confirm three things:

### ✅ CONFIRMATION #1: Does this data exist in the database?

**YES** → Use the existing API endpoint
**NO** → Proceed to Confirmation #2

### ✅ CONFIRMATION #2: Does an API endpoint exist to fetch this data?

**YES** → Use it
**NO** → Proceed to Confirmation #3

### ✅ CONFIRMATION #3: Should demo data be generated for this feature?

**YES** → Create/update demo data generation script FIRST, then build UI
**NO** → Build UI with proper empty states

---

## 9.3 Demo Data Management

### Rule: Whitelist Demo Users ONLY

```python
# ✅ CORRECT - Explicit whitelist
DEMO_USER_EMAILS = [
    'demo@engarde.com',
    'test@engarde.com',
    'admin@engarde.com',
    # Add new demo emails explicitly
]

users = db.query(User).filter(
    User.email.in_(DEMO_USER_EMAILS)
).all()

# ❌ WRONG - Affects ALL non-admin users (including real customers!)
users = db.query(User).filter(User.is_superuser == False).all()
```

### Rule: Demo Data Scripts in `/scripts/`

```python
#!/usr/bin/env python3
"""
Generate Demo User Preferences
================================
Updates ui_preferences for ONLY whitelisted demo users.

IMPORTANT: Never apply to all users - only explicit whitelist!
"""

DEMO_USER_EMAILS = [
    'demo@engarde.com',
    'test@engarde.com',
]

def generate_demo_data():
    """Generate realistic demo data for whitelisted users only"""
    db = SessionLocal()

    users = db.query(User).filter(
        User.email.in_(DEMO_USER_EMAILS)
    ).all()

    for user in users:
        # Generate realistic preferences
        preferences = {
            "phone": generate_phone_number(),
            "timezone": random.choice(TIMEZONES),
            "company": {
                "name": f"{user.first_name}'s Marketing Co.",
                "industry": random.choice(INDUSTRIES),
            }
        }

        # Update user preferences
        from sqlalchemy import text
        db.execute(
            text("UPDATE users SET ui_preferences = :prefs WHERE id = :user_id"),
            {"prefs": json.dumps(preferences), "user_id": user.id}
        )

    db.commit()
```

---

## 9.4 API-First Development Checklist

### Every Page MUST:

- [ ] **Identify data requirements** - What data does this page need?
- [ ] **Find or create API endpoint** - Does `/api/{resource}` exist?
- [ ] **Use React Query/TanStack Query** - For data fetching
- [ ] **Handle loading states** - Show spinners during fetch
- [ ] **Handle empty states** - Show helpful messages when no data
- [ ] **Handle error states** - Show user-friendly error messages

### Example Implementation

```typescript
export default function TeamPage() {
  const { data: members = [], isLoading, error } = useQuery({
    queryKey: ['team-members'],
    queryFn: async () => {
      const response = await apiClient.get('/workspaces/current/members');
      return response.data;
    },
  });

  if (isLoading) {
    return <Spinner />;
  }

  if (error) {
    return <ErrorMessage error={error} />;
  }

  if (members.length === 0) {
    return <EmptyState message="No team members yet" />;
  }

  return (
    <Table>
      {members.map(member => (
        <TeamMemberRow key={member.id} member={member} />
      ))}
    </Table>
  );
}
```

---

## 9.5 Code Review Enforcement

### Reviewers MUST reject PRs that contain:

- [ ] Hardcoded user names, emails, or personal data
- [ ] Hardcoded company names or business data
- [ ] Sample billing history or payment methods
- [ ] Fake analytics or metrics
- [ ] Any placeholder content meant to simulate real data

### Before Merging ANY PR:

- [ ] No hardcoded stub data
- [ ] All data fetched from API endpoints
- [ ] Loading states implemented
- [ ] Empty states implemented
- [ ] Error states implemented
- [ ] Demo data scripts (if needed) whitelist specific users only
- [ ] TypeScript types defined for API responses

---

## 9.6 Why This Rule Exists

### Production Incidents Prevented:

1. **Settings page showing "No Plan"** - Hardcoded billing data didn't reflect real subscription
2. **Fake user names in production** - Demo users saw "Sarah Chen" instead of their actual name
3. **Incorrect company information** - Users saw "Acme Corp" instead of their company
4. **Misleading analytics** - Hardcoded metrics gave false performance indicators

### The Standard:

**If data doesn't exist → Show empty state**
**If data exists → Fetch from API**
**If demo needed → Generate ONLY for whitelisted demo accounts**

---

## 9.7 Acceptable Use of Sample Data

### ✅ ONLY Acceptable in:

1. **Unit tests** - Mock data for testing components
2. **Storybook stories** - Visual component documentation
3. **Type definitions** - Example types in comments
4. **Documentation** - Code examples in markdown files

### Example: Testing with Mock Data

```typescript
// ✅ CORRECT - Mock data in test file
describe('UserCard', () => {
  const mockUser = {
    id: '1',
    name: 'Test User',
    email: 'test@example.com',
  };

  it('renders user information', () => {
    render(<UserCard user={mockUser} />);
    expect(screen.getByText('Test User')).toBeInTheDocument();
  });
});
```

---

## 9.8 Emergency Exceptions

If you absolutely MUST use temporary stub data (emergency demo, time-sensitive prototype):

1. **Add prominent comment**: `// TODO: REMOVE STUB DATA - Replace with API call`
2. **Create immediate follow-up ticket**: Track removal in issue tracker
3. **Set deadline**: No more than 48 hours before removal
4. **Get approval**: Team lead must approve temporary stub data

```typescript
// TODO: REMOVE STUB DATA - Replace with /api/campaigns endpoint
// Ticket: ENG-123 | Deadline: 2026-01-28
// Approved by: @tech-lead
const TEMP_STUB_DATA = [...];
```

---

**Remember: Hardcoded stub data is NEVER acceptable in production code. When in doubt, build the API first, then the UI.**

---

**End of EnGarde Development Rules v2.0.0**
