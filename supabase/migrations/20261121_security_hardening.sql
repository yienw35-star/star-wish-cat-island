-- Security hardening migration for existing Star Wish Cat Island projects.
-- Run once in Supabase SQL Editor AFTER the original schema.sql.
-- Re-running is safe.

-- Never allow client users to assign themselves guild officer/owner privileges.
create or replace function public.add_guild_owner_membership()
returns trigger language plpgsql security definer set search_path=public
as $$
begin
 insert into public.guild_members(guild_id,user_id,role)
 values(new.id,new.owner_id,'owner')
 on conflict(guild_id,user_id) do nothing;
 return new;
end;
$$;
drop trigger if exists on_star_wish_guild_created on public.guilds;
create trigger on_star_wish_guild_created after insert on public.guilds
for each row execute procedure public.add_guild_owner_membership();

drop policy if exists "users join guilds as themselves" on public.guild_members;
create policy "users join guilds as themselves" on public.guild_members
for insert to authenticated
with check(user_id=auth.uid() and role='member');

-- A receiver can change only the response fields, not rewrite request ownership.
drop policy if exists "receivers respond to friend requests" on public.friend_requests;
create policy "receivers respond to friend requests" on public.friend_requests
for update to authenticated
using(receiver_id=auth.uid())
with check(receiver_id=auth.uid());

-- Remove broad grants (including any default anon grants), then restore least privilege.
revoke all on table public.profiles, public.player_saves, public.friend_requests,
 public.guilds, public.guild_members, public.leaderboard_entries from anon, authenticated;

grant usage on schema public to authenticated;
grant select on public.profiles to authenticated;
grant update(display_name,avatar_url,updated_at) on public.profiles to authenticated;

grant select,insert,update,delete on public.player_saves to authenticated;

grant select,insert,delete on public.friend_requests to authenticated;
grant update(status,updated_at) on public.friend_requests to authenticated;

grant select,insert,update,delete on public.guilds to authenticated;
grant select,insert,delete on public.guild_members to authenticated;

-- Do not accept browser-submitted power scores as official competitive rankings.
grant select on public.leaderboard_entries to authenticated;

-- Existing guild owners are backfilled into the membership table.
insert into public.guild_members(guild_id,user_id,role)
select id,owner_id,'owner' from public.guilds
on conflict(guild_id,user_id) do update set role='owner';
