# Master Implementation Plan: Agency Multi-Client Management
## Options A → B → C Parallel Execution

**Created:** 2026-01-27
**Status:** IN PROGRESS
**AI Resumable:** YES - Any AI assistant can resume from this document

---

## 🎯 Execution Order

1. **OPTION A:** Complete Team Management UI (Priority 1)
2. **OPTION B:** Agency Admin Cross-Client Management (Priority 2)
3. **OPTION C:** Langflow Context Switching (Priority 3)

**CRITICAL RULES:**
- ✅ Follow `ENGARDE_DEVELOPMENT_RULES.md` strictly
- ✅ Use Chakra UI (NO Tailwind)
- ✅ Use `apiClient` from `@/lib/api/client`
- ✅ Use `useQuery` from `@tanstack/react-query`
- ✅ Include `tenant_id` in all API calls
- ✅ For Option C: DO NOT modify Langflow container startup - ONLY modify main backend

---

## OPTION A: Complete Team Management UI

### Backend Prerequisites ✅ COMPLETE
- [x] GET `/api/workspaces/current/members/{member_id}/permissions`
- [x] PUT `/api/workspaces/current/members/{member_id}/permissions`
- [x] GET `/api/workspaces/current/brands`
- [x] Permission structure defined
- [x] Backend deployed to Railway

### Frontend Tasks

#### A1. Create Team Member Edit Modal Component
**File:** `production-frontend/app/team/components/EditMemberModal.tsx`
**Status:** PENDING

**Requirements:**
- [ ] Create new file `EditMemberModal.tsx`
- [ ] Import Chakra UI: Modal, ModalOverlay, ModalContent, ModalHeader, ModalBody, ModalFooter, ModalCloseButton
- [ ] Import form components: FormControl, FormLabel, Select, Switch, Checkbox, CheckboxGroup, VStack, HStack
- [ ] Use `useQuery` from `@tanstack/react-query`
- [ ] Use `apiClient` from `@/lib/api/client`

**Component Structure:**
```typescript
interface EditMemberModalProps {
  isOpen: boolean
  onClose: () => void
  memberId: string
  onSuccess: () => void
}

// Sections:
// 1. Workspace Role Section (owner, admin, editor, viewer)
// 2. Brand Access Section (checkbox list + role per brand)
// 3. Admin Permissions Section (toggles for admin capabilities)
```

**API Integration:**
- Fetch permissions: `GET /api/workspaces/current/members/{memberId}/permissions`
- Fetch brands: `GET /api/workspaces/current/brands`
- Update: `PUT /api/workspaces/current/members/{memberId}/permissions`

#### A2. Integrate Modal into Team Page
**File:** `production-frontend/app/team/page.tsx`
**Status:** PENDING

- [ ] Import `EditMemberModal` component
- [ ] Add state: `const [editingMember, setEditingMember] = useState<string | null>(null)`
- [ ] Add modal to render
- [ ] Update "Change Role" menu item
- [ ] Add "Manage Permissions" menu item

#### A3. Add Brand Access Column to Team Table
**File:** `production-frontend/app/team/page.tsx`
**Status:** PENDING

- [ ] Add table column header: `<Th>Brand Access</Th>`
- [ ] Display brand badges with tooltips showing role
- [ ] Use HStack for badge layout

#### A4. Create Permission Badge Components
**File:** `production-frontend/app/team/components/PermissionBadges.tsx`
**Status:** PENDING

- [ ] Create `PermissionBadge` component
- [ ] Props: `{ permission: string, enabled: boolean }`
- [ ] Display icon + text
- [ ] Conditional colorScheme based on enabled status

#### A5. Add Role Descriptions
**File:** `production-frontend/app/team/components/RoleDescriptions.tsx`
**Status:** PENDING

- [ ] Owner: Full access including billing
- [ ] Admin: Team/budgets/API keys (no billing)
- [ ] Editor: Edit campaigns/content
- [ ] Viewer: Read-only access

#### A6. Testing Checklist
- [ ] Test opening edit modal
- [ ] Test changing workspace role
- [ ] Test adding brand access
- [ ] Test removing brand access
- [ ] Test brand role changes
- [ ] Test permission toggles
- [ ] Test owner-only restrictions
- [ ] Test error handling
- [ ] Test modal close on success
- [ ] Test table refresh

