const fs = require("fs");
const { v4: uuidv4 } = require("uuid");
const { faker } = require("@faker-js/faker");

(async () => {
  const chalk = (await import("chalk")).default;
  const ora = (await import("ora")).default;

  function escapeSqlString(str) {
    return str.replace(/'/g, "''");
  }

  function generateDiceBearAvatarUrl(username) {
    const style = "thumbs"; // Simplified for consistency
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

  // Initial Aura Points and Levels for Users
  const userStats = userIds.reduce((acc, id) => {
    acc[id] = {
      essence: Math.floor(Math.random() * 10_000_000), // Large initial aura points
      aura: 0,
      level: "common",
    };
    return acc;
  }, {});

  function calculateAuraLevel(auraPoints) {
    return Math.floor(auraPoints / 1000); // Adjust scaling to achieve higher aura levels
  }

  function calculateAuraTier(auraLevel) {
    if (auraLevel > 1_000_000) return "ethereal";
    if (auraLevel > 500_000) return "radiant";
    if (auraLevel > 100_000) return "fading";
    if (auraLevel >= 0) return "common";
    return "shadowed";
  }

  async function generateUsers(userIds) {
    const users = [];
    for (let i = 0; i < userIds.length; i++) {
      const name = {
        first: faker.person.firstName(),
        last: faker.person.lastName(),
      };
      const username = `@${faker.internet.displayName({ firstName: name.first, lastName: name.last })}`;
      const avatarUrl = generateAvatarUrl(username);

      const essence = userStats[userIds[i]].essence;
      const aura = calculateAuraLevel(essence);
      const level = calculateAuraTier(aura);

      const user = `(
        '${userIds[i]}',
        '${escapeSqlString(username)}',
        '${escapeSqlString(name.first + " " + name.last)}',
        '${escapeSqlString(faker.location.city() + ", " + faker.location.country())}',
        '${avatarUrl}',
        '${escapeSqlString(faker.person.bio())}',
        '${escapeSqlString(faker.internet.url())}',
        '${level}',
        ${aura},
        ${essence},
        ${Math.floor(Math.random() * 500)},
        ${Math.floor(Math.random() * 500)},
        '${faker.date.past().toISOString()}',
        '${faker.date.recent().toISOString()}',
        '{}'::jsonb
      )`;
      users.push(user);
    }

    const combinedUsersSql = `
      INSERT INTO PUBLIC.users (
          id, username, display_name, world_location, avatar_url, bio, website, level, aura, essence, followers_count, following_count, created_at, updated_at, privacy_settings
      ) VALUES
      ${users.join(",\n")};
    `;

    return combinedUsersSql;
  }

  function generateFollows(userIds, n) {
    const follows = new Set();
    const followStatements = [];

    while (follows.size < n) {
      const [follower, followed] = faker.helpers.shuffle(userIds).slice(0, 2);
      if (!follows.has(`${follower}-${followed}`) && follower !== followed) {
        follows.add(`${follower}-${followed}`);
        const follow = `(
          '${follower}',
          '${followed}',
          '${faker.date.recent({ days: 30 }).toISOString()}'
        )`;
        followStatements.push(follow);
      }
    }

    const combinedFollowsSql = `
      INSERT INTO PUBLIC.follows (
          follower_id, followed_id, followed_at
      ) VALUES
      ${followStatements.join(",\n")};
    `;

    return combinedFollowsSql;
  }

  function generateEvaluations(userIds, n) {
    const signs = ["positive", "negative"];
    const evaluations = [];
    const evaluationStatements = [];

    for (let i = 0; i < n; i++) {
      const [evaluator, evaluatee] = faker.helpers.shuffle(userIds).slice(0, 2);
      const isReply = Math.random() < 0.3; // 30% chance to be a reply
      let parentId = null;

      if (isReply && evaluations.length > 0) {
        const parentEvaluation = faker.helpers.arrayElement(evaluations);
        parentId = parentEvaluation.id;
      }

      const essence_change = Math.floor(Math.random() * 500_000) + 1;
      const essence_used =
        signs[i % 2] === "positive" ? essence_change : -essence_change;

      // Update the evaluatee's aura points and level
      const evaluateeStats = userStats[evaluatee];
      evaluateeStats.essence += essence_used;
      evaluateeStats.aura = calculateAuraLevel(evaluateeStats.essence);
      evaluateeStats.level = calculateAuraTier(evaluateeStats.aura);

      const evaluationId = uuidv4();
      const evaluation = {
        id: evaluationId,
        evaluator_id: evaluator,
        evaluatee_id: evaluatee,
        essence_used: Math.abs(essence_used),
        sign: signs[i % 2],
        comment: escapeSqlString(faker.lorem.paragraph({ min: 1, max: 2 })),
        created_at: faker.date.recent({ days: 30 }).toISOString(),
        parent_id: parentId,
      };

      evaluations.push(evaluation);

      const evaluationSql = `(
        '${evaluationId}',
        '${evaluator}',
        '${evaluatee}',
        ${evaluation.essence_used},
        '${evaluation.sign}',
        '${evaluation.comment}',
        '${evaluation.created_at}',
        ${evaluation.parent_id ? `'${evaluation.parent_id}'` : "NULL"}
      )`;
      evaluationStatements.push(evaluationSql);
    }

    const combinedEvaluationsSql = `
      INSERT INTO PUBLIC.evaluations (
          id, evaluator_id, evaluatee_id, essence_used, sign, comment, created_at, parent_id
      ) VALUES
      ${evaluationStatements.join(",\n")};
    `;

    return combinedEvaluationsSql;
  }

  function generateAuditLogs(userIds, n) {
    const actions = ["INSERT", "UPDATE", "DELETE"];
    const tables = ["users", "follows", "evaluations"];
    const auditLogStatements = [];

    for (let i = 0; i < n; i++) {
      const userId = faker.helpers.arrayElement(userIds);
      const action = faker.helpers.arrayElement(actions);
      const tableName = faker.helpers.arrayElement(tables);
      const changedData = escapeSqlString(
        JSON.stringify({
          key: "value", // You can customize this to represent realistic changes
        }),
      );

      const auditLogSql = `(
        '${uuidv4()}',
        '${userId}',
        '${action}',
        '${tableName}',
        '${changedData}'::jsonb,
        '${faker.date.recent({ days: 30 }).toISOString()}'
      )`;
      auditLogStatements.push(auditLogSql);
    }

    const combinedAuditLogsSql = `
      INSERT INTO PUBLIC.audit_log (
          id, user_id, action, table_name, changed_data, action_time
      ) VALUES
      ${auditLogStatements.join(",\n")};
    `;

    return combinedAuditLogsSql;
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
      const auditLogsSql = await run("Audit Logs", () =>
        generateAuditLogs(userIds, 100),
      );

      await new Promise((resolve) => setTimeout(resolve, 1000));

      await run("SQL Snippet", () => {
        const combinedSql = [
          usersSql,
          followsSql,
          evaluationsSql,
          auditLogsSql,
        ].join("\n\n");
        fs.writeFileSync("./supabase/snippets/10. Data.sql", combinedSql);
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
