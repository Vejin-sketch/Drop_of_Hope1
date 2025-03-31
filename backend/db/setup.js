const db = require("./db");

db.serialize(() => {
  // USERS
  db.run(`CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    last_donation_date TEXT,
    blood_group TEXT,
    gender TEXT,
    age INTEGER,
    weight REAL,
    location TEXT,
    has_tattoo INTEGER DEFAULT 0,
    is_hiv_positive INTEGER DEFAULT 0
  )`, (err) => {
    if (err) console.error("❌ Users table error:", err.message);
    else console.log("✅ Users table ready");
  });

  // BLOOD DONATIONS
  db.run(`CREATE TABLE IF NOT EXISTS blood_donations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    donor_name TEXT NOT NULL,
    blood_group TEXT NOT NULL,
    donation_date TEXT NOT NULL,
    contact_number TEXT NOT NULL,
    location TEXT NOT NULL,
    last_donation_date TEXT,
    additional_notes TEXT,
    is_available INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id)
  )`, (err) => {
    if (err) console.error("❌ Donations table error:", err.message);
    else console.log("✅ Blood donations table ready");
  });

  db.run("CREATE INDEX IF NOT EXISTS idx_donations_blood_group ON blood_donations(blood_group)");

  // BLOOD REQUESTS
  db.run(`CREATE TABLE IF NOT EXISTS blood_requests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    patient_name TEXT NOT NULL,
    blood_group TEXT NOT NULL,
    units_required INTEGER DEFAULT 1,
    contact_number TEXT NOT NULL,
    location TEXT NOT NULL,
    required_date TEXT NOT NULL,
    hospital_name TEXT,
    hospital_address TEXT,
    is_critical INTEGER DEFAULT 0,
    additional_notes TEXT,
    fulfilled INTEGER DEFAULT 0,
    fulfilled_by INTEGER,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id),
    FOREIGN KEY(fulfilled_by) REFERENCES blood_donations(id)
  )`, (err) => {
    if (err) console.error("❌ Requests table error:", err.message);
    else console.log("✅ Blood requests table ready");
  });

  db.run("CREATE INDEX IF NOT EXISTS idx_requests_blood_group ON blood_requests(blood_group)");
});
