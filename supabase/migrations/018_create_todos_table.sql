-- ============================================================================
-- GymOS — 018: Create Todos Table
-- Description: The trainer task management feature requires a 'todos' table.
--              This script creates it with proper RLS and schema exposure.
-- ============================================================================

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

-- Grant access
GRANT ALL ON public.todos TO authenticated;
GRANT ALL ON public.todos TO service_role;

-- Refresh PostgREST schema cache so it sees the new table
NOTIFY pgrst, 'reload schema';
