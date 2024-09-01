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
	evaluator_id uuid references PUBLIC.users(id) on delete cascade not null,
	evaluatee_id uuid references PUBLIC.users(id) on delete cascade not null,
	aura_points_used integer not null check (aura_points_used > 0),
	sign sign not null,
	COMMENT text check (char_length(COMMENT) <= 10000),
	created_at timestamptz default now(),
	constraint evaluator_not_target check (evaluator_id != evaluatee_id)
);

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

create index idx_users_username on PUBLIC.users(username);

create index idx_users_aura_tier on PUBLIC.users(aura_tier);

create index idx_follows_follower_id on PUBLIC.follows(follower_id);

create index idx_follows_followed_id on PUBLIC.follows(followed_id);

create index idx_evaluations_evaluator_id on PUBLIC.evaluations(evaluator_id);

create index idx_evaluations_evaluatee_id on PUBLIC.evaluations(evaluatee_id);

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

create trigger trigger_update_updated_at
	before update on PUBLIC.users for each row
	execute function update_updated_at_column();

create trigger trigger_update_follow_counts
	after insert or delete on PUBLIC.follows for each row
	execute function update_follow_counts();

create trigger on_auth_user_created
	after insert on auth.users for each row
	execute function PUBLIC.handle_new_user();

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('c062042f-6446-4376-b543-d64d70eabc0d', '@Lue.Mraz', 'Lue Mraz', 'Walshfield, Egypt', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Lue.Mraz', 'tablecloth devotee', 'https://steel-waiver.biz/', 'fading', 8, 802, 198, 400, '2024-08-08T07:43:34.237Z', '2024-09-01T00:55:50.719Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('e5ae947f-cd22-4c36-8410-17b88f2d4b54', '@Isidro.Reilly15', 'Isidro Reilly', 'Bruenstad, Indonesia', 'https://anime.kirwako.com/api/avatar?name=%40Isidro.Reilly15', 'overload fan', 'https://delightful-jogging.biz/', 'common', 10, 922, 483, 262, '2024-02-28T17:17:13.578Z', '2024-09-01T13:06:27.718Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('f77c87aa-12b5-464a-8629-b607776f75f0', '@Troy.Heller', 'Troy Heller', 'South Estellabury, Montenegro', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Troy.Heller', 'earthquake devotee', 'https://wooden-neurobiologist.info', 'shadowed', 3, 176, 179, 49, '2024-08-24T10:45:57.703Z', '2024-08-31T16:37:08.623Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('8be08817-fd8b-465f-a436-50e8a2816d62', '@Blanche.Dibbert', 'Blanche Dibbert', 'Brettfield, Algeria', 'https://anime.kirwako.com/api/avatar?name=%40Blanche.Dibbert', 'pentagon fan  🍺', 'https://medical-studio.biz', 'radiant', 8, 50, 284, 239, '2024-03-03T09:12:04.923Z', '2024-09-01T15:24:41.603Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('ab75d59a-650e-4768-a6fd-00272eaf98b2', '@Ryan_Lindgren4', 'Ryan Lindgren', 'Lubbock, Belgium', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Ryan_Lindgren4', 'philosopher, scientist', 'https://improbable-discussion.org/', 'shadowed', 9, 191, 298, 434, '2023-11-19T19:41:55.546Z', '2024-08-31T19:08:35.784Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('30f64f29-7abd-42ad-a610-92f2b64e5d5e', '@Rocio.Hirthe86', 'Rocio Hirthe', 'Fisherville, Democratic Republic of the Congo', 'https://anime.kirwako.com/api/avatar?name=%40Rocio.Hirthe86', 'designer, inventor, philosopher', 'https://timely-scene.info', 'shadowed', 9, 697, 104, 135, '2024-07-08T10:21:33.672Z', '2024-09-01T12:49:34.357Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('5fe704f1-a885-4d95-bab3-639503750f61', '@Callie11', 'Callie Dooley', 'Kilbackport, Bermuda', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Callie11', 'traveler, teacher, writer 🇨🇭', 'https://plaintive-manhunt.net', 'radiant', 3, 59, 88, 468, '2024-06-12T01:13:38.671Z', '2024-08-31T20:45:51.512Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('7e3e93a1-32cb-4931-a3df-f7bc90abd991', '@Blanca23', 'Blanca O''Conner', 'Fort Trentside, Sri Lanka', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Blanca23', 'educator', 'https://imaginative-collagen.info/', 'common', 3, 210, 54, 499, '2024-04-05T15:23:14.120Z', '2024-09-01T09:03:55.123Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('e1b52554-e67a-4488-95b8-e13faf830852', '@Terry_Nitzsche', 'Terry Nitzsche', 'South Danykaview, French Guiana', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Terry_Nitzsche', 'streamer, author, activist', 'https://sticky-jam.name', 'fading', 4, 323, 350, 491, '2023-10-26T23:51:44.193Z', '2024-09-01T03:19:26.968Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('eeedb312-c02c-4480-b6e4-7a3145cbb44a', '@Florian_Murazik17', 'Florian Murazik', 'North Loma, Falkland Islands (Malvinas)', 'https://anime.kirwako.com/api/avatar?name=%40Florian_Murazik17', 'dinosaur supporter  🧐', 'https://fitting-durian.info/', 'radiant', 5, 790, 357, 114, '2024-07-23T22:33:30.643Z', '2024-09-01T08:10:35.917Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('0e9a5bca-2473-4466-b882-663b4ec04603', '@Luella.Bernhard-Lebsack', 'Luella Bernhard-Lebsack', 'Fort Sammiehaven, Micronesia', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Luella.Bernhard-Lebsack', 'blame advocate', 'https://every-elbow.info/', 'shadowed', 9, 865, 455, 394, '2024-07-07T20:30:10.457Z', '2024-09-01T03:04:31.799Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('ac8e8a50-bd4e-4053-8772-d2826683c29d', '@Taylor50', 'Taylor Denesik', 'Racine, Russian Federation', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Taylor50', 'patriot, teacher, artist', 'https://jubilant-babushka.org', 'fading', 8, 11, 358, 89, '2024-02-04T22:41:28.344Z', '2024-09-01T11:48:58.106Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('d86d6638-e3f2-4c18-a660-fdd7bcd48dee', '@Zaria_Quitzon', 'Zaria Quitzon', 'Donaldburgh, United Arab Emirates', 'https://anime.kirwako.com/api/avatar?name=%40Zaria_Quitzon', 'bath advocate, veteran 🇧🇪', 'https://careful-bower.biz/', 'shadowed', 5, 762, 482, 158, '2024-07-19T19:37:38.626Z', '2024-08-31T23:28:35.697Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('56aa7ec4-2b39-48bf-a014-635cf7945fc4', '@Emile.Fritsch', 'Emile Fritsch', 'Plymouth, Jordan', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Emile.Fritsch', 'teacher, dreamer, grad', 'https://spotted-cranberry.com', 'ethereal', 6, 220, 178, 162, '2023-10-11T15:41:42.255Z', '2024-09-01T00:03:01.720Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('e96c56b0-fa4a-443c-aaf3-9f95bf409f8b', '@Ottis_Schroeder61', 'Ottis Schroeder', 'Rosettaport, Montenegro', 'https://anime.kirwako.com/api/avatar?name=%40Ottis_Schroeder61', 'leader', 'https://slim-teen.biz', 'radiant', 6, 186, 18, 57, '2023-09-29T14:45:19.270Z', '2024-09-01T09:52:53.145Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('50ab8370-c757-42a7-881c-b44b3f79cc01', '@Kaylee_Mraz84', 'Kaylee Mraz', 'New Assunta, Italy', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Kaylee_Mraz84', 'educator, model, engineer', 'https://soggy-mother.com', 'radiant', 10, 772, 46, 411, '2024-08-09T09:10:41.670Z', '2024-09-01T07:06:51.019Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('cb28b381-e3c1-4155-9e05-9339e5874184', '@Muriel_Ritchie68', 'Muriel Ritchie', 'Kayliport, Maldives', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Muriel_Ritchie68', 'nerd, philosopher, leader 💋', 'https://sugary-cassock.org', 'shadowed', 8, 272, 105, 150, '2024-01-01T20:23:08.116Z', '2024-08-31T23:54:08.222Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('9ae90144-555a-4de6-9262-63a7f62cba92', '@Stefanie11', 'Stefanie Swift', 'East Samantha, Mauritius', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Stefanie11', 'writer', 'https://zealous-crocus.net/', 'radiant', 10, 153, 499, 331, '2024-04-01T17:02:43.032Z', '2024-09-01T07:25:46.598Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('11a25c43-e483-4ae5-9839-841a85e9fa4d', '@Curtis_Reichert53', 'Curtis Reichert', 'North Scot, Equatorial Guinea', 'https://anime.kirwako.com/api/avatar?name=%40Curtis_Reichert53', 'crewmate lover  🥄', 'https://potable-cattle.info', 'ethereal', 7, 484, 138, 36, '2024-05-07T08:54:29.595Z', '2024-09-01T09:10:58.278Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('dc71415e-330e-455d-85ff-ec432ad52862', '@Stephany_Koch', 'Stephany Koch', 'Levittown, Gabon', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Stephany_Koch', 'hub enthusiast, musician 🐞', 'https://full-poor.com/', 'ethereal', 4, 930, 402, 51, '2023-09-04T22:32:25.173Z', '2024-09-01T14:59:35.409Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('f39acdac-6cef-44f1-a0a2-7d6601463bf4', '@Garland.Brakus', 'Garland Brakus', 'San Francisco, American Samoa', 'https://anime.kirwako.com/api/avatar?name=%40Garland.Brakus', 'business owner', 'https://deadly-insert.org', 'shadowed', 1, 83, 472, 201, '2024-03-28T19:48:37.472Z', '2024-09-01T03:56:57.762Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('8044dce0-6679-426f-9335-b5c002fef209', '@Letha_OHara2', 'Letha O''Hara', 'Lake Jewellfurt, Switzerland', 'https://anime.kirwako.com/api/avatar?name=%40Letha_OHara2', 'slang junkie  🇨🇾', 'https://excited-top.net/', 'fading', 9, 619, 236, 454, '2024-03-16T07:07:33.774Z', '2024-09-01T06:00:33.509Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('14973eb6-b77c-49b0-bd35-9bbb307bb52b', '@Lester_Russel', 'Lester Russel', 'West Daphney, Sao Tome and Principe', 'https://anime.kirwako.com/api/avatar?name=%40Lester_Russel', 'gymnast supporter  🎲', 'https://sweaty-creation.org/', 'radiant', 2, 590, 305, 496, '2023-11-29T07:58:43.139Z', '2024-09-01T09:50:00.927Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('4e502c29-e850-483f-89d9-9d422bc359c2', '@Thaddeus_Langosh', 'Thaddeus Langosh', 'West Ethelyn, Philippines', 'https://anime.kirwako.com/api/avatar?name=%40Thaddeus_Langosh', 'geek', 'https://absolute-influence.biz', 'shadowed', 4, 24, 102, 37, '2023-12-25T19:41:37.733Z', '2024-09-01T02:56:02.124Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('75f18662-bf58-4a4e-bf73-b05b6677cd3e', '@Lucious93', 'Lucious Hammes', 'East Stacy, Chile', 'https://anime.kirwako.com/api/avatar?name=%40Lucious93', 'garlic fan, filmmaker', 'https://embellished-kayak.net', 'ethereal', 3, 472, 24, 424, '2024-01-15T01:36:47.419Z', '2024-09-01T13:51:44.485Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('9f0397a9-c3fe-45bc-9a55-a2387e4bbdbe', '@Aurelia.Erdman4', 'Aurelia Erdman', 'Reggiebury, Sudan', 'https://anime.kirwako.com/api/avatar?name=%40Aurelia.Erdman4', 'coach, student', 'https://internal-blessing.info/', 'ethereal', 7, 83, 485, 283, '2024-02-05T20:47:08.834Z', '2024-09-01T10:14:35.371Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('d7fcceab-cf1c-4ac8-804e-842c76f1c606', '@Adrianna.Homenick74', 'Adrianna Homenick', 'South Darlene, Switzerland', 'https://anime.kirwako.com/api/avatar?name=%40Adrianna.Homenick74', 'melatonin advocate, foodie 🎲', 'https://rectangular-technician.info', 'shadowed', 1, 414, 361, 101, '2024-04-18T23:31:35.349Z', '2024-09-01T09:23:23.508Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', '@Kenya15', 'Kenya Hayes', 'Luettgenville, Ireland', 'https://anime.kirwako.com/api/avatar?name=%40Kenya15', 'person, engineer, photographer 🚳', 'https://deep-quill.biz', 'common', 2, 464, 128, 460, '2024-02-16T23:01:17.024Z', '2024-08-31T23:45:20.128Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('11bf0c4f-04e0-4327-96ef-44c3cd03028f', '@Ramona16', 'Ramona Hilpert', 'North Gussie, South Sudan', 'https://anime.kirwako.com/api/avatar?name=%40Ramona16', 'chalice fan, model', 'https://brave-concern.net', 'common', 3, 483, 405, 333, '2023-12-17T07:48:17.958Z', '2024-09-01T15:57:05.853Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('2c37c85f-db8f-4f9a-8e63-ab8cde11dc6e', '@Zack.Hilll-Hoppe75', 'Zack Hilll-Hoppe', 'Lee''s Summit, Saint Vincent and the Grenadines', 'https://anime.kirwako.com/api/avatar?name=%40Zack.Hilll-Hoppe75', 'winter fan', 'https://muted-seed.net/', 'common', 8, 530, 249, 67, '2024-06-09T01:19:53.106Z', '2024-09-01T07:23:53.046Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('a26fac26-d1c6-4223-863a-f5e6ca9d6d2c', '@Flossie_Sauer25', 'Flossie Sauer', 'Rodriguezstead, Turkey', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Flossie_Sauer25', 'person, streamer', 'https://stylish-discharge.name', 'shadowed', 6, 247, 329, 469, '2023-09-27T14:27:01.223Z', '2024-09-01T08:21:36.690Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('37286d2d-a250-4058-afb1-7b7146d36107', '@Rodger_Kessler85', 'Rodger Kessler', 'Fort Karlie, Italy', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Rodger_Kessler85', 'business owner, foodie, veteran 🇰🇲', 'https://trained-kneejerk.org', 'ethereal', 3, 374, 88, 405, '2023-10-17T12:03:41.579Z', '2024-08-31T21:52:20.058Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('bedfc261-99bf-4f47-b9a4-2491a1147734', '@Jade_Parker11', 'Jade Parker', 'West Graciela, Puerto Rico', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Jade_Parker11', 'heroine junkie  🪰', 'https://granular-fund.net/', 'ethereal', 1, 638, 446, 170, '2024-07-23T20:04:17.392Z', '2024-08-31T21:08:12.402Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('6704b2a8-cc47-48df-b0b9-1c82d9031bbd', '@Delilah33', 'Delilah Treutel', 'Trantowstad, Malta', 'https://anime.kirwako.com/api/avatar?name=%40Delilah33', 'uplift advocate  🍃', 'https://unnatural-swivel.biz', 'fading', 4, 135, 345, 38, '2023-10-16T13:38:23.176Z', '2024-08-31T21:47:13.175Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('70a57abc-bf59-4ac8-99e7-db839193fa1e', '@Frederic.Russel', 'Frederic Russel', 'Baileyberg, Faroe Islands', 'https://anime.kirwako.com/api/avatar?name=%40Frederic.Russel', 'music junkie, philosopher', 'https://female-forebear.biz/', 'shadowed', 6, 740, 8, 339, '2024-07-23T06:30:05.041Z', '2024-08-31T22:26:49.313Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('d8c1b5e4-f94e-4b05-a8c7-17d86e2ad315', '@Joshuah.Mohr', 'Joshuah Mohr', 'Kendale Lakes, Comoros', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Joshuah.Mohr', 'patriot, traveler, photographer 📐', 'https://modest-bump.biz', 'shadowed', 10, 8, 344, 216, '2024-05-25T09:32:27.400Z', '2024-09-01T08:30:36.787Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('aba678d1-e6c4-48f9-939a-e58264ed0230', '@Rosalyn.Harris', 'Rosalyn Harris', 'Elmhurst, Seychelles', 'https://anime.kirwako.com/api/avatar?name=%40Rosalyn.Harris', 'developer, gamer, author', 'https://sophisticated-giggle.name', 'shadowed', 1, 891, 61, 126, '2023-10-06T13:56:19.635Z', '2024-08-31T18:24:05.992Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('d665c01e-d750-4046-9428-8264715da6c0', '@Rubie.Pagac27', 'Rubie Pagac', 'Zitacester, Kazakhstan', 'https://anime.kirwako.com/api/avatar?name=%40Rubie.Pagac27', 'business owner, coach', 'https://fortunate-compulsion.org/', 'ethereal', 5, 360, 112, 91, '2024-01-11T12:01:38.186Z', '2024-09-01T00:20:30.268Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('50e872f7-1238-40c4-acd8-d4f082ffb4f0', '@Helga36', 'Helga McLaughlin', 'Kennewick, Guinea', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Helga36', 'remote advocate, nerd', 'https://gloomy-lighting.biz', 'radiant', 10, 721, 251, 300, '2024-08-19T12:19:58.119Z', '2024-08-31T17:37:12.097Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('e345315e-bb59-4787-b0c9-29f69379c00e', '@Robin.Aufderhar49', 'Robin Aufderhar', 'Huntsville, Cambodia', 'https://anime.kirwako.com/api/avatar?name=%40Robin.Aufderhar49', 'engineer', 'https://reasonable-pressurization.info', 'shadowed', 8, 137, 223, 91, '2023-10-06T05:30:48.139Z', '2024-09-01T00:41:55.673Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('c821b7d3-8dd2-44ca-ad17-99c71cbd4d9c', '@Billy.Skiles', 'Billy Skiles', 'Manuelaton, Sao Tome and Principe', 'https://anime.kirwako.com/api/avatar?name=%40Billy.Skiles', 'intervention advocate  🌴', 'https://verifiable-candelabra.net/', 'ethereal', 10, 135, 466, 260, '2023-12-06T12:48:56.471Z', '2024-09-01T16:21:49.536Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('3620f183-cb4d-4537-b5b3-9adb10e096c7', '@Travis_McLaughlin', 'Travis McLaughlin', 'San Clemente, Kyrgyz Republic', 'https://anime.kirwako.com/api/avatar?name=%40Travis_McLaughlin', 'scientist', 'https://jealous-lifestyle.org/', 'radiant', 1, 483, 261, 469, '2023-09-29T02:40:15.216Z', '2024-09-01T09:45:08.701Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('b6283786-5ef5-4970-8e3b-2d341148e67a', '@Berniece.Lakin56', 'Berniece Lakin', 'Peggieside, Cape Verde', 'https://anime.kirwako.com/api/avatar?name=%40Berniece.Lakin56', 'model, environmentalist', 'https://mindless-vernacular.biz/', 'ethereal', 8, 395, 291, 466, '2024-01-25T06:22:25.220Z', '2024-09-01T09:55:18.376Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('7639bb07-14c8-49b8-b815-bec946340f63', '@Virginie_Stoltenberg65', 'Virginie Stoltenberg', 'Bechtelarville, Grenada', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Virginie_Stoltenberg65', 'debt junkie, activist', 'https://vast-brochure.biz/', 'ethereal', 9, 841, 293, 76, '2024-01-27T09:45:23.692Z', '2024-09-01T01:16:24.435Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('2fe7ec0d-de09-40de-90df-4a5a865e7457', '@Jaime.Wuckert29', 'Jaime Wuckert', 'Port Cedrickview, Isle of Man', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Jaime.Wuckert29', 'musician', 'https://low-lye.info', 'fading', 10, 840, 379, 375, '2024-08-12T18:58:46.550Z', '2024-08-31T20:28:11.153Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('996d2b57-51d8-4f34-b44b-12cae5d7b816', '@Isaias.Witting', 'Isaias Witting', 'East Newton, American Samoa', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Isaias.Witting', 'youngster junkie, traveler 💮', 'https://fat-speakerphone.com/', 'fading', 6, 833, 331, 204, '2023-11-11T11:04:52.498Z', '2024-09-01T14:39:55.526Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('a6a05382-5b1a-4a8f-a851-119ccaf77f98', '@Elijah_Reynolds74', 'Elijah Reynolds', 'Monroeburgh, Palestine', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Elijah_Reynolds74', 'hobbit lover, activist 🥋', 'https://mixed-jogging.org', 'shadowed', 10, 129, 64, 443, '2024-01-27T21:03:34.502Z', '2024-08-31T20:17:57.072Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('6997eef9-2c6e-4792-90d0-68b66278121a', '@Guadalupe_Altenwerth25', 'Guadalupe Altenwerth', 'Grahamview, Mali', 'https://anime.kirwako.com/api/avatar?name=%40Guadalupe_Altenwerth25', 'line devotee, public speaker', 'https://primary-temper.name/', 'common', 5, 939, 484, 412, '2023-10-31T10:14:27.205Z', '2024-09-01T14:14:36.616Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('818ffdc2-63a3-4c08-bd82-65b704eb3791', '@Roberto.Braun', 'Roberto Braun', 'East Brianastad, Guam', 'https://anime.kirwako.com/api/avatar?name=%40Roberto.Braun', 'photographer, singer, nerd 🤙🏿', 'https://woozy-chow.name/', 'ethereal', 8, 505, 199, 48, '2024-07-01T09:48:06.231Z', '2024-09-01T07:09:24.610Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('7d30f1e9-5998-4d54-b67f-aa8d7bd779e5', '@Kale.Daniel', 'Kale Daniel', 'Fadelburgh, Chad', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Kale.Daniel', 'friend, author', 'https://standard-awareness.info', 'ethereal', 8, 346, 427, 51, '2023-11-17T04:40:49.565Z', '2024-09-01T07:31:07.302Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('2715ef58-c273-4c9f-a24d-c70bac5f1b1c', '@Marshall74', 'Marshall Jacobi', 'Savannah, Vanuatu', 'https://anime.kirwako.com/api/avatar?name=%40Marshall74', 'shoes advocate', 'https://wealthy-alder.net', 'radiant', 2, 416, 252, 183, '2024-04-17T01:10:05.830Z', '2024-09-01T03:45:08.926Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('000cbabf-d423-4937-8272-a91097dae393', '@Alysson_Donnelly4', 'Alysson Donnelly', 'Pueblo, Israel', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Alysson_Donnelly4', 'student', 'https://dirty-possibility.com', 'radiant', 2, 69, 149, 336, '2023-12-02T23:52:49.534Z', '2024-09-01T07:40:12.117Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('6099e094-d434-4a62-85c7-50506e082577', '@Jannie_Aufderhar', 'Jannie Aufderhar', 'Deckowworth, Guam', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Jannie_Aufderhar', 'traveler, parent, inventor 🧀', 'https://fake-pony.org/', 'ethereal', 1, 961, 78, 494, '2024-07-04T04:22:18.286Z', '2024-08-31T17:20:55.947Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('0e98eb24-3c0a-44bd-9c6a-bc40e7b841b7', '@Clyde_Farrell', 'Clyde Farrell', 'New Trey, American Samoa', 'https://anime.kirwako.com/api/avatar?name=%40Clyde_Farrell', 'colon lover  🕕', 'https://confused-underground.biz/', 'shadowed', 3, 363, 69, 472, '2023-10-02T13:51:15.480Z', '2024-09-01T15:14:37.853Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('3cd2c8bf-8fd4-40ca-96e3-5e41dd52d8c7', '@Afton.Kessler81', 'Afton Kessler', 'East Kristopher, India', 'https://anime.kirwako.com/api/avatar?name=%40Afton.Kessler81', 'creator, business owner', 'https://all-present.net/', 'ethereal', 3, 540, 52, 362, '2023-12-24T08:42:13.846Z', '2024-09-01T05:34:14.214Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('6a96fd38-197e-47c7-8f88-e9d1451bb98a', '@Terrence.Halvorson50', 'Terrence Halvorson', 'Dandrefield, Macao', 'https://anime.kirwako.com/api/avatar?name=%40Terrence.Halvorson50', 'coach, filmmaker, developer', 'https://exotic-flip-flops.biz', 'ethereal', 4, 452, 344, 59, '2024-02-13T18:05:29.026Z', '2024-08-31T17:15:42.408Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('e4659d06-39b9-417a-a5c7-8c51522a48ea', '@Paolo_Borer', 'Paolo Borer', 'Nealburgh, Iceland', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Paolo_Borer', 'academics lover', 'https://colossal-reminder.name', 'radiant', 4, 265, 452, 287, '2024-01-27T05:59:27.567Z', '2024-09-01T08:05:37.932Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('a7058bc0-3700-4e70-a310-e1384942ca63', '@Cathryn55', 'Cathryn Rogahn', 'DuBuqueview, Nigeria', 'https://anime.kirwako.com/api/avatar?name=%40Cathryn55', 'philosopher', 'https://outgoing-tummy.name/', 'common', 1, 552, 47, 334, '2024-07-05T01:02:21.188Z', '2024-09-01T08:37:25.628Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('64af3593-2a87-4c5b-bc96-0f1f38bc7455', '@Savion72', 'Savion Fadel', 'Fort Emmiestead, Canada', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Savion72', 'bun devotee, gamer', 'https://gullible-fedora.name/', 'radiant', 7, 999, 192, 422, '2024-08-23T03:40:32.803Z', '2024-08-31T22:16:38.612Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('b2fa99af-d6ab-4f42-99c0-e42001c854a9', '@Caroline_Stroman', 'Caroline Stroman', 'Maggioburgh, Svalbard & Jan Mayen Islands', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Caroline_Stroman', 'blogger, leader, developer 🥬', 'https://bronze-waterbed.com', 'radiant', 7, 484, 323, 264, '2023-11-12T02:42:51.961Z', '2024-08-31T20:42:33.734Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('819f196b-997c-46ff-8964-96b64e69be09', '@Sadie_Swaniawski37', 'Sadie Swaniawski', 'Beahanfort, Lesotho', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Sadie_Swaniawski37', 'inventor, coach', 'https://bossy-spill.info', 'common', 3, 490, 76, 328, '2024-04-30T10:32:16.427Z', '2024-08-31T17:51:08.699Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('5f554356-f203-4cb4-820d-995d806f2469', '@Alia24', 'Alia Schuppe', 'Watsonville, Niue', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Alia24', 'dreamer, educator, parent ◾', 'https://quirky-contrary.biz/', 'fading', 7, 690, 426, 117, '2023-11-15T23:24:32.128Z', '2024-08-31T23:12:46.051Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('e4935ae6-f609-4044-aff4-3a5a6defd3d3', '@Kaley46', 'Kaley Ryan', 'Schroederland, Mongolia', 'https://anime.kirwako.com/api/avatar?name=%40Kaley46', 'environmentalist, leader', 'https://impassioned-sledge.net', 'common', 3, 624, 377, 434, '2024-03-19T05:07:34.209Z', '2024-08-31T19:20:50.182Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('ff96307c-d5bb-4479-b43d-c400270d6f67', '@Winona.Ebert99', 'Winona Ebert', 'New Makenzie, Brunei Darussalam', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Winona.Ebert99', 'musician', 'https://hungry-underpass.net/', 'shadowed', 9, 534, 239, 51, '2023-12-13T16:09:11.438Z', '2024-08-31T18:46:24.604Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('133ffc07-3119-4c09-a793-f9f2bff49b64', '@Grayson55', 'Grayson Langworth', 'East Anne, Pitcairn Islands', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Grayson55', 'musician, artist, singer ♒', 'https://prime-gas.net/', 'radiant', 7, 215, 470, 476, '2024-04-16T06:57:10.732Z', '2024-09-01T10:52:53.982Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('442d962c-abed-402d-8ee6-14be6ebd74bd', '@Emilia.Koelpin', 'Emilia Koelpin', 'Aloha, Lithuania', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Emilia.Koelpin', 'owner devotee, student 🍝', 'https://clueless-variable.name/', 'ethereal', 9, 252, 262, 427, '2023-11-01T12:10:40.459Z', '2024-09-01T05:35:34.485Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('38812fa2-1f56-447a-b3a7-51cda4e6c075', '@Raymundo.Shanahan', 'Raymundo Shanahan', 'Fort Rosellatown, Poland', 'https://anime.kirwako.com/api/avatar?name=%40Raymundo.Shanahan', 'student, person', 'https://steel-business.info', 'radiant', 10, 635, 241, 86, '2023-09-11T19:31:38.622Z', '2024-08-31T18:18:04.230Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('d66cb4b1-61ab-44b9-b431-2eaa04542320', '@Laurianne.Schaden33', 'Laurianne Schaden', 'South Lonnie, Fiji', 'https://anime.kirwako.com/api/avatar?name=%40Laurianne.Schaden33', 'friend, public speaker, parent', 'https://creamy-habitat.info', 'ethereal', 10, 473, 232, 94, '2024-08-11T05:23:56.555Z', '2024-08-31T17:16:07.644Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('ae2cb809-9444-4bfa-8d82-e0adb2b4ee18', '@Cierra_Wilkinson', 'Cierra Wilkinson', 'Catonsville, Uganda', 'https://anime.kirwako.com/api/avatar?name=%40Cierra_Wilkinson', 'entrepreneur, musician, scientist', 'https://relieved-art.info/', 'common', 3, 340, 228, 44, '2024-06-15T05:50:31.030Z', '2024-08-31T21:05:10.350Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('3c967916-a4d0-4c24-9712-c96d4f45ad47', '@Evert_Feest49', 'Evert Feest', 'Garrisonbury, Italy', 'https://anime.kirwako.com/api/avatar?name=%40Evert_Feest49', 'octopus advocate', 'https://female-playroom.net/', 'shadowed', 10, 53, 125, 108, '2023-12-11T02:27:54.432Z', '2024-08-31T22:09:37.404Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('5ad6bc14-36d1-4e93-b712-806f58dfe4c1', '@Angus73', 'Angus Mertz', 'Martinshire, Saint Helena', 'https://anime.kirwako.com/api/avatar?name=%40Angus73', 'coach, foodie, geek', 'https://grumpy-vision.name', 'fading', 2, 539, 50, 35, '2023-10-24T00:32:10.966Z', '2024-09-01T09:09:43.282Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', '@Tiffany73', 'Tiffany Simonis', 'Thurmanmouth, Brazil', 'https://anime.kirwako.com/api/avatar?name=%40Tiffany73', 'restriction junkie', 'https://tangible-koala.biz', 'fading', 1, 378, 146, 192, '2024-04-27T15:04:35.908Z', '2024-09-01T13:16:07.214Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('90968472-3852-4978-8112-557f11ec7e4d', '@Erling64', 'Erling Cruickshank', 'Lexington-Fayette, Trinidad and Tobago', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Erling64', 'balalaika supporter, blogger', 'https://triangular-toothbrush.biz', 'ethereal', 7, 839, 487, 353, '2024-06-18T09:38:48.726Z', '2024-09-01T14:39:57.243Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('cf4d3686-5356-418f-b16f-0a265a40080d', '@Jermain.Ratke', 'Jermain Ratke', 'Vancouver, Bouvet Island', 'https://anime.kirwako.com/api/avatar?name=%40Jermain.Ratke', 'activist', 'https://barren-daylight.com/', 'shadowed', 3, 196, 178, 21, '2024-05-13T12:21:06.170Z', '2024-08-31T23:38:09.628Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('732c8fa1-2036-4e4b-a210-411bbce9c9a7', '@Micaela_Kirlin36', 'Micaela Kirlin', 'North Lavonfurt, Jamaica', 'https://anime.kirwako.com/api/avatar?name=%40Micaela_Kirlin36', 'filmmaker, geek, photographer', 'https://gifted-mallet.name', 'common', 1, 718, 346, 342, '2023-11-30T19:00:05.039Z', '2024-09-01T05:42:51.312Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('d72ad16a-5ded-487c-877d-3851491634ac', '@Kylee64', 'Kylee Medhurst', 'New Daniellafurt, Faroe Islands', 'https://anime.kirwako.com/api/avatar?name=%40Kylee64', 'streamer, philosopher, film lover 🔎', 'https://optimistic-date.com/', 'common', 2, 597, 443, 286, '2024-01-08T16:40:08.988Z', '2024-09-01T03:41:45.363Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('67b465fa-495f-48ff-bde7-c6879d26a840', '@Luciano84', 'Luciano Kovacek', 'West Neha, North Macedonia', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Luciano84', 'ton supporter  🦦', 'https://animated-document.biz/', 'common', 1, 800, 147, 53, '2023-11-07T15:14:08.615Z', '2024-08-31T19:48:33.534Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('f73af756-45a5-416d-963b-809bb43b4c02', '@Jaylen.Collier49', 'Jaylen Collier', 'Ellisworth, India', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Jaylen.Collier49', 'upgrade lover', 'https://other-lynx.biz', 'common', 10, 414, 118, 168, '2024-03-20T01:01:46.226Z', '2024-08-31T21:15:20.386Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('a478d17a-1b5e-4602-9520-15121bdb0317', '@Maudie_Olson', 'Maudie Olson', 'Kaylahfurt, Andorra', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Maudie_Olson', 'candidacy enthusiast, educator', 'https://caring-destination.info', 'shadowed', 3, 471, 289, 439, '2024-07-03T18:48:06.314Z', '2024-09-01T01:09:08.091Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('46fa3a47-9d5f-45b8-bc28-3c948029848e', '@Mario.Bogan-Gislason23', 'Mario Bogan-Gislason', 'New Ardenstead, Nauru', 'https://anime.kirwako.com/api/avatar?name=%40Mario.Bogan-Gislason23', 'model, friend, film lover', 'https://insubstantial-sombrero.org', 'radiant', 4, 276, 64, 119, '2024-07-27T02:38:17.118Z', '2024-09-01T09:41:28.710Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('92f02a3f-de88-4f6b-b93f-fadb1366255b', '@Donny68', 'Donny Cartwright', 'Ralphworth, Niue', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Donny68', 'valance supporter, teacher', 'https://square-drum.name', 'shadowed', 10, 308, 369, 263, '2023-11-16T14:58:32.150Z', '2024-09-01T12:25:11.365Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('1263c5ad-7edc-46dd-8113-aeb222328767', '@Isadore_Medhurst66', 'Isadore Medhurst', 'Jaimebury, Bolivia', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Isadore_Medhurst66', 'closing junkie  🧒🏿', 'https://submissive-defense.info/', 'common', 6, 773, 140, 447, '2024-06-22T19:24:04.447Z', '2024-09-01T03:29:28.943Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('91c606eb-c2a4-44e2-9ee2-8ae25c9b0485', '@Vernice28', 'Vernice Reichel', 'Waterloo, Slovenia', 'https://anime.kirwako.com/api/avatar?name=%40Vernice28', 'shutdown advocate, scientist 👃🏻', 'https://infinite-devil.info', 'fading', 7, 926, 294, 261, '2024-06-03T02:08:54.160Z', '2024-08-31T21:24:10.270Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('e39947d1-976b-4436-8b90-555ddc6e8891', '@Clementine83', 'Clementine Tromp', 'Ebertburgh, Comoros', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Clementine83', 'gator devotee', 'https://amusing-pince-nez.net', 'common', 1, 984, 279, 373, '2023-11-11T05:03:34.914Z', '2024-08-31T23:45:06.162Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('26f198c8-ed62-4fc7-81c6-b191663aa8da', '@Carolanne.Buckridge64', 'Carolanne Buckridge', 'Fort Zack, Egypt', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Carolanne.Buckridge64', 'ramie advocate, entrepreneur', 'https://tame-sting.info/', 'common', 7, 716, 433, 293, '2024-06-25T13:19:16.732Z', '2024-08-31T17:09:17.059Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('26680a6c-6827-4a0e-a8ce-c67f09bf7cbc', '@Caroline_Dickinson22', 'Caroline Dickinson', 'North Thalialand, Peru', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Caroline_Dickinson22', 'designer', 'https://awesome-coliseum.biz', 'radiant', 5, 779, 64, 111, '2024-04-30T20:49:43.879Z', '2024-09-01T05:31:27.201Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('24ac73f3-192e-424f-8d5c-dfade4d52883', '@Clint.Altenwerth79', 'Clint Altenwerth', 'Ornburgh, Democratic Republic of the Congo', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Clint.Altenwerth79', 'graft devotee, author 🪤', 'https://anchored-passage.net', 'fading', 3, 531, 8, 377, '2024-03-30T00:10:12.777Z', '2024-08-31T18:54:32.472Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('c576d48c-4c3a-418f-8fb7-23c1f488c536', '@Lois_Conroy', 'Lois Conroy', 'Port Jo, Iceland', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Lois_Conroy', 'student, film lover, person 🍻', 'https://pink-inn.biz', 'ethereal', 5, 486, 131, 86, '2024-04-01T18:25:14.723Z', '2024-09-01T12:01:48.491Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('94bb1874-8092-4286-8252-f2f0066d68bb', '@Triston_Littel', 'Triston Littel', 'Eliezerview, Virgin Islands, British', 'https://anime.kirwako.com/api/avatar?name=%40Triston_Littel', 'prow junkie, person 📿', 'https://droopy-schooner.com', 'fading', 10, 383, 11, 376, '2023-12-21T09:22:38.069Z', '2024-08-31T17:13:46.970Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('e18f1135-137c-4966-9883-881bd7cc3c0a', '@Cayla_Koepp2', 'Cayla Koepp', 'North Leatha, Svalbard & Jan Mayen Islands', 'https://anime.kirwako.com/api/avatar?name=%40Cayla_Koepp2', 'scientist', 'https://shiny-toothbrush.biz/', 'ethereal', 7, 581, 403, 57, '2023-09-24T19:47:13.800Z', '2024-09-01T11:59:02.617Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('c369cecb-905f-4c93-8a7c-6ebc4d938f51', '@Dorian_Trantow', 'Dorian Trantow', 'New Carlosshire, Palestine', 'https://anime.kirwako.com/api/avatar?name=%40Dorian_Trantow', 'cartridge enthusiast, artist 📲', 'https://present-administrator.com', 'fading', 8, 87, 160, 177, '2024-03-28T12:11:53.583Z', '2024-09-01T01:28:51.605Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('4e247196-9778-410b-a106-3295e7a8c223', '@Trystan.Champlin', 'Trystan Champlin', 'Wilmington, Democratic People''s Republic of Korea', 'https://anime.kirwako.com/api/avatar?name=%40Trystan.Champlin', 'author', 'https://thirsty-measure.name', 'common', 6, 918, 356, 415, '2024-05-05T17:26:43.333Z', '2024-08-31T23:42:52.807Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('8fe847fa-0a60-4d29-9920-570cec52bae9', '@Lucienne.Raynor99', 'Lucienne Raynor', 'Lake Jolie, Australia', 'https://anime.kirwako.com/api/avatar?name=%40Lucienne.Raynor99', 'ground devotee  ♠️', 'https://long-term-union.name', 'radiant', 9, 21, 103, 310, '2024-01-12T07:32:02.350Z', '2024-08-31T19:51:15.109Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('ee145b69-3acc-4d39-9912-73e66ab99f68', '@Ada40', 'Ada Sporer', 'Darwinfurt, Mayotte', 'https://anime.kirwako.com/api/avatar?name=%40Ada40', 'inventor, designer', 'https://juvenile-gunpowder.name', 'radiant', 2, 632, 28, 77, '2024-01-25T01:58:23.273Z', '2024-08-31T22:26:11.434Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('1b94f1eb-1690-41ab-afa9-4423f9a89a83', '@Glen89', 'Glen Yost', 'Shanonburgh, Bermuda', 'https://anime.kirwako.com/api/avatar?name=%40Glen89', 'oval devotee  🃏', 'https://cheery-macaw.biz/', 'fading', 2, 294, 52, 109, '2024-07-02T15:28:19.057Z', '2024-09-01T11:03:10.503Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('feea87a0-b84f-4c31-857d-371d26a75dac', '@Favian_Graham', 'Favian Graham', 'New Darenview, Argentina', 'https://anime.kirwako.com/api/avatar?name=%40Favian_Graham', 'patriot', 'https://white-nuke.name', 'ethereal', 3, 393, 458, 360, '2024-07-31T12:48:01.886Z', '2024-09-01T03:11:49.765Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('05036186-cbf2-4ea7-b446-dc14447c88f1', '@Liliane45', 'Liliane Will', 'Lehigh Acres, Trinidad and Tobago', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Liliane45', 'founder, author', 'https://passionate-synergy.info/', 'ethereal', 2, 452, 47, 239, '2024-03-11T09:27:40.944Z', '2024-09-01T03:17:41.100Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('307d9772-de85-4b2c-96c4-ba6731df86b8', '@Ruben.Kihn9', 'Ruben Kihn', 'Reynoldsville, Germany', 'https://anime.kirwako.com/api/avatar?name=%40Ruben.Kihn9', 'nerd', 'https://alert-agent.net', 'shadowed', 7, 150, 234, 245, '2023-09-22T17:56:35.185Z', '2024-08-31T22:03:35.644Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('232d534c-9bd4-44bf-849e-0940ff0d8f3e', '@Amira_Ortiz18', 'Amira Ortiz', 'New Dereck, Angola', 'https://api.dicebear.com/9.x/thumbs/svg?seed=%40Amira_Ortiz18', 'pencil fan, developer', 'https://low-reserve.com/', 'radiant', 5, 836, 60, 135, '2024-08-22T18:43:01.804Z', '2024-08-31T20:16:09.387Z', '{}'::jsonb);

insert into PUBLIC.users(id, username, display_name, world_location, avatar_url, bio, website, aura_tier, aura_level, aura_points, followers_count, following_count, created_at, updated_at, privacy_settings)
	values ('4fefac21-ad9e-4ebe-94d5-dd85579ba1b8', '@Darrick59', 'Darrick Klocko', 'Reichertport, Cambodia', 'https://anime.kirwako.com/api/avatar?name=%40Darrick59', 'friend, veteran', 'https://artistic-yahoo.biz/', 'common', 5, 853, 392, 10, '2023-10-01T19:30:52.650Z', '2024-09-01T06:55:24.924Z', '{}'::jsonb);

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ae2cb809-9444-4bfa-8d82-e0adb2b4ee18', '9f0397a9-c3fe-45bc-9a55-a2387e4bbdbe', '2024-08-19T18:03:00.605Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('56aa7ec4-2b39-48bf-a014-635cf7945fc4', 'd86d6638-e3f2-4c18-a660-fdd7bcd48dee', '2024-08-28T08:05:51.272Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2715ef58-c273-4c9f-a24d-c70bac5f1b1c', 'e4935ae6-f609-4044-aff4-3a5a6defd3d3', '2024-08-30T05:15:59.707Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('a478d17a-1b5e-4602-9520-15121bdb0317', 'dc71415e-330e-455d-85ff-ec432ad52862', '2024-08-25T05:48:49.229Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('f77c87aa-12b5-464a-8629-b607776f75f0', '30f64f29-7abd-42ad-a610-92f2b64e5d5e', '2024-08-11T10:16:12.986Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ee145b69-3acc-4d39-9912-73e66ab99f68', '6997eef9-2c6e-4792-90d0-68b66278121a', '2024-08-20T05:21:05.143Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e5ae947f-cd22-4c36-8410-17b88f2d4b54', '0e98eb24-3c0a-44bd-9c6a-bc40e7b841b7', '2024-08-04T16:15:15.518Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ee145b69-3acc-4d39-9912-73e66ab99f68', '14973eb6-b77c-49b0-bd35-9bbb307bb52b', '2024-08-22T06:49:18.659Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('1263c5ad-7edc-46dd-8113-aeb222328767', '2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', '2024-08-03T01:07:48.507Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('c821b7d3-8dd2-44ca-ad17-99c71cbd4d9c', 'a478d17a-1b5e-4602-9520-15121bdb0317', '2024-08-04T20:09:37.573Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('05036186-cbf2-4ea7-b446-dc14447c88f1', 'e1b52554-e67a-4488-95b8-e13faf830852', '2024-08-31T09:22:45.220Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2715ef58-c273-4c9f-a24d-c70bac5f1b1c', '50ab8370-c757-42a7-881c-b44b3f79cc01', '2024-08-12T07:11:17.460Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ab75d59a-650e-4768-a6fd-00272eaf98b2', '50ab8370-c757-42a7-881c-b44b3f79cc01', '2024-08-27T08:58:03.231Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('4e247196-9778-410b-a106-3295e7a8c223', '56aa7ec4-2b39-48bf-a014-635cf7945fc4', '2024-08-02T22:26:45.943Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('3c967916-a4d0-4c24-9712-c96d4f45ad47', '6099e094-d434-4a62-85c7-50506e082577', '2024-08-17T13:18:29.383Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('3c967916-a4d0-4c24-9712-c96d4f45ad47', 'a26fac26-d1c6-4223-863a-f5e6ca9d6d2c', '2024-08-30T13:43:39.213Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('1b94f1eb-1690-41ab-afa9-4423f9a89a83', '307d9772-de85-4b2c-96c4-ba6731df86b8', '2024-08-10T18:31:42.409Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('c062042f-6446-4376-b543-d64d70eabc0d', 'feea87a0-b84f-4c31-857d-371d26a75dac', '2024-08-25T23:59:18.977Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e5ae947f-cd22-4c36-8410-17b88f2d4b54', '11bf0c4f-04e0-4327-96ef-44c3cd03028f', '2024-08-19T18:25:39.274Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('4e502c29-e850-483f-89d9-9d422bc359c2', '7e3e93a1-32cb-4931-a3df-f7bc90abd991', '2024-08-17T01:14:57.742Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('56aa7ec4-2b39-48bf-a014-635cf7945fc4', 'e4659d06-39b9-417a-a5c7-8c51522a48ea', '2024-08-16T07:19:26.263Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('05036186-cbf2-4ea7-b446-dc14447c88f1', '30f64f29-7abd-42ad-a610-92f2b64e5d5e', '2024-08-05T12:19:38.039Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('05036186-cbf2-4ea7-b446-dc14447c88f1', '6704b2a8-cc47-48df-b0b9-1c82d9031bbd', '2024-08-10T12:49:59.550Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', 'c062042f-6446-4376-b543-d64d70eabc0d', '2024-08-29T00:53:11.658Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d72ad16a-5ded-487c-877d-3851491634ac', '56aa7ec4-2b39-48bf-a014-635cf7945fc4', '2024-08-06T09:37:05.468Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('8044dce0-6679-426f-9335-b5c002fef209', '8fe847fa-0a60-4d29-9920-570cec52bae9', '2024-08-07T09:06:30.072Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('819f196b-997c-46ff-8964-96b64e69be09', '6704b2a8-cc47-48df-b0b9-1c82d9031bbd', '2024-08-31T15:36:23.204Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('26680a6c-6827-4a0e-a8ce-c67f09bf7cbc', 'ab75d59a-650e-4768-a6fd-00272eaf98b2', '2024-08-18T15:43:34.632Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', 'e4935ae6-f609-4044-aff4-3a5a6defd3d3', '2024-08-15T02:00:45.427Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ee145b69-3acc-4d39-9912-73e66ab99f68', 'ab75d59a-650e-4768-a6fd-00272eaf98b2', '2024-08-04T08:25:49.320Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('50e872f7-1238-40c4-acd8-d4f082ffb4f0', '37286d2d-a250-4058-afb1-7b7146d36107', '2024-08-15T18:57:00.142Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('38812fa2-1f56-447a-b3a7-51cda4e6c075', '5fe704f1-a885-4d95-bab3-639503750f61', '2024-08-15T08:53:42.783Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('a6a05382-5b1a-4a8f-a851-119ccaf77f98', '996d2b57-51d8-4f34-b44b-12cae5d7b816', '2024-08-11T08:13:37.714Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('c062042f-6446-4376-b543-d64d70eabc0d', '4e502c29-e850-483f-89d9-9d422bc359c2', '2024-08-26T10:35:31.747Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('9f0397a9-c3fe-45bc-9a55-a2387e4bbdbe', 'e345315e-bb59-4787-b0c9-29f69379c00e', '2024-08-19T19:17:34.264Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('b6283786-5ef5-4970-8e3b-2d341148e67a', '894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', '2024-08-09T20:00:14.719Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('a6a05382-5b1a-4a8f-a851-119ccaf77f98', '4fefac21-ad9e-4ebe-94d5-dd85579ba1b8', '2024-08-18T12:37:43.984Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('8044dce0-6679-426f-9335-b5c002fef209', '133ffc07-3119-4c09-a793-f9f2bff49b64', '2024-08-11T20:15:26.868Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('7639bb07-14c8-49b8-b815-bec946340f63', 'e96c56b0-fa4a-443c-aaf3-9f95bf409f8b', '2024-08-22T12:36:49.213Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('11a25c43-e483-4ae5-9839-841a85e9fa4d', 'd7fcceab-cf1c-4ac8-804e-842c76f1c606', '2024-08-30T01:15:52.590Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e96c56b0-fa4a-443c-aaf3-9f95bf409f8b', '7639bb07-14c8-49b8-b815-bec946340f63', '2024-08-03T21:27:42.528Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('996d2b57-51d8-4f34-b44b-12cae5d7b816', '8fe847fa-0a60-4d29-9920-570cec52bae9', '2024-08-07T13:19:22.725Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('000cbabf-d423-4937-8272-a91097dae393', 'd8c1b5e4-f94e-4b05-a8c7-17d86e2ad315', '2024-08-28T00:57:48.793Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6099e094-d434-4a62-85c7-50506e082577', 'ae2cb809-9444-4bfa-8d82-e0adb2b4ee18', '2024-08-05T09:24:46.606Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('4e502c29-e850-483f-89d9-9d422bc359c2', 'e1b52554-e67a-4488-95b8-e13faf830852', '2024-08-31T03:39:06.860Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2c37c85f-db8f-4f9a-8e63-ab8cde11dc6e', '14973eb6-b77c-49b0-bd35-9bbb307bb52b', '2024-08-23T10:36:40.463Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('75f18662-bf58-4a4e-bf73-b05b6677cd3e', '64af3593-2a87-4c5b-bc96-0f1f38bc7455', '2024-08-02T19:58:29.414Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2715ef58-c273-4c9f-a24d-c70bac5f1b1c', 'c576d48c-4c3a-418f-8fb7-23c1f488c536', '2024-08-16T11:30:13.707Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e18f1135-137c-4966-9883-881bd7cc3c0a', '50ab8370-c757-42a7-881c-b44b3f79cc01', '2024-08-11T19:47:38.235Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('75f18662-bf58-4a4e-bf73-b05b6677cd3e', 'a7058bc0-3700-4e70-a310-e1384942ca63', '2024-08-20T00:22:43.266Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('5f554356-f203-4cb4-820d-995d806f2469', '50e872f7-1238-40c4-acd8-d4f082ffb4f0', '2024-08-22T06:48:18.639Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ae2cb809-9444-4bfa-8d82-e0adb2b4ee18', 'e18f1135-137c-4966-9883-881bd7cc3c0a', '2024-08-23T02:29:53.898Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('14973eb6-b77c-49b0-bd35-9bbb307bb52b', 'c576d48c-4c3a-418f-8fb7-23c1f488c536', '2024-08-11T16:22:36.082Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('307d9772-de85-4b2c-96c4-ba6731df86b8', 'dc71415e-330e-455d-85ff-ec432ad52862', '2024-08-23T07:16:54.317Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('46fa3a47-9d5f-45b8-bc28-3c948029848e', 'e96c56b0-fa4a-443c-aaf3-9f95bf409f8b', '2024-09-01T07:46:27.657Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e96c56b0-fa4a-443c-aaf3-9f95bf409f8b', '14973eb6-b77c-49b0-bd35-9bbb307bb52b', '2024-08-09T20:31:12.859Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('4e502c29-e850-483f-89d9-9d422bc359c2', 'bedfc261-99bf-4f47-b9a4-2491a1147734', '2024-08-24T11:30:23.640Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e1b52554-e67a-4488-95b8-e13faf830852', 'ae2cb809-9444-4bfa-8d82-e0adb2b4ee18', '2024-08-06T01:00:27.179Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('c369cecb-905f-4c93-8a7c-6ebc4d938f51', '26f198c8-ed62-4fc7-81c6-b191663aa8da', '2024-08-17T13:03:13.561Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('eeedb312-c02c-4480-b6e4-7a3145cbb44a', 'd7fcceab-cf1c-4ac8-804e-842c76f1c606', '2024-08-15T19:47:40.369Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('0e9a5bca-2473-4466-b882-663b4ec04603', '442d962c-abed-402d-8ee6-14be6ebd74bd', '2024-08-08T19:04:34.797Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('9f0397a9-c3fe-45bc-9a55-a2387e4bbdbe', 'e4935ae6-f609-4044-aff4-3a5a6defd3d3', '2024-08-18T19:32:53.789Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('11a25c43-e483-4ae5-9839-841a85e9fa4d', 'e96c56b0-fa4a-443c-aaf3-9f95bf409f8b', '2024-08-26T23:37:12.838Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('4fefac21-ad9e-4ebe-94d5-dd85579ba1b8', '732c8fa1-2036-4e4b-a210-411bbce9c9a7', '2024-08-27T20:49:52.363Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('f77c87aa-12b5-464a-8629-b607776f75f0', 'a7058bc0-3700-4e70-a310-e1384942ca63', '2024-08-22T17:22:16.563Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('eeedb312-c02c-4480-b6e4-7a3145cbb44a', '3cd2c8bf-8fd4-40ca-96e3-5e41dd52d8c7', '2024-08-23T04:51:56.671Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('30f64f29-7abd-42ad-a610-92f2b64e5d5e', 'd8c1b5e4-f94e-4b05-a8c7-17d86e2ad315', '2024-08-17T00:39:26.248Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6997eef9-2c6e-4792-90d0-68b66278121a', 'c369cecb-905f-4c93-8a7c-6ebc4d938f51', '2024-08-29T01:31:17.741Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ff96307c-d5bb-4479-b43d-c400270d6f67', 'e39947d1-976b-4436-8b90-555ddc6e8891', '2024-08-22T00:50:13.466Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', '232d534c-9bd4-44bf-849e-0940ff0d8f3e', '2024-08-30T13:49:32.244Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('50ab8370-c757-42a7-881c-b44b3f79cc01', '26f198c8-ed62-4fc7-81c6-b191663aa8da', '2024-09-01T01:16:41.836Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('50ab8370-c757-42a7-881c-b44b3f79cc01', '8be08817-fd8b-465f-a436-50e8a2816d62', '2024-08-23T16:13:00.341Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('3620f183-cb4d-4537-b5b3-9adb10e096c7', '92f02a3f-de88-4f6b-b93f-fadb1366255b', '2024-08-04T14:31:32.394Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', '94bb1874-8092-4286-8252-f2f0066d68bb', '2024-08-08T17:41:11.309Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('3620f183-cb4d-4537-b5b3-9adb10e096c7', 'e345315e-bb59-4787-b0c9-29f69379c00e', '2024-08-19T14:59:36.164Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('90968472-3852-4978-8112-557f11ec7e4d', '7d30f1e9-5998-4d54-b67f-aa8d7bd779e5', '2024-08-27T16:27:51.465Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('92f02a3f-de88-4f6b-b93f-fadb1366255b', '6704b2a8-cc47-48df-b0b9-1c82d9031bbd', '2024-08-04T15:21:11.750Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('cb28b381-e3c1-4155-9e05-9339e5874184', '26680a6c-6827-4a0e-a8ce-c67f09bf7cbc', '2024-08-13T08:41:33.881Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('4e247196-9778-410b-a106-3295e7a8c223', '1b94f1eb-1690-41ab-afa9-4423f9a89a83', '2024-08-27T00:31:52.632Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('c576d48c-4c3a-418f-8fb7-23c1f488c536', '0e9a5bca-2473-4466-b882-663b4ec04603', '2024-08-06T07:42:25.170Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('4e502c29-e850-483f-89d9-9d422bc359c2', '1b94f1eb-1690-41ab-afa9-4423f9a89a83', '2024-08-29T19:48:40.816Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('64af3593-2a87-4c5b-bc96-0f1f38bc7455', 'cb28b381-e3c1-4155-9e05-9339e5874184', '2024-08-29T18:11:54.763Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d86d6638-e3f2-4c18-a660-fdd7bcd48dee', 'd8c1b5e4-f94e-4b05-a8c7-17d86e2ad315', '2024-08-26T08:48:50.110Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6a96fd38-197e-47c7-8f88-e9d1451bb98a', '50e872f7-1238-40c4-acd8-d4f082ffb4f0', '2024-08-19T17:31:16.350Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('38812fa2-1f56-447a-b3a7-51cda4e6c075', '46fa3a47-9d5f-45b8-bc28-3c948029848e', '2024-08-26T13:16:03.730Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('3620f183-cb4d-4537-b5b3-9adb10e096c7', '05036186-cbf2-4ea7-b446-dc14447c88f1', '2024-08-06T15:26:45.853Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('8044dce0-6679-426f-9335-b5c002fef209', 'd8c1b5e4-f94e-4b05-a8c7-17d86e2ad315', '2024-08-28T03:47:13.394Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ab75d59a-650e-4768-a6fd-00272eaf98b2', 'ac8e8a50-bd4e-4053-8772-d2826683c29d', '2024-08-22T17:31:01.425Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d8c1b5e4-f94e-4b05-a8c7-17d86e2ad315', 'ff96307c-d5bb-4479-b43d-c400270d6f67', '2024-08-24T15:09:12.536Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('5f554356-f203-4cb4-820d-995d806f2469', '5ad6bc14-36d1-4e93-b712-806f58dfe4c1', '2024-08-04T13:55:32.686Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('8fe847fa-0a60-4d29-9920-570cec52bae9', '05036186-cbf2-4ea7-b446-dc14447c88f1', '2024-08-25T07:44:13.124Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2c37c85f-db8f-4f9a-8e63-ab8cde11dc6e', 'b6283786-5ef5-4970-8e3b-2d341148e67a', '2024-08-03T20:26:36.481Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('dc71415e-330e-455d-85ff-ec432ad52862', '0e98eb24-3c0a-44bd-9c6a-bc40e7b841b7', '2024-08-16T21:12:40.142Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('819f196b-997c-46ff-8964-96b64e69be09', 'd7fcceab-cf1c-4ac8-804e-842c76f1c606', '2024-08-14T18:16:42.492Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e345315e-bb59-4787-b0c9-29f69379c00e', '37286d2d-a250-4058-afb1-7b7146d36107', '2024-08-09T14:42:23.729Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2fe7ec0d-de09-40de-90df-4a5a865e7457', '7d30f1e9-5998-4d54-b67f-aa8d7bd779e5', '2024-08-10T09:55:26.132Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e18f1135-137c-4966-9883-881bd7cc3c0a', '26f198c8-ed62-4fc7-81c6-b191663aa8da', '2024-08-05T05:55:36.392Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2c37c85f-db8f-4f9a-8e63-ab8cde11dc6e', '1b94f1eb-1690-41ab-afa9-4423f9a89a83', '2024-08-15T18:00:05.649Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6099e094-d434-4a62-85c7-50506e082577', '67b465fa-495f-48ff-bde7-c6879d26a840', '2024-08-02T22:07:22.567Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('f73af756-45a5-416d-963b-809bb43b4c02', '30f64f29-7abd-42ad-a610-92f2b64e5d5e', '2024-08-14T18:36:29.357Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('92f02a3f-de88-4f6b-b93f-fadb1366255b', 'd72ad16a-5ded-487c-877d-3851491634ac', '2024-08-30T04:01:58.256Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('cb28b381-e3c1-4155-9e05-9339e5874184', '4e502c29-e850-483f-89d9-9d422bc359c2', '2024-08-08T21:29:51.244Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2715ef58-c273-4c9f-a24d-c70bac5f1b1c', 'a7058bc0-3700-4e70-a310-e1384942ca63', '2024-08-08T01:46:17.414Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e345315e-bb59-4787-b0c9-29f69379c00e', 'feea87a0-b84f-4c31-857d-371d26a75dac', '2024-08-31T19:25:54.639Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', '4e502c29-e850-483f-89d9-9d422bc359c2', '2024-08-07T22:53:27.459Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('4e502c29-e850-483f-89d9-9d422bc359c2', 'a26fac26-d1c6-4223-863a-f5e6ca9d6d2c', '2024-08-14T19:38:46.508Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('75f18662-bf58-4a4e-bf73-b05b6677cd3e', 'e4935ae6-f609-4044-aff4-3a5a6defd3d3', '2024-08-22T11:26:47.195Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('94bb1874-8092-4286-8252-f2f0066d68bb', 'cb28b381-e3c1-4155-9e05-9339e5874184', '2024-08-06T06:07:45.752Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('b2fa99af-d6ab-4f42-99c0-e42001c854a9', '64af3593-2a87-4c5b-bc96-0f1f38bc7455', '2024-08-20T09:23:58.647Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('c369cecb-905f-4c93-8a7c-6ebc4d938f51', 'e18f1135-137c-4966-9883-881bd7cc3c0a', '2024-08-29T04:23:09.190Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('b2fa99af-d6ab-4f42-99c0-e42001c854a9', '818ffdc2-63a3-4c08-bd82-65b704eb3791', '2024-08-17T09:00:14.359Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('30f64f29-7abd-42ad-a610-92f2b64e5d5e', '5ad6bc14-36d1-4e93-b712-806f58dfe4c1', '2024-08-06T19:01:11.620Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('11bf0c4f-04e0-4327-96ef-44c3cd03028f', '8fe847fa-0a60-4d29-9920-570cec52bae9', '2024-08-12T23:36:38.372Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('64af3593-2a87-4c5b-bc96-0f1f38bc7455', 'e1b52554-e67a-4488-95b8-e13faf830852', '2024-08-21T22:45:19.912Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d86d6638-e3f2-4c18-a660-fdd7bcd48dee', '7639bb07-14c8-49b8-b815-bec946340f63', '2024-08-30T21:59:13.052Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('56aa7ec4-2b39-48bf-a014-635cf7945fc4', 'a6a05382-5b1a-4a8f-a851-119ccaf77f98', '2024-08-23T20:28:37.155Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('91c606eb-c2a4-44e2-9ee2-8ae25c9b0485', '11bf0c4f-04e0-4327-96ef-44c3cd03028f', '2024-08-09T12:07:39.003Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('b2fa99af-d6ab-4f42-99c0-e42001c854a9', '2715ef58-c273-4c9f-a24d-c70bac5f1b1c', '2024-08-23T12:09:08.685Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('38812fa2-1f56-447a-b3a7-51cda4e6c075', '91c606eb-c2a4-44e2-9ee2-8ae25c9b0485', '2024-08-24T16:52:35.971Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('442d962c-abed-402d-8ee6-14be6ebd74bd', 'e4659d06-39b9-417a-a5c7-8c51522a48ea', '2024-08-09T03:06:54.693Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('000cbabf-d423-4937-8272-a91097dae393', 'd72ad16a-5ded-487c-877d-3851491634ac', '2024-08-12T09:13:30.675Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e345315e-bb59-4787-b0c9-29f69379c00e', 'b6283786-5ef5-4970-8e3b-2d341148e67a', '2024-08-30T10:41:47.581Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('9ae90144-555a-4de6-9262-63a7f62cba92', '307d9772-de85-4b2c-96c4-ba6731df86b8', '2024-08-05T05:46:52.050Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('cb28b381-e3c1-4155-9e05-9339e5874184', '819f196b-997c-46ff-8964-96b64e69be09', '2024-08-25T02:08:14.601Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('3620f183-cb4d-4537-b5b3-9adb10e096c7', 'b2fa99af-d6ab-4f42-99c0-e42001c854a9', '2024-08-27T17:33:52.420Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6704b2a8-cc47-48df-b0b9-1c82d9031bbd', '64af3593-2a87-4c5b-bc96-0f1f38bc7455', '2024-08-20T23:18:16.787Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('c369cecb-905f-4c93-8a7c-6ebc4d938f51', '92f02a3f-de88-4f6b-b93f-fadb1366255b', '2024-08-04T08:48:31.548Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e5ae947f-cd22-4c36-8410-17b88f2d4b54', '232d534c-9bd4-44bf-849e-0940ff0d8f3e', '2024-08-27T10:46:29.066Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('c821b7d3-8dd2-44ca-ad17-99c71cbd4d9c', '442d962c-abed-402d-8ee6-14be6ebd74bd', '2024-08-22T05:45:02.340Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('90968472-3852-4978-8112-557f11ec7e4d', '2c37c85f-db8f-4f9a-8e63-ab8cde11dc6e', '2024-08-30T20:42:34.065Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('64af3593-2a87-4c5b-bc96-0f1f38bc7455', '05036186-cbf2-4ea7-b446-dc14447c88f1', '2024-08-27T23:53:50.210Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('996d2b57-51d8-4f34-b44b-12cae5d7b816', '6997eef9-2c6e-4792-90d0-68b66278121a', '2024-08-23T10:44:50.750Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('aba678d1-e6c4-48f9-939a-e58264ed0230', 'ff96307c-d5bb-4479-b43d-c400270d6f67', '2024-08-20T22:53:06.454Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d7fcceab-cf1c-4ac8-804e-842c76f1c606', 'cf4d3686-5356-418f-b16f-0a265a40080d', '2024-08-10T12:13:08.856Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('9ae90144-555a-4de6-9262-63a7f62cba92', 'e4935ae6-f609-4044-aff4-3a5a6defd3d3', '2024-08-27T21:12:15.502Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('26f198c8-ed62-4fc7-81c6-b191663aa8da', 'a6a05382-5b1a-4a8f-a851-119ccaf77f98', '2024-08-18T23:18:56.670Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('67b465fa-495f-48ff-bde7-c6879d26a840', '2c37c85f-db8f-4f9a-8e63-ab8cde11dc6e', '2024-08-03T17:43:26.996Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e18f1135-137c-4966-9883-881bd7cc3c0a', 'd86d6638-e3f2-4c18-a660-fdd7bcd48dee', '2024-08-08T06:10:08.340Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('cb28b381-e3c1-4155-9e05-9339e5874184', '5f554356-f203-4cb4-820d-995d806f2469', '2024-08-23T19:42:36.547Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('91c606eb-c2a4-44e2-9ee2-8ae25c9b0485', '818ffdc2-63a3-4c08-bd82-65b704eb3791', '2024-08-24T17:50:15.319Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('dc71415e-330e-455d-85ff-ec432ad52862', '37286d2d-a250-4058-afb1-7b7146d36107', '2024-08-10T14:36:58.937Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ac8e8a50-bd4e-4053-8772-d2826683c29d', 'a6a05382-5b1a-4a8f-a851-119ccaf77f98', '2024-08-26T00:06:15.430Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('38812fa2-1f56-447a-b3a7-51cda4e6c075', 'ab75d59a-650e-4768-a6fd-00272eaf98b2', '2024-08-22T04:46:20.362Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('26680a6c-6827-4a0e-a8ce-c67f09bf7cbc', 'feea87a0-b84f-4c31-857d-371d26a75dac', '2024-08-20T10:15:08.997Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('232d534c-9bd4-44bf-849e-0940ff0d8f3e', 'd66cb4b1-61ab-44b9-b431-2eaa04542320', '2024-08-13T15:05:54.437Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('232d534c-9bd4-44bf-849e-0940ff0d8f3e', '56aa7ec4-2b39-48bf-a014-635cf7945fc4', '2024-08-07T00:43:47.392Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('91c606eb-c2a4-44e2-9ee2-8ae25c9b0485', 'a6a05382-5b1a-4a8f-a851-119ccaf77f98', '2024-08-03T23:17:34.724Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('a6a05382-5b1a-4a8f-a851-119ccaf77f98', '05036186-cbf2-4ea7-b446-dc14447c88f1', '2024-08-29T23:13:03.614Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d8c1b5e4-f94e-4b05-a8c7-17d86e2ad315', '50e872f7-1238-40c4-acd8-d4f082ffb4f0', '2024-08-13T18:21:09.773Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('dc71415e-330e-455d-85ff-ec432ad52862', 'd66cb4b1-61ab-44b9-b431-2eaa04542320', '2024-08-07T15:43:33.269Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6704b2a8-cc47-48df-b0b9-1c82d9031bbd', '46fa3a47-9d5f-45b8-bc28-3c948029848e', '2024-08-31T06:59:13.700Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e18f1135-137c-4966-9883-881bd7cc3c0a', '442d962c-abed-402d-8ee6-14be6ebd74bd', '2024-08-14T13:16:44.790Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('818ffdc2-63a3-4c08-bd82-65b704eb3791', '6a96fd38-197e-47c7-8f88-e9d1451bb98a', '2024-08-03T03:15:32.584Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('819f196b-997c-46ff-8964-96b64e69be09', 'a478d17a-1b5e-4602-9520-15121bdb0317', '2024-08-15T09:27:10.964Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('819f196b-997c-46ff-8964-96b64e69be09', '26680a6c-6827-4a0e-a8ce-c67f09bf7cbc', '2024-08-04T03:13:23.466Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e18f1135-137c-4966-9883-881bd7cc3c0a', 'f77c87aa-12b5-464a-8629-b607776f75f0', '2024-08-09T22:10:40.489Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ab75d59a-650e-4768-a6fd-00272eaf98b2', '90968472-3852-4978-8112-557f11ec7e4d', '2024-08-05T13:03:29.465Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('9ae90144-555a-4de6-9262-63a7f62cba92', '232d534c-9bd4-44bf-849e-0940ff0d8f3e', '2024-08-31T00:13:21.094Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('4fefac21-ad9e-4ebe-94d5-dd85579ba1b8', '0e9a5bca-2473-4466-b882-663b4ec04603', '2024-08-08T15:18:39.689Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ab75d59a-650e-4768-a6fd-00272eaf98b2', '9ae90144-555a-4de6-9262-63a7f62cba92', '2024-08-16T04:06:18.301Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('56aa7ec4-2b39-48bf-a014-635cf7945fc4', '50ab8370-c757-42a7-881c-b44b3f79cc01', '2024-08-13T00:48:35.410Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('30f64f29-7abd-42ad-a610-92f2b64e5d5e', '3c967916-a4d0-4c24-9712-c96d4f45ad47', '2024-08-04T17:01:29.275Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('feea87a0-b84f-4c31-857d-371d26a75dac', '8044dce0-6679-426f-9335-b5c002fef209', '2024-08-29T03:57:47.471Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('a26fac26-d1c6-4223-863a-f5e6ca9d6d2c', '6a96fd38-197e-47c7-8f88-e9d1451bb98a', '2024-09-01T14:29:01.866Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('46fa3a47-9d5f-45b8-bc28-3c948029848e', 'd72ad16a-5ded-487c-877d-3851491634ac', '2024-08-18T00:25:12.194Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('3620f183-cb4d-4537-b5b3-9adb10e096c7', 'cb28b381-e3c1-4155-9e05-9339e5874184', '2024-08-30T07:24:42.044Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e345315e-bb59-4787-b0c9-29f69379c00e', '14973eb6-b77c-49b0-bd35-9bbb307bb52b', '2024-08-12T20:18:29.623Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e345315e-bb59-4787-b0c9-29f69379c00e', '4e247196-9778-410b-a106-3295e7a8c223', '2024-08-12T21:57:55.386Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('50e872f7-1238-40c4-acd8-d4f082ffb4f0', 'e18f1135-137c-4966-9883-881bd7cc3c0a', '2024-08-27T21:17:13.567Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('56aa7ec4-2b39-48bf-a014-635cf7945fc4', '92f02a3f-de88-4f6b-b93f-fadb1366255b', '2024-08-04T22:34:56.505Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e1b52554-e67a-4488-95b8-e13faf830852', '90968472-3852-4978-8112-557f11ec7e4d', '2024-08-06T06:53:38.260Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ab75d59a-650e-4768-a6fd-00272eaf98b2', '819f196b-997c-46ff-8964-96b64e69be09', '2024-08-03T15:53:41.167Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('92f02a3f-de88-4f6b-b93f-fadb1366255b', '7d30f1e9-5998-4d54-b67f-aa8d7bd779e5', '2024-08-13T12:11:39.887Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('c369cecb-905f-4c93-8a7c-6ebc4d938f51', 'e4659d06-39b9-417a-a5c7-8c51522a48ea', '2024-08-15T08:59:31.999Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ee145b69-3acc-4d39-9912-73e66ab99f68', '232d534c-9bd4-44bf-849e-0940ff0d8f3e', '2024-08-23T02:26:13.967Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('56aa7ec4-2b39-48bf-a014-635cf7945fc4', '5ad6bc14-36d1-4e93-b712-806f58dfe4c1', '2024-08-18T15:40:37.502Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('38812fa2-1f56-447a-b3a7-51cda4e6c075', '9f0397a9-c3fe-45bc-9a55-a2387e4bbdbe', '2024-08-21T21:16:12.717Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2715ef58-c273-4c9f-a24d-c70bac5f1b1c', '732c8fa1-2036-4e4b-a210-411bbce9c9a7', '2024-08-16T14:08:00.342Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('7639bb07-14c8-49b8-b815-bec946340f63', '133ffc07-3119-4c09-a793-f9f2bff49b64', '2024-08-07T16:56:44.732Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6a96fd38-197e-47c7-8f88-e9d1451bb98a', 'e18f1135-137c-4966-9883-881bd7cc3c0a', '2024-08-17T07:17:37.540Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('05036186-cbf2-4ea7-b446-dc14447c88f1', '92f02a3f-de88-4f6b-b93f-fadb1366255b', '2024-08-29T05:21:19.662Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('67b465fa-495f-48ff-bde7-c6879d26a840', 'f77c87aa-12b5-464a-8629-b607776f75f0', '2024-08-30T23:54:54.411Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('bedfc261-99bf-4f47-b9a4-2491a1147734', '8be08817-fd8b-465f-a436-50e8a2816d62', '2024-08-16T10:56:15.803Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2c37c85f-db8f-4f9a-8e63-ab8cde11dc6e', 'e5ae947f-cd22-4c36-8410-17b88f2d4b54', '2024-08-12T08:09:28.810Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6a96fd38-197e-47c7-8f88-e9d1451bb98a', 'e96c56b0-fa4a-443c-aaf3-9f95bf409f8b', '2024-08-27T09:50:59.545Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('a6a05382-5b1a-4a8f-a851-119ccaf77f98', 'a26fac26-d1c6-4223-863a-f5e6ca9d6d2c', '2024-08-26T00:33:00.741Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6a96fd38-197e-47c7-8f88-e9d1451bb98a', 'e4659d06-39b9-417a-a5c7-8c51522a48ea', '2024-08-21T09:53:05.765Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('818ffdc2-63a3-4c08-bd82-65b704eb3791', '2c37c85f-db8f-4f9a-8e63-ab8cde11dc6e', '2024-08-16T05:39:42.061Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('f73af756-45a5-416d-963b-809bb43b4c02', '996d2b57-51d8-4f34-b44b-12cae5d7b816', '2024-08-05T17:17:46.827Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('46fa3a47-9d5f-45b8-bc28-3c948029848e', '24ac73f3-192e-424f-8d5c-dfade4d52883', '2024-08-27T16:46:42.009Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('94bb1874-8092-4286-8252-f2f0066d68bb', 'e4935ae6-f609-4044-aff4-3a5a6defd3d3', '2024-08-23T07:44:38.194Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d665c01e-d750-4046-9428-8264715da6c0', '307d9772-de85-4b2c-96c4-ba6731df86b8', '2024-08-05T03:41:32.853Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('307d9772-de85-4b2c-96c4-ba6731df86b8', 'f73af756-45a5-416d-963b-809bb43b4c02', '2024-08-12T04:55:13.243Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('4e502c29-e850-483f-89d9-9d422bc359c2', '9f0397a9-c3fe-45bc-9a55-a2387e4bbdbe', '2024-08-13T07:57:28.585Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('732c8fa1-2036-4e4b-a210-411bbce9c9a7', '6a96fd38-197e-47c7-8f88-e9d1451bb98a', '2024-08-21T21:05:54.291Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('7d30f1e9-5998-4d54-b67f-aa8d7bd779e5', '4e247196-9778-410b-a106-3295e7a8c223', '2024-08-20T19:06:14.520Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d665c01e-d750-4046-9428-8264715da6c0', 'b6283786-5ef5-4970-8e3b-2d341148e67a', '2024-08-08T16:18:32.798Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d86d6638-e3f2-4c18-a660-fdd7bcd48dee', 'f39acdac-6cef-44f1-a0a2-7d6601463bf4', '2024-08-10T21:55:34.010Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('37286d2d-a250-4058-afb1-7b7146d36107', 'feea87a0-b84f-4c31-857d-371d26a75dac', '2024-08-11T10:54:21.843Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('307d9772-de85-4b2c-96c4-ba6731df86b8', 'c576d48c-4c3a-418f-8fb7-23c1f488c536', '2024-08-07T23:46:07.574Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('dc71415e-330e-455d-85ff-ec432ad52862', '819f196b-997c-46ff-8964-96b64e69be09', '2024-09-01T00:36:38.006Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('232d534c-9bd4-44bf-849e-0940ff0d8f3e', '2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', '2024-08-18T18:42:48.581Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('90968472-3852-4978-8112-557f11ec7e4d', 'e4935ae6-f609-4044-aff4-3a5a6defd3d3', '2024-08-29T10:20:05.380Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e5ae947f-cd22-4c36-8410-17b88f2d4b54', '05036186-cbf2-4ea7-b446-dc14447c88f1', '2024-08-25T02:54:14.502Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('7e3e93a1-32cb-4931-a3df-f7bc90abd991', '1b94f1eb-1690-41ab-afa9-4423f9a89a83', '2024-08-26T01:35:06.648Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('dc71415e-330e-455d-85ff-ec432ad52862', '3c967916-a4d0-4c24-9712-c96d4f45ad47', '2024-08-30T02:13:18.273Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('56aa7ec4-2b39-48bf-a014-635cf7945fc4', '91c606eb-c2a4-44e2-9ee2-8ae25c9b0485', '2024-08-04T17:46:03.111Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ab75d59a-650e-4768-a6fd-00272eaf98b2', '26680a6c-6827-4a0e-a8ce-c67f09bf7cbc', '2024-08-30T02:40:07.472Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('a7058bc0-3700-4e70-a310-e1384942ca63', 'a6a05382-5b1a-4a8f-a851-119ccaf77f98', '2024-08-16T14:42:52.867Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6997eef9-2c6e-4792-90d0-68b66278121a', '67b465fa-495f-48ff-bde7-c6879d26a840', '2024-08-06T08:38:56.793Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('92f02a3f-de88-4f6b-b93f-fadb1366255b', '0e9a5bca-2473-4466-b882-663b4ec04603', '2024-08-30T06:47:49.970Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('1263c5ad-7edc-46dd-8113-aeb222328767', 'e18f1135-137c-4966-9883-881bd7cc3c0a', '2024-08-07T12:28:01.545Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('feea87a0-b84f-4c31-857d-371d26a75dac', '70a57abc-bf59-4ac8-99e7-db839193fa1e', '2024-08-18T17:42:50.963Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('11a25c43-e483-4ae5-9839-841a85e9fa4d', 'b6283786-5ef5-4970-8e3b-2d341148e67a', '2024-08-30T13:05:44.847Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('a26fac26-d1c6-4223-863a-f5e6ca9d6d2c', 'c821b7d3-8dd2-44ca-ad17-99c71cbd4d9c', '2024-08-17T20:52:11.016Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('26f198c8-ed62-4fc7-81c6-b191663aa8da', 'ab75d59a-650e-4768-a6fd-00272eaf98b2', '2024-08-30T10:54:48.022Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('c576d48c-4c3a-418f-8fb7-23c1f488c536', '7639bb07-14c8-49b8-b815-bec946340f63', '2024-08-29T10:06:21.507Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6997eef9-2c6e-4792-90d0-68b66278121a', '56aa7ec4-2b39-48bf-a014-635cf7945fc4', '2024-08-13T11:03:05.594Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2fe7ec0d-de09-40de-90df-4a5a865e7457', 'ae2cb809-9444-4bfa-8d82-e0adb2b4ee18', '2024-08-05T12:18:26.905Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('4e247196-9778-410b-a106-3295e7a8c223', 'e39947d1-976b-4436-8b90-555ddc6e8891', '2024-08-12T20:51:21.767Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d8c1b5e4-f94e-4b05-a8c7-17d86e2ad315', '996d2b57-51d8-4f34-b44b-12cae5d7b816', '2024-08-24T03:56:50.841Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6704b2a8-cc47-48df-b0b9-1c82d9031bbd', 'cf4d3686-5356-418f-b16f-0a265a40080d', '2024-08-12T09:51:59.499Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e4659d06-39b9-417a-a5c7-8c51522a48ea', '2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', '2024-08-07T14:38:43.717Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('f77c87aa-12b5-464a-8629-b607776f75f0', '38812fa2-1f56-447a-b3a7-51cda4e6c075', '2024-08-28T14:20:21.899Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('f73af756-45a5-416d-963b-809bb43b4c02', 'e18f1135-137c-4966-9883-881bd7cc3c0a', '2024-08-21T22:44:17.704Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('7639bb07-14c8-49b8-b815-bec946340f63', 'd665c01e-d750-4046-9428-8264715da6c0', '2024-08-19T07:46:46.019Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('8be08817-fd8b-465f-a436-50e8a2816d62', 'f73af756-45a5-416d-963b-809bb43b4c02', '2024-08-04T21:45:03.721Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('11a25c43-e483-4ae5-9839-841a85e9fa4d', '819f196b-997c-46ff-8964-96b64e69be09', '2024-08-17T09:29:10.726Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('94bb1874-8092-4286-8252-f2f0066d68bb', '67b465fa-495f-48ff-bde7-c6879d26a840', '2024-08-19T08:47:24.814Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('37286d2d-a250-4058-afb1-7b7146d36107', 'ab75d59a-650e-4768-a6fd-00272eaf98b2', '2024-08-18T09:50:19.401Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('f39acdac-6cef-44f1-a0a2-7d6601463bf4', 'ac8e8a50-bd4e-4053-8772-d2826683c29d', '2024-08-05T15:50:28.648Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('f39acdac-6cef-44f1-a0a2-7d6601463bf4', '91c606eb-c2a4-44e2-9ee2-8ae25c9b0485', '2024-08-02T18:50:43.440Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('000cbabf-d423-4937-8272-a91097dae393', '5ad6bc14-36d1-4e93-b712-806f58dfe4c1', '2024-08-10T15:38:39.481Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('05036186-cbf2-4ea7-b446-dc14447c88f1', '442d962c-abed-402d-8ee6-14be6ebd74bd', '2024-08-20T08:08:21.146Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('11bf0c4f-04e0-4327-96ef-44c3cd03028f', '819f196b-997c-46ff-8964-96b64e69be09', '2024-08-08T06:23:31.878Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('c576d48c-4c3a-418f-8fb7-23c1f488c536', 'e39947d1-976b-4436-8b90-555ddc6e8891', '2024-08-20T14:57:12.295Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('8be08817-fd8b-465f-a436-50e8a2816d62', '92f02a3f-de88-4f6b-b93f-fadb1366255b', '2024-08-26T00:43:01.804Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e4659d06-39b9-417a-a5c7-8c51522a48ea', '05036186-cbf2-4ea7-b446-dc14447c88f1', '2024-08-27T16:04:17.899Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('9ae90144-555a-4de6-9262-63a7f62cba92', 'cb28b381-e3c1-4155-9e05-9339e5874184', '2024-08-12T23:32:56.260Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('eeedb312-c02c-4480-b6e4-7a3145cbb44a', '819f196b-997c-46ff-8964-96b64e69be09', '2024-08-27T05:05:45.662Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('11a25c43-e483-4ae5-9839-841a85e9fa4d', 'd66cb4b1-61ab-44b9-b431-2eaa04542320', '2024-08-06T09:31:56.147Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('4e247196-9778-410b-a106-3295e7a8c223', '5f554356-f203-4cb4-820d-995d806f2469', '2024-08-17T16:36:30.500Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('30f64f29-7abd-42ad-a610-92f2b64e5d5e', 'ee145b69-3acc-4d39-9912-73e66ab99f68', '2024-08-12T08:14:21.813Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('0e9a5bca-2473-4466-b882-663b4ec04603', '307d9772-de85-4b2c-96c4-ba6731df86b8', '2024-08-21T07:55:50.480Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('1263c5ad-7edc-46dd-8113-aeb222328767', '0e98eb24-3c0a-44bd-9c6a-bc40e7b841b7', '2024-08-22T09:32:34.531Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e18f1135-137c-4966-9883-881bd7cc3c0a', '2c37c85f-db8f-4f9a-8e63-ab8cde11dc6e', '2024-08-23T23:39:13.499Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('5f554356-f203-4cb4-820d-995d806f2469', '64af3593-2a87-4c5b-bc96-0f1f38bc7455', '2024-08-18T20:36:52.631Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('cf4d3686-5356-418f-b16f-0a265a40080d', '133ffc07-3119-4c09-a793-f9f2bff49b64', '2024-08-20T11:43:51.371Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('3cd2c8bf-8fd4-40ca-96e3-5e41dd52d8c7', '5fe704f1-a885-4d95-bab3-639503750f61', '2024-08-26T04:21:11.966Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('c062042f-6446-4376-b543-d64d70eabc0d', 'ae2cb809-9444-4bfa-8d82-e0adb2b4ee18', '2024-08-21T06:05:23.389Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('11a25c43-e483-4ae5-9839-841a85e9fa4d', '7e3e93a1-32cb-4931-a3df-f7bc90abd991', '2024-08-29T17:07:42.299Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('9ae90144-555a-4de6-9262-63a7f62cba92', 'f39acdac-6cef-44f1-a0a2-7d6601463bf4', '2024-08-06T21:58:58.734Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e4659d06-39b9-417a-a5c7-8c51522a48ea', '000cbabf-d423-4937-8272-a91097dae393', '2024-08-07T19:05:12.960Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('9ae90144-555a-4de6-9262-63a7f62cba92', 'feea87a0-b84f-4c31-857d-371d26a75dac', '2024-08-29T10:17:22.430Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('1b94f1eb-1690-41ab-afa9-4423f9a89a83', '30f64f29-7abd-42ad-a610-92f2b64e5d5e', '2024-08-12T12:46:05.553Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6704b2a8-cc47-48df-b0b9-1c82d9031bbd', 'e1b52554-e67a-4488-95b8-e13faf830852', '2024-08-21T08:12:06.866Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d665c01e-d750-4046-9428-8264715da6c0', 'c576d48c-4c3a-418f-8fb7-23c1f488c536', '2024-08-29T18:22:09.950Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('30f64f29-7abd-42ad-a610-92f2b64e5d5e', 'b2fa99af-d6ab-4f42-99c0-e42001c854a9', '2024-08-31T16:07:47.478Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e18f1135-137c-4966-9883-881bd7cc3c0a', '5f554356-f203-4cb4-820d-995d806f2469', '2024-08-27T02:15:02.480Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('307d9772-de85-4b2c-96c4-ba6731df86b8', '894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', '2024-09-01T16:12:28.569Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('1b94f1eb-1690-41ab-afa9-4423f9a89a83', 'f39acdac-6cef-44f1-a0a2-7d6601463bf4', '2024-08-11T06:05:37.990Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('f39acdac-6cef-44f1-a0a2-7d6601463bf4', 'cf4d3686-5356-418f-b16f-0a265a40080d', '2024-08-11T12:18:12.411Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('3620f183-cb4d-4537-b5b3-9adb10e096c7', '90968472-3852-4978-8112-557f11ec7e4d', '2024-08-24T11:04:15.744Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('996d2b57-51d8-4f34-b44b-12cae5d7b816', '92f02a3f-de88-4f6b-b93f-fadb1366255b', '2024-08-19T23:40:33.855Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('8fe847fa-0a60-4d29-9920-570cec52bae9', 'aba678d1-e6c4-48f9-939a-e58264ed0230', '2024-08-06T11:35:46.679Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('1263c5ad-7edc-46dd-8113-aeb222328767', '0e9a5bca-2473-4466-b882-663b4ec04603', '2024-08-16T07:37:24.350Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('7e3e93a1-32cb-4931-a3df-f7bc90abd991', 'e4935ae6-f609-4044-aff4-3a5a6defd3d3', '2024-08-30T08:57:15.043Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e4935ae6-f609-4044-aff4-3a5a6defd3d3', 'c062042f-6446-4376-b543-d64d70eabc0d', '2024-08-11T12:15:26.920Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d8c1b5e4-f94e-4b05-a8c7-17d86e2ad315', '2715ef58-c273-4c9f-a24d-c70bac5f1b1c', '2024-08-08T01:52:31.577Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('c576d48c-4c3a-418f-8fb7-23c1f488c536', '9f0397a9-c3fe-45bc-9a55-a2387e4bbdbe', '2024-08-09T16:22:33.551Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', '9f0397a9-c3fe-45bc-9a55-a2387e4bbdbe', '2024-08-09T18:31:06.028Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('5ad6bc14-36d1-4e93-b712-806f58dfe4c1', '6a96fd38-197e-47c7-8f88-e9d1451bb98a', '2024-08-05T08:13:24.760Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('91c606eb-c2a4-44e2-9ee2-8ae25c9b0485', 'e5ae947f-cd22-4c36-8410-17b88f2d4b54', '2024-08-13T21:11:17.712Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('8be08817-fd8b-465f-a436-50e8a2816d62', '4fefac21-ad9e-4ebe-94d5-dd85579ba1b8', '2024-08-23T00:03:21.630Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('c369cecb-905f-4c93-8a7c-6ebc4d938f51', 'dc71415e-330e-455d-85ff-ec432ad52862', '2024-08-07T17:55:16.684Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('30f64f29-7abd-42ad-a610-92f2b64e5d5e', '50e872f7-1238-40c4-acd8-d4f082ffb4f0', '2024-08-28T16:37:25.724Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('442d962c-abed-402d-8ee6-14be6ebd74bd', 'c369cecb-905f-4c93-8a7c-6ebc4d938f51', '2024-08-24T03:14:38.433Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('37286d2d-a250-4058-afb1-7b7146d36107', '819f196b-997c-46ff-8964-96b64e69be09', '2024-08-11T04:44:04.448Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ae2cb809-9444-4bfa-8d82-e0adb2b4ee18', '442d962c-abed-402d-8ee6-14be6ebd74bd', '2024-08-14T17:51:23.468Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('f77c87aa-12b5-464a-8629-b607776f75f0', '9ae90144-555a-4de6-9262-63a7f62cba92', '2024-08-10T11:55:53.185Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('75f18662-bf58-4a4e-bf73-b05b6677cd3e', '000cbabf-d423-4937-8272-a91097dae393', '2024-08-13T09:48:46.519Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('8be08817-fd8b-465f-a436-50e8a2816d62', 'e1b52554-e67a-4488-95b8-e13faf830852', '2024-08-21T18:56:34.479Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('37286d2d-a250-4058-afb1-7b7146d36107', '46fa3a47-9d5f-45b8-bc28-3c948029848e', '2024-08-28T03:11:27.689Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e18f1135-137c-4966-9883-881bd7cc3c0a', '5fe704f1-a885-4d95-bab3-639503750f61', '2024-08-31T05:07:49.097Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6704b2a8-cc47-48df-b0b9-1c82d9031bbd', '307d9772-de85-4b2c-96c4-ba6731df86b8', '2024-08-02T19:35:57.770Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d7fcceab-cf1c-4ac8-804e-842c76f1c606', '232d534c-9bd4-44bf-849e-0940ff0d8f3e', '2024-08-13T08:12:52.965Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('67b465fa-495f-48ff-bde7-c6879d26a840', 'd66cb4b1-61ab-44b9-b431-2eaa04542320', '2024-08-11T13:32:21.117Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('f73af756-45a5-416d-963b-809bb43b4c02', '7639bb07-14c8-49b8-b815-bec946340f63', '2024-08-03T22:34:48.026Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ae2cb809-9444-4bfa-8d82-e0adb2b4ee18', '0e9a5bca-2473-4466-b882-663b4ec04603', '2024-08-11T10:45:53.270Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6704b2a8-cc47-48df-b0b9-1c82d9031bbd', '133ffc07-3119-4c09-a793-f9f2bff49b64', '2024-09-01T03:27:03.605Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d66cb4b1-61ab-44b9-b431-2eaa04542320', '64af3593-2a87-4c5b-bc96-0f1f38bc7455', '2024-08-29T10:35:35.932Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('8044dce0-6679-426f-9335-b5c002fef209', 'e1b52554-e67a-4488-95b8-e13faf830852', '2024-08-14T13:47:55.927Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ab75d59a-650e-4768-a6fd-00272eaf98b2', '8044dce0-6679-426f-9335-b5c002fef209', '2024-08-17T22:09:56.565Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e4659d06-39b9-417a-a5c7-8c51522a48ea', '6997eef9-2c6e-4792-90d0-68b66278121a', '2024-08-04T12:07:16.799Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('26f198c8-ed62-4fc7-81c6-b191663aa8da', '0e9a5bca-2473-4466-b882-663b4ec04603', '2024-08-03T06:33:44.155Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('f73af756-45a5-416d-963b-809bb43b4c02', '9f0397a9-c3fe-45bc-9a55-a2387e4bbdbe', '2024-08-24T07:25:55.089Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('56aa7ec4-2b39-48bf-a014-635cf7945fc4', '2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', '2024-08-06T23:33:03.893Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('f77c87aa-12b5-464a-8629-b607776f75f0', '8fe847fa-0a60-4d29-9920-570cec52bae9', '2024-08-16T10:43:22.964Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('7d30f1e9-5998-4d54-b67f-aa8d7bd779e5', '30f64f29-7abd-42ad-a610-92f2b64e5d5e', '2024-08-06T13:52:30.164Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('3620f183-cb4d-4537-b5b3-9adb10e096c7', '133ffc07-3119-4c09-a793-f9f2bff49b64', '2024-08-25T05:34:32.539Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d8c1b5e4-f94e-4b05-a8c7-17d86e2ad315', 'e39947d1-976b-4436-8b90-555ddc6e8891', '2024-08-24T17:30:34.590Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ee145b69-3acc-4d39-9912-73e66ab99f68', '818ffdc2-63a3-4c08-bd82-65b704eb3791', '2024-08-10T11:05:15.950Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('14973eb6-b77c-49b0-bd35-9bbb307bb52b', 'f73af756-45a5-416d-963b-809bb43b4c02', '2024-08-16T01:22:55.380Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d66cb4b1-61ab-44b9-b431-2eaa04542320', 'e4935ae6-f609-4044-aff4-3a5a6defd3d3', '2024-08-04T17:41:59.874Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('4e502c29-e850-483f-89d9-9d422bc359c2', '11a25c43-e483-4ae5-9839-841a85e9fa4d', '2024-08-20T08:51:21.399Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6997eef9-2c6e-4792-90d0-68b66278121a', '0e9a5bca-2473-4466-b882-663b4ec04603', '2024-08-15T12:50:01.186Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2fe7ec0d-de09-40de-90df-4a5a865e7457', '6099e094-d434-4a62-85c7-50506e082577', '2024-08-30T07:51:23.207Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('24ac73f3-192e-424f-8d5c-dfade4d52883', 'e18f1135-137c-4966-9883-881bd7cc3c0a', '2024-08-19T01:48:28.644Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d7fcceab-cf1c-4ac8-804e-842c76f1c606', 'eeedb312-c02c-4480-b6e4-7a3145cbb44a', '2024-08-11T07:23:28.731Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d665c01e-d750-4046-9428-8264715da6c0', 'd72ad16a-5ded-487c-877d-3851491634ac', '2024-08-23T16:40:42.946Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('37286d2d-a250-4058-afb1-7b7146d36107', '732c8fa1-2036-4e4b-a210-411bbce9c9a7', '2024-08-04T21:08:29.651Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('90968472-3852-4978-8112-557f11ec7e4d', '2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', '2024-08-21T19:54:35.617Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e4659d06-39b9-417a-a5c7-8c51522a48ea', '7639bb07-14c8-49b8-b815-bec946340f63', '2024-08-27T14:46:36.890Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('3620f183-cb4d-4537-b5b3-9adb10e096c7', '6704b2a8-cc47-48df-b0b9-1c82d9031bbd', '2024-08-15T00:07:29.539Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6704b2a8-cc47-48df-b0b9-1c82d9031bbd', 'd86d6638-e3f2-4c18-a660-fdd7bcd48dee', '2024-08-24T16:20:28.759Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('cb28b381-e3c1-4155-9e05-9339e5874184', '1b94f1eb-1690-41ab-afa9-4423f9a89a83', '2024-08-22T15:40:08.623Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('c369cecb-905f-4c93-8a7c-6ebc4d938f51', 'e5ae947f-cd22-4c36-8410-17b88f2d4b54', '2024-08-02T20:15:36.275Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d8c1b5e4-f94e-4b05-a8c7-17d86e2ad315', 'd86d6638-e3f2-4c18-a660-fdd7bcd48dee', '2024-08-31T12:12:50.776Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('1b94f1eb-1690-41ab-afa9-4423f9a89a83', '894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', '2024-08-14T04:21:33.172Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('232d534c-9bd4-44bf-849e-0940ff0d8f3e', 'e1b52554-e67a-4488-95b8-e13faf830852', '2024-08-28T16:55:04.560Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('3cd2c8bf-8fd4-40ca-96e3-5e41dd52d8c7', 'ab75d59a-650e-4768-a6fd-00272eaf98b2', '2024-08-19T04:53:45.259Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('818ffdc2-63a3-4c08-bd82-65b704eb3791', '2fe7ec0d-de09-40de-90df-4a5a865e7457', '2024-08-05T13:52:24.261Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('732c8fa1-2036-4e4b-a210-411bbce9c9a7', '05036186-cbf2-4ea7-b446-dc14447c88f1', '2024-08-11T03:24:05.358Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e1b52554-e67a-4488-95b8-e13faf830852', '6997eef9-2c6e-4792-90d0-68b66278121a', '2024-08-03T21:40:36.498Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('c062042f-6446-4376-b543-d64d70eabc0d', '5fe704f1-a885-4d95-bab3-639503750f61', '2024-08-06T18:40:56.806Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('c369cecb-905f-4c93-8a7c-6ebc4d938f51', 'feea87a0-b84f-4c31-857d-371d26a75dac', '2024-08-21T09:05:04.092Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('818ffdc2-63a3-4c08-bd82-65b704eb3791', '91c606eb-c2a4-44e2-9ee2-8ae25c9b0485', '2024-08-17T18:39:20.549Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('26680a6c-6827-4a0e-a8ce-c67f09bf7cbc', '67b465fa-495f-48ff-bde7-c6879d26a840', '2024-08-08T17:57:27.026Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('0e9a5bca-2473-4466-b882-663b4ec04603', 'e345315e-bb59-4787-b0c9-29f69379c00e', '2024-08-10T18:51:29.576Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ff96307c-d5bb-4479-b43d-c400270d6f67', 'c062042f-6446-4376-b543-d64d70eabc0d', '2024-08-18T12:20:17.344Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('3c967916-a4d0-4c24-9712-c96d4f45ad47', '5ad6bc14-36d1-4e93-b712-806f58dfe4c1', '2024-08-28T14:31:33.009Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('64af3593-2a87-4c5b-bc96-0f1f38bc7455', 'e39947d1-976b-4436-8b90-555ddc6e8891', '2024-08-30T01:58:19.364Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('bedfc261-99bf-4f47-b9a4-2491a1147734', 'c821b7d3-8dd2-44ca-ad17-99c71cbd4d9c', '2024-08-04T06:05:40.929Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('b6283786-5ef5-4970-8e3b-2d341148e67a', 'cf4d3686-5356-418f-b16f-0a265a40080d', '2024-08-11T00:05:10.247Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('442d962c-abed-402d-8ee6-14be6ebd74bd', '24ac73f3-192e-424f-8d5c-dfade4d52883', '2024-08-29T16:23:42.667Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('cf4d3686-5356-418f-b16f-0a265a40080d', '67b465fa-495f-48ff-bde7-c6879d26a840', '2024-08-27T03:01:45.746Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('8fe847fa-0a60-4d29-9920-570cec52bae9', 'b6283786-5ef5-4970-8e3b-2d341148e67a', '2024-08-15T01:26:26.687Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('b2fa99af-d6ab-4f42-99c0-e42001c854a9', 'eeedb312-c02c-4480-b6e4-7a3145cbb44a', '2024-08-12T12:14:33.669Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6099e094-d434-4a62-85c7-50506e082577', '442d962c-abed-402d-8ee6-14be6ebd74bd', '2024-08-11T01:37:01.647Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('3c967916-a4d0-4c24-9712-c96d4f45ad47', '8044dce0-6679-426f-9335-b5c002fef209', '2024-08-25T00:44:33.777Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e18f1135-137c-4966-9883-881bd7cc3c0a', '56aa7ec4-2b39-48bf-a014-635cf7945fc4', '2024-08-07T19:32:46.621Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('37286d2d-a250-4058-afb1-7b7146d36107', '894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', '2024-08-22T08:25:14.061Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d665c01e-d750-4046-9428-8264715da6c0', 'd86d6638-e3f2-4c18-a660-fdd7bcd48dee', '2024-08-14T18:09:16.176Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('94bb1874-8092-4286-8252-f2f0066d68bb', 'ae2cb809-9444-4bfa-8d82-e0adb2b4ee18', '2024-08-14T01:41:57.215Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2715ef58-c273-4c9f-a24d-c70bac5f1b1c', 'cf4d3686-5356-418f-b16f-0a265a40080d', '2024-08-22T18:41:09.990Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('b6283786-5ef5-4970-8e3b-2d341148e67a', 'feea87a0-b84f-4c31-857d-371d26a75dac', '2024-08-13T00:08:52.308Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('819f196b-997c-46ff-8964-96b64e69be09', 'cb28b381-e3c1-4155-9e05-9339e5874184', '2024-08-31T01:26:41.615Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('232d534c-9bd4-44bf-849e-0940ff0d8f3e', 'e345315e-bb59-4787-b0c9-29f69379c00e', '2024-08-31T12:02:01.058Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('f77c87aa-12b5-464a-8629-b607776f75f0', 'c369cecb-905f-4c93-8a7c-6ebc4d938f51', '2024-08-22T16:16:34.277Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e4935ae6-f609-4044-aff4-3a5a6defd3d3', '75f18662-bf58-4a4e-bf73-b05b6677cd3e', '2024-08-15T16:35:52.332Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('eeedb312-c02c-4480-b6e4-7a3145cbb44a', '6704b2a8-cc47-48df-b0b9-1c82d9031bbd', '2024-08-16T07:18:47.022Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('1263c5ad-7edc-46dd-8113-aeb222328767', '11a25c43-e483-4ae5-9839-841a85e9fa4d', '2024-08-21T14:32:03.923Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('7e3e93a1-32cb-4931-a3df-f7bc90abd991', 'c062042f-6446-4376-b543-d64d70eabc0d', '2024-08-13T00:54:18.538Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('14973eb6-b77c-49b0-bd35-9bbb307bb52b', '442d962c-abed-402d-8ee6-14be6ebd74bd', '2024-08-14T02:25:38.078Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('9ae90144-555a-4de6-9262-63a7f62cba92', '6997eef9-2c6e-4792-90d0-68b66278121a', '2024-09-01T00:03:58.420Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('3cd2c8bf-8fd4-40ca-96e3-5e41dd52d8c7', 'ff96307c-d5bb-4479-b43d-c400270d6f67', '2024-08-24T17:06:52.825Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('3cd2c8bf-8fd4-40ca-96e3-5e41dd52d8c7', '0e98eb24-3c0a-44bd-9c6a-bc40e7b841b7', '2024-08-14T15:34:10.810Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('8fe847fa-0a60-4d29-9920-570cec52bae9', 'e5ae947f-cd22-4c36-8410-17b88f2d4b54', '2024-08-25T15:25:39.054Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('56aa7ec4-2b39-48bf-a014-635cf7945fc4', '0e9a5bca-2473-4466-b882-663b4ec04603', '2024-08-13T09:18:07.761Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('a26fac26-d1c6-4223-863a-f5e6ca9d6d2c', '14973eb6-b77c-49b0-bd35-9bbb307bb52b', '2024-08-23T17:30:27.834Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e1b52554-e67a-4488-95b8-e13faf830852', '56aa7ec4-2b39-48bf-a014-635cf7945fc4', '2024-08-02T17:20:19.741Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2fe7ec0d-de09-40de-90df-4a5a865e7457', '30f64f29-7abd-42ad-a610-92f2b64e5d5e', '2024-08-30T06:20:23.804Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ae2cb809-9444-4bfa-8d82-e0adb2b4ee18', 'c062042f-6446-4376-b543-d64d70eabc0d', '2024-08-16T17:43:20.261Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e345315e-bb59-4787-b0c9-29f69379c00e', '232d534c-9bd4-44bf-849e-0940ff0d8f3e', '2024-08-24T09:48:34.846Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('37286d2d-a250-4058-afb1-7b7146d36107', 'f39acdac-6cef-44f1-a0a2-7d6601463bf4', '2024-08-25T22:59:16.552Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('1263c5ad-7edc-46dd-8113-aeb222328767', '7e3e93a1-32cb-4931-a3df-f7bc90abd991', '2024-08-28T22:27:51.565Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6997eef9-2c6e-4792-90d0-68b66278121a', '2fe7ec0d-de09-40de-90df-4a5a865e7457', '2024-08-12T14:13:38.172Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d7fcceab-cf1c-4ac8-804e-842c76f1c606', '5f554356-f203-4cb4-820d-995d806f2469', '2024-08-25T03:27:16.860Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('5fe704f1-a885-4d95-bab3-639503750f61', '92f02a3f-de88-4f6b-b93f-fadb1366255b', '2024-08-13T04:32:06.383Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('37286d2d-a250-4058-afb1-7b7146d36107', 'ac8e8a50-bd4e-4053-8772-d2826683c29d', '2024-08-07T22:18:08.516Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('b6283786-5ef5-4970-8e3b-2d341148e67a', 'bedfc261-99bf-4f47-b9a4-2491a1147734', '2024-08-22T21:42:32.027Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('4e502c29-e850-483f-89d9-9d422bc359c2', 'd7fcceab-cf1c-4ac8-804e-842c76f1c606', '2024-08-06T01:16:04.912Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('9ae90144-555a-4de6-9262-63a7f62cba92', '8044dce0-6679-426f-9335-b5c002fef209', '2024-08-20T21:57:08.914Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('3620f183-cb4d-4537-b5b3-9adb10e096c7', 'e18f1135-137c-4966-9883-881bd7cc3c0a', '2024-08-31T21:24:38.770Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d72ad16a-5ded-487c-877d-3851491634ac', 'b6283786-5ef5-4970-8e3b-2d341148e67a', '2024-08-21T17:26:49.143Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('819f196b-997c-46ff-8964-96b64e69be09', 'd86d6638-e3f2-4c18-a660-fdd7bcd48dee', '2024-08-07T19:18:07.773Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('a26fac26-d1c6-4223-863a-f5e6ca9d6d2c', '56aa7ec4-2b39-48bf-a014-635cf7945fc4', '2024-08-03T20:22:16.153Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('8be08817-fd8b-465f-a436-50e8a2816d62', 'e5ae947f-cd22-4c36-8410-17b88f2d4b54', '2024-08-15T02:46:44.221Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('4e247196-9778-410b-a106-3295e7a8c223', '6704b2a8-cc47-48df-b0b9-1c82d9031bbd', '2024-08-15T06:33:48.304Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('000cbabf-d423-4937-8272-a91097dae393', '732c8fa1-2036-4e4b-a210-411bbce9c9a7', '2024-08-31T05:19:44.122Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d665c01e-d750-4046-9428-8264715da6c0', 'ae2cb809-9444-4bfa-8d82-e0adb2b4ee18', '2024-08-14T23:44:54.466Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('5fe704f1-a885-4d95-bab3-639503750f61', '7e3e93a1-32cb-4931-a3df-f7bc90abd991', '2024-08-17T07:38:51.115Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('05036186-cbf2-4ea7-b446-dc14447c88f1', 'e4935ae6-f609-4044-aff4-3a5a6defd3d3', '2024-08-11T13:52:52.836Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', '732c8fa1-2036-4e4b-a210-411bbce9c9a7', '2024-08-14T09:09:39.121Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('8044dce0-6679-426f-9335-b5c002fef209', 'd72ad16a-5ded-487c-877d-3851491634ac', '2024-08-18T09:19:56.256Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('50ab8370-c757-42a7-881c-b44b3f79cc01', 'a478d17a-1b5e-4602-9520-15121bdb0317', '2024-08-31T09:39:09.509Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2c37c85f-db8f-4f9a-8e63-ab8cde11dc6e', '6099e094-d434-4a62-85c7-50506e082577', '2024-08-10T09:08:28.579Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d72ad16a-5ded-487c-877d-3851491634ac', '6997eef9-2c6e-4792-90d0-68b66278121a', '2024-08-30T01:28:47.238Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', '9ae90144-555a-4de6-9262-63a7f62cba92', '2024-08-17T07:32:23.333Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('819f196b-997c-46ff-8964-96b64e69be09', 'eeedb312-c02c-4480-b6e4-7a3145cbb44a', '2024-08-23T19:55:48.382Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e4659d06-39b9-417a-a5c7-8c51522a48ea', 'e1b52554-e67a-4488-95b8-e13faf830852', '2024-08-06T19:39:52.720Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('732c8fa1-2036-4e4b-a210-411bbce9c9a7', 'ee145b69-3acc-4d39-9912-73e66ab99f68', '2024-08-09T13:42:23.672Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ac8e8a50-bd4e-4053-8772-d2826683c29d', '05036186-cbf2-4ea7-b446-dc14447c88f1', '2024-08-30T21:33:44.700Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('732c8fa1-2036-4e4b-a210-411bbce9c9a7', '75f18662-bf58-4a4e-bf73-b05b6677cd3e', '2024-08-24T18:02:13.034Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('000cbabf-d423-4937-8272-a91097dae393', 'ac8e8a50-bd4e-4053-8772-d2826683c29d', '2024-08-20T14:33:31.138Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e4659d06-39b9-417a-a5c7-8c51522a48ea', '0e9a5bca-2473-4466-b882-663b4ec04603', '2024-08-05T05:25:17.020Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('8044dce0-6679-426f-9335-b5c002fef209', 'a26fac26-d1c6-4223-863a-f5e6ca9d6d2c', '2024-08-15T08:57:39.815Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('67b465fa-495f-48ff-bde7-c6879d26a840', '5f554356-f203-4cb4-820d-995d806f2469', '2024-08-23T09:00:04.830Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('46fa3a47-9d5f-45b8-bc28-3c948029848e', '819f196b-997c-46ff-8964-96b64e69be09', '2024-08-14T17:30:09.996Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('feea87a0-b84f-4c31-857d-371d26a75dac', '9f0397a9-c3fe-45bc-9a55-a2387e4bbdbe', '2024-08-02T19:11:38.306Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('8be08817-fd8b-465f-a436-50e8a2816d62', 'e96c56b0-fa4a-443c-aaf3-9f95bf409f8b', '2024-09-01T09:14:30.588Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('5f554356-f203-4cb4-820d-995d806f2469', '56aa7ec4-2b39-48bf-a014-635cf7945fc4', '2024-08-02T18:41:00.669Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('a478d17a-1b5e-4602-9520-15121bdb0317', '26680a6c-6827-4a0e-a8ce-c67f09bf7cbc', '2024-08-16T15:37:46.878Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('5ad6bc14-36d1-4e93-b712-806f58dfe4c1', 'd72ad16a-5ded-487c-877d-3851491634ac', '2024-08-07T01:05:21.039Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('1263c5ad-7edc-46dd-8113-aeb222328767', '732c8fa1-2036-4e4b-a210-411bbce9c9a7', '2024-08-10T01:45:44.253Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('cb28b381-e3c1-4155-9e05-9339e5874184', '8fe847fa-0a60-4d29-9920-570cec52bae9', '2024-08-23T15:50:40.403Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ab75d59a-650e-4768-a6fd-00272eaf98b2', '0e98eb24-3c0a-44bd-9c6a-bc40e7b841b7', '2024-08-23T04:39:31.080Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('11a25c43-e483-4ae5-9839-841a85e9fa4d', '46fa3a47-9d5f-45b8-bc28-3c948029848e', '2024-08-11T03:34:38.740Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('05036186-cbf2-4ea7-b446-dc14447c88f1', '38812fa2-1f56-447a-b3a7-51cda4e6c075', '2024-08-20T20:47:03.460Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('50e872f7-1238-40c4-acd8-d4f082ffb4f0', '819f196b-997c-46ff-8964-96b64e69be09', '2024-08-15T00:21:01.363Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('819f196b-997c-46ff-8964-96b64e69be09', '996d2b57-51d8-4f34-b44b-12cae5d7b816', '2024-09-01T09:51:06.170Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('996d2b57-51d8-4f34-b44b-12cae5d7b816', 'b2fa99af-d6ab-4f42-99c0-e42001c854a9', '2024-08-22T07:23:30.323Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('3c967916-a4d0-4c24-9712-c96d4f45ad47', '442d962c-abed-402d-8ee6-14be6ebd74bd', '2024-08-09T03:32:40.267Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d72ad16a-5ded-487c-877d-3851491634ac', '2fe7ec0d-de09-40de-90df-4a5a865e7457', '2024-08-03T15:47:59.319Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e4659d06-39b9-417a-a5c7-8c51522a48ea', 'f77c87aa-12b5-464a-8629-b607776f75f0', '2024-08-07T06:30:27.296Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e96c56b0-fa4a-443c-aaf3-9f95bf409f8b', 'c821b7d3-8dd2-44ca-ad17-99c71cbd4d9c', '2024-08-04T00:10:18.473Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('7d30f1e9-5998-4d54-b67f-aa8d7bd779e5', '442d962c-abed-402d-8ee6-14be6ebd74bd', '2024-08-07T08:14:51.281Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('92f02a3f-de88-4f6b-b93f-fadb1366255b', '8fe847fa-0a60-4d29-9920-570cec52bae9', '2024-08-16T03:27:24.655Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e4659d06-39b9-417a-a5c7-8c51522a48ea', '37286d2d-a250-4058-afb1-7b7146d36107', '2024-08-04T02:14:21.257Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('442d962c-abed-402d-8ee6-14be6ebd74bd', '90968472-3852-4978-8112-557f11ec7e4d', '2024-08-31T18:38:49.060Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('91c606eb-c2a4-44e2-9ee2-8ae25c9b0485', '94bb1874-8092-4286-8252-f2f0066d68bb', '2024-08-08T02:16:56.020Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('8044dce0-6679-426f-9335-b5c002fef209', '75f18662-bf58-4a4e-bf73-b05b6677cd3e', '2024-08-03T21:11:29.651Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d72ad16a-5ded-487c-877d-3851491634ac', '05036186-cbf2-4ea7-b446-dc14447c88f1', '2024-08-17T12:09:33.876Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('1b94f1eb-1690-41ab-afa9-4423f9a89a83', 'a7058bc0-3700-4e70-a310-e1384942ca63', '2024-08-04T21:18:55.039Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('38812fa2-1f56-447a-b3a7-51cda4e6c075', '819f196b-997c-46ff-8964-96b64e69be09', '2024-08-15T15:42:20.376Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('cb28b381-e3c1-4155-9e05-9339e5874184', '26f198c8-ed62-4fc7-81c6-b191663aa8da', '2024-08-22T06:55:04.347Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('50e872f7-1238-40c4-acd8-d4f082ffb4f0', '50ab8370-c757-42a7-881c-b44b3f79cc01', '2024-08-06T02:07:31.980Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('996d2b57-51d8-4f34-b44b-12cae5d7b816', '6704b2a8-cc47-48df-b0b9-1c82d9031bbd', '2024-08-19T20:50:13.879Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('91c606eb-c2a4-44e2-9ee2-8ae25c9b0485', 'f77c87aa-12b5-464a-8629-b607776f75f0', '2024-08-18T06:13:09.888Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('5f554356-f203-4cb4-820d-995d806f2469', '4e502c29-e850-483f-89d9-9d422bc359c2', '2024-08-29T01:43:36.690Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e345315e-bb59-4787-b0c9-29f69379c00e', '6a96fd38-197e-47c7-8f88-e9d1451bb98a', '2024-08-19T13:20:45.649Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('75f18662-bf58-4a4e-bf73-b05b6677cd3e', 'a6a05382-5b1a-4a8f-a851-119ccaf77f98', '2024-08-12T20:14:54.308Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('91c606eb-c2a4-44e2-9ee2-8ae25c9b0485', '6704b2a8-cc47-48df-b0b9-1c82d9031bbd', '2024-08-27T04:23:59.620Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('26f198c8-ed62-4fc7-81c6-b191663aa8da', '50ab8370-c757-42a7-881c-b44b3f79cc01', '2024-08-31T13:16:19.395Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('50e872f7-1238-40c4-acd8-d4f082ffb4f0', '90968472-3852-4978-8112-557f11ec7e4d', '2024-08-28T12:18:12.821Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('a478d17a-1b5e-4602-9520-15121bdb0317', '8be08817-fd8b-465f-a436-50e8a2816d62', '2024-08-07T09:29:30.175Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('3620f183-cb4d-4537-b5b3-9adb10e096c7', 'd86d6638-e3f2-4c18-a660-fdd7bcd48dee', '2024-08-07T21:56:01.175Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('92f02a3f-de88-4f6b-b93f-fadb1366255b', '14973eb6-b77c-49b0-bd35-9bbb307bb52b', '2024-08-19T20:13:21.412Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('4e247196-9778-410b-a106-3295e7a8c223', '50ab8370-c757-42a7-881c-b44b3f79cc01', '2024-08-27T17:30:31.512Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('aba678d1-e6c4-48f9-939a-e58264ed0230', '2fe7ec0d-de09-40de-90df-4a5a865e7457', '2024-08-28T18:01:18.460Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('75f18662-bf58-4a4e-bf73-b05b6677cd3e', 'e18f1135-137c-4966-9883-881bd7cc3c0a', '2024-08-15T20:17:20.676Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('9f0397a9-c3fe-45bc-9a55-a2387e4bbdbe', '7d30f1e9-5998-4d54-b67f-aa8d7bd779e5', '2024-08-10T15:24:22.494Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('a478d17a-1b5e-4602-9520-15121bdb0317', '92f02a3f-de88-4f6b-b93f-fadb1366255b', '2024-08-20T12:25:32.175Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d8c1b5e4-f94e-4b05-a8c7-17d86e2ad315', '732c8fa1-2036-4e4b-a210-411bbce9c9a7', '2024-08-12T11:08:02.607Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('cb28b381-e3c1-4155-9e05-9339e5874184', 'f39acdac-6cef-44f1-a0a2-7d6601463bf4', '2024-08-13T13:07:53.017Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('4e247196-9778-410b-a106-3295e7a8c223', '50e872f7-1238-40c4-acd8-d4f082ffb4f0', '2024-08-11T16:31:30.270Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ab75d59a-650e-4768-a6fd-00272eaf98b2', '6099e094-d434-4a62-85c7-50506e082577', '2024-08-03T19:54:46.922Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e96c56b0-fa4a-443c-aaf3-9f95bf409f8b', '6a96fd38-197e-47c7-8f88-e9d1451bb98a', '2024-08-25T21:49:44.879Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d66cb4b1-61ab-44b9-b431-2eaa04542320', '2715ef58-c273-4c9f-a24d-c70bac5f1b1c', '2024-08-24T03:07:01.821Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('38812fa2-1f56-447a-b3a7-51cda4e6c075', '8fe847fa-0a60-4d29-9920-570cec52bae9', '2024-08-25T22:15:23.521Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('05036186-cbf2-4ea7-b446-dc14447c88f1', '7d30f1e9-5998-4d54-b67f-aa8d7bd779e5', '2024-08-17T00:55:11.785Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6a96fd38-197e-47c7-8f88-e9d1451bb98a', 'd7fcceab-cf1c-4ac8-804e-842c76f1c606', '2024-08-21T03:21:51.309Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('24ac73f3-192e-424f-8d5c-dfade4d52883', '4fefac21-ad9e-4ebe-94d5-dd85579ba1b8', '2024-08-16T15:09:42.159Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('cf4d3686-5356-418f-b16f-0a265a40080d', '75f18662-bf58-4a4e-bf73-b05b6677cd3e', '2024-08-05T04:07:35.256Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6099e094-d434-4a62-85c7-50506e082577', '38812fa2-1f56-447a-b3a7-51cda4e6c075', '2024-08-17T09:43:09.628Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('1b94f1eb-1690-41ab-afa9-4423f9a89a83', 'e18f1135-137c-4966-9883-881bd7cc3c0a', '2024-08-17T12:15:12.189Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('90968472-3852-4978-8112-557f11ec7e4d', 'e39947d1-976b-4436-8b90-555ddc6e8891', '2024-08-13T03:00:15.850Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('7639bb07-14c8-49b8-b815-bec946340f63', '26f198c8-ed62-4fc7-81c6-b191663aa8da', '2024-08-18T20:10:32.895Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('75f18662-bf58-4a4e-bf73-b05b6677cd3e', 'cf4d3686-5356-418f-b16f-0a265a40080d', '2024-08-11T22:14:48.056Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e4659d06-39b9-417a-a5c7-8c51522a48ea', 'a7058bc0-3700-4e70-a310-e1384942ca63', '2024-08-12T21:55:14.818Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d86d6638-e3f2-4c18-a660-fdd7bcd48dee', '3c967916-a4d0-4c24-9712-c96d4f45ad47', '2024-08-10T13:24:35.491Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('5fe704f1-a885-4d95-bab3-639503750f61', '8fe847fa-0a60-4d29-9920-570cec52bae9', '2024-08-21T10:16:01.724Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('1b94f1eb-1690-41ab-afa9-4423f9a89a83', '0e9a5bca-2473-4466-b882-663b4ec04603', '2024-08-26T09:51:15.926Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6099e094-d434-4a62-85c7-50506e082577', '26f198c8-ed62-4fc7-81c6-b191663aa8da', '2024-08-16T11:16:07.660Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('0e9a5bca-2473-4466-b882-663b4ec04603', '26680a6c-6827-4a0e-a8ce-c67f09bf7cbc', '2024-08-11T19:19:51.646Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('732c8fa1-2036-4e4b-a210-411bbce9c9a7', 'd86d6638-e3f2-4c18-a660-fdd7bcd48dee', '2024-08-27T00:28:35.851Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('9f0397a9-c3fe-45bc-9a55-a2387e4bbdbe', '8fe847fa-0a60-4d29-9920-570cec52bae9', '2024-08-30T16:21:00.820Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('ae2cb809-9444-4bfa-8d82-e0adb2b4ee18', '91c606eb-c2a4-44e2-9ee2-8ae25c9b0485', '2024-08-17T01:24:47.665Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('996d2b57-51d8-4f34-b44b-12cae5d7b816', 'e1b52554-e67a-4488-95b8-e13faf830852', '2024-08-11T20:56:22.218Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('11a25c43-e483-4ae5-9839-841a85e9fa4d', '6704b2a8-cc47-48df-b0b9-1c82d9031bbd', '2024-08-06T10:43:18.526Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6099e094-d434-4a62-85c7-50506e082577', 'eeedb312-c02c-4480-b6e4-7a3145cbb44a', '2024-08-03T17:39:54.666Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('0e9a5bca-2473-4466-b882-663b4ec04603', 'e4659d06-39b9-417a-a5c7-8c51522a48ea', '2024-08-04T09:43:29.560Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('7e3e93a1-32cb-4931-a3df-f7bc90abd991', 'f77c87aa-12b5-464a-8629-b607776f75f0', '2024-08-14T05:56:26.940Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('cf4d3686-5356-418f-b16f-0a265a40080d', 'b2fa99af-d6ab-4f42-99c0-e42001c854a9', '2024-08-20T04:01:42.421Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('307d9772-de85-4b2c-96c4-ba6731df86b8', '91c606eb-c2a4-44e2-9ee2-8ae25c9b0485', '2024-08-09T02:28:55.964Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('46fa3a47-9d5f-45b8-bc28-3c948029848e', '3620f183-cb4d-4537-b5b3-9adb10e096c7', '2024-08-14T10:06:45.407Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('b2fa99af-d6ab-4f42-99c0-e42001c854a9', '05036186-cbf2-4ea7-b446-dc14447c88f1', '2024-08-22T18:27:13.029Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('aba678d1-e6c4-48f9-939a-e58264ed0230', '38812fa2-1f56-447a-b3a7-51cda4e6c075', '2024-08-25T08:36:50.055Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e4935ae6-f609-4044-aff4-3a5a6defd3d3', '8fe847fa-0a60-4d29-9920-570cec52bae9', '2024-08-10T13:19:02.567Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d8c1b5e4-f94e-4b05-a8c7-17d86e2ad315', 'f73af756-45a5-416d-963b-809bb43b4c02', '2024-08-19T16:36:59.223Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('000cbabf-d423-4937-8272-a91097dae393', '11a25c43-e483-4ae5-9839-841a85e9fa4d', '2024-08-20T16:33:45.759Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('7639bb07-14c8-49b8-b815-bec946340f63', '819f196b-997c-46ff-8964-96b64e69be09', '2024-08-05T03:46:14.347Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e18f1135-137c-4966-9883-881bd7cc3c0a', '4e502c29-e850-483f-89d9-9d422bc359c2', '2024-08-10T02:36:47.944Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('cb28b381-e3c1-4155-9e05-9339e5874184', '9ae90144-555a-4de6-9262-63a7f62cba92', '2024-08-09T13:16:38.387Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('e1b52554-e67a-4488-95b8-e13faf830852', '1b94f1eb-1690-41ab-afa9-4423f9a89a83', '2024-08-20T12:35:12.063Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('f39acdac-6cef-44f1-a0a2-7d6601463bf4', 'd665c01e-d750-4046-9428-8264715da6c0', '2024-08-27T05:35:41.803Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('c576d48c-4c3a-418f-8fb7-23c1f488c536', '894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', '2024-08-18T08:05:03.317Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('feea87a0-b84f-4c31-857d-371d26a75dac', 'e39947d1-976b-4436-8b90-555ddc6e8891', '2024-08-10T19:22:15.480Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2fe7ec0d-de09-40de-90df-4a5a865e7457', '2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', '2024-08-25T00:21:08.010Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', 'd72ad16a-5ded-487c-877d-3851491634ac', '2024-08-14T06:24:41.335Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('d7fcceab-cf1c-4ac8-804e-842c76f1c606', '30f64f29-7abd-42ad-a610-92f2b64e5d5e', '2024-08-14T23:12:39.612Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('50e872f7-1238-40c4-acd8-d4f082ffb4f0', 'e5ae947f-cd22-4c36-8410-17b88f2d4b54', '2024-08-07T00:12:05.536Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('50e872f7-1238-40c4-acd8-d4f082ffb4f0', 'd72ad16a-5ded-487c-877d-3851491634ac', '2024-08-15T20:18:29.186Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('a6a05382-5b1a-4a8f-a851-119ccaf77f98', 'a7058bc0-3700-4e70-a310-e1384942ca63', '2024-08-18T10:35:13.327Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('6099e094-d434-4a62-85c7-50506e082577', '90968472-3852-4978-8112-557f11ec7e4d', '2024-08-26T12:19:47.957Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('14973eb6-b77c-49b0-bd35-9bbb307bb52b', 'e1b52554-e67a-4488-95b8-e13faf830852', '2024-08-04T17:19:27.439Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', '4fefac21-ad9e-4ebe-94d5-dd85579ba1b8', '2024-08-30T04:37:17.963Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('30f64f29-7abd-42ad-a610-92f2b64e5d5e', 'd86d6638-e3f2-4c18-a660-fdd7bcd48dee', '2024-08-11T10:50:48.777Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('4e247196-9778-410b-a106-3295e7a8c223', '7e3e93a1-32cb-4931-a3df-f7bc90abd991', '2024-08-30T11:26:29.524Z');

insert into PUBLIC.follows(follower_id, followed_id, followed_at)
	values ('30f64f29-7abd-42ad-a610-92f2b64e5d5e', '56aa7ec4-2b39-48bf-a014-635cf7945fc4', '2024-08-02T21:53:21.548Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('f34dbed1-cd44-4548-a486-4b4789fb3053', '37286d2d-a250-4058-afb1-7b7146d36107', '14973eb6-b77c-49b0-bd35-9bbb307bb52b', 40948, 'positive', 'Decor bene chirographum theca nihil accusantium creptio enim. Paens apostolus cultellus tardus auditor subnecto atque uredo.', '2024-08-17T05:14:59.331Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('a31d449f-e5a1-4c11-9ffc-98ee42ae5171', '46fa3a47-9d5f-45b8-bc28-3c948029848e', '4e502c29-e850-483f-89d9-9d422bc359c2', 40139, 'negative', 'Tricesimus vetus eligendi certe.', '2024-08-08T21:28:56.998Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('e13d02f0-2f57-42cb-b154-c20e7539cc61', 'd8c1b5e4-f94e-4b05-a8c7-17d86e2ad315', '1b94f1eb-1690-41ab-afa9-4423f9a89a83', 10850, 'positive', 'Accedo autus claudeo thesaurus utpote curriculum substantia dolorum testimonium. Caecus crepusculum trans stipes subnecto videlicet facilis advenio.', '2024-08-31T15:03:49.792Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('77474f4b-7ee8-4183-8e86-8fdf11521044', '8be08817-fd8b-465f-a436-50e8a2816d62', '92f02a3f-de88-4f6b-b93f-fadb1366255b', 28609, 'negative', 'Aegre trucido averto basium commodo debitis earum. Absque viduo cado cado triduana.', '2024-08-30T06:05:18.423Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('2ee91283-f61b-4746-8605-64dc4b2d7cad', 'b6283786-5ef5-4970-8e3b-2d341148e67a', '996d2b57-51d8-4f34-b44b-12cae5d7b816', 2243, 'positive', 'Audacia vilicus supra defendo impedit comparo.', '2024-08-31T17:06:56.890Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('760af0da-8308-44a3-91e5-0133719ae06f', 'cf4d3686-5356-418f-b16f-0a265a40080d', '2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', 17115, 'negative', 'Copia aufero amoveo vallum subito ceno vilicus.', '2024-08-10T03:55:00.149Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('9696c720-2603-4a82-9ddc-77bac0d7cd9e', '1263c5ad-7edc-46dd-8113-aeb222328767', '14973eb6-b77c-49b0-bd35-9bbb307bb52b', 3735, 'positive', 'Amet corrumpo cupio similique cibus. Terror trepide temporibus similique tabula pecco vivo.', '2024-08-11T04:50:11.233Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('e3201604-46c2-4ab5-8af4-cf3ae031fa60', '2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', '732c8fa1-2036-4e4b-a210-411bbce9c9a7', 64781, 'negative', 'Addo cornu thema validus. Baiulus umerus callide callide tempora ancilla tantum umerus vilicus caritas.', '2024-08-23T05:56:16.028Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('26252982-6f59-4945-a27f-a0c7d2572373', 'd72ad16a-5ded-487c-877d-3851491634ac', '46fa3a47-9d5f-45b8-bc28-3c948029848e', 38786, 'positive', 'Aeger verecundia adeo adhuc adflicto auctor suggero pariatur capto. Antepono at terminatio creber tot depulso territo aspicio.', '2024-08-16T07:08:10.853Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('7c77d61f-4c05-4440-bc47-6c7bb13481c5', '92f02a3f-de88-4f6b-b93f-fadb1366255b', '2fe7ec0d-de09-40de-90df-4a5a865e7457', 24594, 'negative', 'Aedificium arca at tamisium conculco earum. Alienus sublime acceptus delego crapula.', '2024-08-06T22:11:21.939Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('02365eb4-bb70-4fae-829f-8b6ed724024a', '894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', 'cb28b381-e3c1-4155-9e05-9339e5874184', 34034, 'positive', 'Aliquid corrumpo ago adeo terror. Coma adhaero tredecim creptio uterque astrum voluntarius veniam compello ullam.', '2024-08-30T08:06:50.293Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('38da40bd-b696-463e-b39c-100175117cc4', '6704b2a8-cc47-48df-b0b9-1c82d9031bbd', 'd66cb4b1-61ab-44b9-b431-2eaa04542320', 71013, 'negative', 'Arca ad correptius. Ullam calcar sublime acceptus.', '2024-08-31T10:04:01.121Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('e5a341e4-df1c-44f3-ae61-f1d7089eaa9b', '64af3593-2a87-4c5b-bc96-0f1f38bc7455', '26680a6c-6827-4a0e-a8ce-c67f09bf7cbc', 69886, 'positive', 'Temporibus patruus arca canto cultellus auxilium callide adinventitias. Ante vomer adhuc voluptate comminor apparatus.', '2024-08-08T09:05:19.117Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('195d89ed-44a5-464b-928b-a92e235ed0d9', 'ee145b69-3acc-4d39-9912-73e66ab99f68', '1263c5ad-7edc-46dd-8113-aeb222328767', 40767, 'negative', 'Quas delectatio addo adfero amaritudo aggredior cupio.', '2024-08-24T15:47:08.056Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('1857c318-c6a0-4509-9019-45a420e1dda3', '2c37c85f-db8f-4f9a-8e63-ab8cde11dc6e', '37286d2d-a250-4058-afb1-7b7146d36107', 56212, 'positive', 'Delicate cernuus trans aequus tredecim. Asperiores convoco vespillo dolor crudelis aperiam trans dolorum delibero.', '2024-08-31T11:46:33.505Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('7257419a-5e6c-4ca7-abbf-e8a29d63c8bb', '30f64f29-7abd-42ad-a610-92f2b64e5d5e', 'e345315e-bb59-4787-b0c9-29f69379c00e', 82627, 'negative', 'Demitto adopto adversus.', '2024-08-16T19:52:03.729Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('b0f2cfe6-072d-4574-94a4-a32237349768', 'e18f1135-137c-4966-9883-881bd7cc3c0a', 'b6283786-5ef5-4970-8e3b-2d341148e67a', 72560, 'positive', 'Ventito utroque vapulus perferendis quis ultra spoliatio. Demoror cultellus surgo denego.', '2024-08-15T03:45:13.998Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('ac8c24e4-5cb6-4424-bc3b-5294eff4cefa', '6997eef9-2c6e-4792-90d0-68b66278121a', '7d30f1e9-5998-4d54-b67f-aa8d7bd779e5', 88785, 'negative', 'Suggero sordeo tener decumbo.', '2024-08-27T19:30:31.675Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('77a3f0db-42da-4bfd-95cb-79898451dd44', 'eeedb312-c02c-4480-b6e4-7a3145cbb44a', 'a26fac26-d1c6-4223-863a-f5e6ca9d6d2c', 16010, 'positive', 'Suus curo cruentus claudeo tepidus trans tergeo cupressus trepide.', '2024-08-27T01:26:28.264Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('96e0b692-2474-4e2f-ad13-104c4342476f', 'e4659d06-39b9-417a-a5c7-8c51522a48ea', 'e1b52554-e67a-4488-95b8-e13faf830852', 99214, 'negative', 'Calco astrum verumtamen arma vae. Aduro argumentum tendo stipes sint cito voluptatibus denique currus.', '2024-08-06T16:03:36.714Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('cee0d0bc-7750-43dd-832c-7b5ce3104582', 'a6a05382-5b1a-4a8f-a851-119ccaf77f98', 'e39947d1-976b-4436-8b90-555ddc6e8891', 84483, 'positive', 'Utilis administratio usus adversus dedecor tremo. Aiunt eum conicio usitas audentia adversus.', '2024-08-20T17:25:24.506Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('096515b3-a2b0-48a3-a06a-58a8dd7daa23', '6a96fd38-197e-47c7-8f88-e9d1451bb98a', 'feea87a0-b84f-4c31-857d-371d26a75dac', 53086, 'negative', 'Aptus depopulo aestivus aiunt cognomen.', '2024-08-12T20:13:17.182Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('f6a5d0c9-d030-44b2-8992-c181ed0c8564', '442d962c-abed-402d-8ee6-14be6ebd74bd', '90968472-3852-4978-8112-557f11ec7e4d', 19532, 'positive', 'Cito canis titulus. Votum cumque addo ambitus turbo ventosus volutabrum magni uredo cilicium.', '2024-08-16T11:40:51.562Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('334f027e-a80f-4599-83c2-9ca8ff728a46', 'ee145b69-3acc-4d39-9912-73e66ab99f68', '26f198c8-ed62-4fc7-81c6-b191663aa8da', 69170, 'negative', 'Cruentus ipsa cometes antea tot adstringo tego. Bene vulgivagus causa.', '2024-08-13T05:55:09.810Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('4ab4410d-8193-4694-b37a-05cc8b847cbd', '6099e094-d434-4a62-85c7-50506e082577', '92f02a3f-de88-4f6b-b93f-fadb1366255b', 20091, 'positive', 'Allatus claudeo dens. Reiciendis impedit vomer.', '2024-08-25T07:57:34.270Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('63375035-6e61-4e93-8f9a-196522e70cd7', '0e9a5bca-2473-4466-b882-663b4ec04603', 'c576d48c-4c3a-418f-8fb7-23c1f488c536', 66438, 'negative', 'Quod somnus adinventitias caries.', '2024-08-25T04:40:15.461Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('353671ce-3202-404c-8d2b-dc32eaa21f28', '26f198c8-ed62-4fc7-81c6-b191663aa8da', 'f73af756-45a5-416d-963b-809bb43b4c02', 29650, 'positive', 'Angulus velociter arbitro. Vulgus abscido temptatio sed voro stillicidium infit.', '2024-08-10T02:12:27.556Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('7ac1f092-3fa9-4dd2-8f51-1a7ddfc1748f', '5ad6bc14-36d1-4e93-b712-806f58dfe4c1', '5f554356-f203-4cb4-820d-995d806f2469', 31386, 'negative', 'Attollo censura collum bonus infit tenetur tenus approbo. Tergo cattus vado a despecto.', '2024-08-19T23:15:57.005Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('89e5654b-3599-4266-be80-7124e89d53fc', '50e872f7-1238-40c4-acd8-d4f082ffb4f0', '5ad6bc14-36d1-4e93-b712-806f58dfe4c1', 50455, 'positive', 'Vel credo adhuc auxilium tyrannus videlicet. Pariatur cohors antiquus suscipio delicate charisma.', '2024-08-14T20:35:07.690Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('9fc486e4-5a6d-43f8-83d2-b09b6eaa9b13', '4e247196-9778-410b-a106-3295e7a8c223', '732c8fa1-2036-4e4b-a210-411bbce9c9a7', 54719, 'negative', 'Considero summisse derelinquo callide barba tabula cogito attero decretum.', '2024-08-08T00:01:07.431Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('82a1cd78-478e-4f93-8f14-e235b795434a', 'f39acdac-6cef-44f1-a0a2-7d6601463bf4', '8044dce0-6679-426f-9335-b5c002fef209', 29889, 'positive', 'Callide torrens unde aqua taedium certe consequatur cohaero cresco officia. Thorax ventosus summisse fugiat clam tredecim.', '2024-08-17T17:49:58.861Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('bdcf0e0c-9aad-4402-9417-b9d67e46ccd0', 'e4935ae6-f609-4044-aff4-3a5a6defd3d3', '3620f183-cb4d-4537-b5b3-9adb10e096c7', 47499, 'negative', 'Articulus apto curriculum.', '2024-08-07T00:14:09.006Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('1bb1d8d6-fe0a-4c35-a90d-892055d61b6a', '2715ef58-c273-4c9f-a24d-c70bac5f1b1c', 'c821b7d3-8dd2-44ca-ad17-99c71cbd4d9c', 70760, 'positive', 'Crux contra dens deputo ademptio terga amplexus custodia certe torqueo.', '2024-08-02T20:15:54.794Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('c98e08c0-d831-43b3-b14a-091dd7949114', 'dc71415e-330e-455d-85ff-ec432ad52862', '4e247196-9778-410b-a106-3295e7a8c223', 22958, 'negative', 'Agnitio versus spargo subnecto delectus accommodo tenus incidunt.', '2024-08-18T11:58:13.280Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('49bdd67a-2177-4674-92b8-85a920ac8a48', 'f77c87aa-12b5-464a-8629-b607776f75f0', 'a26fac26-d1c6-4223-863a-f5e6ca9d6d2c', 85560, 'positive', 'Occaecati animi baiulus.', '2024-08-20T15:32:25.079Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('13ade49d-cb18-4dcd-a8f1-cfac6445f336', '6997eef9-2c6e-4792-90d0-68b66278121a', '894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', 67863, 'negative', 'Sophismata pauci arbor collum spiculum thymbra. Tyrannus aegrotatio pauci desolo conforto blanditiis rerum utique.', '2024-08-09T14:13:55.081Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('e8a17108-d56f-49c3-b24b-0cbd6d3f6f7d', 'bedfc261-99bf-4f47-b9a4-2491a1147734', 'c369cecb-905f-4c93-8a7c-6ebc4d938f51', 54066, 'positive', 'Spectaculum coaegresco adulatio. Apostolus vix statua adulatio rem verus.', '2024-08-24T14:09:26.002Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('5ec609bf-7947-4222-8dc0-329a0f12243c', '133ffc07-3119-4c09-a793-f9f2bff49b64', '3620f183-cb4d-4537-b5b3-9adb10e096c7', 76930, 'negative', 'Earum acies viriliter deripio incidunt.', '2024-08-28T18:52:00.498Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('55f1e14d-03d4-4cae-8afc-95fbf50e25c8', '5f554356-f203-4cb4-820d-995d806f2469', '50e872f7-1238-40c4-acd8-d4f082ffb4f0', 66237, 'positive', 'Alius crastinus spero commodi tollo triumphus ustilo clementia utique.', '2024-08-25T09:29:29.385Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('ae577c81-95d5-468d-a55b-148e52d6f138', '732c8fa1-2036-4e4b-a210-411bbce9c9a7', 'feea87a0-b84f-4c31-857d-371d26a75dac', 94276, 'negative', 'Vae victus curis video facere toties alo vicissitudo uxor cubo. Vix claudeo congregatio amita sono eum cimentarius exercitationem balbus.', '2024-08-15T02:25:27.129Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('4045ea2e-92b9-4bf7-ab88-2346ad3fb7d3', '24ac73f3-192e-424f-8d5c-dfade4d52883', 'eeedb312-c02c-4480-b6e4-7a3145cbb44a', 59273, 'positive', 'Avaritia amplitudo demulceo thesaurus sol utrum cum absens denique. Conduco vinum vos tego officiis accendo quo in.', '2024-08-25T01:19:43.694Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('c1eefd0f-c7e6-4958-8e72-b9dae6176a2d', '67b465fa-495f-48ff-bde7-c6879d26a840', 'e5ae947f-cd22-4c36-8410-17b88f2d4b54', 48594, 'negative', 'Placeat thymbra ciminatio iste audentia possimus nesciunt. Delicate canto ad veritatis tempus.', '2024-08-05T01:06:45.234Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('d5558b93-6a3e-405d-97ec-f412808e30fe', '8be08817-fd8b-465f-a436-50e8a2816d62', 'c821b7d3-8dd2-44ca-ad17-99c71cbd4d9c', 21456, 'positive', 'Bene comptus sed cavus civitas sub confero usque articulus.', '2024-08-19T07:45:42.935Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('eb776abb-1304-42b7-9e79-9588416bf85d', 'bedfc261-99bf-4f47-b9a4-2491a1147734', '14973eb6-b77c-49b0-bd35-9bbb307bb52b', 4100, 'negative', 'Auxilium temperantia maiores. Possimus debitis amplitudo adaugeo triduana vigor adfero.', '2024-08-11T13:19:17.612Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('247ad01f-3e57-404d-be26-5d4625ad9e3d', '8be08817-fd8b-465f-a436-50e8a2816d62', 'd86d6638-e3f2-4c18-a660-fdd7bcd48dee', 50716, 'positive', 'Ventus textilis viriliter laudantium.', '2024-08-06T02:26:52.121Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('b1391e0c-9c4d-4c2b-afe0-c945d3f7d868', 'ac8e8a50-bd4e-4053-8772-d2826683c29d', '05036186-cbf2-4ea7-b446-dc14447c88f1', 12753, 'negative', 'Et alius tutamen vigor arto incidunt advoco.', '2024-08-18T17:16:54.714Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('7a543e8d-57ad-4a17-a318-545a27bcecd8', 'ae2cb809-9444-4bfa-8d82-e0adb2b4ee18', 'd72ad16a-5ded-487c-877d-3851491634ac', 12727, 'positive', 'Catena totus adficio caelestis defaeco. Vulgus claustrum cruentus.', '2024-08-29T05:08:17.500Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('99e83d85-62b5-4a5b-a3ea-f734a1516066', 'c821b7d3-8dd2-44ca-ad17-99c71cbd4d9c', '38812fa2-1f56-447a-b3a7-51cda4e6c075', 83855, 'negative', 'Animus conitor adflicto depulso sperno.', '2024-08-16T23:38:24.164Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('55308a48-65ad-4d35-8064-7f2a3364dc8d', 'eeedb312-c02c-4480-b6e4-7a3145cbb44a', 'dc71415e-330e-455d-85ff-ec432ad52862', 66172, 'positive', 'Calcar clam vulticulus aperte adsidue eius caecus depopulo qui ter.', '2024-08-16T10:41:10.246Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('13eb9f7b-7d20-4e83-970e-c32578c5cda4', '732c8fa1-2036-4e4b-a210-411bbce9c9a7', '307d9772-de85-4b2c-96c4-ba6731df86b8', 21108, 'negative', 'Claudeo causa dedico blandior combibo.', '2024-08-16T15:05:38.568Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('68b5e66a-de32-44e1-9bf6-9faf2878de88', '8044dce0-6679-426f-9335-b5c002fef209', '50e872f7-1238-40c4-acd8-d4f082ffb4f0', 11667, 'positive', 'Deserunt adulescens textus auctor aranea alveus caelestis temptatio nisi capitulus.', '2024-08-14T09:15:56.981Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('92d085f4-2022-4ee9-9ebe-075f697f48f1', '5ad6bc14-36d1-4e93-b712-806f58dfe4c1', '7e3e93a1-32cb-4931-a3df-f7bc90abd991', 71378, 'negative', 'Patior impedit corona colo bibo debeo bis vaco tum.', '2024-08-17T12:40:34.908Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('472e6e64-cb51-4e96-9934-efcaa88ef35a', '894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', '8044dce0-6679-426f-9335-b5c002fef209', 8459, 'positive', 'Defetiscor texo fugiat utroque vorago ulciscor usitas vis cito. Tabgo voluptatibus virgo caries caveo sulum uterque thymbra defaeco.', '2024-08-09T21:15:57.180Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('7f885e55-8d4e-44c0-b5e7-5807c646e11b', '5fe704f1-a885-4d95-bab3-639503750f61', '0e98eb24-3c0a-44bd-9c6a-bc40e7b841b7', 11170, 'negative', 'Ventus anser voco deleo. Cupiditate corrumpo utrimque.', '2024-08-13T13:55:24.521Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('360436e0-f735-4e07-a563-f5af6a92dd31', 'e1b52554-e67a-4488-95b8-e13faf830852', '91c606eb-c2a4-44e2-9ee2-8ae25c9b0485', 95236, 'positive', 'Sui eum blandior.', '2024-08-14T10:15:53.939Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('66ab4d60-244c-4802-a814-5a7e666d8540', 'e39947d1-976b-4436-8b90-555ddc6e8891', 'ac8e8a50-bd4e-4053-8772-d2826683c29d', 72039, 'negative', 'Adulescens carmen admoneo vicissitudo abbas debilito tutamen solvo considero.', '2024-08-20T12:56:46.872Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('430ed465-47a0-40b4-b3e6-4b2aa07e2381', 'c576d48c-4c3a-418f-8fb7-23c1f488c536', 'eeedb312-c02c-4480-b6e4-7a3145cbb44a', 40051, 'positive', 'Defleo delinquo atavus timidus coma deprecator.', '2024-08-15T12:59:38.650Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('2c968b20-9cd5-4e52-b8b8-1287513efbae', '50ab8370-c757-42a7-881c-b44b3f79cc01', 'e18f1135-137c-4966-9883-881bd7cc3c0a', 1837, 'negative', 'Valetudo suscipit astrum tenax. Cometes vox totam altus.', '2024-08-19T05:50:24.249Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('bc9bf620-8709-41d7-a222-b2d660883743', '7d30f1e9-5998-4d54-b67f-aa8d7bd779e5', 'ff96307c-d5bb-4479-b43d-c400270d6f67', 96621, 'positive', 'Victoria vetus defetiscor arguo. Utpote talus terreo tot virgo aegre amoveo.', '2024-08-06T22:47:33.923Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('8b5e93de-0b65-448f-bb29-78436e9edeca', '0e98eb24-3c0a-44bd-9c6a-bc40e7b841b7', '6997eef9-2c6e-4792-90d0-68b66278121a', 75899, 'negative', 'Ustulo abeo adaugeo coepi pecus crux ultra.', '2024-08-21T01:55:44.097Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('9a40e11b-152f-4a96-bdaf-5b0c0f290889', 'ff96307c-d5bb-4479-b43d-c400270d6f67', 'f73af756-45a5-416d-963b-809bb43b4c02', 8169, 'positive', 'Vir aggero titulus. Vesco odit decumbo denuncio tergiversatio sonitus articulus calcar vis claro.', '2024-09-01T01:19:45.730Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('33aab087-6f34-48ef-b226-34a3e84f4a66', 'e18f1135-137c-4966-9883-881bd7cc3c0a', 'c821b7d3-8dd2-44ca-ad17-99c71cbd4d9c', 71916, 'negative', 'Inventore tepidus tempora vulgus solvo theologus ullam thalassinus totam ambulo.', '2024-08-29T13:33:02.030Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('993b5bd0-5c0f-46c2-830c-fef58e76028d', '819f196b-997c-46ff-8964-96b64e69be09', '3620f183-cb4d-4537-b5b3-9adb10e096c7', 97123, 'positive', 'Contabesco maiores tibi adimpleo tollo praesentium basium baiulus aer.', '2024-08-09T11:31:54.151Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('43cc83c4-8e01-4b87-b8e9-f5681a37b5ab', '37286d2d-a250-4058-afb1-7b7146d36107', 'dc71415e-330e-455d-85ff-ec432ad52862', 84841, 'negative', 'Tantum desidero tabernus decor dapifer.', '2024-08-12T06:24:36.482Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('877fab3e-e54f-479b-821d-1aaf8e17e4e4', '90968472-3852-4978-8112-557f11ec7e4d', '2715ef58-c273-4c9f-a24d-c70bac5f1b1c', 82524, 'positive', 'Aliquam clam doloremque bellicus cilicium. Usus valde ver tabernus.', '2024-08-02T19:26:57.229Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('eec158fe-a3f8-4834-93f1-e9160e4b0cb2', '6704b2a8-cc47-48df-b0b9-1c82d9031bbd', '2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', 55326, 'negative', 'Synagoga conqueror cornu mollitia. Voro error stips vilitas cinis thymbra sum vilitas sortitus vetus.', '2024-08-18T03:13:45.288Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('203f561b-dbb0-4f4f-93cf-ec19c930a254', '000cbabf-d423-4937-8272-a91097dae393', 'cb28b381-e3c1-4155-9e05-9339e5874184', 31066, 'positive', 'Summopere corona adsuesco.', '2024-08-19T06:27:02.019Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('a00b8ca0-564b-4a89-8925-576bf88ef53e', '894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', '6a96fd38-197e-47c7-8f88-e9d1451bb98a', 48093, 'negative', 'Cursus sperno demulceo usus cogito canto aeneus teneo.', '2024-09-01T14:37:53.298Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('a40c3205-ebb5-45ff-8d03-fad5bb9a9f7c', 'a6a05382-5b1a-4a8f-a851-119ccaf77f98', '26f198c8-ed62-4fc7-81c6-b191663aa8da', 10710, 'positive', 'Ipsa xiphias audacia vigilo thesis tenuis ultio delectatio audio. Comitatus verumtamen cura assentator.', '2024-08-30T22:53:26.315Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('7c8a356c-b9b2-4540-85a8-d05d45582b37', '30f64f29-7abd-42ad-a610-92f2b64e5d5e', '38812fa2-1f56-447a-b3a7-51cda4e6c075', 29233, 'negative', 'Utique sollicito cilicium perspiciatis. Custodia nobis cupio auctor.', '2024-08-06T11:23:37.907Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('219a6cc3-f48a-418d-86f9-3dbed94a9670', 'dc71415e-330e-455d-85ff-ec432ad52862', 'ab75d59a-650e-4768-a6fd-00272eaf98b2', 32128, 'positive', 'Defleo aeneus territo vigilo. Beatae vulgo sequi uredo quo vester strues.', '2024-08-17T08:22:14.329Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('dc25412d-aba6-4e44-90b2-d98c1ccf0ccc', '2fe7ec0d-de09-40de-90df-4a5a865e7457', '11bf0c4f-04e0-4327-96ef-44c3cd03028f', 55437, 'negative', 'Amo coerceo cura statua adimpleo accendo creptio. Cui subiungo paens sulum provident combibo ipsum.', '2024-08-17T08:32:39.926Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('b4b4954a-8fe7-445c-9dcf-73ac08c1a0c4', '5fe704f1-a885-4d95-bab3-639503750f61', '6704b2a8-cc47-48df-b0b9-1c82d9031bbd', 72819, 'positive', 'Substantia degenero demergo damnatio maxime adsuesco.', '2024-08-12T20:29:03.932Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('5f110b00-4609-4197-83c1-e998c7ba5a2f', 'eeedb312-c02c-4480-b6e4-7a3145cbb44a', '3620f183-cb4d-4537-b5b3-9adb10e096c7', 13991, 'negative', 'Molestiae tabernus arbitro aspicio cultellus.', '2024-08-24T11:33:35.936Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('daf7d798-c9f8-433d-880f-cee71a827117', '819f196b-997c-46ff-8964-96b64e69be09', '90968472-3852-4978-8112-557f11ec7e4d', 77810, 'positive', 'Viduo contabesco vulgivagus complectus depulso colo ait pauper degusto.', '2024-08-11T12:49:31.578Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('abe0680e-9e4d-4dfa-85f3-402692d63402', '133ffc07-3119-4c09-a793-f9f2bff49b64', '9f0397a9-c3fe-45bc-9a55-a2387e4bbdbe', 80100, 'negative', 'Cotidie ex condico quibusdam depereo territo. Tendo odio texo contabesco tibi suasoria laboriosam decerno.', '2024-08-03T10:23:31.286Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('7f5d4363-f280-423e-8948-b1d6b2ade10d', '70a57abc-bf59-4ac8-99e7-db839193fa1e', 'e4659d06-39b9-417a-a5c7-8c51522a48ea', 15291, 'positive', 'Tenax corroboro voro casus consuasor torqueo dapifer astrum temporibus.', '2024-08-12T01:25:57.177Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('e2944caf-b032-4087-a93d-75add3b63c39', 'e39947d1-976b-4436-8b90-555ddc6e8891', '56aa7ec4-2b39-48bf-a014-635cf7945fc4', 73659, 'negative', 'Autus caelestis defleo. Voveo bos turba nisi vinco.', '2024-08-03T22:52:12.333Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('afd91fbd-db17-4478-a8c2-35378becfd61', '9f0397a9-c3fe-45bc-9a55-a2387e4bbdbe', '6997eef9-2c6e-4792-90d0-68b66278121a', 18331, 'positive', 'Reprehenderit tenax minima cui depopulo sed adipiscor demulceo ventus.', '2024-08-06T19:00:17.517Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('4e51b271-f7df-479b-865a-37cfd584179e', '4e247196-9778-410b-a106-3295e7a8c223', 'e1b52554-e67a-4488-95b8-e13faf830852', 24559, 'negative', 'Voco arceo solum vulgus ager autem ventito aestivus. Aestas tego coepi calamitas.', '2024-08-04T08:16:11.536Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('6c4863a2-8bbd-4dd8-9855-dd3e6aff997f', '0e9a5bca-2473-4466-b882-663b4ec04603', '133ffc07-3119-4c09-a793-f9f2bff49b64', 72475, 'positive', 'Ipsam totus aer vestigium neque celer capitulus pectus autus commodi.', '2024-08-22T08:25:21.161Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('5647f241-54b2-4070-882a-6c8bab9cc33a', 'b2fa99af-d6ab-4f42-99c0-e42001c854a9', 'eeedb312-c02c-4480-b6e4-7a3145cbb44a', 18820, 'negative', 'Xiphias adopto calco statua voluptate advenio curto arbustum blandior ex. Valeo tendo vitium bene auctus velut.', '2024-08-26T03:45:32.876Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('ce9c7e6a-3e8e-4859-a13b-9e60c7112321', '7639bb07-14c8-49b8-b815-bec946340f63', '1b94f1eb-1690-41ab-afa9-4423f9a89a83', 32646, 'positive', 'Apparatus degenero sub cur aestas non vitae patrocinor. Tristis umquam crapula comes cui creo campana.', '2024-08-19T01:23:14.188Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('8dcd228f-d74c-429b-b135-a95daedf116b', '7e3e93a1-32cb-4931-a3df-f7bc90abd991', 'f39acdac-6cef-44f1-a0a2-7d6601463bf4', 10912, 'negative', 'Teneo distinctio speciosus contego suscipio corrigo tergeo tabula creo. Patrocinor cultellus asper adficio unde tandem sol sumptus depraedor.', '2024-08-28T07:00:49.958Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('e77c825d-7c18-4685-8067-6e80295f051f', '232d534c-9bd4-44bf-849e-0940ff0d8f3e', '6a96fd38-197e-47c7-8f88-e9d1451bb98a', 61509, 'positive', 'Magni creta subito anser vehemens tertius absens. Carcer vilis vilicus cenaculum solvo voluptatem omnis maxime.', '2024-08-07T07:42:12.122Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('309fffe4-43a5-41b3-9d7b-f13b2873e933', 'e96c56b0-fa4a-443c-aaf3-9f95bf409f8b', 'f73af756-45a5-416d-963b-809bb43b4c02', 23278, 'negative', 'Versus repellendus textus vociferor patruus libero curso dolorem tego addo. Collum acquiro certus charisma.', '2024-08-22T07:45:09.766Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('2027780a-292d-4baf-a953-088b37abffbd', 'c369cecb-905f-4c93-8a7c-6ebc4d938f51', '90968472-3852-4978-8112-557f11ec7e4d', 79262, 'positive', 'Succurro nobis sollicito unde thema cohibeo cresco causa alias. Abundans appello defero caveo.', '2024-08-07T21:53:10.464Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('f05ef5e4-cef8-4d37-82bc-9d5c8e27ae07', '442d962c-abed-402d-8ee6-14be6ebd74bd', 'eeedb312-c02c-4480-b6e4-7a3145cbb44a', 54005, 'negative', 'Turpis auxilium crinis.', '2024-08-09T02:50:07.744Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('ac9e2ef1-0953-4304-ab79-89087776689a', 'aba678d1-e6c4-48f9-939a-e58264ed0230', 'b2fa99af-d6ab-4f42-99c0-e42001c854a9', 24464, 'positive', 'Cotidie debitis argumentum credo cumque nihil.', '2024-08-02T18:24:56.890Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('365406a1-cde5-418a-b576-57ed14f87230', '7d30f1e9-5998-4d54-b67f-aa8d7bd779e5', '70a57abc-bf59-4ac8-99e7-db839193fa1e', 50157, 'negative', 'Sursum cenaculum sto tristis curatio modi abundans neque absum.', '2024-08-25T20:03:09.330Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('bc11a062-9e87-4828-9f0c-d8b958fdca6b', '56aa7ec4-2b39-48bf-a014-635cf7945fc4', 'ff96307c-d5bb-4479-b43d-c400270d6f67', 9308, 'positive', 'Comptus clarus commodo amor. Tristis soluta totam admitto temeritas comparo tergum sophismata possimus voluptate.', '2024-08-27T09:43:06.407Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('fc076c53-71fd-45ad-b73c-6328869e0e2d', 'cf4d3686-5356-418f-b16f-0a265a40080d', 'd66cb4b1-61ab-44b9-b431-2eaa04542320', 44519, 'negative', 'Facere tandem adiuvo sublime suscipio veritatis teneo.', '2024-08-24T19:45:30.914Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('39a0346c-3f83-403a-9079-94c649ae9536', '133ffc07-3119-4c09-a793-f9f2bff49b64', 'd7fcceab-cf1c-4ac8-804e-842c76f1c606', 88846, 'positive', 'Veniam varietas ciminatio cedo conor demum talio perspiciatis ultra vero.', '2024-08-14T14:30:15.353Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('36eac5da-096a-4d5f-8ca9-5e951b389d2b', '14973eb6-b77c-49b0-bd35-9bbb307bb52b', 'e4935ae6-f609-4044-aff4-3a5a6defd3d3', 52437, 'negative', 'Animi cibo certus video tamisium vitiosus. Sortitus asporto enim suscipio delibero ullam carus.', '2024-08-31T05:31:55.234Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('835246a8-bdd1-4aca-8cec-fccc8e1d4e2f', '6997eef9-2c6e-4792-90d0-68b66278121a', '000cbabf-d423-4937-8272-a91097dae393', 91482, 'positive', 'Ceno rem advoco cum omnis candidus caecus vulgivagus. Vulgaris vallum mollitia.', '2024-08-27T02:22:36.102Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('a294ba30-73c7-4270-9ec5-7f99e6c8e004', 'd665c01e-d750-4046-9428-8264715da6c0', '4e247196-9778-410b-a106-3295e7a8c223', 15336, 'negative', 'Custodia voluptate demo colo clam architecto. Contego substantia tristis infit deleniti solus pecus.', '2024-08-05T03:18:04.929Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('11b185cd-3924-4c96-8fd1-f7e7d2fa984b', 'f77c87aa-12b5-464a-8629-b607776f75f0', 'c821b7d3-8dd2-44ca-ad17-99c71cbd4d9c', 27941, 'positive', 'Spiritus comes solium.', '2024-08-27T00:27:17.376Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('289f4ee2-aba1-4a40-adbd-4e52b4728e02', '50ab8370-c757-42a7-881c-b44b3f79cc01', 'cf4d3686-5356-418f-b16f-0a265a40080d', 32654, 'negative', 'Synagoga aetas administratio appositus adficio dedico solio vito.', '2024-08-13T20:12:17.565Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('b6f14e19-090f-4c45-8c89-868c1fa3e2a5', 'e96c56b0-fa4a-443c-aaf3-9f95bf409f8b', 'e5ae947f-cd22-4c36-8410-17b88f2d4b54', 36623, 'positive', 'Vos catena cenaculum speciosus volaticus corrumpo sapiente vado deserunt consequuntur.', '2024-08-05T09:29:17.641Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('cf8a211a-c416-4aed-a6c5-dd494e5a52b5', 'e39947d1-976b-4436-8b90-555ddc6e8891', 'c576d48c-4c3a-418f-8fb7-23c1f488c536', 31000, 'negative', 'Pel virga tenuis cultura somniculosus esse est.', '2024-08-16T03:53:04.603Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('eab71774-b7dd-4982-bc58-ce2a036a17c5', '38812fa2-1f56-447a-b3a7-51cda4e6c075', '75f18662-bf58-4a4e-bf73-b05b6677cd3e', 84820, 'positive', 'Uxor iste sublime confido quos ascit. Cogo suggero basium venustas.', '2024-08-02T23:04:56.190Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('5c7fb30a-6b8c-44e1-b8d5-231866b6317f', '1263c5ad-7edc-46dd-8113-aeb222328767', '4e502c29-e850-483f-89d9-9d422bc359c2', 33853, 'negative', 'Assentator totidem conculco valens excepturi absum maxime delego. Vereor ut sumptus usitas accommodo turba admoneo.', '2024-08-23T08:43:01.336Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('3fea3be5-4cda-42f0-b63c-136429fd3953', 'a7058bc0-3700-4e70-a310-e1384942ca63', '3c967916-a4d0-4c24-9712-c96d4f45ad47', 97131, 'positive', 'Tres carmen cerno dedico catena universe cresco nam solium. Surculus auditor error sordeo at avarus.', '2024-08-29T19:50:26.484Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('c1fad1f5-576a-48a0-bc02-920556f968fb', 'c369cecb-905f-4c93-8a7c-6ebc4d938f51', 'd665c01e-d750-4046-9428-8264715da6c0', 68852, 'negative', 'Trans bellum iusto amissio amplexus abutor natus alter tergo.', '2024-08-22T00:29:15.986Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('915ec2ca-c3bc-43e8-92ab-9ad79a8dfba3', 'e1b52554-e67a-4488-95b8-e13faf830852', 'b2fa99af-d6ab-4f42-99c0-e42001c854a9', 37064, 'positive', 'Ager ubi voluntarius deleo uterque alioqui capto.', '2024-08-06T10:28:34.733Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('06f4026d-7ced-4396-8829-1678dd136f7e', 'c821b7d3-8dd2-44ca-ad17-99c71cbd4d9c', '8fe847fa-0a60-4d29-9920-570cec52bae9', 4710, 'negative', 'Benigne deprecator virtus sulum. Caritas averto caelum solium reiciendis uter angustus pauper thymbra.', '2024-08-25T08:35:36.013Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('32606d5a-3b4e-4964-a34f-dcbc53adb3d6', '91c606eb-c2a4-44e2-9ee2-8ae25c9b0485', '56aa7ec4-2b39-48bf-a014-635cf7945fc4', 11893, 'positive', 'Pecco adicio xiphias clementia commodo ipsam utique.', '2024-08-21T18:47:33.674Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('e7757292-2f4a-46fc-a752-9ddf8787a5d1', '70a57abc-bf59-4ac8-99e7-db839193fa1e', 'e345315e-bb59-4787-b0c9-29f69379c00e', 66933, 'negative', 'Cubitum ocer comitatus crustulum. In appello aptus compello.', '2024-08-10T08:18:47.585Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('36e8b4fd-bb53-4c71-baa6-96ef9eb61f84', '94bb1874-8092-4286-8252-f2f0066d68bb', '5f554356-f203-4cb4-820d-995d806f2469', 10433, 'positive', 'Eveniet colo viduo adipisci abutor minima.', '2024-08-14T12:37:27.689Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('2cfe50ff-fe43-47f1-896d-301d51b07b82', 'bedfc261-99bf-4f47-b9a4-2491a1147734', '6099e094-d434-4a62-85c7-50506e082577', 1406, 'negative', 'Animi tollo abundans chirographum vociferor expedita demulceo utpote tres surculus. Volva vereor decretum caute.', '2024-08-30T07:02:49.412Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('323141bd-4c43-4cd5-baa2-763bb6eb8891', 'b6283786-5ef5-4970-8e3b-2d341148e67a', 'c062042f-6446-4376-b543-d64d70eabc0d', 89458, 'positive', 'Adsuesco ceno demergo architecto amaritudo.', '2024-08-12T13:58:04.768Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('573333ff-b50a-4d24-b2d8-e92cc5b973f5', 'a478d17a-1b5e-4602-9520-15121bdb0317', '46fa3a47-9d5f-45b8-bc28-3c948029848e', 32847, 'negative', 'Iste reprehenderit taedium volubilis temperantia tego tepidus vehemens. Deficio depromo tabesco paulatim.', '2024-08-31T19:46:52.933Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('020fb12a-320e-49fc-955a-7b88c3828da9', '50ab8370-c757-42a7-881c-b44b3f79cc01', '91c606eb-c2a4-44e2-9ee2-8ae25c9b0485', 23246, 'positive', 'Derelinquo velum demonstro quibusdam mollitia adipisci alveus accusamus.', '2024-08-25T11:22:30.535Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('830b3abf-4449-48bf-b052-814bb0beba14', 'cb28b381-e3c1-4155-9e05-9339e5874184', 'a7058bc0-3700-4e70-a310-e1384942ca63', 84001, 'positive', 'Adulescens tactus argumentum quaerat denuo careo aetas condico velut. Supellex numquam tutamen totus vallum.', '2024-08-19T05:25:21.057Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('d69e76f9-4966-4129-bfc3-422b292c5f88', 'c062042f-6446-4376-b543-d64d70eabc0d', '1263c5ad-7edc-46dd-8113-aeb222328767', 21761, 'negative', 'Crepusculum thema strues adinventitias voro officia utique venia tergeo. Paulatim alius conspergo.', '2024-08-09T10:36:46.325Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('5219e730-a604-4660-ab80-820b881af4d3', '2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', '94bb1874-8092-4286-8252-f2f0066d68bb', 33379, 'positive', 'Derelinquo rem deduco teres tendo varietas vicissitudo antea tamdiu.', '2024-08-05T02:41:37.358Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('d6a361f6-1500-47b1-b541-664a1cd479f0', '05036186-cbf2-4ea7-b446-dc14447c88f1', '894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', 71595, 'negative', 'Animus cinis voluptatum qui.', '2024-08-17T09:44:46.789Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('6a4f34b5-e818-472b-a63e-e432143c4690', 'a26fac26-d1c6-4223-863a-f5e6ca9d6d2c', 'e345315e-bb59-4787-b0c9-29f69379c00e', 81858, 'positive', 'Cultellus constans valeo debitis admoveo ver alias vesica tardus.', '2024-08-08T00:26:09.998Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('fbd91f9c-d205-4393-b6a3-1f5673794fbc', '819f196b-997c-46ff-8964-96b64e69be09', '894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', 16133, 'negative', 'Laboriosam alo desparatus virga tamisium audax.', '2024-08-10T17:39:56.030Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('292159f3-73f2-4fcd-aab7-f43341a2ba62', 'e5ae947f-cd22-4c36-8410-17b88f2d4b54', '8fe847fa-0a60-4d29-9920-570cec52bae9', 20632, 'negative', 'Cursus copia umbra voro armarium statim timidus sol adfero.', '2024-08-22T05:26:53.397Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('9a1b7bfb-2ced-4d9d-b9ee-0123f85841b9', '2715ef58-c273-4c9f-a24d-c70bac5f1b1c', '996d2b57-51d8-4f34-b44b-12cae5d7b816', 49070, 'positive', 'Sodalitas clam ater copia convoco territo.', '2024-08-19T08:19:16.933Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('4fee2828-8fc7-480e-b254-bbf34ad24e7c', '8be08817-fd8b-465f-a436-50e8a2816d62', '1b94f1eb-1690-41ab-afa9-4423f9a89a83', 35929, 'negative', 'Usitas calculus usus subito. Earum voluptatem abscido terra ut vesco.', '2024-08-17T10:41:44.012Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('84f5e332-4fc9-40b5-84c7-c27883b62090', '37286d2d-a250-4058-afb1-7b7146d36107', '46fa3a47-9d5f-45b8-bc28-3c948029848e', 45075, 'positive', 'Absconditus censura venio inflammatio laborum vigor demoror verecundia cresco clamo. Ducimus tenax neque.', '2024-08-15T19:19:02.337Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('9baa9647-8e64-4fb5-989f-192e97765da8', '6704b2a8-cc47-48df-b0b9-1c82d9031bbd', 'f39acdac-6cef-44f1-a0a2-7d6601463bf4', 5934, 'negative', 'Aurum umerus viscus celebrer voro inflammatio cumque vulgivagus patior tunc.', '2024-08-13T01:15:00.456Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('1d9e59ac-3d2a-4324-b7a9-8b91a456a862', 'cb28b381-e3c1-4155-9e05-9339e5874184', '8be08817-fd8b-465f-a436-50e8a2816d62', 99685, 'positive', 'Veritas comprehendo ustulo spes thesis tenus.', '2024-08-16T05:23:11.869Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('77c98f0a-66c3-49ba-9ed3-c770ab0bb909', 'b2fa99af-d6ab-4f42-99c0-e42001c854a9', '5ad6bc14-36d1-4e93-b712-806f58dfe4c1', 20950, 'negative', 'Coma voluptatem curriculum nulla tego amor subnecto adflicto.', '2024-08-17T23:17:43.398Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('42c4a6f6-79dd-4075-9ec4-22a5f0d4ec88', '8be08817-fd8b-465f-a436-50e8a2816d62', '14973eb6-b77c-49b0-bd35-9bbb307bb52b', 25921, 'positive', 'Cursus studio demens vis. Cursim pax nihil vehemens natus cicuta.', '2024-08-25T22:04:07.811Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('699b59dd-0944-4c0b-b6da-e270e096b6e0', 'ac8e8a50-bd4e-4053-8772-d2826683c29d', '996d2b57-51d8-4f34-b44b-12cae5d7b816', 41435, 'negative', 'Turpis adipisci aspernatur audacia texo pecus clamo appositus adipisci stabilis.', '2024-08-10T16:28:59.111Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('b326742c-cac1-414c-8262-ad911b620a72', '30f64f29-7abd-42ad-a610-92f2b64e5d5e', '9ae90144-555a-4de6-9262-63a7f62cba92', 14314, 'positive', 'Ea quis talus facere suffragium caste. Cilicium patria asporto facere commemoro.', '2024-08-09T19:42:39.485Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('17f33700-8da3-4281-9f74-ebf037f92ab6', '4e502c29-e850-483f-89d9-9d422bc359c2', '14973eb6-b77c-49b0-bd35-9bbb307bb52b', 70322, 'negative', 'Tepidus acies cena dens solutio defendo volup. Repellendus decet velociter vulgivagus.', '2024-08-13T13:33:03.983Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('35a533cf-69c8-45a2-9af6-ec2a5a272cc4', '2c37c85f-db8f-4f9a-8e63-ab8cde11dc6e', 'd665c01e-d750-4046-9428-8264715da6c0', 61863, 'positive', 'Beatus expedita tollo. Veniam amor sequi repellat aestus spiculum succedo cena tergiversatio.', '2024-08-10T03:19:39.520Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('0da61cea-196f-4ead-9ea3-9674feb63196', 'b2fa99af-d6ab-4f42-99c0-e42001c854a9', '75f18662-bf58-4a4e-bf73-b05b6677cd3e', 95698, 'negative', 'Votum deorsum solvo volutabrum atque tabella.', '2024-08-24T20:28:32.144Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('7a953e02-f7b0-40b6-9b8f-4fb6ed68d6ea', 'a6a05382-5b1a-4a8f-a851-119ccaf77f98', '3c967916-a4d0-4c24-9712-c96d4f45ad47', 79866, 'positive', 'Rerum calco utique volutabrum voluptatum uterque laudantium vinculum ullus.', '2024-08-27T08:36:15.635Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('be457a5d-2822-4d60-91c5-ef55021979f1', '1b94f1eb-1690-41ab-afa9-4423f9a89a83', '67b465fa-495f-48ff-bde7-c6879d26a840', 62736, 'negative', 'Cometes tandem ter cubitum sed concedo stabilis umbra. Eaque adeptio solvo.', '2024-08-28T17:53:29.527Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('31d31dfa-255b-4d74-8065-9a0b9b7867bb', 'd86d6638-e3f2-4c18-a660-fdd7bcd48dee', '1263c5ad-7edc-46dd-8113-aeb222328767', 87057, 'positive', 'Stips tabesco defero.', '2024-08-13T11:32:35.460Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('0e34e320-a124-4718-990b-e6a4b5559161', 'f77c87aa-12b5-464a-8629-b607776f75f0', '6997eef9-2c6e-4792-90d0-68b66278121a', 49519, 'negative', 'Basium comes acidus aiunt dolorem. Strues audacia ullam utrum.', '2024-09-01T10:53:38.162Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('71ed3147-9381-47ec-be11-9a47f7542ff7', 'e4659d06-39b9-417a-a5c7-8c51522a48ea', 'd7fcceab-cf1c-4ac8-804e-842c76f1c606', 58339, 'positive', 'Ceno comparo accusantium aestivus cohors speciosus cognatus annus umerus. Curia accendo temeritas voluptate validus ustilo teres.', '2024-08-07T18:13:25.442Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('53c57de5-eabf-49ce-ba6b-42b1ae866087', '6704b2a8-cc47-48df-b0b9-1c82d9031bbd', 'ac8e8a50-bd4e-4053-8772-d2826683c29d', 25589, 'negative', 'Concedo suspendo deputo valens caries venia spero cognatus possimus. Advenio cupiditate temeritas aureus uberrime pectus cum aurum.', '2024-08-09T00:37:33.580Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('6beedc02-5c86-452b-909b-4614c5e8c85c', '1b94f1eb-1690-41ab-afa9-4423f9a89a83', '3cd2c8bf-8fd4-40ca-96e3-5e41dd52d8c7', 69592, 'positive', 'Vapulus aro subito audax spiculum fugiat deputo demitto iusto candidus.', '2024-08-25T16:54:59.199Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('49d47fd3-31a6-4e9d-98ac-1caeb5216730', '94bb1874-8092-4286-8252-f2f0066d68bb', '11bf0c4f-04e0-4327-96ef-44c3cd03028f', 20679, 'negative', 'Torrens cultellus vilis nisi cupressus reiciendis.', '2024-08-31T23:13:27.784Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('7b468023-80a5-4808-a95e-9b4362c8452f', '7e3e93a1-32cb-4931-a3df-f7bc90abd991', '307d9772-de85-4b2c-96c4-ba6731df86b8', 66789, 'positive', 'Calamitas venia curriculum textor crapula supra. Illum ager cilicium iure tamquam.', '2024-08-19T22:05:35.870Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('1c12578b-16d9-47b3-9fdd-90eefaa2ddb0', '133ffc07-3119-4c09-a793-f9f2bff49b64', '0e98eb24-3c0a-44bd-9c6a-bc40e7b841b7', 56892, 'negative', 'Sponte accusator denuncio claro amicitia sublime ventito odio. Ter conscendo abeo.', '2024-08-31T16:04:34.020Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('d2ab1185-36a6-4c3b-9b86-c0a5f30e9332', '307d9772-de85-4b2c-96c4-ba6731df86b8', 'e1b52554-e67a-4488-95b8-e13faf830852', 61547, 'positive', 'Appello deficio curis condico. Virga arma dolores sumptus sed vito.', '2024-08-23T05:37:04.267Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('df8ab019-b176-48df-ad80-57ed04b981e9', '92f02a3f-de88-4f6b-b93f-fadb1366255b', '732c8fa1-2036-4e4b-a210-411bbce9c9a7', 44020, 'negative', 'Blandior tabesco acquiro. Quia totidem auxilium ancilla timidus vilis conscendo vomica.', '2024-08-07T17:39:59.414Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('c36e71c6-756e-4657-a45c-2b3fba94191c', '2715ef58-c273-4c9f-a24d-c70bac5f1b1c', 'ac8e8a50-bd4e-4053-8772-d2826683c29d', 23820, 'positive', 'Videlicet consequuntur cedo degenero crux aspicio cotidie quo. Aer urbs consequatur apto nihil usitas damno atque.', '2024-08-22T02:09:20.854Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('689c2652-64da-4a78-a193-50dfe1e31882', '894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', '9ae90144-555a-4de6-9262-63a7f62cba92', 11932, 'positive', 'Modi iste summa sursum nesciunt doloremque video trepide antepono thorax.', '2024-08-25T23:19:10.010Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('bbf5b1fe-2b4f-4837-9d62-6fad59833666', 'd66cb4b1-61ab-44b9-b431-2eaa04542320', '3c967916-a4d0-4c24-9712-c96d4f45ad47', 82518, 'negative', 'Patior desino cuius voco tempus mollitia ait thalassinus.', '2024-08-21T00:35:27.855Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('54d042d4-0724-4c68-be58-0d156305dbca', '91c606eb-c2a4-44e2-9ee2-8ae25c9b0485', 'ab75d59a-650e-4768-a6fd-00272eaf98b2', 29095, 'positive', 'Aperiam abduco curia valens alter cupio adfero quod. Aut molestiae sed.', '2024-08-16T16:20:38.315Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('41b11dbe-a319-4e7b-a235-8dab6441596f', '996d2b57-51d8-4f34-b44b-12cae5d7b816', 'e4935ae6-f609-4044-aff4-3a5a6defd3d3', 59970, 'negative', 'Curia carmen depraedor tripudio suspendo reprehenderit tubineus consequatur certus.', '2024-08-14T09:54:30.539Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('af429e21-4cd3-49c1-9e98-c87af26f0ea2', '14973eb6-b77c-49b0-bd35-9bbb307bb52b', '94bb1874-8092-4286-8252-f2f0066d68bb', 78723, 'positive', 'Magnam qui vado volubilis theatrum terga audacia volo architecto magni. Centum asperiores soleo.', '2024-08-22T20:01:24.948Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('68f3c4a6-49f3-43e0-98a8-46f8cd8817ea', '67b465fa-495f-48ff-bde7-c6879d26a840', 'f39acdac-6cef-44f1-a0a2-7d6601463bf4', 57044, 'negative', 'Numquam cervus civis vesica cubitum alioqui corrumpo subito virga.', '2024-08-07T08:05:24.350Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('e8e952cf-9daf-4adc-9d15-39001d8c8da9', '442d962c-abed-402d-8ee6-14be6ebd74bd', '7d30f1e9-5998-4d54-b67f-aa8d7bd779e5', 21667, 'positive', 'Sonitus vilicus stips. Thesaurus aliquam cras at somniculosus adhaero.', '2024-08-11T08:38:20.310Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('d0d21c80-d77e-452b-a02d-87176835f8d5', 'a26fac26-d1c6-4223-863a-f5e6ca9d6d2c', '46fa3a47-9d5f-45b8-bc28-3c948029848e', 37520, 'negative', 'Aestas celo comburo verto. Socius aduro velociter apostolus.', '2024-08-13T18:48:33.321Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('f9da83bf-7590-44d2-9a0d-8736a208abc9', '818ffdc2-63a3-4c08-bd82-65b704eb3791', 'b2fa99af-d6ab-4f42-99c0-e42001c854a9', 66930, 'positive', 'Auctus concedo timidus quibusdam strues.', '2024-08-18T12:24:14.415Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('04520ad9-ec14-4649-a2a9-22a940cf115a', '2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', '818ffdc2-63a3-4c08-bd82-65b704eb3791', 19511, 'negative', 'Cedo argentum timidus exercitationem credo claustrum venia.', '2024-08-05T22:39:06.375Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('8c463a56-0ceb-4df6-baa8-c5b58d9c4765', '11a25c43-e483-4ae5-9839-841a85e9fa4d', '5f554356-f203-4cb4-820d-995d806f2469', 83660, 'positive', 'Autem usque truculenter alius virtus. Vox caste varietas depraedor crudelis accedo beatus depraedor a.', '2024-08-25T07:28:50.492Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('b4a93ecf-16fa-4838-a985-6dd03e5aca0f', '92f02a3f-de88-4f6b-b93f-fadb1366255b', 'f77c87aa-12b5-464a-8629-b607776f75f0', 46843, 'negative', 'Succedo candidus vito nulla cado triumphus suscipio.', '2024-08-25T12:55:18.458Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('840d2007-a993-4d4f-9130-3ee86bd28d57', '2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', '56aa7ec4-2b39-48bf-a014-635cf7945fc4', 47444, 'positive', 'Stillicidium umquam vulariter ultra creptio voluptate ubi. Sub contabesco conservo decretum degero odit textus.', '2024-08-16T07:27:46.814Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('e08294eb-9fcf-4d5d-9878-5133b8de9f3b', 'feea87a0-b84f-4c31-857d-371d26a75dac', 'cb28b381-e3c1-4155-9e05-9339e5874184', 94411, 'negative', 'Adaugeo voco summisse tumultus repellat verus synagoga colo demo.', '2024-08-11T16:21:40.129Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('3afdc915-5509-4bab-9285-19740a3a9ba6', '307d9772-de85-4b2c-96c4-ba6731df86b8', '11bf0c4f-04e0-4327-96ef-44c3cd03028f', 31648, 'positive', 'Campana admoveo argentum dolores aduro. Sit curo alo esse.', '2024-09-01T10:26:04.249Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('79d8a555-a72c-4bb2-a694-e3ac7ccbd10c', 'feea87a0-b84f-4c31-857d-371d26a75dac', 'dc71415e-330e-455d-85ff-ec432ad52862', 85100, 'negative', 'Utroque cura depereo atqui angustus.', '2024-08-12T20:57:21.157Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('b5087459-9c0f-4cd8-8e4e-e5731698a7c9', 'c062042f-6446-4376-b543-d64d70eabc0d', '7d30f1e9-5998-4d54-b67f-aa8d7bd779e5', 21275, 'positive', 'Vado bos supplanto conqueror. Audacia deleniti ambitus aduro triumphus venustas ars tantum utpote arbustum.', '2024-08-09T12:20:31.356Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('871a920e-1a67-4cac-a192-e83b6db3b857', 'f39acdac-6cef-44f1-a0a2-7d6601463bf4', 'e18f1135-137c-4966-9883-881bd7cc3c0a', 26135, 'negative', 'Assentator vox animadverto benevolentia abbas subseco suffoco canonicus. Sono ocer depulso absum conturbo tonsor comedo vaco sordeo asperiores.', '2024-09-01T05:52:56.257Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('062c95d2-2f91-4b3c-a66b-46f547b2faa5', '1263c5ad-7edc-46dd-8113-aeb222328767', 'e18f1135-137c-4966-9883-881bd7cc3c0a', 84343, 'positive', 'Tener blanditiis labore subito calcar comminor vobis. Absum rem volva acerbitas.', '2024-08-30T14:55:31.821Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('7497f125-889f-4712-940a-974e93adf0a0', '37286d2d-a250-4058-afb1-7b7146d36107', '894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', 49329, 'negative', 'Curtus attollo demonstro venio numquam soluta volo.', '2024-08-30T21:39:39.993Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('526ad3aa-c565-485d-b662-4da80b01f9c2', '14973eb6-b77c-49b0-bd35-9bbb307bb52b', '90968472-3852-4978-8112-557f11ec7e4d', 83403, 'positive', 'Umbra cupiditas degusto theca aegrus caterva absque.', '2024-08-09T06:18:47.732Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('6de8642b-b3bc-4fe9-b5e9-46c50699db84', '0e98eb24-3c0a-44bd-9c6a-bc40e7b841b7', '8be08817-fd8b-465f-a436-50e8a2816d62', 20662, 'negative', 'Demo tempus spes addo tertius spiritus curia. Amplitudo annus cattus coerceo venustas absorbeo arto.', '2024-08-26T23:13:33.375Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('159ad267-85b0-4bfe-b1b7-824eb072f837', '5fe704f1-a885-4d95-bab3-639503750f61', '37286d2d-a250-4058-afb1-7b7146d36107', 13311, 'positive', 'Vinco tardus creator bene amita arcus contego tepidus adficio. Articulus tenax vito cur.', '2024-08-13T22:13:18.442Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('7fd01483-c891-4971-8d7a-8887dd7f44f4', '3c967916-a4d0-4c24-9712-c96d4f45ad47', 'c821b7d3-8dd2-44ca-ad17-99c71cbd4d9c', 193, 'negative', 'Tener summisse termes quae tot.', '2024-08-20T12:40:31.010Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('061c616c-78fb-4194-be99-5039de29be89', '91c606eb-c2a4-44e2-9ee2-8ae25c9b0485', 'e345315e-bb59-4787-b0c9-29f69379c00e', 75109, 'positive', 'Ars vulnus acquiro odit stips derelinquo demitto apto ager.', '2024-08-07T10:23:22.113Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('fc1ec698-b67e-4e40-9fe6-0e7ca8d4623d', '46fa3a47-9d5f-45b8-bc28-3c948029848e', 'ae2cb809-9444-4bfa-8d82-e0adb2b4ee18', 11672, 'negative', 'Caute somniculosus curriculum quisquam. Delinquo inventore delectus sol rem decens adeptio cura est colo.', '2024-08-13T11:57:43.063Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('b057e6cd-06a2-4c73-81bb-c28507d27573', '8044dce0-6679-426f-9335-b5c002fef209', '50ab8370-c757-42a7-881c-b44b3f79cc01', 30054, 'positive', 'Vix aequus omnis. Taedium consectetur vox tredecim alter facilis altus.', '2024-08-26T20:36:15.031Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('300d0b6d-f89d-4593-8628-9cccd8926bab', 'f77c87aa-12b5-464a-8629-b607776f75f0', '05036186-cbf2-4ea7-b446-dc14447c88f1', 42938, 'negative', 'Cotidie torqueo acies acies quo tondeo volup tracto. Acidus depromo denego ratione.', '2024-08-22T18:47:28.999Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('ab0d0a86-a3ab-4ece-b3e3-c829f860346e', 'e345315e-bb59-4787-b0c9-29f69379c00e', 'a6a05382-5b1a-4a8f-a851-119ccaf77f98', 22270, 'positive', 'Vito virtus verbum. Adipiscor spiculum taceo suscipio.', '2024-08-09T22:44:41.778Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('71364a57-b633-4b87-aad9-a4fdbf386b04', '732c8fa1-2036-4e4b-a210-411bbce9c9a7', '56aa7ec4-2b39-48bf-a014-635cf7945fc4', 16374, 'negative', 'Voro bardus carus iure ver acerbitas arbitro. Eum patruus aranea ait summopere sodalitas ver collum iure porro.', '2024-08-17T19:31:24.492Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('2add57a7-7171-41b8-a57b-e790e61441ea', '05036186-cbf2-4ea7-b446-dc14447c88f1', 'd8c1b5e4-f94e-4b05-a8c7-17d86e2ad315', 7804, 'positive', 'In cum admoneo texo defessus terror universe veritas crapula.', '2024-08-22T05:55:32.822Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('e6fda061-75ce-43a2-8de3-b3fc7e6f35ed', '26f198c8-ed62-4fc7-81c6-b191663aa8da', '26680a6c-6827-4a0e-a8ce-c67f09bf7cbc', 80319, 'negative', 'Illum crustulum soleo nulla pauper ambitus trepide.', '2024-08-14T00:39:02.936Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('734ad8b2-9f13-42a5-9da9-879e9f4ba08c', '2715ef58-c273-4c9f-a24d-c70bac5f1b1c', '8be08817-fd8b-465f-a436-50e8a2816d62', 68390, 'positive', 'Cito rem verto tui spectaculum.', '2024-08-07T17:56:23.405Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('e32f76f5-a02a-4c53-80b2-bae8673f201e', 'e4935ae6-f609-4044-aff4-3a5a6defd3d3', '50e872f7-1238-40c4-acd8-d4f082ffb4f0', 70873, 'negative', 'Cultellus ater trado cognomen.', '2024-08-03T15:09:39.886Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('4eb837b8-0fac-4f16-b153-52154b0b9acc', '3620f183-cb4d-4537-b5b3-9adb10e096c7', '14973eb6-b77c-49b0-bd35-9bbb307bb52b', 49664, 'positive', 'Terreo infit magnam conforto dens sol adaugeo dolores vulticulus vinum. Torqueo conqueror censura thema patria curriculum arbor coaegresco cupiditate cena.', '2024-08-27T17:45:29.026Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('853e96b1-e887-496b-8e9b-fa68601d97d4', '30f64f29-7abd-42ad-a610-92f2b64e5d5e', '70a57abc-bf59-4ac8-99e7-db839193fa1e', 29017, 'negative', 'Necessitatibus quia defaeco accommodo tibi ager. Assentator tero depromo cervus agnosco tero odit sumptus commodo.', '2024-08-09T04:46:31.428Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('36679551-7d07-4cd4-9257-48388dc16d85', '46fa3a47-9d5f-45b8-bc28-3c948029848e', '24ac73f3-192e-424f-8d5c-dfade4d52883', 14707, 'positive', 'Antea cernuus caste utrum. Carpo aeternus tandem veritatis corporis adhuc aliqua.', '2024-08-06T00:09:27.905Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('6ee615cb-b305-43ac-8b01-4961f7217e88', 'd7fcceab-cf1c-4ac8-804e-842c76f1c606', '5fe704f1-a885-4d95-bab3-639503750f61', 49927, 'negative', 'Nobis nam aspicio vere creber aestus laudantium enim.', '2024-08-17T17:37:51.996Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('04a3dcbc-e45d-4168-b068-390263df9f84', '8be08817-fd8b-465f-a436-50e8a2816d62', 'e4659d06-39b9-417a-a5c7-8c51522a48ea', 10733, 'positive', 'Tenax somniculosus una paens eum venio urbanus.', '2024-08-05T18:05:52.484Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('0b07bbd1-5930-442e-807e-952ccf60c574', 'c369cecb-905f-4c93-8a7c-6ebc4d938f51', 'd66cb4b1-61ab-44b9-b431-2eaa04542320', 35011, 'negative', 'Recusandae impedit sollicito contra acies commodo.', '2024-08-22T16:44:12.368Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('f4878a17-df25-494f-a76b-bc34d6a13fa6', '70a57abc-bf59-4ac8-99e7-db839193fa1e', '37286d2d-a250-4058-afb1-7b7146d36107', 53197, 'positive', 'Commodo desparatus audentia.', '2024-08-16T14:28:18.410Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('27f479f8-40e2-4adf-b6cb-2784712d3bb8', '5f554356-f203-4cb4-820d-995d806f2469', '4fefac21-ad9e-4ebe-94d5-dd85579ba1b8', 59724, 'negative', 'Dedecor aspernatur uter defluo velum annus conservo sulum timidus auxilium. Adeptio atrox error tracto depopulo ullus combibo cohibeo addo delego.', '2024-08-28T21:07:20.390Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('ed2bdc60-7447-4427-9b86-226a52cd0ba7', 'feea87a0-b84f-4c31-857d-371d26a75dac', '6704b2a8-cc47-48df-b0b9-1c82d9031bbd', 59816, 'positive', 'Enim ager vulgus abbas bibo calamitas acidus angustus color. Alioqui decretum clam desparatus corrigo trucido acidus.', '2024-08-29T03:05:49.512Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('deb17f5d-a730-4826-aaac-dbea03aab44a', '90968472-3852-4978-8112-557f11ec7e4d', '000cbabf-d423-4937-8272-a91097dae393', 77725, 'negative', 'Comminor constans repudiandae voluptas comitatus creptio sumptus canto veniam appositus. Deorsum similique timidus admitto aeneus.', '2024-08-17T12:51:49.116Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('66bc5b99-99e0-410f-9061-4a79e413f155', '2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', 'c369cecb-905f-4c93-8a7c-6ebc4d938f51', 60464, 'positive', 'Sequi subito ulciscor dolorum capto compono turbo avarus conforto vobis. Uterque autus facere.', '2024-08-22T03:31:10.608Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('2ae1b96a-7eb3-413a-b36c-94699c90d1c5', '38812fa2-1f56-447a-b3a7-51cda4e6c075', 'a478d17a-1b5e-4602-9520-15121bdb0317', 86381, 'negative', 'Veritas laborum ratione alioqui conqueror. Adficio defleo stabilis illum angelus patruus.', '2024-08-21T01:37:54.363Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('1f62e835-0c06-41b6-ae89-bb735ee74da9', '4e247196-9778-410b-a106-3295e7a8c223', 'a7058bc0-3700-4e70-a310-e1384942ca63', 82171, 'positive', 'Abstergo cupiditate compono ab cado tergo tricesimus solium aperio uredo. Sordeo tempora damno ventito.', '2024-08-22T19:52:51.186Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('b6dbc2b6-e0e2-4138-aca7-2dfd12aba971', 'e39947d1-976b-4436-8b90-555ddc6e8891', '5f554356-f203-4cb4-820d-995d806f2469', 81230, 'negative', 'Abscido curtus ademptio desipio neque traho curriculum. Uberrime desolo thermae correptius aestivus tamquam a tandem eaque tremo.', '2024-08-03T21:04:08.778Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('92957a7b-ec0f-4407-95c6-4b19a6fd42d3', '5ad6bc14-36d1-4e93-b712-806f58dfe4c1', 'c062042f-6446-4376-b543-d64d70eabc0d', 84606, 'positive', 'Super candidus traho deleo subito stipes animi. Cauda cibo tribuo bis rerum utique crastinus desparatus doloribus dignissimos.', '2024-08-11T02:30:42.384Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('9fa6ce99-3709-4f52-af69-1b867235283b', 'a478d17a-1b5e-4602-9520-15121bdb0317', 'dc71415e-330e-455d-85ff-ec432ad52862', 74207, 'negative', 'Veniam umbra repudiandae sit auxilium spargo ad beatae balbus ventosus.', '2024-08-28T21:41:45.285Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('f521fa2a-9f63-493b-9354-74aece9b04a3', '000cbabf-d423-4937-8272-a91097dae393', 'c369cecb-905f-4c93-8a7c-6ebc4d938f51', 64812, 'positive', 'Adulescens caritas curtus sulum dicta verto amita.', '2024-08-04T13:40:49.671Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('98dfe0fe-7e09-4536-92a0-d5324eeede8c', 'd7fcceab-cf1c-4ac8-804e-842c76f1c606', 'd86d6638-e3f2-4c18-a660-fdd7bcd48dee', 3687, 'negative', 'Peior delego demo artificiose abeo capillus curatio perferendis carmen urbanus. Curso cupio perspiciatis consectetur timidus repellat tepesco.', '2024-09-01T10:40:20.080Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('b5932cd6-0f7e-4b80-8e32-221044659462', 'f77c87aa-12b5-464a-8629-b607776f75f0', 'f39acdac-6cef-44f1-a0a2-7d6601463bf4', 33465, 'positive', 'Cursus audio tandem sulum surculus audentia aranea sophismata.', '2024-08-03T20:53:25.985Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('6dfee053-0731-442d-9ab0-9976bdc50fc5', '1263c5ad-7edc-46dd-8113-aeb222328767', '26680a6c-6827-4a0e-a8ce-c67f09bf7cbc', 98655, 'negative', 'Ocer vitiosus aequitas suffragium utrum stabilis concido ulciscor. Adeo infit demoror cuppedia confido crapula vivo surculus.', '2024-08-09T13:42:03.981Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('5d7832af-fa9e-49fa-abda-cb0ff1fed8ef', '05036186-cbf2-4ea7-b446-dc14447c88f1', 'f39acdac-6cef-44f1-a0a2-7d6601463bf4', 95893, 'positive', 'Suasoria pecco avaritia aequitas. Thema tondeo usus tero votum vicissitudo absens clarus causa cinis.', '2024-08-11T13:53:40.272Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('32f01756-d87a-4ef4-a1b7-c249d4b3bf68', '732c8fa1-2036-4e4b-a210-411bbce9c9a7', '38812fa2-1f56-447a-b3a7-51cda4e6c075', 79811, 'negative', 'Amissio speciosus acceptus tubineus tamisium. Callide virga uxor adhuc.', '2024-08-29T04:08:10.695Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('16036924-52af-4b81-ac66-0e0a3604ca0e', 'e39947d1-976b-4436-8b90-555ddc6e8891', '7e3e93a1-32cb-4931-a3df-f7bc90abd991', 15601, 'positive', 'Sint urbanus id quam.', '2024-08-31T06:47:47.641Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('b90a18eb-5479-42b1-b890-a19b49a4b548', '46fa3a47-9d5f-45b8-bc28-3c948029848e', 'c369cecb-905f-4c93-8a7c-6ebc4d938f51', 1242, 'negative', 'Commodi facere adipisci adulescens tener. Ipsam incidunt thymum colo.', '2024-08-03T15:57:29.438Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('b7680532-c828-4d68-87cd-ac33829644f5', 'e4659d06-39b9-417a-a5c7-8c51522a48ea', 'e345315e-bb59-4787-b0c9-29f69379c00e', 39612, 'positive', 'Cubicularis deprimo arx absens alienus audentia consuasor cenaculum. Creta adeptio deinde clementia demum unus magnam patior iure adficio.', '2024-08-16T12:01:58.208Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('80c87060-4543-4344-b073-7ae2fc2c031a', '5ad6bc14-36d1-4e93-b712-806f58dfe4c1', 'bedfc261-99bf-4f47-b9a4-2491a1147734', 84424, 'negative', 'Cernuus astrum verbum est. Ullam cultellus cum curriculum terga.', '2024-08-06T01:01:40.728Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('ebfcd377-c2a5-4d21-ac97-460da5bbb57d', 'e1b52554-e67a-4488-95b8-e13faf830852', '6099e094-d434-4a62-85c7-50506e082577', 90381, 'positive', 'Voveo amo thorax aurum iure coadunatio canis crudelis tonsor brevis. Sapiente trucido maxime delectus.', '2024-08-28T00:16:17.695Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('e5cd3925-3e7d-47f1-ac6e-05883adf4188', 'e4935ae6-f609-4044-aff4-3a5a6defd3d3', '232d534c-9bd4-44bf-849e-0940ff0d8f3e', 7536, 'negative', 'Ascit pel trado tempora usitas.', '2024-08-29T19:24:17.672Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('b0afc38f-13e6-4e88-9466-32f4f86b4b0f', 'ae2cb809-9444-4bfa-8d82-e0adb2b4ee18', 'e1b52554-e67a-4488-95b8-e13faf830852', 48706, 'positive', 'Volo reprehenderit eum vergo eius natus derelinquo cresco toties tyrannus.', '2024-08-10T13:44:23.632Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('79d5bc2d-1f2c-49d8-ab79-99dfe702ea9a', '3cd2c8bf-8fd4-40ca-96e3-5e41dd52d8c7', 'a7058bc0-3700-4e70-a310-e1384942ca63', 82691, 'negative', 'Adopto adficio libero sit creta pecto alter aliquam demitto curriculum. Vespillo conscendo bonus ter ustulo id condico ambitus.', '2024-08-16T14:23:40.310Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('f9fd4cf9-747a-440e-9706-d9769df6f227', '133ffc07-3119-4c09-a793-f9f2bff49b64', 'feea87a0-b84f-4c31-857d-371d26a75dac', 3466, 'positive', 'Somniculosus arma volubilis dens. Adsuesco utrimque cuppedia ceno vestigium.', '2024-08-30T04:28:08.765Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('11905abd-c255-45dc-a19d-fad2c03414f3', '05036186-cbf2-4ea7-b446-dc14447c88f1', 'c369cecb-905f-4c93-8a7c-6ebc4d938f51', 18450, 'negative', 'Cohors minima thema vere denique. Veritatis saepe conventus absque minus combibo.', '2024-08-30T06:30:45.619Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('8b109f57-fd9d-402a-9557-c2aefc5bf14c', 'e39947d1-976b-4436-8b90-555ddc6e8891', 'e18f1135-137c-4966-9883-881bd7cc3c0a', 4558, 'positive', 'Varius vito versus. Conitor voveo fuga vilitas infit deprimo defetiscor blandior vesper theologus.', '2024-08-27T16:54:51.594Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('fa58659e-cc45-484f-8f4d-58c078d16eed', 'b2fa99af-d6ab-4f42-99c0-e42001c854a9', '2c37c85f-db8f-4f9a-8e63-ab8cde11dc6e', 71210, 'negative', 'Solus desolo ait aufero delego depromo patruus vilitas balbus abstergo.', '2024-08-31T06:34:37.775Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('c4a95d61-f07d-44a0-b3a2-88be1fc3e003', 'dc71415e-330e-455d-85ff-ec432ad52862', '7e3e93a1-32cb-4931-a3df-f7bc90abd991', 8436, 'positive', 'Defendo suscipit despecto.', '2024-08-22T23:07:20.248Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('14ac3544-6314-40fb-ab2e-32fddee51057', 'd665c01e-d750-4046-9428-8264715da6c0', 'c821b7d3-8dd2-44ca-ad17-99c71cbd4d9c', 54226, 'negative', 'Laboriosam degero candidus. Temptatio tantum corona depromo conitor ascit catena curso aer.', '2024-08-23T00:50:22.323Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('b4f77e2a-eb0e-46a1-9e2d-ff1a4742ba21', '11bf0c4f-04e0-4327-96ef-44c3cd03028f', '7e3e93a1-32cb-4931-a3df-f7bc90abd991', 96309, 'positive', 'Tot demulceo conduco concedo volva. Adsidue aestas testimonium demoror nesciunt absque.', '2024-08-31T06:21:58.530Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('ed37f19c-f39a-475a-bfc5-bff4496c8514', '2715ef58-c273-4c9f-a24d-c70bac5f1b1c', 'e39947d1-976b-4436-8b90-555ddc6e8891', 24479, 'negative', 'Libero ullam vero. Celer sto blanditiis.', '2024-08-27T06:41:28.877Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('28d13463-39c9-45b4-a006-12c59fa18c25', '9f0397a9-c3fe-45bc-9a55-a2387e4bbdbe', 'c062042f-6446-4376-b543-d64d70eabc0d', 43339, 'positive', 'Ciminatio ultra paulatim civis curvo auctus audentia textilis decerno.', '2024-08-26T08:18:12.539Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('26e34a8c-50f7-48a9-99e9-32bf870e4286', 'bedfc261-99bf-4f47-b9a4-2491a1147734', '5ad6bc14-36d1-4e93-b712-806f58dfe4c1', 39418, 'negative', 'Doloribus cupio cimentarius praesentium. Tametsi talus temporibus delectus terreo cervus desipio.', '2024-08-16T14:03:06.137Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('aff2fa53-f050-466f-8423-ee6cf63da882', '56aa7ec4-2b39-48bf-a014-635cf7945fc4', '0e98eb24-3c0a-44bd-9c6a-bc40e7b841b7', 87522, 'positive', 'Vespillo repudiandae denego canis tutamen.', '2024-08-09T07:26:10.975Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('72744574-16fa-4042-af8f-c58b0bb1a7ec', '232d534c-9bd4-44bf-849e-0940ff0d8f3e', '26680a6c-6827-4a0e-a8ce-c67f09bf7cbc', 8925, 'negative', 'Comburo nulla sustineo contra supellex utrimque labore teres. Vulariter perferendis debitis caste suppellex clamo.', '2024-08-06T17:14:40.254Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('cade4185-ea43-4bfe-bdaf-ec597f236b93', 'dc71415e-330e-455d-85ff-ec432ad52862', '3c967916-a4d0-4c24-9712-c96d4f45ad47', 92365, 'positive', 'Civitas accommodo stips cras bonus possimus ager demo virtus. Strenuus vulgivagus culpa velociter temeritas occaecati cupiditate caries comitatus cogo.', '2024-08-13T01:20:03.237Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('6102882c-bc37-4239-a864-900bd379ffb3', '7639bb07-14c8-49b8-b815-bec946340f63', '26f198c8-ed62-4fc7-81c6-b191663aa8da', 46231, 'negative', 'Decumbo cruentus cunae arbustum.', '2024-08-17T16:13:58.720Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('f09720cd-51ae-42f4-9a59-a6a8c3c3b98e', '64af3593-2a87-4c5b-bc96-0f1f38bc7455', 'ac8e8a50-bd4e-4053-8772-d2826683c29d', 26669, 'positive', 'Tego somnus abeo voluptate. Pauper coruscus ara concido.', '2024-08-02T18:37:59.725Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('c25b4987-90c5-47f4-ba98-78b67437db1b', 'cf4d3686-5356-418f-b16f-0a265a40080d', 'ab75d59a-650e-4768-a6fd-00272eaf98b2', 15530, 'negative', 'Contego adsidue sustineo vespillo.', '2024-08-04T17:05:20.984Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('b69b9c80-e9ec-412e-ad45-4f7974e6517c', '4e502c29-e850-483f-89d9-9d422bc359c2', 'ff96307c-d5bb-4479-b43d-c400270d6f67', 70623, 'negative', 'Denuncio antiquus terga confero repudiandae deripio crepusculum urbs. Ulterius spoliatio condico cattus timidus ante.', '2024-08-28T11:34:55.399Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('99010818-5447-4bf5-90e5-448152bec061', '8fe847fa-0a60-4d29-9920-570cec52bae9', 'a26fac26-d1c6-4223-863a-f5e6ca9d6d2c', 28441, 'positive', 'Trepide corporis clibanus blanditiis adopto vaco. Suasoria approbo sortitus universe tutamen apto.', '2024-08-19T15:40:58.979Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('592c918c-3728-46be-8f17-e41ae5f27f6b', '2715ef58-c273-4c9f-a24d-c70bac5f1b1c', '94bb1874-8092-4286-8252-f2f0066d68bb', 40394, 'negative', 'Umbra utrimque truculenter strenuus laboriosam.', '2024-08-18T00:25:31.362Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('48efa32d-6004-460c-b4d2-53e9dbf584fc', '2b24b3c5-cda0-44fc-bbe7-658e1a8c0b8f', '50ab8370-c757-42a7-881c-b44b3f79cc01', 21701, 'positive', 'Tubineus adsum suppono canis. Derideo supra defendo tego appello voluptatibus.', '2024-08-08T12:03:00.215Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('4ac3dc1e-34ec-4196-a234-e82fb13e3db6', '5f554356-f203-4cb4-820d-995d806f2469', 'ae2cb809-9444-4bfa-8d82-e0adb2b4ee18', 86557, 'negative', 'Xiphias minus vulariter absque vulgo quibusdam summisse aureus aliquam.', '2024-08-05T14:06:55.367Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('ab6981ad-5ada-4172-888e-63826b549ee7', '50ab8370-c757-42a7-881c-b44b3f79cc01', '30f64f29-7abd-42ad-a610-92f2b64e5d5e', 35585, 'positive', 'Surculus cito animadverto abundans est voluptas attero illum arca ratione. Vilicus coruscus conventus adulescens deorsum adsum atrox dignissimos vesica adsidue.', '2024-08-13T08:35:54.126Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('887bd6e6-f73b-40b1-8133-4e156d616623', 'f73af756-45a5-416d-963b-809bb43b4c02', '3cd2c8bf-8fd4-40ca-96e3-5e41dd52d8c7', 77429, 'negative', 'Canto averto adfero praesentium deprecator. Cariosus explicabo sursum pecus coma carbo comparo.', '2024-08-06T21:40:21.037Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('3f9d30b0-d30a-479e-ac48-c67216837adb', '70a57abc-bf59-4ac8-99e7-db839193fa1e', 'ae2cb809-9444-4bfa-8d82-e0adb2b4ee18', 45605, 'positive', 'Utrum strenuus allatus sonitus libero cohibeo. Porro terebro deleo cui curis cervus terebro explicabo.', '2024-08-17T05:59:33.428Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('79d6fdc2-af06-434a-8bd6-8848d8a1bcae', '818ffdc2-63a3-4c08-bd82-65b704eb3791', '46fa3a47-9d5f-45b8-bc28-3c948029848e', 35805, 'negative', 'A aveho tempore armarium repellat temeritas molestias in. Catena agnitio doloribus.', '2024-08-28T19:37:42.059Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('8bf03c65-be9b-40f0-b98e-4081b700ab0c', 'e1b52554-e67a-4488-95b8-e13faf830852', '70a57abc-bf59-4ac8-99e7-db839193fa1e', 25076, 'positive', 'Tempore sollicito recusandae cotidie vesica cursus consectetur omnis.', '2024-08-13T12:12:56.755Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('6effb3fe-2a6a-4dac-8a7d-d2021616c73e', '2fe7ec0d-de09-40de-90df-4a5a865e7457', '2c37c85f-db8f-4f9a-8e63-ab8cde11dc6e', 10893, 'negative', 'Terra suffragium damno calco deinde. Fugit terra utique cubicularis aer victus.', '2024-08-28T22:03:00.372Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('469fbe08-3c8f-4b81-a8dc-3d8aff2222cd', 'd7fcceab-cf1c-4ac8-804e-842c76f1c606', 'a6a05382-5b1a-4a8f-a851-119ccaf77f98', 49535, 'positive', 'Sustineo civitas spiculum capillus adeptio suus certe terminatio approbo aptus. Atrocitas corrumpo cornu veniam cuppedia alter cursus alter.', '2024-08-23T05:15:44.238Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('57a80411-551c-4684-85db-560137d79a64', '6997eef9-2c6e-4792-90d0-68b66278121a', '11a25c43-e483-4ae5-9839-841a85e9fa4d', 77360, 'negative', 'Sapiente debeo dicta appello sumptus. Vilitas corporis correptius.', '2024-08-21T06:37:52.333Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('4c5378fa-0848-44ff-bb23-0ee859c99a00', '8044dce0-6679-426f-9335-b5c002fef209', '3c967916-a4d0-4c24-9712-c96d4f45ad47', 45668, 'positive', 'Solvo adsum cui vis sto neque. Sto virtus apto solutio denego solium praesentium demergo alo.', '2024-08-06T23:04:46.948Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('af5c2b18-36a6-444d-9d22-824785afadf1', '4e502c29-e850-483f-89d9-9d422bc359c2', '307d9772-de85-4b2c-96c4-ba6731df86b8', 91399, 'negative', 'Antepono attonbitus adhuc contra dolor vado communis laboriosam denego. Terreo clamo articulus ager dolorem vix sed arbitro.', '2024-08-10T21:29:23.774Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('37530b25-b756-4a3c-bb34-0af5531fa998', '8044dce0-6679-426f-9335-b5c002fef209', '000cbabf-d423-4937-8272-a91097dae393', 20833, 'positive', 'Cubitum aetas solitudo eaque adinventitias varietas vindico veniam.', '2024-08-03T14:09:00.348Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('1cc8316f-ce5d-4afb-ad5b-1d7c7d2b0e96', '4e502c29-e850-483f-89d9-9d422bc359c2', '4e247196-9778-410b-a106-3295e7a8c223', 76309, 'negative', 'Vero amplexus ustulo.', '2024-08-03T16:08:36.828Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('e5aecdf1-d6a2-477e-a488-655a2a21e335', '894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', '24ac73f3-192e-424f-8d5c-dfade4d52883', 87530, 'positive', 'Creator subvenio crebro caecus tutamen tollo atqui denego molestias.', '2024-08-26T01:47:29.335Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('eb0cf7ee-3171-48fe-9c3b-62c5b44e98f3', '50ab8370-c757-42a7-881c-b44b3f79cc01', '8fe847fa-0a60-4d29-9920-570cec52bae9', 13826, 'negative', 'Totam virga subito volva ustilo attero perspiciatis.', '2024-09-01T13:53:05.508Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('7de8d183-c807-438f-a59f-56324b485d35', 'e18f1135-137c-4966-9883-881bd7cc3c0a', 'e4659d06-39b9-417a-a5c7-8c51522a48ea', 32099, 'positive', 'Aegrus veritatis claudeo dignissimos cubo uter. Tonsor capto velum.', '2024-08-03T11:07:53.787Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('1a596bfb-bd6b-46bd-b7fb-9fed58ff9d6c', '2c37c85f-db8f-4f9a-8e63-ab8cde11dc6e', '5fe704f1-a885-4d95-bab3-639503750f61', 15159, 'negative', 'Adeo studio dolore vociferor textilis.', '2024-08-29T13:24:22.189Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('21968ab3-99ad-405f-97ba-46fbd8890d18', '5ad6bc14-36d1-4e93-b712-806f58dfe4c1', 'e345315e-bb59-4787-b0c9-29f69379c00e', 52598, 'positive', 'Valde acsi crudelis conicio animus facilis aestus amita paulatim sub.', '2024-08-18T21:30:59.325Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('f6077752-b586-4956-84d6-59270ad32a7b', '30f64f29-7abd-42ad-a610-92f2b64e5d5e', 'e18f1135-137c-4966-9883-881bd7cc3c0a', 13217, 'negative', 'Accedo vitae a. Aufero canto culpo cribro virtus.', '2024-08-29T16:28:20.173Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('ddedf20b-04dd-4a05-acf8-cd14b3ec30e7', '819f196b-997c-46ff-8964-96b64e69be09', '1b94f1eb-1690-41ab-afa9-4423f9a89a83', 24058, 'positive', 'Ater trepide sollicito vindico unus at suffragium repellat super veritatis.', '2024-08-16T22:30:56.651Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('f3b42071-f98a-4ae3-9e3d-53206a430eca', '75f18662-bf58-4a4e-bf73-b05b6677cd3e', 'b2fa99af-d6ab-4f42-99c0-e42001c854a9', 87494, 'negative', 'Asperiores agnitio ocer virga timor tonsor demo audio solitudo arma.', '2024-08-17T22:59:55.672Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('d1b09091-bb50-4af1-87a8-0eb041e310bb', '5f554356-f203-4cb4-820d-995d806f2469', 'd72ad16a-5ded-487c-877d-3851491634ac', 9151, 'positive', 'Uter vito virtus.', '2024-08-12T06:43:20.649Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('1df3a859-28ba-4461-a7a9-f03af1e1eedf', '5f554356-f203-4cb4-820d-995d806f2469', '6704b2a8-cc47-48df-b0b9-1c82d9031bbd', 52247, 'negative', 'Tego vulariter volva demulceo unde articulus. Degero succedo absque trucido videlicet.', '2024-08-16T23:57:26.263Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('2175b3cc-bcf8-4831-a9c9-f391ad8b2fe5', '000cbabf-d423-4937-8272-a91097dae393', 'e345315e-bb59-4787-b0c9-29f69379c00e', 50389, 'positive', 'Temperantia temperantia casus delego verbera. Nihil animus venia suadeo autem absorbeo amplitudo demum fuga.', '2024-08-30T11:18:32.484Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('3d85830d-74c5-4d67-b462-551f7df2c3a4', 'cf4d3686-5356-418f-b16f-0a265a40080d', 'a26fac26-d1c6-4223-863a-f5e6ca9d6d2c', 25253, 'negative', 'Cicuta calco amplitudo adficio substantia argumentum verbera advenio.', '2024-08-18T08:58:38.990Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('8c6f274a-e18e-4eaf-a989-c774e40f3f04', 'c821b7d3-8dd2-44ca-ad17-99c71cbd4d9c', 'a6a05382-5b1a-4a8f-a851-119ccaf77f98', 47249, 'positive', 'Agnitio doloribus similique creber terreo thorax.', '2024-08-15T13:03:16.244Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('775a6318-588a-4b29-ba10-af0f5cf7a52c', '46fa3a47-9d5f-45b8-bc28-3c948029848e', '9f0397a9-c3fe-45bc-9a55-a2387e4bbdbe', 33465, 'negative', 'Ager alter consequatur libero abundans. Bonus vox suffoco creator truculenter balbus unus studio stella vox.', '2024-08-29T01:46:42.886Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('4a6217b0-5528-42d2-8fb5-48271c602b48', '3c967916-a4d0-4c24-9712-c96d4f45ad47', '000cbabf-d423-4937-8272-a91097dae393', 76627, 'positive', 'Arma tenus succurro quasi venio confugo colo caute. Tamdiu cresco amitto.', '2024-08-04T21:01:15.510Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('478b5be3-df93-4949-b27a-5fe39edffc39', 'd8c1b5e4-f94e-4b05-a8c7-17d86e2ad315', 'e96c56b0-fa4a-443c-aaf3-9f95bf409f8b', 64107, 'negative', 'Vinitor statua ab demitto tener et laudantium. Vilitas abscido allatus arceo.', '2024-08-28T10:12:13.484Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('ac1bcd2a-0161-4580-ab93-b759d8a6bb00', '1263c5ad-7edc-46dd-8113-aeb222328767', '307d9772-de85-4b2c-96c4-ba6731df86b8', 2861, 'positive', 'Fuga accusamus ater textor centum crinis conturbo aegrus.', '2024-08-02T21:33:01.946Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('9c19ef90-2b6a-4e56-8f94-144692afd0f8', '894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', '4e247196-9778-410b-a106-3295e7a8c223', 58787, 'negative', 'Consectetur ter distinctio pauper. Thermae creo impedit delibero caute desidero eos.', '2024-08-07T22:59:17.145Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('4318c83e-27ef-4530-9bfb-b8bf7af37ac2', '14973eb6-b77c-49b0-bd35-9bbb307bb52b', '6997eef9-2c6e-4792-90d0-68b66278121a', 13565, 'positive', 'Explicabo comitatus volva undique. Sopor acquiro patria auctor creber cito aequitas.', '2024-08-19T16:42:19.432Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('305d6b43-89b1-4db3-97b6-c723fbd487e8', 'dc71415e-330e-455d-85ff-ec432ad52862', 'f39acdac-6cef-44f1-a0a2-7d6601463bf4', 46834, 'negative', 'Dapifer textor tum depulso. Statim voveo veritas cicuta condico infit numquam tantillus.', '2024-08-27T19:24:51.118Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('e5a1e1c2-8432-4342-87e8-82a8e9d69d8a', 'd7fcceab-cf1c-4ac8-804e-842c76f1c606', 'e1b52554-e67a-4488-95b8-e13faf830852', 93172, 'positive', 'Trado curtus similique spiritus.', '2024-08-07T04:08:33.466Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('a03eb02e-00b3-42ca-861a-ee60dc6b1b1d', 'c576d48c-4c3a-418f-8fb7-23c1f488c536', '6997eef9-2c6e-4792-90d0-68b66278121a', 4509, 'negative', 'Videlicet vespillo circumvenio articulus adstringo subseco adopto advoco aveho. Caelum desidero thymum nisi acidus arbor ocer thalassinus candidus.', '2024-08-20T23:31:37.674Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('122e74cb-d2d0-4da0-b3ae-57795667b83d', '7e3e93a1-32cb-4931-a3df-f7bc90abd991', 'feea87a0-b84f-4c31-857d-371d26a75dac', 39073, 'positive', 'Tubineus dolores casso barba volaticus uxor socius. Tener tergo degero conforto adimpleo aer aedificium.', '2024-08-10T05:47:28.042Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('ef1bf73c-ce38-4b19-91ea-1c771788e4d6', 'e96c56b0-fa4a-443c-aaf3-9f95bf409f8b', '7d30f1e9-5998-4d54-b67f-aa8d7bd779e5', 39281, 'negative', 'Agnosco approbo vomito vinitor. Degusto vis adsum desino sursum vapulus temporibus aduro curis alius.', '2024-08-13T06:30:01.932Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('af90ed15-cb43-44a2-afd1-a5c664141100', '3cd2c8bf-8fd4-40ca-96e3-5e41dd52d8c7', 'a478d17a-1b5e-4602-9520-15121bdb0317', 98812, 'positive', 'Coepi architecto decerno ceno velociter adulatio terreo ab iusto crur.', '2024-08-07T15:44:32.626Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('377e3143-fe61-485d-af5c-872d8d36474f', '2fe7ec0d-de09-40de-90df-4a5a865e7457', 'f77c87aa-12b5-464a-8629-b607776f75f0', 92651, 'negative', 'Amita clarus degero.', '2024-08-29T19:50:20.243Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('661f66ec-74ba-4541-9c30-4bbcc3995134', '9f0397a9-c3fe-45bc-9a55-a2387e4bbdbe', 'c576d48c-4c3a-418f-8fb7-23c1f488c536', 60081, 'positive', 'Cicuta volo decipio laudantium capto arx amita stella. Vesica vulariter credo tabella triumphus cibus.', '2024-08-22T13:53:44.884Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('d3e51abc-b3de-415b-937b-322e23110615', '4e502c29-e850-483f-89d9-9d422bc359c2', 'a6a05382-5b1a-4a8f-a851-119ccaf77f98', 30407, 'negative', 'Umerus appositus certus vorax.', '2024-08-30T22:43:26.719Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('bdc0d1a7-9f6b-46d5-a386-1ef818545201', '05036186-cbf2-4ea7-b446-dc14447c88f1', '56aa7ec4-2b39-48bf-a014-635cf7945fc4', 81878, 'positive', 'Anser solus creptio.', '2024-08-23T12:58:59.196Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('44d0616b-4b8c-4767-91a5-67c9c59bf56d', '8fe847fa-0a60-4d29-9920-570cec52bae9', '732c8fa1-2036-4e4b-a210-411bbce9c9a7', 34089, 'negative', 'Deorsum vomito cui vulariter sollers soleo dicta amaritudo vaco. Corporis tres auxilium ascit impedit auditor abscido coniecto demitto.', '2024-08-12T12:01:00.173Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('d1b2d1d4-85bf-4af0-ae6a-f97d9747ce27', 'f39acdac-6cef-44f1-a0a2-7d6601463bf4', 'e4935ae6-f609-4044-aff4-3a5a6defd3d3', 76976, 'positive', 'Allatus tabula administratio terra vicinus sordeo autem.', '2024-08-03T18:20:03.255Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('36a4ae0a-d2a0-4aa5-9804-c891c1dec35d', 'c369cecb-905f-4c93-8a7c-6ebc4d938f51', 'a6a05382-5b1a-4a8f-a851-119ccaf77f98', 18285, 'negative', 'Ocer ventus impedit tamisium coerceo sapiente suppono spero ancilla.', '2024-08-24T00:19:52.151Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('1e74bb78-0ea6-49f5-b1a2-ab7a5a636117', 'd8c1b5e4-f94e-4b05-a8c7-17d86e2ad315', '14973eb6-b77c-49b0-bd35-9bbb307bb52b', 36317, 'positive', 'Tenax arbor abundans suspendo delego demergo.', '2024-08-13T18:53:17.881Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('024b070d-3898-40f3-996f-184cf155fc7c', '7e3e93a1-32cb-4931-a3df-f7bc90abd991', '894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', 90236, 'negative', 'Sperno sunt tot vere atque dedico apostolus occaecati voco. Temporibus cenaculum coruscus.', '2024-08-13T16:38:08.722Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('08e427a6-bcc9-4fe1-ac41-3db4155902a6', '90968472-3852-4978-8112-557f11ec7e4d', '3c967916-a4d0-4c24-9712-c96d4f45ad47', 80304, 'positive', 'Vivo alter caelestis debeo sint armarium.', '2024-08-18T09:04:45.512Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('0f2f4077-52a8-4f5c-ae73-a4d01cff974c', '6a96fd38-197e-47c7-8f88-e9d1451bb98a', 'e4935ae6-f609-4044-aff4-3a5a6defd3d3', 47915, 'negative', 'Terminatio asperiores delectus apparatus cibus dapifer adiuvo campana exercitationem volutabrum.', '2024-08-30T01:45:10.396Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('925f618c-ecea-41a2-8386-1b9b8122de71', 'd66cb4b1-61ab-44b9-b431-2eaa04542320', 'f39acdac-6cef-44f1-a0a2-7d6601463bf4', 35127, 'positive', 'Vulnus voco certus maiores tondeo adeptio eligendi ante.', '2024-08-03T05:39:44.842Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('7a21c577-1948-40a0-a0c5-b8b1ff05e8b3', 'ac8e8a50-bd4e-4053-8772-d2826683c29d', '4e502c29-e850-483f-89d9-9d422bc359c2', 85402, 'negative', 'Magnam terga velut tamdiu comedo denique complectus cubitum constans temptatio. Copia recusandae cimentarius acerbitas ullam corpus vicinus tamen textus demulceo.', '2024-08-06T04:09:17.929Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('6b795496-2ac3-4efa-a774-a99d435937bb', 'eeedb312-c02c-4480-b6e4-7a3145cbb44a', '9ae90144-555a-4de6-9262-63a7f62cba92', 7939, 'positive', 'Suppellex consectetur vaco basium cedo clibanus tot.', '2024-08-11T09:23:33.294Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('b3aa354c-6242-4380-90c5-d1646697dc50', '38812fa2-1f56-447a-b3a7-51cda4e6c075', '133ffc07-3119-4c09-a793-f9f2bff49b64', 36911, 'negative', 'Video aequus solio atque.', '2024-08-20T13:38:02.631Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('ace1abcb-d6fe-4e56-922e-bb8316af2d66', '70a57abc-bf59-4ac8-99e7-db839193fa1e', '5fe704f1-a885-4d95-bab3-639503750f61', 43572, 'positive', 'Sto aeternus apud adsum vesica umerus vomer utroque. Adeo porro alo despecto.', '2024-08-28T21:25:29.108Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('8fafc6fa-27e2-4a4c-a995-ef00fe6486d3', 'e4659d06-39b9-417a-a5c7-8c51522a48ea', 'cb28b381-e3c1-4155-9e05-9339e5874184', 44620, 'negative', 'Ventito eos benigne arto super alo celebrer color comptus vomica. Aufero eveniet tametsi utor advoco debeo sublime calamitas.', '2024-08-27T09:12:22.549Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('8be7d653-ac37-4c3a-abe9-afcd2a8723da', 'c062042f-6446-4376-b543-d64d70eabc0d', '894f6a51-5f5d-4730-9fc3-aac2d1d34d0a', 7874, 'positive', 'Vesica laborum curo usque. Colligo ancilla considero curriculum cauda ater spes.', '2024-08-17T07:51:31.990Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('6b04fb45-e3f8-4f54-9457-a62f3e1b9d08', '3cd2c8bf-8fd4-40ca-96e3-5e41dd52d8c7', '442d962c-abed-402d-8ee6-14be6ebd74bd', 95442, 'negative', 'Virga patruus confero ago voluptatibus tenus cena.', '2024-08-31T10:56:42.533Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('3e4ca9a4-0e74-4595-8d2d-05051ee8ca9f', '7639bb07-14c8-49b8-b815-bec946340f63', 'c576d48c-4c3a-418f-8fb7-23c1f488c536', 77109, 'positive', 'Caveo brevis aggredior. Textor anser vere cunae attero capio.', '2024-08-17T20:10:56.194Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('6d4e5e05-0720-4434-a18a-6b7c490507de', '732c8fa1-2036-4e4b-a210-411bbce9c9a7', 'c821b7d3-8dd2-44ca-ad17-99c71cbd4d9c', 73387, 'negative', 'Spiritus depereo comis curis.', '2024-08-12T01:42:58.418Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('6f91b08f-8626-4b59-acd5-a09f0928126a', 'c369cecb-905f-4c93-8a7c-6ebc4d938f51', '442d962c-abed-402d-8ee6-14be6ebd74bd', 34838, 'positive', 'Dedico vobis totus iste sunt contra tondeo. Necessitatibus adinventitias carpo angelus talio torqueo arto vulticulus.', '2024-08-05T19:17:47.723Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('05ca3619-1fd6-4c3b-b81a-52a0ec104a8f', 'e4659d06-39b9-417a-a5c7-8c51522a48ea', '24ac73f3-192e-424f-8d5c-dfade4d52883', 7546, 'negative', 'Timor sui hic sit degusto audeo abscido laborum.', '2024-08-10T11:35:44.795Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('11081b3e-9e4d-474e-9861-cbf3c055dde9', '7d30f1e9-5998-4d54-b67f-aa8d7bd779e5', '9ae90144-555a-4de6-9262-63a7f62cba92', 8678, 'positive', 'Thymum creta triumphus paulatim abduco supra. Audacia tempora amissio libero vobis strenuus.', '2024-08-14T08:14:18.806Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('a82c9259-070b-4bab-888a-bbe8081fb54a', '05036186-cbf2-4ea7-b446-dc14447c88f1', '11a25c43-e483-4ae5-9839-841a85e9fa4d', 68947, 'negative', 'Denego coruscus summa turba comes clarus.', '2024-08-08T05:58:42.715Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('29f5da35-696d-4783-afce-0817a79fb672', 'f73af756-45a5-416d-963b-809bb43b4c02', '05036186-cbf2-4ea7-b446-dc14447c88f1', 89695, 'positive', 'Decet arbustum nesciunt approbo. Sordeo avarus curo.', '2024-08-10T20:20:25.649Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('0b5b1594-8dec-4504-8a97-7634cd5210d5', 'e18f1135-137c-4966-9883-881bd7cc3c0a', 'd665c01e-d750-4046-9428-8264715da6c0', 40409, 'negative', 'Dedico surculus timor consuasor agnitio bestia nisi.', '2024-08-03T19:06:11.019Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('53568545-9c90-4f45-b971-dcdd32cff688', '3cd2c8bf-8fd4-40ca-96e3-5e41dd52d8c7', 'cf4d3686-5356-418f-b16f-0a265a40080d', 5407, 'positive', 'Claustrum viriliter tollo facere alienus derideo administratio uter aqua. Desparatus itaque surgo amita patior vado derideo.', '2024-08-19T17:38:56.984Z');

insert into PUBLIC.evaluations(id, evaluator_id, evaluatee_id, aura_points_used, sign, comment, created_at)
	values ('6a427dba-8b84-4c7b-9950-16f8ac634fcc', '67b465fa-495f-48ff-bde7-c6879d26a840', '37286d2d-a250-4058-afb1-7b7146d36107', 45743, 'negative', 'Confugo consequatur tergum voro torrens copia. Aequus xiphias cohaero officiis absconditus claustrum doloribus.', '2024-08-26T23:01:49.980Z');

