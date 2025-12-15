# Marketplace Agent Flow: Current vs. Proposed

## Current State (Not Implemented)

```
┌─────────────────────────────────────────────────────────────────┐
│                    PUBLISHER'S TENANT                           │
│                                                                 │
│  ┌──────────────┐                                               │
│  │  AIAgent     │  (Created by User A)                         │
│  │              │                                               │
│  │  tenant_id   │  → Publisher's tenant                         │
│  │  name        │  → "Content Generator"                        │
│  │  workflow_id │  → langflow_workflow_123                     │
│  └──────────────┘                                               │
│         │                                                        │
│         │  ❌ NO LINK                                          │
│         │                                                        │
│         ▼                                                        │
│  ┌──────────────────────┐                                       │
│  │ MarketplaceAgent     │  (Separate entity)                   │
│  │                      │                                       │
│  │  tenant_id           │  → Publisher's tenant                 │
│  │  name                │  → "Content Generator"                │
│  │  langflow_workflow_id│  → langflow_workflow_123             │
│  │  price_type          │  → "credits_per_use"                  │
│  │  credits_per_exec    │  → 10                                 │
│  │  ❌ NO source_agent_id                                       │
│  └──────────────────────┘                                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ Published to Marketplace
                            │
                            ▼
                    ┌───────────────┐
                    │  MARKETPLACE  │
                    │   (Public)    │
                    └───────────────┘
                            │
                            │ User B browses & purchases
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PURCHASER'S TENANT                           │
│                                                                 │
│  ┌──────────────────────┐                                       │
│  │ AgentPurchase        │  (Purchase record)                    │
│  │                      │                                       │
│  │  tenant_id           │  → Purchaser's tenant                 │
│  │  agent_id            │  → marketplace_agents.id              │
│  │  purchase_type       │  → "credits"                          │
│  │  is_installed        │  → FALSE ❌                           │
│  │  ❌ NO installed_agent_id                                    │
│  └──────────────────────┘                                       │
│                                                                 │
│  ❌ NO AIAgent instance created                                 │
│  ❌ Agent cannot be used by Purchaser                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Proposed Implementation

```
┌─────────────────────────────────────────────────────────────────┐
│                    PUBLISHER'S TENANT                            │
│                                                                 │
│  ┌──────────────┐                                               │
│  │  AIAgent     │  (Original agent created by User A)          │
│  │              │                                               │
│  │  id          │  → agent_abc123                              │
│  │  tenant_id   │  → publisher_tenant                           │
│  │  name        │  → "Content Generator"                        │
│  │  workflow_id │  → langflow_workflow_123                     │
│  └──────────────┘                                               │
│         │                                                        │
│         │  ✅ LINKED                                            │
│         │                                                        │
│         ▼                                                        │
│  ┌──────────────────────┐                                       │
│  │ MarketplaceAgent     │  (Published listing)                  │
│  │                      │                                       │
│  │  id                  │  → marketplace_xyz789                │
│  │  source_agent_id      │  → agent_abc123 ✅                   │
│  │  source_tenant_id    │  → publisher_tenant                   │
│  │  created_by_user_id  │  → user_a_id                          │
│  │  tenant_id           │  → publisher_tenant                    │
│  │  name                │  → "Content Generator"                │
│  │  langflow_workflow_id│  → langflow_workflow_123             │
│  │  price_type          │  → "credits_per_use"                  │
│  │  credits_per_exec    │  → 10                                 │
│  │  is_public           │  → TRUE                               │
│  │  status              │  → "approved"                         │
│  └──────────────────────┘                                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ Published to Marketplace
                            │
                            ▼
                    ┌───────────────┐
                    │  MARKETPLACE  │
                    │   (Public)    │
                    └───────────────┘
                            │
                            │ User B browses & purchases
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PURCHASER'S TENANT                           │
│                                                                 │
│  ┌──────────────────────┐                                       │
│  │ AgentPurchase        │  (Purchase record)                    │
│  │                      │                                       │
│  │  id                  │  → purchase_def456                    │
│  │  tenant_id           │  → purchaser_tenant                   │
│  │  agent_id            │  → marketplace_xyz789                 │
│  │  purchase_type       │  → "credits"                          │
│  │  credits_per_exec    │  → 10                                 │
│  │  is_installed         │  → TRUE ✅                            │
│  │  installation_config │  → {installed_agent_id: ...} ✅      │
│  └──────────────────────┘                                       │
│         │                                                        │
│         │  ✅ LINKED                                            │
│         │                                                        │
│         ▼                                                        │
│  ┌──────────────┐                                               │
│  │  AIAgent     │  (Installed instance for Purchaser)           │
│  │              │                                               │
│  │  id          │  → agent_installed_789 ✅                    │
│  │  tenant_id   │  → purchaser_tenant ✅                        │
│  │  brand_id    │  → purchaser_brand (optional) ✅              │
│  │  name        │  → "Content Generator"                        │
│  │  workflow_id │  → langflow_workflow_123 (same workflow)     │
│  │              │                                               │
│  │  ✅ Marketplace fields:                                     │
│  │  source_marketplace_agent_id → marketplace_xyz789            │
│  │  is_marketplace_agent         → TRUE                         │
│  │  purchased_via_purchase_id    → purchase_def456              │
│  │  original_tenant_id           → publisher_tenant             │
│  │  original_creator_user_id     → user_a_id                    │
│  └──────────────┘                                               │
│                                                                 │
│  ✅ Agent can now be used by Purchaser                          │
│  ✅ Usage tracked via AgentPurchase                             │
│  ✅ Credits deducted per execution                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Installation Flow

