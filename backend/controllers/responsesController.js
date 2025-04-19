const db = require("../db/db");

exports.createResponse = async (req, res) => {
  const { donor_id, request_id } = req.body;

  if (!donor_id || !request_id) {
    return res.status(400).json({ message: "Missing donor_id or request_id" });
  }

  try {
    // Check if donor already responded to this request
    const existing = await db.getAsync(
      "SELECT * FROM responses WHERE donor_id = ? AND request_id = ? AND status = 'pending'",
      [donor_id, request_id]
    );

    if (existing) {
      return res.status(409).json({ message: "You have already responded to this request." });
    }

    // Fetch request to determine critical status
    const request = await db.getAsync("SELECT * FROM blood_requests WHERE id = ?", [request_id]);

    if (!request) {
      return res.status(404).json({ message: "Blood request not found." });
    }

    // Calculate expiration time (e.g., 2 hours from now) if critical
    let expiresAt = null;
    if (request.is_critical === 1) {
      const now = new Date();
      now.setHours(now.getHours() + 2);
      expiresAt = now.toISOString();
    }

    // Insert new response and return the ID
    const result = await db.runAsync(
      "INSERT INTO responses (donor_id, request_id, status, expires_at) VALUES (?, ?, 'pending', ?)",
      [donor_id, request_id, expiresAt]
    );

    const newId = result.lastID;

    res.status(201).json({ message: "Response recorded successfully.", response_id: newId });
  } catch (err) {
    console.error("Error creating response:", err);
    res.status(500).json({ message: "Failed to create response." });
  }
};

exports.fulfillResponse = async (req, res) => {
  const responseId = req.params.id;

  try {
    const existing = await db.getAsync("SELECT * FROM responses WHERE id = ?", [responseId]);
    if (!existing) return res.status(404).json({ message: "Response not found." });

    await db.runAsync(
      "UPDATE responses SET status = 'fulfilled', fulfilled_at = CURRENT_TIMESTAMP WHERE id = ?",
      [responseId]
    );

    res.json({ message: "Response marked as fulfilled." });
  } catch (err) {
    console.error("Error fulfilling response:", err);
    res.status(500).json({ message: "Error fulfilling response." });
  }
};

exports.cancelResponse = async (req, res) => {
  const responseId = req.params.id;
  const { cancel_reason } = req.body;

  if (!cancel_reason || cancel_reason.trim() === "") {
    return res.status(400).json({ message: "Cancel reason is required." });
  }

  try {
    const existing = await db.getAsync("SELECT * FROM responses WHERE id = ?", [responseId]);
    if (!existing) return res.status(404).json({ message: "Response not found." });

    await db.runAsync(
      "UPDATE responses SET status = 'cancelled', cancel_reason = ?, fulfilled_at = null WHERE id = ?",
      [cancel_reason, responseId]
    );

    res.json({ message: "Response cancelled successfully." });
  } catch (err) {
    console.error("Error cancelling response:", err);
    res.status(500).json({ message: "Error cancelling response." });
  }
};

exports.getResponseByDonor = async (req, res) => {
  const { donorId, requestId } = req.query;

  if (!donorId || !requestId) {
    return res.status(400).json({ message: "Missing donorId or requestId" });
  }

  try {
    const response = await db.getAsync(
      "SELECT id, status FROM responses WHERE donor_id = ? AND request_id = ? ORDER BY responded_at DESC LIMIT 1",
      [donorId, requestId]
    );

    if (!response) {
      return res.status(404).json({ message: "Response not found" });
    }

    res.json({
      responseId: response.id,
      status: response.status
    });
  } catch (err) {
    console.error("Error fetching response by donor:", err);
    res.status(500).json({ message: "Error fetching response" });
  }
};