import { UserEvaluation } from "@/lib/types/supabase";

import styles from "./evaluation.module.scss";
import Island from "@/components/island";
import Button from "@/components/button";
import { DotsHorizontalIcon } from "@radix-ui/react-icons";
import { compareAsc, format, intlFormat, intlFormatDistance } from "date-fns";

interface EvaluationProps extends React.HTMLAttributes<HTMLDivElement> {
  evaluation: UserEvaluation;
  end?: boolean;
}

export const Evaluation = ({ evaluation, end }: EvaluationProps) => {
  const formatter = {
    number: new Intl.NumberFormat("en-US", {
      notation: "compact",
      compactDisplay: "short",
      maximumFractionDigits: 1,
    }),
    // use date-fns to format the date
    date: {
      format: (date: Date | number, type: string) => {
        return format(date, type);
      },
    },
  };

  function RelativeTime(date: Date) {
    const timeString = intlFormatDistance(new Date(date), new Date());
    return timeString;
  }

  return (
    <div className={styles.evaluation}>
      <div className={styles.content}>
        <div className={styles.left}>
          <div className={styles.avatar}></div>
          <div className={styles.seperator} />
        </div>
        <div className={styles.right}>
          <div className={styles.heading}>
            <div className={styles.text}>
              <div className={styles.sentence}>
                <p>@{evaluation.evaluator?.username}</p>
                <p>
                  evaluated and
                  {evaluation.sign === "positive" ? " added" : " removed"}
                </p>

                <p>AP {evaluation.aura_points_used}</p>
              </div>
              <p>·</p>
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
        </div>
      </div>
      <div data-evaluation-seperator={!end}>
        <div className={styles.seperator} />
      </div>
    </div>
  );
};
