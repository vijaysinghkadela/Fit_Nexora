-- ============================================================================
-- 022_pro_ai_generation_updates.sql
-- FitNexora Pro AI updates for NVIDIA-hosted Kimi outputs and member RLS
-- ============================================================================

-- ─── AI Generated Plans Schema Updates ───────────────────────────────────────

ALTER TABLE public.ai_generated_plans
  ADD COLUMN IF NOT EXISTS plan_name TEXT,
  ADD COLUMN IF NOT EXISTS plan_description TEXT,
  ADD COLUMN IF NOT EXISTS plan_tier TEXT NOT NULL DEFAULT 'pro',
  ADD COLUMN IF NOT EXISTS reasoning_content TEXT;

ALTER TABLE public.ai_generated_plans
  ALTER COLUMN model_used SET DEFAULT 'moonshotai/kimi-k2-thinking';

UPDATE public.ai_generated_plans
SET model_used = 'moonshotai/kimi-k2-thinking'
WHERE model_used IS NULL
   OR model_used = ''
   OR model_used = 'claude-opus-4-5';

-- ─── Row Level Security ─────────────────────────────────────────────────────

ALTER TABLE public.ai_generated_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.diet_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.progress_checkins ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ai_generated_plans_member_manage ON public.ai_generated_plans;
CREATE POLICY ai_generated_plans_member_manage
  ON public.ai_generated_plans
  FOR ALL
  USING (member_id = auth.uid())
  WITH CHECK (member_id = auth.uid());

DROP POLICY IF EXISTS workout_plans_member_manage ON public.workout_plans;
CREATE POLICY workout_plans_member_manage
  ON public.workout_plans
  FOR ALL
  USING (
    client_id IN (
      SELECT id FROM public.clients WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    client_id IN (
      SELECT id FROM public.clients WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS diet_plans_member_manage ON public.diet_plans;
CREATE POLICY diet_plans_member_manage
  ON public.diet_plans
  FOR ALL
  USING (
    client_id IN (
      SELECT id FROM public.clients WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    client_id IN (
      SELECT id FROM public.clients WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS progress_checkins_member_manage ON public.progress_checkins;
CREATE POLICY progress_checkins_member_manage
  ON public.progress_checkins
  FOR ALL
  USING (
    client_id IN (
      SELECT id FROM public.clients WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    client_id IN (
      SELECT id FROM public.clients WHERE user_id = auth.uid()
    )
  );
