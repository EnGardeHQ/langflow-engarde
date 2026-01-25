import psycopg2
import sys

DATABASE_URL = "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"

def find_tenant():
    conn = None
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()

        print("--- EnGarde Media Tenant Check ---")
        cursor.execute("SELECT id, name FROM tenants WHERE name ILIKE '%EnGarde%'")
        tenants = cursor.fetchall()
        print(f"Tenants matching 'EnGarde': {tenants}")

        cursor.close()
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    find_tenant()
