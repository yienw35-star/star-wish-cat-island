-- Run with: supabase test db
-- These checks verify the browser roles receive only intended table/column grants.
begin;
select plan(8);
select ok(not has_table_privilege('anon','public.player_saves','select'),
 'anonymous visitors cannot read player saves');
select ok(has_table_privilege('authenticated','public.player_saves','insert'),
 'signed-in users can create their own save rows (RLS still scopes the row)');
select ok(not has_table_privilege('authenticated','public.leaderboard_entries','insert'),
 'browser clients cannot submit leaderboard scores');
select ok(not has_table_privilege('authenticated','public.leaderboard_entries','update'),
 'browser clients cannot edit leaderboard scores');
select ok(not has_column_privilege('authenticated','public.guild_members','role','insert'),
 'browser clients cannot assign guild roles');
select ok(has_column_privilege('authenticated','public.guild_members','guild_id','insert'),
 'signed-in users can request guild membership');
select ok(not has_column_privilege('authenticated','public.friend_requests','sender_id','update'),
 'friend request ownership cannot be rewritten');
select ok(has_column_privilege('authenticated','public.friend_requests','status','update'),
 'friend request recipient can update response status');
select * from finish();
rollback;
