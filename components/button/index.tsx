import styles from "./styles.module.scss";

interface ButtonProps extends React.HTMLAttributes<HTMLButtonElement> {
  size?: "1" | "2" | "3" | "4";
  variant?: "primary" | "secondary" | "tertiary";
  loading?: boolean;
  disabled?: boolean;
}

const Button = ({
  size = "2",
  variant = "primary",
  loading = false,
  disabled = false,
  ...props
}: ButtonProps) => (
  <button
    data-variant={variant}
    data-loading={loading}
    data-disabled={disabled}
    className={styles.button}
  >
    <span>{props.children}</span>
  </button>
);

export default Button;
