import fs from "fs";
import { v4 as uuidv4 } from "uuid";
import { faker } from "@faker-js/faker";
import chalk from "chalk";
import ora from "ora";
import path from "path";

const __dirname = path.dirname(decodeURI(new URL(import.meta.url).pathname));
const outputFilePath = path.join(__dirname, "../snippets/insert.sql");

function escapeSqlString(str) {
  return str.replace(/'/g, "''");
}

async function generateUsers(n) {
  const users = [];

  for (let i = 0; i < n; i++) {
    const id = uuidv4();
    const name = {
      firstName: faker.person.firstName(),
      lastName: faker.person.lastName(),
    };
    const userName = faker.internet.userName({
      firstName: name.firstName,
      lastName: name.lastName,
    });
    const userDisplayName = `${name.firstName} ${name.lastName}`;
    const userAvatarUrl = `https://api.dicebear.com/9.x/glass/svg?seed=${encodeURIComponent(userName)}`;
    const entityName = faker.company.name();
    const entityLogoUrl = `https://api.dicebear.com/9.x/bottts-neutral/svg?seed=${encodeURIComponent(entityName)}`;
    const bio = faker.lorem.paragraphs({ min: 5, max: 10 });
    const website = faker.internet.url();
    const worldLocation = `${faker.location.city()}, ${faker.location.country()}`;
    const essence = faker.number.int({ min: 50, max: 10000 });
    const aura = faker.number.int({ min: 0, max: 50000 });
    const createdAt = faker.date.recent().toISOString();
    const updatedAt = faker.date.recent().toISOString();

    users.push({
      id,
      userName,
      userDisplayName,
      userAvatarUrl,
      entityName,
      entityLogoUrl,
      bio,
      website,
      worldLocation,
      essence,
      aura,
      createdAt,
      updatedAt,
    });
  }

  const userInserts = users
    .map((user) => {
      return `(
        '${user.id}',
        '${escapeSqlString(user.userName)}',
        '${escapeSqlString(user.userDisplayName)}',
        '${escapeSqlString(user.userAvatarUrl)}',
        '${escapeSqlString(user.entityName)}',
        '${escapeSqlString(user.entityLogoUrl)}',
        '${escapeSqlString(user.bio)}',
        '${escapeSqlString(user.website)}',
         ${user.aura},  
         ${user.essence},
        '${escapeSqlString(user.worldLocation)}',
        '${user.createdAt}',
        '${user.updatedAt}'
      )`;
    })
    .join(",\n");

  return {
    sql: `
        INSERT INTO users (
          id, user_name, user_display_name, user_avatar_url, entity_name, entity_logo_url, bio, website, aura, essence, world_location, created_at, updated_at
        ) VALUES
        ${userInserts};
      `,
    userIds: users.map((user) => user.id),
  };
}

async function generateFollows(userIds, n) {
  const follows = new Set();
  const followStatements = [];

  while (follows.size < n) {
    const [followerId, followedId] = faker.helpers.shuffle(userIds).slice(0, 2);

    if (
      followerId !== followedId &&
      !follows.has(`${followerId}-${followedId}`)
    ) {
      follows.add(`${followerId}-${followedId}`);

      followStatements.push(`(
        '${followerId}',
        '${followedId}',
        '${faker.date.recent().toISOString()}'
      )`);
    }
  }

  return `
    INSERT INTO follows (follower_id, followed_id, followed_at) VALUES
    ${followStatements.join(",\n")};
  `;
}

async function generateEvaluationsAndAuraHistory(userIds, n) {
  const evaluations = [];
  const auraHistory = [];

  for (let i = 0; i < n; i++) {
    const [evaluatorId, evaluateeId] = faker.helpers
      .shuffle(userIds)
      .slice(0, 2);
    const essenceUsed = faker.number.int({ min: 10, max: 1000 });
    const auraChange = faker.number.int({ min: -100, max: 500 });
    const createdAt = faker.date.recent().toISOString();
    const comment = faker.lorem.sentences(2);

    evaluations.push(`(
      '${uuidv4()}',
      '${evaluatorId}',
      '${evaluateeId}',
      ${essenceUsed},
      '${escapeSqlString(comment)}',
      '${createdAt}'
    )`);

    auraHistory.push(`(
      '${uuidv4()}',
      '${evaluateeId}',
      ${auraChange},
      '${createdAt}'
    )`);
  }

  const evaluationsSql = `
    INSERT INTO evaluations (id, evaluator_id, evaluatee_id, essence_used, comment, created_at) VALUES
    ${evaluations.join(",\n")};
  `;

  const auraHistorySql = `
    INSERT INTO aura_history (id, user_id, aura_change, created_at) VALUES
    ${auraHistory.join(",\n")};
  `;

  return [evaluationsSql, auraHistorySql];
}

async function generateData() {
  const spinner = ora("Generating users...").start();

  try {
    const numberOfUsers = 1000;
    const numberOfFollows = 10 * numberOfUsers;
    const numberOfEvaluations = 1000;

    const { sql: usersSql, userIds } = await generateUsers(numberOfUsers);

    spinner.succeed("Users generated.");

    spinner.start("Generating follows...");
    const followsSql = await generateFollows(userIds, numberOfFollows);
    spinner.succeed("Follows generated.");

    spinner.start("Generating evaluations and aura history...");
    const [evaluationsSql, auraHistorySql] =
      await generateEvaluationsAndAuraHistory(userIds, numberOfEvaluations);
    spinner.succeed("Evaluations and aura history generated.");

    const combinedSql = [
      usersSql,
      followsSql,
      evaluationsSql,
      auraHistorySql,
    ].join("\n\n");

    const libraryDir = path.dirname(outputFilePath);
    if (!fs.existsSync(libraryDir)) {
      fs.mkdirSync(libraryDir);
    }

    fs.writeFileSync(outputFilePath, combinedSql);
    console.log(chalk.green(`✅ SQL script written to ${outputFilePath}`));
  } catch (error) {
    spinner.fail("Data generation failed.");
    console.error(chalk.red(error));
  }
}

generateData();
