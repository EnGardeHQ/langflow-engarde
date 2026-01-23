#!/usr/bin/env python3
"""
Create tenant_user associations for users missing tenant links
"""
import psycopg2
import psycopg2.extras
import uuid
import json
from datetime import datetime

# Database connection
DATABASE_URL = "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"

def fix_tenant_associations():
    conn = None
    try:
        print("Connecting to database...")
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()

        # Get users without tenant associations
        cursor.execute("""
            SELECT u.id, u.email, u.user_type
            FROM users u
            LEFT JOIN tenant_users tu ON u.id = tu.user_id
            WHERE tu.user_id IS NULL;
        """)
        users_without_tenants = cursor.fetchall()

        print(f"\n🔍 Found {len(users_without_tenants)} users without tenant associations\n")

        for user_id, email, user_type in users_without_tenants:
            print(f"Processing: {email} ({user_type})")

            tenant_id = None

            # Match user to tenant based on email or type
            if email == "cope@engarde.media":
                # Admin user - associate with En Garde Admin tenant
                cursor.execute("""
                    SELECT id FROM tenants WHERE name = 'En Garde Admin';
                """)
                result = cursor.fetchone()
                if result:
                    tenant_id = result[0]
                    print(f"  → Matched to 'En Garde Admin' tenant")

            elif email == "client@stellar-retail.com":
                # Client user - associate with Stellar Retail Co tenant
                cursor.execute("""
                    SELECT id FROM tenants WHERE name = 'Stellar Retail Co';
                """)
                result = cursor.fetchone()
                if result:
                    tenant_id = result[0]
                    print(f"  → Matched to 'Stellar Retail Co' tenant")

            elif email == "client@acme-corp.com":
                # Client user - associate with Acme Corporation tenant
                cursor.execute("""
                    SELECT id FROM tenants WHERE name = 'Acme Corporation';
                """)
                result = cursor.fetchone()
                if result:
                    tenant_id = result[0]
                    print(f"  → Matched to 'Acme Corporation' tenant")

            if tenant_id:
                # Create tenant_user association
                tu_id = str(uuid.uuid4())
                cursor.execute("""
                    INSERT INTO tenant_users (id, tenant_id, user_id, permissions, created_at)
                    VALUES (%s, %s, %s, %s, %s);
                """, (tu_id, tenant_id, user_id, json.dumps({}), datetime.utcnow()))

                print(f"  ✅ Created tenant_user association (ID: {tu_id})")
            else:
                print(f"  ⚠️  No matching tenant found for {email}")

        # Commit changes
        conn.commit()
        print(f"\n✅ All changes committed")

        # Verify changes
        cursor.execute("""
            SELECT COUNT(*)
            FROM users u
            LEFT JOIN tenant_users tu ON u.id = tu.user_id
            WHERE tu.user_id IS NULL;
        """)
        remaining = cursor.fetchone()[0]
        print(f"\n📊 Users without tenant associations after fix: {remaining}")

        # Show updated associations
        cursor.execute("""
            SELECT u.email, t.name as tenant_name
            FROM users u
            INNER JOIN tenant_users tu ON u.id = tu.user_id
            INNER JOIN tenants t ON tu.tenant_id = t.id
            WHERE u.email IN ('cope@engarde.media', 'client@stellar-retail.com', 'client@acme-corp.com')
            ORDER BY u.email;
        """)
        updated_users = cursor.fetchall()

        if updated_users:
            print(f"\n✅ Updated user-tenant associations:")
            print(f"{'Email':<40} {'Tenant Name'}")
            print("-" * 70)
            for email, tenant_name in updated_users:
                print(f"{email:<40} {tenant_name}")

        cursor.close()

    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        if conn:
            conn.rollback()
    finally:
        if conn:
            conn.close()
            print("\n✅ Database connection closed")

if __name__ == "__main__":
    fix_tenant_associations()
