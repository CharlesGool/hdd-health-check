// Static HTTP/session runner and synthetic APIs: never access disks or run a scheduler.
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { createRequire } from "node:module";
import { mkdir, readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { resolve } from "node:path";
import { createInterface } from "node:readline";
const root = fileURLToPath(new URL("../", import.meta.url));
const { chromium } = createRequire(
  new URL("../src/web/package.json", import.meta.url),
)("playwright");
const preview = spawn(
  process.env.PYTHON || "python3",
  ["tests/fixtures/web-preview.py"],
  { cwd: root, stdio: ["ignore", "pipe", "inherit"] },
);
let browser;
const lines = createInterface({ input: preview.stdout });
const errors = [];
const output = resolve(root, ".local/verification/ui");
const build = JSON.parse(
  await readFile(resolve(root, "dist/web/version.json"), "utf8"),
);
let scenarios = 0;
try {
  const port = await new Promise((accept, reject) => {
    const timer = setTimeout(
      () => reject(new Error("Preview startup timed out")),
      10000,
    );
    lines.once("line", (line) => {
      clearTimeout(timer);
      accept(Number(line));
    });
    preview.once("exit", (code) => {
      clearTimeout(timer);
      reject(new Error(`Preview exited: ${code}`));
    });
  });
  const base = `http://127.0.0.1:${port}`;
  browser = await chromium.launch({
    headless: true,
    ...(process.env.PLAYWRIGHT_EXECUTABLE_PATH
      ? { executablePath: process.env.PLAYWRIGHT_EXECUTABLE_PATH }
      : {}),
  });
  const page = await browser.newPage({
    hasTouch: true,
    viewport: { width: 1280, height: 900 },
    hasTouch: true,
  });
  page.on("pageerror", (error) => errors.push(error.message));
  page.on("console", (message) => {
    if (message.type() === "error") errors.push(message.text());
  });
  const screenshot = async (name) => {
    if (process.env.UI_SCREENSHOTS === "1") {
      await mkdir(output, { recursive: true });
      await page.screenshot({
        path: resolve(output, `${name}.png`),
        fullPage: true,
      });
    }
  };
  const visit = async (path, width, mode) => {
    await page.setViewportSize({ width, height: 900 });
    await page.addInitScript(
      ({ mode }) => {
        localStorage.setItem("hdd-mode", mode);
        localStorage.setItem("hdd-lang", "en");
      },
      { mode },
    );
    const response = await page.goto(base + path);
    assert.equal(response.status(), 200);
    await page.locator("h1").waitFor();
    await page.waitForTimeout(1100);
    assert.equal(await page.locator("h1").count(), 1);
    assert(
      await page.evaluate(
        () => document.documentElement.scrollWidth <= innerWidth,
      ),
      `${path}: overflow at ${width}`,
    );
    scenarios++;
  };
  for (const width of [1280, 375])
    for (const mode of ["light", "dark"]) {
      await visit("/disks", width, mode);
      assert.equal(
        await page.locator("#login-password").getAttribute("type"),
        "password",
      );
      assert.equal(
        await page.locator(".app-login-version").textContent(),
        build.version,
      );
      assert.equal(await page.locator(".app-login-action").count(), 2);
      assert(
        (await page.locator(".app-login-card").boundingBox()).width <= 480,
      );
      assert((await page.locator("header").boundingBox()).height >= 72);
      assert(
        (await page.locator("#login-password").boundingBox()).height >= 48,
      );
      await screenshot(`login-${mode}-${width}`);
    }
  // Authenticate against the real server; all disk-dependent endpoints are intercepted first.
  const disks = Array.from({ length: 7 }, (_, index) => ({
    name: `sd${String.fromCharCode(97 + index)}`,
    model: `Synthetic HDD ${index + 1}`,
    size: "4 TB",
    bytes: 4e12,
    serial: "••••1234",
    rotation: "1",
    transport: "sata",
    temperature: 32,
    temperatureState: "available",
    score: null,
    coverage: "partial",
    grade: "unknown",
    level: 0,
    stale: 0,
    modules: [],
  }));
  await page.route("**/api/**", async (route) => {
    const path = new URL(route.request().url()).pathname;
    if (path.startsWith("/api/auth") || path === "/api/build")
      return route.continue();
    const data =
      path === "/api/snapshot"
        ? {
            version: "4.1.0",
            disks,
            storage: { totalBytes: 28e12, usedBytes: 2e12 },
          }
        : path === "/api/status"
          ? { running: false, text: "", job: null }
          : path === "/api/schedule"
            ? { enabled: false, hours: 24, last: 0, attempt: 0, error: "" }
            : path === "/api/preferences"
              ? { wakeSleepingOnVisit: false }
              : path === "/api/access"
                ? { enabled: false, ips: [] }
                : path === "/api/jobs/history"
                  ? { jobs: [] }
                  : path === "/api/history/samples"
                    ? { samples: [] }
                    : path.endsWith("/smart")
                      ? {
                          available: true,
                          model: "Synthetic HDD 1",
                          serial: "••••1234",
                          protocol: "ATA",
                          capacity: 4e12,
                          passed: true,
                          temperature: 32,
                          powerOnHours: 100,
                          attributes: [
                            {
                              key: "Reallocated_Sector_Ct",
                              value: "0",
                              id: 5,
                              normalized: 100,
                              threshold: 10,
                            },
                          ],
                        }
                      : path.endsWith("/serial")
                        ? { serial: "SYNTHETIC-SERIAL-1234" }
                        : null;
    assert.notEqual(data, null, `Unexpected disk API ${path}`);
    await route.fulfill({ json: data });
  });
  await page.locator("#login-password").fill("synthetic-preview-password");
  await page
    .locator("form")
    .getByRole("button", { name: "Sign in", exact: true })
    .click();
  await page.locator(".dashboard-grid").waitFor();
  assert.deepEqual(
    await page.evaluate(() => fetch("/api/build").then((r) => r.json())),
    build,
  );
  for (const width of [1280, 375])
    for (const mode of ["light", "dark"])
      for (const path of [
        "/disks",
        "/settings",
        "/security",
        "/attention",
        "/tasks",
        "/schedule",
        "/changelog",
        "/disks/sda",
      ]) {
        await visit(path, width, mode);
        assert.equal(
          await page.locator(".brand-version").textContent(),
          build.version,
        );
        assert.equal(await page.locator("header nav a").count(), 3);
        if (path === "/disks") {
          const cards = await page.locator(".disk-cards .disk-card").all();
          assert.equal(cards.length, 7);
          const boxes = await Promise.all(
            cards.map((card) => card.boundingBox()),
          );
          for (let i = 0; i < boxes.length; i++)
            for (let j = i + 1; j < boxes.length; j++) {
              const a = boxes[i],
                b = boxes[j];
              assert(
                a.x + a.width <= b.x + 1 ||
                  b.x + b.width <= a.x + 1 ||
                  a.y + a.height <= b.y + 1 ||
                  b.y + b.height <= a.y + 1,
                "Disk cards overlap",
              );
            }
          const dashboard = await page.locator(".dashboard-grid").boundingBox();
          const storage = await page.locator(".storage-summary").boundingBox();
          assert(
            dashboard.y + dashboard.height <= storage.y + 1,
            "Dashboard overlaps storage summary",
          );
          const controls = await page
            .locator(".assessment-controls")
            .boundingBox();
          const note = await page.locator(".assessment-note").boundingBox();
          assert(
            controls.y + controls.height <= note.y + 1,
            "Assessment controls overlap note",
          );
          const last = await cards.at(-1).boundingBox();
          const grid = await page.locator(".disk-cards").boundingBox();
          const padding = await page.locator(".disk-cards").evaluate((el) => {
            const s = getComputedStyle(el);
            return parseFloat(s.paddingLeft) + parseFloat(s.paddingRight);
          });
          assert(
            Math.abs(last.width - (grid.width - padding)) <= 2,
            "Last-row card must fill its row",
          );
          assert(
            (
              await page
                .locator(".assessment-panel > div:first-child")
                .boundingBox()
            ).width >
              (await page.locator(".assessment-panel").boundingBox()).width *
                0.7,
            "Assessment explanation squeezed",
          );
        }
        if (path === "/changelog")
          assert(
            (await page.locator(".markdown-body").allTextContents())
              .join("")
              .includes("v4.1.0"),
          );
        await screenshot(
          `${path.slice(1).replaceAll("/", "-")}-${mode}-${width}`,
        );
      }
  const tabs = page.getByRole("tab");
  await tabs.first().focus();
  await page.keyboard.press("ArrowRight");
  assert.equal(await tabs.nth(1).getAttribute("aria-selected"), "true");
  await page.keyboard.press("Home");
  assert.equal(await tabs.first().getAttribute("aria-selected"), "true");
  await page.waitForTimeout(300);
  const label = await tabs.first().locator("span").boundingBox();
  const line = await page.locator(".indicator").boundingBox();
  assert(
    Math.abs(label.width - line.width) <= 1 && Math.abs(label.x - line.x) <= 1,
    "Underline must match label text",
  );
  assert.equal(await page.getByRole("tabpanel").count(), 1);
  await page.getByRole("button", { name: "Show serial", exact: true }).click();
  await page.getByText("SYNTHETIC-SERIAL-1234", { exact: true }).waitFor();
  await tabs.nth(1).click();
  await tabs.first().click();
  assert.equal(
    await page.getByText("SYNTHETIC-SERIAL-1234", { exact: true }).count(),
    0,
  );
  const tip = page.locator("td").getByRole("button");
  await tip.focus();
  assert.equal(await page.getByRole("tooltip").count(), 1);
  await page.keyboard.press("Escape");
  assert.equal(await page.getByRole("tooltip").count(), 0);
  await tip.evaluate((element) => element.blur());
  await tip.tap();
  assert.equal(await page.getByRole("tooltip").count(), 1);
  const rect = await page.getByRole("tooltip").boundingBox();
  assert(rect.x >= 0 && rect.x + rect.width <= 375, "Tooltip outside viewport");
  await page.goto(`${base}/settings`);
  await page.locator("h1").waitFor();
  // Start from another palette so selecting the default is an actual model change.
  await page.getByRole("combobox", { name: "Accent", exact: true }).click();
  await page.getByRole("option", { name: "Teal", exact: true }).click();
  for (const mode of ["light", "dark"]) {
    await page
      .getByRole("radio", {
        name: mode === "light" ? "Light" : "Dark",
        exact: true,
      })
      .click();
    for (const [name, value] of [
      ["Slate Blue", "slate-blue"],
      ["Sage", "sage"],
      ["Teal", "teal"],
      ["Plum", "plum"],
      ["Ocean", "ocean"],
      ["Olive", "olive"],
      ["Terracotta", "terracotta"],
      ["Indigo", "indigo"],
    ]) {
      await page.getByRole("combobox", { name: "Accent", exact: true }).click();
      await page.getByRole("option", { name, exact: true }).click();
      assert.equal(
        await page.evaluate(() => localStorage.getItem("hdd-theme")),
        value,
      );
      assert.equal(
        await page.evaluate(() => localStorage.getItem("hdd-mode")),
        mode,
      );
    }
  }
  await page.reload();
  assert.equal(
    await page.evaluate(() => document.documentElement.dataset.theme),
    "indigo",
  );
  assert(
    await page.evaluate(() =>
      document.documentElement.classList.contains("dark"),
    ),
  );
  await page
    .locator(".section-nav")
    .getByRole("link", { name: "Security", exact: true })
    .click();
  assert.equal(new URL(page.url()).pathname, "/settings");
  await page.waitForTimeout(1100);
  assert.equal(
    await page.locator(".section-nav a[aria-current]").textContent(),
    "Security",
  );
  // SSD's five checks use radios, while HDD's eight retain their listbox.
  disks[0].rotation = "0";
  await page.goto(`${base}/disks/sda`);
  await page.getByRole("tab").last().click();
  assert.equal(
    await page
      .getByRole("radiogroup", { name: "Check type", exact: true })
      .getByRole("radio")
      .count(),
    5,
  );
  await page.goto(`${base}/disks`);
  await page
    .getByRole("radio", { name: "All solid-state drives", exact: true })
    .click();
  assert.equal(
    await page
      .getByRole("radiogroup", { name: "Check type", exact: true })
      .getByRole("radio")
      .count(),
    5,
  );
  await page.emulateMedia({ reducedMotion: "no-preference" });
  await page.setViewportSize({ width: 900, height: 900 });
  await page.waitForTimeout(60);
  await page.emulateMedia({ reducedMotion: "reduce" });
  for (const width of [320, 900, 375, 1280])
    await page.setViewportSize({ width, height: 900 });
  await page.waitForTimeout(300);
  assert.equal(await page.evaluate(() => document.body.style.transform), "");
  assert.equal(
    await page.evaluate(() =>
      document.documentElement.classList.contains("layout-resizing"),
    ),
    false,
  );

  for (const code of [
    "zh-CN",
    "en",
    "es",
    "zh-TW",
    "zh-HK",
    "hi",
    "ar",
    "fr",
  ]) {
    await page.addInitScript(
      (code) => localStorage.setItem("hdd-lang", code),
      code,
    );
    await page.setViewportSize({ width: 375, height: 900 });
    await page.goto(`${base}/disks/sda`);
    await page.getByRole("tab").first().waitFor();
    assert.equal(
      await page.evaluate(() => document.documentElement.dir),
      code === "ar" ? "rtl" : "ltr",
    );
    assert(
      await page.evaluate(
        () => document.documentElement.scrollWidth <= innerWidth,
      ),
      code,
    );
    await page.getByRole("tab").last().click();
    await page.getByRole("tab").first().click();
    const textRect = await page
      .getByRole("tab")
      .first()
      .locator("span")
      .boundingBox();
    const indicatorRect = await page.locator(".indicator").boundingBox();
    assert(
      Math.abs(textRect.width - indicatorRect.width) <= 1 &&
        Math.abs(textRect.x - indicatorRect.x) <= 1,
      `${code}: underline geometry`,
    );
  }
  for (const language of [
    "zh-CN",
    "en",
    "es",
    "zh-TW",
    "zh-HK",
    "hi",
    "ar",
    "fr",
  ]) {
    await page.addInitScript(
      (language) => localStorage.setItem("hdd-lang", language),
      language,
    );
    await page.goto(`${base}/changelog`);
    await page.locator(".markdown-body").first().waitFor();
    assert(
      (await page.locator(".markdown-body").allTextContents())
        .join("")
        .includes("v4.1.0"),
      `${language}: changelog fallback`,
    );
  }
  assert.deepEqual(errors, []);
  console.log(
    `web-ui: ${scenarios} page/mode/viewport scenarios; keyboard, privacy, palettes and reduced motion passed`,
  );
} finally {
  await browser?.close();
  lines.close();
  preview.kill("SIGTERM");
}
