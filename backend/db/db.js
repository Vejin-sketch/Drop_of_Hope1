const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Define database file path
const dbPath = path.join(__dirname, 'database.db');

// Connect to SQLite database
const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('Error connecting to SQLite database:', err.message);
    } else {
        console.log('✅ Connected to SQLite database');
    }
});

// Create Users Table (if not exists)
db.run(`
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
    )
`, (err) => {
    if (err) {
        console.error('Error creating users table:', err.message);
    } else {
        console.log('✅ Users table ready');
    }
});

module.exports = db;