import security from "eslint-plugin-security";

export default [
  {
    ignores: ["node_modules/**", "reports/**", ".scannerwork/**"]
  },
  {
    files: ["**/*.js"],
    plugins: { security },
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      globals: {
        console: "readonly",
        document: "readonly",
        process: "readonly",
        URL: "readonly",
        URLSearchParams: "readonly",
        fetch: "readonly"
      }
    },
    rules: {
      "no-eval": "error",
      "no-implied-eval": "error",
      "no-new-func": "error",
      ...security.configs.recommended.rules
    }
  }
];
