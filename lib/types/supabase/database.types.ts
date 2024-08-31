export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export type Database = {
  public: {
    Tables: {
      analytics: {
        Row: {
          aura_points: number;
          created_at: string | null;
          cumulative_aura_points: number;
          date: string;
          id: string;
          negative_evaluations: number;
          net_evaluations: number | null;
          positive_evaluations: number;
          user_id: string;
        };
        Insert: {
          aura_points?: number;
          created_at?: string | null;
          cumulative_aura_points?: number;
          date: string;
          id?: string;
          negative_evaluations?: number;
          net_evaluations?: number | null;
          positive_evaluations?: number;
          user_id: string;
        };
        Update: {
          aura_points?: number;
          created_at?: string | null;
          cumulative_aura_points?: number;
          date?: string;
          id?: string;
          negative_evaluations?: number;
          net_evaluations?: number | null;
          positive_evaluations?: number;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "analytics_user_id_fkey";
            columns: ["user_id"];
            isOneToOne: false;
            referencedRelation: "users";
            referencedColumns: ["id"];
          },
        ];
      };
      evaluations: {
        Row: {
          aura_points_used: number;
          comment: string | null;
          created_at: string | null;
          evaluatee_id: string;
          evaluator_id: string;
          id: string;
          sign: Database["public"]["Enums"]["sign"];
        };
        Insert: {
          aura_points_used: number;
          comment?: string | null;
          created_at?: string | null;
          evaluatee_id: string;
          evaluator_id: string;
          id?: string;
          sign: Database["public"]["Enums"]["sign"];
        };
        Update: {
          aura_points_used?: number;
          comment?: string | null;
          created_at?: string | null;
          evaluatee_id?: string;
          evaluator_id?: string;
          id?: string;
          sign?: Database["public"]["Enums"]["sign"];
        };
        Relationships: [
          {
            foreignKeyName: "evaluations_evaluatee_id_fkey";
            columns: ["evaluatee_id"];
            isOneToOne: false;
            referencedRelation: "users";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "evaluations_evaluator_id_fkey";
            columns: ["evaluator_id"];
            isOneToOne: false;
            referencedRelation: "users";
            referencedColumns: ["id"];
          },
        ];
      };
      follows: {
        Row: {
          followed_at: string | null;
          followed_id: string;
          follower_id: string;
        };
        Insert: {
          followed_at?: string | null;
          followed_id: string;
          follower_id: string;
        };
        Update: {
          followed_at?: string | null;
          followed_id?: string;
          follower_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "follows_followed_id_fkey";
            columns: ["followed_id"];
            isOneToOne: false;
            referencedRelation: "users";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "follows_follower_id_fkey";
            columns: ["follower_id"];
            isOneToOne: false;
            referencedRelation: "users";
            referencedColumns: ["id"];
          },
        ];
      };
      users: {
        Row: {
          aura_level: number | null;
          aura_points: number | null;
          aura_tier: Database["public"]["Enums"]["aura_tier"] | null;
          avatar_url: string | null;
          bio: string | null;
          created_at: string | null;
          display_name: string | null;
          followers_count: number | null;
          following_count: number | null;
          id: string;
          privacy_settings: Json | null;
          updated_at: string | null;
          username: string;
          website: string | null;
          world_location: string | null;
        };
        Insert: {
          aura_level?: number | null;
          aura_points?: number | null;
          aura_tier?: Database["public"]["Enums"]["aura_tier"] | null;
          avatar_url?: string | null;
          bio?: string | null;
          created_at?: string | null;
          display_name?: string | null;
          followers_count?: number | null;
          following_count?: number | null;
          id: string;
          privacy_settings?: Json | null;
          updated_at?: string | null;
          username: string;
          website?: string | null;
          world_location?: string | null;
        };
        Update: {
          aura_level?: number | null;
          aura_points?: number | null;
          aura_tier?: Database["public"]["Enums"]["aura_tier"] | null;
          avatar_url?: string | null;
          bio?: string | null;
          created_at?: string | null;
          display_name?: string | null;
          followers_count?: number | null;
          following_count?: number | null;
          id?: string;
          privacy_settings?: Json | null;
          updated_at?: string | null;
          username?: string;
          website?: string | null;
          world_location?: string | null;
        };
        Relationships: [];
      };
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      [_ in never]: never;
    };
    Enums: {
      aura_tier: "shadowed" | "fading" | "common" | "radiant" | "ethereal";
      sign: "positive" | "negative";
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
};

type PublicSchema = Database[Extract<keyof Database, "public">];

export type Tables<
  PublicTableNameOrOptions extends
    | keyof (PublicSchema["Tables"] & PublicSchema["Views"])
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
        Database[PublicTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
      Database[PublicTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R;
    }
    ? R
    : never
  : PublicTableNameOrOptions extends keyof (PublicSchema["Tables"] &
        PublicSchema["Views"])
    ? (PublicSchema["Tables"] &
        PublicSchema["Views"])[PublicTableNameOrOptions] extends {
        Row: infer R;
      }
      ? R
      : never
    : never;

export type TablesInsert<
  PublicTableNameOrOptions extends
    | keyof PublicSchema["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I;
    }
    ? I
    : never
  : PublicTableNameOrOptions extends keyof PublicSchema["Tables"]
    ? PublicSchema["Tables"][PublicTableNameOrOptions] extends {
        Insert: infer I;
      }
      ? I
      : never
    : never;

export type TablesUpdate<
  PublicTableNameOrOptions extends
    | keyof PublicSchema["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U;
    }
    ? U
    : never
  : PublicTableNameOrOptions extends keyof PublicSchema["Tables"]
    ? PublicSchema["Tables"][PublicTableNameOrOptions] extends {
        Update: infer U;
      }
      ? U
      : never
    : never;

export type Enums<
  PublicEnumNameOrOptions extends
    | keyof PublicSchema["Enums"]
    | { schema: keyof Database },
  EnumName extends PublicEnumNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = PublicEnumNameOrOptions extends { schema: keyof Database }
  ? Database[PublicEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : PublicEnumNameOrOptions extends keyof PublicSchema["Enums"]
    ? PublicSchema["Enums"][PublicEnumNameOrOptions]
    : never;
