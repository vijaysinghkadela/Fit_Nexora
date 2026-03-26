-- ============================================================================
-- GymOS SaaS — Cashfree Payments Migration
-- ============================================================================

-- ─── B2B (SaaS Subscriptions) ────────────────────────────────────────────────
ALTER TABLE subscriptions DROP COLUMN IF EXISTS razorpay_customer_id;
ALTER TABLE subscriptions DROP COLUMN IF EXISTS razorpay_subscription_id;
ALTER TABLE subscriptions DROP COLUMN IF EXISTS razorpay_plan_id;

ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS cashfree_customer_id TEXT;
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS cashfree_subscription_id TEXT;

-- Update constraint if it exists (we might just leave it)

-- ─── B2C (Gym to Member) ─────────────────────────────────────────────────────
-- Gyms can provide their own Cashfree credentials to collect payments
ALTER TABLE gyms ADD COLUMN IF NOT EXISTS cashfree_app_id TEXT;
ALTER TABLE gyms ADD COLUMN IF NOT EXISTS cashfree_secret_key TEXT;

-- Track membership payment status
ALTER TABLE memberships ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'paid'; 
-- We default to 'paid' for existing memberships so they don't break
ALTER TABLE memberships ADD COLUMN IF NOT EXISTS cashfree_order_id TEXT;

-- Add a check constraint on payment_status if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'memberships_payment_status_check'
  ) THEN
    ALTER TABLE memberships ADD CONSTRAINT memberships_payment_status_check
      CHECK (payment_status IN ('pending', 'paid', 'failed'));
  END IF;
END $$;
