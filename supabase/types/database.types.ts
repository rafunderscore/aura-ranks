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
      aura_history: {
        Row: {
          aura_change: number | null;
          created_at: string;
          id: string;
          user_id: string | null;
        };
        Insert: {
          aura_change?: number | null;
          created_at?: string;
          id: string;
          user_id?: string | null;
        };
        Update: {
          aura_change?: number | null;
          created_at?: string;
          id?: string;
          user_id?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "aura_history_user_id_fkey";
            columns: ["user_id"];
            isOneToOne: false;
            referencedRelation: "evaluations_with_parent_details";
            referencedColumns: ["evaluatee_id"];
          },
          {
            foreignKeyName: "aura_history_user_id_fkey";
            columns: ["user_id"];
            isOneToOne: false;
            referencedRelation: "evaluations_with_parent_details";
            referencedColumns: ["parent_evaluator_id"];
          },
          {
            foreignKeyName: "aura_history_user_id_fkey";
            columns: ["user_id"];
            isOneToOne: false;
            referencedRelation: "evaluations_with_parent_details";
            referencedColumns: ["evaluator_id"];
          },
          {
            foreignKeyName: "aura_history_user_id_fkey";
            columns: ["user_id"];
            isOneToOne: false;
            referencedRelation: "full_user_details";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "aura_history_user_id_fkey";
            columns: ["user_id"];
            isOneToOne: false;
            referencedRelation: "users";
            referencedColumns: ["id"];
          },
        ];
      };
      essence_transactions: {
        Row: {
          amount: number | null;
          created_at: string;
          id: string;
          transaction_type: string | null;
          user_id: string | null;
        };
        Insert: {
          amount?: number | null;
          created_at?: string;
          id: string;
          transaction_type?: string | null;
          user_id?: string | null;
        };
        Update: {
          amount?: number | null;
          created_at?: string;
          id?: string;
          transaction_type?: string | null;
          user_id?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "essence_transactions_user_id_fkey";
            columns: ["user_id"];
            isOneToOne: false;
            referencedRelation: "evaluations_with_parent_details";
            referencedColumns: ["evaluatee_id"];
          },
          {
            foreignKeyName: "essence_transactions_user_id_fkey";
            columns: ["user_id"];
            isOneToOne: false;
            referencedRelation: "evaluations_with_parent_details";
            referencedColumns: ["parent_evaluator_id"];
          },
          {
            foreignKeyName: "essence_transactions_user_id_fkey";
            columns: ["user_id"];
            isOneToOne: false;
            referencedRelation: "evaluations_with_parent_details";
            referencedColumns: ["evaluator_id"];
          },
          {
            foreignKeyName: "essence_transactions_user_id_fkey";
            columns: ["user_id"];
            isOneToOne: false;
            referencedRelation: "full_user_details";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "essence_transactions_user_id_fkey";
            columns: ["user_id"];
            isOneToOne: false;
            referencedRelation: "users";
            referencedColumns: ["id"];
          },
        ];
      };
      evaluations: {
        Row: {
          comment: string;
          created_at: string | null;
          essence_used: number | null;
          evaluatee_id: string | null;
          evaluator_id: string | null;
          id: string;
          parent_evaluation_id: string | null;
        };
        Insert: {
          comment: string;
          created_at?: string | null;
          essence_used?: number | null;
          evaluatee_id?: string | null;
          evaluator_id?: string | null;
          id: string;
          parent_evaluation_id?: string | null;
        };
        Update: {
          comment?: string;
          created_at?: string | null;
          essence_used?: number | null;
          evaluatee_id?: string | null;
          evaluator_id?: string | null;
          id?: string;
          parent_evaluation_id?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "evaluations_evaluatee_id_fkey";
            columns: ["evaluatee_id"];
            isOneToOne: false;
            referencedRelation: "evaluations_with_parent_details";
            referencedColumns: ["evaluatee_id"];
          },
          {
            foreignKeyName: "evaluations_evaluatee_id_fkey";
            columns: ["evaluatee_id"];
            isOneToOne: false;
            referencedRelation: "evaluations_with_parent_details";
            referencedColumns: ["parent_evaluator_id"];
          },
          {
            foreignKeyName: "evaluations_evaluatee_id_fkey";
            columns: ["evaluatee_id"];
            isOneToOne: false;
            referencedRelation: "evaluations_with_parent_details";
            referencedColumns: ["evaluator_id"];
          },
          {
            foreignKeyName: "evaluations_evaluatee_id_fkey";
            columns: ["evaluatee_id"];
            isOneToOne: false;
            referencedRelation: "full_user_details";
            referencedColumns: ["id"];
          },
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
            referencedRelation: "evaluations_with_parent_details";
            referencedColumns: ["evaluatee_id"];
          },
          {
            foreignKeyName: "evaluations_evaluator_id_fkey";
            columns: ["evaluator_id"];
            isOneToOne: false;
            referencedRelation: "evaluations_with_parent_details";
            referencedColumns: ["parent_evaluator_id"];
          },
          {
            foreignKeyName: "evaluations_evaluator_id_fkey";
            columns: ["evaluator_id"];
            isOneToOne: false;
            referencedRelation: "evaluations_with_parent_details";
            referencedColumns: ["evaluator_id"];
          },
          {
            foreignKeyName: "evaluations_evaluator_id_fkey";
            columns: ["evaluator_id"];
            isOneToOne: false;
            referencedRelation: "full_user_details";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "evaluations_evaluator_id_fkey";
            columns: ["evaluator_id"];
            isOneToOne: false;
            referencedRelation: "users";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "evaluations_parent_evaluation_id_fkey";
            columns: ["parent_evaluation_id"];
            isOneToOne: false;
            referencedRelation: "evaluations";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "evaluations_parent_evaluation_id_fkey";
            columns: ["parent_evaluation_id"];
            isOneToOne: false;
            referencedRelation: "evaluations_with_parent_details";
            referencedColumns: ["evaluation_id"];
          },
          {
            foreignKeyName: "evaluations_parent_evaluation_id_fkey";
            columns: ["parent_evaluation_id"];
            isOneToOne: false;
            referencedRelation: "evaluations_with_parent_details";
            referencedColumns: ["parent_evaluation_id"];
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
            referencedRelation: "evaluations_with_parent_details";
            referencedColumns: ["evaluatee_id"];
          },
          {
            foreignKeyName: "follows_followed_id_fkey";
            columns: ["followed_id"];
            isOneToOne: false;
            referencedRelation: "evaluations_with_parent_details";
            referencedColumns: ["parent_evaluator_id"];
          },
          {
            foreignKeyName: "follows_followed_id_fkey";
            columns: ["followed_id"];
            isOneToOne: false;
            referencedRelation: "evaluations_with_parent_details";
            referencedColumns: ["evaluator_id"];
          },
          {
            foreignKeyName: "follows_followed_id_fkey";
            columns: ["followed_id"];
            isOneToOne: false;
            referencedRelation: "full_user_details";
            referencedColumns: ["id"];
          },
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
            referencedRelation: "evaluations_with_parent_details";
            referencedColumns: ["evaluatee_id"];
          },
          {
            foreignKeyName: "follows_follower_id_fkey";
            columns: ["follower_id"];
            isOneToOne: false;
            referencedRelation: "evaluations_with_parent_details";
            referencedColumns: ["parent_evaluator_id"];
          },
          {
            foreignKeyName: "follows_follower_id_fkey";
            columns: ["follower_id"];
            isOneToOne: false;
            referencedRelation: "evaluations_with_parent_details";
            referencedColumns: ["evaluator_id"];
          },
          {
            foreignKeyName: "follows_follower_id_fkey";
            columns: ["follower_id"];
            isOneToOne: false;
            referencedRelation: "full_user_details";
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
          aura: number | null;
          aura_rank: Database["public"]["Enums"]["rank_enum"] | null;
          bio: string | null;
          created_at: string | null;
          entity_logo_url: string | null;
          entity_name: string;
          essence: number | null;
          id: string;
          sector: Database["public"]["Enums"]["sector_enum"] | null;
          updated_at: string | null;
          user_avatar_url: string | null;
          user_display_name: string | null;
          user_name: string;
          website: string | null;
          world_location: string | null;
        };
        Insert: {
          aura?: number | null;
          aura_rank?: Database["public"]["Enums"]["rank_enum"] | null;
          bio?: string | null;
          created_at?: string | null;
          entity_logo_url?: string | null;
          entity_name: string;
          essence?: number | null;
          id: string;
          sector?: Database["public"]["Enums"]["sector_enum"] | null;
          updated_at?: string | null;
          user_avatar_url?: string | null;
          user_display_name?: string | null;
          user_name: string;
          website?: string | null;
          world_location?: string | null;
        };
        Update: {
          aura?: number | null;
          aura_rank?: Database["public"]["Enums"]["rank_enum"] | null;
          bio?: string | null;
          created_at?: string | null;
          entity_logo_url?: string | null;
          entity_name?: string;
          essence?: number | null;
          id?: string;
          sector?: Database["public"]["Enums"]["sector_enum"] | null;
          updated_at?: string | null;
          user_avatar_url?: string | null;
          user_display_name?: string | null;
          user_name?: string;
          website?: string | null;
          world_location?: string | null;
        };
        Relationships: [];
      };
    };
    Views: {
      evaluations_with_parent_details: {
        Row: {
          essence_used: number | null;
          evaluatee_aura: number | null;
          evaluatee_aura_rank: Database["public"]["Enums"]["rank_enum"] | null;
          evaluatee_avatar: string | null;
          evaluatee_display_name: string | null;
          evaluatee_id: string | null;
          evaluatee_username: string | null;
          evaluation_comment: string | null;
          evaluation_id: string | null;
          evaluation_time: string | null;
          evaluator_aura: number | null;
          evaluator_aura_rank: Database["public"]["Enums"]["rank_enum"] | null;
          evaluator_avatar: string | null;
          evaluator_display_name: string | null;
          evaluator_id: string | null;
          evaluator_username: string | null;
          parent_evaluation_comment: string | null;
          parent_evaluation_id: string | null;
          parent_evaluator_aura: number | null;
          parent_evaluator_aura_rank:
            | Database["public"]["Enums"]["rank_enum"]
            | null;
          parent_evaluator_avatar: string | null;
          parent_evaluator_display_name: string | null;
          parent_evaluator_id: string | null;
          parent_evaluator_username: string | null;
        };
        Relationships: [];
      };
      full_user_details: {
        Row: {
          aura: number | null;
          aura_rank: Database["public"]["Enums"]["rank_enum"] | null;
          bio: string | null;
          created_at: string | null;
          entity_logo_url: string | null;
          entity_name: string | null;
          essence: number | null;
          evaluations_made: number | null;
          evaluations_received: number | null;
          followers_count: number | null;
          following_count: number | null;
          id: string | null;
          recent_aura_gained: number | null;
          sector: Database["public"]["Enums"]["sector_enum"] | null;
          total_aura_changes: number | null;
          updated_at: string | null;
          user_avatar_url: string | null;
          user_display_name: string | null;
          user_name: string | null;
          website: string | null;
          world_location: string | null;
        };
        Relationships: [];
      };
    };
    Functions: {
      add_compression_policy: {
        Args: {
          hypertable: unknown;
          compress_after: unknown;
          if_not_exists?: boolean;
          schedule_interval?: unknown;
          initial_start?: string;
          timezone?: string;
        };
        Returns: number;
      };
      add_continuous_aggregate_policy: {
        Args: {
          continuous_aggregate: unknown;
          start_offset: unknown;
          end_offset: unknown;
          schedule_interval: unknown;
          if_not_exists?: boolean;
          initial_start?: string;
          timezone?: string;
        };
        Returns: number;
      };
      add_data_node: {
        Args: {
          node_name: unknown;
          host: string;
          database?: unknown;
          port?: number;
          if_not_exists?: boolean;
          bootstrap?: boolean;
          password?: string;
        };
        Returns: {
          node_name: unknown;
          host: string;
          port: number;
          database: unknown;
          node_created: boolean;
          database_created: boolean;
          extension_created: boolean;
        }[];
      };
      add_dimension: {
        Args: {
          hypertable: unknown;
          column_name: unknown;
          number_partitions?: number;
          chunk_time_interval?: unknown;
          partitioning_func?: unknown;
          if_not_exists?: boolean;
        };
        Returns: {
          dimension_id: number;
          schema_name: unknown;
          table_name: unknown;
          column_name: unknown;
          created: boolean;
        }[];
      };
      add_job: {
        Args: {
          proc: unknown;
          schedule_interval: unknown;
          config?: Json;
          initial_start?: string;
          scheduled?: boolean;
          check_config?: unknown;
          fixed_schedule?: boolean;
          timezone?: string;
        };
        Returns: number;
      };
      add_reorder_policy: {
        Args: {
          hypertable: unknown;
          index_name: unknown;
          if_not_exists?: boolean;
          initial_start?: string;
          timezone?: string;
        };
        Returns: number;
      };
      add_retention_policy: {
        Args: {
          relation: unknown;
          drop_after: unknown;
          if_not_exists?: boolean;
          schedule_interval?: unknown;
          initial_start?: string;
          timezone?: string;
        };
        Returns: number;
      };
      alter_data_node: {
        Args: {
          node_name: unknown;
          host?: string;
          database?: unknown;
          port?: number;
          available?: boolean;
        };
        Returns: {
          node_name: unknown;
          host: string;
          port: number;
          database: unknown;
          available: boolean;
        }[];
      };
      alter_job: {
        Args: {
          job_id: number;
          schedule_interval?: unknown;
          max_runtime?: unknown;
          max_retries?: number;
          retry_period?: unknown;
          scheduled?: boolean;
          config?: Json;
          next_start?: string;
          if_exists?: boolean;
          check_config?: unknown;
        };
        Returns: {
          job_id: number;
          schedule_interval: unknown;
          max_runtime: unknown;
          max_retries: number;
          retry_period: unknown;
          scheduled: boolean;
          config: Json;
          next_start: string;
          check_config: string;
        }[];
      };
      approximate_row_count: {
        Args: {
          relation: unknown;
        };
        Returns: number;
      };
      attach_data_node: {
        Args: {
          node_name: unknown;
          hypertable: unknown;
          if_not_attached?: boolean;
          repartition?: boolean;
        };
        Returns: {
          hypertable_id: number;
          node_hypertable_id: number;
          node_name: unknown;
        }[];
      };
      attach_tablespace: {
        Args: {
          tablespace: unknown;
          hypertable: unknown;
          if_not_attached?: boolean;
        };
        Returns: undefined;
      };
      calculate_aura_rank: {
        Args: {
          aura: number;
        };
        Returns: Database["public"]["Enums"]["rank_enum"];
      };
      chunk_compression_stats: {
        Args: {
          hypertable: unknown;
        };
        Returns: {
          chunk_schema: unknown;
          chunk_name: unknown;
          compression_status: string;
          before_compression_table_bytes: number;
          before_compression_index_bytes: number;
          before_compression_toast_bytes: number;
          before_compression_total_bytes: number;
          after_compression_table_bytes: number;
          after_compression_index_bytes: number;
          after_compression_toast_bytes: number;
          after_compression_total_bytes: number;
          node_name: unknown;
        }[];
      };
      chunks_detailed_size: {
        Args: {
          hypertable: unknown;
        };
        Returns: {
          chunk_schema: unknown;
          chunk_name: unknown;
          table_bytes: number;
          index_bytes: number;
          toast_bytes: number;
          total_bytes: number;
          node_name: unknown;
        }[];
      };
      compress_chunk: {
        Args: {
          uncompressed_chunk: unknown;
          if_not_compressed?: boolean;
        };
        Returns: unknown;
      };
      create_distributed_hypertable: {
        Args: {
          relation: unknown;
          time_column_name: unknown;
          partitioning_column?: unknown;
          number_partitions?: number;
          associated_schema_name?: unknown;
          associated_table_prefix?: unknown;
          chunk_time_interval?: unknown;
          create_default_indexes?: boolean;
          if_not_exists?: boolean;
          partitioning_func?: unknown;
          migrate_data?: boolean;
          chunk_target_size?: string;
          chunk_sizing_func?: unknown;
          time_partitioning_func?: unknown;
          replication_factor?: number;
          data_nodes?: unknown[];
        };
        Returns: {
          hypertable_id: number;
          schema_name: unknown;
          table_name: unknown;
          created: boolean;
        }[];
      };
      create_distributed_restore_point: {
        Args: {
          name: string;
        };
        Returns: {
          node_name: unknown;
          node_type: string;
          restore_point: unknown;
        }[];
      };
      create_hypertable: {
        Args: {
          relation: unknown;
          time_column_name: unknown;
          partitioning_column?: unknown;
          number_partitions?: number;
          associated_schema_name?: unknown;
          associated_table_prefix?: unknown;
          chunk_time_interval?: unknown;
          create_default_indexes?: boolean;
          if_not_exists?: boolean;
          partitioning_func?: unknown;
          migrate_data?: boolean;
          chunk_target_size?: string;
          chunk_sizing_func?: unknown;
          time_partitioning_func?: unknown;
          replication_factor?: number;
          data_nodes?: unknown[];
          distributed?: boolean;
        };
        Returns: {
          hypertable_id: number;
          schema_name: unknown;
          table_name: unknown;
          created: boolean;
        }[];
      };
      decompress_chunk: {
        Args: {
          uncompressed_chunk: unknown;
          if_compressed?: boolean;
        };
        Returns: unknown;
      };
      delete_data_node: {
        Args: {
          node_name: unknown;
          if_exists?: boolean;
          force?: boolean;
          repartition?: boolean;
          drop_database?: boolean;
        };
        Returns: boolean;
      };
      delete_job: {
        Args: {
          job_id: number;
        };
        Returns: undefined;
      };
      detach_data_node: {
        Args: {
          node_name: unknown;
          hypertable?: unknown;
          if_attached?: boolean;
          force?: boolean;
          repartition?: boolean;
          drop_remote_data?: boolean;
        };
        Returns: number;
      };
      detach_tablespace: {
        Args: {
          tablespace: unknown;
          hypertable?: unknown;
          if_attached?: boolean;
        };
        Returns: number;
      };
      detach_tablespaces: {
        Args: {
          hypertable: unknown;
        };
        Returns: number;
      };
      drop_chunks: {
        Args: {
          relation: unknown;
          older_than?: unknown;
          newer_than?: unknown;
          verbose?: boolean;
        };
        Returns: string[];
      };
      get_telemetry_report: {
        Args: Record<PropertyKey, never>;
        Returns: Json;
      };
      hypertable_compression_stats: {
        Args: {
          hypertable: unknown;
        };
        Returns: {
          total_chunks: number;
          number_compressed_chunks: number;
          before_compression_table_bytes: number;
          before_compression_index_bytes: number;
          before_compression_toast_bytes: number;
          before_compression_total_bytes: number;
          after_compression_table_bytes: number;
          after_compression_index_bytes: number;
          after_compression_toast_bytes: number;
          after_compression_total_bytes: number;
          node_name: unknown;
        }[];
      };
      hypertable_detailed_size: {
        Args: {
          hypertable: unknown;
        };
        Returns: {
          table_bytes: number;
          index_bytes: number;
          toast_bytes: number;
          total_bytes: number;
          node_name: unknown;
        }[];
      };
      hypertable_index_size: {
        Args: {
          index_name: unknown;
        };
        Returns: number;
      };
      hypertable_size: {
        Args: {
          hypertable: unknown;
        };
        Returns: number;
      };
      interpolate:
        | {
            Args: {
              value: number;
              prev?: Record<string, unknown>;
              next?: Record<string, unknown>;
            };
            Returns: number;
          }
        | {
            Args: {
              value: number;
              prev?: Record<string, unknown>;
              next?: Record<string, unknown>;
            };
            Returns: number;
          }
        | {
            Args: {
              value: number;
              prev?: Record<string, unknown>;
              next?: Record<string, unknown>;
            };
            Returns: number;
          }
        | {
            Args: {
              value: number;
              prev?: Record<string, unknown>;
              next?: Record<string, unknown>;
            };
            Returns: number;
          }
        | {
            Args: {
              value: number;
              prev?: Record<string, unknown>;
              next?: Record<string, unknown>;
            };
            Returns: number;
          };
      locf: {
        Args: {
          value: unknown;
          prev?: unknown;
          treat_null_as_missing?: boolean;
        };
        Returns: unknown;
      };
      move_chunk: {
        Args: {
          chunk: unknown;
          destination_tablespace: unknown;
          index_destination_tablespace?: unknown;
          reorder_index?: unknown;
          verbose?: boolean;
        };
        Returns: undefined;
      };
      remove_compression_policy: {
        Args: {
          hypertable: unknown;
          if_exists?: boolean;
        };
        Returns: boolean;
      };
      remove_continuous_aggregate_policy: {
        Args: {
          continuous_aggregate: unknown;
          if_not_exists?: boolean;
          if_exists?: boolean;
        };
        Returns: undefined;
      };
      remove_reorder_policy: {
        Args: {
          hypertable: unknown;
          if_exists?: boolean;
        };
        Returns: undefined;
      };
      remove_retention_policy: {
        Args: {
          relation: unknown;
          if_exists?: boolean;
        };
        Returns: undefined;
      };
      reorder_chunk: {
        Args: {
          chunk: unknown;
          index?: unknown;
          verbose?: boolean;
        };
        Returns: undefined;
      };
      set_adaptive_chunking: {
        Args: {
          hypertable: unknown;
          chunk_target_size: string;
        };
        Returns: Record<string, unknown>;
      };
      set_chunk_time_interval: {
        Args: {
          hypertable: unknown;
          chunk_time_interval: unknown;
          dimension_name?: unknown;
        };
        Returns: undefined;
      };
      set_integer_now_func: {
        Args: {
          hypertable: unknown;
          integer_now_func: unknown;
          replace_if_exists?: boolean;
        };
        Returns: undefined;
      };
      set_number_partitions: {
        Args: {
          hypertable: unknown;
          number_partitions: number;
          dimension_name?: unknown;
        };
        Returns: undefined;
      };
      set_replication_factor: {
        Args: {
          hypertable: unknown;
          replication_factor: number;
        };
        Returns: undefined;
      };
      show_chunks: {
        Args: {
          relation: unknown;
          older_than?: unknown;
          newer_than?: unknown;
        };
        Returns: unknown[];
      };
      show_tablespaces: {
        Args: {
          hypertable: unknown;
        };
        Returns: unknown[];
      };
      time_bucket:
        | {
            Args: {
              bucket_width: number;
              ts: number;
            };
            Returns: number;
          }
        | {
            Args: {
              bucket_width: number;
              ts: number;
            };
            Returns: number;
          }
        | {
            Args: {
              bucket_width: number;
              ts: number;
            };
            Returns: number;
          }
        | {
            Args: {
              bucket_width: number;
              ts: number;
              offset: number;
            };
            Returns: number;
          }
        | {
            Args: {
              bucket_width: number;
              ts: number;
              offset: number;
            };
            Returns: number;
          }
        | {
            Args: {
              bucket_width: number;
              ts: number;
              offset: number;
            };
            Returns: number;
          }
        | {
            Args: {
              bucket_width: unknown;
              ts: string;
            };
            Returns: string;
          }
        | {
            Args: {
              bucket_width: unknown;
              ts: string;
            };
            Returns: string;
          }
        | {
            Args: {
              bucket_width: unknown;
              ts: string;
            };
            Returns: string;
          }
        | {
            Args: {
              bucket_width: unknown;
              ts: string;
              offset: unknown;
            };
            Returns: string;
          }
        | {
            Args: {
              bucket_width: unknown;
              ts: string;
              offset: unknown;
            };
            Returns: string;
          }
        | {
            Args: {
              bucket_width: unknown;
              ts: string;
              offset: unknown;
            };
            Returns: string;
          }
        | {
            Args: {
              bucket_width: unknown;
              ts: string;
              origin: string;
            };
            Returns: string;
          }
        | {
            Args: {
              bucket_width: unknown;
              ts: string;
              origin: string;
            };
            Returns: string;
          }
        | {
            Args: {
              bucket_width: unknown;
              ts: string;
              origin: string;
            };
            Returns: string;
          }
        | {
            Args: {
              bucket_width: unknown;
              ts: string;
              timezone: string;
              origin?: string;
              offset?: unknown;
            };
            Returns: string;
          };
      time_bucket_gapfill:
        | {
            Args: {
              bucket_width: number;
              ts: number;
              start?: number;
              finish?: number;
            };
            Returns: number;
          }
        | {
            Args: {
              bucket_width: number;
              ts: number;
              start?: number;
              finish?: number;
            };
            Returns: number;
          }
        | {
            Args: {
              bucket_width: number;
              ts: number;
              start?: number;
              finish?: number;
            };
            Returns: number;
          }
        | {
            Args: {
              bucket_width: unknown;
              ts: string;
              start?: string;
              finish?: string;
            };
            Returns: string;
          }
        | {
            Args: {
              bucket_width: unknown;
              ts: string;
              start?: string;
              finish?: string;
            };
            Returns: string;
          }
        | {
            Args: {
              bucket_width: unknown;
              ts: string;
              start?: string;
              finish?: string;
            };
            Returns: string;
          }
        | {
            Args: {
              bucket_width: unknown;
              ts: string;
              timezone: string;
              start?: string;
              finish?: string;
            };
            Returns: string;
          };
      timescaledb_fdw_handler: {
        Args: Record<PropertyKey, never>;
        Returns: unknown;
      };
      timescaledb_post_restore: {
        Args: Record<PropertyKey, never>;
        Returns: boolean;
      };
      timescaledb_pre_restore: {
        Args: Record<PropertyKey, never>;
        Returns: boolean;
      };
    };
    Enums: {
      level: "shadowed" | "fading" | "common" | "radiant" | "ethereal";
      rank_enum:
        | "Mortal I"
        | "Mortal II"
        | "Mortal III"
        | "Mortal IV"
        | "Ascendant I"
        | "Ascendant II"
        | "Ascendant III"
        | "Ascendant IV"
        | "Seraphic I"
        | "Seraphic II"
        | "Seraphic III"
        | "Seraphic IV"
        | "Angelic I"
        | "Angelic II"
        | "Angelic III"
        | "Angelic IV"
        | "Divine I"
        | "Divine II"
        | "Divine III"
        | "Divine IV"
        | "Celestial I"
        | "Celestial II"
        | "Celestial III"
        | "Celestial IV"
        | "Ethereal I"
        | "Ethereal II"
        | "Ethereal III"
        | "Ethereal IV"
        | "Transcendent";
      sector_enum:
        | "Sports"
        | "Technology"
        | "Creatives"
        | "Health"
        | "Education"
        | "Finance"
        | "Entertainment";
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

// Schema: public
// Enums
export type Level = Database["public"]["Enums"]["level"];

export type RankEnum = Database["public"]["Enums"]["rank_enum"];

export type SectorEnum = Database["public"]["Enums"]["sector_enum"];

// Tables
export type AuraHistory = Database["public"]["Tables"]["aura_history"]["Row"];
export type InsertAuraHistory =
  Database["public"]["Tables"]["aura_history"]["Insert"];
export type UpdateAuraHistory =
  Database["public"]["Tables"]["aura_history"]["Update"];

export type EssenceTransaction =
  Database["public"]["Tables"]["essence_transactions"]["Row"];
export type InsertEssenceTransaction =
  Database["public"]["Tables"]["essence_transactions"]["Insert"];
export type UpdateEssenceTransaction =
  Database["public"]["Tables"]["essence_transactions"]["Update"];

export type Evaluation = Database["public"]["Tables"]["evaluations"]["Row"];
export type InsertEvaluation =
  Database["public"]["Tables"]["evaluations"]["Insert"];
export type UpdateEvaluation =
  Database["public"]["Tables"]["evaluations"]["Update"];

export type Follow = Database["public"]["Tables"]["follows"]["Row"];
export type InsertFollow = Database["public"]["Tables"]["follows"]["Insert"];
export type UpdateFollow = Database["public"]["Tables"]["follows"]["Update"];

export type User = Database["public"]["Tables"]["users"]["Row"];
export type InsertUser = Database["public"]["Tables"]["users"]["Insert"];
export type UpdateUser = Database["public"]["Tables"]["users"]["Update"];

// Views
export type EvaluationWithParentDetail =
  Database["public"]["Views"]["evaluations_with_parent_details"]["Row"];

export type FullUserDetail =
  Database["public"]["Views"]["full_user_details"]["Row"];

// Functions
export type ArgsAddCompressionPolicy =
  Database["public"]["Functions"]["add_compression_policy"]["Args"];
export type ReturnTypeAddCompressionPolicy =
  Database["public"]["Functions"]["add_compression_policy"]["Returns"];

export type ArgsAddContinuousAggregatePolicy =
  Database["public"]["Functions"]["add_continuous_aggregate_policy"]["Args"];
export type ReturnTypeAddContinuousAggregatePolicy =
  Database["public"]["Functions"]["add_continuous_aggregate_policy"]["Returns"];

export type ArgsAddDatumNode =
  Database["public"]["Functions"]["add_data_node"]["Args"];
export type ReturnTypeAddDatumNode =
  Database["public"]["Functions"]["add_data_node"]["Returns"];

export type ArgsAddDimension =
  Database["public"]["Functions"]["add_dimension"]["Args"];
export type ReturnTypeAddDimension =
  Database["public"]["Functions"]["add_dimension"]["Returns"];

export type ArgsAddJob = Database["public"]["Functions"]["add_job"]["Args"];
export type ReturnTypeAddJob =
  Database["public"]["Functions"]["add_job"]["Returns"];

export type ArgsAddReorderPolicy =
  Database["public"]["Functions"]["add_reorder_policy"]["Args"];
export type ReturnTypeAddReorderPolicy =
  Database["public"]["Functions"]["add_reorder_policy"]["Returns"];

export type ArgsAddRetentionPolicy =
  Database["public"]["Functions"]["add_retention_policy"]["Args"];
export type ReturnTypeAddRetentionPolicy =
  Database["public"]["Functions"]["add_retention_policy"]["Returns"];

export type ArgsAlterDatumNode =
  Database["public"]["Functions"]["alter_data_node"]["Args"];
export type ReturnTypeAlterDatumNode =
  Database["public"]["Functions"]["alter_data_node"]["Returns"];

export type ArgsAlterJob = Database["public"]["Functions"]["alter_job"]["Args"];
export type ReturnTypeAlterJob =
  Database["public"]["Functions"]["alter_job"]["Returns"];

export type ArgsApproximateRowCount =
  Database["public"]["Functions"]["approximate_row_count"]["Args"];
export type ReturnTypeApproximateRowCount =
  Database["public"]["Functions"]["approximate_row_count"]["Returns"];

export type ArgsAttachDatumNode =
  Database["public"]["Functions"]["attach_data_node"]["Args"];
export type ReturnTypeAttachDatumNode =
  Database["public"]["Functions"]["attach_data_node"]["Returns"];

export type ArgsAttachTablespace =
  Database["public"]["Functions"]["attach_tablespace"]["Args"];
export type ReturnTypeAttachTablespace =
  Database["public"]["Functions"]["attach_tablespace"]["Returns"];

export type ArgsCalculateAuraRank =
  Database["public"]["Functions"]["calculate_aura_rank"]["Args"];
export type ReturnTypeCalculateAuraRank =
  Database["public"]["Functions"]["calculate_aura_rank"]["Returns"];

export type ArgsChunkCompressionStat =
  Database["public"]["Functions"]["chunk_compression_stats"]["Args"];
export type ReturnTypeChunkCompressionStat =
  Database["public"]["Functions"]["chunk_compression_stats"]["Returns"];

export type ArgsChunkDetailedSize =
  Database["public"]["Functions"]["chunks_detailed_size"]["Args"];
export type ReturnTypeChunkDetailedSize =
  Database["public"]["Functions"]["chunks_detailed_size"]["Returns"];

export type ArgsCompressChunk =
  Database["public"]["Functions"]["compress_chunk"]["Args"];
export type ReturnTypeCompressChunk =
  Database["public"]["Functions"]["compress_chunk"]["Returns"];

export type ArgsCreateDistributedHypertable =
  Database["public"]["Functions"]["create_distributed_hypertable"]["Args"];
export type ReturnTypeCreateDistributedHypertable =
  Database["public"]["Functions"]["create_distributed_hypertable"]["Returns"];

export type ArgsCreateDistributedRestorePoint =
  Database["public"]["Functions"]["create_distributed_restore_point"]["Args"];
export type ReturnTypeCreateDistributedRestorePoint =
  Database["public"]["Functions"]["create_distributed_restore_point"]["Returns"];

export type ArgsCreateHypertable =
  Database["public"]["Functions"]["create_hypertable"]["Args"];
export type ReturnTypeCreateHypertable =
  Database["public"]["Functions"]["create_hypertable"]["Returns"];

export type ArgsDecompressChunk =
  Database["public"]["Functions"]["decompress_chunk"]["Args"];
export type ReturnTypeDecompressChunk =
  Database["public"]["Functions"]["decompress_chunk"]["Returns"];

export type ArgsDeleteDatumNode =
  Database["public"]["Functions"]["delete_data_node"]["Args"];
export type ReturnTypeDeleteDatumNode =
  Database["public"]["Functions"]["delete_data_node"]["Returns"];

export type ArgsDeleteJob =
  Database["public"]["Functions"]["delete_job"]["Args"];
export type ReturnTypeDeleteJob =
  Database["public"]["Functions"]["delete_job"]["Returns"];

export type ArgsDetachDatumNode =
  Database["public"]["Functions"]["detach_data_node"]["Args"];
export type ReturnTypeDetachDatumNode =
  Database["public"]["Functions"]["detach_data_node"]["Returns"];

export type ArgsDetachTablespace =
  Database["public"]["Functions"]["detach_tablespace"]["Args"];
export type ReturnTypeDetachTablespace =
  Database["public"]["Functions"]["detach_tablespace"]["Returns"];

export type ArgsDetachTablespace =
  Database["public"]["Functions"]["detach_tablespaces"]["Args"];
export type ReturnTypeDetachTablespace =
  Database["public"]["Functions"]["detach_tablespaces"]["Returns"];

export type ArgsDropChunk =
  Database["public"]["Functions"]["drop_chunks"]["Args"];
export type ReturnTypeDropChunk =
  Database["public"]["Functions"]["drop_chunks"]["Returns"];

export type ArgsGetTelemetryReport =
  Database["public"]["Functions"]["get_telemetry_report"]["Args"];
export type ReturnTypeGetTelemetryReport =
  Database["public"]["Functions"]["get_telemetry_report"]["Returns"];

export type ArgsHypertableCompressionStat =
  Database["public"]["Functions"]["hypertable_compression_stats"]["Args"];
export type ReturnTypeHypertableCompressionStat =
  Database["public"]["Functions"]["hypertable_compression_stats"]["Returns"];

export type ArgsHypertableDetailedSize =
  Database["public"]["Functions"]["hypertable_detailed_size"]["Args"];
export type ReturnTypeHypertableDetailedSize =
  Database["public"]["Functions"]["hypertable_detailed_size"]["Returns"];

export type ArgsHypertableIndexSize =
  Database["public"]["Functions"]["hypertable_index_size"]["Args"];
export type ReturnTypeHypertableIndexSize =
  Database["public"]["Functions"]["hypertable_index_size"]["Returns"];

export type ArgsHypertableSize =
  Database["public"]["Functions"]["hypertable_size"]["Args"];
export type ReturnTypeHypertableSize =
  Database["public"]["Functions"]["hypertable_size"]["Returns"];

export type ArgsInterpolate =
  Database["public"]["Functions"]["interpolate"]["Args"];
export type ReturnTypeInterpolate =
  Database["public"]["Functions"]["interpolate"]["Returns"];

export type ArgsLocf = Database["public"]["Functions"]["locf"]["Args"];
export type ReturnTypeLocf = Database["public"]["Functions"]["locf"]["Returns"];

export type ArgsMoveChunk =
  Database["public"]["Functions"]["move_chunk"]["Args"];
export type ReturnTypeMoveChunk =
  Database["public"]["Functions"]["move_chunk"]["Returns"];

export type ArgsRemoveCompressionPolicy =
  Database["public"]["Functions"]["remove_compression_policy"]["Args"];
export type ReturnTypeRemoveCompressionPolicy =
  Database["public"]["Functions"]["remove_compression_policy"]["Returns"];

export type ArgsRemoveContinuousAggregatePolicy =
  Database["public"]["Functions"]["remove_continuous_aggregate_policy"]["Args"];
export type ReturnTypeRemoveContinuousAggregatePolicy =
  Database["public"]["Functions"]["remove_continuous_aggregate_policy"]["Returns"];

export type ArgsRemoveReorderPolicy =
  Database["public"]["Functions"]["remove_reorder_policy"]["Args"];
export type ReturnTypeRemoveReorderPolicy =
  Database["public"]["Functions"]["remove_reorder_policy"]["Returns"];

export type ArgsRemoveRetentionPolicy =
  Database["public"]["Functions"]["remove_retention_policy"]["Args"];
export type ReturnTypeRemoveRetentionPolicy =
  Database["public"]["Functions"]["remove_retention_policy"]["Returns"];

export type ArgsReorderChunk =
  Database["public"]["Functions"]["reorder_chunk"]["Args"];
export type ReturnTypeReorderChunk =
  Database["public"]["Functions"]["reorder_chunk"]["Returns"];

export type ArgsSetAdaptiveChunking =
  Database["public"]["Functions"]["set_adaptive_chunking"]["Args"];
export type ReturnTypeSetAdaptiveChunking =
  Database["public"]["Functions"]["set_adaptive_chunking"]["Returns"];

export type ArgsSetChunkTimeInterval =
  Database["public"]["Functions"]["set_chunk_time_interval"]["Args"];
export type ReturnTypeSetChunkTimeInterval =
  Database["public"]["Functions"]["set_chunk_time_interval"]["Returns"];

export type ArgsSetIntegerNowFunc =
  Database["public"]["Functions"]["set_integer_now_func"]["Args"];
export type ReturnTypeSetIntegerNowFunc =
  Database["public"]["Functions"]["set_integer_now_func"]["Returns"];

export type ArgsSetNumberPartition =
  Database["public"]["Functions"]["set_number_partitions"]["Args"];
export type ReturnTypeSetNumberPartition =
  Database["public"]["Functions"]["set_number_partitions"]["Returns"];

export type ArgsSetReplicationFactor =
  Database["public"]["Functions"]["set_replication_factor"]["Args"];
export type ReturnTypeSetReplicationFactor =
  Database["public"]["Functions"]["set_replication_factor"]["Returns"];

export type ArgsShowChunk =
  Database["public"]["Functions"]["show_chunks"]["Args"];
export type ReturnTypeShowChunk =
  Database["public"]["Functions"]["show_chunks"]["Returns"];

export type ArgsShowTablespace =
  Database["public"]["Functions"]["show_tablespaces"]["Args"];
export type ReturnTypeShowTablespace =
  Database["public"]["Functions"]["show_tablespaces"]["Returns"];

export type ArgsTimeBucket =
  Database["public"]["Functions"]["time_bucket"]["Args"];
export type ReturnTypeTimeBucket =
  Database["public"]["Functions"]["time_bucket"]["Returns"];

export type ArgsTimeBucketGapfill =
  Database["public"]["Functions"]["time_bucket_gapfill"]["Args"];
export type ReturnTypeTimeBucketGapfill =
  Database["public"]["Functions"]["time_bucket_gapfill"]["Returns"];

export type ArgsTimescaledbFdwHandler =
  Database["public"]["Functions"]["timescaledb_fdw_handler"]["Args"];
export type ReturnTypeTimescaledbFdwHandler =
  Database["public"]["Functions"]["timescaledb_fdw_handler"]["Returns"];

export type ArgsTimescaledbPostRestore =
  Database["public"]["Functions"]["timescaledb_post_restore"]["Args"];
export type ReturnTypeTimescaledbPostRestore =
  Database["public"]["Functions"]["timescaledb_post_restore"]["Returns"];

export type ArgsTimescaledbPreRestore =
  Database["public"]["Functions"]["timescaledb_pre_restore"]["Args"];
export type ReturnTypeTimescaledbPreRestore =
  Database["public"]["Functions"]["timescaledb_pre_restore"]["Returns"];
