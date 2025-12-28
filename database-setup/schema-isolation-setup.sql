-- ============================================================================
-- En Garde Microservices Schema Isolation Setup
-- ============================================================================
-- Purpose: Create separate schemas for each microservice while using the
--          same PostgreSQL database for cost efficiency and operational simplicity
-- 
-- Database: En Garde Production PostgreSQL (Railway)
-- Date: December 2024
-- ============================================================================

-- ============================================================================
-- 1. CREATE SCHEMAS
-- ============================================================================

-- MadanSara: Intelligence layer for audience conversion and outreach
CREATE SCHEMA IF NOT EXISTS madansara;

-- Sankore: Ad intelligence and trend analysis
CREATE SCHEMA IF NOT EXISTS sankore;

-- Onside: SEO and content intelligence
CREATE SCHEMA IF NOT EXISTS onside;

-- Langflow: Flow builder and execution engine
CREATE SCHEMA IF NOT EXISTS langflow;

-- NOTE: EasyAppointments/Scheduler uses MySQL and maintains its own separate database
-- It is NOT included in this PostgreSQL schema isolation setup

-- Production Backend: Main application (already exists as 'public' or custom schema)
-- Note: If your production backend uses 'public' schema, leave it as is
-- If it uses a custom schema, create it here:
-- CREATE SCHEMA IF NOT EXISTS production_backend;

COMMENT ON SCHEMA madansara IS 'Madan Sara - Audience conversion and multi-channel outreach intelligence';
COMMENT ON SCHEMA sankore IS 'Sankore - Ad intelligence, trend tracking, and competitive analysis';
COMMENT ON SCHEMA onside IS 'Onside - SEO intelligence and content optimization';
COMMENT ON SCHEMA langflow IS 'Langflow - Flow builder and workflow execution engine';

-- ============================================================================
-- 2. CREATE SERVICE-SPECIFIC DATABASE USERS (Optional but Recommended)
-- ============================================================================
-- This provides an additional layer of security by ensuring each service
-- can only access its own schema

-- Note: Replace 'SECURE_PASSWORD_HERE' with actual secure passwords
-- You can generate secure passwords with: openssl rand -base64 32

-- MadanSara User
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'madansara_user') THEN
        CREATE USER madansara_user WITH PASSWORD 'SECURE_PASSWORD_HERE';
    END IF;
END
$$;

-- Sankore User
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'sankore_user') THEN
        CREATE USER sankore_user WITH PASSWORD 'SECURE_PASSWORD_HERE';
    END IF;
END
$$;

-- Onside User
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'onside_user') THEN
        CREATE USER onside_user WITH PASSWORD 'SECURE_PASSWORD_HERE';
    END IF;
END
$$;

-- Langflow User
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'langflow_user') THEN
        CREATE USER langflow_user WITH PASSWORD 'SECURE_PASSWORD_HERE';
    END IF;
END
$$;

-- ============================================================================
-- 3. GRANT PERMISSIONS
-- ============================================================================

-- MadanSara Permissions
GRANT CONNECT ON DATABASE postgres TO madansara_user;  -- Replace 'postgres' with your actual DB name
GRANT USAGE ON SCHEMA madansara TO madansara_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA madansara TO madansara_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA madansara TO madansara_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA madansara TO madansara_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA madansara GRANT ALL ON TABLES TO madansara_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA madansara GRANT ALL ON SEQUENCES TO madansara_user;

-- Sankore Permissions
GRANT CONNECT ON DATABASE postgres TO sankore_user;
GRANT USAGE ON SCHEMA sankore TO sankore_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA sankore TO sankore_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA sankore TO sankore_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA sankore TO sankore_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA sankore GRANT ALL ON TABLES TO sankore_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA sankore GRANT ALL ON SEQUENCES TO sankore_user;

-- Onside Permissions
GRANT CONNECT ON DATABASE postgres TO onside_user;
GRANT USAGE ON SCHEMA onside TO onside_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA onside TO onside_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA onside TO onside_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA onside TO onside_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA onside GRANT ALL ON TABLES TO onside_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA onside GRANT ALL ON SEQUENCES TO onside_user;

-- Langflow Permissions
GRANT CONNECT ON DATABASE postgres TO langflow_user;
GRANT USAGE ON SCHEMA langflow TO langflow_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA langflow TO langflow_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA langflow TO langflow_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA langflow TO langflow_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA langflow GRANT ALL ON TABLES TO langflow_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA langflow GRANT ALL ON SEQUENCES TO langflow_user;



