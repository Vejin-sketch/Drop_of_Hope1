const express = require("express");
const router = express.Router();
const matchController = require("../controllers/matchController");
const requireAuth = require("../middleware/auth");

router.use(requireAuth);

// Match donors for a specific request
router.get("/donors/:id", matchController.getMatchesForRequest);

// Match requests for a specific donor
router.get("/requests", matchController.getMatchesForDonor);

module.exports = router;