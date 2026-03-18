-- Migration 013: Allow public selection of active gyms
-- This allows users to search for cities and gyms during account creation
-- before they have an authenticated session.

CREATE POLICY gyms_public_select ON gyms
  FOR SELECT USING (is_active = true);
