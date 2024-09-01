const { faker } = require("@faker-js/faker");
const fs = require("fs");
const { v4: uuidv4 } = require("uuid");

// Aura tiers for random selection
const auraTiers = ["common", "fading", "radiant", "ethereal", "shadowed"];

// List of available DiceBear styles
const diceBearStyles = ["thumbs"];

// Function to escape single quotes in strings for SQL
function escapeSqlString(str) {
  return str.replace(/'/g, "''");
}

// Function to generate a DiceBear avatar URL
function generateDiceBearAvatarUrl(username) {
  const style =
    diceBearStyles[Math.floor(Math.random() * diceBearStyles.length)];
  return `https://api.dicebear.com/9.x/${style}/svg?seed=${encodeURIComponent(username)}`;
}

// Function to generate an Anime avatar URL
function generateAnimeAvatarUrl(username) {
  return `https://anime.kirwako.com/api/avatar?name=${encodeURIComponent(username)}`;
}

// Function to randomly select an avatar service
function generateAvatarUrl(username) {
  const randomChoice = Math.random();
  if (randomChoice < 0.5) {
    // 50% chance to use DiceBear
    return generateDiceBearAvatarUrl(username);
  } else {
    // 50% chance to use Anime avatar
    return generateAnimeAvatarUrl(username);
  }
}

// Generate a consistent set of user IDs for all operations
const userIds = Array.from({ length: 100 }, () => uuidv4());

// Function to generate users with avatars from multiple services
async function generateUsers(userIds) {
  const users = [];
  for (let i = 0; i < userIds.length; i++) {
    const name = {
      first: faker.name.firstName(),
      last: faker.name.lastName(),
    };
    const username = `@${faker.internet.displayName({ firstName: name.first, lastName: name.last })}`;
    const avatarUrl = generateAvatarUrl(username); // Generate avatar URL using a random service

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
                '${escapeSqlString(faker.lorem.sentence())}',
                '${escapeSqlString(faker.internet.url())}',
                '${auraTiers[Math.floor(Math.random() * auraTiers.length)]}',
                ${Math.floor(Math.random() * 10) + 1},
                ${Math.floor(Math.random() * 1000)},
                ${Math.floor(Math.random() * 500)},
                ${Math.floor(Math.random() * 500)},
                '${faker.date.past(2).toISOString()}',
                '${faker.date.recent().toISOString()}',
                '{}'::jsonb
            );
        `;
    users.push(user);
  }
  return users;
}

// Function to generate follows
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
                    '${faker.date.recent(30).toISOString()}'
                );
            `;
      followStatements.push(follow);
    }
  }
  return followStatements;
}

// Function to generate evaluations with more realistic comments
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
                    '${escapeSqlString(faker.lorem.sentence())} ${escapeSqlString(faker.lorem.sentences(Math.floor(Math.random() * 2) + 1))}',
                    '${faker.date.recent(30).toISOString()}'
                );
            `;
      evaluationStatements.push(evaluation);
    }
  }
  return evaluationStatements;
}

// Main function to orchestrate the data generation and writing to a file
async function generateData() {
  const followCount = 500;
  const evaluationCount = 300;

  // Ensure users are generated first and use the same IDs
  const usersSql = await generateUsers(userIds); // Note: We're using await since generateUsers is now async
  const followsSql = generateFollows(userIds, followCount);
  const evaluationsSql = generateEvaluations(userIds, evaluationCount);

  // Combine all SQL statements into one file
  const combinedSql = [...usersSql, ...followsSql, ...evaluationsSql].join(
    "\n",
  );

  // Write to a single SQL file
  fs.writeFileSync("./utils/supabase/data/insert.sql", combinedSql);

  console.log("Combined SQL file generated successfully!");
}

// Run the data generation script
generateData();
