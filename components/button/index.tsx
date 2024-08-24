import styles from "./styles.module.scss";

interface ButtonProps extends React.HTMLAttributes<HTMLButtonElement> {
  size?: "1" | "2" | "3" | "4";
  variant?: "primary" | "secondary" | "tertiary";
  corners?: "circle" | "rounded";
  loading?: boolean;
  disabled?: boolean;
  fit?: boolean;
}

const Button = ({
  size = "2",
  variant = "primary",
  corners = "rounded",
  loading = false,
  disabled = false,
  fit = false,
  ...props
}: ButtonProps) => (
  <button
    data-fit={fit}
    data-radius={corners}
    data-variant={variant}
    data-loading={loading}
    data-disabled={disabled}
    className={styles.button}
  >
    <span>{props.children}</span>
  </button>
);

export default Button;
