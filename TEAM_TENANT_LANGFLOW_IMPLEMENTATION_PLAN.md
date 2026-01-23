# Team Management, Tenant Associations & Langflow Sharing Implementation Plan

## Overview
This document outlines the implementation plan for three critical features:

1. **Automatic Tenant Association on User Creation**
2. **Subscription-Based Team Member Limits**
3. **Shared Langflow Agent Folder Access for Team Members**

---

## 1. Automatic Tenant Association on User Creation

### Current State Analysis
- **Problem**: Users created via signup, admin addition, agency client addition, or team member invitation do NOT automatically get `tenant_users` associations
- **Impact**: JWT tokens missing `tenant_id`, causing frontend errors and audit trail issues
- **Found Issues**:
  - `auth.py:signup()` creates User but not Tenant or TenantUser
  - No centralized user creation service

### Implementation Plan

#### 1.1 Create User Service (`app/services/user_service.py`)
```python
class UserService:
    @staticmethod
    def create_user_with_tenant(
        db: Session,
        email: str,
        password: str,
        first_name: str,
        last_name: str,
        user_type: str = "brand",
        tenant_id: Optional[str] = None,  # If None, create new tenant
        tenant_name: Optional[str] = None,
        role_id: Optional[str] = None
    ) -> Tuple[User, Tenant, TenantUser]:
        """
        Create user and automatically associate with tenant.

        Scenarios:
        1. New brand user (signup) → Create new tenant + tenant_user
        2. Team member addition → Use existing tenant_id
        3. Admin adding user → Can specify tenant_id or create new
        4. Agency client → Create new tenant for client
        """
```

#### 1.2 Update All User Creation Endpoints
- `auth.py:signup()` → Use `UserService.create_user_with_tenant()`
- `admin.py:create_user()` → Use `UserService.create_user_with_tenant()`
- `agency.py:add_client()` → Use `UserService.create_user_with_tenant()`
- `brands_team_onboarding.py:invite_team_member()` → Use `UserService.create_user_with_tenant()`

#### 1.3 Default Tenant Creation Rules
```
User Type     | Scenario              | Tenant Creation
------------- | --------------------- | ---------------
brand         | Signup                | New tenant (name: "{first_name} {last_name}'s Workspace")
brand         | Team member invite    | Use inviter's tenant_id
agency        | Signup                | New tenant (name: "{company_name} Agency")
client        | Agency adds client    | New tenant (name: "{company_name}")
admin         | Admin self-creation   | Use "En Garde Admin" tenant (00000000-0000-0000-0000-000000000002)
```

---

## 2. Subscription-Based Team Member Limits

### Current State Analysis
- **Problem**: No limit enforcement on team member additions
- **Found**: `PlanTierConfig` model exists but lacks `max_team_members` field
- **Need**: Tier-based limits enforced at team member invitation time

### Implementation Plan

#### 2.1 Update `PlanTierConfig` Model
```python
class PlanTierConfig(Base):
    # ... existing fields ...

    # Team Member Limits
    max_team_members = Column(Integer, nullable=False, default=1)
    # -1 = unlimited (enterprise custom)
```

#### 2.2 Create Migration
```sql
-- Migration: add_team_member_limits_to_plan_tiers
ALTER TABLE plan_tier_configs
ADD COLUMN max_team_members INTEGER NOT NULL DEFAULT 1;

-- Set initial values based on tier
UPDATE plan_tier_configs
SET max_team_members = CASE tier_id
    WHEN 'starter' THEN 1       -- 1 additional member (2 total)
    WHEN 'professional' THEN 3  -- 3 additional members (4 total)
    WHEN 'business' THEN 5      -- 5 additional members (6 total)
    WHEN 'enterprise' THEN -1   -- unlimited
    ELSE 1
END;
```

#### 2.3 Team Member Limit Validation Service
```python
class TeamMemberLimitService:
    @staticmethod
    def can_add_team_member(db: Session, tenant_id: str) -> bool:
        """
        Check if tenant can add more team members based on subscription tier.

        Returns:
            bool: True if can add, False if limit reached

        Raises:
            HTTPException: 402 Payment Required if limit exceeded
        """
        # Get tenant's current subscription
        subscription = get_active_subscription(db, tenant_id)

        # Get tier config
        tier_config = db.query(PlanTierConfig).filter(
            PlanTierConfig.tier_id == subscription.plan_id
        ).first()

        # Count current team members
        current_members = db.query(TenantUser).filter(
            TenantUser.tenant_id == tenant_id
        ).count()

        # Check limit (-1 = unlimited)
        if tier_config.max_team_members == -1:
            return True  # Enterprise unlimited

        # Owner + max_team_members = total allowed
        total_allowed = 1 + tier_config.max_team_members

        if current_members >= total_allowed:
            raise HTTPException(
                status_code=402,
                detail={
                    "error": "team_member_limit_reached",
                    "message": f"Your {tier_config.tier_name} plan allows {tier_config.max_team_members} additional team member(s). Upgrade to add more.",
                    "current_members": current_members,
                    "max_allowed": total_allowed,
                    "tier": tier_config.tier_id
                }
            )

        return True
```

