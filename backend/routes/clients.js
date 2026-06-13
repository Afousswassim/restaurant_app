const express = require('express');
const clientController = require('../controllers/clientController');
const clientAuth = require('../middleware/clientAuth');

const router = express.Router();

router.post('/register', clientController.register);
router.post('/login', clientController.login);
router.get('/profile', clientAuth, clientController.getProfile);
router.put('/profile', clientAuth, clientController.updateProfile);

module.exports = router;
