import styles from "./styles.module.scss";

interface LabelProps extends React.HTMLAttributes<HTMLDivElement> {
  icon: React.ReactNode;
  text: string | number | React.ReactNode;
}

const Label = ({ icon, text, ...props }: LabelProps) => (
  <div {...props} className={styles.label}>
    {icon}
    <p>{text}</p>
  </div>
);

export default Label;
