-- ============================================================================
-- GymOS SaaS — Expanded Subscriptions & GST Invoices
-- ============================================================================

-- ─── EXPAND SUBSCRIPTIONS TABLE ──────────────────────────────────────────────

-- Razorpay fields (Indian market)
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS razorpay_customer_id TEXT;
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS razorpay_subscription_id TEXT;
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS razorpay_plan_id TEXT;

-- Payment gateway
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS payment_gateway TEXT DEFAULT 'none';
  -- Options: none | stripe | razorpay

-- Billing
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS billing_interval TEXT DEFAULT 'monthly';
  -- Options: monthly | annual

-- Trial
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS is_trialing BOOLEAN DEFAULT false;
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS trial_start TIMESTAMPTZ;
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS trial_end TIMESTAMPTZ;

-- Financials
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS amount_paid DECIMAL(10,2);
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'INR';
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS overage_charges DECIMAL(10,2) DEFAULT 0;

-- GST
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS gst_number TEXT;

-- ─── GST INVOICES TABLE ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS gst_invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES subscriptions(id),
  client_id UUID REFERENCES clients(id),

  invoice_number TEXT NOT NULL UNIQUE,
  invoice_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  due_date TIMESTAMPTZ,

  subtotal DECIMAL(10,2) NOT NULL,
  gst_rate DECIMAL(5,2) NOT NULL DEFAULT 18.00,
  cgst_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  sgst_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  igst_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_amount DECIMAL(10,2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'INR',

  seller_gstin TEXT,
  buyer_gstin TEXT,
  place_of_supply TEXT,
  hsn TEXT NOT NULL DEFAULT '998314',

  description TEXT NOT NULL,
  quantity INT NOT NULL DEFAULT 1,

  status TEXT NOT NULL DEFAULT 'paid',
  payment_id TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS
ALTER TABLE gst_invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY gst_invoices_owner_select ON gst_invoices
  FOR SELECT USING (
    gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid())
  );

CREATE POLICY gst_invoices_service_all ON gst_invoices
  FOR ALL USING (auth.role() = 'service_role');

-- Indexes
CREATE INDEX IF NOT EXISTS idx_gst_invoices_gym ON gst_invoices(gym_id);
CREATE INDEX IF NOT EXISTS idx_gst_invoices_number ON gst_invoices(invoice_number);
CREATE INDEX IF NOT EXISTS idx_subscriptions_gateway ON subscriptions(payment_gateway);
CREATE INDEX IF NOT EXISTS idx_subscriptions_trial ON subscriptions(is_trialing) WHERE is_trialing = true;

-- ─── AUTO-INCREMENT INVOICE NUMBER ───────────────────────────────────────────
CREATE SEQUENCE IF NOT EXISTS invoice_number_seq START WITH 1;

CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.invoice_number := 'GYMOS-' || TO_CHAR(now(), 'YYYY') || '-' || LPAD(nextval('invoice_number_seq')::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER auto_invoice_number
  BEFORE INSERT ON gst_invoices
  FOR EACH ROW
  WHEN (NEW.invoice_number IS NULL OR NEW.invoice_number = '')
  EXECUTE FUNCTION generate_invoice_number();
