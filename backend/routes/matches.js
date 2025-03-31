const express = require("express");
const router = express.Router();
const matchController = require("../controllers/matchController");

router.get("/requests/:id", matchController.getMatchesForRequest);

module.exports = router;