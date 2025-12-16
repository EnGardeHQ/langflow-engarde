# EnGarde Demo Data Seeding Summary

## Overview
Successfully seeded the EnGarde database with comprehensive demo data for testing purposes.

---

## Database Schema Changes

### 1. Users Table Default Value Updated
```sql
ALTER TABLE users ALTER COLUMN user_type SET DEFAULT 'brand';
```
- Changed default value from `'advertiser'` to `'brand'`
- All new users will now default to brand user type

---

## Demo Brands Created

### Brand 1: Acme Corporation
- **ID**: `brand-acme-corp-001`
- **Tenant ID**: `tenant-acme-corp-001`
- **Industry**: Technology
- **Company Size**: Medium
- **Timezone**: America/New_York
- **Description**: Leading technology solutions provider specializing in enterprise software, cloud infrastructure, and digital transformation services
- **Website**: https://acme-corp.example.com
- **Slug**: `acme-corporation`
- **Status**: Active, Verified, Onboarding Complete

### Brand 2: Global Retail Co
- **ID**: `brand-global-retail-002`
- **Tenant ID**: `tenant-global-retail-002`
- **Industry**: Retail
- **Company Size**: Large
- **Timezone**: America/Los_Angeles
- **Description**: International e-commerce platform offering diverse product categories with seamless shopping experiences across web and mobile
- **Website**: https://globalretail.example.com
- **Slug**: `global-retail-co`
- **Status**: Active, Verified, Onboarding Complete

### Brand 3: HealthTech Plus
- **ID**: `brand-healthtech-plus-003`
- **Tenant ID**: `tenant-healthtech-plus-003`
- **Industry**: Healthcare
- **Company Size**: Medium
- **Timezone**: America/Chicago
- **Description**: Innovative healthcare technology platform providing SaaS solutions for patient management, telemedicine, and health data analytics
- **Website**: https://healthtechplus.example.com
- **Slug**: `healthtech-plus`
- **Status**: Active, Verified, Onboarding Complete

### Brand 4: Creative Agency Pro (SHARED BRAND)
- **ID**: `brand-creative-agency-004`
- **Tenant ID**: `tenant-creative-agency-004`
- **Industry**: Marketing
- **Company Size**: Small
- **Timezone**: America/New_York
- **Description**: Full-service creative marketing agency specializing in brand strategy, digital campaigns, content creation, and multi-channel advertising
- **Website**: https://creativeagencypro.example.com
- **Slug**: `creative-agency-pro`
- **Status**: Active, Verified, Onboarding Complete
- **Special**: Shared by 2 users for team collaboration testing

---

## Demo Users Created

### User 1: demo1@engarde.ai
- **ID**: `user-demo1-engarde-001`
- **Password**: `demo123`
- **Name**: Demo User One
- **User Type**: brand
- **Status**: Active
- **Brand Memberships**:
  - **Acme Corporation**: OWNER (Primary Brand)
  - **Creative Agency Pro**: MEMBER
- **Total Brands**: 2
- **Active Brand**: Acme Corporation

### User 2: demo2@engarde.ai
- **ID**: `user-demo2-engarde-002`
- **Password**: `demo123`
- **Name**: Demo User Two
- **User Type**: brand
- **Status**: Active
- **Brand Memberships**:
  - **Global Retail Co**: OWNER (Primary Brand)
  - **Creative Agency Pro**: ADMIN (for team admin testing)
- **Total Brands**: 2
- **Active Brand**: Global Retail Co

### User 3: demo3@engarde.ai
- **ID**: `user-demo3-engarde-003`
- **Password**: `demo123`
- **Name**: Demo User Three
- **User Type**: brand
- **Status**: Active
- **Brand Memberships**:
  - **HealthTech Plus**: OWNER (Primary Brand)
- **Total Brands**: 1
- **Active Brand**: HealthTech Plus

### User 4: admin@demo.engarde.ai (Existing)
- **ID**: `5b3a31e4-7b10-4630-8994-d40166f2cf94`
- **User Type**: Updated to `brand`
- **Status**: Active
- **Note**: Existing user, maintained for continuity

