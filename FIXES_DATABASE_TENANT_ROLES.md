# Database and Data Model Fixes - November 3, 2025

## Executive Summary

Fixed critical database schema issues and seed script failures related to missing `tenant_roles` table and improper user-tenant-brand relationship handling.

## Problems Identified

### Problem 1: Missing tenant_roles Table
**Issue**: Database seeding failed with error: `relation "tenant_roles" does not exist`

**Location**: `/Users/cope/EnGardeHQ/scripts/seed-database.sh` running `/Users/cope/EnGardeHQ/production-backend/scripts/seed_demo_data.sql`

**Root Cause**:
- The `tenant_roles` table was defined in the initial Alembic migration (`7456be403827_initial_migration.py`)
- However, the table was never actually created in the database
- The `tenant_users` table has a foreign key constraint to `tenant_roles.id`, causing INSERT failures

**Evidence**:
```sql
-- tenant_users table structure shows the FK constraint
CONSTRAINT "tenant_users_role_id_fkey" FOREIGN KEY (role_id) REFERENCES tenant_roles(id)

-- But tenant_roles table didn't exist
SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE '%tenant%';
-- Output: only 'tenant_users' and 'tenants', NO 'tenant_roles'
```

### Problem 2: Brands API 500 Errors (False Alarm)
**Issue**: Initially reported that `/api/brands/` and `/api/brands/current` return 500 errors

**Investigation**: Upon checking logs, the brands API was actually returning 200 OK
- The issue may have been intermittent or resolved by user session data
- The real issue was missing brand_members associations in the seed script

**Root Cause**:
- No brand_members were being created by the seed script
- Users couldn't access brands because they weren't members of any brands

### Problem 3: User ID Mismatch in Seed Script
**Issue**: Seed script tried to insert tenant_users with user IDs that didn't exist

**Root Cause**:
- The seed script used `ON CONFLICT (email) DO UPDATE` for users
- Existing users had different IDs (e.g., 'demo-user-id') than the seed script expected ('user-demo-main')
- When trying to insert tenant_users, it referenced the expected IDs, not the actual IDs

## Solutions Implemented

### Fix 1: Created tenant_roles Table Directly

Since Alembic migrations had issues (broken migration chain with missing revisions like 'ai_setup_assistant_001'), I created the table directly using SQL:

**File**: Direct SQL execution via Docker
**Location**: Command line

```sql
CREATE TABLE IF NOT EXISTS tenant_roles (
    id VARCHAR(36) PRIMARY KEY,
    tenant_id VARCHAR(36) REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    permissions JSON NOT NULL,
    is_system_role BOOLEAN DEFAULT FALSE
);

-- Add FK constraint to tenant_users if it doesn't exist
ALTER TABLE tenant_users
ADD CONSTRAINT tenant_users_role_id_fkey
FOREIGN KEY (role_id) REFERENCES tenant_roles(id);
```

**Alternative Migration File Created**: `/Users/cope/EnGardeHQ/production-backend/alembic/versions/20251103_add_tenant_roles_table.py`
- This migration can be used once the Alembic chain is fixed
- Currently not runnable due to broken migration chain

### Fix 2: Updated Seed Script to Handle Dynamic User IDs

**File**: `/Users/cope/EnGardeHQ/production-backend/scripts/seed_demo_data.sql`

**Changes**:
1. Added variables to store actual user IDs:
```sql
DECLARE
    v_user_demo_main_id VARCHAR(36);
    v_user_demo1_id VARCHAR(36);
    v_user_demo2_id VARCHAR(36);
    v_user_demo3_id VARCHAR(36);
BEGIN
```

2. Captured actual user IDs after upsert:
```sql
WITH upserted_users AS (
    INSERT INTO users (...) VALUES (...)
    ON CONFLICT (email) DO UPDATE SET ...
    RETURNING id, email
)
SELECT id INTO v_user_demo_main_id FROM upserted_users WHERE email = 'demo@engarde.com';
SELECT id INTO v_user_demo1_id FROM users WHERE email = 'demo1@engarde.local';
-- etc.
```

3. Used actual IDs for tenant_users inserts:
```sql
INSERT INTO tenant_users (tenant_id, user_id, role_id, permissions, created_at)
VALUES
    ('tenant-demo-main', v_user_demo_main_id, 'role-demo-main-admin', '["*"]'::json, NOW()),
    -- etc.
ON CONFLICT (tenant_id, user_id) DO NOTHING;
```

### Fix 3: Added Brand Members Creation

