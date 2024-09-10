import { faker } from "@faker-js/faker";
import { greenA, redA } from "@radix-ui/colors";
import { DotsHorizontalIcon } from "@radix-ui/react-icons";
import { intlFormatDistance } from "date-fns";
import { ThumbsUp, ThumbsDown, Send } from "lucide-react";
import Image from "next/image";

import { Island } from "@/components";
import Button from "@/components/button";
import { Essence } from "@/components/icons";

import styles from "./evaluation.module.scss";

export interface EvaluationType {
  id: string;
  name: string;
  avatar: string;
  comment: string;
  essence_used: number;
  type: "positive" | "negative";
  created_at: Date;
  likes: number;
  dislikes: number;
  shares: number;
  responses: number;
}

interface EvaluationProps {
  evaluation: EvaluationType;
}

const PlaceholderImage = () => {
  return (
    <div>
      <Image
        unoptimized
        src={`https://api.dicebear.com/9.x/glass/svg?seed=${encodeURIComponent(faker.string.uuid())}`}
        alt={"Profile Picture"}
        width={40}
        height={40}
      />
    </div>
  );
};

export const Evaluation = ({ evaluation }: EvaluationProps) => {
  function RelativeTime(date: Date) {
    const timeString = intlFormatDistance(new Date(date), new Date());
    return timeString;
  }

  const formatter = {
    number: new Intl.NumberFormat("en-US", {
      notation: "standard",
    }),
    date: new Intl.DateTimeFormat("en-US", {
      dateStyle: "medium",
    }),
  };

  const icon = {
    width: 16,
    height: 16,
  };

  return (
    <div className={styles.evaluation}>
      <div className={styles.left}>
        <div className={styles.avatar}>
          <Image
            unoptimized
            src={evaluation.avatar}
            alt={"Profile Picture"}
            width={40}
            height={40}
          />
        </div>
        <div className={styles.thread} />
        <div className={styles.responses}>
          <div className={styles.image}>
            <PlaceholderImage />
          </div>
          <div className={styles.image}>
            <PlaceholderImage />
          </div>
          <div className={styles.image}>
            <PlaceholderImage />
          </div>
        </div>
      </div>
      <div className={styles.right}>
        <div className={styles.heading}>
          <div className={styles.sentence}>
            <p>{evaluation.name}</p>
            {evaluation.type === "positive" ? (
              <span>bestowed</span>
            ) : (
              <span>siphoned</span>
            )}
            <div
              data-evaluation-type={evaluation.type}
              className={styles.essence}
            >
              <Essence
                color={
                  evaluation.type === "positive" ? greenA.greenA10 : redA.redA10
                }
              />
              <p>{formatter.number.format(evaluation.essence_used)}</p>
            </div>
            <p className={styles.date}>
              {evaluation.created_at
                ? RelativeTime(new Date(evaluation.created_at))
                : ""}
            </p>
          </div>
          <Button fit="square" variant="tertiary">
            <DotsHorizontalIcon />
          </Button>
        </div>
        <Island style={{ width: "100%" }}>
          <p
            style={{
              whiteSpace: "pre-wrap",
              wordBreak: "break-word",
            }}
          >
            {evaluation.comment}
          </p>
        </Island>
        <div className={styles.actions}>
          <div>
            Show Responses
            <p>({formatter.number.format(evaluation.responses)})</p>
          </div>
          <div>
            <ThumbsUp {...icon} />
            <p>{formatter.number.format(evaluation.likes)}</p>
          </div>
          <div>
            <ThumbsDown {...icon} />
            <p>{formatter.number.format(evaluation.dislikes)}</p>
          </div>
          <div>
            <Send {...icon} />
            <p>{formatter.number.format(evaluation.shares)}</p>
          </div>
        </div>
      </div>
    </div>
  );
};
