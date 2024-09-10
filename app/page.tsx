"use client";

import { motion } from "framer-motion";
import { useState, useEffect } from "react";

import { createClient } from "@/supabase/lib/client";
import { User } from "@/supabase/types/database.types";

export default function Page() {
  const supabase = createClient();

  const [users, setUsers] = useState<User[]>([]);

  useEffect(() => {
    getUsers();
  }, []);

  async function getUsers() {
    const { data } = await supabase
      .from("users")
      .select("*")
      .order("user_name");

    console.log(data);

    if (data) {
      return setUsers(data);
    }
  }

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
        height: "100vh",
        gap: "8px",
      }}
    >
      {users.map((user: User) => (
        <motion.div
          initial={{ opacity: 0.5 }}
          whileHover={{ opacity: 1, cursor: "pointer" }}
          key={user.id}
          onClick={() => {
            window.location.href = `/${user.user_name}`;
          }}
        >
          <h1>{user.user_name}</h1>
        </motion.div>
      ))}
    </div>
  );
}
