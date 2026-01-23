# EnGarde Langflow - User Activation & Utilization Plan

**Created:** January 11, 2026
**Status:** Infrastructure Complete - Ready for User Activation
**Purpose:** Enable EnGarde platform users to access and utilize existing Langflow resources

---

## Executive Summary

**Current State:**
- ✅ Langflow UI is accessible at Railway deployment
- ✅ PostgreSQL database with `langflow` schema configured
- ✅ Custom Walker Agent components deployed in `/app/components/engarde_components`
- ✅ Environment variables set (SSO secrets, database URLs, API keys)
- ✅ Tables for flows, folders, transactions, users already exist

**What's Needed:**
Enable EnGarde users to:
1. **Discover** existing flows and folders through the EnGarde dashboard
2. **Execute** Walker Agent workflows for their campaigns
3. **View** results and analytics in the EnGarde platform
4. **Create** new flows using the existing custom components

---

## Phase 1: SSO Integration Verification (Day 1)

### Objective
Ensure EnGarde users can seamlessly access Langflow without separate login.

### Tasks

#### 1.1 Verify SSO Endpoint is Accessible
```bash
# Test the SSO endpoint exists
curl https://langflow.engarde.media/api/v1/custom/sso_login

# Expected: 422 error (missing token parameter) = endpoint exists
```

#### 1.2 Test SSO Flow from EnGarde Backend
```python
# File: production-backend/app/routers/langflow_sso.py
# Verify this endpoint works:

@router.post("/sso/langflow")
async def generate_langflow_sso_url(
    current_user: User = Depends(get_current_user)
):
    """Generate SSO URL for Langflow access"""

    # Create JWT token with tenant info
    sso_token = create_sso_token({
        "email": current_user.email,
        "tenant_id": str(current_user.tenant_id),
        "role": current_user.role,
        "subscription_tier": current_user.tenant.subscription_tier
    })

    # Return SSO URL
    return {
        "sso_url": f"https://langflow.engarde.media/api/v1/custom/sso_login?token={sso_token}"
    }
```

**Test Command:**
```bash
# From EnGarde frontend:
POST https://api.engarde.media/api/v1/sso/langflow
Authorization: Bearer <user_token>

# Should return:
{
  "sso_url": "https://langflow.engarde.media/api/v1/custom/sso_login?token=..."
}
```

#### 1.3 Verify User Creation in Langflow
After SSO login, check that user was created in `langflow.user` table:

```sql
-- Connect to PostgreSQL
SELECT
    id,
    username,
    is_active,
    is_superuser,
    created_at
FROM langflow.user
WHERE username = '<test-user-email>';
```

**Success Criteria:**
- [ ] SSO endpoint responds (not 404)
- [ ] JWT token generation works in EnGarde backend
- [ ] SSO login creates user in Langflow database
- [ ] User can access Langflow UI after SSO redirect

---

## Phase 2: Frontend Integration (Days 2-3)

### Objective
Enable users to access Langflow from within the EnGarde dashboard.

### Tasks

#### 2.1 Create "Agent Suite" Page in EnGarde Frontend

**File:** `production-frontend/app/agent-suite/page.tsx`

```typescript
'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/hooks/useAuth';
import AuthenticatedLangflowIframe from '@/components/workflow/AuthenticatedLangflowIframe';

export default function AgentSuitePage() {
  const { user } = useAuth();
  const [ssoUrl, setSsoUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function generateSSOUrl() {
      try {
        const response = await fetch('/api/v1/sso/langflow', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${user?.token}`
          }
        });

        const data = await response.json();
        setSsoUrl(data.sso_url);
      } catch (error) {
        console.error('Failed to generate SSO URL:', error);
      } finally {
        setLoading(false);
      }
    }

    if (user) {
      generateSSOUrl();
    }
  }, [user]);

  if (loading) {
    return <div>Loading Agent Suite...</div>;
  }

  if (!ssoUrl) {
    return <div>Failed to load Agent Suite. Please try again.</div>;
  }

  return (
    <div className="h-screen w-full">
      <AuthenticatedLangflowIframe ssoUrl={ssoUrl} />
    </div>
  );
}
```

#### 2.2 Create Iframe Component

**File:** `production-frontend/components/workflow/AuthenticatedLangflowIframe.tsx`

```typescript
'use client';

import { useEffect, useRef, useState } from 'react';

