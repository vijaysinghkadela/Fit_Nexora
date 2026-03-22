-- ============================================================================
-- GymOS SaaS — Trainer RLS Fix
-- Allows trainers to add clients to their gym
-- ============================================================================

-- Add INSERT policy for trainers on the clients table
CREATE POLICY "clients_trainer_insert" ON "public"."clients"
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM gym_members
    WHERE gym_members.gym_id = clients.gym_id
    AND gym_members.user_id = auth.uid()
    AND gym_members.role = 'trainer'
  )
);

-- Note: We do not strictly enforce assigned_trainer_id = auth.uid() here
-- to allow for future flexibility (e.g., trainers adding clients for others),
-- but the UI will be updated to auto-assign for the current "My Clients" view.
