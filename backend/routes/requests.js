const express = require("express");
const router = express.Router();
const requestController = require("../controllers/requestController");
const requireAuth = require("../middleware/auth");

router.use(requireAuth);

router.post("/", requestController.createRequest);
router.get("/", requestController.getAllRequests);
router.get("/:id", requestController.getRequestById);
router.put("/:id/fulfill", requestController.fulfillRequest);

module.exports = router;
