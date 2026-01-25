import psycopg2
import sys

DATABASE_URL = "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"

def check_tenant_users():
    conn = None
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()

        print("--- columns in tenant_users table ---")
        cursor.execute("""
            SELECT column_name
            FROM information_schema.columns
            WHERE table_name = 'tenant_users';
        """)
        columns = cursor.fetchall()
        print(f"Columns: {[c[0] for c in columns]}")

        cursor.execute("SELECT tenant_id, user_id FROM tenant_users LIMIT 5")
        records = cursor.fetchall()
        print(f"tenant_users records: {records}")

        cursor.close()
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    check_tenant_users()
