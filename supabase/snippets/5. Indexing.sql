create index idx_users_username on PUBLIC.users(username);

create index idx_users_aura_tier on PUBLIC.users(aura_tier);

create index idx_follows_follower_id on PUBLIC.follows(follower_id);

create index idx_follows_followed_id on PUBLIC.follows(followed_id);

create index idx_evaluations_evaluator_id on PUBLIC.evaluations(evaluator_id);

create index idx_evaluations_evaluatee_id on PUBLIC.evaluations(evaluatee_id);

create index idx_users_aura_level on PUBLIC.users(aura_level);

create index idx_users_aura_points on PUBLIC.users(aura_points);

