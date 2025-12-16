-- ============================================================================
-- EnGarde Demo Data - INSERT/UPDATE Statements Summary
-- All statements executed successfully on 2025-10-29
-- ============================================================================

-- SCHEMA CHANGE
-- -----------------------------------------------------------------------------
ALTER TABLE users ALTER COLUMN user_type SET DEFAULT 'brand';
-- Result: ALTER TABLE


-- TENANT INSERTS (4 tenants)
-- -----------------------------------------------------------------------------
INSERT INTO tenants (id, name, slug, plan_tier, status, created_at, updated_at)
VALUES ('tenant-acme-corp-001', 'Acme Corporation', 'acme-corporation', 'professional', 'active', NOW(), NOW())
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, updated_at = NOW();
-- Result: INSERT 0 1

INSERT INTO tenants (id, name, slug, plan_tier, status, created_at, updated_at)
VALUES ('tenant-global-retail-002', 'Global Retail Co', 'global-retail-co', 'professional', 'active', NOW(), NOW())
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, updated_at = NOW();
-- Result: INSERT 0 1

INSERT INTO tenants (id, name, slug, plan_tier, status, created_at, updated_at)
VALUES ('tenant-healthtech-plus-003', 'HealthTech Plus', 'healthtech-plus', 'enterprise', 'active', NOW(), NOW())
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, updated_at = NOW();
-- Result: INSERT 0 1

INSERT INTO tenants (id, name, slug, plan_tier, status, created_at, updated_at)
VALUES ('tenant-creative-agency-004', 'Creative Agency Pro', 'creative-agency-pro', 'professional', 'active', NOW(), NOW())
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, updated_at = NOW();
-- Result: INSERT 0 1


