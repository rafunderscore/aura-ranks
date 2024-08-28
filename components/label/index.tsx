import styles from "./styles.module.scss";

interface LabelProps extends React.HTMLAttributes<HTMLDivElement> {
  leading: React.ReactNode;
  trailing: string | number | React.ReactNode;
}

const Label = ({ leading, trailing, ...props }: LabelProps) => (
  <div {...props} className={styles.label}>
    <div className={styles.leading}>{leading}</div>
    <div className={styles.trailing}>{trailing}</div>
  </div>
);

export default Label;
