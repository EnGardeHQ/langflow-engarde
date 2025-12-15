# Users, Brands, and Tenants: Complete Relationship Guide

## Quick Answer: How Are They Related?

**The 11 agents are associated with the Tenant (`default-tenant-001`), not a specific brand.** All brands within that tenant share access to the same 11 agents.

## Architecture Overview

EnGarde uses a **three-tier hierarchy**:

```
Organization (optional)
    └── Tenant (data isolation boundary)
        └── Brand (user-facing organizational unit)
            └── User (individual accounts)
```

## Core Concepts

### 1. **Tenant** (Data Isolation Boundary)
- **Purpose**: PostgreSQL Row-Level Security (RLS) boundary
- **Scope**: All data within a tenant is isolated from other tenants
- **Relationship**: One tenant can have multiple brands
- **Example**: "EnGarde Media" tenant contains 3 brands

### 2. **Brand** (User-Facing Organization)
- **Purpose**: The primary organizational unit users interact with
- **Scope**: Each brand has its own identity, settings, and some brand-specific resources
- **Relationship**: Belongs to one tenant, can have multiple users
- **Example**: "Demo Brand", "Demo E-commerce", "EnGarde Platform"

### 3. **User** (Individual Account)
- **Purpose**: Individual user accounts that can access multiple tenants and brands
- **Scope**: Users can belong to multiple tenants and multiple brands
- **Relationship**: Many-to-many with tenants (via `TenantUser`) and brands (via `BrandMember`)
- **Example**: `demo@engarde.com` belongs to 1 tenant and 2 brands

## Relationship Tables

### TenantUser (User ↔ Tenant)
- **Purpose**: Controls which tenants a user can access
- **Fields**: `user_id`, `tenant_id`, `role_id`, `permissions`
- **Cardinality**: Many-to-Many
- **Example**: User can be member of multiple tenants (e.g., agency tenant + client tenant)

### BrandMember (User ↔ Brand)
- **Purpose**: Controls which brands within a tenant a user can access
- **Fields**: `user_id`, `brand_id`, `tenant_id`, `role` (owner/admin/member/viewer)
- **Cardinality**: Many-to-Many
- **Example**: User can be owner of "Demo Brand" and member of "Demo E-commerce"

### UserActiveBrand (User → Active Brand)
- **Purpose**: Tracks which brand is currently selected in the UI dropdown
- **Fields**: `user_id` (unique), `brand_id`, `tenant_id`, `recent_brand_ids`
- **Cardinality**: One-to-One (each user has one active brand)
- **Example**: User's active brand determines which tenant context is used for RLS

## Data Scoping Strategy

### Tenant-Scoped Resources (Shared Across All Brands)
These resources belong to the tenant and are **shared** by all brands within that tenant:

| Resource | Table | Foreign Key | Why Shared? |
|----------|-------|-------------|--------------|
| AI Agents | `ai_agents` | `tenant_id` | Agents are workflow execution capabilities, shared across brands |
| Workflows | `workflow_definitions` | `tenant_id` | Workflow templates are reusable across brands |
| AI Executions | `ai_executions` | `tenant_id` | Execution history is tenant-wide |
| Data Sources | `data_sources` | `tenant_id` | Data connections are tenant-level |
| Audit Logs | `audit_logs` | `tenant_id` | System-wide audit trail |

**Example**: The 11 agents belong to `default-tenant-001` and are visible to all 3 brands in that tenant.

### Brand-Scoped Resources (Brand-Specific)
These resources belong to a specific brand:

| Resource | Table | Foreign Keys | Why Brand-Specific? |
|----------|-------|--------------|---------------------|
| Campaigns | `campaigns` | `tenant_id` + `brand_id` | Marketing campaigns are brand-specific |
| Brand Members | `brand_members` | `brand_id` + `user_id` + `tenant_id` | Team memberships are brand-specific |
| Brand Invitations | `brand_invitations` | `brand_id` + `tenant_id` | Invitations are brand-specific |

**Example**: Campaigns are brand-specific - "Demo Brand" has 66 campaigns, "Demo E-commerce" has 64 campaigns.

