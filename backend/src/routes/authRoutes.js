const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/auth');

router.post('/register', authController.register);
router.post('/verify-email', authController.verifyEmail);
router.post('/create-org', authController.createOrganization);
router.post('/login', authController.login);

router.post('/forgot-password', authController.requestPasswordReset);
router.post('/reset-password', authController.resetPassword);

router.post('/forgot-org-id', authController.requestOrgIdRecovery);
router.post('/recover-org-id', authController.verifyOrgIdRecovery);

router.get('/me', authMiddleware.verifyToken, authController.getMe);

module.exports = router;
