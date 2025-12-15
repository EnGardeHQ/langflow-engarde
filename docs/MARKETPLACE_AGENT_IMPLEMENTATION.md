# Marketplace Agent Implementation Analysis

## Current State

### Existing Models

1. **`AIAgent`** (tenant-scoped agent instances)
   - Belongs to a specific `tenant_id` (the creator's tenant)
   - Used for actual agent execution within a tenant
   - No marketplace fields currently

2. **`MarketplaceAgent`** (marketplace listings)
   - Separate entity for marketplace listings
   - Has its own `tenant_id` (publisher's tenant)
   - Includes pricing, ratings, marketplace metadata
   - **No direct link to `AIAgent`**

3. **`AgentPurchase`** (purchase/license tracking)
   - Links purchasing `tenant_id` to `marketplace_agents.id`
   - Tracks license, usage limits, payment
   - Has `is_installed` flag but **no link to `AIAgent`**

### Current Gap

**Answer: NO**, agents cannot currently be associated with another user's brand because:

1. **No Link Between Models**: `MarketplaceAgent` and `AIAgent` are separate entities with no foreign key relationship
2. **No Installation Process**: When an agent is purchased, there's no mechanism to create an `AIAgent` instance in the purchasing tenant
3. **No Brand Association**: Even if installed, agents are tenant-scoped, not brand-scoped

## What's Needed: Implementation Steps

### Step 1: Add Marketplace Fields to AIAgent

Add fields to link `AIAgent` to marketplace listings:

```python
class AIAgent(Base):
    # ... existing fields ...
    
    # Marketplace integration
    source_marketplace_agent_id = Column(String(36), ForeignKey("marketplace_agents.id"), nullable=True, index=True)
    is_marketplace_agent = Column(Boolean, default=False, index=True)  # True if from marketplace
    purchased_via_purchase_id = Column(String(36), ForeignKey("agent_purchases.id"), nullable=True)
    
    # Original creator info (for marketplace agents)
    original_tenant_id = Column(String(36), ForeignKey("tenants.id"), nullable=True)  # Publisher's tenant
    original_creator_user_id = Column(String(36), ForeignKey("users.id"), nullable=True)  # Publisher's user
```

### Step 2: Add Source Agent Link to MarketplaceAgent

Link `MarketplaceAgent` back to the original `AIAgent`:

```python
class MarketplaceAgent(Base):
    # ... existing fields ...
    
    # Link to source agent (the original AIAgent that was published)
    source_agent_id = Column(String(36), ForeignKey("ai_agents.id"), nullable=True, index=True)
    source_tenant_id = Column(String(36), ForeignKey("tenants.id"), nullable=False, index=True)
    created_by_user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
```

### Step 3: Create Agent Installation Process

When an agent is purchased, create an `AIAgent` instance in the purchasing tenant:

```python
async def install_marketplace_agent(
    purchase_id: str,
    target_tenant_id: str,
    target_brand_id: Optional[str] = None,  # Optional brand association
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Install a purchased marketplace agent into the purchasing tenant.
    Creates a new AIAgent instance based on the MarketplaceAgent.
    """
    # 1. Get purchase record
    purchase = db.query(AgentPurchase).filter(AgentPurchase.id == purchase_id).first()
    if not purchase:
        raise HTTPException(404, "Purchase not found")
    
    # 2. Verify purchase belongs to tenant
    if purchase.tenant_id != target_tenant_id:
        raise HTTPException(403, "Purchase does not belong to this tenant")
    
    # 3. Get marketplace agent
    marketplace_agent = db.query(MarketplaceAgent).filter(
        MarketplaceAgent.id == purchase.agent_id
    ).first()
    
    # 4. Create AIAgent instance in purchasing tenant
    new_agent = AIAgent(
        tenant_id=target_tenant_id,
        name=marketplace_agent.name,
        description=marketplace_agent.description,
        agent_type=marketplace_agent.category,  # Map category to agent_type
        status="active",
        langflow_workflow_id=marketplace_agent.langflow_workflow_id,
        workflow_definition=marketplace_agent.workflow_config,
        configuration=marketplace_agent.input_schema,  # Or merge with defaults
        capabilities=marketplace_agent.tags,  # Or extract from tags
        # Marketplace links
        source_marketplace_agent_id=marketplace_agent.id,
        is_marketplace_agent=True,
        purchased_via_purchase_id=purchase.id,
        original_tenant_id=marketplace_agent.tenant_id,
        original_creator_user_id=marketplace_agent.created_by_user_id,
    )
    
    db.add(new_agent)
    
    # 5. Update purchase record
    purchase.is_installed = True
    purchase.installation_config = {
        "installed_agent_id": new_agent.id,
        "installed_at": datetime.utcnow().isoformat(),
        "target_brand_id": target_brand_id,  # Optional brand association
    }
    
    db.commit()
    
    return new_agent
```

### Step 4: Add Brand Association (Optional)

If you want agents to be brand-specific when installed from marketplace:

**Option A: Add brand_id to AIAgent** (makes agents brand-scoped)
```python
class AIAgent(Base):
    # ... existing fields ...
    brand_id = Column(String(36), ForeignKey("brands.id", ondelete="CASCADE"), nullable=True, index=True)
```

**Option B: Create AgentBrandAssociation table** (allows agents to be associated with multiple brands)
```python
class AgentBrandAssociation(Base):
    """Associates marketplace-installed agents with specific brands"""
    __tablename__ = "agent_brand_associations"
    
    id = Column(String(36), primary_key=True)
    agent_id = Column(String(36), ForeignKey("ai_agents.id", ondelete="CASCADE"), nullable=False)
    brand_id = Column(String(36), ForeignKey("brands.id", ondelete="CASCADE"), nullable=False)
    tenant_id = Column(String(36), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False)
    
    # Usage tracking per brand
    executions_count = Column(Integer, default=0)
    last_used_at = Column(DateTime, nullable=True)
    
    __table_args__ = (
        UniqueConstraint('agent_id', 'brand_id', name='uq_agent_brand'),
    )
```

### Step 5: Create Publish to Marketplace Endpoint

Allow users to publish their agents to the marketplace:

```python
@router.post("/{agent_id}/publish-to-marketplace")
async def publish_agent_to_marketplace(
    agent_id: str,
    pricing: MarketplacePricingRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Publish an AIAgent to the marketplace.
    Creates a MarketplaceAgent listing linked to the source AIAgent.
    """
    # 1. Get agent
    agent = db.query(AIAgent).filter(AIAgent.id == agent_id).first()
    if not agent:
        raise HTTPException(404, "Agent not found")
    
    # 2. Verify ownership (agent belongs to user's tenant)
    tenant_id = get_tenant_id_from_current_brand(db, current_user)
    if agent.tenant_id != tenant_id:
        raise HTTPException(403, "Agent does not belong to your tenant")
    
    # 3. Check if already published
    existing = db.query(MarketplaceAgent).filter(
        MarketplaceAgent.source_agent_id == agent_id
    ).first()
    if existing:
        raise HTTPException(400, "Agent already published to marketplace")
    
    # 4. Create marketplace listing
    marketplace_agent = MarketplaceAgent(
        tenant_id=agent.tenant_id,  # Publisher's tenant
        source_agent_id=agent.id,
        source_tenant_id=agent.tenant_id,
        created_by_user_id=current_user.id,
        name=agent.name,
        description=agent.description or "",
        category=agent.agent_type,
        tags=agent.capabilities or [],
        langflow_workflow_id=agent.langflow_workflow_id,
        workflow_config=agent.workflow_definition,
        input_schema=agent.configuration,
        # Pricing
        price_type=pricing.price_type,  # "free", "one_time", "credits_per_use"
        price_amount=pricing.price_amount,
        credits_per_execution=pricing.credits_per_execution,
        # Publishing
        is_public=pricing.is_public,
        status="pending_review",  # Requires approval
        publisher_name=current_user.email,  # Or get from tenant/brand
        # ... other fields
    )
    
    db.add(marketplace_agent)
    db.commit()
    
    return marketplace_agent
```

### Step 6: Update Agent Query Endpoints

Modify agent listing endpoints to include marketplace-installed agents:

```python
@router.get("/installed")
async def get_installed_agents(...):
    """
    Get user's installed agents, including:
    - Tenant's own agents (created locally)
    - Marketplace-installed agents (purchased from marketplace)
    """
    tenant_id = get_tenant_id_from_current_brand(db, current_user)
    
    # Get all agents for tenant (both local and marketplace-installed)
    agents = db.query(AIAgent).filter(
        AIAgent.tenant_id == tenant_id
    ).all()
    
    # Optionally filter by brand if brand_id is provided
    if brand_id:
        # If using Option B (AgentBrandAssociation):
        agent_ids = db.query(AgentBrandAssociation.agent_id).filter(
            AgentBrandAssociation.brand_id == brand_id,
            AgentBrandAssociation.tenant_id == tenant_id
        ).all()
        agents = [a for a in agents if a.id in agent_ids]
    
    return agents
```

### Step 7: Handle Execution Context

When executing a marketplace-installed agent, track usage and billing:

```python
async def execute_agent(agent_id: str, ...):
    """
    Execute an agent, handling marketplace billing if applicable.
    """
    agent = db.query(AIAgent).filter(AIAgent.id == agent_id).first()
    
    # Check if marketplace agent
    if agent.is_marketplace_agent:
        purchase = db.query(AgentPurchase).filter(
            AgentPurchase.id == agent.purchased_via_purchase_id
        ).first()
        
        # Check license validity
        if purchase.license_end and purchase.license_end < datetime.utcnow():
            raise HTTPException(403, "Agent license has expired")
        
        # Check usage limits
        if purchase.usage_limit and purchase.usage_count >= purchase.usage_limit:
            raise HTTPException(403, "Agent usage limit reached")
        
        # Handle credit-based billing
        if purchase.purchase_type == "credits":
            # Deduct credits from tenant's credit wallet
            wallet = db.query(CreditWallet).filter(
                CreditWallet.tenant_id == current_tenant_id
            ).first()
            
            if wallet.balance < purchase.credits_per_execution:
                raise HTTPException(402, "Insufficient credits")
            
            wallet.balance -= purchase.credits_per_execution
            # Create credit transaction record
        
        # Increment usage count
        purchase.usage_count += 1
    
    # Execute agent...
    result = await execute_langflow_workflow(agent.langflow_workflow_id, ...)
    
    return result
```

## Database Migration Required

```sql
-- Add marketplace fields to ai_agents
ALTER TABLE ai_agents
ADD COLUMN source_marketplace_agent_id VARCHAR(36) REFERENCES marketplace_agents(id),
ADD COLUMN is_marketplace_agent BOOLEAN DEFAULT FALSE,
ADD COLUMN purchased_via_purchase_id VARCHAR(36) REFERENCES agent_purchases(id),
ADD COLUMN original_tenant_id VARCHAR(36) REFERENCES tenants(id),
ADD COLUMN original_creator_user_id VARCHAR(36) REFERENCES users(id),
ADD COLUMN brand_id VARCHAR(36) REFERENCES brands(id);  -- If making brand-scoped

CREATE INDEX idx_ai_agents_marketplace ON ai_agents(source_marketplace_agent_id);
CREATE INDEX idx_ai_agents_is_marketplace ON ai_agents(is_marketplace_agent);
CREATE INDEX idx_ai_agents_brand ON ai_agents(brand_id);  -- If brand-scoped

-- Add source agent link to marketplace_agents
ALTER TABLE marketplace_agents
ADD COLUMN source_agent_id VARCHAR(36) REFERENCES ai_agents(id),
ADD COLUMN created_by_user_id VARCHAR(36) REFERENCES users(id);

CREATE INDEX idx_marketplace_agents_source ON marketplace_agents(source_agent_id);

-- Optional: Create agent-brand association table
CREATE TABLE agent_brand_associations (
    id VARCHAR(36) PRIMARY KEY,
    agent_id VARCHAR(36) NOT NULL REFERENCES ai_agents(id) ON DELETE CASCADE,
    brand_id VARCHAR(36) NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
    tenant_id VARCHAR(36) NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    executions_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(agent_id, brand_id)
);

CREATE INDEX idx_agent_brand_tenant ON agent_brand_associations(tenant_id, brand_id);
```

## Summary

**Current State**: Agents cannot be associated with another user's brand because:
- `AIAgent` and `MarketplaceAgent` are separate entities
- No installation process exists
- No brand association mechanism

**What's Needed**:
1. ✅ Link `MarketplaceAgent` to source `AIAgent`
2. ✅ Add marketplace fields to `AIAgent`
3. ✅ Create installation endpoint to create `AIAgent` instances in purchasing tenant
4. ✅ Add brand association (optional - can be tenant-scoped or brand-scoped)
5. ✅ Update agent queries to include marketplace-installed agents
6. ✅ Handle billing/usage tracking for marketplace agents
7. ✅ Create publish-to-marketplace endpoint

**Design Decision**: 
- **Tenant-scoped** (current): Marketplace-installed agents are available to all brands in the purchasing tenant
- **Brand-scoped** (optional): Marketplace-installed agents are associated with specific brands

The implementation above supports both approaches.
