# Langflow & EnGarde Database Architecture

**Date**: January 15, 2026
**Purpose**: Explain the relationship between `ai_agents` table (EnGarde schema) and Langflow's flow storage

---

## Executive Summary

**Current State**: The `ai_agents` table in EnGarde's PostgreSQL database and Langflow's flow storage system are **currently disconnected** but designed to work together.

**Key Finding**:
- ✅ EnGarde has 5 AI agents with `langflow_workflow_id` references
- ❌ Langflow's `flow` table is **empty** (0 flows)
- ❌ `engarde_langflow_workflows` bridge table is **empty** (0 workflows)
- ⚠️ The workflow IDs in `ai_agents` are **placeholder UUIDs** with no actual Langflow flows

**Status**: Infrastructure is ready but integration needs activation.

---

## Database Architecture

### Schema Distribution

The PostgreSQL database on Railway contains **multiple schemas**:

```
railway (database)
├── public (EnGarde core tables)
│   ├── ai_agents              # EnGarde's agent metadata
│   ├── ai_executions          # Agent execution history
│   ├── engarde_langflow_workflows  # Bridge table (empty)
│   ├── flow                   # Langflow flows (empty)
│   ├── tenants                # Multi-tenant data
│   └── ... (176 more tables)
│
├── langflow (Langflow's schema)
│   └── alembic_version_langflow  # Version tracking only
│
├── production_backend (backend schema)
├── onside (Onside service schema)
├── madansara (MadanSara service schema)
└── sankore (Sankore service schema)
```

---

## Table Structures

### 1. `public.ai_agents` (EnGarde Agent Metadata)

**Purpose**: Stores EnGarde's AI agent definitions, configuration, and performance metrics

**Key Columns**:
```sql
CREATE TABLE public.ai_agents (
    id                      VARCHAR(36) PRIMARY KEY,
    tenant_id               VARCHAR(36) NOT NULL,
    name                    VARCHAR(255) NOT NULL,
    agent_type              VARCHAR(100) NOT NULL,
    status                  VARCHAR(50),  -- draft, deployed, active, paused

    -- Langflow Integration Fields
    langflow_workflow_id    VARCHAR(255),  -- References Langflow flow UUID
    langflow_deployment_id  VARCHAR(255),  -- References deployed endpoint
    workflow_definition     JSON,          -- Local workflow config

    -- Performance Metrics
    total_executions        INTEGER DEFAULT 0,
    successful_executions   INTEGER DEFAULT 0,
    average_response_time   INTEGER DEFAULT 0,

    -- Timestamps
    created_at              TIMESTAMP,
    deployed_at             TIMESTAMP,
    last_execution_at       TIMESTAMP
);
```

**Current Data** (5 records):
| Name | Type | Langflow Workflow ID | Status |
|------|------|---------------------|--------|
| Ad Creative Testing Agent | walker_optimization | 7d90a696-5cb9-4c70-a89c-e813dbd6fb8d | active |
| Audience Segmentation Agent | walker_audience | ff847a46-b057-47f4-88fc-d105422aa1c5 | active |
| Budget Optimizer Agent | walker_optimization | b2a5d65d-3c59-45a0-bcbe-706e0515dd05 | active |
| Campaign Performance Monitor Agent | walker_analytics | 93fa75b5-6496-4877-82a2-a764aecdfaf6 | active |
| Social Media Content Pipeline Agent | walker_content | 5f81ee64-8f1e-46d9-90ac-81fdb98a51a9 | active |

---

### 2. `public.flow` (Langflow Flow Storage)

**Purpose**: Stores Langflow's flow definitions created in the UI

