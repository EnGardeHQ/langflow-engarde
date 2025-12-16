-- ============================================================================
-- EnGarde Demo Data Seeding Script
-- Purpose: Create 4 demo brands, 3 new demo users, and proper relationships
-- ============================================================================

-- Step 1: Update users table default value for user_type
ALTER TABLE users ALTER COLUMN user_type SET DEFAULT 'brand';

-- Step 2: Create 4 Demo Brands with Tenants
-- Note: Using gen_random_uuid() for PostgreSQL 13+ or uuid_generate_v4() for older versions

-- Brand 1: Acme Corporation (Technology)
INSERT INTO tenants (id, name, slug, plan_tier, status, created_at, updated_at)
VALUES (
    'tenant-acme-corp-001',
    'Acme Corporation',
    'acme-corporation',
    'professional',
    'active',
    NOW(),
    NOW()
) ON CONFLICT (slug) DO UPDATE SET
    name = EXCLUDED.name,
    updated_at = NOW();

INSERT INTO brands (
    id, tenant_id, name, description, slug, website, industry,
    company_size, timezone, currency, is_active, is_verified,
    onboarding_completed, created_at, updated_at
)
VALUES (
    'brand-acme-corp-001',
    'tenant-acme-corp-001',
    'Acme Corporation',
    'Leading technology solutions provider specializing in enterprise software, cloud infrastructure, and digital transformation services.',
    'acme-corporation',
    'https://acme-corp.example.com',
    'technology',
    'medium',
    'America/New_York',
    'USD',
    true,
    true,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    website = EXCLUDED.website,
    industry = EXCLUDED.industry,
    company_size = EXCLUDED.company_size,
    is_active = EXCLUDED.is_active,
    updated_at = NOW();

-- Brand 2: Global Retail Co (Retail/E-commerce)
INSERT INTO tenants (id, name, slug, plan_tier, status, created_at, updated_at)
VALUES (
    'tenant-global-retail-002',
    'Global Retail Co',
    'global-retail-co',
    'professional',
    'active',
    NOW(),
    NOW()
) ON CONFLICT (slug) DO UPDATE SET
    name = EXCLUDED.name,
    updated_at = NOW();

INSERT INTO brands (
    id, tenant_id, name, description, slug, website, industry,
    company_size, timezone, currency, is_active, is_verified,
    onboarding_completed, created_at, updated_at
)
VALUES (
    'brand-global-retail-002',
    'tenant-global-retail-002',
    'Global Retail Co',
    'International e-commerce platform offering diverse product categories with seamless shopping experiences across web and mobile.',
    'global-retail-co',
    'https://globalretail.example.com',
    'retail',
    'large',
    'America/Los_Angeles',
    'USD',
    true,
    true,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    website = EXCLUDED.website,
    industry = EXCLUDED.industry,
    company_size = EXCLUDED.company_size,
    is_active = EXCLUDED.is_active,
    updated_at = NOW();

-- Brand 3: HealthTech Plus (Healthcare/SaaS)
INSERT INTO tenants (id, name, slug, plan_tier, status, created_at, updated_at)
VALUES (
    'tenant-healthtech-plus-003',
    'HealthTech Plus',
    'healthtech-plus',
    'enterprise',
    'active',
    NOW(),
    NOW()
) ON CONFLICT (slug) DO UPDATE SET
    name = EXCLUDED.name,
    updated_at = NOW();

INSERT INTO brands (
    id, tenant_id, name, description, slug, website, industry,
    company_size, timezone, currency, is_active, is_verified,
    onboarding_completed, created_at, updated_at
)
VALUES (
    'brand-healthtech-plus-003',
    'tenant-healthtech-plus-003',
    'HealthTech Plus',
    'Innovative healthcare technology platform providing SaaS solutions for patient management, telemedicine, and health data analytics.',
    'healthtech-plus',
    'https://healthtechplus.example.com',
    'healthcare',
    'medium',
    'America/Chicago',
    'USD',
    true,
    true,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    website = EXCLUDED.website,
    industry = EXCLUDED.industry,
    company_size = EXCLUDED.company_size,
    is_active = EXCLUDED.is_active,
    updated_at = NOW();

-- Brand 4: Creative Agency Pro (Marketing/Agency) - SHARED BRAND
INSERT INTO tenants (id, name, slug, plan_tier, status, created_at, updated_at)
VALUES (
    'tenant-creative-agency-004',
    'Creative Agency Pro',
    'creative-agency-pro',
    'professional',
    'active',
    NOW(),
    NOW()
) ON CONFLICT (slug) DO UPDATE SET
    name = EXCLUDED.name,
    updated_at = NOW();

INSERT INTO brands (
    id, tenant_id, name, description, slug, website, industry,
    company_size, timezone, currency, is_active, is_verified,
    onboarding_completed, created_at, updated_at
)
VALUES (
    'brand-creative-agency-004',
    'tenant-creative-agency-004',
    'Creative Agency Pro',
    'Full-service creative marketing agency specializing in brand strategy, digital campaigns, content creation, and multi-channel advertising.',
    'creative-agency-pro',
    'https://creativeagencypro.example.com',
    'marketing',
    'small',
    'America/New_York',
    'USD',
    true,
    true,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    website = EXCLUDED.website,
    industry = EXCLUDED.industry,
    company_size = EXCLUDED.company_size,
    is_active = EXCLUDED.is_active,
    updated_at = NOW();

-- Step 3: Create Demo Users with bcrypt hashed passwords
-- Password for all users: demo123
-- Bcrypt hash (generated via passlib.context.CryptContext): $2b$12$xQ16Mz8KUCgiCILc.1R4PeV.7YIj3OjZl9t/DujPityJ/cAtL24AS

-- User 1: demo1@engarde.ai
INSERT INTO users (
    id, email, hashed_password, first_name, last_name,
    user_type, is_active, is_superuser, created_at, updated_at
)
VALUES (
    'user-demo1-engarde-001',
    'demo1@engarde.ai',
    '$2b$12$xQ16Mz8KUCgiCILc.1R4PeV.7YIj3OjZl9t/DujPityJ/cAtL24AS',
    'Demo',
    'User One',
    'brand',
    true,
    false,
    NOW(),
    NOW()
) ON CONFLICT (email) DO UPDATE SET
    user_type = 'brand',
    is_active = true,
    updated_at = NOW();

-- User 2: demo2@engarde.ai
INSERT INTO users (
    id, email, hashed_password, first_name, last_name,
    user_type, is_active, is_superuser, created_at, updated_at
)
VALUES (
    'user-demo2-engarde-002',
    'demo2@engarde.ai',
    '$2b$12$xQ16Mz8KUCgiCILc.1R4PeV.7YIj3OjZl9t/DujPityJ/cAtL24AS',
    'Demo',
    'User Two',
    'brand',
    true,
    false,
    NOW(),
    NOW()
) ON CONFLICT (email) DO UPDATE SET
    user_type = 'brand',
    is_active = true,
    updated_at = NOW();

-- User 3: demo3@engarde.ai
INSERT INTO users (
    id, email, hashed_password, first_name, last_name,
    user_type, is_active, is_superuser, created_at, updated_at
)
VALUES (
    'user-demo3-engarde-003',
    'demo3@engarde.ai',
    '$2b$12$xQ16Mz8KUCgiCILc.1R4PeV.7YIj3OjZl9t/DujPityJ/cAtL24AS',
    'Demo',
    'User Three',
    'brand',
    true,
    false,
    NOW(),
    NOW()
) ON CONFLICT (email) DO UPDATE SET
    user_type = 'brand',
    is_active = true,
    updated_at = NOW();

-- Update existing admin user to ensure it's a brand user
UPDATE users
SET user_type = 'brand', updated_at = NOW()
WHERE email = 'admin@demo.engarde.ai';

-- Step 4: Create Tenant-User Relationships
-- User 1 -> Tenant 1 (Acme Corp)
INSERT INTO tenant_users (id, tenant_id, user_id, created_at)
VALUES (
    'tenant-user-demo1-acme',
    'tenant-acme-corp-001',
    'user-demo1-engarde-001',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- User 1 -> Tenant 4 (Creative Agency - shared)
INSERT INTO tenant_users (id, tenant_id, user_id, created_at)
VALUES (
    'tenant-user-demo1-creative',
    'tenant-creative-agency-004',
    'user-demo1-engarde-001',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- User 2 -> Tenant 2 (Global Retail)
INSERT INTO tenant_users (id, tenant_id, user_id, created_at)
VALUES (
    'tenant-user-demo2-retail',
    'tenant-global-retail-002',
    'user-demo2-engarde-002',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- User 2 -> Tenant 4 (Creative Agency - shared)
INSERT INTO tenant_users (id, tenant_id, user_id, created_at)
VALUES (
    'tenant-user-demo2-creative',
    'tenant-creative-agency-004',
    'user-demo2-engarde-002',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- User 3 -> Tenant 3 (HealthTech)
INSERT INTO tenant_users (id, tenant_id, user_id, created_at)
VALUES (
    'tenant-user-demo3-healthtech',
    'tenant-healthtech-plus-003',
    'user-demo3-engarde-003',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Step 5: Create Brand Memberships with Roles
-- User 1: OWNER of Brand 1 (Acme Corp)
INSERT INTO brand_members (
    id, brand_id, user_id, tenant_id, role, is_active,
    joined_at, created_at, updated_at
)
VALUES (
    'brand-member-demo1-acme',
    'brand-acme-corp-001',
    'user-demo1-engarde-001',
    'tenant-acme-corp-001',
    'owner',
    true,
    NOW(),
    NOW(),
    NOW()
) ON CONFLICT (brand_id, user_id) DO UPDATE SET
    role = 'owner',
    is_active = true,
    updated_at = NOW();

-- User 1: MEMBER of Brand 4 (Creative Agency - shared)
INSERT INTO brand_members (
    id, brand_id, user_id, tenant_id, role, is_active,
    joined_at, created_at, updated_at
)
VALUES (
    'brand-member-demo1-creative',
    'brand-creative-agency-004',
    'user-demo1-engarde-001',
    'tenant-creative-agency-004',
    'member',
    true,
    NOW(),
    NOW(),
    NOW()
) ON CONFLICT (brand_id, user_id) DO UPDATE SET
    role = 'member',
    is_active = true,
    updated_at = NOW();

-- User 2: OWNER of Brand 2 (Global Retail)
INSERT INTO brand_members (
    id, brand_id, user_id, tenant_id, role, is_active,
    joined_at, created_at, updated_at
)
VALUES (
    'brand-member-demo2-retail',
    'brand-global-retail-002',
    'user-demo2-engarde-002',
    'tenant-global-retail-002',
    'owner',
    true,
    NOW(),
    NOW(),
    NOW()
) ON CONFLICT (brand_id, user_id) DO UPDATE SET
    role = 'owner',
    is_active = true,
    updated_at = NOW();

-- User 2: ADMIN of Brand 4 (Creative Agency - for team admin testing)
INSERT INTO brand_members (
    id, brand_id, user_id, tenant_id, role, is_active,
    joined_at, created_at, updated_at
)
VALUES (
    'brand-member-demo2-creative',
    'brand-creative-agency-004',
    'user-demo2-engarde-002',
    'tenant-creative-agency-004',
    'admin',
    true,
    NOW(),
    NOW(),
    NOW()
) ON CONFLICT (brand_id, user_id) DO UPDATE SET
    role = 'admin',
    is_active = true,
    updated_at = NOW();

-- User 3: OWNER of Brand 3 (HealthTech)
INSERT INTO brand_members (
    id, brand_id, user_id, tenant_id, role, is_active,
    joined_at, created_at, updated_at
)
VALUES (
    'brand-member-demo3-healthtech',
    'brand-healthtech-plus-003',
    'user-demo3-engarde-003',
    'tenant-healthtech-plus-003',
    'owner',
    true,
    NOW(),
    NOW(),
    NOW()
) ON CONFLICT (brand_id, user_id) DO UPDATE SET
    role = 'owner',
    is_active = true,
    updated_at = NOW();

-- Step 6: Set Up User Active Brands (Primary Brand for Each User)
-- User 1 -> Brand 1 (Acme Corp)
INSERT INTO user_active_brands (
    id, user_id, brand_id, tenant_id, switch_count,
    last_switched_at, created_at, updated_at
)
VALUES (
    'active-brand-demo1',
    'user-demo1-engarde-001',
    'brand-acme-corp-001',
    'tenant-acme-corp-001',
    0,
    NOW(),
    NOW(),
    NOW()
) ON CONFLICT (user_id) DO UPDATE SET
    brand_id = 'brand-acme-corp-001',
    tenant_id = 'tenant-acme-corp-001',
    updated_at = NOW();

-- User 2 -> Brand 2 (Global Retail)
INSERT INTO user_active_brands (
    id, user_id, brand_id, tenant_id, switch_count,
    last_switched_at, created_at, updated_at
)
VALUES (
    'active-brand-demo2',
    'user-demo2-engarde-002',
    'brand-global-retail-002',
    'tenant-global-retail-002',
    0,
    NOW(),
    NOW(),
    NOW()
) ON CONFLICT (user_id) DO UPDATE SET
    brand_id = 'brand-global-retail-002',
    tenant_id = 'tenant-global-retail-002',
    updated_at = NOW();

-- User 3 -> Brand 3 (HealthTech)
INSERT INTO user_active_brands (
    id, user_id, brand_id, tenant_id, switch_count,
    last_switched_at, created_at, updated_at
)
VALUES (
    'active-brand-demo3',
    'user-demo3-engarde-003',
    'brand-healthtech-plus-003',
    'tenant-healthtech-plus-003',
    0,
    NOW(),
    NOW(),
    NOW()
) ON CONFLICT (user_id) DO UPDATE SET
    brand_id = 'brand-healthtech-plus-003',
    tenant_id = 'tenant-healthtech-plus-003',
    updated_at = NOW();

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Verify all brands were created
SELECT
    b.id,
    b.name,
    b.slug,
    b.industry,
    b.is_active,
    t.name as tenant_name
FROM brands b
LEFT JOIN tenants t ON b.tenant_id = t.id
WHERE b.id IN (
    'brand-acme-corp-001',
    'brand-global-retail-002',
    'brand-healthtech-plus-003',
    'brand-creative-agency-004'
)
ORDER BY b.name;

-- Verify all users were created
SELECT
    id,
    email,
    first_name,
    last_name,
    user_type,
    is_active
FROM users
WHERE email IN (
    'demo1@engarde.ai',
    'demo2@engarde.ai',
    'demo3@engarde.ai',
    'admin@demo.engarde.ai'
)
ORDER BY email;

-- Verify brand memberships
SELECT
    u.email,
    u.first_name || ' ' || u.last_name as user_name,
    b.name as brand_name,
    bm.role,
    bm.is_active
FROM brand_members bm
JOIN users u ON bm.user_id = u.id
JOIN brands b ON bm.brand_id = b.id
WHERE u.email IN (
    'demo1@engarde.ai',
    'demo2@engarde.ai',
    'demo3@engarde.ai'
)
ORDER BY u.email, b.name;

-- Verify Brand 4 (Creative Agency) has 2 members
SELECT
    b.name as brand_name,
    u.email,
    u.first_name || ' ' || u.last_name as user_name,
    bm.role,
    bm.is_active
FROM brand_members bm
JOIN users u ON bm.user_id = u.id
JOIN brands b ON bm.brand_id = b.id
WHERE b.id = 'brand-creative-agency-004'
ORDER BY bm.role DESC, u.email;

-- Verify user active brands
SELECT
    u.email,
    b.name as active_brand,
    uab.tenant_id
FROM user_active_brands uab
JOIN users u ON uab.user_id = u.id
LEFT JOIN brands b ON uab.brand_id = b.id
WHERE u.email IN (
    'demo1@engarde.ai',
    'demo2@engarde.ai',
    'demo3@engarde.ai'
)
ORDER BY u.email;

-- Summary: Count memberships per user
SELECT
    u.email,
    u.first_name || ' ' || u.last_name as user_name,
    COUNT(bm.id) as brand_count,
    STRING_AGG(b.name || ' (' || bm.role || ')', ', ' ORDER BY b.name) as brands
FROM users u
LEFT JOIN brand_members bm ON u.id = bm.user_id AND bm.is_active = true
LEFT JOIN brands b ON bm.brand_id = b.id
WHERE u.email IN (
    'demo1@engarde.ai',
    'demo2@engarde.ai',
    'demo3@engarde.ai'
)
GROUP BY u.id, u.email, u.first_name, u.last_name
ORDER BY u.email;
