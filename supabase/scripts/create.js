const fs = require("fs");
const path = require("path");

// Get the directory from the command line arguments
const snippetsDir = process.argv[2];

// List of SQL files to include (excluding '10.Data.sql')
const filesToInclude = [
  "1. Reset.sql",
  "2. Types.sql",
  "3. Tables.sql",
  "4. Views.sql",
  "5. Indexing.sql",
  "6. Policies.sql",
  "7. Functions.sql",
  "8. Triggers.sql",
];

// Output file
const outputFile = path.join(snippetsDir, "11. Combined.sql");

// Function to join all the SQL files
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

// Check if the path argument is provided
if (!snippetsDir) {
  console.error(
    "Please provide the path to the snippets directory as an argument.",
  );
  process.exit(1);
}

// Execute the function
joinSQLFiles();
