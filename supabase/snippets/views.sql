create view global_leaderboard as
select
	id,
	username,
	display_name,
	aura,
	aura_rank
from
	users
order by
	aura desc;

create view time_based_leaderboard as
select
	u.id,
	u.username,
	u.display_name,
	u.aura_rank,
	sum(ah.aura_change) as aura_gained,
	count(ah.id) as evaluations_received
from
	users u
	join aura_history ah on u.id = ah.user_id
where
	ah.created_at > now() - INTERVAL '30 days'
group by
	u.id,
	u.username,
	u.display_name,
	u.aura_rank
order by
	aura_gained desc;

create view top_evaluators as
select
	u.id,
	u.username,
	u.display_name,
	u.aura_rank,
	count(e.id) as evaluations_made
from
	users u
	join evaluations e on u.id = e.evaluator_id
group by
	u.id,
	u.username,
	u.display_name,
	u.aura_rank
order by
	evaluations_made desc;

create view user_profile as
select
	u.id,
	u.username,
	u.display_name,
	u.aura,
	u.aura_rank,
	sum(
		case when ah.created_at > now() - INTERVAL '30 days' then
			ah.aura_change
		else
			0
		end) as recent_aura_gained,
	count(
		case when ah.created_at > now() - INTERVAL '30 days' then
			ah.id
		else
			null
		end) as evaluations_received
from
	users u
	left join aura_history ah on u.id = ah.user_id
group by
	u.id,
	u.username,
	u.display_name,
	u.aura,
	u.aura_rank;

create view followers_count as
select
	followed_id as user_id,
	count(follower_id) as follower_count
from
	follows
group by
	followed_id;

create view following_count as
select
	follower_id as user_id,
	count(followed_id) as following_count
from
	follows
group by
	follower_id;

create view followers_list as
select
	f.followed_id as user_id,
	u.id as follower_id,
	u.username as follower_username,
	u.display_name as follower_display_name,
	f.followed_at
from
	follows f
	join users u on u.id = f.follower_id
order by
	f.followed_at desc;

create view recent_aura_changes as
select
	ah.user_id,
	u.username,
	ah.aura_change,
	ah.created_at
from
	aura_history ah
	join users u on u.id = ah.user_id
order by
	ah.created_at desc;

create view evaluations_with_user_details as
select
	e.id as evaluation_id,
	e.essence_used,
	e.created_at as evaluation_time,
	ev.id as evaluator_id,
	ev.username as evaluator_username,
	ev.display_name as evaluator_display_name,
	ev.avatar_url as evaluator_avatar,
	ev.aura as evaluator_aura,
	ev.aura_rank as evaluator_aura_rank,
	ee.id as evaluatee_id,
	ee.username as evaluatee_username,
	ee.display_name as evaluatee_display_name,
	ee.avatar_url as evaluatee_avatar,
	ee.aura as evaluatee_aura,
	ee.aura_rank as evaluatee_aura_rank
from
	evaluations e
	join users ev on e.evaluator_id = ev.id
	join users ee on e.evaluatee_id = ee.id
order by
	e.created_at desc;

