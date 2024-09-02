create trigger trigger_update_updated_at
	before update on PUBLIC.users for each row
	execute function update_updated_at_column();

create trigger trigger_update_follow_counts
	after insert or delete on PUBLIC.follows for each row
	execute function update_follow_counts();

create trigger on_auth_user_created
	after insert on auth.users for each row
	execute function PUBLIC.handle_new_user();

