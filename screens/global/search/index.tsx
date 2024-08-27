import { MagnifyingGlassIcon } from "@radix-ui/react-icons";

import styles from "./styles.module.scss";

export const Search = () => {
  return (
    <div className={styles.search}>
      <div className={styles.left}>
        <MagnifyingGlassIcon />
        <span>Search</span>
      </div>

      <div className={styles.right}>
        <code>⌘ K</code>
      </div>
    </div>
  );
};
