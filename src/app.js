import express from "express";
import helmet from "helmet";

import { databaseIsReady, logSearch } from "./db.js";
import { homePage, resultPage } from "./pages.js";
import { validateSearchTerm } from "./validation.js";

export const app = express();

app.disable("x-powered-by");
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'"],
        styleSrc: ["'self'"],
        objectSrc: ["'none'"],
        baseUri: ["'none'"],
        frameAncestors: ["'none'"],
        upgradeInsecureRequests: null
      }
    },
    strictTransportSecurity: false
  })
);
app.use(express.urlencoded({ extended: false, limit: "2kb", parameterLimit: 5 }));
app.use(express.static("public", { dotfiles: "deny", maxAge: "1h" }));

app.get("/", (_request, response) => {
  response.type("html").send(homePage());
});

app.post("/search", async (request, response, next) => {
  const validation = validateSearchTerm(request.body.search);
  if (!validation.valid) {
    response.redirect(303, "/");
    return;
  }

  try {
    await logSearch(validation.value);
    response.type("html").send(resultPage(validation.value));
  } catch (error) {
    next(error);
  }
});

app.get("/health", async (_request, response) => {
  try {
    await databaseIsReady();
    response.json({ status: "ok" });
  } catch {
    response.status(503).json({ status: "unavailable" });
  }
});

app.use((_request, response) => {
  response.status(404).type("text").send("Not found");
});

app.use((error, _request, response, _next) => {
  console.error("Request failed", error instanceof Error ? error.name : "Error");
  response.status(500).type("html").send(homePage("Search is temporarily unavailable."));
});
