import os
import sys
import glob
import pandas as pd
from supabase import create_client, Client
from dotenv import load_dotenv

def main():
    load_dotenv()
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    
    if not url or not key:
        print("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env")
        sys.exit(1)
        
    print("Connecting to Supabase...")
    supabase: Client = create_client(url, key)
    
    # Find an admin user to act as the owner
    try:
        profiles_res = supabase.table("profiles").select("id").limit(1).execute()
        if not profiles_res.data:
            print("No profiles found in the database. Cannot assign owner_id.")
            sys.exit(1)
        admin_uuid = profiles_res.data[0]["id"]
        print(f"Using owner_id: {admin_uuid}")
    except Exception as e:
        print(f"Failed to query profiles: {e}")
        sys.exit(1)
    
    # Process all CSVs in data/ folder
    csv_files = glob.glob("data/*Gym-Owner-list.csv")
    if not csv_files:
        print("No CSV files found in data/")
        sys.exit(1)
        
    total_inserted = 0
    total_skipped = 0
        
    for file in csv_files:
        city_name = os.path.basename(file).split('-')[0]
        print(f"Processing {city_name} from {file}...")
        
        try:
            df = pd.read_csv(file, skipinitialspace=True)
            
            # Map columns to Supabase schema
            for _, row in df.iterrows():
                gym_name = str(row.get('Gym Name', '')).strip()
                if not gym_name or gym_name == 'nan':
                    continue
                    
                address = str(row.get('Address', '')).strip()
                if address == 'nan': address = None
                
                phone = str(row.get('Phone Number', '')).strip()
                if phone == 'nan': phone = None
                
                # Validate UUID length so constraint doesnt fail
                
                data = {
                    "name": gym_name,
                    "owner_id": admin_uuid,
                    "address": address,
                    "phone": phone,
                    "city": city_name,
                    "is_active": True
                }
                
                try:
                    supabase.table("gyms").insert(data).execute()
                    total_inserted += 1
                except Exception as e:
                    print(f"Failed to insert '{gym_name}': {e}")
                    total_skipped += 1
        except Exception as e:
            print(f"Error reading {file}: {e}")
            
    print(f"\nImport complete! Inserted: {total_inserted}, Skipped/Errors: {total_skipped}")

if __name__ == "__main__":
    main()
