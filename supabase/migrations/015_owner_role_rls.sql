-- Migration 015: Allow users with role 'owner' in gym_members to actually manage the gym.
-- Previously, only the specific 'owner_id' on the gyms table had management rights.
-- Since gyms were bulk imported under an admin ID, new users who register
-- and claim a gym as 'owner' need these permissions too!

-- 1. Helper Function to get gyms where the user is an owner
CREATE OR REPLACE FUNCTION my_owned_gym_ids()
RETURNS SETOF UUID
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT gym_id FROM gym_members WHERE user_id = auth.uid() AND role = 'owner'
$$;

-- 2. Update Gyms Table Policy
DROP POLICY IF EXISTS gyms_owner_all ON gyms;
CREATE POLICY gyms_owner_all ON gyms
  FOR ALL USING (
    owner_id = auth.uid() OR id IN (SELECT my_owned_gym_ids())
  );

-- 3. Update Gym Members Table Policy
DROP POLICY IF EXISTS gym_members_owner_all ON gym_members;
CREATE POLICY gym_members_owner_all ON gym_members
  FOR ALL USING (
    gym_id IN (
      SELECT id FROM gyms WHERE owner_id = auth.uid() 
      UNION 
      SELECT my_owned_gym_ids()
    )
  );

-- 4. Update Clients Table Policy
DROP POLICY IF EXISTS clients_owner_all ON clients;
CREATE POLICY clients_owner_all ON clients
  FOR ALL USING (
    gym_id IN (
      SELECT id FROM gyms WHERE owner_id = auth.uid() 
      UNION 
      SELECT my_owned_gym_ids()
    )
  );

-- 5. Update Memberships Table Policy
DROP POLICY IF EXISTS memberships_owner_all ON memberships;
CREATE POLICY memberships_owner_all ON memberships
  FOR ALL USING (
    gym_id IN (
      SELECT id FROM gyms WHERE owner_id = auth.uid() 
      UNION 
      SELECT my_owned_gym_ids()
    )
  );

-- 6. Update Subscriptions Table Policy
DROP POLICY IF EXISTS subscriptions_owner_select ON subscriptions;
CREATE POLICY subscriptions_owner_select ON subscriptions
  FOR SELECT USING (
    gym_id IN (
      SELECT id FROM gyms WHERE owner_id = auth.uid() 
      UNION 
      SELECT my_owned_gym_ids()
    )
  );
