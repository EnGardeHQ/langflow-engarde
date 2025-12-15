# Database Relationships: Users, Brands, and Tenants

## Overview

The EnGarde platform uses a multi-tenant, multi-brand architecture where:
- **Organizations** are the top-level entity (e.g., agencies)
- **Tenants** represent isolated data partitions (RLS boundaries)
- **Brands** are business units within a tenant
- **Users** can belong to multiple tenants and brands

## Core Entity Relationships

### 1. Organization → Tenant (One-to-Many)
- An **Organization** can have multiple **Tenants**
- Organizations support hierarchical relationships (parent-child)
- Tenants can optionally belong to an Organization (for backward compatibility)
- **Purpose**: Agency → Client relationships, enterprise multi-tenant management

### 2. Tenant → Brand (One-to-Many)
- A **Tenant** can have multiple **Brands**
- Each Brand belongs to exactly one Tenant
- Brands share the same tenant_id (data isolation boundary)
- **Purpose**: Allow users to manage multiple brands/companies within the same tenant

### 3. User → Tenant (Many-to-Many via TenantUser)
- A **User** can belong to multiple **Tenants**
- A **Tenant** can have multiple **Users**
- Junction table: `tenant_users` with role-based permissions
- **Purpose**: Support users working across different organizations/tenants

### 4. User → Brand (Many-to-Many via BrandMember)
- A **User** can belong to multiple **Brands**
- A **Brand** can have multiple **Users**
- Junction table: `brand_members` with role-based access (owner, admin, member, viewer)
- **Purpose**: Team collaboration within brands

### 5. User → Active Brand (One-to-One via UserActiveBrand)
- Each **User** has one currently active **Brand**
- Tracks brand switching history (last 5 brands)
- **Purpose**: Enable seamless brand switching in the UI

## Data Isolation Strategy

### Tenant-Level Isolation (RLS Boundary)
Most resources are **tenant-scoped** and share data across all brands within a tenant:
- `ai_agents` - AI agents (tenant_id only)
- `workflow_definitions` - Workflow templates (tenant_id only)
- `ai_executions` - Agent execution history (tenant_id only)
- `cultural_contexts` - Cultural context data (tenant_id only)
- `data_sources` - Data source connections (tenant_id only)
- `audit_logs` - System audit logs (tenant_id only)
- `user_sessions` - Active user sessions (tenant_id only)

### Brand-Level Isolation
Some resources are **brand-scoped** for brand-specific operations:
- `campaigns` - Marketing campaigns (tenant_id + brand_id)
- `brand_members` - Brand team memberships (brand_id + user_id + tenant_id)
- `brand_invitations` - Brand invitation system (brand_id + tenant_id)
- `brand_onboarding` - Brand onboarding progress (brand_id + tenant_id)

### User-Level Resources
Some resources are **user-scoped**:
- `users` - User accounts (no tenant_id, linked via relationships)
- `password_reset_tokens` - Password reset tokens (user_id only)
- `refresh_tokens` - JWT refresh tokens (user_id only)
- `user_security_settings` - Security preferences (user_id only)

## Key Design Decisions

### 1. Why Tenant-Scoped Agents?
- **Agents** are tenant-scoped because they represent workflow execution capabilities
- All brands within a tenant share the same agent pool
- This allows brand switching without losing access to agents
- Agents execute workflows that may be brand-specific, but the agent itself is shared

### 2. Why Brand-Scoped Campaigns?
- **Campaigns** are brand-scoped because they represent brand-specific marketing activities
- Each brand has its own campaigns
- Campaigns reference brand_id for brand-specific targeting and content

### 3. Why Both TenantUser and BrandMember?
- **TenantUser**: Controls tenant-level access (can user access this tenant?)
- **BrandMember**: Controls brand-level access within a tenant (which brands can user access?)
- A user must be a TenantUser to access a tenant, then BrandMember to access specific brands

### 4. Why UserActiveBrand?
- Tracks the currently selected brand in the UI dropdown
- Used by `get_tenant_id_from_current_brand()` to determine tenant context
- Enables RLS policies to filter data based on active brand's tenant_id

## RLS (Row-Level Security) Implementation

PostgreSQL RLS policies use session variables set by the application:
- `app.current_tenant_id` - Set from active brand's tenant_id
- `app.current_user_id` - Set from authenticated user's id

These variables are set automatically via SQLAlchemy event listeners before each query.

## Example Data Flow

1. **User logs in** → Authenticated user retrieved
2. **Get active brand** → Query `user_active_brands` for user's active brand_id
3. **Get brand's tenant_id** → Query `brands` table for tenant_id
4. **Set RLS context** → Set `app.current_tenant_id` and `app.current_user_id` session variables
5. **Query resources** → RLS policies automatically filter by tenant_id
6. **Brand switching** → Update `user_active_brands.brand_id`, repeat from step 2

## Relationship Cardinality Summary

```
Organization (1) ──< (0..*) Tenant
Tenant (1) ──< (0..*) Brand
Tenant (1) ──< (0..*) TenantUser >── (0..*) User
Brand (1) ──< (0..*) BrandMember >── (0..*) User
User (1) ──< (1) UserActiveBrand >── (0..1) Brand
```

## Foreign Key Patterns

### Tenant-Scoped Tables
- `tenant_id` (required, indexed)
- Examples: `ai_agents`, `workflow_definitions`, `ai_executions`

### Brand-Scoped Tables
- `tenant_id` (required, indexed) + `brand_id` (nullable, indexed)
- Examples: `campaigns`, `brand_members`

### User-Scoped Tables
- `user_id` (required, indexed)
- Examples: `password_reset_tokens`, `refresh_tokens`

### Junction Tables
- Multiple foreign keys: `tenant_id`, `user_id`, `brand_id` (as needed)
- Examples: `tenant_users`, `brand_members`, `user_active_brands`
