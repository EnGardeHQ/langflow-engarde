import psycopg2
import sys

DATABASE_URL = "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"

def check_db():
    conn = None
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()

        print("--- Tables Check ---")
        cursor.execute("""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
            AND table_name IN ('campaign_spaces', 'campaign_assets');
        """)
        tables = cursor.fetchall()
        print(f"Found tables: {tables}")

        for table in ['campaign_spaces', 'campaign_assets']:
            if (table,) in tables:
                cursor.execute(f"SELECT COUNT(*) FROM {table}")
                count = cursor.fetchone()[0]
                print(f"Table '{table}' has {count} rows.")
            else:
                print(f"Table '{table}' DOES NOT EXIST.")

        print("\n--- Enum Check ---")
        cursor.execute("SELECT typname FROM pg_type WHERE typname IN ('adplatform', 'campaignassettype', 'campaignimportsource');")
        enums = cursor.fetchall()
        print(f"Found enums: {enums}")

        cursor.close()
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    check_db()