**File**: `/Users/cope/EnGardeHQ/production-backend/scripts/seed_demo_data.sql`

**Changes**:
Added brand_members creation section:
```sql
-- Create brand members (associate users with their brands)
RAISE NOTICE '👥 Creating brand members...';
INSERT INTO brand_members (brand_id, user_id, tenant_id, role, is_active, joined_at, created_at)
VALUES
    -- demo@engarde.com is owner of all 4 demo brands
    ('brand-demo-main', v_user_demo_main_id, 'tenant-demo-main', 'owner', true, NOW(), NOW()),
    ('brand-demo-main-retail', v_user_demo_main_id, 'tenant-demo-main', 'owner', true, NOW(), NOW()),
    ('brand-demo-main-tech', v_user_demo_main_id, 'tenant-demo-main', 'owner', true, NOW(), NOW()),
    ('brand-demo-main-health', v_user_demo_main_id, 'tenant-demo-main', 'owner', true, NOW(), NOW()),
    -- Each demo user owns their brand
    ('brand-techflow', v_user_demo1_id, 'tenant-techflow', 'owner', true, NOW(), NOW()),
    ('brand-ecostyle', v_user_demo2_id, 'tenant-ecostyle', 'owner', true, NOW(), NOW()),
    ('brand-globaleats', v_user_demo3_id, 'tenant-globaleats', 'owner', true, NOW(), NOW()),
    -- All users are members of shared brand
    ('brand-shared', v_user_demo_main_id, 'tenant-shared', 'admin', true, NOW(), NOW()),
    ('brand-shared', v_user_demo1_id, 'tenant-shared', 'member', true, NOW(), NOW()),
    ('brand-shared', v_user_demo2_id, 'tenant-shared', 'member', true, NOW(), NOW()),
    ('brand-shared', v_user_demo3_id, 'tenant-shared', 'member', true, NOW(), NOW())
ON CONFLICT (brand_id, user_id) DO NOTHING;
```

### Fix 4: Made platform_connections Optional

**File**: `/Users/cope/EnGardeHQ/production-backend/scripts/seed_demo_data.sql`

**Changes**:
Wrapped platform_connections in a conditional check:
```sql
IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'platform_connections') THEN
    RAISE NOTICE '🔌 Creating platform connections...';
    INSERT INTO platform_connections (...)
    VALUES (...)
    ON CONFLICT (id) DO NOTHING;
ELSE
    RAISE NOTICE '  ⚠️  Skipped platform connections (table does not exist)';
END IF;
```

## Data Model Relationships

### User → Tenant Relationship
- **Junction Table**: `tenant_users`
- **Foreign Keys**:
  - `user_id` → `users.id`
  - `tenant_id` → `tenants.id`
  - `role_id` → `tenant_roles.id`
- **Relationship**: Many-to-Many (users can belong to multiple tenants)

### User → Brand Relationship
- **Junction Table**: `brand_members`
- **Foreign Keys**:
  - `user_id` → `users.id`
  - `brand_id` → `brands.id`
  - `tenant_id` → `tenants.id`
- **Relationship**: Many-to-Many (users can be members of multiple brands)
- **Roles**: owner, admin, member, viewer

### Tenant → Brand Relationship
- **Direct Foreign Key**: `brands.tenant_id` → `tenants.id`
- **Relationship**: One-to-Many (tenant has many brands)

### Complete Flow
```
User
  ↓ (tenant_users)
Tenant
  ↓ (brands.tenant_id)
Brand
  ↓ (brand_members)
User (access control)
```

## Tables Created/Fixed

### tenant_roles
```sql
CREATE TABLE tenant_roles (
    id VARCHAR(36) PRIMARY KEY,
    tenant_id VARCHAR(36) REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    permissions JSON NOT NULL,
    is_system_role BOOLEAN DEFAULT FALSE
);
```

**Purpose**: Defines roles for users within a tenant (Admin, Member, etc.)

### brand_members (existing, now properly seeded)
```sql
CREATE TABLE brand_members (
    id VARCHAR(36) PRIMARY KEY,
    brand_id VARCHAR(36) REFERENCES brands(id) ON DELETE CASCADE,
    user_id VARCHAR(36) REFERENCES users(id) ON DELETE CASCADE,
    tenant_id VARCHAR(36) REFERENCES tenants(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL DEFAULT 'member',
    is_active BOOLEAN DEFAULT TRUE,
    joined_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    custom_permissions JSONB DEFAULT '{}',
    invitation_id VARCHAR(36),
    last_accessed_at TIMESTAMP,
    access_count INTEGER DEFAULT 0,
    UNIQUE(brand_id, user_id)
);
```

