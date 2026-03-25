-- Persist optional member-selected start dates for diet plans.
ALTER TABLE public.diet_plans
ADD COLUMN IF NOT EXISTS start_date DATE;
