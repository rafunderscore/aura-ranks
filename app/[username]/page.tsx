"use client";

import React from "react";

import * as Profile from "@/screens/profile";

import styles from "./styles.module.scss";

export default function Page() {
  return (
    <div className={styles.page}>
      <Profile.Chart />
      <Profile.Details />
      <Profile.Evaluations />
    </div>
  );
}