-- ============================================================================
-- 4. REVOKE CROSS-SCHEMA ACCESS (Security Hardening)
-- ============================================================================
-- Ensure each service can ONLY access its own schema

REVOKE ALL ON SCHEMA sankore FROM madansara_user;
REVOKE ALL ON SCHEMA onside FROM madansara_user;
REVOKE ALL ON SCHEMA langflow FROM madansara_user;
REVOKE ALL ON SCHEMA public FROM madansara_user;

REVOKE ALL ON SCHEMA madansara FROM sankore_user;
REVOKE ALL ON SCHEMA onside FROM sankore_user;
REVOKE ALL ON SCHEMA langflow FROM sankore_user;
REVOKE ALL ON SCHEMA public FROM sankore_user;

REVOKE ALL ON SCHEMA madansara FROM onside_user;
REVOKE ALL ON SCHEMA sankore FROM onside_user;
REVOKE ALL ON SCHEMA langflow FROM onside_user;
REVOKE ALL ON SCHEMA public FROM onside_user;

REVOKE ALL ON SCHEMA madansara FROM langflow_user;
REVOKE ALL ON SCHEMA sankore FROM langflow_user;
REVOKE ALL ON SCHEMA onside FROM langflow_user;
REVOKE ALL ON SCHEMA public FROM langflow_user;

-- ============================================================================
-- 5. CREATE READ-ONLY ANALYTICS USER (Optional)
-- ============================================================================
-- For cross-service analytics and reporting

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'analytics_readonly') THEN
        CREATE USER analytics_readonly WITH PASSWORD 'SECURE_PASSWORD_HERE';
    END IF;
END
$$;

GRANT CONNECT ON DATABASE postgres TO analytics_readonly;
GRANT USAGE ON SCHEMA madansara, sankore, onside, langflow TO analytics_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA madansara TO analytics_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA sankore TO analytics_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA onside TO analytics_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA langflow TO analytics_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA madansara GRANT SELECT ON TABLES TO analytics_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA sankore GRANT SELECT ON TABLES TO analytics_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA onside GRANT SELECT ON TABLES TO analytics_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA langflow GRANT SELECT ON TABLES TO analytics_readonly;

-- ============================================================================
-- 6. VERIFICATION QUERIES
-- ============================================================================
-- Run these to verify the setup

-- List all schemas
SELECT schema_name 
FROM information_schema.schemata 
WHERE schema_name IN ('madansara', 'sankore', 'onside', 'langflow')
ORDER BY schema_name;

-- List all service users
SELECT usename, usecreatedb, usesuper 
FROM pg_catalog.pg_user 
WHERE usename LIKE '%_user' OR usename = 'analytics_readonly'
ORDER BY usename;

-- Check schema permissions for each user
SELECT 
    grantee,
    table_schema,
    privilege_type
FROM information_schema.schema_privileges
WHERE table_schema IN ('madansara', 'sankore', 'onside', 'langflow')
ORDER BY grantee, table_schema;

-- ============================================================================
-- 7. NEXT STEPS
-- ============================================================================
-- After running this script:
--
-- 1. Update Railway environment variables for each service:
--    
--    MadanSara:
--    DATABASE_URL=postgresql://madansara_user:PASSWORD@HOST:5432/DB_NAME?options=-c%20search_path=madansara,public
--    
--    Sankore:
--    DATABASE_URL=postgresql://sankore_user:PASSWORD@HOST:5432/DB_NAME?options=-c%20search_path=sankore,public
--    
--    Onside:
--    DATABASE_URL=postgresql://onside_user:PASSWORD@HOST:5432/DB_NAME?options=-c%20search_path=onside,public
--    
--    Langflow:
--    DATABASE_URL=postgresql://langflow_user:PASSWORD@HOST:5432/DB_NAME?options=-c%20search_path=langflow,public
--    
--    Scheduler:
--    DATABASE_URL=postgresql://scheduler_user:PASSWORD@HOST:5432/DB_NAME?options=-c%20search_path=scheduler,public
--
-- 2. Update Alembic configurations to use schema-specific version tables
--
-- 3. Run migrations for each service:
--    cd MadanSara && alembic upgrade head
--    cd Sankore && alembic upgrade head
--    cd Onside && alembic upgrade head
--
-- 4. Test cross-service analytics with analytics_readonly user
--
-- ============================================================================
