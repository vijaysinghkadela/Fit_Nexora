-- Migration 020: Security Fixes

-- 1. Enable RLS on public.profiles (policies exist but RLS was disabled)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 2. Lock function search paths to prevent privilege escalation
ALTER FUNCTION public.update_updated_at() SET search_path = public;
ALTER FUNCTION public.generate_invoice_number() SET search_path = public;
ALTER FUNCTION public.check_client_cap() SET search_path = public;
ALTER FUNCTION public.check_trainer_cap() SET search_path = public;
ALTER FUNCTION public.handle_new_user() SET search_path = public;
