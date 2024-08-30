"use client";

import { createClient } from "@/utils/supabase/client";
import { useEffect, useState } from "react";

import * as Profile from "@/screens/profile";
import { Evaluation, User } from "@/lib/types/supabase";

import { useParams } from "next/navigation";

export default function Page() {
  const { username } = useParams();
  const [user, setUser] = useState<User | null>(null);
  const [evaluations, setEvaluations] = useState<Evaluation[]>([]);

  const supabase = createClient();

  useEffect(() => {
    const getData = async () => {
      try {
        // Fetch the user based on the username
        const { data: userData, error: userError } = await supabase
          .from("users")
          .select("*")
          .eq("username", username)
          .single();

        if (userError) throw userError;

        if (userData) {
          setUser(userData);
          console.log("User", userData);

          // Fetch evaluations for the user with explicit relationship aliasing
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
        console.error("Error fetching data:", error.message);
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
          <Profile.Evaluations evaluations={evaluations} />
        </div>
      ) : (
        <div>loading</div>
      )}
    </div>
  );
}
