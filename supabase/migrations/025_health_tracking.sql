-- Create step_logs table
CREATE TABLE IF NOT EXISTS public.step_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    steps INTEGER NOT NULL DEFAULT 0,
    daily_goal INTEGER NOT NULL DEFAULT 10000,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- Enable RLS
ALTER TABLE public.step_logs ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own step logs" 
    ON public.step_logs FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own step logs" 
    ON public.step_logs FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own step logs" 
    ON public.step_logs FOR UPDATE 
    USING (auth.uid() = user_id);

-- Create sleep_logs table
CREATE TABLE IF NOT EXISTS public.sleep_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    hours_slept NUMERIC(4,2) NOT NULL,
    quality TEXT NOT NULL CHECK (quality IN ('poor', 'fair', 'good', 'excellent')),
    bedtime TEXT NOT NULL,
    wake_time TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- Enable RLS
ALTER TABLE public.sleep_logs ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own sleep logs" 
    ON public.sleep_logs FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sleep logs" 
    ON public.sleep_logs FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sleep logs" 
    ON public.sleep_logs FOR UPDATE 
    USING (auth.uid() = user_id);
