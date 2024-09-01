const fs = require("fs");
const { v4: uuidv4 } = require("uuid");
const { faker } = require("@faker-js/faker");

(async () => {
  const chalk = (await import("chalk")).default;
  const ora = (await import("ora")).default;

  const auraTiers = ["common", "fading", "radiant", "ethereal", "shadowed"];
  const diceBearStyles = ["thumbs"];

  function escapeSqlString(str) {
    return str.replace(/'/g, "''");
  }

  function generateDiceBearAvatarUrl(username) {
    const style =
      diceBearStyles[Math.floor(Math.random() * diceBearStyles.length)];
    return `https://api.dicebear.com/9.x/${style}/svg?seed=${encodeURIComponent(username)}`;
  }

  function generateAnimeAvatarUrl(username) {
    return `https://anime.kirwako.com/api/avatar?name=${encodeURIComponent(username)}`;
  }

  function generateAvatarUrl(username) {
    const randomChoice = Math.random();
    return randomChoice < 0.5
      ? generateDiceBearAvatarUrl(username)
      : generateAnimeAvatarUrl(username);
  }

  const userIds = Array.from({ length: 100 }, () => uuidv4());

  async function generateUsers(userIds) {
    const users = [];
    for (let i = 0; i < userIds.length; i++) {
      const name = {
        first: faker.person.firstName(),
        last: faker.person.lastName(),
      };
      const username = `@${faker.internet.displayName({ firstName: name.first, lastName: name.last })}`;
      const avatarUrl = generateAvatarUrl(username);

      const user = `
              INSERT INTO PUBLIC.users (
                  id, 
                  username, 
                  display_name, 
                  world_location, 
                  avatar_url, 
                  bio, 
                  website, 
                  aura_tier, 
                  aura_level, 
                  aura_points, 
                  followers_count, 
                  following_count, 
                  created_at, 
                  updated_at, 
                  privacy_settings
              ) VALUES (
                  '${userIds[i]}',
                  '${escapeSqlString(username)}',
                  '${escapeSqlString(name.first + " " + name.last)}',
                  '${escapeSqlString(faker.location.city() + ", " + faker.location.country())}',
                  '${avatarUrl}',
                  '${escapeSqlString(faker.person.bio())}',
                  '${escapeSqlString(faker.internet.url())}',
                  '${auraTiers[Math.floor(Math.random() * auraTiers.length)]}',
                  ${Math.floor(Math.random() * 10) + 1},
                  ${Math.floor(Math.random() * 1000)},
                  ${Math.floor(Math.random() * 500)},
                  ${Math.floor(Math.random() * 500)},
                  '${faker.date.past().toISOString()}',
                  '${faker.date.recent().toISOString()}',
                  '{}'::jsonb
              );
          `;
      users.push(user);
    }
    return users;
  }

  function generateFollows(userIds, n) {
    const follows = new Set();
    const followStatements = [];

    while (follows.size < n) {
      const [follower, followed] = faker.helpers.shuffle(userIds).slice(0, 2);
      if (!follows.has(`${follower}-${followed}`) && follower !== followed) {
        follows.add(`${follower}-${followed}`);
        const follow = `
                  INSERT INTO PUBLIC.follows (
                      follower_id, 
                      followed_id, 
                      followed_at
                  ) VALUES (
                      '${follower}',
                      '${followed}',
                      '${faker.date.recent({ days: 30 }).toISOString()}'
                  );
              `;
        followStatements.push(follow);
      }
    }
    return followStatements;
  }

  function generateEvaluations(userIds, n) {
    const signs = ["positive", "negative"];
    const evaluations = new Set();
    const evaluationStatements = [];

    for (let i = 0; i < n; i++) {
      const [evaluator, evaluatee] = faker.helpers.shuffle(userIds).slice(0, 2);
      if (
        !evaluations.has(`${evaluator}-${evaluatee}`) &&
        evaluator !== evaluatee
      ) {
        evaluations.add(`${evaluator}-${evaluatee}`);
        const evaluation = `
                  INSERT INTO PUBLIC.evaluations (
                      id, 
                      evaluator_id, 
                      evaluatee_id, 
                      aura_points_used, 
                      sign, 
                      comment, 
                      created_at
                  ) VALUES (
                      '${uuidv4()}',
                      '${evaluator}',
                      '${evaluatee}',
                      ${Math.floor(Math.random() * 99999) + 1},
                      '${signs[i % 2]}',
                      '${escapeSqlString(faker.lorem.paragraph({ min: 1, max: 2 }))}',
                      '${faker.date.recent({ days: 30 }).toISOString()}'
                  );
              `;
        evaluationStatements.push(evaluation);
      }
    }
    return evaluationStatements;
  }

  async function run(taskName, taskFunction) {
    const spinner = ora({
      text: chalk.blue(`Starting ${taskName}...`),
      color: "blue",
      indent: 2,
    }).start();

    try {
      const result = await taskFunction();
      spinner.succeed(chalk.green(`${taskName} Created Successfully!`));
      return result;
    } catch (error) {
      spinner.fail(chalk.red(`${taskName} failed.`));
      console.error(chalk.red(error));
      throw error;
    }
  }

  async function generateData() {
    console.log(
      chalk("  ") + chalk.red.dim.bold("☘ Laura Data Generation 0.0.1\n"),
    );

    try {
      const usersSql = await run("Users", () => generateUsers(userIds));

      await new Promise((resolve) => setTimeout(resolve, 1000));
      const followsSql = await run("Followers", () =>
        generateFollows(userIds, 500),
      );

      await new Promise((resolve) => setTimeout(resolve, 1000));
      const evaluationsSql = await run("Evaluations", () =>
        generateEvaluations(userIds, 300),
      );

      await new Promise((resolve) => setTimeout(resolve, 1000));

      await run("SQL Snippet", () => {
        const combinedSql = [
          ...usersSql,
          ...followsSql,
          ...evaluationsSql,
        ].join("\n");
        fs.writeFileSync("./utils/supabase/data/insert.sql", combinedSql);
        return Promise.resolve();
      });
    } catch (error) {
      console.error(chalk.red("Data generation process encountered an error."));
    }

    console.log(
      chalk("\n  ") + chalk.red.dim.bold("☘ Data Generation Complete\n"),
    );
  }

  await generateData();
})();