interface AuthenticatedLangflowIframeProps {
  ssoUrl: string;
}

export default function AuthenticatedLangflowIframe({
  ssoUrl
}: AuthenticatedLangflowIframeProps) {
  const iframeRef = useRef<HTMLIFrameElement>(null);
  const [authenticated, setAuthenticated] = useState(false);

  useEffect(() => {
    // First navigate to SSO URL to authenticate
    if (!authenticated && ssoUrl) {
      // Open SSO in popup to handle authentication
      const popup = window.open(ssoUrl, 'langflow-sso', 'width=600,height=400');

      // Listen for authentication complete
      const checkAuth = setInterval(() => {
        try {
          if (popup?.closed) {
            clearInterval(checkAuth);
            setAuthenticated(true);
          }
        } catch (e) {
          // Ignore cross-origin errors
        }
      }, 500);

      return () => clearInterval(checkAuth);
    }
  }, [ssoUrl, authenticated]);

  if (!authenticated) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="text-center">
          <p>Authenticating with Agent Suite...</p>
          <p className="text-sm text-gray-500 mt-2">
            A popup window will open for authentication.
          </p>
        </div>
      </div>
    );
  }

  return (
    <iframe
      ref={iframeRef}
      src="https://langflow.engarde.media"
      className="w-full h-full border-0"
      title="EnGarde Agent Suite"
      allow="clipboard-read; clipboard-write"
    />
  );
}
```

#### 2.3 Add Navigation Menu Item

**File:** `production-frontend/components/layout/Sidebar.tsx`

```typescript
// Add to navigation items:
{
  name: 'Agent Suite',
  href: '/agent-suite',
  icon: BrainCircuitIcon, // or appropriate icon
  description: 'Build AI-powered campaign workflows'
}
```

**Success Criteria:**
- [ ] "Agent Suite" appears in EnGarde navigation
- [ ] Clicking opens Langflow in authenticated session
- [ ] User sees their flows and folders in Langflow
- [ ] No separate login required

---

## Phase 3: Workflow Discovery & Execution (Days 4-5)

### Objective
Enable users to discover existing flows and execute them for campaigns.

### Tasks

#### 3.1 Create Flow Browser API Endpoint

**File:** `production-backend/app/routers/langflow_flows.py`

```python
from fastapi import APIRouter, Depends
from sqlalchemy import text
from app.database import get_db
from app.auth import get_current_user

router = APIRouter(prefix="/api/v1/langflow", tags=["langflow"])

