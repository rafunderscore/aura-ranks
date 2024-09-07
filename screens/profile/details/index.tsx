"use client";

import { Clock, Globe, PieChart } from "lucide-react";
import Image from "next/image";

import { IconButton } from "@/components";
import Label from "@/components/label";
import { FullUserDetail } from "@/supabase/types/database.types";

import styles from "./styles.module.scss";

interface HeaderProps extends React.HTMLAttributes<HTMLDivElement> {
  user: FullUserDetail;
}

export const Details = ({ user }: HeaderProps) => {
  const formatter = {
    number: new Intl.NumberFormat("en-US", {
      notation: "compact",
      compactDisplay: "short",
      maximumFractionDigits: 1,
    }),
    date: new Intl.DateTimeFormat("en-US", {
      dateStyle: "medium",
    }),
  };

  return (
    <div className={styles.details}>
      <div className={styles.header}>
        <div className={styles.avatar}>
          <Image
            unoptimized
            src={user.user_avatar_url || ""}
            alt={"Profile Picture"}
            fill
          />
        </div>
        <div className={styles.names}>
          <h1>{user.user_display_name}</h1>
          <h2>@{user.user_name}</h2>
        </div>
        <IconButton />
      </div>

      <div className={styles.content}>
        <p>{user.bio}</p>
      </div>
      <div className={styles.footer}>
        <Label
          leading={formatter.number.format(user.following_count || 0)}
          trailing={"Following"}
        />
        <Label
          leading={formatter.number.format(user.followers_count || 0)}
          trailing={"Following"}
        />
        <Label leading={<PieChart />} trailing={user.sector} />
        <Label leading={<Globe />} trailing={user.website} />
        <Label
          leading={<Clock />}
          trailing={formatter.date.format(new Date(user.created_at || ""))}
        />
      </div>
    </div>
  );
};
