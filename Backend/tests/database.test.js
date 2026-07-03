const test    = require("node:test");
const assert  = require("node:assert/strict");
const fs      = require("fs");
const os      = require("os");
const path    = require("path");
const initDatabase = require("../database");

function tempDbPath() {
  return path.join(fs.mkdtempSync(path.join(os.tmpdir(), "agripulse-test-")), "test.db");
}

test("seeds the database with initial crop prices on first run", async () => {
  const dbPath = tempDbPath();
  const { query } = await initDatabase(dbPath);
  const rows = query("SELECT * FROM prices");
  assert.ok(rows.length > 0);
  fs.rmSync(path.dirname(dbPath), { recursive: true, force: true });
});

test("run() inserts a row and persists it, query() retrieves it", async () => {
  const dbPath = tempDbPath();
  const { query, run } = await initDatabase(dbPath);

  const id = run(
    "INSERT INTO prices (crop_name, market, price, created_at) VALUES (?, ?, ?, ?)",
    ["Cassava", "Test Market", 0.75, "2026-01-01 00:00:00"]
  );

  const [row] = query("SELECT * FROM prices WHERE id = ?", [id]);
  assert.equal(row.crop_name, "Cassava");
  assert.equal(row.market, "Test Market");
  assert.equal(row.price, 0.75);
  fs.rmSync(path.dirname(dbPath), { recursive: true, force: true });
});

test("does not re-seed when the database already has data", async () => {
  const dbPath = tempDbPath();
  const first = await initDatabase(dbPath);
  const countAfterSeed = first.query("SELECT COUNT(*) AS n FROM prices")[0].n;

  const second = await initDatabase(dbPath);
  const countAfterReload = second.query("SELECT COUNT(*) AS n FROM prices")[0].n;

  assert.equal(countAfterSeed, countAfterReload);
  fs.rmSync(path.dirname(dbPath), { recursive: true, force: true });
});

test("search filters rows case-insensitively", async () => {
  const dbPath = tempDbPath();
  const { query } = await initDatabase(dbPath);
  const rows = query(
    "SELECT * FROM prices WHERE LOWER(crop_name) LIKE LOWER(?)",
    ["%maize%"]
  );
  assert.ok(rows.every((r) => r.crop_name.toLowerCase().includes("maize")));
  assert.ok(rows.length > 0);
  fs.rmSync(path.dirname(dbPath), { recursive: true, force: true });
});
