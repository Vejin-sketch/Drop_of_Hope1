const express = require("express");
const router = express.Router();
const matchController = require("../controllers/matchController");

// Match donors for a specific request
router.get("/donors/:id", matchController.getMatchesForRequest);

// Match requests for a specific donor
router.get("/requests", matchController.getMatchesForDonor);

module.exports = router;