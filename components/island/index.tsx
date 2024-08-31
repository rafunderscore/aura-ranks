import styles from "./styles.module.scss";

type IslandProps = React.HTMLAttributes<HTMLDivElement>;

export const Island = ({ ...props }: IslandProps) => (
  <div className={styles.island} style={props.style}>
    <div className={styles.container}>{props.children}</div>
  </div>
);

export default Island;
