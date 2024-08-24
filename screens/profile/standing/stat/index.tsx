import Island from "@/components/island";
import styles from "./styles.module.scss";

interface StatProps extends React.HTMLAttributes<HTMLDivElement> {
  heading: string;
  standout: string;
  subtext?: string;
  value?: number;
  sign?: "positive" | "negative";
}

export const Stat = ({
  heading,
  standout,
  subtext,
  value,
  sign,
  ...props
}: StatProps) => {
  return (
    <Island>
      <div className={styles.stat}>
        <div className={styles.heading}>{heading}</div>
        <div className={styles.details}>
          <div className={styles.standout}>
            {standout}
            {subtext && <sub>({subtext})</sub>}
          </div>
          {/* <div className={styles.value}>+7.44%</div> */}
          {value && (
            <div data-sign={sign} className={styles.value}>
              {sign === "positive" ? "+" : "-"}
              {value}%
            </div>
          )}
        </div>
      </div>
    </Island>
  );
};
