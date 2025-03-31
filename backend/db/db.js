const sqlite3 = require("sqlite3").verbose();
const path = require("path");

// Define DB path
const dbPath = path.join(__dirname, "database.db");

// Connect to DB
const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READWRITE | sqlite3.OPEN_CREATE, (err) => {
  if (err) {
    console.error("❌ Error connecting to SQLite database:", err.message);
  } else {
    console.log("✅ Connected to SQLite database");
    db.run("PRAGMA foreign_keys = ON", (fkErr) => {
      if (fkErr) {
        console.error("❌ Foreign key enable error:", fkErr.message);
      } else {
        console.log("✅ Foreign key constraints enabled");
      }
    });
  }
});

// Async wrapper methods
db.allAsync = function (sql, params = []) {
  return new Promise((resolve, reject) => {
    this.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
};

db.getAsync = function (sql, params = []) {
  return new Promise((resolve, reject) => {
    this.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
};

db.runAsync = function (sql, params = []) {
  return new Promise((resolve, reject) => {
    this.run(sql, params, function (err) {
      if (err) reject(err);
      else resolve(this);
    });
  });
};

module.exports = db;
