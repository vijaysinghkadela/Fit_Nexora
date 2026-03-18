"""
Creates the 'todos' table in Supabase using the service role key.
"""
import os, sys
from dotenv import load_dotenv

try:
    import psycopg2
except ImportError:
    print("Run: pip install psycopg2-binary")
    sys.exit(1)

SQL = """
-- Create todos table for trainer task management
CREATE TABLE IF NOT EXISTS public.todos (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    gym_id      UUID REFERENCES public.gyms(id) ON DELETE SET NULL,
    title       TEXT NOT NULL,
    description TEXT,
    priority    TEXT DEFAULT 'medium' CHECK (priority IN ('high', 'medium', 'low')),
    status      TEXT DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'done')),
    due_at      TIMESTAMPTZ,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.todos ENABLE ROW LEVEL SECURITY;

-- Policy: Users can manage their own todos
DROP POLICY IF EXISTS todos_own_user ON public.todos;
CREATE POLICY todos_own_user ON public.todos
    FOR ALL USING (user_id = auth.uid());

-- Allow Supabase Realtime / PostgREST to see the table
GRANT ALL ON public.todos TO authenticated;
GRANT ALL ON public.todos TO service_role;

-- Expose the table in the PostgREST schema cache
NOTIFY pgrst, 'reload schema';
"""

def main():
    load_dotenv()
    db_url = os.environ.get("SUPABASE_DB_URL")
    if not db_url:
        # Build it from the Supabase URL
        supabase_url = os.environ.get("SUPABASE_URL", "")
        if "supabase.co" in supabase_url:
            project_ref = supabase_url.replace("https://", "").split(".")[0]
            db_url = f"postgresql://postgres.{project_ref}:postgres@aws-0-ap-south-1.pooler.supabase.com:5432/postgres"
        else:
            print("ERROR: Set SUPABASE_DB_URL in your .env file.")
            return

    print(f"Connecting to: {db_url[:60]}...")
    try:
        conn = psycopg2.connect(db_url)
        conn.autocommit = True
        cur = conn.cursor()
        print("Executing SQL...")
        cur.execute(SQL)
        print("✅ todos table created successfully!")
        
        # Verify
        cur.execute("SELECT COUNT(*) FROM public.todos;")
        count = cur.fetchone()[0]
        print(f"   Table has {count} rows.")
        cur.close()
        conn.close()
    except Exception as e:
        print(f"❌ Database error: {e}")
        print("\nIf connection failed, please run this SQL manually in Supabase Dashboard -> SQL Editor:")
        print(SQL)

if __name__ == "__main__":
    main()
