import NavigationBar from "@/screens/global/navigation";
import * as Profile from "@/screens/profile";
import styles from "@/styles/page.module.scss";

export default async function Page() {
  return (
    <main className={styles.main}>
      <div className={styles.content}>
        <NavigationBar />
        <Profile.Header />
        <Profile.Standing />
        <Profile.Evaluations />
      </div>
    </main>
  );
}
