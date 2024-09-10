import { execSync } from "child_process";

(async () => {
  const chalk = (await import("chalk")).default;
  const ora = (await import("ora")).default;

  const run = (cmd, description) => {
    const spinner = ora({
      indent: 2,
      spinner: process.argv[2],
      text: chalk(`Running ${description}...`),
      color: "black",
    }).start();

    try {
      execSync(cmd, { stdio: "inherit" });
      spinner.succeed(chalk.black(`${description} (Passed)`));
    } catch (error) {
      spinner.fail(chalk.black(`${description} (Failed)`));
      process.exit(1);
    }
  };

  console.log(chalk("  ") + chalk.green.dim.bold("☘ Lint.js 0.0.1\n"));

  run("prettier --write . --log-level error", "Prettier");
  run("eslint --stats --fix '**/*.{ts,tsx}'", "ESLint");
  run("stylelint --fix '**/*.scss'", "Stylelint");

  console.log(chalk("\n  ") + chalk.bold("✔ Linting Complete\n"));
})();
