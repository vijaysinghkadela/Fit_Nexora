-- Ensure the table exists
CREATE TABLE IF NOT EXISTS public.gym_announcements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    gym_id UUID REFERENCES public.gyms(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT,
    is_pinned BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Make gym_id nullable to support app-wide announcements
ALTER TABLE public.gym_announcements ALTER COLUMN gym_id DROP NOT NULL;

-- Add announcement_type column
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='gym_announcements' AND column_name='announcement_type') THEN
    ALTER TABLE public.gym_announcements ADD COLUMN announcement_type TEXT DEFAULT 'gym' NOT NULL CHECK (announcement_type IN ('gym', 'app'));
  END IF;
END $$;

-- Enable RLS
ALTER TABLE public.gym_announcements ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to recreate them cleanly)
DO $$
BEGIN
  DROP POLICY IF EXISTS "Anyone can view app announcements or their gym's announcements" ON public.gym_announcements;
  DROP POLICY IF EXISTS "Gym owners can manage their gym announcements" ON public.gym_announcements;
  DROP POLICY IF EXISTS "Super admins can manage app announcements" ON public.gym_announcements;
  DROP POLICY IF EXISTS "gym_announcements select policy" ON public.gym_announcements;
  DROP POLICY IF EXISTS "gym_announcements owner all policy" ON public.gym_announcements;
  DROP POLICY IF EXISTS "Members can view their gym announcements" ON public.gym_announcements;
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END $$;

-- Create Policies

-- 1. View policy: Users can see 'app' announcements, or 'gym' announcements for gyms they belong to/own
CREATE POLICY "Users can view relevant announcements"
ON public.gym_announcements FOR SELECT
USING (
  announcement_type = 'app'
  OR 
  (announcement_type = 'gym' AND gym_id IN (
    -- Member of the gym
    SELECT gym_id FROM public.gym_members WHERE user_id = auth.uid()
    UNION
    -- Owner of the gym
    SELECT id FROM public.gyms WHERE owner_id = auth.uid()
  ))
);

-- 2. Gym Owners can insert/update/delete their own gym's announcements
CREATE POLICY "Owners can manage gym announcements"
ON public.gym_announcements FOR ALL
USING (
  announcement_type = 'gym' AND gym_id IN (SELECT id FROM public.gyms WHERE owner_id = auth.uid())
)
WITH CHECK (
  announcement_type = 'gym' AND gym_id IN (SELECT id FROM public.gyms WHERE owner_id = auth.uid())
);

-- 3. Super Admins can insert/update/delete app announcements
CREATE POLICY "Admins can manage app announcements"
ON public.gym_announcements FOR ALL
USING (
  announcement_type = 'app' AND (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'superAdmin'
)
WITH CHECK (
  announcement_type = 'app' AND (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'superAdmin'
);

