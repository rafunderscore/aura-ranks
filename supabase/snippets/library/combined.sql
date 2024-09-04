-- reset.sql
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
			typname
		from
			pg_type
		where
			typnamespace = 'public'::regnamespace
			and typtype = 'c')
		loop
			execute 'DROP TYPE IF EXISTS ' || quote_ident(r.typname) || ' CASCADE;';
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



-- tables.sql
create table users(
	id uuid primary key,
	username text not null,
	display_name text,
	avatar_url text,
	bio text,
	website text,
	essence int4 default 100,
	aura int4 default 0,
	aura_rank rank_enum,
	world_location text,
	created_at timestamptz default now(),
	updated_at timestamptz default now()
);

create table evaluations(
	id uuid primary key,
	evaluator_id uuid references users(id),
	evaluatee_id uuid references users(id),
	essence_used int4,
	comment text not null,
	parent_evaluation_id uuid references evaluations(id) on delete cascade,
	created_at timestamptz default now()
);

create table aura_history(
	id uuid,
	user_id uuid references users(id),
	aura_change int4,
	created_at timestamptz default now(),
	primary key (id, created_at)
);

select
	create_hypertable('aura_history', 'created_at');

create table essence_transactions(
	id uuid,
	user_id uuid references users(id),
	amount int4,
	transaction_type text,
	created_at timestamptz default now(),
	primary key (id, created_at)
);

select
	create_hypertable('essence_transactions', 'created_at');

alter table aura_history
	alter column created_at set not null;

alter table essence_transactions
	alter column created_at set not null;

create table follows(
	follower_id uuid references users(id) on delete cascade,
	followed_id uuid references users(id) on delete cascade,
	followed_at timestamptz default now(),
	primary key (follower_id, followed_id)
);



-- views.sql
create view global_leaderboard as
select
	id,
	username,
	display_name,
	aura,
	aura_rank
from
	users
order by
	aura desc;

create view time_based_leaderboard as
select
	u.id,
	u.username,
	u.display_name,
	u.aura_rank,
	sum(ah.aura_change) as aura_gained,
	count(ah.id) as evaluations_received
from
	users u
	join aura_history ah on u.id = ah.user_id
where
	ah.created_at > now() - INTERVAL '30 days'
group by
	u.id,
	u.username,
	u.display_name,
	u.aura_rank
order by
	aura_gained desc;

create view top_evaluators as
select
	u.id,
	u.username,
	u.display_name,
	u.aura_rank,
	count(e.id) as evaluations_made
from
	users u
	join evaluations e on u.id = e.evaluator_id
group by
	u.id,
	u.username,
	u.display_name,
	u.aura_rank
order by
	evaluations_made desc;

create view user_profile as
select
	u.id,
	u.username,
	u.display_name,
	u.aura,
	u.aura_rank,
	sum(
		case when ah.created_at > now() - INTERVAL '30 days' then
			ah.aura_change
		else
			0
		end) as recent_aura_gained,
	count(
		case when ah.created_at > now() - INTERVAL '30 days' then
			ah.id
		else
			null
		end) as evaluations_received
from
	users u
	left join aura_history ah on u.id = ah.user_id
group by
	u.id,
	u.username,
	u.display_name,
	u.aura,
	u.aura_rank;

create view followers_count as
select
	followed_id as user_id,
	count(follower_id) as follower_count
from
	follows
group by
	followed_id;

create view following_count as
select
	follower_id as user_id,
	count(followed_id) as following_count
from
	follows
group by
	follower_id;

create view followers_list as
select
	f.followed_id as user_id,
	u.id as follower_id,
	u.username as follower_username,
	u.display_name as follower_display_name,
	f.followed_at
from
	follows f
	join users u on u.id = f.follower_id
order by
	f.followed_at desc;

create view recent_aura_changes as
select
	ah.user_id,
	u.username,
	ah.aura_change,
	ah.created_at
