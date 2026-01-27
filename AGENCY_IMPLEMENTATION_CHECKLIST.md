# Agency Multi-Client Management - Implementation Checklist

## 🎯 Implementation Order: A → B → C

**CRITICAL**: Must follow `ENGARDE_DEVELOPMENT_RULES.md` and `DATA_RETRIEVAL_RULES.md`

---

## OPTION A: Complete Team Management UI (Priority 1)

### Backend Prerequisites ✅
- [x] GET `/api/workspaces/current/members/{member_id}/permissions` - Implemented
- [x] PUT `/api/workspaces/current/members/{member_id}/permissions` - Implemented
- [x] GET `/api/workspaces/current/brands` - Implemented
- [x] Permission structure defined
- [x] Backend deployed to Railway

### Frontend Tasks - Team Member Edit Modal

#### A1. Create Team Member Edit Modal Component
**File**: `/Users/cope/EnGardeHQ/production-frontend/app/team/components/EditMemberModal.tsx`

**Requirements**:
- [ ] Create new file `EditMemberModal.tsx`
- [ ] Import Chakra UI components: Modal, ModalOverlay, ModalContent, ModalHeader, ModalBody, ModalFooter, ModalCloseButton
- [ ] Import form components: FormControl, FormLabel, Select, Switch, Checkbox, CheckboxGroup, VStack, HStack
- [ ] Use `useQuery` from `@tanstack/react-query` for data fetching (per DATA_RETRIEVAL_RULES.md)
- [ ] Use `apiClient` from `@/lib/api/client` for API calls (per DATA_RETRIEVAL_RULES.md)

**Component Structure**:
```typescript
interface EditMemberModalProps {
  isOpen: boolean
  onClose: () => void
  memberId: string
  onSuccess: () => void
}

export function EditMemberModal({ isOpen, onClose, memberId, onSuccess }: EditMemberModalProps) {
  // Fetch member permissions
  const { data: memberData, isLoading } = useQuery({
    queryKey: ['member-permissions', memberId],
    queryFn: async () => {
      const response = await apiClient.get(`/workspaces/current/members/${memberId}/permissions`)
      return response.data
    },
    enabled: isOpen && !!memberId
  })

  // Fetch available brands
  const { data: brands } = useQuery({
    queryKey: ['workspace-brands'],
    queryFn: async () => {
      const response = await apiClient.get('/workspaces/current/brands')
      return response.data
    },
    enabled: isOpen
  })

  // Update mutation
  const updateMutation = useMutation({
    mutationFn: async (updates) => {
      const response = await apiClient.put(
        `/workspaces/current/members/${memberId}/permissions`,
        updates
      )
      return response.data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['team-members'] })
      onSuccess()
      onClose()
    }
  })

  // Form state
  const [workspaceRole, setWorkspaceRole] = useState('')
  const [selectedBrands, setSelectedBrands] = useState<{brand_id: string, role: string}[]>([])

  // Render modal with sections
}
```

**Sections to Include**:
1. **Workspace Role Section**
   - Select dropdown: owner, admin, editor, viewer
   - Description of each role

2. **Brand Access Section**
   - Checkbox list of all brands
   - Role dropdown per selected brand (owner, admin, member, viewer)

3. **Admin Permissions Section** (only if role = admin or owner)
   - Switch: Can manage billing (owner only)
   - Switch: Can manage API keys
   - Switch: Can set budgets
   - Switch: Can invite members
   - Switch: Can remove members (owner only)
   - Switch: Can upgrade plan (owner only)

#### A2. Integrate Modal into Team Page
**File**: `/Users/cope/EnGardeHQ/production-frontend/app/team/page.tsx`

- [ ] Import `EditMemberModal` component
- [ ] Add state for selected member: `const [editingMember, setEditingMember] = useState<string | null>(null)`
- [ ] Add modal: `<EditMemberModal isOpen={!!editingMember} onClose={() => setEditingMember(null)} memberId={editingMember} onSuccess={() => refetch()} />`
- [ ] Update "Change Role" menu item to: `onClick={() => setEditingMember(member.id)}`
- [ ] Add "Manage Permissions" menu item: `onClick={() => setEditingMember(member.id)}`