---

## OPTION B: Agency Admin Cross-Client Management

### Backend Tasks

#### B1. Create Agency Admin Middleware
**File:** `production-backend/app/routers/agency_admin.py` (NEW)
**Status:** PENDING

- [ ] Create new router file
- [ ] Add dependency `get_agency_admin_user()`
- [ ] Verify user is agency admin (owner/admin role)
- [ ] Verify organization type is 'agency'
- [ ] Return tuple (user, organization)

**Implementation:**
```python
def get_agency_admin_user(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> tuple[User, Organization]:
    # Verify agency admin membership
    # Return (user, org)
```

#### B2. Client Workspace Management Endpoints
**File:** `production-backend/app/routers/agency_admin.py`
**Status:** PENDING

**Endpoints to create:**
- [ ] `GET /api/agency/clients/{client_id}/workspaces` - List client workspaces
- [ ] `POST /api/agency/clients/{client_id}/workspaces` - Create workspace
- [ ] `GET /api/agency/clients/{client_id}/workspaces/{workspace_id}/members` - List members
- [ ] `PUT /api/agency/clients/{client_id}/workspaces/{workspace_id}/members/{member_id}` - Update member

#### B3. Client Brand Management Endpoints
**File:** `production-backend/app/routers/agency_admin.py`
**Status:** PENDING

- [ ] `GET /api/agency/clients/{client_id}/brands` - List client brands

#### B4. Register Agency Admin Router
**File:** `production-backend/app/main.py`
**Status:** PENDING

- [ ] Import: `from app.routers import agency_admin`
- [ ] Add: `app.include_router(agency_admin.router)`

#### B5. Testing Backend Endpoints
- [ ] Test agency admin can list client workspaces
- [ ] Test agency admin can create workspace
- [ ] Test agency admin can view members
- [ ] Test agency admin can update permissions
- [ ] Test non-agency users get 403
- [ ] Test cross-client restrictions

### Frontend Tasks

#### B6. Create Agency Client Dashboard
**File:** `production-frontend/app/agency/clients/page.tsx`
**Status:** PENDING

- [ ] Create agency dashboard page
- [ ] Fetch: `GET /api/agency/clients`
- [ ] Display client cards in grid
- [ ] Show workspace count, member count
- [ ] Add "Manage" button per client

#### B7. Create Client Detail View
**File:** `production-frontend/app/agency/clients/[clientId]/page.tsx`
**Status:** PENDING

- [ ] Dynamic route for client detail
- [ ] Fetch workspaces: `GET /api/agency/clients/{clientId}/workspaces`
- [ ] Fetch brands: `GET /api/agency/clients/{clientId}/brands`
- [ ] Display workspace list
- [ ] Display brand list
- [ ] Add "Manage Team" button

#### B8. Create Cross-Client Team Manager
**File:** `production-frontend/app/agency/clients/[clientId]/workspaces/[workspaceId]/team/page.tsx`
**Status:** PENDING

- [ ] Fetch workspace members
- [ ] Reuse `EditMemberModal` component
- [ ] Add "Agency Admin" badge
- [ ] Show which admin is making changes

#### B9. Add Agency Navigation
**File:** `production-frontend/components/layout/sidebar-nav.tsx`
**Status:** PENDING

- [ ] Add "Agency Dashboard" link (only for agency users)
- [ ] Check: `state.user?.organization?.org_type === 'agency'`
- [ ] Add icon and route

#### B10. Testing Frontend
- [ ] Test agency dashboard loads
- [ ] Test client list displays
- [ ] Test client detail page
- [ ] Test cross-client team management
- [ ] Test navigation
- [ ] Test agency admin indicator

---

## OPTION C: Langflow Context Switching

**⚠️ CRITICAL:** Do NOT modify Langflow container startup. Only modify main backend service.

### Backend Tasks

#### C1. Add Workspace Context to JWT Claims
**File:** `production-backend/app/routers/langflow_sso.py`
**Status:** PENDING

- [ ] Add `workspace_id` to JWT payload
- [ ] Add `workspace_name` to JWT payload
- [ ] Add `brand_id` to JWT payload (optional)
- [ ] Add `brand_name` to JWT payload (optional)

