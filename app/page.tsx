"use client";

import { motion } from "framer-motion";
import { Ellipsis } from "lucide-react";
import { useState, useEffect } from "react";

import { User } from "@/lib/types/supabase";
import styles from "@/styles/page.module.scss";
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
        justifyContent: "center",
        height: "100vh",
        gap: "8px",
      }}
    >
      <div className={styles.button}>
        <Ellipsis />
      </div>
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
