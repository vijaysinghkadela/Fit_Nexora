-- ============================================================
-- 011_new_features.sql
-- Tables: body_measurements, water_logs, personal_records
-- ============================================================

-- ─── Body Measurements ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.body_measurements (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  weight_kg      NUMERIC(6,2),
  height_cm      NUMERIC(5,2),
  body_fat_percent NUMERIC(5,2),
  muscle_mass_kg NUMERIC(6,2),
  waist_cm       NUMERIC(5,2),
  chest_cm       NUMERIC(5,2),
  arm_cm         NUMERIC(5,2),
  thigh_cm       NUMERIC(5,2),
  hip_cm         NUMERIC(5,2),
  notes          TEXT,
  recorded_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_body_measurements_user_recorded
  ON public.body_measurements (user_id, recorded_at DESC);

ALTER TABLE public.body_measurements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "body_measurements: owner can select"
  ON public.body_measurements FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "body_measurements: owner can insert"
  ON public.body_measurements FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "body_measurements: owner can delete"
  ON public.body_measurements FOR DELETE
  USING (auth.uid() = user_id);

-- ─── Water Logs ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.water_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount_ml   INTEGER NOT NULL CHECK (amount_ml > 0),
  logged_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_water_logs_user_logged
  ON public.water_logs (user_id, logged_at DESC);

ALTER TABLE public.water_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "water_logs: owner can select"
  ON public.water_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "water_logs: owner can insert"
  ON public.water_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "water_logs: owner can delete"
  ON public.water_logs FOR DELETE
  USING (auth.uid() = user_id);

-- ─── Personal Records ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.personal_records (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  exercise_name  TEXT NOT NULL,
  weight_kg      NUMERIC(7,2) NOT NULL,
  reps           INTEGER NOT NULL DEFAULT 1 CHECK (reps > 0),
  notes          TEXT,
  achieved_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_personal_records_user_exercise
  ON public.personal_records (user_id, exercise_name, achieved_at DESC);

ALTER TABLE public.personal_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "personal_records: owner can select"
  ON public.personal_records FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "personal_records: owner can insert"
  ON public.personal_records FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "personal_records: owner can delete"
  ON public.personal_records FOR DELETE
  USING (auth.uid() = user_id);

-- ─── Gym Real-Time Traffic ───────────────────────────────────────────────────
-- Extend existing gym_checkins with checkout_at if not present
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'gym_checkins' AND column_name = 'checkout_at'
  ) THEN
    ALTER TABLE public.gym_checkins ADD COLUMN checkout_at TIMESTAMPTZ;
  END IF;
END
$$;

-- View: current occupancy per gym (members checked in but not checked out today)
CREATE OR REPLACE VIEW public.gym_current_occupancy AS
SELECT
  gym_id,
  COUNT(*) AS current_count,
  MAX(checked_in_at) AS last_checkin
FROM public.gym_checkins
WHERE
  checkout_at IS NULL
  AND checked_in_at >= NOW() - INTERVAL '12 hours'
GROUP BY gym_id;

-- ─── Notification Preferences ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notification_preferences (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  membership_expiry     BOOLEAN NOT NULL DEFAULT TRUE,
  workout_reminders     BOOLEAN NOT NULL DEFAULT TRUE,
  hydration_reminders   BOOLEAN NOT NULL DEFAULT FALSE,
  achievement_alerts    BOOLEAN NOT NULL DEFAULT TRUE,
  gym_announcements     BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notif_prefs: owner can all"
  ON public.notification_preferences FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── Equipment Status ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.equipment_status (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id        UUID NOT NULL REFERENCES public.gyms(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  category      TEXT NOT NULL DEFAULT 'cardio',
  total_units   INTEGER NOT NULL DEFAULT 1,
  in_use        INTEGER NOT NULL DEFAULT 0 CHECK (in_use >= 0),
  out_of_service INTEGER NOT NULL DEFAULT 0 CHECK (out_of_service >= 0),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_equipment_status_gym
  ON public.equipment_status (gym_id);

ALTER TABLE public.equipment_status ENABLE ROW LEVEL SECURITY;

CREATE POLICY "equipment_status: members can view"
  ON public.equipment_status FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.gym_members gm
      WHERE gm.gym_id = equipment_status.gym_id
        AND gm.user_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM public.gyms g
      WHERE g.id = equipment_status.gym_id
        AND g.owner_id = auth.uid()
    )
  );

CREATE POLICY "equipment_status: owner can manage"
  ON public.equipment_status FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.gyms g
      WHERE g.id = equipment_status.gym_id
        AND g.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.gyms g
      WHERE g.id = equipment_status.gym_id
        AND g.owner_id = auth.uid()
    )
  );

-- ─── Seed: Default equipment for existing gyms ───────────────────────────────
-- Uncomment if you want default equipment rows:
-- INSERT INTO public.equipment_status (gym_id, name, category, total_units)
-- SELECT id, 'Treadmill', 'cardio', 5 FROM public.gyms
-- ON CONFLICT DO NOTHING;
