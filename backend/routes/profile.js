const express = require("express");
const router = express.Router();
const db = require("../db/db");

// ✅ GET PROFILE
router.get("/", async (req, res) => {
  const userId = req.query.userId;

  if (!userId) {
    return res.status(400).json({ success: false, message: "User ID is required" });
  }

  try {
    const profile = await db.getAsync(
      `SELECT last_donation_date, blood_group, gender, age, weight, location,
              has_tattoo, is_hiv_positive
       FROM users WHERE id = ?`,
      [userId]
    );

    if (!profile) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    res.json({ success: true, profile });
  } catch (err) {
    console.error("Get Profile Error:", err);
    res.status(500).json({ success: false, message: "Failed to fetch profile" });
  }
});

// ✅ PUT PROFILE
router.put("/", async (req, res) => {
  const userId = req.body.userId;
  if (!userId) {
    return res.status(400).json({ success: false, message: "User ID is required" });
  }

  const allowedFields = {
    lastDonationDate: "last_donation_date",
    bloodGroup: "blood_group",
    gender: "gender",
    age: "age",
    weight: "weight",
    location: "location",
    hasTattoo: "has_tattoo",
    isHivPositive: "is_hiv_positive",
    latitude: "latitude",
    longitude: "longitude"
  };

  const updates = [];
  const values = [];

  for (const [key, column] of Object.entries(allowedFields)) {
    if (req.body[key] !== undefined) {
      updates.push(`${column} = ?`);
      values.push(req.body[key]);
    }
  }

  if (updates.length === 0) {
    return res.status(400).json({ success: false, message: "No fields to update" });
  }

  const sql = "UPDATE users SET " + updates.join(", ") + " WHERE id = ?";
  values.push(userId);

  try {
    const result = await db.runAsync(sql, values);
    res.json({
      success: true,
      message: "Profile updated successfully",
      changes: result.changes
    });
  } catch (err) {
    console.error("Update Profile Error:", err);
    res.status(500).json({ success: false, message: "Failed to update profile" });
  }
});

module.exports = router;
