# Database Relationship Diagram

## Entity Relationship Diagram (ERD)

```mermaid
erDiagram
    %% Top-level Organization
    Organization ||--o{ Tenant : "has"
    Organization ||--o{ OrganizationMember : "has"
    Organization ||--o| Organization : "parent_of"
    
    %% Tenant Relationships
    Tenant ||--o{ Brand : "has"
    Tenant ||--o{ TenantUser : "has"
    Tenant ||--o{ TenantRole : "has"
    Tenant ||--o{ AIAgent : "has"
    Tenant ||--o{ WorkflowDefinition : "has"
    Tenant ||--o{ Campaign : "has"
    Tenant ||--o{ AIExecution : "has"
    Tenant ||--o{ DataSource : "has"
    Tenant ||--o{ AuditLog : "has"
    Tenant ||--o{ UserSession : "has"
    Tenant ||--o{ BrandMember : "has"
    Tenant ||--o{ BrandInvitation : "has"
    Tenant ||--o{ BrandOnboarding : "has"
    Tenant ||--o{ UserActiveBrand : "has"
    
    %% User Relationships
    User ||--o{ TenantUser : "belongs_to"
    User ||--o{ BrandMember : "belongs_to"
    User ||--|| UserActiveBrand : "has_active"
    User ||--o{ PasswordResetToken : "has"
    User ||--o{ RefreshToken : "has"
    User ||--o{ EmailVerificationToken : "has"
    User ||--o{ SecurityAuditLog : "has"
    User ||--o{ AccountLockout : "has"
    User ||--|| UserSecuritySettings : "has"
    
    %% Brand Relationships
    Brand ||--o{ BrandMember : "has"
    Brand ||--o{ BrandInvitation : "has"
    Brand ||--|| BrandOnboarding : "has"
    Brand ||--o{ Campaign : "has"
    Brand ||--o{ UserActiveBrand : "active_for"
    
    %% Junction Tables
    TenantUser }o--|| Tenant : "references"
    TenantUser }o--|| User : "references"
    TenantUser }o--o| TenantRole : "has"
    
    BrandMember }o--|| Brand : "references"
    BrandMember }o--|| User : "references"
    BrandMember }o--|| Tenant : "references"
    
    UserActiveBrand }o--|| User : "references"
    UserActiveBrand }o--o| Brand : "references"
    UserActiveBrand }o--|| Tenant : "references"
    
    OrganizationMember }o--|| Organization : "references"
    OrganizationMember }o--|| User : "references"
    
    %% Resource Tables
    AIAgent }o--|| Tenant : "belongs_to"
    WorkflowDefinition }o--|| Tenant : "belongs_to"
    Campaign }o--|| Tenant : "belongs_to"
    Campaign }o--o| Brand : "belongs_to"
    AIExecution }o--|| Tenant : "belongs_to"
    DataSource }o--|| Tenant : "belongs_to"
    AuditLog }o--|| Tenant : "belongs_to"
    AuditLog }o--o| User : "created_by"
    UserSession }o--|| Tenant : "belongs_to"
    UserSession }o--|| User : "belongs_to"
    
    %% Entity Definitions
    Organization {
        string id PK
        string name
        string slug UK
        string org_type
        string parent_org_id FK
        json settings
    }
    
    Tenant {
        string id PK
        string organization_id FK "nullable"
        string name
        string slug UK
        string plan_tier
        json settings
    }
    
    User {
        string id PK
        string email UK
        string hashed_password
        string first_name
        string last_name
        string user_type
        boolean is_active
        boolean is_superuser
    }
    
    Brand {
        string id PK
        string tenant_id FK
        string name
        string slug UK "nullable"
        string description
        string logo_url
        boolean is_active
        string plan_tier
    }
    
    TenantUser {
        string id PK
        string tenant_id FK
        string user_id FK
        string role_id FK "nullable"
        json permissions
    }
    
    BrandMember {
        string id PK
        string brand_id FK
        string user_id FK
        string tenant_id FK
        enum role
        boolean is_active
    }
    
    UserActiveBrand {
        string id PK
        string user_id FK UK
        string brand_id FK "nullable"
        string tenant_id FK
        json recent_brand_ids
    }
    
    AIAgent {
        string id PK
        string tenant_id FK
        string name
        string agent_type
        string status
        string langflow_workflow_id
    }
    
    Campaign {
        string id PK
        string tenant_id FK
        string brand_id FK "nullable"
        string name
        json nodes
        json edges
    }
    
    WorkflowDefinition {
        string id PK
        string tenant_id FK
        string name
        string category
        json workflow_data
    }
```

