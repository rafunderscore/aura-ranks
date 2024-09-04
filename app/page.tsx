"use client";

import { motion } from "framer-motion";
import { useState, useEffect } from "react";

import { User } from "@/lib/types/supabase";
import { createClient } from "@/supabase/lib/client";

export default function Page() {
  const supabase = createClient();

  const [usersData, setUsersData] = useState<User[]>([]);

  useEffect(() => {
    supabase
      .from("users")
      .select("*")
      .then(({ data, error }) => {
        if (error) {
          console.error("Error fetching users:", error);
        } else {
          setUsersData(data || []);
        }
      });
  }, []);

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        gap: "8px",
      }}
    >
      {usersData.map((user: User) => (
        <motion.div
          initial={{ opacity: 0.5 }}
          whileHover={{ opacity: 1, cursor: "pointer" }}
          key={user.id}
          onClick={() => {
            window.location.href = `/${user.username}`;
          }}
        >
          <h1>{user.username}</h1>
        </motion.div>
      ))}
    </div>
  );
}
