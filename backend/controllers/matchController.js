const db = require("../db/db");
const compatibility = require("../utils/bloodCompatibility");

exports.getMatchesForRequest = async (req, res) => {
  const requestId = req.params.id;

  try {
    const request = await db.getAsync("SELECT * FROM blood_requests WHERE id = ?", [requestId]);

    if (!request) {
      return res.status(404).json({ message: "Request not found" });
    }

    const compatibleGroups = compatibility[request.blood_group] || [];

    const placeholders = compatibleGroups.map(() => "?").join(",");
    const params = [request.blood_group, ...compatibleGroups, request.location, request.location];

    const sql = `
      SELECT d.*, u.name as donor_name,
        CASE WHEN d.blood_group = ? THEN 1 ELSE 0 END AS match_priority
      FROM blood_donations d
      JOIN users u ON d.user_id = u.id
      WHERE d.blood_group IN (${placeholders})
        AND (d.location LIKE '%' || ? || '%' OR ? LIKE '%' || d.location || '%')
        AND d.is_available = 1
      ORDER BY match_priority DESC, d.created_at DESC
    `;

    const matches = await db.allAsync(sql, params);

    res.json({
      request: {
        id: request.id,
        patient_name: request.patient_name,
        blood_group: request.blood_group,
        location: request.location
      },
      matches
    });

  } catch (err) {
    console.error("Match Error:", err);
    res.status(500).json({ message: "Failed to find matches" });
  }
};
