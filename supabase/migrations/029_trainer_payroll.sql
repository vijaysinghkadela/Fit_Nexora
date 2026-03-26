-- 029_trainer_payroll.sql
-- Migration to add trainer contracts and payroll system

-- 1. Trainer Contracts
-- Links a trainer to a gym with their salary details
CREATE TABLE IF NOT EXISTS trainer_contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
    trainer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    base_salary DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN NOT NULL DEFAULT true,
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(gym_id, trainer_id)
);

-- 2. Payroll Runs
-- Represents a monthly pay cycle for the whole gym
CREATE TABLE IF NOT EXISTS payroll_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
    month INT NOT NULL CHECK (month >= 1 AND month <= 12),
    year INT NOT NULL CHECK (year >= 2024),
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'processed', 'paid')),
    total_payout DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(gym_id, month, year)
);

-- 3. Salary Slips
-- The individual payout record for a trainer in a specific run
CREATE TABLE IF NOT EXISTS salary_slips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payroll_run_id UUID NOT NULL REFERENCES payroll_runs(id) ON DELETE CASCADE,
    trainer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE, -- denormalized for easier querying
    base_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    bonuses DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    deductions DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    tax_deductions DECIMAL(10, 2) NOT NULL DEFAULT 0.00, -- Future proofing (TDS/PF/etc)
    net_payable DECIMAL(10, 2) GENERATED ALWAYS AS (base_amount + bonuses - deductions - tax_deductions) STORED,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(payroll_run_id, trainer_id)
);

-- RLS Policies

-- trainer_contracts
ALTER TABLE trainer_contracts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Gym owners can manage their trainer contracts" ON trainer_contracts
    FOR ALL USING (
        gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid())
    );
CREATE POLICY "Trainers can view their own contracts" ON trainer_contracts
    FOR SELECT USING (trainer_id = auth.uid());

-- payroll_runs
ALTER TABLE payroll_runs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Gym owners can manage their payroll runs" ON payroll_runs
    FOR ALL USING (
        gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid())
    );
CREATE POLICY "Trainers can view payroll runs for their slips" ON payroll_runs
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM salary_slips WHERE salary_slips.payroll_run_id = payroll_runs.id AND salary_slips.trainer_id = auth.uid())
    );

-- salary_slips
ALTER TABLE salary_slips ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Gym owners can manage their gym's salary slips" ON salary_slips
    FOR ALL USING (
        gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid())
    );
CREATE POLICY "Trainers can view their own salary slips" ON salary_slips
    FOR SELECT USING (trainer_id = auth.uid());

-- Triggers for updated_at
CREATE OR REPLACE TRIGGER set_updated_at_trainer_contracts
  BEFORE UPDATE ON trainer_contracts FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER set_updated_at_payroll_runs
  BEFORE UPDATE ON payroll_runs FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER set_updated_at_salary_slips
  BEFORE UPDATE ON salary_slips FOR EACH ROW EXECUTE FUNCTION update_updated_at();
