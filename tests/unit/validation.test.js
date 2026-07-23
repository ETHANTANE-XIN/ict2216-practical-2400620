import assert from "node:assert/strict";
import test from "node:test";

import {
  MAX_SEARCH_LENGTH,
  validateSearchTerm
} from "../../src/validation.js";

test("accepts an ordinary search term and trims it", () => {
  assert.deepEqual(validateSearchTerm("  secure coding  "), {
    valid: true,
    value: "secure coding",
    reason: ""
  });
});

test("rejects terms below and above the length limits", () => {
  assert.equal(validateSearchTerm("a").valid, false);
  assert.equal(validateSearchTerm("a".repeat(MAX_SEARCH_LENGTH + 1)).valid, false);
});

test("rejects XSS and SQL injection examples", () => {
  const attacks = [
    "<script>alert(1)</script>",
    "1 OR 1=1",
    "hello' UNION SELECT password",
    "union select credentials",
    "javascript:alert(1)"
  ];

  for (const attack of attacks) {
    const result = validateSearchTerm(attack);
    assert.equal(result.valid, false);
    assert.equal(result.value, "");
  }
});

test("rejects repeated fields and non-string values", () => {
  assert.equal(validateSearchTerm(["one", "two"]).valid, false);
  assert.equal(validateSearchTerm(undefined).valid, false);
});
