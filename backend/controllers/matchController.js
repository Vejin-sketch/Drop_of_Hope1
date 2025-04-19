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

exports.getMatchesForDonor = async (req, res) => {
  const donorId = req.query.donorId;

  if (!donorId) {
    return res.status(400).json({ message: "Missing donorId in query params" });
  }

  try {
    const donor = await db.getAsync("SELECT * FROM users WHERE id = ?", [donorId]);

    if (!donor) {
      return res.status(404).json({ message: "Donor not found" });
    }

    if (!donor.blood_group || donor.latitude == null || donor.longitude == null) {
      return res.status(400).json({ message: "Incomplete donor profile" });
    }

    const donorBloodGroup = donor.blood_group;
    const donorLat = donor.latitude;
    const donorLon = donor.longitude;

    const compatibleGroups = compatibility[donorBloodGroup] || [];
    compatibleGroups.push(donorBloodGroup); // include exact match

    const requests = await db.allAsync("SELECT * FROM blood_requests WHERE fulfilled = 0");

    function calculateDistance(lat1, lon1, lat2, lon2) {
      const R = 6371;
      const dLat = (lat2 - lat1) * Math.PI / 180;
      const dLon = (lon2 - lon1) * Math.PI / 180;
      const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      return R * c;
    }

    const matches = requests
      .filter(req =>
        req.latitude != null && req.longitude != null
      )
      .map(req => {
        const distance = calculateDistance(donorLat, donorLon, req.latitude, req.longitude);
        return { ...req, distance };
      })
      .filter(req => req.distance <= 35)
      .sort((a, b) => {
        if ((a.is_critical ?? 0) === 1 && (b.is_critical ?? 0) !== 1) return -1;
        if ((a.is_critical ?? 0) !== 1 && (b.is_critical ?? 0) === 1) return 1;
        return a.distance - b.distance;
      });

    res.json({
      donor: {
        id: donor.id,
        name: donor.name,
        blood_group: donor.blood_group
      },
      matches
    });

  } catch (err) {
    console.error("Error matching requests for donor:", err);
    res.status(500).json({ message: "Failed to find matching requests" });
  }
};