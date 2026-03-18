import os
import psycopg2
from dotenv import load_dotenv

def main():
    load_dotenv()
    # Read the Supabase URL and parse it to get DB credentials
    # Actually, the user's .env has SUPABASE_URL and SUPABASE_ANON_KEY.
    # Where is the database connection string? Usually SUPABASE_DB_URL
    # Let's check environment variables for any postgres url.
    db_url = os.environ.get("SUPABASE_DB_URL")
    if not db_url:
        print("Error: Could not find SUPABASE_DB_URL in environment.")
        # Alternatively, we can prompt the user to run it.
        return

    with open(r"supabase\migrations\016_clients_insert_rls.sql", "r") as f:
        sql = f.read()

    try:
        conn = psycopg2.connect(db_url)
        conn.autocommit = True
        cur = conn.cursor()
        print("Executing SQL Migration...")
        cur.execute(sql)
        print("Success! Migration 016 applied.")
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Database error: {e}")

if __name__ == "__main__":
    main()
