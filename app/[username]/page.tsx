"use client";

import { createClient } from "@/utils/supabase/client";
import { useEffect, useState } from "react";

import * as Profile from "@/screens/profile";
import { User } from "@/lib/types/supabase";

import { useParams } from "next/navigation";

export default function Page() {
  const { username } = useParams();
  console.log(username);
  const [user, setUser] = useState<User | null>(null);
  const supabase = createClient();

  useEffect(() => {
    const getData = async () => {
      const { data } = await supabase
        .from("users")
        .select("*")
        .eq("username", username);

      console.log(data);

      if (data && data.length > 0) {
        setUser(data[0]);
      }
    };
    getData();
  }, []);

  return (
    <div
      style={{
        width: "100%",
      }}
    >
      {user ? (
        <div>
          <Profile.Header user={user} />
          {/* <Profile.Standing /> */}
        </div>
      ) : (
        <div>loading</div>
      )}
    </div>
  );
}