**Key Columns**:
```sql
CREATE TABLE public.flow (
    id                  UUID PRIMARY KEY,
    name                VARCHAR NOT NULL,
    description         TEXT,
    data                JSON,            -- Flow graph definition
    user_id             UUID,            -- Creator
    folder_id           UUID,            -- Organization
    endpoint_name       VARCHAR,         -- API endpoint
    webhook             BOOLEAN,         -- Webhook enabled
    is_component        BOOLEAN,         -- Is custom component
    updated_at          TIMESTAMP,
    icon                VARCHAR,
    tags                JSON,
    locked              BOOLEAN
);
```

**Current Data**: **0 records** (empty)

---

### 3. `public.engarde_langflow_workflows` (Bridge Table)

**Purpose**: Links EnGarde business entities (tenant, brand, campaign) to Langflow flows

**Key Columns**:
```sql
CREATE TABLE public.engarde_langflow_workflows (
    id                      VARCHAR PRIMARY KEY,
    tenant_id               VARCHAR NOT NULL,
    brand_id                VARCHAR,
    campaign_id             VARCHAR,
    created_by              VARCHAR NOT NULL,

    -- Langflow Reference
    langflow_flow_id        VARCHAR NOT NULL,  -- FK to flow.id

    -- Workflow Metadata
    workflow_name           VARCHAR NOT NULL,
    workflow_type           VARCHAR NOT NULL,
    description             TEXT,
    configuration           JSONB NOT NULL,

    -- Status & Metrics
    status                  VARCHAR NOT NULL,
    deployment_status       VARCHAR NOT NULL,
    deployment_url          VARCHAR,
    execution_count         INTEGER DEFAULT 0,
    success_count           INTEGER DEFAULT 0,
    error_count             INTEGER DEFAULT 0,

    -- Versioning
    version                 VARCHAR NOT NULL,
    previous_version        VARCHAR,

    -- Timestamps
    created_at              TIMESTAMP NOT NULL,
    last_deployed_at        TIMESTAMP,
    last_execution_at       TIMESTAMP
);
```

**Current Data**: **0 records** (empty)

---

## Intended Relationship

### Design Pattern

The architecture follows a **three-tier integration pattern**:

```
┌─────────────────────────────────────────────────────────────┐
│                    EnGarde Application Layer                │
│                                                              │
│  User creates agent via UI (/agents/create)                │
│  ↓                                                           │
│  POST /api/v1/agents                                        │
│  ↓                                                           │
│  Creates record in ai_agents table                          │
│  - Generates agent_id                                       │
│  - Stores configuration                                     │
│  - Sets status = "draft"                                    │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ↓
┌─────────────────────────────────────────────────────────────┐
│              Integration/Bridge Layer                        │
│                                                              │
│  When agent is "deployed":                                  │
│  ↓                                                           │
│  POST /api/v1/langflow/deploy                               │
│  ↓                                                           │
│  Creates Langflow flow via Langflow API                     │
│  ↓                                                           │
│  Receives flow_id from Langflow                             │
│  ↓                                                           │
│  Updates ai_agents.langflow_workflow_id = flow_id          │
│  ↓                                                           │
│  Creates engarde_langflow_workflows record                  │
│  - Links tenant_id → langflow_flow_id                       │
│  - Stores deployment metadata                               │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ↓
┌─────────────────────────────────────────────────────────────┐
│                    Langflow Layer                            │
│                                                              │
│  Langflow creates flow in flow table                        │
│  - Stores graph definition in data JSON                     │
│  - Creates API endpoint                                     │
│  - Returns flow UUID                                        │
│                                                              │
│  Flow is executable via:                                    │
│  POST /api/v1/run/{flow_id}                                 │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow Example

**1. User Creates Agent** (via EnGarde UI):
```typescript
// Frontend: /agents/create
const response = await fetch('/api/v1/agents', {
  method: 'POST',
  body: JSON.stringify({
    name: "Social Media Campaign Agent",
    agent_type: "walker_content",
    configuration: { platforms: ["facebook", "instagram"] }
  })
});

