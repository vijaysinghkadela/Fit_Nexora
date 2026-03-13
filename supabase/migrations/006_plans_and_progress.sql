-- ============================================================================
-- GymOS SaaS — Workout Plans, Diet Plans & Progress Tracking
-- ============================================================================

-- ─── WORKOUT PLANS ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS workout_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
  trainer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,

  name TEXT NOT NULL,
  description TEXT,
  goal TEXT NOT NULL DEFAULT 'general_fitness',
  duration_weeks INT NOT NULL DEFAULT 8,
  current_week INT NOT NULL DEFAULT 1,
  phase TEXT DEFAULT 'Phase 1',

  -- Stored as JSONB array of TrainingDay objects
  days JSONB NOT NULL DEFAULT '[]'::jsonb,

  status TEXT NOT NULL DEFAULT 'active',
  is_template BOOLEAN NOT NULL DEFAULT false,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── DIET PLANS ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS diet_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
  trainer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,

  name TEXT NOT NULL,
  description TEXT,
  goal TEXT NOT NULL DEFAULT 'general_fitness',

  target_calories INT NOT NULL DEFAULT 2000,
  target_protein INT NOT NULL DEFAULT 150,
  target_carbs INT NOT NULL DEFAULT 200,
  target_fat INT NOT NULL DEFAULT 65,
  hydration_liters DECIMAL(3,1) DEFAULT 3.0,

  -- Stored as JSONB array of Meal objects
  meals JSONB NOT NULL DEFAULT '[]'::jsonb,

  status TEXT NOT NULL DEFAULT 'active',
  is_template BOOLEAN NOT NULL DEFAULT false,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── PROGRESS CHECK-INS ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS progress_checkins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  trainer_id UUID REFERENCES profiles(id),

  checkin_date DATE NOT NULL DEFAULT CURRENT_DATE,

  -- Body metrics
  weight_kg DECIMAL(5,2),
  body_fat_percent DECIMAL(4,1),
  chest_cm DECIMAL(5,1),
  waist_cm DECIMAL(5,1),
  hips_cm DECIMAL(5,1),
  arm_cm DECIMAL(5,1),
  thigh_cm DECIMAL(5,1),

  -- Self-reported
  sleep_quality TEXT, -- poor, fair, good, excellent
  energy_level TEXT,
  soreness_level TEXT,
  adherence_percent INT,
  mood TEXT,
  notes TEXT,

  -- Photos (Supabase Storage paths)
  front_photo_url TEXT,
  side_photo_url TEXT,
  back_photo_url TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── TRAINER ASSIGNMENTS ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS trainer_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  trainer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,

  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_active BOOLEAN NOT NULL DEFAULT true,

  UNIQUE(gym_id, trainer_id, client_id)
);

-- ─── RLS POLICIES ────────────────────────────────────────────────────────────

ALTER TABLE workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE diet_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainer_assignments ENABLE ROW LEVEL SECURITY;

-- Gym owner sees all plans in their gym
CREATE POLICY workout_plans_owner_select ON workout_plans
  FOR SELECT USING (
    gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid())
  );

CREATE POLICY workout_plans_owner_all ON workout_plans
  FOR ALL USING (
    gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid())
  );

CREATE POLICY diet_plans_owner_select ON diet_plans
  FOR SELECT USING (
    gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid())
  );

CREATE POLICY diet_plans_owner_all ON diet_plans
  FOR ALL USING (
    gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid())
  );

CREATE POLICY checkins_owner_select ON progress_checkins
  FOR SELECT USING (
    gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid())
  );

CREATE POLICY checkins_owner_all ON progress_checkins
  FOR ALL USING (
    gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid())
  );

CREATE POLICY assignments_owner_all ON trainer_assignments
  FOR ALL USING (
    gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid())
  );

-- Service role can do anything
CREATE POLICY workout_plans_service ON workout_plans
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY diet_plans_service ON diet_plans
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY checkins_service ON progress_checkins
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY assignments_service ON trainer_assignments
  FOR ALL USING (auth.role() = 'service_role');

-- ─── INDEXES ─────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_workout_plans_gym ON workout_plans(gym_id);
CREATE INDEX IF NOT EXISTS idx_workout_plans_client ON workout_plans(client_id);
CREATE INDEX IF NOT EXISTS idx_workout_plans_template ON workout_plans(is_template) WHERE is_template = true;

CREATE INDEX IF NOT EXISTS idx_diet_plans_gym ON diet_plans(gym_id);
CREATE INDEX IF NOT EXISTS idx_diet_plans_client ON diet_plans(client_id);

CREATE INDEX IF NOT EXISTS idx_checkins_client ON progress_checkins(client_id, checkin_date);
CREATE INDEX IF NOT EXISTS idx_checkins_gym ON progress_checkins(gym_id);

CREATE INDEX IF NOT EXISTS idx_assignments_trainer ON trainer_assignments(trainer_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_assignments_client ON trainer_assignments(client_id) WHERE is_active = true;

-- ─── AUTO-UPDATE updated_at ──────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER workout_plans_updated
  BEFORE UPDATE ON workout_plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER diet_plans_updated
  BEFORE UPDATE ON diet_plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
