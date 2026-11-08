-- Taste Doner cloud database. Run once in Supabase SQL Editor.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 role text not null default 'staff' check (role in ('owner','staff')),
 display_name text,
 created_at timestamptz not null default now()
);
create or replace function public.create_profile_for_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into public.profiles(id,role) values(new.id,'staff') on conflict(id) do nothing; return new; end; $$;
drop trigger if exists on_auth_user_created_taste_doner on auth.users;
create trigger on_auth_user_created_taste_doner after insert on auth.users for each row execute procedure public.create_profile_for_new_user();
create or replace function public.current_user_role() returns text language sql stable security definer set search_path=public as $$ select role from public.profiles where id=auth.uid() $$;
create or replace function public.is_owner() returns boolean language sql stable security definer set search_path=public as $$ select coalesce(public.current_user_role()='owner',false) $$;
create table if not exists public.menu_items(id uuid primary key default gen_random_uuid(),name text not null,price numeric(12,2) not null check(price>=0),cost numeric(12,2),created_at timestamptz not null default now());
create table if not exists public.sales(id uuid primary key default gen_random_uuid(),created_by uuid not null references auth.users(id),sold_on date not null default current_date,payment text not null default 'Cash',discount numeric(12,2) not null default 0,total numeric(12,2) not null,items jsonb not null,created_at timestamptz not null default now());
create table if not exists public.expenses(id uuid primary key default gen_random_uuid(),created_by uuid not null references auth.users(id),spent_on date not null default current_date,type text not null,amount numeric(12,2) not null check(amount>0),note text,created_at timestamptz not null default now());
create table if not exists public.stock_purchases(id uuid primary key default gen_random_uuid(),created_by uuid not null references auth.users(id),purchased_on date not null default current_date,name text not null,quantity text,amount numeric(12,2) not null check(amount>0),supplier text,created_at timestamptz not null default now());
alter table public.profiles enable row level security;alter table public.menu_items enable row level security;alter table public.sales enable row level security;alter table public.expenses enable row level security;alter table public.stock_purchases enable row level security;
drop policy if exists profile_self_read on public.profiles;create policy profile_self_read on public.profiles for select to authenticated using(id=auth.uid() or public.is_owner());
drop policy if exists menu_read on public.menu_items;create policy menu_read on public.menu_items for select to authenticated using(true);
drop policy if exists menu_owner_write on public.menu_items;create policy menu_owner_write on public.menu_items for all to authenticated using(public.is_owner()) with check(public.is_owner());
drop policy if exists sales_read on public.sales;create policy sales_read on public.sales for select to authenticated using(true);
drop policy if exists sales_insert on public.sales;create policy sales_insert on public.sales for insert to authenticated with check(created_by=auth.uid());
drop policy if exists sales_owner_update on public.sales;create policy sales_owner_update on public.sales for update to authenticated using(public.is_owner()) with check(public.is_owner());
drop policy if exists sales_owner_delete on public.sales;create policy sales_owner_delete on public.sales for delete to authenticated using(public.is_owner());
drop policy if exists expenses_read on public.expenses;create policy expenses_read on public.expenses for select to authenticated using(true);
drop policy if exists expenses_insert on public.expenses;create policy expenses_insert on public.expenses for insert to authenticated with check(created_by=auth.uid());
drop policy if exists expenses_owner_update on public.expenses;create policy expenses_owner_update on public.expenses for update to authenticated using(public.is_owner()) with check(public.is_owner());
drop policy if exists expenses_owner_delete on public.expenses;create policy expenses_owner_delete on public.expenses for delete to authenticated using(public.is_owner());
drop policy if exists stock_read on public.stock_purchases;create policy stock_read on public.stock_purchases for select to authenticated using(true);
drop policy if exists stock_owner_write on public.stock_purchases;create policy stock_owner_write on public.stock_purchases for all to authenticated using(public.is_owner()) with check(public.is_owner());
insert into public.menu_items(name,price,cost) values
('Small shawarma',100,80),('Medium shawarma',150,90),('Large shawarma',200,95),('Egg burger',180,85),('Burger without egg',140,75),('Fries',100,null)
on conflict do nothing;
-- After creating the Owner login in the app, replace the email below and run this once:
-- update public.profiles set role='owner' where id=(select id from auth.users where email='YOUR_OWNER_EMAIL');
-- Enable Realtime for sales, expenses, stock_purchases and menu_items in Database -> Publications -> supabase_realtime.
