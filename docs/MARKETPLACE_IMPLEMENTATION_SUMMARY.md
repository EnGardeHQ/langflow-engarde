# Marketplace Functionality Implementation Summary

## Overview

Marketplace functionality has been implemented to allow users to publish their agents to the marketplace and install agents from other users' brands. Agents can be associated with another user's brand through the marketplace installation process.

## Implementation Complete ✅

### 1. Database Schema Changes

**AIAgent Model** (`production-backend/app/models/core.py`):
- Added `source_marketplace_agent_id` - Links to MarketplaceAgent
- Added `is_marketplace_agent` - Boolean flag
- Added `purchased_via_purchase_id` - Links to AgentPurchase record
- Added `original_tenant_id` - Publisher's tenant ID
- Added `original_creator_user_id` - Publisher's user ID

**MarketplaceAgent Model** (`production-backend/app/models/core.py`):
- Added `source_agent_id` - Links to original AIAgent
- Added `source_tenant_id` - Publisher's tenant ID
- Added `created_by_user_id` - Publisher's user ID

### 2. Database Migration

**Migration Script**: `production-backend/scripts/migrations/add_marketplace_fields_to_agents.py`
- Adds all marketplace fields to both tables
- Creates foreign key constraints
- Creates indexes for performance
- Idempotent (can be run multiple times safely)

**To Run Migration**:
```bash
cd production-backend
python scripts/migrations/add_marketplace_fields_to_agents.py
```

### 3. API Endpoints

#### Publish Agent to Marketplace
**Endpoint**: `POST /api/agents/{agent_id}/publish-to-marketplace`

**Request Body**:
```json
{
  "price_type": "free" | "one_time" | "credits_per_use",
  "price_amount": 0.0,
  "credits_per_execution": 0,
  "is_public": true,
  "publisher_name": "Optional Publisher Name",
  "publisher_contact": "contact@example.com",
  "support_url": "https://support.example.com",
  "documentation_url": "https://docs.example.com"
}
```

**Response**:
```json
{
  "status": "published",
  "marketplace_agent_id": "uuid",
  "agent_id": "uuid",
  "message": "Agent published to marketplace. Pending review before going live."
}
```

**Features**:
- Creates MarketplaceAgent listing linked to source AIAgent
- Sets status to "pending_review" (requires admin approval)
- Validates agent has Langflow workflow ID
- Prevents duplicate publishing

#### Install Marketplace Agent
**Endpoint**: `POST /api/agents/marketplace/{marketplace_agent_id}/install`

**Response**:
```json
{
  "status": "installed",
  "agent_id": "uuid",
  "marketplace_agent_id": "uuid",
  "purchase_id": "uuid",
  "message": "Agent installed successfully"
}
```

**Features**:
- Creates AIAgent instance in purchaser's tenant
- Creates AgentPurchase record
- Handles free, one-time, and credit-based pricing
- Links installed agent to marketplace listing
- Tracks original publisher information
- Increments download count

#### Get Marketplace Agents
**Endpoint**: `GET /api/agents/marketplace`

**Query Parameters**:
- `category` - Filter by category
- `featured` - Filter featured agents
- `sort_by` - Sort by: popularity, rating, newest
- `page` - Page number
- `page_size` - Page size

**Features**:
- Returns only approved, public agents
- Includes ratings and install counts
- Supports filtering and sorting
- Pagination support

### 4. Agent Execution with Marketplace Billing

**Endpoint**: `POST /api/agents/{agent_id}/execute`

**Marketplace Billing Logic**:
1. Checks if agent is marketplace-installed (`is_marketplace_agent`)
2. Validates purchase record is active
3. Checks license expiration
4. Checks usage limits
5. For credit-based agents:
   - Gets or creates CreditWallet
   - Validates sufficient credits
   - Deducts credits per execution
   - Tracks spending
6. Increments usage count
7. Updates agent execution metrics

**Error Handling**:
- `403` - License expired or usage limit reached
- `402` - Insufficient credits
- `404` - Agent or purchase record not found

### 5. Installed Agents Endpoint

