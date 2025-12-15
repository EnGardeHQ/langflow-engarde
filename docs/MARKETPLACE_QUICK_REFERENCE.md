# Marketplace Functionality - Quick Reference

## API Endpoints

### 1. Publish Agent to Marketplace
```http
POST /api/agents/{agent_id}/publish-to-marketplace
Content-Type: application/json

{
  "price_type": "free" | "one_time" | "credits_per_use",
  "price_amount": 0.0,
  "credits_per_execution": 10,
  "is_public": true,
  "publisher_name": "My Company",
  "publisher_contact": "contact@example.com",
  "support_url": "https://support.example.com",
  "documentation_url": "https://docs.example.com"
}
```

### 2. Install Marketplace Agent
```http
POST /api/agents/marketplace/{marketplace_agent_id}/install
```

### 3. Browse Marketplace
```http
GET /api/agents/marketplace?category=content&featured=true&sort_by=popularity&page=1&page_size=20
```

### 4. Execute Agent (with Marketplace Billing)
```http
POST /api/agents/{agent_id}/execute
Content-Type: application/json

{
  "input_data": {...},
  "configuration_overrides": {...},
  "session_id": "optional-session-id",
  "async_execution": false
}
```

## Database Migration

Run the migration to add marketplace fields:
```bash
cd production-backend
python scripts/migrations/add_marketplace_fields_to_agents.py
```

## Pricing Models

1. **Free**: No cost, unlimited usage
2. **One-Time**: Pay once, unlimited usage
3. **Credits Per Use**: Pay credits per execution

## Workflow

1. **Publisher** creates agent → Publishes to marketplace
2. **Marketplace** reviews and approves agent
3. **Purchaser** browses marketplace → Installs agent
4. **System** creates AIAgent instance in purchaser's tenant
5. **Purchaser** executes agent → System handles billing

## Key Fields

### AIAgent (Installed Agent)
- `is_marketplace_agent` - True if from marketplace
- `source_marketplace_agent_id` - Links to MarketplaceAgent
- `purchased_via_purchase_id` - Links to AgentPurchase
- `original_tenant_id` - Publisher's tenant
- `original_creator_user_id` - Publisher's user

### MarketplaceAgent (Listing)
- `source_agent_id` - Links to original AIAgent
- `source_tenant_id` - Publisher's tenant
- `created_by_user_id` - Publisher's user
- `status` - "pending_review" | "approved" | "rejected"
- `is_public` - Public visibility flag

### AgentPurchase (Purchase Record)
- `tenant_id` - Purchaser's tenant
- `agent_id` - MarketplaceAgent ID
- `purchase_type` - "free" | "one_time" | "credits"
- `credits_per_execution` - Credits per use
- `usage_count` - Current usage
- `usage_limit` - Max executions (null = unlimited)
- `is_installed` - Installation status
