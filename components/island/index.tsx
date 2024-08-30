import styles from "./styles.module.scss";

interface IslandProps extends React.HTMLAttributes<HTMLDivElement> {}

const Island = ({ ...props }: IslandProps) => (
  <div className={styles.island} style={props.style}>
    <div className={styles.container}>{props.children}</div>
  </div>
);

export default Island;
