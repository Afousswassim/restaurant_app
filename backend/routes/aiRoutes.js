const express = require('express');
const aiController = require('../controllers/aiController');

const router = express.Router();

router.post('/food-assistant', aiController.generateFoodAssistantPlan);

module.exports = router;