**Implementation:**
```python
payload = {
    "email": langflow_email,
    "sub": langflow_user_id,
    "tenant_id": tenant_id or "staging",
    "tenant_name": tenant_name,
    "role": user_role,
    "subscription_tier": subscription_tier,
    # NEW FIELDS
    "workspace_id": workspace_id,
    "workspace_name": workspace_name,
    "brand_id": brand_id,
    "brand_name": brand_name,
    # EXISTING FIELDS
    "exp": datetime.utcnow() + timedelta(minutes=5),
    # ...
}
```

#### C2. Create Context Switch Endpoint
**File:** `production-backend/app/routers/langflow_context.py` (NEW)
**Status:** PENDING

- [ ] Create new router file
- [ ] Add endpoint: `POST /api/langflow/switch-context`
- [ ] Add endpoint: `GET /api/langflow/current-context`
- [ ] Verify user has access to tenant
- [ ] Support agency admin context switching
- [ ] Generate new Langflow JWT with updated context

#### C3. Extract JWT Generation to Reusable Function
**File:** `production-backend/app/routers/langflow_sso.py`
**Status:** PENDING

- [ ] Extract JWT creation to `generate_langflow_jwt()` function
- [ ] Add parameters: `workspace_id`, `workspace_name`, `brand_id`, `brand_name`
- [ ] Update existing SSO endpoint to call this function
- [ ] Keep all existing logic unchanged

#### C4. Update Agency Client Switch to Include Langflow Context
**File:** `production-backend/app/routers/agency.py`
**Status:** PENDING

- [ ] Modify `/api/agency/clients/{client_id}/switch` endpoint
- [ ] Include Langflow JWT in response
- [ ] Add langflow_context object to response

#### C5. Register Langflow Context Router
**File:** `production-backend/app/main.py`
**Status:** PENDING

- [ ] Import: `from app.routers import langflow_context`
- [ ] Add: `app.include_router(langflow_context.router)`

#### C6. Testing Backend
- [ ] Test context switch returns valid JWT
- [ ] Test JWT includes workspace_id and brand_id
- [ ] Test agency admin can switch
- [ ] Test client switch includes Langflow JWT
- [ ] Test JWT expiry (5 minutes)

### Frontend Tasks

#### C7. Create Langflow Context Provider
**File:** `production-frontend/contexts/LangflowContext.tsx`
**Status:** PENDING

- [ ] Create React Context for Langflow state
- [ ] Store: current JWT, tenant_id, workspace_id, brand_id
- [ ] Method: `switchContext(tenant, workspace?, brand?)`
- [ ] Auto-refresh JWT before expiry (4 minutes)

**Implementation:**
```typescript
interface LangflowContextType {
  jwt: string | null
  tenantId: string | null
  workspaceId: string | null
  brandId: string | null
  switchContext: (params: SwitchContextParams) => Promise<void>
  isLoading: boolean
}
```

#### C8. Create Brand/Client Selector Component
**File:** `production-frontend/components/layout/ContextSelector.tsx`
**Status:** PENDING

- [ ] Create dropdown component in header
- [ ] For agencies: Show client list → workspaces → brands
- [ ] For brands: Show workspace list → brands
- [ ] On selection: Call `switchContext()`
- [ ] Show current context in header

#### C9. Integrate Context Selector into Header
**File:** `production-frontend/components/layout/header.tsx`
**Status:** PENDING

- [ ] Import `ContextSelector`
- [ ] Add to header (after brand dropdown)
- [ ] Style to match existing header
- [ ] Show only for authenticated users

#### C10. Update Langflow Integration to Use Context JWT
**File:** `production-frontend/app/workflow/[id]/page.tsx`
**Status:** PENDING

- [ ] Import `useLangflowContext`
- [ ] Use JWT from context
- [ ] Pass JWT to Langflow iframe/API
- [ ] Handle JWT expiry and refresh

#### C11. Testing Frontend
- [ ] Test context selector displays
- [ ] Test tenant selection updates context
- [ ] Test workspace selection updates context
- [ ] Test brand selection updates context
- [ ] Test JWT auto-refresh
- [ ] Test Langflow receives updated JWT
- [ ] Test agency admin can switch

---

## Parallel Execution Waves

