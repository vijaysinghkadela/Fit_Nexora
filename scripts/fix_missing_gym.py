"""
Fix: Create the missing gym record for gym_id=74e1b887 so that:
  - gym_members row has a valid gym
  - clients row has a valid gym
  - The user can see their gym and clients in the app
"""
import os, sys
from dotenv import load_dotenv
from supabase import create_client

def main():
    load_dotenv()
    url  = os.environ.get("SUPABASE_URL")
    key  = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    client = create_client(url, key)

    missing_gym_id = "74e1b887-f23e-4ac7-8d3c-c253554a7390"
    owner_user_id  = "99ca0470-7d5c-43e3-9372-309867ba136e"  # abhishek@gmail.com

    print(f"Checking if gym {missing_gym_id} exists...")
    existing = client.from_("gyms").select("id,name").eq("id", missing_gym_id).execute()
    
    if existing.data:
        print(f"Gym already exists: {existing.data}")
    else:
        print("Gym NOT found — creating it now...")
        result = client.from_("gyms").insert({
            "id": missing_gym_id,
            "name": "Abhishek's Gym",
            "owner_id": owner_user_id,
            "city": "Jaipur",
            "is_active": True,
        }).execute()
        print(f"Created gym: {result.data}")

    print("\nVerifying gym_members...")
    members = client.from_("gym_members").select("*").eq("gym_id", missing_gym_id).execute()
    print(f"  gym_members rows: {members.data}")

    print("\nVerifying clients...")
    clients_result = client.from_("clients").select("id,full_name,gym_id").eq("gym_id", missing_gym_id).execute()
    print(f"  clients rows: {clients_result.data}")

    print("\nAll done! Now reload the app — the Clients screen should show 'vinay'.")

if __name__ == "__main__":
    main()
