#!/usr/bin/env python3
"""
Check if users have tenant_users table entries
"""
import psycopg2
import os

# Database connection
DATABASE_URL = "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"

def check_tenant_users():
    conn = None
    try:
        print("Connecting to database...")
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()

        # Check total users
        cursor.execute("SELECT COUNT(*) FROM users;")
        total_users = cursor.fetchone()[0]
        print(f"\n📊 Total users: {total_users}")

        # Check total tenants
        cursor.execute("SELECT COUNT(*) FROM tenants;")
        total_tenants = cursor.fetchone()[0]
        print(f"📊 Total tenants: {total_tenants}")

        # Check total tenant_users entries
        cursor.execute("SELECT COUNT(*) FROM tenant_users;")
        total_tenant_users = cursor.fetchone()[0]
        print(f"📊 Total tenant_users entries: {total_tenant_users}")

        # Check users WITHOUT tenant associations
        cursor.execute("""
            SELECT u.id, u.email, u.user_type, u.created_at
            FROM users u
            LEFT JOIN tenant_users tu ON u.id = tu.user_id
            WHERE tu.user_id IS NULL
            ORDER BY u.created_at DESC
            LIMIT 20;
        """)
        users_without_tenants = cursor.fetchall()

        print(f"\n🚨 Users WITHOUT tenant associations: {len(users_without_tenants)}")
        if users_without_tenants:
            print("\nFirst 20 users without tenant associations:")
            print(f"{'Email':<40} {'User Type':<15} {'Created At'}")
            print("-" * 80)
            for user in users_without_tenants:
                user_id, email, user_type, created_at = user
                print(f"{email:<40} {user_type or 'None':<15} {created_at}")

        # Check users WITH tenant associations
        cursor.execute("""
            SELECT u.id, u.email, u.user_type, t.name as tenant_name, tu.tenant_id
            FROM users u
            INNER JOIN tenant_users tu ON u.id = tu.user_id
            INNER JOIN tenants t ON tu.tenant_id = t.id
            ORDER BY u.created_at DESC
            LIMIT 10;
        """)
        users_with_tenants = cursor.fetchall()

        print(f"\n✅ Users WITH tenant associations: {cursor.rowcount}")
        if users_with_tenants:
            print("\nFirst 10 users with tenant associations:")
            print(f"{'Email':<40} {'User Type':<15} {'Tenant Name'}")
            print("-" * 80)
            for user in users_with_tenants:
                user_id, email, user_type, tenant_name, tenant_id = user
                print(f"{email:<40} {user_type or 'None':<15} {tenant_name}")

        # Check sample tenant details
        cursor.execute("""
            SELECT id, name, created_at
            FROM tenants
            ORDER BY created_at DESC
            LIMIT 5;
        """)
        tenants = cursor.fetchall()

        print(f"\n🏢 Sample tenants:")
        if tenants:
            print(f"{'Tenant ID':<38} {'Name':<40} {'Created At'}")
            print("-" * 90)
            for tenant in tenants:
                tenant_id, name, created_at = tenant
                print(f"{tenant_id:<38} {name:<40} {created_at}")

        cursor.close()

    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        if conn:
            conn.close()
            print("\n✅ Database connection closed")

if __name__ == "__main__":
    check_tenant_users()
