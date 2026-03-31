-- =============================================
-- HALAL.COM — Supabase Database Schema
-- =============================================
-- Run this in your Supabase SQL Editor
-- =============================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ─── PROFILES ────────────────────────────────────────────────────────────────
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text not null,
  display_name text,
  avatar_url text,
  created_at timestamptz default now()
);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ─── PRODUCTS ─────────────────────────────────────────────────────────────────
create table if not exists public.products (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  brand text,
  barcode text unique,
  status text not null check (status in ('halal', 'haram', 'doubtful')) default 'doubtful',
  reason text,
  ingredients text[],
  image_url text,
  category text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Index for fast barcode lookup
create index if not exists products_barcode_idx on public.products(barcode);
create index if not exists products_status_idx on public.products(status);
create index if not exists products_name_idx on public.products using gin(to_tsvector('english', name));

-- ─── BRANDS ───────────────────────────────────────────────────────────────────
create table if not exists public.brands (
  id uuid default uuid_generate_v4() primary key,
  name text not null unique,
  status text not null check (status in ('halal', 'haram', 'doubtful')) default 'doubtful',
  logo_url text,
  country text,
  reason text,
  created_at timestamptz default now()
);

create index if not exists brands_name_idx on public.brands(name);

-- ─── FAVORITES ────────────────────────────────────────────────────────────────
create table if not exists public.favorites (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  product_id uuid references public.products(id) on delete cascade not null,
  created_at timestamptz default now(),
  unique(user_id, product_id)
);

create index if not exists favorites_user_idx on public.favorites(user_id);

-- ─── REPORTS ──────────────────────────────────────────────────────────────────
create table if not exists public.reports (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete set null,
  product_name text not null,
  barcode text,
  issue_type text not null,
  details text not null,
  status text default 'pending' check (status in ('pending', 'reviewed', 'resolved', 'rejected')),
  admin_notes text,
  created_at timestamptz default now()
);

-- ─── ROW LEVEL SECURITY ───────────────────────────────────────────────────────

-- Profiles: users can only see/edit their own
alter table public.profiles enable row level security;
create policy "Users can view own profile" on public.profiles
  for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles
  for update using (auth.uid() = id);

-- Products: public read, no public write
alter table public.products enable row level security;
create policy "Anyone can view products" on public.products
  for select using (true);

-- Brands: public read
alter table public.brands enable row level security;
create policy "Anyone can view brands" on public.brands
  for select using (true);

-- Favorites: users manage their own
alter table public.favorites enable row level security;
create policy "Users can manage own favorites" on public.favorites
  for all using (auth.uid() = user_id);

-- Reports: users can submit and see their own
alter table public.reports enable row level security;
create policy "Users can submit reports" on public.reports
  for insert with check (auth.uid() = user_id or user_id is null);
create policy "Users can view own reports" on public.reports
  for select using (auth.uid() = user_id);

-- ─── SAMPLE DATA ──────────────────────────────────────────────────────────────

-- Sample brands
insert into public.brands (name, status, country, reason) values
  ('Nestlé', 'halal', 'Switzerland', 'Halal certified in most product lines globally'),
  ('Heinz', 'halal', 'USA', 'Plant-based sauces, halal certified'),
  ('Ferrero', 'halal', 'Italy', 'Nutella and Ferrero Rocher are halal certified'),
  ('Mars', 'halal', 'USA', 'Most chocolate bars are halal certified'),
  ('Haribo', 'haram', 'Germany', 'Uses pork-derived gelatin in gummy products'),
  ('PepsiCo', 'doubtful', 'USA', 'Some products contain questionable flavors')
on conflict (name) do nothing;

-- Sample products
insert into public.products (name, brand, barcode, status, reason, ingredients, category) values
  (
    'Cadbury Dairy Milk',
    'Mondelez',
    '012345678901',
    'halal',
    'All ingredients are halal certified. No animal-derived additives.',
    ARRAY['Sugar', 'Cocoa Mass', 'Milk Powder', 'Cocoa Butter', 'Vegetable Fat', 'Emulsifiers', 'Flavorings'],
    'Chocolate'
  ),
  (
    'Lay''s Classic Chips',
    'PepsiCo',
    '028400321198',
    'halal',
    'Simple ingredients, no haram additives detected.',
    ARRAY['Potatoes', 'Vegetable Oil', 'Salt'],
    'Snacks'
  ),
  (
    'Haribo Gummy Bears',
    'Haribo',
    '042238320244',
    'haram',
    'Contains pork-derived gelatin which is not permissible in Islam.',
    ARRAY['Sugar', 'Glucose Syrup', 'Gelatin (Pork)', 'Citric Acid', 'Starch', 'Natural Flavors', 'Colors'],
    'Candy'
  ),
  (
    'Kit Kat Chocolate',
    'Nestlé',
    '034000002528',
    'halal',
    'Halal certified. No pork or alcohol-derived ingredients.',
    ARRAY['Sugar', 'Wheat Flour', 'Cocoa Butter', 'Skim Milk Powder', 'Cocoa Mass', 'Vegetable Fat', 'Soy Lecithin'],
    'Chocolate'
  ),
  (
    'Doritos Nacho Cheese',
    'PepsiCo',
    '028400090032',
    'doubtful',
    'Contains natural flavors which may include non-halal sources. Verify with manufacturer.',
    ARRAY['Corn', 'Vegetable Oil', 'Cheddar Cheese', 'Whey', 'Buttermilk', 'Natural Flavors', 'Salt'],
    'Snacks'
  ),
  (
    'Heinz Tomato Ketchup',
    'Heinz',
    '013000006323',
    'halal',
    'Plant-based ingredients only. Halal certified in most markets.',
    ARRAY['Tomato Concentrate', 'Distilled Vinegar', 'High Fructose Corn Syrup', 'Sugar', 'Salt', 'Spice'],
    'Condiments'
  ),
  (
    'Nutella',
    'Ferrero',
    '009800895007',
    'halal',
    'Halal certified globally. No animal fat or pork derivatives.',
    ARRAY['Sugar', 'Palm Oil', 'Hazelnuts', 'Cocoa', 'Skim Milk', 'Whey', 'Lecithin', 'Vanillin'],
    'Spreads'
  )
on conflict (barcode) do nothing;