**Purpose**: Associates users with brands and defines their role

## Testing Results

### Seed Script Output
```
🌱 Starting Demo Data Seeding - Version 1.1.0
============================================================================
📦 Creating demo tenants...
  ✓ Created 5 tenants
👤 Creating demo users...
  ✓ Created/Updated 4 users (demo@engarde.com ID: demo-user-id)
🔑 Creating admin roles...
  ✓ Created 5 roles
🔗 Linking users to tenants...
  ✓ Created 8 tenant-user links
🏢 Creating demo brands...
  ✓ Created 8 brands
👥 Creating brand members...
  ✓ Created 11 brand members
  ⚠️  Skipped platform connections (table does not exist)
📝 Recording seed version...
============================================================================
✅ Demo Data Seeding Completed Successfully!
```

### Database Verification
```sql
-- Verify brand members
SELECT b.name as brand_name, u.email, bm.role, t.name as tenant_name
FROM brand_members bm
JOIN brands b ON bm.brand_id = b.id
JOIN users u ON bm.user_id = u.id
JOIN tenants t ON bm.tenant_id = t.id
ORDER BY u.email, b.name
LIMIT 15;

-- Results: 11 brand members created successfully
--   - demo@engarde.com: owner of 4 brands + admin of shared brand
--   - demo1@engarde.local: owner of TechFlow + member of shared brand
--   - demo2@engarde.local: owner of EcoStyle + member of shared brand
--   - demo3@engarde.local: owner of GlobalEats + member of shared brand
```

## Brands API Status

The brands API endpoints are now working correctly:
- `/api/brands/` - Lists all brands user has access to (200 OK)
- `/api/brands/current` - Returns currently active brand (200 OK)

## Known Issues / Future Work

### 1. Alembic Migration Chain Broken
**Issue**: Migration chain has missing revisions (e.g., 'ai_setup_assistant_001')
**Impact**: Cannot run `alembic upgrade head`
**Workaround**: Direct SQL table creation (already implemented)
**Fix Needed**: Clean up migration files and fix references

### 2. platform_connections Table Missing
**Issue**: Table doesn't exist in current schema
**Impact**: Seed script skips platform connections
**Workaround**: Made optional in seed script
**Fix Needed**: Create migration for platform_connections table

### 3. Duplicate Brands
**Issue**: Some brands exist in both 'default-tenant' and 'tenant-demo-main'
**Impact**: Potential confusion in UI
**Root Cause**: Previous manual seeding created brands in default tenant
**Fix Needed**: Clean up duplicate brands or add tenant filtering

## Files Modified

1. **Direct Database Changes**:
   - Created `tenant_roles` table via SQL
   - Added foreign key constraint to `tenant_users`

2. **Seed Script**: `/Users/cope/EnGardeHQ/production-backend/scripts/seed_demo_data.sql`
   - Added user ID variable declarations
   - Implemented dynamic user ID resolution
   - Added brand_members creation
   - Made platform_connections optional

3. **Migration File Created** (not yet applied): `/Users/cope/EnGardeHQ/production-backend/alembic/versions/20251103_add_tenant_roles_table.py`

## Test Credentials

All seed users have password: `demo123`

- **demo@engarde.com** - Owner of 4 brands (Demo, Retail, Tech, Health)
- **demo1@engarde.local** - Owner of TechFlow Solutions
- **demo2@engarde.local** - Owner of EcoStyle Fashion
- **demo3@engarde.local** - Owner of GlobalEats Delivery

All users also have access to "Team Testing Brand" as members.

## Recommendations

1. **Fix Alembic Migration Chain**: Clean up broken migration references to enable proper migration management
2. **Add platform_connections Migration**: Create proper table schema for platform connections
3. **Clean Up Duplicate Brands**: Remove or merge brands that exist in multiple tenants
4. **Add Database Constraints**: Consider adding CHECK constraints for enum values (role, status, etc.)
5. **Add Indexes**: Review query patterns and add appropriate indexes for performance
6. **Test Brand Switching**: Verify that brand switching functionality works correctly with the new data

## Conclusion

Successfully resolved critical database schema issues preventing database seeding. The system now has:
- Proper tenant_roles table with foreign key relationships
- Functional seed script that handles dynamic user IDs
- Complete brand_members associations for proper access control
- Working brands API endpoints

The seed script is now idempotent and can handle re-seeding with the `--force` flag.
