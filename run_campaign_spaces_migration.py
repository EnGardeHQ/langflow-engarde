#!/usr/bin/env python3
"""
Run campaign spaces migration directly on Railway database
"""
import psycopg2
import sys

# Database connection
DATABASE_URL = "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"

def run_migration():
    conn = None
    try:
        print("🔌 Connecting to Railway database...")
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()

        print("📊 Checking if campaign_spaces table already exists...")
        cursor.execute("""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
            AND table_name = 'campaign_spaces';
        """)

        if cursor.fetchone():
            print("⚠️  campaign_spaces table already exists! Skipping migration.")
            cursor.close()
            conn.close()
            return

        print("➕ Creating enums for campaign spaces...")

        # Check if enums already exist
        cursor.execute("SELECT typname FROM pg_type WHERE typname = 'adplatform';")
        if not cursor.fetchone():
            cursor.execute("""
                CREATE TYPE adplatform AS ENUM (
                    'google_ads', 'meta', 'linkedin', 'twitter', 'tiktok',
                    'snapchat', 'pinterest', 'reddit', 'amazon_ads',
                    'microsoft_ads', 'youtube', 'other'
                )
            """)
            print("✅ Created adplatform enum")
        else:
            print("⚠️  adplatform enum already exists")

        cursor.execute("SELECT typname FROM pg_type WHERE typname = 'campaignassettype';")
        if not cursor.fetchone():
            cursor.execute("""
                CREATE TYPE campaignassettype AS ENUM (
                    'image', 'video', 'ad_copy', 'headline', 'description',
                    'call_to_action', 'document', 'performance_data', 'other'
                )
            """)
            print("✅ Created campaignassettype enum")
        else:
            print("⚠️  campaignassettype enum already exists")

        cursor.execute("SELECT typname FROM pg_type WHERE typname = 'campaignimportsource';")
        if not cursor.fetchone():
            cursor.execute("""
                CREATE TYPE campaignimportsource AS ENUM (
                    'manual_upload', 'platform_api', 'csv_import', 'bulk_import'
                )
            """)
            print("✅ Created campaignimportsource enum")
        else:
            print("⚠️  campaignimportsource enum already exists")

        print("➕ Creating campaign_spaces table...")
        cursor.execute("""
            CREATE TABLE campaign_spaces (
                -- Primary key
                id VARCHAR(36) PRIMARY KEY,

                -- Multi-tenancy and ownership
                tenant_id VARCHAR(36) NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
                brand_id VARCHAR(36) REFERENCES brands(id) ON DELETE CASCADE,
                user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,

                -- Campaign identification
                campaign_name VARCHAR(255) NOT NULL,
                campaign_slug VARCHAR(255),
                platform adplatform NOT NULL,
                external_campaign_id VARCHAR(255),

                -- Campaign metadata
                description TEXT,
                campaign_objective VARCHAR(100),
                target_audience TEXT,
                budget FLOAT,
                currency VARCHAR(3) DEFAULT 'USD',

                -- Time tracking
                campaign_start_date TIMESTAMP,
                campaign_end_date TIMESTAMP,
                is_active BOOLEAN DEFAULT false,

                -- Import details
                import_source campaignimportsource NOT NULL,
                import_metadata JSONB DEFAULT '{}' NOT NULL,
                imported_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                imported_by VARCHAR(36) REFERENCES users(id) ON DELETE SET NULL,

                -- Organization
                tags VARCHAR[] DEFAULT '{}' NOT NULL,
                category VARCHAR(100),

                -- Template capabilities
                is_template BOOLEAN DEFAULT false,
                template_metadata JSONB DEFAULT '{}' NOT NULL,

                -- Langflow integration
                langflow_flow_id VARCHAR(255),
                langflow_execution_history JSONB DEFAULT '[]',

                -- Performance summary (cached from BigQuery)
                total_impressions INTEGER DEFAULT 0,
                total_clicks INTEGER DEFAULT 0,
                total_spend FLOAT DEFAULT 0.0,
                total_conversions INTEGER DEFAULT 0,
                total_revenue FLOAT DEFAULT 0.0,
                avg_ctr FLOAT DEFAULT 0.0,
                avg_roas FLOAT DEFAULT 0.0,
                performance_last_updated TIMESTAMP,

                -- Asset counts
                asset_count INTEGER DEFAULT 0,
                total_asset_size_bytes INTEGER DEFAULT 0,

                -- Status
                is_archived BOOLEAN DEFAULT false,
                archived_at TIMESTAMP,

                -- Timestamps
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                deleted_at TIMESTAMP
            );
        """)
        print("✅ campaign_spaces table created successfully!")

        print("📈 Creating indexes for campaign_spaces...")
        indexes = [
            "CREATE INDEX ix_campaign_spaces_tenant_id ON campaign_spaces(tenant_id);",
            "CREATE INDEX ix_campaign_spaces_brand_id ON campaign_spaces(brand_id);",
            "CREATE INDEX ix_campaign_spaces_user_id ON campaign_spaces(user_id);",
            "CREATE INDEX ix_campaign_spaces_campaign_name ON campaign_spaces(campaign_name);",
            "CREATE INDEX ix_campaign_spaces_campaign_slug ON campaign_spaces(campaign_slug);",
            "CREATE INDEX ix_campaign_spaces_platform ON campaign_spaces(platform);",
            "CREATE INDEX ix_campaign_spaces_external_campaign_id ON campaign_spaces(external_campaign_id);",
            "CREATE INDEX ix_campaign_spaces_import_source ON campaign_spaces(import_source);",
            "CREATE INDEX ix_campaign_spaces_is_template ON campaign_spaces(is_template);",
            "CREATE INDEX ix_campaign_spaces_is_archived ON campaign_spaces(is_archived);",
            "CREATE INDEX ix_campaign_spaces_created_at ON campaign_spaces(created_at);",
            "CREATE INDEX ix_campaign_spaces_tenant_brand ON campaign_spaces(tenant_id, brand_id);",
            "CREATE INDEX ix_campaign_spaces_platform_active ON campaign_spaces(platform, is_active);",
            "CREATE INDEX ix_campaign_spaces_template ON campaign_spaces(is_template, platform);",
            "CREATE INDEX ix_campaign_spaces_tenant_platform ON campaign_spaces(tenant_id, platform);"
        ]

        for idx_sql in indexes:
            cursor.execute(idx_sql)

        print("✅ All indexes created successfully!")

        print("➕ Creating campaign_assets table...")
        cursor.execute("""
            CREATE TABLE campaign_assets (
                -- Primary key
                id VARCHAR(36) PRIMARY KEY,

                -- Parent campaign space
                campaign_space_id VARCHAR(36) NOT NULL REFERENCES campaign_spaces(id) ON DELETE CASCADE,

                -- Multi-tenancy
                tenant_id VARCHAR(36) NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
                brand_id VARCHAR(36) REFERENCES brands(id) ON DELETE SET NULL,
                user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,

                -- Asset identification
                asset_name VARCHAR(255) NOT NULL,
                asset_type campaignassettype NOT NULL,
                external_asset_id VARCHAR(255),

                -- File storage (GCS)
                file_url TEXT,
                public_url TEXT,
                gcs_path VARCHAR(500),
                file_hash VARCHAR(64),
                file_size INTEGER,
                mime_type VARCHAR(100),

                -- Content metadata
                title VARCHAR(255),
                description TEXT,
                ad_copy_text TEXT,
                headline_text VARCHAR(500),
                cta_text VARCHAR(100),
                tags VARCHAR[] DEFAULT '{}' NOT NULL,

                -- Media metadata
                width INTEGER,
                height INTEGER,
                duration INTEGER,
                thumbnail_url TEXT,

                -- Performance metadata
                impressions INTEGER DEFAULT 0,
                clicks INTEGER DEFAULT 0,
                conversions INTEGER DEFAULT 0,
                spend FLOAT DEFAULT 0.0,
                ctr FLOAT DEFAULT 0.0,
                performance_data JSONB DEFAULT '{}' NOT NULL,

                -- Platform-specific data
                platform_metadata JSONB DEFAULT '{}' NOT NULL,
                platform_variants JSONB DEFAULT '{}' NOT NULL,

                -- Usage tracking
                reused_count INTEGER DEFAULT 0,
                last_reused_at TIMESTAMP,

                -- Import metadata
                import_metadata JSONB DEFAULT '{}' NOT NULL,
                imported_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

                -- Timestamps
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                deleted_at TIMESTAMP
            );
        """)
        print("✅ campaign_assets table created successfully!")

        print("📈 Creating indexes for campaign_assets...")
        asset_indexes = [
            "CREATE INDEX ix_campaign_assets_campaign_space_id ON campaign_assets(campaign_space_id);",
            "CREATE INDEX ix_campaign_assets_tenant_id ON campaign_assets(tenant_id);",
            "CREATE INDEX ix_campaign_assets_brand_id ON campaign_assets(brand_id);",
            "CREATE INDEX ix_campaign_assets_user_id ON campaign_assets(user_id);",
            "CREATE INDEX ix_campaign_assets_asset_type ON campaign_assets(asset_type);",
            "CREATE INDEX ix_campaign_assets_external_asset_id ON campaign_assets(external_asset_id);",
            "CREATE INDEX ix_campaign_assets_file_hash ON campaign_assets(file_hash);",
            "CREATE INDEX ix_campaign_assets_created_at ON campaign_assets(created_at);",
            "CREATE INDEX ix_campaign_assets_space_type ON campaign_assets(campaign_space_id, asset_type);",
            "CREATE INDEX ix_campaign_assets_tenant_type ON campaign_assets(tenant_id, asset_type);",
            "CREATE INDEX ix_campaign_assets_hash ON campaign_assets(file_hash);"
        ]

        for idx_sql in asset_indexes:
            cursor.execute(idx_sql)

        print("✅ All campaign_assets indexes created successfully!")

        # Commit the changes
        conn.commit()
        print("\n✅ Campaign spaces migration completed successfully!")

        cursor.close()

    except Exception as e:
        print(f"❌ Error running migration: {e}")
        if conn:
            conn.rollback()
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        if conn:
            conn.close()
            print("\n🔌 Database connection closed")

if __name__ == "__main__":
    print("=" * 60)
    print("CAMPAIGN SPACES MIGRATION")
    print("=" * 60)
    print()
    run_migration()
