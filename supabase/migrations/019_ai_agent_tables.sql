-- ============================================================================
-- 019_ai_agent_tables.sql
-- FitNexora AI Agent — member_fitness_profiles, ai_generated_plans, visit view
-- ============================================================================

-- ─── Member Fitness Profiles ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.member_fitness_profiles (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  member_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  gym_id          UUID NOT NULL REFERENCES public.gyms(id) ON DELETE CASCADE,

  -- Body metrics
  height_cm       NUMERIC(5,1),
  weight_kg       NUMERIC(5,1),
  body_fat_pct    NUMERIC(4,1),
  muscle_mass_kg  NUMERIC(5,1),
  bmi             NUMERIC(4,1),
  age             INTEGER,
  gender          TEXT CHECK (gender IN ('male', 'female', 'other')),

  -- Fitness context
  fitness_level   TEXT CHECK (fitness_level IN ('beginner', 'intermediate', 'advanced')),
  primary_goal    TEXT CHECK (primary_goal IN (
                    'weight_loss', 'muscle_gain', 'endurance',
                    'flexibility', 'general_fitness', 'sports_performance'
                  )),
  secondary_goal  TEXT,
  injuries        TEXT[],
  available_days  INTEGER DEFAULT 5,

  -- Diet context
  diet_type       TEXT CHECK (diet_type IN (
                    'vegetarian', 'vegan', 'non_vegetarian',
                    'eggetarian', 'keto', 'paleo'
                  )),
  food_allergies  TEXT[],
  calorie_target  INTEGER,

  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW(),

  -- One profile per member per gym
  UNIQUE(member_id, gym_id)
);

ALTER TABLE public.member_fitness_profiles ENABLE ROW LEVEL SECURITY;

-- Gym members (owner/trainer) can view profiles for their gym
CREATE POLICY "fitness_profiles: gym members can view"
  ON public.member_fitness_profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.gym_members gm
      WHERE gm.gym_id = member_fitness_profiles.gym_id
        AND gm.user_id = auth.uid()
    )
    OR member_id = auth.uid()
  );

-- Gym owners can manage profiles
CREATE POLICY "fitness_profiles: owner can manage"
  ON public.member_fitness_profiles FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.gyms g
      WHERE g.id = member_fitness_profiles.gym_id
        AND g.owner_id = auth.uid()
    )
    OR member_id = auth.uid()
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.gyms g
      WHERE g.id = member_fitness_profiles.gym_id
        AND g.owner_id = auth.uid()
    )
    OR member_id = auth.uid()
  );

-- ─── AI-Generated Plans ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ai_generated_plans (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  member_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  gym_id          UUID NOT NULL REFERENCES public.gyms(id) ON DELETE CASCADE,

  plan_month      DATE NOT NULL,
  plan_type       TEXT NOT NULL CHECK (plan_type IN ('workout', 'diet', 'combined')),

  -- AI outputs (structured JSON)
  body_analysis   JSONB,
  workout_plan    JSONB,
  diet_plan       JSONB,
  monthly_report  JSONB,
  tips            TEXT[],

  -- Generation metadata
  model_used      TEXT DEFAULT 'claude-opus-4-5',
  tokens_used     INTEGER,
  generation_ms   INTEGER,

  -- Report PDF
  report_pdf_url  TEXT,

  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_generated_plans_member
  ON public.ai_generated_plans (member_id, plan_month DESC);

ALTER TABLE public.ai_generated_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ai_plans: gym members can view"
  ON public.ai_generated_plans FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.gym_members gm
      WHERE gm.gym_id = ai_generated_plans.gym_id
        AND gm.user_id = auth.uid()
    )
    OR member_id = auth.uid()
  );

CREATE POLICY "ai_plans: owner can manage"
  ON public.ai_generated_plans FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.gyms g
      WHERE g.id = ai_generated_plans.gym_id
        AND g.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.gyms g
      WHERE g.id = ai_generated_plans.gym_id
        AND g.owner_id = auth.uid()
    )
  );

-- ─── Visit Summary View ────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.member_visit_summary AS
SELECT
  user_id AS member_id,
  gym_id,
  COUNT(*) AS total_visits,
  COUNT(*) FILTER (WHERE checked_in_at >= NOW() - INTERVAL '30 days') AS visits_last_30_days,
  COUNT(*) FILTER (WHERE checked_in_at >= NOW() - INTERVAL '7 days')  AS visits_last_7_days,
  MAX(checked_in_at) AS last_visit,
  ROUND(
    AVG(
      EXTRACT(EPOCH FROM (
        COALESCE(checkout_at, checked_in_at + INTERVAL '1 hour') - checked_in_at
      )) / 3600
    )::numeric,
    1
  ) AS avg_session_hrs
FROM public.gym_checkins
GROUP BY user_id, gym_id;
