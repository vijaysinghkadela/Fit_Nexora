import pandas as pd
import sys

file_path = "data/Rajasthan_Gym_Directory.xlsx"
try:
    df = pd.read_excel(file_path, sheet_name=None)
    for sheet_name, sheet_data in df.items():
        print(f"--- Sheet: {sheet_name} ---")
        print(f"Columns: {sheet_data.columns.tolist()}")
        print(f"Row count: {len(sheet_data)}")
        if len(sheet_data) > 0:
            print("First row:")
            print(sheet_data.iloc[0].to_dict())
        print("\n")
except Exception as e:
    print(f"Error reading excel: {e}")
