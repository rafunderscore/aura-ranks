import { fixupConfigRules, fixupPluginRules } from "@eslint/compat";
import { FlatCompat } from "@eslint/eslintrc";
import js from "@eslint/js";
import typescriptEslint from "@typescript-eslint/eslint-plugin";
import tsParser from "@typescript-eslint/parser";
import _import from "eslint-plugin-import";
import globals from "globals";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: js.configs.recommended,
  allConfig: js.configs.all,
});

/** @type { import("eslint").Linter.Config[] } */
export default [
  ...fixupConfigRules(
    compat.extends(
      "plugin:@next/next/recommended",
      "eslint:recommended",
      "plugin:@typescript-eslint/recommended",
      "plugin:import/errors",
      "plugin:import/warnings",
      "plugin:import/typescript",
      "prettier",
    ),
  ),
  {
    ignores: [
      "**/next.config.mjs",
      "**/scripts/**/*",
      "**/openapi/**/*",
      "**/public/**/*",
      ".next/**/*",
    ],
  },
  {
    files: ["**/*.js", "**/*.jsx", "**/*.ts", "**/*.tsx"],
  },
  {
    plugins: {
      "@typescript-eslint": fixupPluginRules(typescriptEslint),
      import: fixupPluginRules(_import),
    },
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
      },

      parser: tsParser,

      ecmaVersion: 2021,
      sourceType: "module",

      parserOptions: {
        ecmaFeatures: {
          jsx: true,
        },

        project: "./tsconfig.json",
      },
    },
    settings: {
      "import/parsers": {
        "@typescript-eslint/parser": [".ts", ".tsx", ".js", ".jsx"],
      },
      "import/resolver": {
        node: {
          extensions: [".js", ".jsx", ".ts", ".tsx"],
          paths: ["src"],
        },
        typescript: {
          alwaysTryTypes: true,
          project: "./tsconfig.json",
        },
      },
    },
    rules: {
      "@typescript-eslint/no-unused-vars": "error",
      "@typescript-eslint/no-explicit-any": "off",
      "import/newline-after-import": "error",
      "import/no-named-as-default": "off",
      "import/no-duplicates": "error",
      "import/no-unresolved": "error",
      "import/export": "error",
      "import/order": [
        "error",
        {
          groups: [
            ["builtin", "external", "internal"],
            ["parent", "sibling", "index"],
            "type",
          ],

          pathGroups: [
            {
              pattern: "@/**",
              group: "internal",
              position: "after",
            },
          ],

          "newlines-between": "always",

          alphabetize: {
            order: "asc",
            caseInsensitive: true,
          },
        },
      ],
    },
  },
];
