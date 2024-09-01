import { faker } from "@faker-js/faker";
import { DotsHorizontalIcon } from "@radix-ui/react-icons";
import { intlFormatDistance } from "date-fns";
import { Send, ThumbsDown, ThumbsUp } from "lucide-react";
import Image from "next/image";

import Button from "@/components/button";
import Island from "@/components/island";
import { UserEvaluation } from "@/lib/types/supabase";

import styles from "./evaluation.module.scss";

interface EvaluationProps extends React.HTMLAttributes<HTMLDivElement> {
  evaluation: UserEvaluation;
  end?: boolean;
}

const PlaceholderImage = () => {
  return (
    <Image
      unoptimized
      src={`https://anime.kirwako.com/api/avatar?name=${faker.name.firstName()}`}
      alt={"Profile Picture"}
      fill
    />
  );
};

export const Evaluation = ({ evaluation }: EvaluationProps) => {
  function RelativeTime(date: Date) {
    const timeString = intlFormatDistance(new Date(date), new Date());
    return timeString;
  }

  const formatter = {
    number: new Intl.NumberFormat("en-US", {
      notation: "compact",
      compactDisplay: "short",
      maximumSignificantDigits: 3,
    }),
    date: new Intl.DateTimeFormat("en-US", {
      dateStyle: "medium",
    }),
  };

  const data = {
    likes: faker.number.int({ max: 100000 }),
    dislikes: faker.number.int({ max: 10000 }),
    shares: faker.number.int({ max: 10000 }),
    responses: faker.number.int({ max: 10000 }),
  };

  const icon = {
    width: 15,
    height: 15,
  };

  return (
    <div className={styles.evaluation}>
      <div className={styles.left}>
        <div className={styles.avatar}>
          <Image
            unoptimized
            src={evaluation.evaluator?.avatar_url ?? ""}
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
            <p>{evaluation.evaluator?.display_name}</p>
            <div data-evaluation-type={evaluation.sign}>
              <p>AP {formatter.number.format(evaluation.aura_points_used)}</p>
            </div>
            <p>
              {evaluation.created_at
                ? RelativeTime(new Date(evaluation.created_at))
                : ""}
            </p>
          </div>
          <Button fit="square" variant="tertiary">
            <DotsHorizontalIcon />
          </Button>
        </div>
        <Island style={{ width: "100%" }}>{evaluation.comment}</Island>
        <div className={styles.actions}>
          <div>
            Show Responses
            <p>({formatter.number.format(data.responses)})</p>
          </div>
          <div>
            <ThumbsUp {...icon} />
            <p>{formatter.number.format(data.likes)}</p>
          </div>
          <div>
            <ThumbsDown {...icon} />
            <p>{formatter.number.format(data.dislikes)}</p>
          </div>
          <div>
            <Send {...icon} />
            <p>{formatter.number.format(data.shares)}</p>
          </div>
        </div>
      </div>
    </div>
  );
};
