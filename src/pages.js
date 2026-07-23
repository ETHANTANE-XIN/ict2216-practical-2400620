import { MAX_SEARCH_LENGTH, MIN_SEARCH_LENGTH } from "./validation.js";

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function layout(title, body, script = "") {
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeHtml(title)}</title>
  <link rel="stylesheet" href="/style.css">
  ${script}
</head>
<body>
  <main>${body}</main>
</body>
</html>`;
}

export function homePage(error = "") {
  const errorText = error
    ? `<p id="error" role="alert">${escapeHtml(error)}</p>`
    : '<p id="error" role="alert" hidden></p>';

  return layout(
    "Secure Search",
    `<h1>Secure Search</h1>
${errorText}
<form id="search-form" action="/search" method="post" novalidate>
  <label for="search">Search term</label>
  <input
    id="search"
    name="search"
    type="text"
    required
    minlength="${MIN_SEARCH_LENGTH}"
    maxlength="${MAX_SEARCH_LENGTH}"
    autocomplete="off"
  >
  <button type="submit">Search</button>
</form>`,
    '<script src="/app.js" defer></script>'
  );
}

export function resultPage(searchTerm) {
  return layout(
    "Search Result",
    `<h1>Search Result</h1>
<p id="result">You searched for: <strong>${escapeHtml(searchTerm)}</strong></p>
<form action="/" method="get">
  <button id="home-button" type="submit">Return to homepage</button>
</form>`
  );
}
