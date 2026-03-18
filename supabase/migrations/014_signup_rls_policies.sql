-- Migration 014: Allow users to insert themselves into gyms during signup
-- Because row level security is enabled, users need explicit permission 
-- to link their newly created accounts to their selected gym.

CREATE POLICY gym_members_insert_own ON gym_members
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY clients_insert_own ON clients
  FOR INSERT WITH CHECK (user_id = auth.uid());
