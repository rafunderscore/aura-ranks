create or replace view leaderboard as
select
	id,
	username,
	display_name,
	aura,
	rank() over (order by aura desc, essence desc) as rank
from
	PUBLIC.users
where
	aura > 0;

create materialized view leaderboard_mview as
select
	id,
	username,
	display_name,
	aura,
	rank() over (order by aura desc, essence desc) as rank
from
	PUBLIC.users
where
	aura > 0 with no DATA;

refresh materialized view leaderboard_mview;

create or replace view comment_threads as
WITH recursive thread as (
	select
		id,
		evaluator_id,
		evaluatee_id,
		essence_used,
		sign,
		comment,
		created_at,
		parent_id,
		0 as level
	from
		PUBLIC.evaluations
	where
		parent_id is null
	union all
	select
		e.id,
		e.evaluator_id,
		e.evaluatee_id,
		e.essence_used,
		e.sign,
		e.comment,
		e.created_at,
		e.parent_id,
		t.level + 1
	from
		PUBLIC.evaluations e
		inner join thread t on e.parent_id = t.id
)
select
	*
from
	thread
order by
	level asc,
	created_at asc;

create or replace view user_evaluations as
select
	e.id as evaluation_id,
	e.evaluator_id,
	evaluator.username as evaluator_username,
	evaluator.display_name as evaluator_display_name,
	evaluator.avatar_url as evaluator_avatar_url,
	e.evaluatee_id,
	evaluatee.username as evaluatee_username,
	evaluatee.display_name as evaluatee_display_name,
	evaluatee.avatar_url as evaluatee_avatar_url,
	e.essence_used,
	e.sign,
	e.comment,
	e.created_at as evaluation_created_at
from
	PUBLIC.evaluations e
	join PUBLIC.users evaluator on e.evaluator_id = evaluator.id
	join PUBLIC.users evaluatee on e.evaluatee_id = evaluatee.id;

