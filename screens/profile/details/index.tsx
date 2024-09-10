"use client";

import { Clock, Globe, PieChart } from "lucide-react";
import Image from "next/image";

import { IconButton } from "@/components";
import Label from "@/components/label";

import styles from "./styles.module.scss";

const DETAILS = {
  user_avatar_url: "https://api.dicebear.com/9.x/glass/svg?seed=playboicarti",
  user_display_name: "Playboi Carti",
  user_name: "playboicarti",
  bio: `Jordan Terrell Carter (born September 13, 1995 or 1996a), known professionally as Playboi Carti, is an American rapper from Atlanta, Georgia. An influential figure among his generation, he has contributed to the progression of trap music and its rage subgenre.[7] He first signed with local underground record label Awful Records in 2014, and later signed with ASAP Mob's record label AWGE, in a joint venture with Interscope Records two years later.[8] Carter gained mainstream attention following the release of his eponymous debut mixtape (2017), which peaked at number 12 on the U.S. Billboard 200 and spawned the Billboard Hot 100-charting singles "Magnolia" and "Wokeuplikethis" (featuring Lil Uzi Vert).`,
  following_count: 10,
  followers_count: 89324,
  sector: "Creatives",
  website: "https://playboicarti.com",
  created_at: "2024-05-23T00:00:00Z",
};

export const Details = () => {
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
            src={DETAILS.user_avatar_url}
            alt={"Profile Picture"}
            fill
          />
        </div>
        <div className={styles.names}>
          <h1>{DETAILS.user_display_name}</h1>
          <h2>@{DETAILS.user_name}</h2>
        </div>
        <IconButton />
      </div>

      <div className={styles.content}>
        <p>{DETAILS.bio}</p>
      </div>
      <div className={styles.footer}>
        <Label
          leading={formatter.number.format(DETAILS.following_count || 0)}
          trailing={"Following"}
        />
        <Label
          leading={formatter.number.format(DETAILS.followers_count || 0)}
          trailing={"Following"}
        />
        <Label leading={<PieChart />} trailing={DETAILS.sector} />
        <Label leading={<Globe />} trailing={DETAILS.website} />
        <Label
          leading={<Clock />}
          trailing={formatter.date.format(new Date(DETAILS.created_at || ""))}
        />
      </div>
    </div>
  );
};
