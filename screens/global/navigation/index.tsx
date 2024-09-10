import Button from "@/components/button";
import IconButton from "@/components/icon-button";
import { Essence } from "@/components/icons";

import styles from "./styles.module.scss";
import { Search } from "../search/index";

const MOCK_DATA = {
  ap: 43.01,
  notifcation: 9,
};

const NavigationBar = () => {
  return (
    <nav className={styles.navigation}>
      <div className={styles.container}>
        <div className={styles.left}>
          <div className={styles.home}>Laura</div>
          <div className={styles.links}>
            <div>Activity</div>
            <div>Ranks</div>
          </div>
        </div>
        <div className={styles.center}>
          <Search />
        </div>
        <div className={styles.right}>
          <Button fit variant="secondary">
            <Essence /> <p>{MOCK_DATA.ap}</p>
          </Button>
          <IconButton background="orange-10">9</IconButton>
          <IconButton corners="circle">RS</IconButton>
        </div>
      </div>
    </nav>
  );
};

export default NavigationBar;
