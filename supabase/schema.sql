-- Star Wish Cat Island Supabase schema. Run once in Supabase SQL Editor.
-- Use only the browser Publishable Key. Never expose a Secret/Service Role key.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default '星願旅人' check (char_length(display_name) between 1 and 24),
 avatar_url text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.player_saves (
 user_id uuid primary key references auth.users(id) on delete cascade,
 save_data jsonb not null default '{}'::jsonb,
 updated_at timestamptz not null default now()
);
create table if not exists public.friend_requests (
 id uuid primary key default gen_random_uuid(),
 sender_id uuid not null references public.profiles(id) on delete cascade,
 receiver_id uuid not null references public.profiles(id) on delete cascade,
 status text not null default 'pending' check(status in ('pending','accepted','declined')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 constraint friend_request_not_self check(sender_id<>receiver_id),
 constraint friend_request_unique_pair unique(sender_id,receiver_id)
);
create table if not exists public.guilds (
 id uuid primary key default gen_random_uuid(),
 name text not null unique check(char_length(name) between 2 and 32),
 description text not null default '',
 owner_id uuid not null references public.profiles(id) on delete restrict,
 created_at timestamptz not null default now()
);
create table if not exists public.guild_members (
 guild_id uuid not null references public.guilds(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade,
 role text not null default 'member' check(role in ('owner','officer','member')),
 joined_at timestamptz not null default now(),
 primary key(guild_id,user_id)
);
create table if not exists public.leaderboard_entries (
 user_id uuid primary key references public.profiles(id) on delete cascade,
 display_name text not null default '星願旅人',
 power integer not null default 0 check(power>=0),
 adventure_level integer not null default 1 check(adventure_level>=1),
 updated_at timestamptz not null default now()
);
create index if not exists friend_requests_receiver_status_idx on public.friend_requests(receiver_id,status);
create index if not exists guild_members_user_idx on public.guild_members(user_id);
create index if not exists leaderboard_power_idx on public.leaderboard_entries(power desc,updated_at asc);
create or replace function public.handle_new_star_wish_user()
returns trigger language plpgsql security definer set search_path=public
as $$
begin
 insert into public.profiles(id,display_name)
 values(new.id,coalesce(nullif(new.raw_user_meta_data->>'display_name',''),'星願旅人'))
 on conflict(id) do nothing;
 return new;
end;
$$;
drop trigger if exists on_star_wish_user_created on auth.users;
create trigger on_star_wish_user_created after insert on auth.users
for each row execute procedure public.handle_new_star_wish_user();
alter table public.profiles enable row level security;
alter table public.player_saves enable row level security;
alter table public.friend_requests enable row level security;
alter table public.guilds enable row level security;
alter table public.guild_members enable row level security;
alter table public.leaderboard_entries enable row level security;
drop policy if exists "profiles readable by signed-in users" on public.profiles;
create policy "profiles readable by signed-in users" on public.profiles for select to authenticated using(true);
drop policy if exists "users insert own profile" on public.profiles;
create policy "users insert own profile" on public.profiles for insert to authenticated with check(id=auth.uid());
drop policy if exists "users update own profile" on public.profiles;
create policy "users update own profile" on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
drop policy if exists "users manage own save" on public.player_saves;
create policy "users manage own save" on public.player_saves for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
drop policy if exists "users view their friend requests" on public.friend_requests;
create policy "users view their friend requests" on public.friend_requests for select to authenticated using(sender_id=auth.uid() or receiver_id=auth.uid());
drop policy if exists "users send friend requests" on public.friend_requests;
create policy "users send friend requests" on public.friend_requests for insert to authenticated with check(sender_id=auth.uid() and receiver_id<>auth.uid());
drop policy if exists "participants update friend requests" on public.friend_requests;
create policy "receivers respond to friend requests" on public.friend_requests for update to authenticated using(receiver_id=auth.uid()) with check(receiver_id=auth.uid());
drop policy if exists "participants delete friend requests" on public.friend_requests;
create policy "participants delete friend requests" on public.friend_requests for delete to authenticated using(sender_id=auth.uid() or receiver_id=auth.uid());
drop policy if exists "signed-in users view guilds" on public.guilds;
create policy "signed-in users view guilds" on public.guilds for select to authenticated using(true);
drop policy if exists "users create guilds as owner" on public.guilds;
create policy "users create guilds as owner" on public.guilds for insert to authenticated with check(owner_id=auth.uid());
drop policy if exists "owners update guilds" on public.guilds;
create policy "owners update guilds" on public.guilds for update to authenticated using(owner_id=auth.uid()) with check(owner_id=auth.uid());
drop policy if exists "owners delete guilds" on public.guilds;
create policy "owners delete guilds" on public.guilds for delete to authenticated using(owner_id=auth.uid());
drop policy if exists "signed-in users view guild membership" on public.guild_members;
create policy "signed-in users view guild membership" on public.guild_members for select to authenticated using(true);
drop policy if exists "users join guilds as themselves" on public.guild_members;
create policy "users join guilds as themselves" on public.guild_members for insert to authenticated with check(user_id=auth.uid());
drop policy if exists "users leave or guild owners remove members" on public.guild_members;
create policy "users leave or guild owners remove members" on public.guild_members for delete to authenticated using(user_id=auth.uid() or exists(select 1 from public.guilds g where g.id=guild_id and g.owner_id=auth.uid()));
drop policy if exists "signed-in users view leaderboard" on public.leaderboard_entries;
create policy "signed-in users view leaderboard" on public.leaderboard_entries for select to authenticated using(true);
drop policy if exists "users publish own leaderboard row" on public.leaderboard_entries;
create policy "users publish own leaderboard row" on public.leaderboard_entries for insert to authenticated with check(user_id=auth.uid());
drop policy if exists "users update own leaderboard row" on public.leaderboard_entries;
create policy "users update own leaderboard row" on public.leaderboard_entries for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
grant usage on schema public to authenticated;
grant select,insert,update on public.profiles to authenticated;
grant select,insert,update,delete on public.player_saves to authenticated;
grant select,insert,update,delete on public.friend_requests to authenticated;
grant select,insert,update,delete on public.guilds to authenticated;
grant select,insert,delete on public.guild_members to authenticated;
grant select,insert,update on public.leaderboard_entries to authenticated;
