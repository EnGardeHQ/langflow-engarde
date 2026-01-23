#!/usr/bin/env python3
"""
Run marketplace beta access migration directly on Railway database
"""
import psycopg2
import os

# Database connection
DATABASE_URL = "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"

def run_migration():
    conn = None
    try:
        print("🔌 Connecting to Railway database...")
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()

        print("📊 Checking if marketplace_beta_access column exists on users...")
        cursor.execute("""
            SELECT column_name
            FROM information_schema.columns
            WHERE table_name = 'users'
            AND column_name = 'marketplace_beta_access';
        """)

        if cursor.fetchone():
            print("⚠️  Marketplace beta fields already exist! Skipping migration.")
            cursor.close()
            conn.close()
            return

        print("➕ Adding marketplace_beta_access to users table...")
        cursor.execute("""
            ALTER TABLE users
            ADD COLUMN marketplace_beta_access BOOLEAN NOT NULL DEFAULT false;
        """)

        print("📈 Creating index on marketplace_beta_access...")
        cursor.execute("""
            CREATE INDEX ix_users_marketplace_beta_access ON users(marketplace_beta_access);
        """)

        print("✅ User marketplace_beta_access added successfully!")

        print("➕ Adding marketplace_enabled to tenants table...")
        cursor.execute("""
            ALTER TABLE tenants
            ADD COLUMN marketplace_enabled BOOLEAN NOT NULL DEFAULT false;
        """)

        print("✅ Tenant marketplace_enabled added successfully!")

        print("📦 Creating marketplace_beta_invitations table...")
        cursor.execute("""
            CREATE TABLE marketplace_beta_invitations (
                id VARCHAR(36) PRIMARY KEY,
                user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                tenant_id VARCHAR(36) REFERENCES tenants(id) ON DELETE CASCADE,
                invited_by VARCHAR(36) REFERENCES users(id) ON DELETE SET NULL,
                invitation_reason TEXT,
                status VARCHAR(50) NOT NULL DEFAULT 'active',
                granted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                revoked_at TIMESTAMP,
                revoked_by VARCHAR(36) REFERENCES users(id) ON DELETE SET NULL,
                revocation_reason TEXT
            );
        """)

        print("📈 Creating indexes on marketplace_beta_invitations...")
        cursor.execute("CREATE INDEX ix_marketplace_beta_invitations_user_id ON marketplace_beta_invitations(user_id);")
        cursor.execute("CREATE INDEX ix_marketplace_beta_invitations_tenant_id ON marketplace_beta_invitations(tenant_id);")
        cursor.execute("CREATE INDEX ix_marketplace_beta_invitations_status ON marketplace_beta_invitations(status);")

        print("✅ marketplace_beta_invitations table created successfully!")

        print("📦 Creating marketplace_beta_activity_logs table...")
        cursor.execute("""
            CREATE TABLE marketplace_beta_activity_logs (
                id VARCHAR(36) PRIMARY KEY,
                admin_user_id VARCHAR(36) REFERENCES users(id) ON DELETE SET NULL,
                action_type VARCHAR(100) NOT NULL,
                target_user_id VARCHAR(36) REFERENCES users(id) ON DELETE SET NULL,
                action_details JSON,
                ip_address VARCHAR(45),
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
        """)

        print("📈 Creating indexes on marketplace_beta_activity_logs...")
        cursor.execute("CREATE INDEX ix_marketplace_beta_activity_logs_admin_user_id ON marketplace_beta_activity_logs(admin_user_id);")
        cursor.execute("CREATE INDEX ix_marketplace_beta_activity_logs_target_user_id ON marketplace_beta_activity_logs(target_user_id);")
        cursor.execute("CREATE INDEX ix_marketplace_beta_activity_logs_action_type ON marketplace_beta_activity_logs(action_type);")
        cursor.execute("CREATE INDEX ix_marketplace_beta_activity_logs_created_at ON marketplace_beta_activity_logs(created_at);")

        print("✅ marketplace_beta_activity_logs table created successfully!")

        # Commit the changes
        conn.commit()
        print("\n✅ Marketplace beta access migration completed successfully!")

        cursor.close()

    except Exception as e:
        print(f"❌ Error running migration: {e}")
        if conn:
            conn.rollback()
        import traceback
        traceback.print_exc()
    finally:
        if conn:
            conn.close()
            print("\n🔌 Database connection closed")

if __name__ == "__main__":
    print("=" * 60)
    print("MARKETPLACE BETA ACCESS MIGRATION")
    print("=" * 60)
    print()
    run_migration()
