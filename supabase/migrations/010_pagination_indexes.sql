-- Supports Phase 5 paged queries and dashboard/report lookups.

create index if not exists idx_clients_gym_created_at
  on public.clients (gym_id, created_at desc);

create index if not exists idx_clients_gym_full_name
  on public.clients (gym_id, full_name);

create index if not exists idx_memberships_gym_status_end_date
  on public.memberships (gym_id, status, end_date);

create index if not exists idx_food_logs_user_logged_at
  on public.food_logs (user_id, logged_at desc);

create index if not exists idx_gym_announcements_gym_pinned_created
  on public.gym_announcements (gym_id, is_pinned desc, created_at desc);

create index if not exists idx_gym_checkins_gym_checked_in_at
  on public.gym_checkins (gym_id, checked_in_at desc);
