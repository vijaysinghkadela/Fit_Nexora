-- Create user_notes table
CREATE TABLE IF NOT EXISTS public.user_notes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    tags TEXT[] DEFAULT '{}',
    color TEXT,
    is_pinned BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_notes ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own notes" 
    ON public.user_notes FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notes" 
    ON public.user_notes FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notes" 
    ON public.user_notes FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own notes" 
    ON public.user_notes FOR DELETE 
    USING (auth.uid() = user_id);