// Backend creates:
INSERT INTO ai_agents (
    id,
    tenant_id,
    name,
    agent_type,
    status,
    langflow_workflow_id  -- NULL initially
) VALUES (
    'agent-123',
    'tenant-456',
    'Social Media Campaign Agent',
    'walker_content',
    'draft',
    NULL
);
```

**2. User Deploys Agent** (triggers Langflow flow creation):
```typescript
// Frontend: Agent detail page → "Deploy" button
const response = await fetch('/api/v1/agents/agent-123/deploy', {
  method: 'POST'
});

// Backend:
// 1. Get agent config from ai_agents
// 2. Generate Langflow flow definition
// 3. Call Langflow API to create flow
const langflowResponse = await fetch('https://langflow.engarde.media/api/v1/flows', {
  method: 'POST',
  body: JSON.stringify({
    name: "Social Media Campaign Agent",
    data: {
      nodes: [...],
      edges: [...]
    }
  })
});

const { flow_id } = langflowResponse.data;

// 4. Update ai_agents with flow_id
UPDATE ai_agents
SET langflow_workflow_id = 'flow-uuid-789',
    status = 'deployed',
    deployed_at = NOW()
WHERE id = 'agent-123';

// 5. Create bridge record
INSERT INTO engarde_langflow_workflows (
    id,
    tenant_id,
    langflow_flow_id,
    workflow_name,
    status,
    deployment_status
) VALUES (
    'workflow-999',
    'tenant-456',
    'flow-uuid-789',
    'Social Media Campaign Agent',
    'active',
    'deployed'
);
```

**3. Langflow Stores Flow**:
```sql
-- Langflow creates record in flow table
INSERT INTO flow (
    id,
    name,
    description,
    data,
    user_id,
    endpoint_name
) VALUES (
    'flow-uuid-789',
    'Social Media Campaign Agent',
    'Generated from EnGarde',
    '{"nodes": [...], "edges": [...]}',
    'system-user',
    'social-media-campaign-agent'
);
```

**4. User Executes Agent** (triggers workflow run):
```typescript
// Frontend: Agent detail page → "Run" button
const response = await fetch('/api/v1/agents/agent-123/execute', {
  method: 'POST',
  body: JSON.stringify({
    inputs: { campaign_id: "camp-555" }
  })
});

// Backend:
// 1. Get langflow_workflow_id from ai_agents
// 2. Call Langflow API to execute flow
const result = await fetch(`https://langflow.engarde.media/api/v1/run/${flow_id}`, {
  method: 'POST',
  body: JSON.stringify({ inputs: { campaign_id: "camp-555" } })
});

// 3. Store execution record
INSERT INTO ai_executions (
    id,
    agent_id,
    tenant_id,
    execution_type,
    status,
    input_data,
    output_data
) VALUES (
    'exec-888',
    'agent-123',
    'tenant-456',
    'manual',
    'completed',
    '{"campaign_id": "camp-555"}',
    '{"content_generated": [...]}}'
);

// 4. Update metrics
UPDATE ai_agents
SET total_executions = total_executions + 1,
    successful_executions = successful_executions + 1,
    last_execution_at = NOW()
WHERE id = 'agent-123';
```

---

## Current State Issues

### Problem 1: No Langflow Flows

**Issue**: The `flow` table is empty, meaning no Langflow workflows have been created in the UI.

**Why**:
- Langflow is deployed at `https://langflow.engarde.media`
- But users haven't created any flows in the Langflow UI yet
- The integration code exists but hasn't been triggered

**Evidence**:
```sql
SELECT COUNT(*) FROM flow;
-- Result: 0
```

### Problem 2: Orphaned Workflow IDs

**Issue**: `ai_agents` table has `langflow_workflow_id` values that don't reference any actual Langflow flows.

**Why**:
- These appear to be placeholder UUIDs generated during agent seeding
- No actual Langflow flows were created during seeding
- The IDs are random UUIDs with no corresponding data

