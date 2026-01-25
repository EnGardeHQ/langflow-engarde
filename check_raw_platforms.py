import psycopg2

DATABASE_URL = "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"

def check_platforms():
    conn = None
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()

        print("--- Checking raw platform values in campaign_spaces ---")
        cursor.execute("SELECT DISTINCT platform FROM campaign_spaces")
        platforms = cursor.fetchall()
        print(f"Raw platform values: {platforms}")

        cursor.close()
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    check_platforms()
