const express = require('express');
const adminController = require('../controllers/adminController');

const router = express.Router();

// Route: POST /admin/login
router.post('/login', adminController.login);

// Route: GET /admin/customers
router.get('/customers', adminController.getCustomers);

// Route: GET /admin/customers/:id
router.get('/customers/:id', adminController.getCustomerById);

// Route: POST /admin/customers
router.post('/customers', adminController.createCustomer);

// Route: PUT /admin/customers/:id
router.put('/customers/:id', adminController.updateCustomer);

// Route: DELETE /admin/customers/:id
router.delete('/customers/:id', adminController.deleteCustomer);

// Route: PATCH /admin/customers/:id/status
router.patch('/customers/:id/status', adminController.updateCustomerStatus);

// Route: PATCH /admin/customers/:id/vip
router.patch('/customers/:id/vip', adminController.updateCustomerVip);

// Route: PATCH /admin/customers/:id/rewards
router.patch('/customers/:id/rewards', adminController.updateCustomerRewards);

// ==========================================
// CATEGORIES ROUTES
// ==========================================

// Route: GET /admin/categories
router.get('/categories', adminController.getAdminCategories);
// Debug: raw categories
router.get('/debug/categories', adminController.debugCategories);

// Route: GET /admin/categories/:id
router.get('/categories/:id', adminController.getAdminCategoryById);

// Route: POST /admin/categories
router.post('/categories', adminController.createAdminCategory);

// Route: PUT /admin/categories/:id
router.put('/categories/:id', adminController.updateAdminCategory);

// Route: DELETE /admin/categories/:id
router.delete('/categories/:id', adminController.deleteAdminCategory);

// Route: PATCH /admin/categories/:id/status
router.patch('/categories/:id/status', adminController.updateAdminCategoryStatus);

module.exports = router;
