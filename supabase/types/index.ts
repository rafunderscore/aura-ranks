import { Database } from "./database.types";

type DatabaseTables = Database["public"]["Tables"];
type DatabaseViews = Database["public"]["Views"];
type DatabaseEnums = Database["public"]["Enums"];

type RowType<T extends { Row: any }> = T["Row"];

export type User = RowType<DatabaseTables["users"]>;
export type Evaluations = RowType<DatabaseTables["evaluations"]>;
export type Follows = RowType<DatabaseTables["follows"]>;
export type AuraHistory = RowType<DatabaseTables["aura_history"]>;
export type EssenceTransactions = RowType<
  DatabaseTables["essence_transactions"]
>;

export type EvaluationsWithUserDetails = RowType<
  DatabaseViews["evaluations_with_user_details"]
>;
export type FollowersList = RowType<DatabaseViews["followers_list"]>;
export type FollowingCount = RowType<DatabaseViews["following_count"]>;
export type GlobalLeaderboard = RowType<DatabaseViews["global_leaderboard"]>;
export type RecentAuraChanges = RowType<DatabaseViews["recent_aura_changes"]>;
export type TimeBasedLeaderboard = RowType<
  DatabaseViews["time_based_leaderboard"]
>;
export type TopEvaluators = RowType<DatabaseViews["top_evaluators"]>;
export type UserProfile = RowType<DatabaseViews["user_profile"]>;
export type Portfolio = RowType<DatabaseViews["portfolio"]>;

export type AuraTier = DatabaseEnums["aura_tier"];
export type Level = DatabaseEnums["level"];
