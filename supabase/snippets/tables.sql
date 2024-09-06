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