#### A3. Add Brand Access Column to Team Table
**File**: `/Users/cope/EnGardeHQ/production-frontend/app/team/page.tsx`

- [ ] Fetch brand access for each member (already in `/api/workspaces/current/members/{id}/permissions`)
- [ ] Add new table column: `<Th>Brand Access</Th>`
- [ ] Display brand badges: `<HStack>{member.brand_access?.map(ba => <Badge key={ba.brand_id}>{ba.brand_name}</Badge>)}</HStack>`
- [ ] Add tooltip showing brand role on hover

#### A4. Create Permission Badge Components
**File**: `/Users/cope/EnGardeHQ/production-frontend/app/team/components/PermissionBadges.tsx`

- [ ] Create `PermissionBadge` component
- [ ] Props: `{ permission: string, enabled: boolean }`
- [ ] Display icon + text for each permission
- [ ] Show checkmark if enabled, X if disabled
- [ ] Use Chakra UI Badge with conditional colorScheme

#### A5. Add Role Descriptions
**File**: `/Users/cope/EnGardeHQ/production-frontend/app/team/components/RoleDescriptions.tsx`

- [ ] Create component with role explanations
- [ ] **Owner**: Full access to everything including billing and team management
- [ ] **Admin**: Can manage team, budgets, API keys (no billing or workspace deletion)
- [ ] **Editor**: Can edit campaigns and content (no admin access)
- [ ] **Viewer**: Read-only access to workspace

#### A6. Testing Checklist
- [ ] Test opening edit modal for existing member
- [ ] Test changing workspace role
- [ ] Test adding brand access
- [ ] Test removing brand access
- [ ] Test changing brand-specific roles
- [ ] Test permission toggles update correctly
- [ ] Test owner-only permissions are disabled for non-owners
- [ ] Test API call success/error handling
- [ ] Test modal closes on success
- [ ] Test table updates after save

---

## OPTION B: Agency Admin Cross-Client Management (Priority 2)

### Backend Tasks

#### B1. Create Agency Admin Middleware
**File**: `/Users/cope/EnGardeHQ/production-backend/app/routers/agency_admin.py` (NEW)

- [ ] Create new router file
- [ ] Add dependency `get_agency_admin_user()`:
  ```python
  def get_agency_admin_user(
      current_user: User = Depends(get_current_user),
      db: Session = Depends(get_db)
  ) -> tuple[User, Organization]:
      """Verify user is agency admin and return user + organization"""
      membership = db.query(OrganizationMember).filter(
          OrganizationMember.user_id == current_user.id,
          OrganizationMember.role.in_(['owner', 'admin'])
      ).first()

      if not membership:
          raise HTTPException(403, "User is not an agency admin")

      org = db.query(Organization).filter(
          Organization.id == membership.organization_id,
          Organization.org_type == 'agency'
      ).first()

      if not org:
          raise HTTPException(404, "Agency organization not found")

      return current_user, org
  ```

#### B2. Client Workspace Management Endpoints
**File**: `/Users/cope/EnGardeHQ/production-backend/app/routers/agency_admin.py`

**Endpoint 1**: List Client Workspaces
- [ ] `GET /api/agency/clients/{client_id}/workspaces`
- [ ] Verify client belongs to agency
- [ ] Return all workspaces for client tenant
- [ ] Include member counts per workspace

```python
@router.get("/clients/{client_id}/workspaces")
async def list_client_workspaces(
    client_id: str,
    admin_user_org: tuple = Depends(get_agency_admin_user),
    db: Session = Depends(get_db)
):
    """List all workspaces for a client tenant"""
    user, org = admin_user_org

    # Verify client belongs to agency
    client = db.query(Tenant).filter(
        Tenant.id == client_id,
        Tenant.organization_id == org.id
    ).first()

    if not client:
        raise HTTPException(404, "Client not found")

    # Get workspaces
    workspaces = db.query(Workspace).filter(
        Workspace.tenant_id == client_id,
        Workspace.is_active == '1'
    ).all()

    result = []
    for ws in workspaces:
        member_count = db.query(WorkspaceMember).filter(
            WorkspaceMember.workspace_id == ws.id
        ).count()

        result.append({
            "id": ws.id,
            "name": ws.name,
            "description": ws.description,
            "member_count": member_count,
            "created_at": ws.created_at
        })

    return result
```

