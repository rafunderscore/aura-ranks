import fs from "fs";
import path from "path";

const snippetsDir = process.argv[2];

const filesToInclude = [
  "reset.sql",
  "tables.sql",
  "views.sql",
  "functions.sql",
  "indexing.sql",
  "policies.sql",
  "triggers.sql",
];

const outputFile = path.join(snippetsDir, "./library/combined.sql");

function joinSQLFiles() {
  let combinedSQL = "";

  filesToInclude.forEach((fileName) => {
    const filePath = path.join(snippetsDir, fileName);
    const fileContent = fs.readFileSync(filePath, "utf8");
    combinedSQL += `-- ${fileName}\n${fileContent}\n\n`;
  });

  fs.writeFileSync(outputFile, combinedSQL);
  console.log(`All SQL files combined into ${outputFile}`);
}

if (!snippetsDir) {
  console.error(
    "Please provide the path to the snippets directory as an argument.",
  );
  process.exit(1);
}

joinSQLFiles();
