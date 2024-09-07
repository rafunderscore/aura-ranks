create or replace view full_user_details as
select
	u.id,
	u.user_name,
	u.user_display_name,
	u.user_avatar_url,
	u.entity_name,
	u.entity_logo_url,
	u.sector,
	u.bio,
	u.website,
	u.essence,
	u.aura,
	u.aura_rank,
	u.world_location,
	coalesce((
		select
			count(*)
		from follows
		where
			followed_id = u.id), 0) as followers_count,
	coalesce((
		select
			count(*)
		from follows
		where
			follower_id = u.id), 0) as following_count,
	coalesce(sum(ah.aura_change), 0) as total_aura_changes,
	coalesce(sum(
			case when ah.created_at > now() - INTERVAL '30 days' then
				ah.aura_change
			else
				0
			end), 0) as recent_aura_gained,
	coalesce(count(e.id), 0) as evaluations_made,
	coalesce(sum(
			case when e.created_at > now() - INTERVAL '30 days' then
				1
			else
				0
			end), 0) as evaluations_received,
	u.created_at,
	u.updated_at
from
	users u
	left join aura_history ah on u.id = ah.user_id
	left join evaluations e on u.id = e.evaluatee_id
group by
	u.id
order by
	u.aura desc;

create view evaluations_with_user_details as
select
	e.id as evaluation_id,
	e.essence_used,
	e.created_at as evaluation_time,
	ev.id as evaluator_id,
	ev.user_name as evaluator_username,
	ev.user_display_name as evaluator_display_name,
	ev.user_avatar_url as evaluator_avatar,
	ev.aura as evaluator_aura,
	ev.aura_rank as evaluator_aura_rank,
	ee.id as evaluatee_id,
	ee.user_name as evaluatee_username,
	ee.user_display_name as evaluatee_display_name,
	ee.user_avatar_url as evaluatee_avatar,
	ee.aura as evaluatee_aura,
	ee.aura_rank as evaluatee_aura_rank
from
	evaluations e
	join users ev on e.evaluator_id = ev.id
	join users ee on e.evaluatee_id = ee.id
order by
	e.created_at desc;

