create trigger update_aura_rank_trigger_on_update
	before update on users for each row
	when(old.aura is distinct from new.aura)
	execute function update_aura_rank();

create trigger update_aura_rank_trigger_on_insert
	before insert on users for each row
	execute function update_aura_rank();

create trigger before_insert_users_sector
	before insert on users
	for each row
	execute function assign_random_sector();

