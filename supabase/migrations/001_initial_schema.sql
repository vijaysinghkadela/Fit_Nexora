-- ============================================================================
-- GymOS SaaS — Initial Database Schema
-- Multi-tenant gym management platform
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── PROFILES ────────────────────────────────────────────────────────────────
-- Extended user profile linked to Supabase auth.users
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  avatar_url TEXT,
  global_role TEXT NOT NULL DEFAULT 'client'
    CHECK (global_role IN ('super_admin', 'gym_owner', 'trainer', 'client')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Auto-create profile on new user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, full_name, email, global_role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'global_role', 'client')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- ─── GYMS ────────────────────────────────────────────────────────────────────
-- Multi-tenant gym entity
CREATE TABLE IF NOT EXISTS gyms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_id UUID NOT NULL REFERENCES profiles(id),
  address TEXT,
  phone TEXT,
  logo_url TEXT,
  plan_tier TEXT NOT NULL DEFAULT 'basic'
    CHECK (plan_tier IN ('basic', 'pro', 'elite')),
  max_clients INT NOT NULL DEFAULT 50,
  max_trainers INT NOT NULL DEFAULT 1,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── GYM MEMBERS ─────────────────────────────────────────────────────────────
-- Join table: users ↔ gyms with per-gym role
CREATE TABLE IF NOT EXISTS gym_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'trainer', 'client')),
  assigned_trainer_id UUID REFERENCES profiles(id),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(gym_id, user_id)
);

-- ─── CLIENTS ─────────────────────────────────────────────────────────────────
-- Client fitness profile within a gym
CREATE TABLE IF NOT EXISTS clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  full_name TEXT,
  email TEXT,
  phone TEXT,
  age INT,
  sex TEXT CHECK (sex IN ('male', 'female', 'other')),
  weight_kg DECIMAL(5,2),
  height_cm DECIMAL(5,2),
  goal TEXT DEFAULT 'general_fitness',
  training_level TEXT DEFAULT 'beginner'
    CHECK (training_level IN ('beginner', 'intermediate', 'advanced')),
  days_per_week INT DEFAULT 3 CHECK (days_per_week BETWEEN 1 AND 7),
  equipment TEXT DEFAULT 'gym',
  diet_type TEXT DEFAULT 'non_veg',
  restrictions TEXT,
  injuries TEXT,
  assigned_trainer_id UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── MEMBERSHIPS ─────────────────────────────────────────────────────────────
-- Client membership (subscription to the gym itself)
CREATE TABLE IF NOT EXISTS memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  plan_name TEXT NOT NULL,
  amount DECIMAL(10,2),
  currency TEXT NOT NULL DEFAULT 'INR',
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'expired', 'cancelled', 'paused')),
  auto_renew BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── SUBSCRIPTIONS ───────────────────────────────────────────────────────────
-- Gym's SaaS subscription (Basic/Pro/Elite from GymOS)
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  plan_tier TEXT NOT NULL DEFAULT 'basic'
    CHECK (plan_tier IN ('basic', 'pro', 'elite')),
  stripe_customer_id TEXT,
  stripe_subscription_id TEXT,
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'past_due', 'cancelled', 'trialing')),
  current_period_start TIMESTAMPTZ,
  current_period_end TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── INDEXES ─────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_gyms_owner ON gyms(owner_id);
CREATE INDEX IF NOT EXISTS idx_gym_members_gym ON gym_members(gym_id);
CREATE INDEX IF NOT EXISTS idx_gym_members_user ON gym_members(user_id);
CREATE INDEX IF NOT EXISTS idx_clients_gym ON clients(gym_id);
CREATE INDEX IF NOT EXISTS idx_clients_trainer ON clients(assigned_trainer_id);
CREATE INDEX IF NOT EXISTS idx_memberships_client ON memberships(client_id);
CREATE INDEX IF NOT EXISTS idx_memberships_gym ON memberships(gym_id);
CREATE INDEX IF NOT EXISTS idx_memberships_status ON memberships(gym_id, status);
CREATE INDEX IF NOT EXISTS idx_memberships_expiry ON memberships(gym_id, end_date)
  WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_subscriptions_gym ON subscriptions(gym_id);

-- ─── UPDATED_AT TRIGGER ─────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER set_updated_at_profiles
  BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE OR REPLACE TRIGGER set_updated_at_gyms
  BEFORE UPDATE ON gyms FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE OR REPLACE TRIGGER set_updated_at_clients
  BEFORE UPDATE ON clients FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE OR REPLACE TRIGGER set_updated_at_memberships
  BEFORE UPDATE ON memberships FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE OR REPLACE TRIGGER set_updated_at_subscriptions
  BEFORE UPDATE ON subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at();