#### 2.4 Update Team Member Invitation Endpoints
- `brands_team_onboarding.py:invite_team_member()` → Add validation
- Frontend should also check and show upgrade prompt

#### 2.5 Enterprise Custom Storage Settings
- Enterprise tier has `max_team_members = -1` (unlimited)
- Storage limits governed by `storage_limit_gb` in `PlanTierConfig`
- Enterprise tenants can have custom `storage_limit_gb` value set by admin

---

## 3. Shared Langflow Agent Folder Access for Team Members

### Current State Analysis
- **Problem**: Team members cannot access owner's Langflow agents
- **Current Behavior**: Each user has isolated Langflow session
- **Desired**: Team members share owner's Langflow folder (like template-admin for admins)

### Implementation Plan

#### 3.1 Langflow Folder Structure
```
Langflow Users:
- template-admin       (admin templates, read-only for all admins)
- demo@engarde.com     (workspace owner's folder)
- teammember@demo.com  (team member - should access demo@engarde.com's folder)
```

#### 3.2 Update Langflow SSO Token Generation
```python
# In langflow_sso.py:generate_langflow_sso_token()

# Determine which Langflow user account to use
if current_user.user_type == "admin":
    langflow_username = "template-admin"  # Admins use shared template account
else:
    # Get workspace owner (first TenantUser with role=owner)
    tenant_user = db.query(TenantUser).filter(
        TenantUser.user_id == current_user.id
    ).first()

    if tenant_user:
        # Get workspace owner
        owner_tenant_user = db.query(TenantUser).filter(
            TenantUser.tenant_id == tenant_user.tenant_id,
            TenantUser.role_id == "owner"  # Or check role permissions
        ).first()

        if owner_tenant_user:
            owner = db.query(User).filter(
                User.id == owner_tenant_user.user_id
            ).first()
            langflow_username = owner.email  # Team members use owner's Langflow account
        else:
            langflow_username = current_user.email  # Fallback to own account
    else:
        langflow_username = current_user.email  # Fallback to own account

# Generate SSO token with langflow_username
payload = {
    "sub": langflow_username,  # Critical: Use workspace owner's email
    "name": f"{current_user.first_name} {current_user.last_name}",
    "email": current_user.email,  # Keep current user email for audit
    "actual_user_email": current_user.email,  # Track who actually logged in
    "workspace_owner": langflow_username,  # Track workspace owner
    "iat": datetime.utcnow(),
    "exp": datetime.utcnow() + timedelta(seconds=300)
}
```

#### 3.3 Langflow Backend Changes (if needed)
- May need to update Langflow's SSO handler to support `actual_user_email` for audit
- Ensure Langflow respects the `sub` claim for folder access
- Add audit logging to track which team member accessed which workspace

#### 3.4 Security Considerations
- Team members get FULL access to owner's Langflow agents (by design)
- Audit trail: Track `actual_user_email` in Langflow logs
- Future enhancement: Role-based permissions (viewer, editor, admin)

---

## Implementation Order

### Phase 1: Automatic Tenant Association (P0 - Critical)
1. Create `UserService` with `create_user_with_tenant()` method
2. Update `auth.py:signup()` to use UserService
3. Update admin user creation endpoints
4. Test with new user signup → verify tenant_users created → verify JWT has tenant_id

### Phase 2: Team Member Limits (P1 - High)
1. Add `max_team_members` field to `PlanTierConfig` model
2. Create and run migration
3. Create `TeamMemberLimitService`
4. Update team invitation endpoints with validation
5. Test: Starter (1), Pro (3), Business (5), Enterprise (unlimited)

### Phase 3: Langflow Shared Access (P1 - High)
1. Update `langflow_sso.py` to detect workspace owner
2. Generate SSO tokens with owner's email as `sub`
3. Add audit fields (`actual_user_email`, `workspace_owner`)
4. Test: Team member logs in → accesses owner's Langflow folder

