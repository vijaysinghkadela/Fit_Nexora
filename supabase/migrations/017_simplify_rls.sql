-- ============================================================================
-- GymOS — 017: Simplify RLS Policies
-- Description: The '015' migration introduced UNION clauses inside the RLS 
--              IN (...) checks. Supabase PostgREST struggles to evaluate 
--              these complex UNION subqueries for outer joins, resulting in 
--              'Unable to load clients right now' PostgrestExceptions. 
--              This script explicitly replaces them with simpler OR checks.
-- ============================================================================

-- 1. Simplify Gyms Table Policy
DROP POLICY IF EXISTS gyms_owner_all ON gyms;
CREATE POLICY gyms_owner_all ON gyms
  FOR ALL USING (
    owner_id = auth.uid() OR id IN (SELECT my_owned_gym_ids())
  );

-- 2. Simplify Gym Members Table Policy
DROP POLICY IF EXISTS gym_members_owner_all ON gym_members;
CREATE POLICY gym_members_owner_all ON gym_members
  FOR ALL USING (
    gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid()) 
    OR 
    gym_id IN (SELECT my_owned_gym_ids())
  );

-- 3. Simplify Clients Table Policy
DROP POLICY IF EXISTS clients_owner_all ON clients;
CREATE POLICY clients_owner_all ON clients
  FOR ALL USING (
    gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid()) 
    OR 
    gym_id IN (SELECT my_owned_gym_ids())
  );

-- 4. Simplify Memberships Table Policy
DROP POLICY IF EXISTS memberships_owner_all ON memberships;
CREATE POLICY memberships_owner_all ON memberships
  FOR ALL USING (
    client_id IN (
      SELECT id FROM clients WHERE 
        gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid())
        OR 
        gym_id IN (SELECT my_owned_gym_ids())
    )
  );

-- Note: The clients_owner_explicit_insert from 016 remains active and already uses OR.
