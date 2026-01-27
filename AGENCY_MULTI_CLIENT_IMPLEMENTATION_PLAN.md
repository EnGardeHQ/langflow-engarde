# Agency Multi-Client Workspace Management Implementation Plan

## Overview
Enable agencies to manage multiple client workspaces with granular team member access control and Langflow workspace switching.

## Current Architecture ✅

### Existing Components
- **Organization** (Agency) → **Tenant** (Client) → **Workspace** → **Brands**
- **OrganizationMember**: Agency-level users (owner, admin, member)
- **WorkspaceMember**: Workspace-level team members (owner, admin, editor, viewer)
- **BrandMember**: Brand-level access control (owner, admin, member, viewer)
- **Client Switching**: `/api/agency/clients/{client_id}/switch` returns tenant-scoped tokens
- **Langflow SSO**: Uses tenant_id for isolation, team members share owner's workspace

### Data Model
```
Agency (Organization)
├── Agency Admins (OrganizationMember)
└── Clients (Tenant)
    ├── Client Workspaces (Workspace) - MULTIPLE per client
    │   ├── Workspace Members (WorkspaceMember)
    │   └── Workspace Brands (Brand)
    │       └── Brand Members (BrandMember)
    └── Langflow Workspace (tenant_id based)
```

## Requirements

### 1. Multiple Workspaces Per Client Tenant
**Status**: ✅ Already supported by Workspace model

**Current**: Each tenant can have multiple workspaces
**Needed**: UI to create/manage multiple workspaces per client

### 2. Agency Admin Cross-Client Access
**Status**: ❌ Not implemented

**Needed**:
- Agency admins can view all client workspaces
- Agency admins can manage team members across all client workspaces
- Agency admins can assign brand access across clients
- Permission checks in all workspace endpoints

### 3. Langflow Workspace Switching
**Status**: ⚠️ Partially implemented

**Current**:
- Langflow uses `tenant_id` for isolation
- Team members share owner's Langflow workspace
- JWT payload includes tenant info

**Needed**:
- When agency admin switches clients → update Langflow JWT with new tenant_id
- When user switches brands → maintain correct Langflow workspace context
- Frontend brand/client selector triggers Langflow context switch

### 4. Granular Permission System
**Status**: ✅ Recently implemented (workspaces.py)

**Completed**:
- `/api/workspaces/current/members/{member_id}/permissions` - Get permissions
- `/api/workspaces/current/members/{member_id}/permissions` - Update permissions
- `/api/workspaces/current/brands` - List brands for selection
- Workspace roles: owner, admin, editor, viewer
- Brand-level access control
- Permission flags: can_manage_billing, can_manage_api_keys, can_set_budgets, etc.

**Needed**:
- Frontend UI to manage these permissions (in progress)

## Implementation Phases

### Phase 1: Agency Admin Cross-Client Permissions ⏳
**Backend Tasks:**
1. Add middleware to check OrganizationMember role in workspace endpoints
2. Create `/api/agency/clients/{client_id}/workspaces` - List client workspaces
3. Create `/api/agency/clients/{client_id}/workspaces/{workspace_id}/members` - Manage client workspace members
4. Create `/api/agency/clients/{client_id}/brands` - List client brands
5. Update workspace permission endpoints to allow agency admin override

**Frontend Tasks:**
1. Build agency client dashboard showing all clients
2. Build client workspace management UI
3. Add "Manage as Agency Admin" indicator
4. Build cross-client team member assignment UI

### Phase 2: Langflow Workspace Context Switching ⏳
**Backend Tasks:**
1. Update Langflow SSO JWT to accept explicit workspace_id parameter
2. Create `/api/langflow/switch-context` endpoint
   - Input: tenant_id, workspace_id, brand_id
   - Output: New Langflow JWT with updated context
3. Modify `/api/agency/clients/{client_id}/switch` to return Langflow context
4. Add workspace_id to Langflow JWT payload

**Frontend Tasks:**
1. Build brand/client selector component
2. Trigger Langflow context switch on brand/client change
3. Update Langflow iframe/integration to use new context
4. Store active workspace context in state

### Phase 3: Multi-Workspace Management UI ⏳
**Backend Tasks:**
1. Create `/api/workspaces` - Create new workspace for current tenant
2. Create `/api/workspaces/{id}` - Update/delete workspace
3. Add workspace templates (for quick setup)

**Frontend Tasks:**
1. Build workspace creation modal
2. Build workspace settings page
3. Add workspace switcher to header
4. Build workspace template library

### Phase 4: Enhanced Team Member Management ⏳
**Backend Tasks**:
1. Bulk team member operations
2. Team member invitation system
3. Access audit logs

