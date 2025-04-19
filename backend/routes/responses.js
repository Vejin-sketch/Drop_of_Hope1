const express = require("express");
const router = express.Router();
const responsesController = require("../controllers/responsesController");

// Donor offers to help
router.post("/", responsesController.createResponse);

// Donor marks their response as fulfilled
router.put("/:id/fulfill", responsesController.fulfillResponse);

// Donor cancels their response with a reason
router.put("/:id/cancel", responsesController.cancelResponse);

router.get("/by-donor", responsesController.getResponseByDonor);

module.exports = router;