import { clsx } from "clsx";
import { Inter } from "next/font/google";

import styles from "@/styles/main.module.scss";

import type { Metadata } from "next";

import "@/styles/main.scss";
import "@/styles/main.css";

const sans = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Laura",
  description: "Where Aura is defined",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={clsx({
          [styles.body]: true,
          [sans.className]: true,
        })}
      >
        <main className={styles.main}>{children}</main>
      </body>
    </html>
  );
}