### User-Scoped Resources (Personal)
These resources belong to individual users:

| Resource | Table | Foreign Key | Why User-Specific? |
|----------|-------|-------------|-------------------|
| Password Reset Tokens | `password_reset_tokens` | `user_id` | Personal security tokens |
| Refresh Tokens | `refresh_tokens` | `user_id` | Personal session tokens |
| Security Settings | `user_security_settings` | `user_id` | Personal preferences |

## How It Works: Demo User Example

Based on actual database data:

```
User: demo@engarde.com
│
├── Tenant Membership (TenantUser)
│   └── EnGarde Media (default-tenant-001)
│
├── Brand Memberships (BrandMember)
│   ├── Demo Brand (owner) → tenant: default-tenant-001
│   └── Demo E-commerce (owner) → tenant: default-tenant-001
│
├── Active Brand (UserActiveBrand)
│   └── Demo Brand → tenant: default-tenant-001
│
└── Tenant Resources (default-tenant-001)
    │
    ├── Tenant-Scoped (Shared):
    │   ├── 11 AI Agents ← Visible to all 3 brands
    │   ├── 11 Workflows ← Visible to all 3 brands
    │   └── Data Sources ← Shared across brands
    │
    └── Brand-Scoped (Separate):
        ├── Demo Brand: 66 campaigns
        ├── Demo E-commerce: 64 campaigns
        └── EnGarde Platform: 66 campaigns
```

## RLS (Row-Level Security) Flow

When a user makes an API request:

1. **Authentication**: User is authenticated, `user_id` is known
2. **Get Active Brand**: Query `user_active_brands` for user's `brand_id`
3. **Get Tenant ID**: Query `brands` table to get `tenant_id` from active brand
4. **Set RLS Context**: Set PostgreSQL session variables:
   ```sql
   SET app.current_tenant_id = 'default-tenant-001';
   SET app.current_user_id = 'eebb36a4-b599-4dcf-8ca2-a8fd06e16912';
   ```
5. **Query Resources**: RLS policies automatically filter by `tenant_id`
6. **Filter by Brand** (if needed): Application code filters brand-specific resources by `brand_id`

## Why Agents Are Tenant-Scoped

**Question**: Why aren't agents brand-specific?

**Answer**: 
- Agents represent **workflow execution capabilities** (like "Content Generation Agent")
- These capabilities are **reusable** across all brands in a tenant
- When a user switches brands, they should still have access to the same agents
- The **workflows** executed by agents can be brand-specific, but the **agent itself** is shared

**Analogy**: Think of agents as "tools" and brands as "workspaces". All workspaces in the same office (tenant) share the same toolset (agents), but each workspace has its own projects (campaigns/workflows).

## Key Design Decisions

### 1. Why Both TenantUser and BrandMember?
- **TenantUser**: "Can this user access this tenant?" (tenant-level access control)
- **BrandMember**: "Which brands can this user access within the tenant?" (brand-level access control)
- A user must be a TenantUser to access a tenant, then BrandMember to access specific brands

### 2. Why UserActiveBrand?
- Tracks the currently selected brand in the UI dropdown
- Used by `get_tenant_id_from_current_brand()` to determine tenant context
- Enables RLS policies to filter data based on active brand's tenant_id
- Stores switching history for UX improvements

### 3. Why Tenant-Scoped Agents?
- Agents are workflow execution engines, not brand-specific content
- Allows brand switching without losing access to agents
- Workflows executed by agents can be brand-specific, but agents themselves are shared
- Simplifies agent management (one pool per tenant vs. one pool per brand)

## Summary

- **Tenants** = Data isolation boundaries (RLS scope)
- **Brands** = User-facing organizational units within a tenant
- **Users** = Individual accounts that can access multiple tenants and brands
- **Agents** = Tenant-scoped workflow execution capabilities (shared across brands)
- **Campaigns** = Brand-scoped marketing activities (brand-specific)

The 11 agents belong to the **tenant** (`default-tenant-001`), which means all 3 brands in that tenant share access to the same 11 agents. This is by design - agents are reusable capabilities, not brand-specific resources.
