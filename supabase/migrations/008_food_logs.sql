-- ============================================================================
-- GymOS — Food Logs & Nutrition Tracking
-- Stores per-serving food intake for daily/weekly/monthly reports
-- ============================================================================

CREATE TABLE IF NOT EXISTS food_logs (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  gym_id         UUID REFERENCES gyms(id) ON DELETE SET NULL,
  barcode        TEXT,
  product_name   TEXT NOT NULL,
  brand          TEXT,

  -- Actual nutrients consumed (per serving × quantity)
  calories_kcal  DECIMAL(8,1) NOT NULL DEFAULT 0,
  protein_g      DECIMAL(7,2) NOT NULL DEFAULT 0,
  fat_g          DECIMAL(7,2) NOT NULL DEFAULT 0,
  carbs_g        DECIMAL(7,2) NOT NULL DEFAULT 0,
  sugar_g        DECIMAL(7,2) NOT NULL DEFAULT 0,
  fiber_g        DECIMAL(7,2) NOT NULL DEFAULT 0,
  sodium_mg      DECIMAL(8,1) NOT NULL DEFAULT 0,

  -- Serving meta
  serving_size_g DECIMAL(7,2) NOT NULL DEFAULT 100,
  quantity       DECIMAL(6,2) NOT NULL DEFAULT 1,
  meal_type      TEXT NOT NULL DEFAULT 'snack'
    CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),

  logged_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for date-range queries used in reports
CREATE INDEX IF NOT EXISTS idx_food_logs_user_date
  ON food_logs(user_id, logged_at DESC);

CREATE INDEX IF NOT EXISTS idx_food_logs_gym_date
  ON food_logs(gym_id, logged_at DESC);

-- ─── ROW LEVEL SECURITY ─────────────────────────────────────────────────────
ALTER TABLE food_logs ENABLE ROW LEVEL SECURITY;

-- Users can only see their own food logs
CREATE POLICY "users_own_food_logs_select" ON food_logs
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "users_own_food_logs_insert" ON food_logs
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_own_food_logs_delete" ON food_logs
  FOR DELETE USING (user_id = auth.uid());
