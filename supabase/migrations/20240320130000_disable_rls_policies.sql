-- Migration: Disable RLS Policies
-- Description: Disables RLS policies for app, generations, and generations_error_log tables

-- Disable RLS on all tables
alter table public.continents disable row level security;
alter table public.countries disable row level security;
alter table public.user_visited_countries disable row level security;
alter table public.planned_visits disable row level security;
alter table public.user_map_settings disable row level security;

-- Drop all existing policies
drop policy if exists "continents are viewable by everyone" on public.continents;
drop policy if exists "countries are viewable by everyone" on public.countries;
drop policy if exists "users can view their own visited countries" on public.user_visited_countries;
drop policy if exists "users can insert their own visited countries" on public.user_visited_countries;
drop policy if exists "users can delete their own visited countries" on public.user_visited_countries;
drop policy if exists "users can manage their planned visits" on public.planned_visits;
drop policy if exists "users can manage their map settings" on public.user_map_settings; 