## Relationship Cardinality Legend

- `||--o{` : One-to-Many (one required, many optional)
- `}o--||` : Many-to-One (many optional, one required)
- `||--||` : One-to-One (both required)
- `}o--o{` : Many-to-Many (both optional)
- `}o--o|` : Many-to-One (many optional, one optional)

## Key Relationships Explained

### 1. Organization → Tenant → Brand Hierarchy
```
Organization (1) ──< (0..*) Tenant (1) ──< (0..*) Brand
```
- Organizations can have multiple tenants (e.g., agency → clients)
- Each tenant can have multiple brands
- Brands are the primary organizational unit users interact with

### 2. User Access Pattern
```
User (1) ──< (0..*) TenantUser >── (0..*) Tenant
User (1) ──< (0..*) BrandMember >── (0..*) Brand
User (1) ──< (1) UserActiveBrand >── (0..1) Brand
```
- Users must be TenantUsers to access a tenant
- Users must be BrandMembers to access specific brands within a tenant
- Each user has one active brand at a time

### 3. Data Scoping Strategy

#### Tenant-Scoped (Shared Across Brands)
- `ai_agents` - All brands in tenant share same agents
- `workflow_definitions` - Workflow templates shared
- `ai_executions` - Execution history shared
- `data_sources` - Data connections shared

#### Brand-Scoped (Brand-Specific)
- `campaigns` - Each brand has its own campaigns
- `brand_members` - Brand team memberships
- `brand_invitations` - Brand invitation system

#### User-Scoped (Personal)
- `password_reset_tokens` - User-specific tokens
- `refresh_tokens` - User session tokens
- `user_security_settings` - User preferences

## Data Flow Example: Demo User

Based on actual database query:

```
User: demo@engarde.com
├── Tenant Membership: EnGarde Media (default-tenant-001)
├── Brand Memberships:
│   ├── Demo Brand (owner)
│   └── Demo E-commerce (owner)
├── Active Brand: Demo Brand
└── Tenant Resources:
    ├── 11 AI Agents (shared across all brands)
    ├── 11 Workflows (shared across all brands)
    └── 196 Campaigns (brand-specific):
        ├── Demo Brand: 66 campaigns
        ├── Demo E-commerce: 64 campaigns
        └── EnGarde Platform: 66 campaigns
```

## RLS (Row-Level Security) Context

When a user makes a request:
1. Get user's active brand from `user_active_brands`
2. Get brand's `tenant_id` from `brands` table
3. Set PostgreSQL session variables:
   - `app.current_tenant_id` = brand.tenant_id
   - `app.current_user_id` = user.id
4. RLS policies automatically filter queries by `tenant_id`
5. Application code filters brand-specific resources by `brand_id` when needed

## Foreign Key Patterns

### Pattern 1: Tenant-Scoped Resources
```sql
CREATE TABLE resource (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    -- other fields
);
CREATE INDEX idx_resource_tenant ON resource(tenant_id);
```

### Pattern 2: Brand-Scoped Resources
```sql
CREATE TABLE resource (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    brand_id UUID REFERENCES brands(id) ON DELETE CASCADE,
    -- other fields
);
CREATE INDEX idx_resource_tenant ON resource(tenant_id);
CREATE INDEX idx_resource_brand ON resource(brand_id);
```

### Pattern 3: Junction Tables
```sql
CREATE TABLE junction (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    brand_id UUID REFERENCES brands(id) ON DELETE CASCADE,
    -- other fields
    UNIQUE (brand_id, user_id) -- if applicable
);
CREATE INDEX idx_junction_tenant ON junction(tenant_id);
CREATE INDEX idx_junction_user ON junction(user_id);
CREATE INDEX idx_junction_brand ON junction(brand_id);
```
