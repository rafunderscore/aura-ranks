alter table users enable row level security;

create policy "Allow individual users to select their own data" on users
	for select
		using (auth.uid() = id);

create policy "Allow individual users to update their own aura" on users
	for update
		using (auth.uid() = id);

