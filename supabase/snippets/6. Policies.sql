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

