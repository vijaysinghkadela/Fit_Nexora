-- ============================================================================
-- GymOS SaaS — Row Level Security Policies
-- Enforces multi-tenant data isolation
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE gyms ENABLE ROW LEVEL SECURITY;
ALTER TABLE gym_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- ─── PROFILES ────────────────────────────────────────────────────────────────

-- Users can read their own profile
CREATE POLICY profiles_select_own ON profiles
  FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY profiles_update_own ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Users can insert their own profile (signup)
CREATE POLICY profiles_insert_own ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Gym members can see profiles of other members in the same gym
CREATE POLICY profiles_select_gym_members ON profiles
  FOR SELECT USING (
    id IN (
      SELECT gm.user_id FROM gym_members gm
      WHERE gm.gym_id IN (
        SELECT gm2.gym_id FROM gym_members gm2
        WHERE gm2.user_id = auth.uid()
      )
    )
  );

-- ─── GYMS ────────────────────────────────────────────────────────────────────

-- Gym owners can do everything with their gyms
CREATE POLICY gyms_owner_all ON gyms
  FOR ALL USING (owner_id = auth.uid());

-- Gym members can read their gym
CREATE POLICY gyms_member_select ON gyms
  FOR SELECT USING (
    id IN (
      SELECT gym_id FROM gym_members WHERE user_id = auth.uid()
    )
  );

-- ─── GYM MEMBERS ─────────────────────────────────────────────────────────────

-- Gym owners can manage members
CREATE POLICY gym_members_owner_all ON gym_members
  FOR ALL USING (
    gym_id IN (
      SELECT id FROM gyms WHERE owner_id = auth.uid()
    )
  );

-- Members can see other members in their gym
CREATE POLICY gym_members_select_same_gym ON gym_members
  FOR SELECT USING (
    gym_id IN (
      SELECT gym_id FROM gym_members WHERE user_id = auth.uid()
    )
  );

-- ─── CLIENTS ─────────────────────────────────────────────────────────────────

-- Gym owners can manage all clients
CREATE POLICY clients_owner_all ON clients
  FOR ALL USING (
    gym_id IN (
      SELECT id FROM gyms WHERE owner_id = auth.uid()
    )
  );

-- Trainers can see their assigned clients
CREATE POLICY clients_trainer_select ON clients
  FOR SELECT USING (
    assigned_trainer_id = auth.uid()
  );

-- Trainers can update their assigned clients
CREATE POLICY clients_trainer_update ON clients
  FOR UPDATE USING (
    assigned_trainer_id = auth.uid()
  );

-- Clients can see their own profile
CREATE POLICY clients_self_select ON clients
  FOR SELECT USING (user_id = auth.uid());

-- ─── MEMBERSHIPS ─────────────────────────────────────────────────────────────

-- Gym owners can manage all memberships
CREATE POLICY memberships_owner_all ON memberships
  FOR ALL USING (
    gym_id IN (
      SELECT id FROM gyms WHERE owner_id = auth.uid()
    )
  );

-- Trainers can view memberships of assigned clients
CREATE POLICY memberships_trainer_select ON memberships
  FOR SELECT USING (
    client_id IN (
      SELECT id FROM clients WHERE assigned_trainer_id = auth.uid()
    )
  );

-- Clients can see their own membership
CREATE POLICY memberships_self_select ON memberships
  FOR SELECT USING (
    client_id IN (
      SELECT id FROM clients WHERE user_id = auth.uid()
    )
  );

-- ─── SUBSCRIPTIONS ───────────────────────────────────────────────────────────

-- Gym owners can read their subscription
CREATE POLICY subscriptions_owner_select ON subscriptions
  FOR SELECT USING (
    gym_id IN (
      SELECT id FROM gyms WHERE owner_id = auth.uid()
    )
  );