**Endpoint 2**: Create Client Workspace
- [ ] `POST /api/agency/clients/{client_id}/workspaces`
- [ ] Create new workspace for client
- [ ] Optionally add team members

**Endpoint 3**: Get Client Workspace Members
- [ ] `GET /api/agency/clients/{client_id}/workspaces/{workspace_id}/members`
- [ ] Return all members with brand access
- [ ] Include permission details

**Endpoint 4**: Update Client Workspace Member
- [ ] `PUT /api/agency/clients/{client_id}/workspaces/{workspace_id}/members/{member_id}`
- [ ] Update workspace role
- [ ] Update brand access
- [ ] Agency admin override

#### B3. Client Brand Management Endpoints
**File**: `/Users/cope/EnGardeHQ/production-backend/app/routers/agency_admin.py`

**Endpoint**: List Client Brands
- [ ] `GET /api/agency/clients/{client_id}/brands`
- [ ] Return all brands for client tenant
- [ ] Include brand member counts

```python
@router.get("/clients/{client_id}/brands")
async def list_client_brands(
    client_id: str,
    admin_user_org: tuple = Depends(get_agency_admin_user),
    db: Session = Depends(get_db)
):
    """List all brands for a client"""
    user, org = admin_user_org

    # Verify client
    client = db.query(Tenant).filter(
        Tenant.id == client_id,
        Tenant.organization_id == org.id
    ).first()

    if not client:
        raise HTTPException(404, "Client not found")

    # Get brands
    brands = db.query(Brand).filter(
        Brand.tenant_id == client_id,
        Brand.is_active == True
    ).all()

    result = []
    for brand in brands:
        member_count = db.query(BrandMember).filter(
            BrandMember.brand_id == brand.id,
            BrandMember.is_active == True
        ).count()

        result.append({
            "id": brand.id,
            "name": brand.name,
            "logo_url": brand.logo_url,
            "member_count": member_count
        })

    return result
```

#### B4. Register Agency Admin Router
**File**: `/Users/cope/EnGardeHQ/production-backend/app/main.py`

- [ ] Import: `from app.routers import agency_admin`
- [ ] Add: `app.include_router(agency_admin.router)`

#### B5. Testing Backend Endpoints
- [ ] Test agency admin can list client workspaces
- [ ] Test agency admin can create workspace for client
- [ ] Test agency admin can view client workspace members
- [ ] Test agency admin can update member permissions
- [ ] Test non-agency users get 403 errors
- [ ] Test cross-client access is properly restricted

### Frontend Tasks

#### B6. Create Agency Client Dashboard
**File**: `/Users/cope/EnGardeHQ/production-frontend/app/agency/clients/page.tsx`

- [ ] Create agency dashboard page
- [ ] Use `useQuery` to fetch: `GET /api/agency/clients`
- [ ] Display client cards in grid
- [ ] Show client name, workspace count, member count
- [ ] Add "Manage" button per client

#### B7. Create Client Detail View
**File**: `/Users/cope/EnGardeHQ/production-frontend/app/agency/clients/[clientId]/page.tsx`

- [ ] Dynamic route for client detail
- [ ] Fetch client workspaces: `GET /api/agency/clients/{clientId}/workspaces`
- [ ] Fetch client brands: `GET /api/agency/clients/{clientId}/brands`
- [ ] Display workspace list with member counts
- [ ] Display brand list with access counts
- [ ] Add "Manage Team" button per workspace

#### B8. Create Cross-Client Team Manager
**File**: `/Users/cope/EnGardeHQ/production-frontend/app/agency/clients/[clientId]/workspaces/[workspaceId]/team/page.tsx`

- [ ] Fetch workspace members: `GET /api/agency/clients/{clientId}/workspaces/{workspaceId}/members`
- [ ] Reuse `EditMemberModal` component
- [ ] Add "Agency Admin" badge to UI
- [ ] Show which agency admin is making changes
- [ ] Audit log display (future)

