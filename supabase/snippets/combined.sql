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

create table users(
	id uuid primary key,
	user_name text not null,
	user_display_name text,
	user_avatar_url text,
	entity_name text not null,
	entity_logo_url text,
	sector sector_enum,
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

create or replace view full_user_details as
select
	u.id,
	u.user_name,
	u.user_display_name,
	u.user_avatar_url,
	u.entity_name,
	u.entity_logo_url,
	u.sector,
	u.bio,
	u.website,
	u.essence,
	u.aura,
	u.aura_rank,
	u.world_location,
	coalesce((
		select
			count(*)
		from follows
		where
			followed_id = u.id), 0) as followers_count,
	coalesce((
		select
			count(*)
		from follows
		where
			follower_id = u.id), 0) as following_count,
	coalesce(sum(ah.aura_change), 0) as total_aura_changes,
	coalesce(sum(
			case when ah.created_at > now() - INTERVAL '30 days' then
				ah.aura_change
			else
				0
			end), 0) as recent_aura_gained,
	coalesce(count(e.id), 0) as evaluations_made,
	coalesce(sum(
			case when e.created_at > now() - INTERVAL '30 days' then
				1
			else
				0
			end), 0) as evaluations_received,
	u.created_at,
	u.updated_at
from
	users u
	left join aura_history ah on u.id = ah.user_id
	left join evaluations e on u.id = e.evaluatee_id
group by
	u.id
order by
	u.aura desc;

create or replace view evaluations_with_parent_details as
select
	e.id as evaluation_id,
	e.essence_used,
	e.comment as evaluation_comment,
	e.created_at as evaluation_time,
	ev.id as evaluator_id,
	ev.user_name as evaluator_username,
	ev.user_display_name as evaluator_display_name,
	ev.user_avatar_url as evaluator_avatar,
	ev.aura as evaluator_aura,
	ev.aura_rank as evaluator_aura_rank,
	ee.id as evaluatee_id,
	ee.user_name as evaluatee_username,
	ee.user_display_name as evaluatee_display_name,
	ee.user_avatar_url as evaluatee_avatar,
	ee.aura as evaluatee_aura,
	ee.aura_rank as evaluatee_aura_rank,
	parent_e.id as parent_evaluation_id,
	parent_e.comment as parent_evaluation_comment,
	parent_ev.id as parent_evaluator_id,
	parent_ev.user_name as parent_evaluator_username,
	parent_ev.user_display_name as parent_evaluator_display_name,
	parent_ev.user_avatar_url as parent_evaluator_avatar,
	parent_ev.aura as parent_evaluator_aura,
	parent_ev.aura_rank as parent_evaluator_aura_rank
from
	evaluations e
	join users ev on e.evaluator_id = ev.id
	join users ee on e.evaluatee_id = ee.id
	left join evaluations parent_e on e.parent_evaluation_id = parent_e.id
	left join users parent_ev on parent_e.evaluator_id = parent_ev.id
order by
	e.created_at desc;

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

create or replace function assign_random_sector()
	returns trigger
	as $$
declare
	random_sector sector_enum;
begin
	if new.sector is null then
		select
			into random_sector(array['Sports', 'Technology', 'Creatives', 'Health', 'Education', 'Finance', 'Entertainment'])[floor(random() * 8 + 1)];
		new.sector := random_sector;
	end if;
	return NEW;
end;
$$
language plpgsql;

create index idx_aura on users(aura desc);

create index idx_aura_rank on users(aura_rank);

create index idx_aura_history_created_at on aura_history(created_at);

create index idx_follower_id on follows(follower_id);

create index idx_followed_id on follows(followed_id);

alter table users enable row level security;

create policy "Allow all users to read users" on users
	for select
		using (true);

create policy "Allow individual users to select their own data" on users
	for select
		using (auth.uid() = id);

create policy "Allow individual users to update their own aura" on users
	for update
		using (auth.uid() = id);

create policy "Allow individual users to insert their own records" on users
	for insert
		with check (auth.uid() = id);

alter table follows enable row level security;

create policy "Allow all users to read follows" on follows
	for select
		using (true);

alter table evaluations enable row level security;

create policy "Allow all users to read evaluations" on evaluations
	for select
		using (true);

create policy "Allow individual users to select their own evaluations" on evaluations
	for select
		using (auth.uid() = evaluator_id);

create policy "Allow individual users to update their own evaluations" on evaluations
	for update
		using (auth.uid() = evaluator_id);

create policy "Allow individual users to insert their own evaluations" on evaluations
	for insert
		with check (auth.uid() = evaluator_id);

alter table aura_history enable row level security;

create policy "Allow all users to read aura history" on aura_history
	for select
		using (true);

create policy "Allow individual users to select their own aura history" on aura_history
	for select
		using (auth.uid() = user_id);

create policy "Allow individual users to insert their own aura history" on aura_history
	for insert
		with check (auth.uid() = user_id);

create policy "Allow individual users to insert follow relationships" on follows
	for insert
		with check (auth.uid() = follower_id);

create policy "Allow individual users to delete follow relationships" on follows
	for delete
		using (auth.uid() = follower_id);

alter table essence_transactions enable row level security;

create policy "Allow all users to read essence transactions" on essence_transactions
	for select
		using (true);

create policy "Allow individual users to select their own essence transactions" on essence_transactions
	for select
		using (auth.uid() = user_id);

create trigger update_aura_rank_trigger_on_update
	before update on users for each row
	when(old.aura is distinct from new.aura)
	execute function update_aura_rank();

create trigger update_aura_rank_trigger_on_insert
	before insert on users for each row
	execute function update_aura_rank();

create trigger before_insert_users_sector
	before insert on users for each row
	execute function assign_random_sector();