**Frontend Tasks**:
1. Complete team member edit modal with brand selection (in progress)
2. Add permission toggle UI (in progress)
3. Build team member invitation flow
4. Build access audit log viewer

## API Endpoints Needed

### Agency Admin Endpoints
```
GET    /api/agency/clients                          # ✅ Exists
POST   /api/agency/clients                          # ✅ Exists
GET    /api/agency/clients/{id}                     # ✅ Exists
POST   /api/agency/clients/{id}/switch              # ✅ Exists
GET    /api/agency/clients/{id}/workspaces          # ❌ Need to create
POST   /api/agency/clients/{id}/workspaces          # ❌ Need to create
GET    /api/agency/clients/{id}/workspaces/{wid}/members  # ❌ Need to create
PUT    /api/agency/clients/{id}/workspaces/{wid}/members/{mid}  # ❌ Need to create
GET    /api/agency/clients/{id}/brands              # ❌ Need to create
```

### Workspace Management Endpoints
```
GET    /api/workspaces/current/members              # ✅ Exists
GET    /api/workspaces/current/members/{id}/permissions  # ✅ Exists
PUT    /api/workspaces/current/members/{id}/permissions  # ✅ Exists
GET    /api/workspaces/current/brands               # ✅ Exists
POST   /api/workspaces                              # ❌ Need to create
PUT    /api/workspaces/{id}                         # ❌ Need to create
DELETE /api/workspaces/{id}                         # ❌ Need to create
```

### Langflow Context Switching
```
POST   /api/langflow/switch-context                 # ❌ Need to create
GET    /api/langflow/current-context                # ❌ Need to create
```

## Database Schema Changes

### No schema changes needed! ✅
All existing tables support the required functionality:
- `organizations` - Agency
- `organization_members` - Agency admins
- `tenants` - Clients
- `workspaces` - Client workspaces (already supports multiple per tenant)
- `workspace_members` - Team members in workspaces
- `brands` - Client brands
- `brand_members` - Brand access control

## Frontend Components Needed

### Agency Admin Dashboard
- **ClientListView**: Grid/table of all clients
- **ClientDetailView**: Single client overview
- **ClientWorkspaceManager**: Manage client workspaces
- **CrossClientTeamManager**: Assign team members across clients

### Workspace Management
- **WorkspaceSelector**: Header dropdown to switch workspaces
- **WorkspaceCreationModal**: Create new workspace
- **WorkspaceSettingsPage**: Configure workspace

### Team Member Management
- **TeamMemberEditModal**: Edit member permissions (in progress)
- **BrandAccessSelector**: Checkboxes for brand selection (in progress)
- **PermissionToggles**: Admin capability toggles (in progress)

### Context Switching
- **BrandClientSelector**: Combined brand/client selector
- **LangflowContextProvider**: React context for Langflow state

## Security Considerations

1. **Agency Admin Authorization**
   - Verify OrganizationMember role = 'owner' or 'admin'
   - Check organization_id matches client's organization_id
   - Audit log all admin actions

2. **Langflow Isolation**
   - Maintain tenant_id based folder isolation
   - Verify user has access to requested tenant/workspace
   - Short JWT expiry (5 minutes)

3. **Cross-Client Access**
   - Agency admins only
   - Clear audit trail
   - Client data isolation

## Testing Requirements

### Backend Tests
- [ ] Agency admin can access all client workspaces
- [ ] Non-agency users cannot access other clients
- [ ] Langflow context switches correctly
- [ ] Brand access is properly enforced

### Frontend Tests
- [ ] Agency admin UI shows all clients
- [ ] Client switching updates context
- [ ] Langflow integration maintains workspace context
- [ ] Permission management UI updates correctly

## Next Steps

1. **Immediate (Today)**:
   - Complete team member edit modal UI (frontend)
   - Add brand selection checkboxes
   - Add permission toggles

2. **Short-term (This Week)**:
   - Implement agency admin cross-client endpoints
   - Build agency client management UI
   - Implement Langflow context switching

3. **Medium-term (Next Week)**:
   - Multi-workspace UI
   - Workspace creation/management
   - Access audit logging

## Current Progress

### ✅ Completed
- Permission structure design
- Backend permission management endpoints
- Workspace member detail endpoints
- Brand access control models

### ⏳ In Progress
- Team member edit modal UI (frontend)
- Brand access selection UI (frontend)
- Permission toggles UI (frontend)

### ❌ Not Started
- Agency admin cross-client endpoints
- Langflow context switching
- Multi-workspace UI
- Agency admin dashboard

---

**Last Updated**: 2026-01-27
**Status**: Phase 1 - Backend foundations complete, Frontend UI in progress
