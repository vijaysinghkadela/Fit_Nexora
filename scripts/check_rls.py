import os
import sys
from supabase import create_client, Client
from dotenv import load_dotenv

def main():
    load_dotenv()
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    supabase: Client = create_client(url, key)
    
    print("Recent profiles (checking role constraints):")
    try:
        profiles = supabase.table("profiles").select("*").order("created_at", desc=True).limit(2).execute()
        for p in profiles.data:
            print(f"- {p['email']}, role: {p['global_role']}, id: {p['id']}")
            
            # Check gym_members
            members = supabase.table("gym_members").select("*").eq("user_id", p['id']).execute()
            if members.data:
                print(f"  -> Found gym_members rows: {members.data}")
            else:
                print(f"  -> NO gym_members rows found.")
                
            # Simulate my_owned_gym_ids query
            print("  -> Simulating my_owned_gym_ids()")
            res = supabase.rpc("my_owned_gym_ids", {}).execute()
            # Wait, RPC without auth headers uses service role. We can't easily simulate auth.uid
            # Just directly query if there is any gym_members with role='owner'
            owners = supabase.table("gym_members").select("*").eq("user_id", p['id']).eq("role", "owner").execute()
            if owners.data:
                print(f"  -> User IS an owner of gym_id: {owners.data[0]['gym_id']}")
            else:
                print(f"  -> User is NOT an owner in gym_members.")
                
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
