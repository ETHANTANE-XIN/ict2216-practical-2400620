export const MIN_SEARCH_LENGTH = 2;
export const MAX_SEARCH_LENGTH = 100;

const ALLOWED_SEARCH = /^[A-Za-z0-9][A-Za-z0-9 ._-]*$/;
const BLOCKED_FRAGMENTS = [
  "<script",
  "</script",
  "javascript:",
  " union select ",
  " drop table ",
  " delete from ",
  " insert into ",
  "--",
  "/*",
  "*/"
];

function containsAttackPattern(value) {
  const lowerCaseValue = ` ${value.toLowerCase()} `;
  return BLOCKED_FRAGMENTS.some((fragment) =>
    lowerCaseValue.includes(fragment)
  );
}

export function validateSearchTerm(value) {
  if (typeof value !== "string") {
    return { valid: false, value: "", reason: "Enter one search term." };
  }

  const valueToCheck = value.trim();
  if (
    valueToCheck.length < MIN_SEARCH_LENGTH ||
    valueToCheck.length > MAX_SEARCH_LENGTH
  ) {
    return {
      valid: false,
      value: "",
      reason: `Search term must be ${MIN_SEARCH_LENGTH}-${MAX_SEARCH_LENGTH} characters.`
    };
  }

  if (containsAttackPattern(valueToCheck) || !ALLOWED_SEARCH.test(valueToCheck)) {
    return {
      valid: false,
      value: "",
      reason: "Search term contains unsupported or unsafe characters."
    };
  }

  return { valid: true, value: valueToCheck, reason: "" };
}
