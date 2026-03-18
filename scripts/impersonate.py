import os
import sys
from supabase import create_client, Client
from dotenv import load_dotenv
import jwt
from datetime import datetime, timedelta, timezone

def main():
    load_dotenv()
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_ANON_KEY")
    jwt_secret = os.environ.get("SUPABASE_JWT_SECRET") 
    
    # If standard JWT secret is not in .env, we can't mint our own token easily.
    # We will just fetch using service role, but then use the REST api auth header manually.
    # Actually, Supabase admin allows admin.auth.admin.generate_link to get an access token? No.
    # We can instead query the database using standard psycopg2 to see what the exact RLS evaluation outputs,
    # OR we can just execute a query via psycopg2 SET ROLE authenticated; SET request.jwt.claims='{"sub":"abhishek_id"}';
    pass

def test_via_psycopg2():
    load_dotenv()
    db_url = os.environ.get("SUPABASE_DB_URL")
    import psycopg2
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
        
        # 1. Get the UUID of the newest owner
        cur.execute("SELECT id FROM auth.users ORDER BY created_at DESC LIMIT 1;")
        user_id = cur.fetchone()[0]
        print(f"Testing as user: {user_id}")
        
        # 2. Impersonate PostgREST
        cur.execute("SET session_authorization = 'authenticated';")
        cur.execute(f"SET request.jwt.claim.sub = '{user_id}';")
        cur.execute(f"SET request.jwt.claims = '{(\'{"sub":"\' + str(user_id) + \'"}\')}';")
        
        # 3. Query clients
        print("Executing SELECT * FROM clients...")
        try:
            cur.execute("SELECT * FROM clients;")
            rows = cur.fetchall()
            print(f"Success! Fetched {len(rows)} clients: {rows}")
        except Exception as e:
            print(f"QUERY FAILED: {e}")
            
    except Exception as e:
        print(f"DB Error: {e}")

if __name__ == "__main__":
    test_via_psycopg2()
