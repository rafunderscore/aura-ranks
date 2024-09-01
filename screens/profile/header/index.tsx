"use client";

import {
  CalendarIcon,
  DotsHorizontalIcon,
  DrawingPinIcon,
  Link1Icon,
} from "@radix-ui/react-icons";
import Image from "next/image";

import Button from "@/components/button";
import IconButton from "@/components/icon-button";
import Label from "@/components/label";
import { User } from "@/lib/types/supabase";
import styles from "@/screens/profile/header/styles.module.scss";

interface HeaderProps extends React.HTMLAttributes<HTMLDivElement> {
  user: User;
}

export const Header = ({ user }: HeaderProps) => {
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
    <div className={styles.header}>
      <div className={styles.avatar}>
        <Image
          src={user.avatar_url ?? ""}
          alt={"Profile Picture"}
          width={128}
          unoptimized
          height={128}
        />
      </div>
      <div className={styles.details}>
        <div className={styles.heading}>
          <h1>{user.display_name}</h1>
          <h2>{user.username}</h2>
        </div>
        <p className={styles.bio}> {user.bio}</p>
        <div className={styles.additional}>
          <Label leading={user.following_count} trailing="Followers" />
          <Label
            leading={formatter.number.format(user.followers_count ?? 0)}
            trailing="Followers"
          />
          <Label
            leading={<CalendarIcon />}
            trailing={
              "Joined " +
              formatter.date.format(
                user.created_at ? new Date(user.created_at) : undefined,
              )
            }
          />
          <Label leading={<DrawingPinIcon />} trailing={user.world_location} />
          <Label
            leading={<Link1Icon />}
            trailing={
              <a
                href={user.website ? user.website : "https://playboicarti.com"}
                target="_blank"
                rel="noopener noreferrer"
              >
                {user.website}
              </a>
            }
          />
        </div>
      </div>
      <div className={styles.actions}>
        <Button>Evaluate</Button>
        <IconButton>
          <DotsHorizontalIcon />
        </IconButton>
      </div>
    </div>
  );
};
