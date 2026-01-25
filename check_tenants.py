import psycopg2
import sys

DATABASE_URL = "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"

def check_tenants():
    conn = None
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()

        print("--- Tenant ID Check in campaign_spaces ---")
        cursor.execute("SELECT DISTINCT tenant_id FROM campaign_spaces")
        tenants = cursor.fetchall()
        print(f"Unique tenant_ids in campaign_spaces: {tenants}")

        print("\n--- User Tenant ID Check ---")
        cursor.execute("SELECT id, email, tenant_id FROM users LIMIT 5")
        users = cursor.fetchall()
        print(f"Recent users and their tenant_ids: {users}")

        cursor.close()
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    check_tenants()