#### B9. Add Agency Navigation
**File**: `/Users/cope/EnGardeHQ/production-frontend/components/layout/sidebar-nav.tsx`

- [ ] Add "Agency Dashboard" link (only for agency users)
- [ ] Check user organization type: `state.user?.organization?.org_type === 'agency'`
- [ ] Add icon and route to agency pages

#### B10. Testing Frontend
- [ ] Test agency dashboard loads
- [ ] Test client list displays correctly
- [ ] Test client detail page shows workspaces and brands
- [ ] Test cross-client team management works
- [ ] Test navigation between clients
- [ ] Test agency admin indicator displays

---

## OPTION C: Langflow Context Switching (Priority 3)

⚠️ **CRITICAL**: Do NOT modify Langflow container startup. Only modify main backend service.

### Backend Tasks

#### C1. Add Workspace Context to JWT Claims
**File**: `/Users/cope/EnGardeHQ/production-backend/app/routers/langflow_sso.py`

- [ ] Add `workspace_id` parameter to JWT payload generation
- [ ] Add `brand_id` parameter to JWT payload (optional)
- [ ] Modify existing JWT creation (around line 260-275):

```python
# EXISTING CODE - DO NOT CHANGE STRUCTURE, ONLY ADD FIELDS
payload = {
    "email": langflow_email,
    "sub": langflow_user_id,
    "tenant_id": tenant_id or "staging",
    "tenant_name": tenant_name,
    "role": user_role,
    "subscription_tier": subscription_tier,
    # NEW FIELDS - ADD THESE
    "workspace_id": workspace_id,  # From request or current workspace
    "workspace_name": workspace_name,  # For display
    "brand_id": brand_id,  # Currently active brand
    "brand_name": brand_name,  # For display
    # KEEP EXISTING FIELDS
    "exp": datetime.utcnow() + timedelta(minutes=5),
    "iat": datetime.utcnow(),
    "is_owner": is_owner,
    "actual_user_email": actual_user_email if not is_owner else None,
    "actual_user_id": str(current_user.id) if not is_owner else None,
}
```

#### C2. Create Context Switch Endpoint
**File**: `/Users/cope/EnGardeHQ/production-backend/app/routers/langflow_context.py` (NEW)

- [ ] Create new router file
- [ ] Add endpoint for context switching:

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from app.database import get_db
from app.routers.auth import get_current_user
from app.models import User

router = APIRouter(prefix="/api/langflow", tags=["langflow"])

class ContextSwitchRequest(BaseModel):
    tenant_id: str
    workspace_id: Optional[str] = None
    brand_id: Optional[str] = None