@router.get("/flows")
async def list_tenant_flows(
    db = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """List all Langflow flows for the current tenant"""

    query = text("""
        SELECT
            f.id,
            f.name,
            f.description,
            f.data,
            f.updated_at,
            f.folder_id,
            folder.name as folder_name
        FROM langflow.flow f
        LEFT JOIN langflow.folder ON folder.id = f.folder_id
        WHERE f.tenant_id = :tenant_id
        ORDER BY f.updated_at DESC
    """)

    result = db.execute(query, {"tenant_id": str(current_user.tenant_id)})
    flows = [dict(row._mapping) for row in result]

    return {"flows": flows}


@router.get("/folders")
async def list_tenant_folders(
    db = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """List all Langflow folders for the current tenant"""

    query = text("""
        SELECT
            id,
            name,
            description,
            parent_id,
            created_at
        FROM langflow.folder
        WHERE tenant_id = :tenant_id
        ORDER BY name
    """)

    result = db.execute(query, {"tenant_id": str(current_user.tenant_id)})
    folders = [dict(row._mapping) for row in result]

    return {"folders": folders}


@router.post("/flows/{flow_id}/execute")
async def execute_flow(
    flow_id: str,
    campaign_id: str,
    db = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Execute a Langflow flow for a specific campaign"""

    # Call Langflow API to execute flow
    import httpx

    langflow_url = os.getenv("LANGFLOW_URL", "https://langflow.engarde.media")

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{langflow_url}/api/v1/run/{flow_id}",
            json={
                "input_value": campaign_id,
                "input_type": "campaign",
                "tenant_id": str(current_user.tenant_id)
            },
            headers={
                "Authorization": f"Bearer {current_user.token}"
            }
        )

        return response.json()
```

#### 3.2 Create Flow Browser UI Component

**File:** `production-frontend/components/langflow/FlowBrowser.tsx`

```typescript
'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/hooks/useAuth';

interface Flow {
  id: string;
  name: string;
  description: string;
  folder_name: string;
  updated_at: string;
}

export default function FlowBrowser() {
  const { user } = useAuth();
  const [flows, setFlows] = useState<Flow[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadFlows() {
      try {
        const response = await fetch('/api/v1/langflow/flows', {
          headers: {
            'Authorization': `Bearer ${user?.token}`
          }
        });

        const data = await response.json();
        setFlows(data.flows);
      } catch (error) {
        console.error('Failed to load flows:', error);
      } finally {
        setLoading(false);
      }
    }

    if (user) {
      loadFlows();
    }
  }, [user]);

  return (
    <div className="p-6">
      <h2 className="text-2xl font-bold mb-4">Available Workflows</h2>

      {loading ? (
        <div>Loading workflows...</div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {flows.map((flow) => (
            <div key={flow.id} className="border rounded-lg p-4 hover:shadow-lg transition">
              <h3 className="font-semibold text-lg">{flow.name}</h3>
              <p className="text-sm text-gray-600 mt-2">{flow.description}</p>
              <div className="mt-4 flex items-center justify-between">
                <span className="text-xs text-gray-500">{flow.folder_name}</span>
                <button
                  className="btn btn-primary btn-sm"
                  onClick={() => handleExecuteFlow(flow.id)}
                >
                  Run Workflow
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
```

**Success Criteria:**
- [ ] API endpoint returns flows filtered by tenant_id
- [ ] Users can browse their flows in EnGarde dashboard
- [ ] Flows are organized by folders
- [ ] Users can execute flows from EnGarde UI

---

## Phase 4: Walker Agent Integration (Days 6-7)

### Objective
Connect existing Walker Agent components to EnGarde campaigns.

### Tasks

#### 4.1 Verify Custom Components are Loaded

Check that custom components exist in Langflow:

```bash
# SSH into Railway container or check logs
railway logs --service langflow-server | grep "Loaded.*components"

# Should see:
# Loaded 351 components (including custom components from /app/components/engarde_components)
```

#### 4.2 Create Campaign → Flow Association

**Database Migration:**

```sql
-- Add langflow_flow_id to campaigns table
ALTER TABLE public.campaigns
ADD COLUMN IF NOT EXISTS langflow_flow_id UUID;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_campaigns_langflow_flow_id
ON public.campaigns(langflow_flow_id);
```

**Backend Model Update:**

```python
# File: production-backend/app/models/campaign.py

class Campaign(Base):
    __tablename__ = "campaigns"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    # ... existing fields ...
    langflow_flow_id = Column(UUID(as_uuid=True), nullable=True)
```

#### 4.3 Create Walker Agent Execution Endpoint

**File:** `production-backend/app/routers/walker_agents.py`

```python
@router.post("/campaigns/{campaign_id}/run-walker-agent")
async def run_walker_agent_for_campaign(
    campaign_id: UUID,
    agent_type: str,  # "seo", "content", "paid_ads", "audience"
    db = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Execute a Walker Agent workflow for a campaign"""

    # Get campaign
    campaign = db.query(Campaign).filter(
        Campaign.id == campaign_id,
        Campaign.tenant_id == current_user.tenant_id
    ).first()

    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")

    # Map agent type to flow ID
    agent_flow_mapping = {
        "seo": os.getenv("WALKER_AGENT_FLOW_ID_SEO"),
        "content": os.getenv("WALKER_AGENT_FLOW_ID_CONTENT"),
        "paid_ads": os.getenv("WALKER_AGENT_FLOW_ID_PAID_ADS"),
        "audience": os.getenv("WALKER_AGENT_FLOW_ID_AUDIENCE")
    }

    flow_id = agent_flow_mapping.get(agent_type)
    if not flow_id:
        raise HTTPException(status_code=400, detail="Invalid agent type")

    # Execute flow via Langflow API
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{LANGFLOW_URL}/api/v1/run/{flow_id}",
            json={
                "input_value": str(campaign_id),
                "campaign_data": {
                    "id": str(campaign.id),
                    "name": campaign.name,
                    "description": campaign.description,
                    "target_audience": campaign.target_audience,
                    "platforms": campaign.platforms
                },
                "tenant_id": str(current_user.tenant_id)
            },
            headers={
                "Authorization": f"Bearer {WALKER_AGENT_API_KEYS[agent_type]}"
            },
            timeout=120.0
        )

        return response.json()
```

**Success Criteria:**
- [ ] Custom Walker Agent components visible in Langflow UI
- [ ] Can create flows using Walker Agent components
- [ ] EnGarde campaigns can trigger Walker Agent flows
- [ ] Results returned to EnGarde backend

---

## Phase 5: Results Display & Analytics (Days 8-9)

### Objective
Show Walker Agent results and flow execution history in EnGarde.

### Tasks

#### 5.1 Create Execution History API

**File:** `production-backend/app/routers/langflow_flows.py`

```python
@router.get("/campaigns/{campaign_id}/walker-agent-history")
async def get_walker_agent_history(
    campaign_id: UUID,
    db = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get Walker Agent execution history for a campaign"""

    query = text("""
        SELECT
            t.id,
            t.flow_id,
            f.name as flow_name,
            t.timestamp,
            t.inputs,
            t.outputs,
            EXTRACT(EPOCH FROM (t.updated_at - t.created_at)) as duration_seconds
        FROM langflow.transaction t
        JOIN langflow.flow f ON f.id = t.flow_id
        WHERE t.inputs::text LIKE :campaign_pattern
        AND f.tenant_id = :tenant_id
        ORDER BY t.timestamp DESC
        LIMIT 50
    """)

    result = db.execute(query, {
        "campaign_pattern": f"%{campaign_id}%",
        "tenant_id": str(current_user.tenant_id)
    })

    executions = [dict(row._mapping) for row in result]

    return {"executions": executions}
```

#### 5.2 Create Execution History UI Component

**File:** `production-frontend/components/campaigns/WalkerAgentHistory.tsx`

```typescript
interface Execution {
  id: string;
  flow_name: string;
  timestamp: string;
  duration_seconds: number;
  outputs: any;
}

export default function WalkerAgentHistory({ campaignId }: { campaignId: string }) {
  const [executions, setExecutions] = useState<Execution[]>([]);

  useEffect(() => {
    async function loadHistory() {
      const response = await fetch(
        `/api/v1/langflow/campaigns/${campaignId}/walker-agent-history`
      );
      const data = await response.json();
      setExecutions(data.executions);
    }

    loadHistory();
  }, [campaignId]);

  return (
    <div className="mt-8">
      <h3 className="text-xl font-semibold mb-4">AI Agent Analysis History</h3>

      <div className="space-y-4">
        {executions.map((execution) => (
          <div key={execution.id} className="border rounded-lg p-4">
            <div className="flex justify-between items-start">
              <div>
                <h4 className="font-medium">{execution.flow_name}</h4>
                <p className="text-sm text-gray-500">
                  {new Date(execution.timestamp).toLocaleString()}
                </p>
              </div>
              <span className="text-sm text-gray-600">
                {execution.duration_seconds.toFixed(1)}s
              </span>
            </div>

            <div className="mt-3">
              <h5 className="text-sm font-medium mb-2">Suggestions:</h5>
              <div className="bg-gray-50 p-3 rounded text-sm">
                {JSON.stringify(execution.outputs, null, 2)}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
```

**Success Criteria:**
- [ ] Can view execution history for each campaign
- [ ] Walker Agent suggestions displayed in EnGarde
- [ ] Execution time and status tracked
- [ ] Results formatted for user readability

---

## Phase 6: User Onboarding & Documentation (Day 10)

### Objective
Create user-facing documentation and onboarding flow.

### Tasks

#### 6.1 Create In-App Tutorial

**File:** `production-frontend/components/onboarding/AgentSuiteTutorial.tsx`

```typescript
export default function AgentSuiteTutorial() {
  const steps = [
    {
      title: "Welcome to Agent Suite",
      description: "Build AI-powered workflows for your campaigns using visual drag-and-drop interface.",
      image: "/tutorials/agent-suite-welcome.png"
    },
    {
      title: "Walker Agents",
      description: "Pre-built AI agents analyze your campaigns and provide actionable suggestions.",
      image: "/tutorials/walker-agents.png"
    },
    {
      title: "Create Your First Workflow",
      description: "Combine components to create custom automation for your marketing needs.",
      image: "/tutorials/create-workflow.png"
    }
  ];

  return <TutorialCarousel steps={steps} />;
}
```

#### 6.2 Create User Documentation

**File:** `docs/user-guides/AGENT_SUITE_USER_GUIDE.md`

```markdown
# EnGarde Agent Suite - User Guide

## What is Agent Suite?

Agent Suite is your AI-powered workflow builder for marketing campaigns. Create custom automation using pre-built Walker Agents or build your own workflows.

## Quick Start

### 1. Access Agent Suite
- Navigate to "Agent Suite" in the left sidebar
- You'll be automatically logged in (no separate password needed)

### 2. Browse Available Workflows
- View pre-built workflows in the "Flows" tab
- Organized by folders: SEO, Content, Paid Ads, Audience

### 3. Run a Walker Agent
- Click on any workflow to view details
- Click "Run" to analyze your campaign
- View results in the campaign dashboard

## Available Walker Agents

### SEO Walker Agent
Analyzes your campaign content for SEO optimization opportunities.

**What it does:**
- Keyword analysis
- Content gap identification
- Meta description suggestions
- Title optimization

### Content Walker Agent
Reviews your content strategy and suggests improvements.

**What it does:**
- Content calendar analysis
- Topic suggestions
- Engagement predictions
- Platform-specific recommendations

### Paid Ads Walker Agent
Optimizes your paid advertising campaigns.

**What it does:**
- Budget allocation recommendations
- Ad copy suggestions
- Targeting optimization
- ROI projections

### Audience Intelligence Walker Agent
Analyzes your target audience and provides insights.

**What it does:**
- Audience segmentation
- Demographic analysis
- Behavior patterns
- Engagement predictions

## Creating Custom Workflows

### Step 1: Create a New Flow
1. Click "New Flow" button
2. Give your flow a name and description
3. Select a folder to organize it

### Step 2: Add Components
1. Drag components from the left panel
2. Connect components with arrows
3. Configure each component's settings

### Step 3: Save and Run
1. Click "Save" to preserve your workflow
2. Click "Run" to execute
3. View results in the output panel

## Tips & Best Practices

- **Start Simple:** Use pre-built Walker Agents before creating custom workflows
- **Test Incrementally:** Run workflows on test campaigns first
- **Review Results:** Always review AI suggestions before applying them
- **Organize Flows:** Use folders to keep workflows organized by purpose

## Troubleshooting

**Q: I can't see any workflows**
A: Make sure you've selected your account tenant in the dropdown

**Q: Workflow execution failed**
A: Check the execution logs in the flow details panel

**Q: How do I share a workflow with my team?**
A: Workflows are automatically shared with all users in your organization

## Support

Need help? Contact support@engarde.media or visit our [Help Center](https://help.engarde.media)
```

**Success Criteria:**
- [ ] Tutorial appears on first Agent Suite visit
- [ ] User guide accessible from help menu
- [ ] Video tutorials created and embedded
- [ ] FAQ section answers common questions

---

## Implementation Timeline

| Phase | Duration | Dependencies | Deliverable |
|-------|----------|-------------|-------------|
| Phase 1: SSO Verification | Day 1 | None | SSO working end-to-end |
| Phase 2: Frontend Integration | Days 2-3 | Phase 1 | Agent Suite page in EnGarde |
| Phase 3: Workflow Discovery | Days 4-5 | Phase 2 | Flow browser and execution |
| Phase 4: Walker Agent Integration | Days 6-7 | Phase 3 | Campaign → Flow association |
| Phase 5: Results Display | Days 8-9 | Phase 4 | Execution history UI |
| Phase 6: Documentation | Day 10 | All phases | User guide and tutorials |

**Total Duration:** 10 business days (2 weeks)

---

## Testing & Validation

### Test Scenarios

#### Scenario 1: First-Time User
1. User logs into EnGarde
2. Clicks "Agent Suite" in navigation
3. SSO authenticates automatically
4. Langflow loads with user's flows
5. User runs SEO Walker Agent on a campaign
6. Results appear in campaign dashboard

**Expected Result:** ✅ Seamless experience, no manual login

#### Scenario 2: Workflow Execution
1. User selects a campaign
2. Clicks "Run AI Analysis"
3. Selects "SEO Walker Agent"
4. Workflow executes in Langflow
5. Results returned to EnGarde
6. Suggestions displayed in UI

**Expected Result:** ✅ Results within 30 seconds

#### Scenario 3: Multi-Tenant Isolation
1. User A from Tenant A logs in
2. Views their flows in Agent Suite
3. User B from Tenant B logs in
4. Views their flows in Agent Suite

**Expected Result:** ✅ Each user only sees their tenant's flows

---

## Success Metrics

### Key Performance Indicators (KPIs)

1. **Adoption Rate**
   - Target: 70% of active users access Agent Suite within first month
   - Measure: Unique users accessing `/agent-suite` page

2. **Workflow Execution Rate**
   - Target: 50 workflow executions per day (average)
   - Measure: Count of `langflow.transaction` records per day

3. **User Satisfaction**
   - Target: 4.5/5 star rating for Agent Suite
   - Measure: In-app feedback survey

4. **Time to Value**
   - Target: Users get first AI suggestion within 5 minutes
   - Measure: Time from first login to first workflow execution

5. **Error Rate**
   - Target: <2% workflow execution failures
   - Measure: Failed transactions / total transactions

---

## Rollout Strategy

### Phase 1: Internal Beta (Week 1)
- **Audience:** EnGarde team members only
- **Goal:** Identify bugs and UX issues
- **Success Criteria:**
  - Zero critical bugs
  - Positive feedback from team
  - All test scenarios pass

### Phase 2: Limited Beta (Week 2)
- **Audience:** 10-20 select customers
- **Goal:** Validate with real users
- **Success Criteria:**
  - 80% users successfully run a workflow
  - <5% error rate
  - Positive feedback

### Phase 3: General Availability (Week 3)
- **Audience:** All EnGarde users
- **Announcement:** Email campaign + in-app notification
- **Success Criteria:**
  - 50% of target users access Agent Suite
  - Adoption metrics meet targets

---

## Monitoring & Support

### Monitoring Dashboard

Create Grafana dashboard to track:

1. **Usage Metrics**
   - Daily active users in Agent Suite
   - Workflow executions per day
   - Average execution time

2. **Error Metrics**
   - SSO failure rate
   - Workflow execution failures
   - API errors

3. **Performance Metrics**
   - Page load time
   - API response time
   - Database query performance

### Support Runbook

**Issue: SSO not working**
```bash
# Check Langflow logs
railway logs --service langflow-server | grep "sso_login"

# Verify shared secret matches
railway variables --service langflow-server | grep LANGFLOW_SECRET_KEY
railway variables --service main | grep LANGFLOW_SECRET_KEY

# Test JWT generation
curl -X POST https://api.engarde.media/api/v1/sso/langflow \
  -H "Authorization: Bearer <token>"
```

**Issue: Components not loading**
```bash
# Check components directory
railway run --service langflow-server ls -la /app/components/engarde_components

# Check component loading logs
railway logs --service langflow-server | grep "Loaded.*components"
```

**Issue: Workflow execution failing**
```sql
-- Check recent failed executions
SELECT
    id,
    flow_id,
    timestamp,
    error
FROM langflow.transaction
WHERE status = 'error'
ORDER BY timestamp DESC
LIMIT 10;
```

---

## Next Steps

Once this plan is implemented:

1. **Analytics Integration**
   - Track which Walker Agents are most used
   - Measure impact on campaign performance
   - A/B test AI suggestions vs manual work

2. **Advanced Features**
   - Scheduled workflow execution
   - Multi-step approval workflows
   - Custom component marketplace

3. **Platform Expansion**
   - Mobile app integration
   - API access for third-party tools
   - Webhook integrations

---

## Appendix: Database Schema Reference

### Existing Tables (Already Created)

```sql
-- Langflow schema tables
langflow.user          -- SSO-created users
langflow.flow          -- Workflow definitions
langflow.folder        -- Flow organization
langflow.transaction   -- Execution history
langflow.message       -- Chat/conversation logs
langflow.variables     -- User-defined variables

-- Public schema tables (EnGarde)
public.campaigns       -- Marketing campaigns
public.users           -- EnGarde users
public.tenants         -- Multi-tenant organizations
```

### Row-Level Security (RLS) Policies

**Already Applied:**
```sql
-- Tenant isolation on flows
CREATE POLICY tenant_isolation_flows ON langflow.flow
FOR ALL
USING (tenant_id = current_setting('app.current_tenant_id')::uuid);

-- Tenant isolation on transactions
CREATE POLICY tenant_isolation_transactions ON langflow.transaction
FOR ALL
USING (tenant_id = current_setting('app.current_tenant_id')::uuid);
```

---

**Document Owner:** EnGarde Development Team
**Last Updated:** January 11, 2026
**Status:** Ready for Implementation
