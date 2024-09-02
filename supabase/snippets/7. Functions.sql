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

