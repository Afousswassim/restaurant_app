const { requireAuth, requireClient } = require('./authMiddleware');

module.exports = [requireAuth, requireClient];

