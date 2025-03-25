const express = require("express");
const sqlite3 = require("sqlite3").verbose();
const cors = require("cors");

const app = express();
const port = 3000;

const db = new sqlite3.Database("./db/database.db", (err) => {
  if (err) {
    console.error("❌ Database Connection Error:", err.message);
  } else {
    console.log("✅ Connected to SQLite database");
  }
});

// Create users table with additional profile fields
db.run(
  `CREATE TABLE IF NOT EXISTS users (
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
  )`,
  (err) => {
    if (err) {
      console.error("❌ Table Creation Error:", err.message);
    } else {
      console.log("✅ Users table ready");
    }
  }
);

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.send("Blood Donation App API is Running...");
});

// Register a new user
app.post("/register", (req, res) => {
  const { name, email, password } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({ error: "All fields are required" });
  }

  const checkEmailSQL = "SELECT * FROM users WHERE email = ?";
  db.get(checkEmailSQL, [email], (err, existingUser) => {
    if (err) return res.status(500).json({ error: err.message });
    if (existingUser) return res.status(400).json({ error: "Email already registered" });

    const insertSQL = "INSERT INTO users (name, email, password) VALUES (?, ?, ?)";
    db.run(insertSQL, [name, email, password], function (err) {
      if (err) return res.status(500).json({ error: err.message });

      res.status(200).json({
        success: true,
        message: "User Registered Successfully",
        user: { id: this.lastID, name, email },
      });
    });
  });
});

// Login a user
app.post("/login", (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: "All fields are required" });
  }

  const sql = "SELECT * FROM users WHERE email = ?";
  db.get(sql, [email], (err, user) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!user) return res.status(400).json({ error: "User not found" });
    if (password !== user.password) return res.status(400).json({ error: "Invalid password" });

    res.status(200).json({
      success: true,
      message: "Login Successful",
      user: { id: user.id, name: user.name, email: user.email },
    });
  });
});

// Fetch recent blood requests
app.get("/recent-requests", (req, res) => {
  const sql = `
    SELECT
      id,
      patient_name,
      hospital_name,
      blood_group,
      urgency_level,
      location,
      created_at
    FROM blood_requests
    ORDER BY created_at DESC
    LIMIT 5
  `;

  db.all(sql, [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.status(200).json({ success: true, requests: rows });
  });
});

// Fetch blood stock
app.get("/blood-stock", (req, res) => {
  const sql = `
    SELECT
      blood_group,
      stock_level,
      last_updated
    FROM blood_stock
    ORDER BY last_updated DESC
  `;

  db.all(sql, [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.status(200).json({ success: true, stock: rows });
  });
});

// Fetch user profile
app.get("/profile", (req, res) => {
  const userId = req.query.userId; // Get userId from query parameter

  if (!userId) {
    return res.status(400).json({ error: "User ID is required" });
  }

  const sql = `
    SELECT
      last_donation_date,
      blood_group,
      gender,
      age,
      weight,
      location,
      has_tattoo,
      is_hiv_positive
    FROM users
    WHERE id = ?
  `;

  db.get(sql, [userId], (err, row) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!row) return res.status(404).json({ error: "User not found" });

    res.status(200).json({ success: true, profile: row });
  });
});

// Update user profile
app.put("/profile", (req, res) => {
  const userId = req.body.userId; // Get userId from request body
  const {
    lastDonationDate,
    bloodGroup,
    gender,
    age,
    weight,
    location,
    hasTattoo,
    isHivPositive,
  } = req.body;

  if (!userId) {
    return res.status(400).json({ error: "User ID is required" });
  }

  // Prepare the SQL query dynamically based on provided fields
  let sql = "UPDATE users SET ";
  const params = [];
  const updates = [];

  if (lastDonationDate !== undefined) {
    updates.push("last_donation_date = ?");
    params.push(lastDonationDate);
  }
  if (bloodGroup !== undefined) {
    updates.push("blood_group = ?");
    params.push(bloodGroup);
  }
  if (gender !== undefined) {
    updates.push("gender = ?");
    params.push(gender);
  }
  if (age !== undefined) {
    updates.push("age = ?");
    params.push(age);
  }
  if (weight !== undefined) {
    updates.push("weight = ?");
    params.push(weight);
  }
  if (location !== undefined) {
    updates.push("location = ?");
    params.push(location);
  }
  if (hasTattoo !== undefined) {
    updates.push("has_tattoo = ?");
    params.push(hasTattoo ? 1 : 0);
  }
  if (isHivPositive !== undefined) {
    updates.push("is_hiv_positive = ?");
    params.push(isHivPositive ? 1 : 0);
  }

  if (updates.length === 0) {
    return res.status(400).json({ error: "No fields to update" });
  }

  sql += updates.join(", ") + " WHERE id = ?";
  params.push(userId);

  db.run(sql, params, function (err) {
    if (err) return res.status(500).json({ error: err.message });

    res.status(200).json({ success: true, message: "Profile updated successfully" });
  });
});

// Start the server
app.listen(port, () => {
  console.log(`🚀 Server running on http://localhost:${port}`);
});