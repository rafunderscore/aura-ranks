create index idx_users_username on PUBLIC.users(username);

create index idx_users_level on PUBLIC.users(level);

create index idx_follows_follower_id on PUBLIC.follows(follower_id);

create index idx_follows_followed_id on PUBLIC.follows(followed_id);

create index idx_evaluations_evaluator_id on PUBLIC.evaluations(evaluator_id);

create index idx_evaluations_evaluatee_id on PUBLIC.evaluations(evaluatee_id);

create index idx_users_aura on PUBLIC.users(aura);

create index idx_users_essence on PUBLIC.users(essence);

