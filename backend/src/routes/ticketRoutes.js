const express = require('express');
const router = express.Router();
const ticketController = require('../controllers/ticketController');
const { verifyToken } = require('../middleware/auth');

router.post('/', verifyToken, ticketController.createTicket);
router.get('/', verifyToken, ticketController.getTickets);
router.put('/:id', verifyToken, ticketController.updateTicket);
router.get('/:id/history', verifyToken, ticketController.getTicketHistory);

module.exports = router;
