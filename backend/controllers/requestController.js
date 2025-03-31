const db = require("../db/db");
const compatibility = require("../utils/bloodCompatibility");

exports.createRequest = async (req, res) => {
  const {
    userId, patientName, bloodGroup, unitsRequired,
    contactNumber, location, requiredDate,
    hospitalName, hospitalAddress, isCritical, additionalNotes
  } = req.body;

  if (!userId || !patientName || !bloodGroup || !contactNumber || !location || !requiredDate) {
    return res.status(400).json({ message: "Missing required fields" });
  }

  try {
    const { lastID } = await db.runAsync(
      `INSERT INTO blood_requests (
        user_id, patient_name, blood_group, units_required,
        contact_number, location, required_date,
        hospital_name, hospital_address, is_critical, additional_notes
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        userId, patientName, bloodGroup, unitsRequired || 1,
        contactNumber, location, requiredDate,
        hospitalName || null, hospitalAddress || null,
        isCritical ? 1 : 0, additionalNotes || null
      ]
    );

    res.status(201).json({ message: "Request created", requestId: lastID });
  } catch (err) {
    console.error("Create Request Error:", err);
    res.status(500).json({ message: "Failed to create request" });
  }
};

exports.getAllRequests = async (req, res) => {
  const { bloodGroup, isCritical, fulfilled } = req.query;

  let sql = `
    SELECT r.*, u.name as user_name
    FROM blood_requests r
    JOIN users u ON r.user_id = u.id
  `;

  const whereClauses = [];
  const params = [];

  if (fulfilled === '1') {
    whereClauses.push(`r.fulfilled = 1`);
  } else if (fulfilled === '0' || fulfilled === undefined) {
    whereClauses.push(`r.fulfilled = 0`);
  }

  if (bloodGroup) {
    whereClauses.push("r.blood_group = ?");
    params.push(bloodGroup);
  }

  if (isCritical === 'true') {
    whereClauses.push("r.is_critical = 1");
  }

  if (whereClauses.length > 0) {
    sql += " WHERE " + whereClauses.join(" AND ");
  }

  sql += " ORDER BY r.is_critical DESC, r.created_at DESC";

  try {
    const requests = await db.allAsync(sql, params);
    res.json({ requests });
  } catch (err) {
    console.error("Get Requests Error:", err);
    res.status(500).json({ message: "Failed to fetch requests" });
  }
};

exports.getRequestById = async (req, res) => {
  try {
    const request = await db.getAsync(
      `SELECT r.*, u.name as user_name
       FROM blood_requests r
       JOIN users u ON r.user_id = u.id
       WHERE r.id = ?`,
      [req.params.id]
    );

    if (!request) {
      return res.status(404).json({ message: "Request not found" });
    }

    res.json({ request });
  } catch (err) {
    console.error("Get Request Error:", err);
    res.status(500).json({ message: "Failed to fetch request" });
  }
};

exports.fulfillRequest = async (req, res) => {
  const { donationId } = req.body;
  const requestId = req.params.id;

  try {
    await db.runAsync("BEGIN TRANSACTION");

    const donation = await db.getAsync(
      "SELECT * FROM blood_donations WHERE id = ? AND is_available = 1",
      [donationId]
    );
    if (!donation) {
      await db.runAsync("ROLLBACK");
      return res.status(400).json({ message: "Donation not available" });
    }

    const request = await db.getAsync(
      "SELECT * FROM blood_requests WHERE id = ? AND fulfilled = 0",
      [requestId]
    );
    if (!request) {
      await db.runAsync("ROLLBACK");
      return res.status(400).json({ message: "Request not found or already fulfilled" });
    }

    const compatible = compatibility[request.blood_group] || [];
    if (!compatible.includes(donation.blood_group)) {
      await db.runAsync("ROLLBACK");
      return res.status(400).json({
        message: "Incompatible blood types",
        details: `${request.blood_group} cannot receive ${donation.blood_group}`
      });
    }

    await db.runAsync(
      "UPDATE blood_requests SET fulfilled = 1, fulfilled_by = ? WHERE id = ?",
      [donationId, requestId]
    );
    await db.runAsync(
      "UPDATE blood_donations SET is_available = 0 WHERE id = ?",
      [donationId]
    );

    await db.runAsync("COMMIT");

    res.json({ message: "Request fulfilled successfully" });

  } catch (err) {
    await db.runAsync("ROLLBACK");
    console.error("Fulfill Error:", err);
    res.status(500).json({ message: "Failed to fulfill request" });
  }
};