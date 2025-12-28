# Agents Display Architecture Diagnosis

## Architecture Flow

### 1. User Authentication & Brand Selection
```
User Login → JWT Token → Frontend selects Brand from dropdown
```

### 2. Tenant ID Retrieval
**Location**: `app/routers/agents_api.py::get_tenant_id_from_current_brand()`

The system retrieves `tenant_id` from the **currently active brand** (not from the user directly):
- Queries `UserActiveBrand` table for user's active brand
- Gets `brand_id` from `UserActiveBrand.brand_id`
- Queries `Brand` table to get `Brand.tenant_id`
- Returns `tenant_id` for all subsequent queries

**Key Point**: The tenant context comes from the **brand selected in the dropdown**, not from the user's direct tenant assignment.

### 3. Subscription Tier Assessment
**Location**: `app/routers/agents_api.py::get_agent_config()` and `create_agent()`

The system checks subscription tier in two scenarios:

#### A. When Creating Agents (Line 476-482)
```python
tenant = db.query(Tenant).filter(Tenant.id == tenant_id).first()
plan_tier = tenant.plan_tier or "free"  # Defaults to "free" if None
max_agents = get_agent_limit(plan_tier)  # Gets limit from database
```

#### B. When Getting Agent Config (Line 1917-1921)
```python
tenant = db.query(Tenant).filter(Tenant.id == tenant_id).first()
if tenant:
    plan_tier = tenant.plan_tier or "free"
    max_agents = get_agent_limit(plan_tier)
```

**Key Point**: Subscription tier is used to **LIMIT how many agents can be CREATED**, not to control VIEWING.

### 4. Agent Retrieval
**Location**: `app/routers/agents_api.py::get_installed_agents()` (Line 1579)

Agents are queried **only by tenant_id** - there is NO subscription tier check:
```python
query = db.query(AIAgent).filter(AIAgent.tenant_id == tenant_id)
```

**Key Point**: All agents for a tenant are visible regardless of subscription tier. The tier only limits creation.

## The Issue

### Root Cause Analysis

Based on the logs showing `404: Agent not found` errors, the issue is likely:

1. **Tenant has no `plan_tier` set** (or it's NULL)
   - When `tenant.plan_tier` is `None`, code defaults to `"free"`
   - Free tier allows 1 agent (from `agent_tiers.py`)

2. **No agents exist in database for that tenant_id**
   - The query `db.query(AIAgent).filter(AIAgent.tenant_id == tenant_id)` returns empty
   - This is NOT a subscription tier issue - it's a data issue

3. **Possible RLS Policy Blocking**
   - Row Level Security policies might be filtering out agents
   - The code sets RLS context (lines 1550-1564), but policies might still block

### Current Error Flow

From logs:
```
Failed to get agent installed: 404: Agent not found
Failed to get agent analytics: 404: Agent not found
```

These errors are being caught and logged, but the endpoints return empty lists (not 404s). The "404: Agent not found" message suggests:
- An internal service call is raising HTTPException(404)
- OR the frontend is interpreting empty results as "not found"

## Database Schema

### Tenant Model (`app/models/core.py`)
```python
class Tenant(Base):
    plan_tier = Column(String(50), nullable=False)  # REQUIRED, no default
```

**Issue**: If `plan_tier` is NULL in database, SQLAlchemy will raise an error OR return None, which code handles with `or "free"`.

### Brand Model (`app/models/brand_models.py`)
```python
class Brand(Base):
    plan_tier = Column(String(50), default="free")  # Has default
    tenant_id = Column(String(36), ForeignKey("tenants.id"))
```

**Note**: Brands have their own `plan_tier`, but the code reads from `Tenant.plan_tier`, not `Brand.plan_tier`.

## Subscription Tier Limits

**Location**: `app/config/agent_tiers.py`

Fallback limits (if database unavailable):
- `free`: 1 agent
- `starter`: 2 agents
- `professional`: 3 agents
- `business`: 4 agents
- `enterprise`: 100 agents (effectively unlimited)

**Dynamic Loading**: Limits are loaded from `plan_tier_configs` table with caching (5-minute TTL).

## Diagnosis Steps

### 1. Check Tenant's Plan Tier
```sql
SELECT id, name, plan_tier 
FROM tenants 
WHERE id = (
    SELECT tenant_id 
    FROM brands 
    WHERE id = (
        SELECT brand_id 
        FROM user_active_brands 
        WHERE user_id = (
            SELECT id FROM users WHERE email = 'demo@engarde.com'
        )
    )
);
```

### 2. Check if Agents Exist for Tenant
```sql
SELECT COUNT(*) 
FROM ai_agents 
WHERE tenant_id = '<tenant_id_from_step_1>';
```

### 3. Check User's Active Brand
```sql
SELECT uab.brand_id, b.name, b.tenant_id
FROM user_active_brands uab
JOIN brands b ON b.id = uab.brand_id
WHERE uab.user_id = (SELECT id FROM users WHERE email = 'demo@engarde.com');
```

### 4. Check RLS Policies
```sql
-- Check if RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'ai_agents';

-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'ai_agents';
```

## Recommended Fixes

### Fix 1: Ensure Tenant Has Plan Tier
```sql
-- Set plan_tier for demo tenant
UPDATE tenants 
SET plan_tier = 'professional'  -- or 'starter', 'business', etc.
WHERE id = '<tenant_id>';
```

### Fix 2: Create Demo Agents (if none exist)
```sql
-- Create a demo agent for the tenant
INSERT INTO ai_agents (
    id, tenant_id, name, description, agent_type, status, 
    created_at, updated_at
) VALUES (
    gen_random_uuid(),
    '<tenant_id>',
    'Demo Marketing Agent',
    'A sample agent for demonstration',
    'content_generation',
    'active',
    NOW(),
    NOW()
);
```

### Fix 3: Verify Brand-Tenant Relationship
```sql
-- Ensure brand has correct tenant_id
UPDATE brands 
SET tenant_id = '<tenant_id>'
WHERE id = (
    SELECT brand_id 
    FROM user_active_brands 
    WHERE user_id = (SELECT id FROM users WHERE email = 'demo@engarde.com')
);
```

## Code Changes Needed

### Option A: Add Subscription Tier Check to Viewing (if desired)
If you want subscription tier to control VIEWING (not just creation), modify `get_installed_agents()`:

```python
# After getting tenant_id, check subscription tier
tenant = db.query(Tenant).filter(Tenant.id == tenant_id).first()
if tenant:
    plan_tier = tenant.plan_tier or "free"
    # If free tier and no agents allowed, return empty
    if plan_tier == "free" and get_agent_limit(plan_tier) == 0:
        return default_response
```

### Option B: Ensure Default Plan Tier (Recommended)
Add a database migration to set default `plan_tier` for existing tenants:

```sql
UPDATE tenants 
SET plan_tier = 'free' 
WHERE plan_tier IS NULL OR plan_tier = '';
```

## Summary

**The issue is NOT subscription tier screening logic** - the code doesn't check subscription tier when viewing agents. The issue is likely:

1. **No agents exist** in the database for the demo user's tenant
2. **Tenant has NULL plan_tier** (though code handles this with default "free")
3. **RLS policies** might be blocking access

**Next Steps**:
1. Run diagnostic SQL queries above
2. Check if agents exist for the tenant
3. If no agents exist, create demo agents
4. Ensure tenant has a valid `plan_tier` set