---

## Brand Membership Roles

### Role Hierarchy
1. **OWNER**: Full control over brand, can manage all members and settings
2. **ADMIN**: Can manage members and most settings (used for demo2 in Creative Agency Pro)
3. **MEMBER**: Standard access (used for demo1 in Creative Agency Pro)
4. **VIEWER**: Read-only access

### Brand 4 Team Structure (Creative Agency Pro)
- **demo1@engarde.ai**: MEMBER role
- **demo2@engarde.ai**: ADMIN role
- **Purpose**: Test team collaboration, multi-user brand access, and role-based permissions

---

## Tenant Relationships

All brands have corresponding tenant records with proper relationships:

| Tenant ID | Brand | Plan Tier | Status |
|-----------|-------|-----------|--------|
| tenant-acme-corp-001 | Acme Corporation | Professional | Active |
| tenant-global-retail-002 | Global Retail Co | Professional | Active |
| tenant-healthtech-plus-003 | HealthTech Plus | Enterprise | Active |
| tenant-creative-agency-004 | Creative Agency Pro | Professional | Active |

### Tenant-User Mappings
- User 1 linked to: tenant-acme-corp-001, tenant-creative-agency-004
- User 2 linked to: tenant-global-retail-002, tenant-creative-agency-004
- User 3 linked to: tenant-healthtech-plus-003

---

## User Active Brands

Each user has a default "active brand" configured:

| User | Active Brand | Tenant |
|------|-------------|---------|
| demo1@engarde.ai | Acme Corporation | tenant-acme-corp-001 |
| demo2@engarde.ai | Global Retail Co | tenant-global-retail-002 |
| demo3@engarde.ai | HealthTech Plus | tenant-healthtech-plus-003 |

---

## Login Test Results

### All Users Successfully Tested

#### User 1 (demo1@engarde.ai)
- ✅ Login successful
- ✅ JWT token generated
- ✅ Current brand: Acme Corporation
- ✅ Role: owner
- ✅ Total brands: 2

#### User 2 (demo2@engarde.ai)
- ✅ Login successful
- ✅ JWT token generated
- ✅ Current brand: Global Retail Co
- ✅ Role: owner
- ✅ Total brands: 2

#### User 3 (demo3@engarde.ai)
- ✅ Login successful
- ✅ JWT token generated
- ✅ Current brand: HealthTech Plus
- ✅ Role: owner
- ✅ Total brands: 1

---

## API Endpoints Verified

### Authentication
- ✅ POST `/api/auth/login` - All users can authenticate

### Brand Access
- ✅ GET `/api/brands/current` - Returns correct brand data for each user
- ✅ Brand switching capability available (user1 and user2 can switch between their brands)

---

## Files Created

### 1. `/Users/cope/EnGardeHQ/seed_demo_data.sql`
Complete SQL script with:
- Schema alterations
- Brand creation with full details
- User creation with bcrypt password hashing
- Tenant setup
- Brand membership assignments
- User active brand configuration
- Comprehensive verification queries

### 2. `/Users/cope/EnGardeHQ/test_demo_users.sh`
Bash script for testing user authentication and brand access via API calls

### 3. `/Users/cope/EnGardeHQ/verify_demo_data.sh`
Comprehensive verification script that:
- Tests all user logins
- Verifies brand access
- Queries database for data integrity
- Provides formatted summary output

### 4. `/Users/cope/EnGardeHQ/generate_password_hash.py`
Python utility for generating bcrypt password hashes

---

## Password Hashing Details

### Implementation
- **Library**: passlib with bcrypt
- **Scheme**: bcrypt with automatic rounds (default: 12)
- **Password**: `demo123` for all demo users
- **Hash**: `$2b$12$xQ16Mz8KUCgiCILc.1R4PeV.7YIj3OjZl9t/DujPityJ/cAtL24AS`

### Verification Process
```python
from passlib.context import CryptContext
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
pwd_context.verify("demo123", hashed_password)  # Returns True
```

---

## Database Verification Queries

