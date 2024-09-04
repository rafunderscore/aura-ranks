create index idx_aura on users(aura desc);

create index idx_aura_rank on users(aura_rank);

create index idx_aura_history_created_at on aura_history(created_at);

create index idx_follower_id on follows(follower_id);

create index idx_followed_id on follows(followed_id);