**Evidence**:
```sql
SELECT
    a.name,
    a.langflow_workflow_id,
    CASE WHEN f.id IS NOT NULL THEN 'Found' ELSE 'Not Found' END as flow_exists
FROM ai_agents a
LEFT JOIN flow f ON f.id::text = a.langflow_workflow_id;

-- Result: All show "Not Found"
```

### Problem 3: Empty Bridge Table

**Issue**: `engarde_langflow_workflows` table is empty, meaning no EnGarde-Langflow linkage has been established.

**Why**:
- This table is only populated when agents are deployed
- No agents have been deployed yet (they were seeded as "active" but never went through deployment flow)

**Evidence**:
```sql
SELECT COUNT(*) FROM engarde_langflow_workflows;
-- Result: 0
```

---

## Integration Code Status

### Backend Services

**✅ Implemented**:
- `/Users/cope/EnGardeHQ/production-backend/app/services/langflow_integration.py`
  - `LangFlowIntegration` class
  - `create_workflow()` method
  - `deploy_workflow()` method
  - `execute_workflow()` method

**✅ API Endpoints**:
- `/Users/cope/EnGardeHQ/production-backend/app/routers/agents_api.py`
  - `POST /agents` - Create agent
  - `POST /agents/{id}/deploy` - Deploy agent (should create Langflow flow)
  - `POST /agents/{id}/execute` - Execute agent workflow

**❌ Missing**:
- Actual deployment trigger when agent status changes to "deployed"
- Langflow flow creation logic in deployment endpoint
- Sync mechanism to keep `ai_agents` and `flow` tables in sync

### Frontend

**✅ Implemented**:
- `/Users/cope/EnGardeHQ/production-frontend/app/agents/*` pages
- Agent creation UI
- Agent detail pages
- Agent execution UI

**❌ Missing**:
- "Deploy to Langflow" button/action
- Flow visualization (showing Langflow graph)
- Direct Langflow UI integration

---

## How to Activate Integration

### Step 1: Verify Langflow is Running

```bash
curl https://langflow.engarde.media/health
```

Should return: `{"status": "healthy"}`

### Step 2: Create Test Flow in Langflow UI

1. Visit https://langflow.engarde.media
2. Login with SSO (should redirect from EnGarde)
3. Create a simple test flow
4. Note the flow ID

### Step 3: Verify Flow Storage

```bash
python3 -c "
from sqlalchemy import create_engine, text
engine = create_engine('postgresql://...')
with engine.connect() as conn:
    result = conn.execute(text('SELECT id, name FROM flow LIMIT 5'))
    for row in result:
        print(f'{row[0]} - {row[1]}')
"
```

### Step 4: Implement Deployment Trigger

Update `/Users/cope/EnGardeHQ/production-backend/app/routers/agents_api.py`:

```python
@router.post("/agents/{agent_id}/deploy")
async def deploy_agent(
    agent_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Deploy agent to Langflow"""

    # 1. Get agent from database
    agent = db.query(AIAgent).filter(AIAgent.id == agent_id).first()
    if not agent:
        raise HTTPException(404, "Agent not found")

    # 2. Initialize Langflow integration
    langflow = LangFlowIntegration()

    # 3. Create flow in Langflow
    flow_id = await langflow.create_workflow(
        tenant_id=agent.tenant_id,
        workflow_name=agent.name,
        workflow_type=agent.agent_type,
        template_id=agent.configuration.get("template_id"),
        configuration=agent.configuration
    )

    # 4. Update agent with flow_id
    agent.langflow_workflow_id = flow_id
    agent.status = "deployed"
    agent.deployed_at = datetime.utcnow()
    db.commit()

    # 5. Create bridge record
    workflow = EngardeLangflowWorkflow(
        id=str(uuid.uuid4()),
        tenant_id=agent.tenant_id,
        langflow_flow_id=flow_id,
        workflow_name=agent.name,
        workflow_type=agent.agent_type,
        status="active",
        deployment_status="deployed",
        configuration=agent.configuration
    )
    db.add(workflow)
    db.commit()

    return {"flow_id": flow_id, "status": "deployed"}
```

