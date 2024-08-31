import { MotionButton } from "@/components/framer-motion/button";

import styles from "./styles.module.scss";

interface IconButtonProps extends React.HTMLAttributes<HTMLButtonElement> {
  size?: "1" | "2" | "3" | "4";
  variant?: "primary" | "secondary" | "tertiary";
  corners?: "circle" | "rounded";
  loading?: boolean;
  disabled?: boolean;
  background?: string | undefined;
}

export const IconButton = ({
  size = "2",
  variant = "primary",
  corners = "rounded",
  loading = false,
  disabled = false,
  background = undefined,
  ...props
}: IconButtonProps) => {
  return (
    <MotionButton
      data-size={size}
      data-radius={corners}
      data-variant={variant}
      data-loading={loading}
      data-disabled={disabled}
      data-background={background}
      className={styles.icon}
    >
      {props.children}
    </MotionButton>
  );
};

export default IconButton;
