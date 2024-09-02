create table PUBLIC.users(
	id uuid primary key,
	username text unique not null,
	display_name text,
	world_location text,
	avatar_url text,
	bio text,
	website text,
	aura_tier aura_tier default 'common',
	aura_level integer default 0,
	aura_points integer default 5,
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
	aura_points_used integer not null check (aura_points_used > 0),
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

create trigger audit_users
	after insert or update or delete on PUBLIC.users for each row
	execute function log_user_changes();