---

## Database Schema Changes

### New Migration: `add_team_member_limits`
```sql
-- Plan tier team limits
ALTER TABLE plan_tier_configs
ADD COLUMN max_team_members INTEGER NOT NULL DEFAULT 1;

UPDATE plan_tier_configs
SET max_team_members = CASE tier_id
    WHEN 'starter' THEN 1
    WHEN 'professional' THEN 3
    WHEN 'business' THEN 5
    WHEN 'enterprise' THEN -1
    ELSE 1
END;
```

---

## Testing Checklist

### Tenant Association Tests
- [ ] New brand user signup → creates tenant + tenant_user
- [ ] Team member invite → creates tenant_user with owner's tenant_id
- [ ] Admin creates user → creates tenant_user with specified/new tenant
- [ ] Agency adds client → creates new tenant for client
- [ ] JWT token includes tenant_id for all users
- [ ] Frontend no longer shows tenant_id warnings

### Team Limit Tests
- [ ] Starter plan: Can add 1 additional member, 2nd invite fails with 402
- [ ] Professional plan: Can add 3 additional members, 4th invite fails
- [ ] Business plan: Can add 5 additional members, 6th invite fails
- [ ] Enterprise plan: Can add unlimited members
- [ ] Upgrade flow: Starter → Pro allows adding more members
- [ ] Frontend shows upgrade prompt when limit reached

### Langflow Sharing Tests
- [ ] Owner (demo@engarde.com) logs in → sees their folder
- [ ] Team member 1 logs in → sees demo@engarde.com's folder
- [ ] Team member 2 logs in → sees demo@engarde.com's folder
- [ ] Admin logs in → sees template-admin folder
- [ ] Audit log tracks actual_user_email for team member access
- [ ] Team member can create/edit/delete in owner's folder

---

## Rollout Plan

### Stage 1: Fix Existing Users (Immediate)
- Run fix_tenant_associations.py for all users missing tenant_users

### Stage 2: Deploy Phase 1 (Automatic Tenant Association)
- Deploy UserService
- Deploy updated signup/user creation endpoints
- Monitor logs for tenant_id warnings → should go to zero

### Stage 3: Deploy Phase 2 (Team Limits)
- Deploy migration
- Deploy TeamMemberLimitService
- Deploy updated invitation endpoints
- Communicate limits to existing users

### Stage 4: Deploy Phase 3 (Langflow Sharing)
- Deploy updated langflow_sso.py
- Test with pilot team
- Roll out to all users
- Monitor Langflow audit logs

---

## Future Enhancements

1. **Role-Based Langflow Permissions**
   - Viewer: Read-only access to owner's folder
   - Editor: Can edit but not delete
   - Admin: Full access

2. **Team Member Activity Tracking**
   - Which team member created which agent
   - Audit trail for all Langflow actions

3. **Workspace Isolation Option**
   - Enterprise feature: Isolate team members into sub-workspaces
   - Each sub-workspace has its own Langflow folder

4. **Team Member Usage Quotas**
   - Track storage per team member
   - Enforce individual quotas within team

---

## Implementation Files

### New Files to Create
1. `app/services/user_service.py` - Centralized user creation with tenant association
2. `app/services/team_member_limit_service.py` - Team limit validation
3. `alembic/versions/XXXXXX_add_team_member_limits.py` - Migration

### Files to Modify
1. `app/models/plan_tier_config.py` - Add max_team_members field
2. `app/routers/auth.py` - Use UserService for signup
3. `app/routers/admin.py` - Use UserService for admin user creation
4. `app/routers/agency.py` - Use UserService for client creation
5. `app/routers/brands_team_onboarding.py` - Add limit validation
6. `app/routers/langflow_sso.py` - Shared folder access logic

---

## Success Metrics

1. **Tenant Association**
   - 0 users without tenant_users associations
   - 0 JWT token tenant_id warnings in frontend logs
   - 100% of new users get automatic tenant association

2. **Team Limits**
   - 100% enforcement of tier limits
   - Clear upgrade prompts when limit reached
   - 0 team invites exceeding tier limits

3. **Langflow Sharing**
   - 100% of team members access owner's folder
   - Audit log tracks all team member actions
   - 0 permission errors for team members

---

**Document Status**: Draft
**Created**: 2026-01-22
**Author**: Claude Code
**Review Status**: Pending Developer Review
