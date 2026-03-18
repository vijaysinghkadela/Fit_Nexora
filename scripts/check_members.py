import os
import sys
from supabase import create_client, Client
from dotenv import load_dotenv

def main():
    load_dotenv()
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    supabase: Client = create_client(url, key)
    
    # Query latest users
    print("Recent profiles:")
    try:
        profiles = supabase.table("profiles").select("*").order("created_at", desc=True).limit(5).execute()
        for p in profiles.data:
            print(f"- {p['email']}, role: {p['global_role']}, id: {p['id']}")
            
            # Check gym_members
            members = supabase.table("gym_members").select("*").eq("user_id", p['id']).execute()
            if members.data:
                print(f"  -> Found {len(members.data)} gym_members rows: {members.data}")
            else:
                print(f"  -> NO gym_members rows found for this user.")
                
            # Check clients
            clients = supabase.table("clients").select("*").eq("user_id", p['id']).execute()
            if clients.data:
                print(f"  -> Found {len(clients.data)} clients rows.")
            else:
                print(f"  -> NO clients rows found.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