**Endpoint**: `GET /api/agents/installed`

**Features**:
- Returns all agents for tenant (local + marketplace-installed)
- Marketplace-installed agents are automatically included
- No changes needed - endpoint already queries all AIAgents for tenant

## How It Works: Agent Association Across Brands

### Publishing Flow
```
User A (Publisher)
├── Creates AIAgent in their tenant
├── Publishes to marketplace
│   └── Creates MarketplaceAgent listing
│       └── Links to source AIAgent
└── Agent status: "pending_review" → "approved"
```

### Installation Flow
```
User B (Purchaser)
├── Browses marketplace
├── Finds agent from User A
├── Clicks "Install"
│   └── POST /api/agents/marketplace/{id}/install
│       ├── Creates AgentPurchase record
│       ├── Creates AIAgent instance in User B's tenant
│       │   ├── tenant_id = User B's tenant ✅
│       │   ├── source_marketplace_agent_id = MarketplaceAgent.id
│       │   ├── original_tenant_id = User A's tenant
│       │   └── original_creator_user_id = User A's user ID
│       └── Links purchase to installed agent
└── Agent appears in User B's "/api/agents/installed"
```

### Execution Flow
```
User B executes marketplace-installed agent
├── System checks purchase record
├── Validates license & usage limits
├── Deducts credits (if credit-based)
├── Increments usage count
└── Executes Langflow workflow
```

## Key Design Decisions

### 1. Tenant-Scoped Agents (Not Brand-Specific)
- Marketplace-installed agents are **tenant-scoped**
- Available to **all brands** within the purchasing tenant
- Matches current AIAgent design (tenant-scoped)
- Simpler implementation and management

### 2. Agent Instance Creation
- Each installation creates a **new AIAgent instance**
- Allows customization per tenant
- Tracks original publisher for attribution
- Enables per-tenant usage tracking

### 3. Purchase Record Tracking
- `AgentPurchase` links marketplace listing to installed agent
- Tracks license type, usage limits, billing
- Supports free, one-time, and credit-based pricing
- Enables usage analytics and billing

### 4. Credit Wallet System
- Automatic wallet creation if needed
- Credit deduction per execution for credit-based agents
- Balance tracking and spending history
- Supports marketplace transactions

## Testing Checklist

- [ ] Run database migration
- [ ] Publish an agent to marketplace
- [ ] Verify marketplace listing appears
- [ ] Install marketplace agent in different tenant
- [ ] Verify agent appears in installed agents list
- [ ] Execute marketplace-installed agent
- [ ] Verify credit deduction (for credit-based agents)
- [ ] Verify usage tracking
- [ ] Test license expiration handling
- [ ] Test usage limit enforcement

## Next Steps (Optional Enhancements)

1. **Admin Approval System**: Create endpoint to approve/reject marketplace submissions
2. **Brand-Scoped Installation**: Add option to install agents for specific brands only
3. **Agent Versioning**: Support multiple versions of marketplace agents
4. **Reviews & Ratings**: Implement review system for marketplace agents
5. **Revenue Sharing**: Track and distribute revenue to publishers
6. **Agent Updates**: Notify purchasers when marketplace agents are updated

## Files Modified

1. `production-backend/app/models/core.py` - Added marketplace fields
2. `production-backend/app/routers/agents_api.py` - Added endpoints and billing logic
3. `production-backend/scripts/migrations/add_marketplace_fields_to_agents.py` - Migration script

## Answer to Original Question

**Q: Can an agent be associated with another user's brand if listed in the marketplace?**

**A: YES** - After implementation:
- Agents can be published to marketplace by their creator
- Other users can install marketplace agents into their tenant
- Installed agents are **tenant-scoped** (available to all brands in the tenant)
- Each installation creates a new AIAgent instance in the purchaser's tenant
- The agent is linked back to the original publisher via `original_tenant_id` and `original_creator_user_id`
- Usage is tracked per tenant via `AgentPurchase` records

The agent is **not brand-specific** - it's tenant-scoped, meaning all brands within the purchasing tenant share access to the installed agent, just like locally-created agents.
