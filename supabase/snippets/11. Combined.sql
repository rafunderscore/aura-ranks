-- 1. Reset.sql
do $$
declare
	r RECORD;
begin
	for r in (
		select
			schemaname,
			tablename,
			policyname
		from
			pg_policies
		where
			schemaname = 'public')
		loop
			execute 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON ' || quote_ident(r.schemaname) || '.' || quote_ident(r.tablename) || ' CASCADE;';
		end loop;
	for r in (
		select
			trigger_name,
			event_object_table
		from
			information_schema.triggers
		where
			trigger_schema = 'public')
		loop
			execute 'DROP TRIGGER IF EXISTS ' || quote_ident(r.trigger_name) || ' ON ' || quote_ident(r.event_object_table) || ' CASCADE;';
		end loop;
	for r in (
		select
			tablename
		from
			pg_tables
		where
			schemaname = 'public')
		loop
			execute 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE;';
		end loop;
	for r in (
		select
			table_name
		from
			information_schema.views
		where
			table_schema = 'public')
		loop
			execute 'DROP VIEW IF EXISTS ' || quote_ident(r.table_name) || ' CASCADE;';
		end loop;
	for r in (
		select
			routine_name
		from
			information_schema.routines
		where
			routine_schema = 'public')
		loop
			execute 'DROP FUNCTION IF EXISTS ' || quote_ident(r.routine_name) || '() CASCADE;';
		end loop;
	for r in (
		select
			typname
		from
			pg_type
		where
			typnamespace = 'public'::regnamespace
			and typtype = 'c')
		loop
			execute 'DROP TYPE IF EXISTS ' || quote_ident(r.typname) || ' CASCADE;';
		end loop;
end
$$;

drop type if exists level;

drop type if exists sign;



-- 2. Types.sql
create type PUBLIC.level as enum(
	'shadowed',
	'fading',
	'common',
	'radiant',
	'ethereal'
);

create type PUBLIC.sign as enum(
	'positive',
	'negative'
);



-- 3. Tables.sql
create table PUBLIC.users(
	id uuid primary key,
	username text unique not null,
	display_name text,
	world_location text,
	avatar_url text,
	bio text,
	website text,
	level level default 'common',
	aura integer default 0,
	essence integer default 5,
	followers_count integer default 0,
	following_count integer default 0,
	created_at timestamptz default now(),
	updated_at timestamptz default now(),
	privacy_settings jsonb default '{}' ::jsonb
);

create table PUBLIC.follows(
	follower_id uuid references PUBLIC.users(id) on delete cascade not null,
	followed_id uuid references PUBLIC.users(id) on delete cascade not null,
	followed_at timestamptz default now(),
	primary key (follower_id, followed_id)
);

create table PUBLIC.evaluations(
	id uuid primary key default gen_random_uuid(),
	parent_id uuid references PUBLIC.evaluations(id) on delete cascade,
	evaluator_id uuid references PUBLIC.users(id) on delete cascade not null,
	evaluatee_id uuid references PUBLIC.users(id) on delete cascade not null,
	essence_used integer not null check (essence_used > 0),
	sign sign not null,
	COMMENT text check (char_length(COMMENT) <= 10000),
	created_at timestamptz default now(),
	constraint evaluator_not_target check (evaluator_id != evaluatee_id)
);

create table audit_log(
	id uuid primary key default gen_random_uuid(),
	user_id uuid,
	action text,
	table_name text,
	changed_data jsonb,
	action_time timestamptz default now()
);



-- 4. Views.sql
create or replace view leaderboard as
select
	id,
	username,
	display_name,
	aura,
	rank() over (order by aura desc, essence desc) as rank
from
	PUBLIC.users
where
	aura > 0;

create materialized view leaderboard_mview as
select
	id,
	username,
	display_name,
	aura,
	rank() over (order by aura desc, essence desc) as rank
from
	PUBLIC.users
where
	aura > 0 with no DATA;

refresh materialized view leaderboard_mview;

create or replace view comment_threads as
WITH recursive thread as (
	select
		id,
		evaluator_id,
		evaluatee_id,
		essence_used,
		sign,
		comment,
		created_at,
		parent_id,
		0 as level
	from
		PUBLIC.evaluations
	where
		parent_id is null
	union all
	select
		e.id,
		e.evaluator_id,
		e.evaluatee_id,
		e.essence_used,
		e.sign,
		e.comment,
		e.created_at,
		e.parent_id,
		t.level + 1
	from
		PUBLIC.evaluations e
		inner join thread t on e.parent_id = t.id
)
select
	*
