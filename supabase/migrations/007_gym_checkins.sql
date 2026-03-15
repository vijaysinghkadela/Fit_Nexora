-- ============================================================================
-- GymOS — Gym Check-In / Traffic Tracking
-- Enables real-time traffic counting and historical traffic analytics
-- ============================================================================

CREATE TABLE IF NOT EXISTS gym_checkins (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id        UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  checked_in_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  checked_out_at TIMESTAMPTZ
);

-- Prevent double active check-in: one open session per user per gym
CREATE UNIQUE INDEX IF NOT EXISTS uq_active_checkin
  ON gym_checkins(gym_id, user_id)
  WHERE checked_out_at IS NULL;

-- Query speed: fetch active sessions for a gym
CREATE INDEX IF NOT EXISTS idx_checkins_gym_active
  ON gym_checkins(gym_id)
  WHERE checked_out_at IS NULL;

-- Query speed: historical analysis by time
CREATE INDEX IF NOT EXISTS idx_checkins_gym_time
  ON gym_checkins(gym_id, checked_in_at DESC);

-- ─── ROW LEVEL SECURITY ─────────────────────────────────────────────────────
ALTER TABLE gym_checkins ENABLE ROW LEVEL SECURITY;

-- Any gym member can view all check-ins for their gym (needed for traffic count)
CREATE POLICY "gym_members_view_checkins" ON gym_checkins
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM gym_members gm
      WHERE gm.gym_id = gym_checkins.gym_id
        AND gm.user_id = auth.uid()
    )
  );

-- Gym owners can also view (covered above, but explicit for clarity)
-- Members can insert their own check-in
CREATE POLICY "members_can_checkin" ON gym_checkins
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Members can update only their own check-in (to check out)
CREATE POLICY "members_can_checkout" ON gym_checkins
  FOR UPDATE USING (user_id = auth.uid());
