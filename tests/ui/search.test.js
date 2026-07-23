import assert from "node:assert/strict";
import test from "node:test";
import { Builder, By, until } from "selenium-webdriver";

const baseUrl = process.env.BASE_URL ?? "http://127.0.0.1:8080";
const seleniumUrl =
  process.env.SELENIUM_URL ?? "http://127.0.0.1:4444/wd/hub";

test("browser validation rejects attacks and accepts a safe search", async () => {
  const driver = await new Builder()
    .forBrowser("chrome")
    .usingServer(seleniumUrl)
    .build();

  try {
    await driver.get(baseUrl);
    const input = await driver.findElement(By.id("search"));
    await input.sendKeys("<script>alert(1)</script>");
    await driver.findElement(By.css('button[type="submit"]')).click();

    await driver.wait(until.elementIsVisible(driver.findElement(By.id("error"))));
    assert.equal(await input.getAttribute("value"), "");
    assert.equal(new URL(await driver.getCurrentUrl()).pathname, "/");

    const safeTerm = `ui-${Date.now()}`;
    await input.sendKeys(safeTerm);
    await driver.findElement(By.css('button[type="submit"]')).click();
    await driver.wait(until.elementLocated(By.id("result")));

    assert.ok(
      (await driver.findElement(By.id("result")).getText()).includes(safeTerm)
    );
    await driver.findElement(By.id("home-button")).click();
    await driver.wait(until.elementLocated(By.id("search-form")));
  } finally {
    await driver.quit();
  }
});
