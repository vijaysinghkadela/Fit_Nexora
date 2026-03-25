-- ============================================================================
-- 023_member_plan_rls_via_client.sql
-- Repair member plan/check-in policies to authorize through clients.user_id
-- ============================================================================

ALTER TABLE public.workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.diet_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.progress_checkins ENABLE ROW LEVEL SECURITY;

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
