const initSqlJs = require("sql.js");
const fs = require("fs");
const path = require("path");

const DB_PATH = path.join(__dirname, "agripulse.db");

async function initDatabase() {
  const SQL = await initSqlJs();

  let db;
  if (fs.existsSync(DB_PATH)) {
    const fileBuffer = fs.readFileSync(DB_PATH);
    db = new SQL.Database(fileBuffer);
    console.log(" Loaded existing database from disk.");
  } else {
    db = new SQL.Database();
    console.log(" Created new database.");
  }

  function save() {
    const data = db.export();
    fs.writeFileSync(DB_PATH, Buffer.from(data));
  }

  db.run(`
    CREATE TABLE IF NOT EXISTS prices (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      crop_name  TEXT NOT NULL,
      market     TEXT NOT NULL,
      price      REAL NOT NULL,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    )
  `);

  const [{ values }] = db.exec("SELECT COUNT(*) AS n FROM prices");
  const count = values[0][0];

  if (count === 0) {
    const seeds = [
      ["Beans", "Kimironko Market", 1.2],
      ["Beans", "Nyabugogo Market", 1.1],
      ["Maize", "Kimironko Market", 0.55],
      ["Maize", "Musanze Market", 0.5],
      ["Potatoes", "Kimironko Market", 0.4],
      ["Potatoes", "Huye Market", 0.38],
      ["Potatoes", "Rwamagana Market", 0.42],
      ["Tomatoes", "Kimironko Market", 0.9],
      ["Tomatoes", "Nyabugogo Market", 0.85],
      ["Rice", "Kimironko Market", 1.5],
      ["Rice", "Musanze Market", 1.45],
      ["Rice", "Huye Market", 1.55],
    ];

    const stmt = db.prepare(
      "INSERT INTO prices (crop_name, market, price) VALUES (?, ?, ?)",
    );
    seeds.forEach(([crop, market, price]) => stmt.run([crop, market, price]));
    stmt.free();
    save();
    console.log(`Database seeded with ${seeds.length} records.`);
  } else {
    console.log(`  Database already has ${count} record(s). Skipping seed.`);
  }

  function query(sql, params = []) {
    const results = db.exec(sql, params);
    if (!results.length) return [];
    const { columns, values } = results[0];
    return values.map((row) =>
      Object.fromEntries(columns.map((col, i) => [col, row[i]])),
    );
  }

  function run(sql, params = []) {
    db.run(sql, params);
    const lastId = db.exec("SELECT last_insert_rowid() AS id")[0].values[0][0];
    save();
    return lastId;
  }

  return { query, run };
}

module.exports = initDatabase;
