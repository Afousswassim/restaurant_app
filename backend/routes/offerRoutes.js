const express = require('express');
const offerController = require('../controllers/offerController');
const { requireAuth, requireAdmin } = require('../middleware/authMiddleware');

const adminRouter = express.Router();
const publicRouter = express.Router();

adminRouter.use(requireAuth, requireAdmin);

adminRouter.get('/', offerController.getAdminOffers);
adminRouter.post('/', offerController.createOffer);
adminRouter.put('/:productId', offerController.updateOffer);
adminRouter.delete('/:productId', offerController.deleteOffer);
adminRouter.patch('/:productId/toggle', offerController.toggleOfferStatus);

publicRouter.get('/', offerController.getActiveOffers);

module.exports = { adminRouter, publicRouter };
