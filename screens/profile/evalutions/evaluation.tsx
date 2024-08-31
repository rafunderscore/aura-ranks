import { DotsHorizontalIcon } from "@radix-ui/react-icons";
import { intlFormatDistance } from "date-fns";
import Image from "next/image";

import Button from "@/components/button";
import Island from "@/components/island";
import { UserEvaluation } from "@/lib/types/supabase";

import styles from "./evaluation.module.scss";

interface EvaluationProps extends React.HTMLAttributes<HTMLDivElement> {
  evaluation: UserEvaluation;
  end?: boolean;
}

export const Evaluation = ({ evaluation, end }: EvaluationProps) => {
  function RelativeTime(date: Date) {
    const timeString = intlFormatDistance(new Date(date), new Date());
    return timeString;
  }

  return (
    <div className={styles.evaluation}>
      <div className={styles.content}>
        <div className={styles.left}>
          <div className={styles.avatar}>
            <Image
              src={`https://avatar.vercel.sh/${evaluation.evaluator?.username}`}
              alt={"Profile Picture"}
              width={40}
              height={40}
            />
          </div>
          <div className={styles.seperator} />
        </div>
        <div className={styles.right}>
          <div className={styles.heading}>
            <div className={styles.text}>
              <div className={styles.sentence}>
                <p>{evaluation.evaluator?.username}</p>

                <p>
                  evaluated and
                  {evaluation.sign === "positive" ? " added" : " removed"}
                </p>

                <div data-evaluation-type={evaluation.sign}>
                  <p>AP {evaluation.aura_points_used}</p>
                </div>
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
