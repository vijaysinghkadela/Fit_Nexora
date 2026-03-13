-- ============================================================================
-- GymOS SaaS — Expanded Client Profile Schema
-- ============================================================================
-- Adds new columns to match the master AI prompt's CLIENT PROFILE SCHEMA.
-- These fields enable personalized AI plan generation and progress tracking.

-- ─── NEW COLUMNS ON clients TABLE ────────────────────────────────────────────

-- Training preferences
ALTER TABLE clients ADD COLUMN IF NOT EXISTS training_time TEXT DEFAULT 'morning';
  -- Options: morning | afternoon | evening

-- Medical & health tracking
ALTER TABLE clients ADD COLUMN IF NOT EXISTS medical_conditions TEXT;
  -- Free text: diabetes, hypertension, PCOS, etc.
ALTER TABLE clients ADD COLUMN IF NOT EXISTS current_plan_phase TEXT;
  -- e.g., "Week 3 of 12", "Deload Week", "Maintenance Phase"

-- Progress tracking fields
ALTER TABLE clients ADD COLUMN IF NOT EXISTS last_checkin_weight DECIMAL(5,1);
ALTER TABLE clients ADD COLUMN IF NOT EXISTS weight_trend TEXT;
  -- Options: losing | gaining | stalling | fluctuating
ALTER TABLE clients ADD COLUMN IF NOT EXISTS sleep_quality TEXT;
  -- Options: poor | average | good | excellent
ALTER TABLE clients ADD COLUMN IF NOT EXISTS energy_level TEXT;
  -- Options: poor | average | good | excellent
ALTER TABLE clients ADD COLUMN IF NOT EXISTS adherence_percent INT DEFAULT 0;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS last_gym_visit TIMESTAMPTZ;

-- Plan & assignment tracking
ALTER TABLE clients ADD COLUMN IF NOT EXISTS current_plan_name TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS assigned_trainer_name TEXT;

-- Localization
ALTER TABLE clients ADD COLUMN IF NOT EXISTS language_preference TEXT DEFAULT 'english';
  -- Options: english | hindi | hinglish

-- ─── UPDATE EXISTING COLUMNS ─────────────────────────────────────────────────
-- Ensure 'equipment' column accepts the expanded values
-- (full_gym | home_with_equipment | home_minimal | bodyweight_only)
-- No schema change needed — it's already TEXT type.

-- ─── INDEXES FOR AI/ANALYTICS QUERIES ────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_clients_weight_trend
  ON clients(gym_id, weight_trend);
CREATE INDEX IF NOT EXISTS idx_clients_adherence
  ON clients(gym_id, adherence_percent);
CREATE INDEX IF NOT EXISTS idx_clients_last_visit
  ON clients(gym_id, last_gym_visit);
CREATE INDEX IF NOT EXISTS idx_clients_language
  ON clients(gym_id, language_preference);

-- ─── ADD plan_tier COLUMN TO gyms TABLE ──────────────────────────────────────
-- Required by the client/trainer cap triggers in 003_ai_usage_and_enforcement.sql
ALTER TABLE gyms ADD COLUMN IF NOT EXISTS plan_tier TEXT DEFAULT 'basic';
  -- Options: basic | pro | elite
CREATE INDEX IF NOT EXISTS idx_gyms_plan_tier ON gyms(plan_tier);
