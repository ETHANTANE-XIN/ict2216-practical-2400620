(() => {
  "use strict";

  const MIN_LENGTH = 2;
  const MAX_LENGTH = 100;
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

  function validateSearchTerm(value) {
    const valueToCheck = value.trim();
    return (
      valueToCheck.length >= MIN_LENGTH &&
      valueToCheck.length <= MAX_LENGTH &&
      ALLOWED_SEARCH.test(valueToCheck) &&
      !containsAttackPattern(valueToCheck)
    );
  }

  const form = document.querySelector("#search-form");
  const input = document.querySelector("#search");
  const error = document.querySelector("#error");

  form.addEventListener("submit", (event) => {
    if (validateSearchTerm(input.value)) {
      return;
    }

    event.preventDefault();
    input.value = "";
    error.textContent =
      "Enter 2-100 characters using letters, numbers, spaces, dot, underscore or hyphen.";
    error.hidden = false;
    input.focus();
  });
})();
