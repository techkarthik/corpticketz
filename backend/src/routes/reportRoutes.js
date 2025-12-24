const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const { verifyToken, authorizeRoles } = require('../middleware/auth');

// Allow GlobalAdmin, Manager, and BranchManager to view reports
router.get('/summary', verifyToken, authorizeRoles('GlobalAdmin', 'Manager', 'BranchManager'), reportController.getReportSummary);

module.exports = router;
