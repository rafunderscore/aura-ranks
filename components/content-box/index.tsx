import styles from "./styles.module.scss";

interface ContentBoxProps extends React.HTMLAttributes<HTMLDivElement> {
  heading: React.ReactNode;
  actions: React.ReactNode[];
  items: React.ReactNode[];
  layout?: "row" | "grid";
}

const ContentBox = ({ heading, actions, items, ...props }: ContentBoxProps) => (
  <div className={styles.box}>
    <div className={styles.header}>
      <div className={styles.heading}>{heading}</div>
      <div className={styles.actions}>
        {actions.map((action, index) => (
          <div key={index} className={styles.action}>
            {action}
          </div>
        ))}
      </div>
    </div>
    <div data-layout="row" className={styles.items}>
      {items.map((item, index) => (
        <div key={index}>{item}</div>
      ))}
    </div>
  </div>
);

export default ContentBox;