```
1. User B browses marketplace
   │
   ▼
2. User B finds "Content Generator" agent
   │
   ▼
3. User B purchases agent (creates AgentPurchase record)
   │
   ▼
4. User B clicks "Install" button
   │
   ▼
5. System calls install_marketplace_agent():
   │
   ├─→ Get MarketplaceAgent details
   ├─→ Create new AIAgent instance in purchaser's tenant
   ├─→ Copy workflow_id, configuration, etc.
   ├─→ Set marketplace tracking fields
   ├─→ Link to AgentPurchase record
   └─→ Update AgentPurchase.is_installed = TRUE
   │
   ▼
6. Agent appears in User B's "/api/agents/installed" list
   │
   ▼
7. User B can execute agent
   │
   ▼
8. On execution:
   ├─→ Check AgentPurchase license validity
   ├─→ Check usage limits
   ├─→ Deduct credits (if credit-based)
   ├─→ Increment usage_count
   └─→ Execute Langflow workflow
```

## Brand Association Options

### Option A: Tenant-Scoped (Current Design)
```
Purchaser's Tenant
├── Brand 1 ──┐
├── Brand 2 ──┼──→ All brands share the installed agent
└── Brand 3 ──┘
```
- Agent installed at tenant level
- Available to all brands in tenant
- Simpler implementation
- Matches current AIAgent design

### Option B: Brand-Scoped (Optional Enhancement)
```
Purchaser's Tenant
├── Brand 1 ──→ Agent installed for Brand 1 only
├── Brand 2 ──→ (No access to agent)
└── Brand 3 ──→ Agent installed for Brand 3 only
```
- Agent installed per brand
- Requires `brand_id` field on AIAgent
- Or `AgentBrandAssociation` junction table
- More granular control

## Key Implementation Points

1. **Publishing**: Link `MarketplaceAgent.source_agent_id` → `AIAgent.id`
2. **Installation**: Create new `AIAgent` instance in purchaser's tenant
3. **Tracking**: Link installed agent back to `MarketplaceAgent` and `AgentPurchase`
4. **Execution**: Check license, deduct credits, track usage
5. **Brand Association**: Optional - can be tenant-scoped or brand-scoped
