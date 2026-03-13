-- ============================================================================
-- GymOS SaaS — AI Usage Tracking & Plan Enforcement
-- ============================================================================

-- ─── AI USAGE ────────────────────────────────────────────────────────────────
-- Per-gym monthly AI usage tracking
CREATE TABLE IF NOT EXISTS ai_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  period_start TIMESTAMPTZ NOT NULL,
  period_end TIMESTAMPTZ NOT NULL,
  opus_calls_used INT NOT NULL DEFAULT 0,
  haiku_calls_used INT NOT NULL DEFAULT 0,
  total_tokens_used INT NOT NULL DEFAULT 0,
  overage_charges DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(gym_id, period_start)
);

-- RLS
ALTER TABLE ai_usage ENABLE ROW LEVEL SECURITY;

-- Gym owners can read their own usage
CREATE POLICY ai_usage_owner_select ON ai_usage
  FOR SELECT USING (
    gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid())
  );

-- Only service role can insert/update (backend enforced)
CREATE POLICY ai_usage_service_all ON ai_usage
  FOR ALL USING (auth.role() = 'service_role');

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_ai_usage_gym_period
  ON ai_usage(gym_id, period_start DESC);

-- ─── PLAN ENFORCEMENT CHECK CONSTRAINT ───────────────────────────────────────
-- Add a function to enforce client caps at the database level
CREATE OR REPLACE FUNCTION check_client_cap()
RETURNS TRIGGER AS $$
DECLARE
  current_count INT;
  gym_plan TEXT;
  max_allowed INT;
BEGIN
  -- Get the gym's plan tier
  SELECT plan_tier INTO gym_plan FROM gyms WHERE id = NEW.gym_id;

  -- Get current client count
  SELECT COUNT(*) INTO current_count FROM clients WHERE gym_id = NEW.gym_id;

  -- Determine max allowed
  CASE gym_plan
    WHEN 'basic' THEN max_allowed := 50;
    WHEN 'pro' THEN max_allowed := 200;
    WHEN 'elite' THEN max_allowed := 500;
    ELSE max_allowed := 50;
  END CASE;

  IF current_count >= max_allowed THEN
    RAISE EXCEPTION 'Client limit reached for % plan (max: %)', gym_plan, max_allowed;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER enforce_client_cap
  BEFORE INSERT ON clients
  FOR EACH ROW
  EXECUTE FUNCTION check_client_cap();

-- ─── TRAINER CAP ENFORCEMENT ─────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION check_trainer_cap()
RETURNS TRIGGER AS $$
DECLARE
  current_count INT;
  gym_plan TEXT;
  max_allowed INT;
BEGIN
  -- Only enforce for trainer role
  IF NEW.role != 'trainer' THEN
    RETURN NEW;
  END IF;

  SELECT plan_tier INTO gym_plan FROM gyms WHERE id = NEW.gym_id;

  SELECT COUNT(*) INTO current_count
  FROM gym_members
  WHERE gym_id = NEW.gym_id AND role = 'trainer';

  CASE gym_plan
    WHEN 'basic' THEN max_allowed := 1;
    WHEN 'pro' THEN max_allowed := 5;
    WHEN 'elite' THEN max_allowed := -1; -- unlimited
    ELSE max_allowed := 1;
  END CASE;

  IF max_allowed != -1 AND current_count >= max_allowed THEN
    RAISE EXCEPTION 'Trainer seat limit reached for % plan (max: %)', gym_plan, max_allowed;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER enforce_trainer_cap
  BEFORE INSERT ON gym_members
  FOR EACH ROW
  EXECUTE FUNCTION check_trainer_cap();

-- ─── UPDATED_AT TRIGGER FOR AI USAGE ─────────────────────────────────────────
CREATE OR REPLACE TRIGGER set_updated_at_ai_usage
  BEFORE UPDATE ON ai_usage
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