-- BRAND INSERTS (4 brands)
-- -----------------------------------------------------------------------------
INSERT INTO brands (
    id, tenant_id, name, description, slug, website, industry,
    company_size, timezone, currency, is_active, is_verified,
    onboarding_completed, created_at, updated_at
) VALUES (
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
-- Result: INSERT 0 1

INSERT INTO brands (
    id, tenant_id, name, description, slug, website, industry,
    company_size, timezone, currency, is_active, is_verified,
    onboarding_completed, created_at, updated_at
) VALUES (
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
-- Result: INSERT 0 1

INSERT INTO brands (
    id, tenant_id, name, description, slug, website, industry,
    company_size, timezone, currency, is_active, is_verified,
    onboarding_completed, created_at, updated_at
) VALUES (
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
-- Result: INSERT 0 1

INSERT INTO brands (
    id, tenant_id, name, description, slug, website, industry,
    company_size, timezone, currency, is_active, is_verified,
    onboarding_completed, created_at, updated_at
) VALUES (
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
-- Result: INSERT 0 1


-- USER INSERTS (3 new users)
-- Password for all users: demo123
-- Bcrypt hash: $2b$12$xQ16Mz8KUCgiCILc.1R4PeV.7YIj3OjZl9t/DujPityJ/cAtL24AS
-- -----------------------------------------------------------------------------
INSERT INTO users (
    id, email, hashed_password, first_name, last_name,
    user_type, is_active, is_superuser, created_at, updated_at
) VALUES (
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
-- Result: INSERT 0 1

INSERT INTO users (
    id, email, hashed_password, first_name, last_name,
    user_type, is_active, is_superuser, created_at, updated_at
) VALUES (
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
-- Result: INSERT 0 1

INSERT INTO users (
    id, email, hashed_password, first_name, last_name,
    user_type, is_active, is_superuser, created_at, updated_at
) VALUES (
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
-- Result: INSERT 0 1


-- USER UPDATE (existing admin user)
-- -----------------------------------------------------------------------------
UPDATE users
SET user_type = 'brand', updated_at = NOW()
WHERE email = 'admin@demo.engarde.ai';
-- Result: UPDATE 1


-- TENANT-USER RELATIONSHIPS (5 tenant-user links)
-- -----------------------------------------------------------------------------
INSERT INTO tenant_users (id, tenant_id, user_id, created_at)
VALUES ('tenant-user-demo1-acme', 'tenant-acme-corp-001', 'user-demo1-engarde-001', NOW())
ON CONFLICT (id) DO NOTHING;
-- Result: INSERT 0 1

INSERT INTO tenant_users (id, tenant_id, user_id, created_at)
VALUES ('tenant-user-demo1-creative', 'tenant-creative-agency-004', 'user-demo1-engarde-001', NOW())
ON CONFLICT (id) DO NOTHING;
-- Result: INSERT 0 1

INSERT INTO tenant_users (id, tenant_id, user_id, created_at)
VALUES ('tenant-user-demo2-retail', 'tenant-global-retail-002', 'user-demo2-engarde-002', NOW())
ON CONFLICT (id) DO NOTHING;
-- Result: INSERT 0 1

INSERT INTO tenant_users (id, tenant_id, user_id, created_at)
VALUES ('tenant-user-demo2-creative', 'tenant-creative-agency-004', 'user-demo2-engarde-002', NOW())
ON CONFLICT (id) DO NOTHING;
-- Result: INSERT 0 1

INSERT INTO tenant_users (id, tenant_id, user_id, created_at)
VALUES ('tenant-user-demo3-healthtech', 'tenant-healthtech-plus-003', 'user-demo3-engarde-003', NOW())
ON CONFLICT (id) DO NOTHING;
-- Result: INSERT 0 1


-- BRAND MEMBERSHIPS (5 brand-user relationships with roles)
-- -----------------------------------------------------------------------------
-- User 1: OWNER of Acme Corporation
INSERT INTO brand_members (
    id, brand_id, user_id, tenant_id, role, is_active,
    joined_at, created_at, updated_at
) VALUES (
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
-- Result: INSERT 0 1

-- User 1: MEMBER of Creative Agency Pro
INSERT INTO brand_members (
    id, brand_id, user_id, tenant_id, role, is_active,
    joined_at, created_at, updated_at
) VALUES (
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
-- Result: INSERT 0 1

-- User 2: OWNER of Global Retail Co
INSERT INTO brand_members (
    id, brand_id, user_id, tenant_id, role, is_active,
    joined_at, created_at, updated_at
) VALUES (
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
-- Result: INSERT 0 1

-- User 2: ADMIN of Creative Agency Pro (for team admin testing)
INSERT INTO brand_members (
    id, brand_id, user_id, tenant_id, role, is_active,
    joined_at, created_at, updated_at
) VALUES (
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
-- Result: INSERT 0 1

-- User 3: OWNER of HealthTech Plus
INSERT INTO brand_members (
    id, brand_id, user_id, tenant_id, role, is_active,
    joined_at, created_at, updated_at
) VALUES (
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
-- Result: INSERT 0 1


-- USER ACTIVE BRANDS (3 active brand settings)
-- -----------------------------------------------------------------------------
-- User 1 -> Brand 1 (Acme Corp)
INSERT INTO user_active_brands (
    id, user_id, brand_id, tenant_id, switch_count,
    last_switched_at, created_at, updated_at
) VALUES (
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
-- Result: INSERT 0 1

-- User 2 -> Brand 2 (Global Retail)
INSERT INTO user_active_brands (
    id, user_id, brand_id, tenant_id, switch_count,
    last_switched_at, created_at, updated_at
) VALUES (
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
-- Result: INSERT 0 1

-- User 3 -> Brand 3 (HealthTech)
INSERT INTO user_active_brands (
    id, user_id, brand_id, tenant_id, switch_count,
    last_switched_at, created_at, updated_at
) VALUES (
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
-- Result: INSERT 0 1


-- ============================================================================
-- SUMMARY OF CHANGES
-- ============================================================================
-- Schema Changes: 1 (ALTER TABLE)
-- Tenants Created: 4
-- Brands Created: 4
-- Users Created: 3 new + 1 updated = 4 total
-- Tenant-User Links: 5
-- Brand Memberships: 5
-- Active Brand Settings: 3
-- ============================================================================
-- TOTAL STATEMENTS EXECUTED: 27
-- ALL SUCCESSFUL: Yes
-- ============================================================================