### Wave 1: Independent Backend Tasks (Parallel)
**Agent Assignment:**
- **Agent 1 (backend-api-architect):** B1 - Create agency admin middleware
- **Agent 2 (backend-api-architect):** B2 - Client workspace endpoints
- **Agent 3 (backend-api-architect):** B3 - Client brand endpoints
- **Agent 4 (backend-api-architect):** C1 - Add workspace context to JWT
- **Agent 5 (backend-api-architect):** C2 - Create context switch endpoint

### Wave 2: Dependent Backend Tasks (Sequential after Wave 1)
**Agent Assignment:**
- **Agent 1 (backend-api-architect):** C3 - Extract JWT generation function
- **Agent 2 (backend-api-architect):** C4 - Update client switch endpoint
- **Agent 3 (backend-api-architect):** B4 - Register agency router
- **Agent 4 (backend-api-architect):** C5 - Register Langflow router

### Wave 3: Frontend Foundation (Parallel)
**Agent Assignment:**
- **Agent 1 (frontend-ui-builder):** A1 - Create EditMemberModal component
- **Agent 2 (frontend-ui-builder):** A4 - Create PermissionBadges component
- **Agent 3 (frontend-ui-builder):** A5 - Create RoleDescriptions component
- **Agent 4 (frontend-ui-builder):** C7 - Create Langflow context provider

### Wave 4: Frontend Integration (Sequential after Wave 3)
**Agent Assignment:**
- **Agent 1 (frontend-ui-builder):** A2 - Integrate modal into team page
- **Agent 2 (frontend-ui-builder):** A3 - Add brand access column
- **Agent 3 (frontend-ui-builder):** B6 - Create agency dashboard
- **Agent 4 (frontend-ui-builder):** C8 - Create context selector

### Wave 5: Final Integration (Sequential after Wave 4)
**Agent Assignment:**
- **Agent 1 (frontend-ui-builder):** B7 - Client detail view
- **Agent 2 (frontend-ui-builder):** B8 - Cross-client team manager
- **Agent 3 (frontend-ui-builder):** C9 - Integrate context selector
- **Agent 4 (frontend-ui-builder):** C10 - Update Langflow integration

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
- [ ] Agency admin can assign team members
- [ ] Agency admin can set brand access
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

## Rollback Plan

### If Option A Fails
- [ ] Remove `EditMemberModal` component
- [ ] Revert team page changes
- [ ] Keep backend endpoints (safe)

### If Option B Fails
- [ ] Remove `agency_admin.py` router
- [ ] Remove agency frontend pages
- [ ] Keep Option A changes (independent)

### If Option C Fails
- [ ] Revert JWT payload changes
- [ ] Remove `langflow_context.py` router
- [ ] Remove `LangflowContext` provider
- [ ] Keep Options A & B (independent)

---

## Testing Strategy

### Unit Tests
- [ ] Backend: Test all new endpoints with pytest
- [ ] Backend: Test agency admin authorization
- [ ] Backend: Test Langflow JWT generation
- [ ] Frontend: Test modal component renders
- [ ] Frontend: Test context provider state

### Integration Tests
- [ ] Test agency admin can manage client workspaces
- [ ] Test team member permissions update
- [ ] Test Langflow context switches
- [ ] Test cross-client access restrictions
- [ ] Test brand access enforcement

### E2E Tests
- [ ] Agency admin flow: Create client → workspace → team member → brand access
- [ ] Team member flow: Login → see brands → access Langflow
- [ ] Context switch flow: Switch client → workspace → brand → verify Langflow

---

## Deployment Checklist

### Backend Deployment
- [ ] Run migrations if needed
- [ ] Deploy to Railway
- [ ] Verify endpoints in /docs
- [ ] Test with curl/Postman
- [ ] Check Railway logs

### Frontend Deployment
- [ ] Build passes: `npm run build`
- [ ] Type check passes: `npm run type-check`
- [ ] Lint passes: `npm run lint`
- [ ] Deploy to Vercel
- [ ] Verify in production

---

**Document Version:** 1.0
**Last Updated:** 2026-01-27
**Status:** Ready for parallel execution
**Estimated Time:** 8-12 hours total (3-4 hours per option with parallelization)

**Next Steps:**
1. Launch Wave 1 agents (5 backend tasks in parallel)
2. Monitor completion, then launch Wave 2
3. Continue through Wave 5
4. Run testing checklist
5. Deploy to production
