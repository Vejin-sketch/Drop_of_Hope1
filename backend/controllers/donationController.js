const db = require("../db/db");

exports.createDonation = async (req, res) => {
  const {
    userId, donorName, bloodGroup, donationDate,
    contactNumber, location, lastDonationDate, additionalNotes
  } = req.body;

  if (!userId || !donorName || !bloodGroup || !donationDate || !contactNumber || !location) {
    return res.status(400).json({ message: "Missing required fields" });
  }

  try {
    const { lastID } = await db.runAsync(
      `INSERT INTO blood_donations (
        user_id, donor_name, blood_group, donation_date,
        contact_number, location, last_donation_date, additional_notes
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        userId, donorName, bloodGroup, donationDate,
        contactNumber, location, lastDonationDate || null, additionalNotes || null
      ]
    );

    res.status(201).json({ message: "Donation added", donationId: lastID });
  } catch (err) {
    console.error("Create Donation Error:", err);
    res.status(500).json({ message: "Failed to create donation" });
  }
};

exports.getDonations = async (req, res) => {
  const { bloodGroup } = req.query;
  let sql = `
    SELECT d.*, u.name as user_name
    FROM blood_donations d
    JOIN users u ON d.user_id = u.id
    WHERE d.is_available = 1
  `;
  const params = [];

  if (bloodGroup) {
    sql += " AND d.blood_group = ?";
    params.push(bloodGroup);
  }

  sql += " ORDER BY d.created_at DESC";

  try {
    const donations = await db.allAsync(sql, params);
    res.json({ donations });
  } catch (err) {
    console.error("Get Donations Error:", err);
    res.status(500).json({ message: "Failed to fetch donations" });
  }
};

exports.getDonationById = async (req, res) => {
  try {
    const donation = await db.getAsync(
      `SELECT d.*, u.name as user_name
       FROM blood_donations d
       JOIN users u ON d.user_id = u.id
       WHERE d.id = ?`,
      [req.params.id]
    );

    if (!donation) {
      return res.status(404).json({ message: "Donation not found" });
    }

    res.json({ donation });
  } catch (err) {
    console.error("Get Donation Error:", err);
    res.status(500).json({ message: "Failed to fetch donation" });
  }
};

exports.updateDonation = async (req, res) => {
  const { donorName, bloodGroup, donationDate, contactNumber, location } = req.body;

  try {
    const { changes } = await db.runAsync(
      `UPDATE blood_donations SET
        donor_name = ?, blood_group = ?, donation_date = ?,
        contact_number = ?, location = ?
       WHERE id = ?`,
      [donorName, bloodGroup, donationDate, contactNumber, location, req.params.id]
    );

    res.json({ message: "Donation updated", changes });
  } catch (err) {
    console.error("Update Donation Error:", err);
    res.status(500).json({ message: "Failed to update donation" });
  }
};

exports.deleteDonation = async (req, res) => {
  try {
    const donation = await db.getAsync(
      "SELECT id FROM blood_donations WHERE id = ?",
      [req.params.id]
    );
    if (!donation) {
      return res.status(404).json({ message: "Donation not found" });
    }

    const request = await db.getAsync(
      "SELECT id FROM blood_requests WHERE fulfilled_by = ?",
      [req.params.id]
    );
    if (request) {
      return res.status(400).json({
        message: "Cannot delete. Donation is linked to a request",
        requestId: request.id
      });
    }

    const { changes } = await db.runAsync(
      "DELETE FROM blood_donations WHERE id = ?",
      [req.params.id]
    );

    res.json({ message: "Donation deleted", changes });
  } catch (err) {
    console.error("Delete Donation Error:", err);
    res.status(500).json({ message: "Failed to delete donation" });
  }
};

exports.updateAvailability = async (req, res) => {
  const { isAvailable } = req.body;
  const id = req.params.id;

  try {
    const donation = await db.getAsync("SELECT * FROM blood_donations WHERE id = ?", [id]);

    if (isAvailable && donation.last_donation_date) {
      const last = new Date(donation.last_donation_date);
      const threeMonthsAgo = new Date();
      threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

      if (last > threeMonthsAgo) {
        return res.status(400).json({
          message: "Cannot mark available — donation less than 3 months ago"
        });
      }
    }

    const { changes } = await db.runAsync(
      "UPDATE blood_donations SET is_available = ? WHERE id = ?",
      [isAvailable ? 1 : 0, id]
    );

    res.json({ message: "Availability updated", changes });
  } catch (err) {
    console.error("Update Availability Error:", err);
    res.status(500).json({ message: "Failed to update availability" });
  }
};

exports.getUserDonationHistory = async (req, res) => {
  const userId = req.params.userId;

  try {
    const history = await db.allAsync(
      `SELECT d.*, r.patient_name as used_for_patient
       FROM blood_donations d
       LEFT JOIN blood_requests r ON r.fulfilled_by = d.id
       WHERE d.user_id = ?
       ORDER BY d.donation_date DESC`,
      [userId]
    );

    res.json({ history });
  } catch (err) {
    console.error("Get History Error:", err);
    res.status(500).json({ message: "Failed to fetch donation history" });
  }
};