@router.post("/switch-context")
async def switch_langflow_context(
    context: ContextSwitchRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Switch Langflow workspace context.
    Returns updated JWT for Langflow with new tenant/workspace/brand context.
    """
    from app.models.core import TenantUser, Tenant
    from app.models.workspace_models import Workspace, WorkspaceMember
    from app.models.brand_models import Brand, BrandMember

    # Verify user has access to tenant
    tenant_user = db.query(TenantUser).filter(
        TenantUser.user_id == current_user.id,
        TenantUser.tenant_id == context.tenant_id
    ).first()

    if not tenant_user:
        # Check if agency admin
        from app.models.core import OrganizationMember, Organization
        org_member = db.query(OrganizationMember).filter(
            OrganizationMember.user_id == current_user.id
        ).first()

        if org_member:
            org = db.query(Organization).filter(
                Organization.id == org_member.organization_id
            ).first()

            if org and org.org_type == 'agency':
                # Verify tenant belongs to agency
                tenant = db.query(Tenant).filter(
                    Tenant.id == context.tenant_id,
                    Tenant.organization_id == org.id
                ).first()

                if not tenant:
                    raise HTTPException(403, "Access denied to this tenant")
            else:
                raise HTTPException(403, "Access denied to this tenant")
        else:
            raise HTTPException(403, "Access denied to this tenant")

    # Get workspace details if provided
    workspace_name = None
    if context.workspace_id:
        workspace = db.query(Workspace).filter(
            Workspace.id == context.workspace_id,
            Workspace.tenant_id == context.tenant_id
        ).first()

        if workspace:
            workspace_name = workspace.name

    # Get brand details if provided
    brand_name = None
    if context.brand_id:
        brand = db.query(Brand).filter(
            Brand.id == context.brand_id,
            Brand.tenant_id == context.tenant_id
        ).first()

        if brand:
            brand_name = brand.name

    # Generate new Langflow JWT with updated context
    # Import and call existing JWT generation from langflow_sso
    from app.routers.langflow_sso import generate_langflow_jwt

    jwt_token = generate_langflow_jwt(
        user=current_user,
        tenant_id=context.tenant_id,
        workspace_id=context.workspace_id,
        workspace_name=workspace_name,
        brand_id=context.brand_id,
        brand_name=brand_name,
        db=db
    )

    return {
        "jwt": jwt_token,
        "context": {
            "tenant_id": context.tenant_id,
            "workspace_id": context.workspace_id,
            "workspace_name": workspace_name,
            "brand_id": context.brand_id,
            "brand_name": brand_name
        }
    }

@router.get("/current-context")
async def get_current_langflow_context(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current Langflow context for user"""
    from app.models.core import TenantUser

    tenant_user = db.query(TenantUser).filter(
        TenantUser.user_id == current_user.id
    ).first()

    if not tenant_user:
        return {"tenant_id": None, "workspace_id": None, "brand_id": None}

    # Return current context (from session or defaults)
    return {
        "tenant_id": tenant_user.tenant_id,
        "workspace_id": None,  # TODO: Get from session
        "brand_id": None  # TODO: Get from session
    }
```

#### C3. Extract JWT Generation to Reusable Function
**File**: `/Users/cope/EnGardeHQ/production-backend/app/routers/langflow_sso.py`

- [ ] Extract JWT creation logic to function `generate_langflow_jwt()`
- [ ] Add parameters: `workspace_id`, `workspace_name`, `brand_id`, `brand_name`
- [ ] Update existing SSO endpoint to call this function
- [ ] Keep all existing logic unchanged (team member workspace sharing, owner detection, etc.)

#### C4. Update Agency Client Switch to Include Langflow Context
**File**: `/Users/cope/EnGardeHQ/production-backend/app/routers/agency.py`

- [ ] Modify `/api/agency/clients/{client_id}/switch` endpoint
- [ ] Include Langflow JWT in response:

```python
@router.post("/clients/{client_id}/switch")
def switch_client(
    client_id: str,
    org: Organization = Depends(get_current_agency_org),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # ... existing verification code ...

    # Generate Langflow JWT for new client context
    from app.routers.langflow_sso import generate_langflow_jwt

    langflow_jwt = generate_langflow_jwt(
        user=current_user,
        tenant_id=client.id,
        workspace_id=None,  # Will be set when workspace selected
        workspace_name=None,
        brand_id=None,
        brand_name=None,
        db=db
    )

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "expires_in": ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        "user": user_data,
        "langflow_context": {
            "jwt": langflow_jwt,
            "tenant_id": client.id
        }
    }
```

#### C5. Register Langflow Context Router
**File**: `/Users/cope/EnGardeHQ/production-backend/app/main.py`

- [ ] Import: `from app.routers import langflow_context`
- [ ] Add: `app.include_router(langflow_context.router)`

#### C6. Testing Backend
- [ ] Test context switch endpoint returns valid JWT
- [ ] Test JWT includes workspace_id and brand_id
- [ ] Test agency admin can switch to client context
- [ ] Test client switch includes Langflow JWT
- [ ] Test JWT expiry (5 minutes)

### Frontend Tasks

#### C7. Create Langflow Context Provider
**File**: `/Users/cope/EnGardeHQ/production-frontend/contexts/LangflowContext.tsx`

- [ ] Create React Context for Langflow state
- [ ] Store: current JWT, tenant_id, workspace_id, brand_id
- [ ] Methods: `switchContext(tenant, workspace?, brand?)`
- [ ] Auto-refresh JWT before expiry (4 minutes)

```typescript
interface LangflowContextType {
  jwt: string | null
  tenantId: string | null
  workspaceId: string | null
  brandId: string | null
  switchContext: (params: SwitchContextParams) => Promise<void>
  isLoading: boolean
}

export const LangflowContext = createContext<LangflowContextType>(...)

export function LangflowProvider({ children }) {
  const [jwt, setJwt] = useState<string | null>(null)
  const [context, setContext] = useState({...})

  const switchContext = async (params) => {
    const response = await apiClient.post('/langflow/switch-context', params)
    setJwt(response.data.jwt)
    setContext(response.data.context)
  }

  // Auto-refresh JWT
  useEffect(() => {
    if (!jwt) return

    const timer = setTimeout(() => {
      switchContext(context) // Refresh
    }, 4 * 60 * 1000) // 4 minutes

    return () => clearTimeout(timer)
  }, [jwt])

  return <LangflowContext.Provider value={{...}}>{children}</LangflowContext.Provider>
}
```

#### C8. Create Brand/Client Selector Component
**File**: `/Users/cope/EnGardeHQ/production-frontend/components/layout/ContextSelector.tsx`

- [ ] Create dropdown component in header
- [ ] For agencies: Show client list first, then workspaces, then brands
- [ ] For brands: Show workspace list (if multiple), then brands
- [ ] On selection: Call `switchContext()` from LangflowContext
- [ ] Show current context in header

```typescript
export function ContextSelector() {
  const { state } = useAuth()
  const { switchContext, tenantId, workspaceId, brandId } = useLangflowContext()
  const isAgency = state.user?.organization?.org_type === 'agency'

  // Fetch clients if agency
  const { data: clients } = useQuery({
    queryKey: ['agency-clients'],
    queryFn: async () => {
      const res = await apiClient.get('/agency/clients')
      return res.data
    },
    enabled: isAgency
  })

  // Fetch workspaces for current tenant
  const { data: workspaces } = useQuery({
    queryKey: ['workspaces', tenantId],
    queryFn: async () => {
      const res = await apiClient.get(`/workspaces`)
      return res.data
    },
    enabled: !!tenantId
  })

  // Handle selection
  const handleSelect = (tenant, workspace, brand) => {
    switchContext({
      tenant_id: tenant,
      workspace_id: workspace,
      brand_id: brand
    })
  }

  return <Menu>...</Menu>
}
```

#### C9. Integrate Context Selector into Header
**File**: `/Users/cope/EnGardeHQ/production-frontend/components/layout/header.tsx`

- [ ] Import `ContextSelector`
- [ ] Add to header (after brand dropdown, before notifications)
- [ ] Style to match existing header design
- [ ] Show only for authenticated users

#### C10. Update Langflow Integration to Use Context JWT
**File**: `/Users/cope/EnGardeHQ/production-frontend/app/workflow/[id]/page.tsx` (or wherever Langflow is embedded)

- [ ] Import `useLangflowContext`
- [ ] Use JWT from context instead of fetching separately
- [ ] Pass JWT to Langflow iframe/API calls
- [ ] Handle JWT expiry and refresh

#### C11. Testing Frontend
- [ ] Test context selector displays correctly
- [ ] Test selecting different tenants updates context
- [ ] Test selecting different workspaces updates context
- [ ] Test selecting different brands updates context
- [ ] Test JWT refresh happens automatically
- [ ] Test Langflow receives updated JWT
- [ ] Test agency admin can switch between clients

---

## Parallel Execution Plan

### Wave 1: Independent Backend Tasks (Can run in parallel)
- Agent 1: B1 - Create agency admin middleware
- Agent 2: B2 - Client workspace endpoints
- Agent 3: B3 - Client brand endpoints
- Agent 4: C1 - Add workspace context to JWT
- Agent 5: C2 - Create context switch endpoint

### Wave 2: Dependent Backend Tasks (After Wave 1)
- Agent 1: C3 - Extract JWT generation function
- Agent 2: C4 - Update client switch endpoint
- Agent 3: B4 - Register routers
- Agent 4: C5 - Register Langflow router

### Wave 3: Frontend Foundation (Can run in parallel)
- Agent 1: A1 - Create EditMemberModal component
- Agent 2: A4 - Create PermissionBadges component
- Agent 3: A5 - Create RoleDescriptions component
- Agent 4: C7 - Create Langflow context provider

### Wave 4: Frontend Integration (After Wave 3)
- Agent 1: A2 - Integrate modal into team page
- Agent 2: A3 - Add brand access column
- Agent 3: B6 - Create agency dashboard
- Agent 4: C8 - Create context selector

### Wave 5: Final Integration (After Wave 4)
- Agent 1: B7 - Client detail view
- Agent 2: B8 - Cross-client team manager
- Agent 3: C9 - Integrate context selector
- Agent 4: C10 - Update Langflow integration

---

## Critical Rules to Follow

### From ENGARDE_DEVELOPMENT_RULES.md
1. ✅ Use Chakra UI (NOT Tailwind CSS)
2. ✅ Use `apiClient` from `@/lib/api/client` for all API calls
3. ✅ Handle loading, error, and empty states
4. ✅ Use TypeScript with proper types
5. ✅ Follow existing component patterns

### From DATA_RETRIEVAL_RULES.md
1. ✅ Use `useQuery` from `@tanstack/react-query` for data fetching
2. ✅ Use `useAuth()` from `@/contexts/AuthContext` for user/tenant data
3. ✅ Include `tenant_id` in API calls where required
4. ✅ Wait for auth to load: `if (isAuthLoading) return`
5. ✅ Use query keys: `['resource-name', id]`

### Critical Langflow Rule
⚠️ **DO NOT modify Langflow container startup or configuration**
⚠️ **Only modify backend JWT generation and context switching**
⚠️ **Langflow receives context via JWT claims, not environment variables**

---

## Testing Strategy

### Unit Tests
- [ ] Backend: Test all new endpoints with pytest
- [ ] Backend: Test agency admin authorization
- [ ] Backend: Test Langflow JWT generation
- [ ] Frontend: Test modal component renders
- [ ] Frontend: Test context provider state management

### Integration Tests
- [ ] Test agency admin can manage client workspaces
- [ ] Test team member permissions update correctly
- [ ] Test Langflow context switches successfully
- [ ] Test cross-client access is properly restricted
- [ ] Test brand access enforcement

### E2E Tests
- [ ] Agency admin flow: Create client → Create workspace → Add team member → Assign brand access
- [ ] Team member flow: Login → See assigned brands only → Access Langflow with correct workspace
- [ ] Context switch flow: Switch client → Switch workspace → Switch brand → Verify Langflow context

---

## Rollback Plan

### If Option A Fails
- [ ] Remove `EditMemberModal` component
- [ ] Revert team page changes
- [ ] Keep backend endpoints (they won't break anything)

### If Option B Fails
- [ ] Remove `agency_admin.py` router
- [ ] Remove agency frontend pages
- [ ] Keep Option A changes (they work independently)

### If Option C Fails
- [ ] Revert JWT payload changes in `langflow_sso.py`
- [ ] Remove `langflow_context.py` router
- [ ] Remove `LangflowContext` provider
- [ ] Keep Options A & B (they work independently)

---

## Success Criteria

### Option A Complete When:
- [x] Backend endpoints deployed and working
- [ ] Team member edit modal functional
- [ ] Brand access selection working
- [ ] Permission toggles working
- [ ] Table shows brand access column
- [ ] Changes persist to database
- [ ] UI is polished and user-friendly

### Option B Complete When:
- [ ] Agency admin can view all clients
- [ ] Agency admin can manage client workspaces
- [ ] Agency admin can assign team members to workspaces
- [ ] Agency admin can set brand access across clients
- [ ] Non-agency users cannot access agency features
- [ ] All endpoints properly authorized

### Option C Complete When:
- [ ] Context selector in header works
- [ ] Switching tenants updates Langflow JWT
- [ ] Switching workspaces updates Langflow JWT
- [ ] Switching brands updates Langflow JWT
- [ ] JWT auto-refreshes before expiry
- [ ] Langflow integration receives correct context
- [ ] No modifications to Langflow container

---

**Document Version**: 1.0
**Last Updated**: 2026-01-27
**Status**: Ready for parallel execution
**Estimated Time**: 8-12 hours total (3-4 hours per option with parallelization)
