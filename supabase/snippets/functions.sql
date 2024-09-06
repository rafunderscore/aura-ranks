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

