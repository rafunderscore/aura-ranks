import styles from "./styles.module.scss";

interface LabelProps extends React.HTMLAttributes<HTMLDivElement> {
  leading: string | number | React.ReactNode;
  trailing: string | number | React.ReactNode;
}

export const Label = ({ leading, trailing, ...props }: LabelProps) => (
  <div {...props} className={styles.label}>
    <div className={styles.leading}>{leading}</div>
    <div className={styles.trailing}>{trailing}</div>
  </div>
);

export default Label;
