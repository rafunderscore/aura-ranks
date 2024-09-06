"use client";

import { useEffect, useState } from "react";

import * as Profile from "@/screens/profile";
import { createClient } from "@/supabase/lib/client";
import { User, EvaluationsWithUserDetails } from "@/supabase/types";

export default function Page({ params }: { params: any }) {
  const supabase = createClient();
  const username = decodeURIComponent(params.username).toLowerCase();
  const [user, setUser] = useState<User | null>(null);
  const [evaluations, setEvaluations] = useState<EvaluationsWithUserDetails[]>(
    [],
  );

  useEffect(() => {
    const getData = async () => {
      try {
        const { data: userData, error: userError } = await supabase
          .from("users")
          .select("*")
          .ilike("username", username)
          .single();

        if (userError) throw userError;

        if (userData) {
          setUser(userData);
          console.log("User", userData);

          const { data: evaluationsData, error: evaluationsError } =
            await supabase
              .from("evaluations")
              .select(
                "*, evaluator:users!evaluations_evaluator_id_fkey(id, username, display_name, avatar_url)",
              )
              .eq("evaluatee_id", userData.id);

          if (evaluationsError) throw evaluationsError;

          if (evaluationsData) {
            setEvaluations(evaluationsData);
            console.log("Evaluations with Evaluator Info", evaluationsData);
          }
        }
      } catch (error) {
        console.error("Error fetching data:", (error as Error).message);
      }
    };

    getData();
  }, [username]);

  return (
    <div
      style={{
        width: "100%",
      }}
    >
      {user ? (
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: "48px",
          }}
        >
          <Profile.Header user={user} />
          <Profile.Standing user={user} />
          <Profile.Evaluations evaluations={evaluations} />
        </div>
      ) : (
        <div>loading</div>
      )}
    </div>
  );
}
