-- Upgrade the existing public.attendance table used by the dashboard.
-- Run this entire file once in Supabase SQL Editor.

alter table public.attendance
    add column if not exists user_id uuid references auth.users(id) on delete cascade,
    add column if not exists check_in_at timestamptz default timezone('utc', now()),
    add column if not exists check_in_latitude double precision,
    add column if not exists check_in_longitude double precision,
    add column if not exists check_out_at timestamptz,
    add column if not exists check_out_latitude double precision,
    add column if not exists check_out_longitude double precision;

create index if not exists attendance_user_check_in_idx
    on public.attendance (user_id, check_in_at desc);

create unique index if not exists one_open_attendance_per_user_idx
    on public.attendance (user_id)
    where check_out_at is null;

alter table public.attendance enable row level security;

drop policy if exists "Users can view their own attendance" on public.attendance;
create policy "Users can view their own attendance"
    on public.attendance for select
    using (auth.uid() = user_id);

drop policy if exists "Users can create their own attendance" on public.attendance;
create policy "Users can create their own attendance"
    on public.attendance for insert
    with check (auth.uid() = user_id);

drop policy if exists "Users can close their own attendance" on public.attendance;
create policy "Users can close their own attendance"
    on public.attendance for update
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

-- Refresh the API schema cache after the columns are added.
notify pgrst, 'reload schema';