import pandas as pd
import os
from dotenv import load_dotenv
from supabase import create_client, Client
import sys

load_dotenv()
url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not url or not key:
    print("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY")
    sys.exit(1)

supabase: Client = create_client(url, key)

print("Fetching users to find an owner_id...")
users_resp = supabase.auth.admin.list_users()

# Handle depending on PySupabase version response structure
users = getattr(users_resp, 'users', users_resp)

owner_id = None
if hasattr(users, '__len__') and len(users) > 0:
    for u in users:
        # Avoid picking a user we just created if we want a real one, or just take the first one
        owner_id = getattr(u, 'id', getattr(u, 'user_id', None))
        if type(u) is dict:
            owner_id = u.get('id')
        if owner_id:
            break

if not owner_id:
    print("No users found. Creating a dummy admin user...")
    try:
        new_user = supabase.auth.admin.create_user({
            "email": "directory_admin@gymos.ai",
            "password": "SecurePassword123!",
            "email_confirm": True
        })
        owner_id = getattr(new_user.user, 'id', new_user.user.id)
    except Exception as e:
        print(f"Failed to create user: {e}")
        sys.exit(1)

print(f"Using owner_id: {owner_id}")

file_path = "data/Rajasthan_Gym_Directory.xlsx"
df = pd.read_excel(file_path, sheet_name=None)

inserted_count = 0

for sheet_name, sheet_data in df.items():
    if sheet_name == 'Summary': continue
    
    print(f"Processing sheet: {sheet_name}")
    # The header is in row 0
    sheet_data.columns = sheet_data.iloc[0]
    sheet_data = sheet_data[1:]
    
    for index, row in sheet_data.iterrows():
        gym_name = str(row.get('Gym Name', '')).strip()
        if not gym_name or gym_name == 'nan': continue
        
        phone = str(row.get('Phone', '')).strip()
        if phone == 'nan' or not phone: phone = None
        
        address_col = 'Address' if 'Address' in row else 'Address / Details / Insights'
        address = str(row.get(address_col, '')).strip()
        if address == 'nan' or not address: address = None
        
        address_full = f"{address}, {sheet_name}" if address else sheet_name
        
        try:
            res = supabase.table('gyms').insert({
                'name': gym_name,
                'owner_id': owner_id,
                'phone': phone,
                'address': address_full[:255], # Ensure it fits in normal varchar
                'is_active': True
            }).execute()
            inserted_count += 1
            # print(f"Inserted: {gym_name}")
        except Exception as e:
            print(f"Error inserting {gym_name}: {e}")

print(f"Successfully inserted {inserted_count} gyms.")
