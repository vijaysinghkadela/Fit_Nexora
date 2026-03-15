-- ============================================================================
-- GymOS — Fix RLS Infinite Recursion on gym_members
--
-- Root cause:
--   gym_members_owner_all  → queries gyms
--   gyms_member_select     → queries gym_members   ← cycle start
--   gym_members_select_same_gym → queries gym_members  ← self-referential
--
-- Fix: a SECURITY DEFINER helper that bypasses RLS to get the current
-- user's gym IDs. All policies that used to subquery gym_members now
-- call this function instead, breaking the recursion.
-- ============================================================================

-- ─── Helper function (runs as owner, bypasses RLS) ──────────────────────────

CREATE OR REPLACE FUNCTION my_gym_ids()
RETURNS SETOF UUID
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT gym_id FROM gym_members WHERE user_id = auth.uid()
$$;

-- ─── Drop the recursive policies ────────────────────────────────────────────

DROP POLICY IF EXISTS gym_members_select_same_gym  ON gym_members;
DROP POLICY IF EXISTS gyms_member_select            ON gyms;
DROP POLICY IF EXISTS profiles_select_gym_members   ON profiles;
DROP POLICY IF EXISTS gym_members_view_checkins     ON gym_checkins;

-- ─── Recreate without recursion ─────────────────────────────────────────────

-- gym_members: members see rows in their own gym(s)
CREATE POLICY gym_members_select_same_gym ON gym_members
  FOR SELECT USING (
    gym_id IN (SELECT my_gym_ids())
  );

-- gyms: members can read their gym
CREATE POLICY gyms_member_select ON gyms
  FOR SELECT USING (
    id IN (SELECT my_gym_ids())
  );

-- profiles: gym members can see profiles of people in the same gym
CREATE POLICY profiles_select_gym_members ON profiles
  FOR SELECT USING (
    id IN (
      SELECT user_id FROM gym_members
      WHERE gym_id IN (SELECT my_gym_ids())
    )
  );

-- gym_checkins: any gym member can view check-ins for their gym
CREATE POLICY gym_members_view_checkins ON gym_checkins
  FOR SELECT USING (
    gym_id IN (SELECT my_gym_ids())
  );
