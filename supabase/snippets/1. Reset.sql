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

drop type if exists level;

drop type if exists sign;