from
	thread
order by
	level asc,
	created_at asc;

create or replace view user_evaluations as
select
	e.id as evaluation_id,
	e.evaluator_id,
	evaluator.username as evaluator_username,
	evaluator.display_name as evaluator_display_name,
	evaluator.avatar_url as evaluator_avatar_url,
	e.evaluatee_id,
	evaluatee.username as evaluatee_username,
	evaluatee.display_name as evaluatee_display_name,
	evaluatee.avatar_url as evaluatee_avatar_url,
	e.essence_used,
	e.sign,
	e.comment,
	e.created_at as evaluation_created_at
from
	PUBLIC.evaluations e
	join PUBLIC.users evaluator on e.evaluator_id = evaluator.id
	join PUBLIC.users evaluatee on e.evaluatee_id = evaluatee.id;



-- 5. Indexing.sql
create index idx_users_username on PUBLIC.users(username);

create index idx_users_level on PUBLIC.users(level);

create index idx_follows_follower_id on PUBLIC.follows(follower_id);

create index idx_follows_followed_id on PUBLIC.follows(followed_id);

create index idx_evaluations_evaluator_id on PUBLIC.evaluations(evaluator_id);

create index idx_evaluations_evaluatee_id on PUBLIC.evaluations(evaluatee_id);

create index idx_users_aura on PUBLIC.users(aura);

create index idx_users_essence on PUBLIC.users(essence);



-- 6. Policies.sql
alter table PUBLIC.users enable row level security;

create policy "Public users are viewable by everyone." on PUBLIC.users
	for select
		using (true);

create policy "Users can insert their own profile." on PUBLIC.users
	for insert
		with check (auth.uid() = id);

create policy "Users can update own profile." on PUBLIC.users
	for update
		using (auth.uid() = id);

alter table PUBLIC.follows enable row level security;

create policy "Users can view their own follows" on PUBLIC.follows
	for select
		using (auth.uid() = follower_id
			or auth.uid() = followed_id);

create policy "Users can remove their own follows" on PUBLIC.follows
	for delete
		using (auth.uid() = follower_id);

alter table PUBLIC.evaluations enable row level security;

create policy "Users can view their own evaluations or those about them" on PUBLIC.evaluations
	for select
		using (auth.uid() = evaluator_id
			or auth.uid() = evaluatee_id);

create policy "Users can create evaluations for others" on PUBLIC.evaluations
	for insert
		with check (auth.uid() = evaluator_id);

create policy "Enable read access for all users" on PUBLIC.evaluations
	for select
		using (true);



-- 7. Functions.sql
create or replace function update_updated_at_column()
	returns trigger
	as $$
begin
	new.updated_at = now();
	return NEW;
end;
$$
language plpgsql;

create or replace function update_follow_counts()
	returns trigger
	as $$
begin
	if TG_OP = 'INSERT' then
		update
			PUBLIC.users
		set
			followers_count = followers_count + 1
		where
			id = new.followed_id;
		update
			PUBLIC.users
		set
			following_count = following_count + 1
		where
			id = new.follower_id;
	elsif TG_OP = 'DELETE' then
		update
			PUBLIC.users
		set
			followers_count = followers_count - 1
		where
			id = old.followed_id;
		update
			PUBLIC.users
		set
			following_count = following_count - 1
		where
			id = old.follower_id;
	end if;
	return NEW;
end;
$$
language plpgsql;

create or replace function PUBLIC.handle_new_user()
	returns trigger
	as $$
begin
	insert into PUBLIC.users(id, username, display_name, avatar_url, created_at, updated_at)
		values(new.id, new.email, new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'avatar_url', now(), now());
	return NEW;
end;
$$
language plpgsql
security definer;

create or replace function log_user_changes()
	returns trigger
	as $$
begin
	insert into audit_log(user_id, action, table_name, changed_data)
		values(auth.uid(), TG_OP, TG_TABLE_NAME, row_to_json(NEW));
	return NEW;
end;
$$
language plpgsql;



-- 8. Triggers.sql
create trigger trigger_update_updated_at
	before update on PUBLIC.users for each row
	execute function update_updated_at_column();

create trigger trigger_update_follow_counts
	after insert or delete on PUBLIC.follows for each row
	execute function update_follow_counts();

create trigger on_auth_user_created
	after insert on auth.users for each row
	execute function PUBLIC.handle_new_user();

create trigger audit_users
	after insert or update or delete on PUBLIC.users for each row
	execute function log_user_changes();



