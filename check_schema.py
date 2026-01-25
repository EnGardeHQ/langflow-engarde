import psycopg2
import sys

DATABASE_URL = "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"

def check_schema():
    conn = None
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()

        print("--- columns in users table ---")
        cursor.execute("""
            SELECT column_name
            FROM information_schema.columns
            WHERE table_name = 'users';
        """)
        columns = cursor.fetchall()
        print(f"Columns: {[c[0] for c in columns]}")

        print("\n--- check user_tenants table ---")
        cursor.execute("""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_name = 'user_tenants';
        """)
        if cursor.fetchone():
            cursor.execute("SELECT * FROM user_tenants LIMIT 5")
            records = cursor.fetchall()
            print(f"user_tenants records: {records}")
        else:
            print("Table 'user_tenants' does not exist.")

        cursor.close()
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    check_schema()