from
	aura_history ah
	join users u on u.id = ah.user_id
order by
	ah.created_at desc;

create view evaluations_with_user_details as
select
	e.id as evaluation_id,
	e.essence_used,
	e.created_at as evaluation_time,
	ev.id as evaluator_id,
	ev.username as evaluator_username,
	ev.display_name as evaluator_display_name,
	ev.avatar_url as evaluator_avatar,
	ev.aura as evaluator_aura,
	ev.aura_rank as evaluator_aura_rank,
	ee.id as evaluatee_id,
	ee.username as evaluatee_username,
	ee.display_name as evaluatee_display_name,
	ee.avatar_url as evaluatee_avatar,
	ee.aura as evaluatee_aura,
	ee.aura_rank as evaluatee_aura_rank
from
	evaluations e
	join users ev on e.evaluator_id = ev.id
	join users ee on e.evaluatee_id = ee.id
order by
	e.created_at desc;



-- functions.sql
create or replace function calculate_aura_rank(aura int4)
	returns rank_enum
	as $$
begin
	if aura < 100 then
		if aura < 25 then
			return 'Mortal I';
		elsif aura < 50 then
			return 'Mortal II';
		elsif aura < 75 then
			return 'Mortal III';
		else
			return 'Mortal IV';
		end if;
	elsif aura < 500 then
		if aura < 200 then
			return 'Ascendant I';
		elsif aura < 300 then
			return 'Ascendant II';
		elsif aura < 400 then
			return 'Ascendant III';
		else
			return 'Ascendant IV';
		end if;
	elsif aura < 1000 then
		if aura < 600 then
			return 'Seraphic I';
		elsif aura < 700 then
			return 'Seraphic II';
		elsif aura < 800 then
			return 'Seraphic III';
		else
			return 'Seraphic IV';
		end if;
	elsif aura < 5000 then
		if aura < 2000 then
			return 'Angelic I';
		elsif aura < 3000 then
			return 'Angelic II';
		elsif aura < 4000 then
			return 'Angelic III';
		else
			return 'Angelic IV';
		end if;
	elsif aura < 10000 then
		if aura < 6000 then
			return 'Divine I';
		elsif aura < 7000 then
			return 'Divine II';
		elsif aura < 8000 then
			return 'Divine III';
		else
			return 'Divine IV';
		end if;
	elsif aura < 50000 then
		if aura < 20000 then
			return 'Celestial I';
		elsif aura < 30000 then
			return 'Celestial II';
		elsif aura < 40000 then
			return 'Celestial III';
		else
			return 'Celestial IV';
		end if;
	elsif aura < 100000 then
		if aura < 60000 then
			return 'Ethereal I';
		elsif aura < 70000 then
			return 'Ethereal II';
		elsif aura < 80000 then
			return 'Ethereal III';
		else
			return 'Ethereal IV';
		end if;
	else
		return 'Transcendent';
	end if;
end;
$$
language plpgsql;

create or replace function update_aura_rank()
	returns trigger
	as $$
begin
	new.aura_rank := calculate_aura_rank(new.aura);
	return new;
end;
$$
language plpgsql;



-- indexing.sql
create index idx_aura on users(aura desc);

create index idx_aura_rank on users(aura_rank);

create index idx_aura_history_created_at on aura_history(created_at);

create index idx_follower_id on follows(follower_id);

create index idx_followed_id on follows(followed_id);



-- policies.sql
alter table users enable row level security;

create policy "Allow individual users to select their own data" on users
	for select
		using (auth.uid() = id);

create policy "Allow individual users to update their own aura" on users
	for update
		using (auth.uid() = id);



-- triggers.sql
create trigger update_aura_rank_trigger_on_update
	before update on users for each row
	when(old.aura is distinct from new.aura)
	execute function update_aura_rank();

create trigger update_aura_rank_trigger_on_insert
	before insert on users for each row
	execute function update_aura_rank();