### Step 5: Test End-to-End Flow

```typescript
// 1. Create agent
const agent = await fetch('/api/v1/agents', {
  method: 'POST',
  body: JSON.stringify({
    name: "Test Agent",
    agent_type: "walker_content"
  })
});

// 2. Deploy agent (should create Langflow flow)
const deployment = await fetch(`/api/v1/agents/${agent.id}/deploy`, {
  method: 'POST'
});

// 3. Execute agent (should run Langflow flow)
const execution = await fetch(`/api/v1/agents/${agent.id}/execute`, {
  method: 'POST',
  body: JSON.stringify({ inputs: { test: "data" } })
});
```

---

## Schema Isolation

### Langflow's Isolated Schema

Langflow should be using the `langflow` schema, but currently only has a version table there. This suggests:

**Option 1**: Langflow is configured to use `public` schema
```bash
# Check Langflow's DATABASE_URL
LANGFLOW_DATABASE_URL=postgresql://user:pass@host:port/db?options=-csearch_path=langflow,public
```

**Option 2**: Langflow tables are in `public` schema
```sql
-- The flow table exists in public schema
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_name = 'flow';

-- Result: public.flow (not langflow.flow)
```

### Multi-Tenant Isolation

EnGarde uses Row-Level Security (RLS) on `ai_agents`:
```sql
-- All queries filtered by tenant_id
SELECT * FROM ai_agents WHERE tenant_id = current_setting('app.current_tenant_id');
```

Langflow should also filter flows by tenant:
```sql
-- Proposed: Add tenant_id to flow table
ALTER TABLE flow ADD COLUMN tenant_id VARCHAR(36);

-- Create RLS policy
CREATE POLICY tenant_isolation ON flow
FOR ALL TO PUBLIC
USING (tenant_id = current_setting('app.current_tenant_id', true));
```

---

## Recommendations

### Immediate Actions

1. **Verify Langflow Deployment**:
   - Check if Langflow is accessible
   - Verify database connection
   - Check schema configuration

2. **Clean Up Placeholder Data**:
   ```sql
   -- Option A: Clear invalid workflow IDs
   UPDATE ai_agents SET langflow_workflow_id = NULL;

   -- Option B: Generate real flows for existing agents
   -- (requires implementing deployment trigger)
   ```

3. **Implement Deployment Flow**:
   - Add deployment endpoint logic
   - Create Langflow flows programmatically
   - Update bridge table

4. **Test Integration**:
   - Create test agent
   - Deploy to Langflow
   - Execute and verify results

### Long-Term Architecture

1. **Bidirectional Sync**:
   - Flows created in Langflow UI → sync to `ai_agents`
   - Agents created in EnGarde → sync to `flow`

2. **Webhook Integration**:
   - Langflow notifies EnGarde when flow completes
   - EnGarde updates execution metrics in real-time

3. **Unified UI**:
   - Embed Langflow flow builder in EnGarde UI
   - Show flow visualization in agent detail page

4. **Tenant Isolation**:
   - Add RLS policies to `flow` table
   - Ensure multi-tenant filtering at all levels

---

## Summary

**Current Relationship**: `ai_agents.langflow_workflow_id` → `flow.id` (intended but broken)

**Issue**:
- `ai_agents` has placeholder UUIDs in `langflow_workflow_id`
- `flow` table is empty (no actual Langflow flows)
- `engarde_langflow_workflows` bridge is empty
- No flows created in Langflow UI

**Solution**:
1. Clear placeholder workflow IDs or create real flows
2. Implement deployment trigger to create Langflow flows
3. Activate Langflow integration code
4. Test end-to-end agent creation → deployment → execution

**Architecture is sound, implementation needs activation.**

---

*Report Generated: January 15, 2026*
*Status: Integration code exists but not activated*
