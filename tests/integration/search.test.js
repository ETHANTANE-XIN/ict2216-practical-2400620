import assert from "node:assert/strict";
import test from "node:test";

const baseUrl = process.env.BASE_URL ?? "http://127.0.0.1:8080";

test("home page exposes the required search form", async () => {
  const response = await fetch(baseUrl);
  const body = await response.text();

  assert.equal(response.status, 200);
  assert.match(body, /id="search-form"/);
  assert.match(body, /name="search"/);
});

test("backend rejects an attack, clears it and stays on the home page", async () => {
  const response = await fetch(`${baseUrl}/search`, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ search: "<script>alert(1)</script>" }),
    redirect: "manual"
  });

  assert.equal(response.status, 303);
  assert.equal(response.headers.get("location"), "/");

  const homeResponse = await fetch(`${baseUrl}/`);
  const body = await homeResponse.text();
  assert.equal(homeResponse.status, 200);
  assert.match(body, /id="search-form"/);
  assert.doesNotMatch(body, /<script>alert\(1\)<\/script>/);
  assert.doesNotMatch(body, /value="<script/);
});

test("backend accepts and displays a safe term", async () => {
  const search = `integration-${Date.now()}`;
  const response = await fetch(`${baseUrl}/search`, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ search })
  });
  const body = await response.text();

  assert.equal(response.status, 200);
  assert.match(body, /Search Result/);
  assert.ok(body.includes(search));
  assert.match(body, /<button id="home-button" type="submit">Return to homepage<\/button>/);
});
