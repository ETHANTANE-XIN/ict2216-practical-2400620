import assert from "node:assert/strict";
import test from "node:test";

import { homePage, resultPage } from "../../src/pages.js";

test("home page includes the required controls and length limits", () => {
  const page = homePage();

  assert.ok(page.includes('id="search-form"'));
  assert.ok(page.includes('minlength="2"'));
  assert.ok(page.includes('maxlength="100"'));
  assert.ok(page.includes('id="error" role="alert" hidden'));
});

test("home page and result page HTML-encode dynamic text", () => {
  const unsafeText = '<img src=x onerror="alert(1)">';
  const errorPage = homePage(unsafeText);
  const result = resultPage(unsafeText);

  assert.ok(errorPage.includes("&lt;img"));
  assert.ok(result.includes("&lt;img"));
  assert.ok(!errorPage.includes(unsafeText));
  assert.ok(!result.includes(unsafeText));
  assert.ok(
    result.includes(
      '<button id="home-button" type="submit">Return to homepage</button>'
    )
  );
});
