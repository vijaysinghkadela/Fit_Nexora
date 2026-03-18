"""
Diagnostic: Check what data exists in the database.
This connects using the SERVICE ROLE KEY so RLS is bypassed.
"""
import os, sys
from dotenv import load_dotenv

try:
    from supabase import create_client
except ImportError:
    print("Install supabase: pip install supabase")
    sys.exit(1)

def main():
    load_dotenv()
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    
    if not url or not key:
        print("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env")
        return
    
    client = create_client(url, key)
    
    print("\n=== AUTH USERS ===")
    users = client.auth.admin.list_users()
    if users:
        for u in users:
            print(f"  ID: {u.id}  email: {u.email}")
    
    print("\n=== GYM_MEMBERS TABLE (all rows) ===")
    rows = client.from_("gym_members").select("*").execute()
    if rows.data:
        for r in rows.data:
            print(f"  user_id={r.get('user_id')}  gym_id={r.get('gym_id')}  role={r.get('role')}")
    else:
        print("  No rows found!")
    
    print("\n=== GYMS TABLE ===")
    gyms = client.from_("gyms").select("id, name, owner_id, city").execute()
    if gyms.data:
        for g in gyms.data[:5]:  # show first 5
            print(f"  id={g.get('id')}  name={g.get('name')}  owner_id={g.get('owner_id')}")
    else:
        print("  No gyms found!")
    
    print("\n=== CLIENTS TABLE ===")
    clients = client.from_("clients").select("id, full_name, gym_id").execute()
    if clients.data:
        for c in clients.data:
            print(f"  id={c.get('id')}  name={c.get('full_name')}  gym_id={c.get('gym_id')}")
    else:
        print("  No clients found!")

if __name__ == "__main__":
    main()
