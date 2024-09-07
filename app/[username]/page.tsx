"use client";

import React from "react";

import * as Profile from "@/screens/profile";
import { createClient } from "@/supabase/lib/client";
import { FullUserDetail } from "@/supabase/types/database.types";

export default function Page({ params }: { params: any }) {
  const supabase = createClient();

  const username = decodeURIComponent(params.username).toLowerCase();

  const [user, setUser] = React.useState<FullUserDetail | null>(null);

  React.useEffect(() => {
    getUser().then((data: FullUserDetail) => {
      setUser(data);
    });
  }, []);

  async function getUser() {
    const { data, error } = await supabase
      .from("full_user_details")
      .select("*")
      .ilike("user_name", username)
      .single();

    if (error) {
      console.error(error);
      return null;
    }

    console.log(data);

    return data;
  }

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
          <Profile.Details user={user} />
        </div>
      ) : (
        <div>loading</div>
      )}
    </div>
  );
}