### Verify All Brands
```sql
SELECT b.name, b.industry, b.company_size, COUNT(DISTINCT bm.user_id) as member_count
FROM brands b
LEFT JOIN brand_members bm ON b.id = bm.brand_id AND bm.is_active = true
WHERE b.id IN (
    'brand-acme-corp-001',
    'brand-global-retail-002',
    'brand-healthtech-plus-003',
    'brand-creative-agency-004'
)
GROUP BY b.id, b.name, b.industry, b.company_size
ORDER BY b.name;
```

### Verify Brand Memberships
```sql
SELECT
    u.email,
    COUNT(bm.id) as total_brands,
    STRING_AGG(b.name || ' (' || bm.role || ')', ', ' ORDER BY b.name) as brand_memberships
FROM users u
LEFT JOIN brand_members bm ON u.id = bm.user_id AND bm.is_active = true
LEFT JOIN brands b ON bm.brand_id = b.id
WHERE u.email IN ('demo1@engarde.ai', 'demo2@engarde.ai', 'demo3@engarde.ai')
GROUP BY u.email
ORDER BY u.email;
```

### Verify Creative Agency Pro Team
```sql
SELECT u.email, u.first_name || ' ' || u.last_name as name, bm.role, bm.is_active
FROM brand_members bm
JOIN users u ON bm.user_id = u.id
WHERE bm.brand_id = 'brand-creative-agency-004'
ORDER BY bm.role DESC, u.email;
```

**Result**: 2 members confirmed (demo1 as MEMBER, demo2 as ADMIN)

---

## Testing Use Cases

### 1. Single Brand Owner
- **User**: demo3@engarde.ai
- **Test**: Basic brand management, single-tenant scenarios

### 2. Multi-Brand Owner
- **User**: demo1@engarde.ai
- **Test**: Brand switching, multi-tenant access, member role permissions

### 3. Multi-Brand with Admin Role
- **User**: demo2@engarde.ai
- **Test**: Team administration, role-based permissions, brand switching

### 4. Shared Brand Collaboration
- **Brand**: Creative Agency Pro
- **Users**: demo1 (member), demo2 (admin)
- **Test**: Team features, permission boundaries, collaborative workflows

---

## Quick Start Commands

### Re-run Complete Seeding
```bash
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec -T postgres psql -U engarde_user -d engarde < /Users/cope/EnGardeHQ/seed_demo_data.sql
```

### Update User Passwords
```bash
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec -T postgres psql -U engarde_user -d engarde -c "UPDATE users SET hashed_password = '\$2b\$12\$xQ16Mz8KUCgiCILc.1R4PeV.7YIj3OjZl9t/DujPityJ/cAtL24AS', updated_at = NOW() WHERE email IN ('demo1@engarde.ai', 'demo2@engarde.ai', 'demo3@engarde.ai');"
```

### Run Verification Tests
```bash
/Users/cope/EnGardeHQ/verify_demo_data.sh
```

### Test Single User Login
```bash
curl -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo1@engarde.ai&password=demo123"
```

---

## Summary

✅ **4 Demo Brands** created with comprehensive details
✅ **3 New Demo Users** created with proper authentication
✅ **1 Existing User** updated (admin@demo.engarde.ai)
✅ **6 Brand Memberships** established with appropriate roles
✅ **4 Tenants** configured with user relationships
✅ **3 Active Brands** set as user defaults
✅ **100% Login Success** rate for all demo users
✅ **Brand 4 Sharing** verified with 2 members
✅ **Team Admin Testing** enabled via demo2 admin role

---

## Next Steps

1. **Test Brand Switching**: Use demo1 or demo2 to switch between brands
2. **Test Team Features**: Access Creative Agency Pro with both demo1 and demo2
3. **Test Role Permissions**: Verify OWNER vs ADMIN vs MEMBER access levels
4. **Test Campaigns**: Create campaigns under different brands
5. **Test Multi-Tenant Features**: Verify data isolation between tenants

---

*Generated on: 2025-10-29*
*Database: PostgreSQL in Docker (engarde_postgres_dev)*
*API Base URL: http://localhost:8000*
