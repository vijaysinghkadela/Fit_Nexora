-- Migration 016: Explicitly define INSERT policies for Gym Owners adding clients
-- The FOR ALL policy USING clause can sometimes act strictly if the row 
-- is entirely new and does not have an existing context in the view.
-- Providing an explicit FOR INSERT WITH CHECK guarantees owners can add clients.

-- Provide explicit INSERT policy for clients for gym owners
CREATE POLICY clients_owner_explicit_insert ON clients
  FOR INSERT WITH CHECK (
    gym_id IN (SELECT my_owned_gym_ids()) 
    OR 
    gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid())
  );
