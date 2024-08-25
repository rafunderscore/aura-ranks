"use client";

import { motion, HTMLMotionProps } from "framer-motion";

interface MotionButtonProps extends HTMLMotionProps<"div"> {}

export const MotionButton = (props: MotionButtonProps) => {
  return (
    <motion.div
      whileHover={{ opacity: 0.8 }}
      whileTap={{ scale: 0.9 }}
      transition={{ ease: [0.175, 0.85, 0.42, 0.96], duration: 0.4 }}
      {...props}
    >
      {props.children}
    </motion.div>
  );
};
