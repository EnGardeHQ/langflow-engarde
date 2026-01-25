import psycopg2

DATABASE_URL = "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"

def check_data():
    conn = None
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()

        print("--- Checking campaign_spaces for NULLs or invalid platforms ---")
        cursor.execute("SELECT id, campaign_name, platform FROM campaign_spaces WHERE platform IS NULL")
        null_platforms = cursor.fetchall()
        print(f"Rows with NULL platform: {null_platforms}")

        print("\n--- Checking campaign_spaces for NULL import_source ---")
        cursor.execute("SELECT id, campaign_name FROM campaign_spaces WHERE import_source IS NULL")
        null_import = cursor.fetchall()
        print(f"Rows with NULL import_source: {null_import}")

        print("\n--- Checking for potential casting issues ---")
        # Try to to_dict manually in a sense
        cursor.execute("SELECT id, tags FROM campaign_spaces LIMIT 10")
        tags = cursor.fetchall()
        print(f"Sample tags: {tags}")

        cursor.close()
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    check_data()
