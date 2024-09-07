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

