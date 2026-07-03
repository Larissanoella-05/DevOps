const globals = require("globals");

module.exports = [
  {
    // Backend: Node/CommonJS runtime.
    files: ["Backend/**/*.js"],
    languageOptions: {
      sourceType: "commonjs",
      ecmaVersion: 2022,
      globals: globals.node,
    },
    rules: {
      "no-unused-vars": "error",
      "no-undef": "error",
      eqeqeq: "error",
      "no-var": "error",
    },
  },
  {
    // Frontend: plain <script> in the browser, not a module bundle.
    files: ["Frontend/**/*.js"],
    languageOptions: {
      sourceType: "script",
      ecmaVersion: 2022,
      globals: globals.browser,
    },
    rules: {
      "no-unused-vars": "error",
      "no-undef": "error",
      eqeqeq: "error",
      "no-var": "error",
    },
  },
  {
    ignores: ["**/node_modules/**", "Backend/agripulse.db"],
  },
];
