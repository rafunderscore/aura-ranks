import styles from "./styles.module.scss";

interface IconButtonProps extends React.HTMLAttributes<HTMLButtonElement> {
  size?: "1" | "2" | "3" | "4";
  variant?: "primary" | "secondary" | "tertiary";
  loading?: boolean;
  disabled?: boolean;
}

const IconButton = ({
  size = "2",
  variant = "primary",
  loading = false,
  disabled = false,
  ...props
}: IconButtonProps) => (
  <div
    data-variant={variant}
    data-loading={loading}
    data-disabled={disabled}
    className={styles.icon}
  >
    {props.children}
  </div>
);

export default IconButton;
