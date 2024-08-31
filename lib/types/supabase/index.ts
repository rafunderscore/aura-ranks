import { Database } from "./database.types";

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export type Analytic = Database["public"]["Tables"]["analytics"]["Row"];
export type Evaluation = Database["public"]["Tables"]["evaluations"]["Row"];
export type UserEvaluation =
  Database["public"]["Tables"]["evaluations"]["Row"] & {
    evaluator: Pick<
      User,
      "id" | "username" | "display_name" | "avatar_url"
    > | null;
  };

export type Follow = Database["public"]["Tables"]["follows"]["Row"];
export type User = Database["public"]["Tables"]["users"]["Row"];

export type AuraTier = Database["public"]["Enums"]["aura_tier"];
export type Sign = Database["public"]["Enums"]["sign"];

export type PublicSchema = Database["public"];

export type Table<T extends keyof PublicSchema["Tables"]> =
  PublicSchema["Tables"][T]["Row"];
export type Enum<E extends keyof PublicSchema["Enums"]> =
  PublicSchema["Enums"][E];
