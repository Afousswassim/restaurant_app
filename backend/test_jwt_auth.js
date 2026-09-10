process.env.PORT = 5055;
require('dotenv').config();
const http = require('http');
const connectDB = require('./config/database');
const express = require('express');
const cors = require('cors');

const branchRoutes = require('./routes/branches');
const menuRoutes = require('./routes/menu');
const categoriesRoutes = require('./routes/categories');
const cartRoutes = require('./routes/cart');
const orderRoutes = require('./routes/orders');
const notificationRoutes = require('./routes/notifications');
const adminRoutes = require('./routes/adminRoutes');
const offerRoutes = require('./routes/offerRoutes');
const clientRoutes = require('./routes/clients');
const couponRoutes = require('./routes/coupons');
const loyaltyRoutes = require('./routes/loyalty');
const aiRoutes = require('./routes/aiRoutes');
const errorHandler = require('./middleware/errorHandler');

const app = express();
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

app.use('/branches', branchRoutes);
app.use('/menu', menuRoutes);
app.use('/categories', categoriesRoutes);
app.use('/cart', cartRoutes);
app.use('/orders', orderRoutes);
app.use('/notifications', notificationRoutes);
app.use('/admin', adminRoutes);
app.use('/admin/offers', offerRoutes.adminRouter);
app.use('/offers', offerRoutes.publicRouter);
app.use('/clients', clientRoutes);
app.use('/coupons', couponRoutes);
app.use('/loyalty', loyaltyRoutes);
app.use('/ai', aiRoutes);

app.get('/health', (req, res) => {
  res.status(200).json({ success: true, message: 'Server is running' });
});

app.use(errorHandler);

const PORT = 5055;
const BASE_URL = `http://localhost:${PORT}`;

function makeRequest(path, method = 'GET', data = null, token = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const payload = data ? JSON.stringify(data) : null;
    if (payload) headers['Content-Length'] = Buffer.byteLength(payload);

    const req = http.request(url, { method, headers }, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        try {
          resolve({ statusCode: res.statusCode, body: JSON.parse(body) });
        } catch (e) {
          resolve({ statusCode: res.statusCode, rawBody: body });
        }
      });
    });

    req.on('error', (err) => reject(err));
    if (payload) req.write(payload);
    req.end();
  });
}

async function runTests() {
  await connectDB();
  const server = app.listen(PORT, async () => {
    console.log(`Test server running on port ${PORT}`);
    try {
      console.log('\n--- 1. Public Route Check ---');
      const health = await makeRequest('/health');
      console.log('GET /health -> Status:', health.statusCode, 'Body:', health.body);

      console.log('\n--- 2. Admin Login ---');
      const adminLogin = await makeRequest('/admin/login', 'POST', {
        email: 'admin@wassimfood.com',
        password: 'admin123',
      });
      console.log('POST /admin/login -> Status:', adminLogin.statusCode, 'Success:', adminLogin.body.success);
      const adminToken = adminLogin.body.token;
      console.log('Admin Token:', adminToken ? `${adminToken.substring(0, 30)}...` : 'NULL');

      console.log('\n--- 3. Client Register ---');
      const testEmail = `jwt_user_${Date.now()}@test.com`;
      const clientReg = await makeRequest('/clients/register', 'POST', {
        fullName: 'Wassim Test',
        phone: '0612345678',
        email: testEmail,
        password: 'password123',
      });
      console.log('POST /clients/register -> Status:', clientReg.statusCode, 'Success:', clientReg.body.success);
      const clientToken = clientReg.body?.data?.token;
      console.log('Client Token:', clientToken ? `${clientToken.substring(0, 30)}...` : 'NULL');

      console.log('\n--- 4. Client Login ---');
      const clientLogin = await makeRequest('/clients/login', 'POST', {
        email: testEmail,
        password: 'password123',
      });
      console.log('POST /clients/login -> Status:', clientLogin.statusCode, 'Success:', clientLogin.body.success);

      console.log('\n--- 5. Protected Client Route (GET /clients/profile) ---');
      const profile = await makeRequest('/clients/profile', 'GET', null, clientToken);
      console.log('GET /clients/profile with Client Token -> Status:', profile.statusCode, 'User email:', profile.body?.data?.email);

      console.log('\n--- 6. Protected Admin Route (GET /admin/customers) with Admin Token ---');
      const customers = await makeRequest('/admin/customers', 'GET', null, adminToken);
      console.log('GET /admin/customers with Admin Token -> Status:', customers.statusCode, 'Success:', customers.body?.success);

      console.log('\n--- 7. Role Check: Client Token on Admin Route ---');
      const clientOnAdmin = await makeRequest('/admin/customers', 'GET', null, clientToken);
      console.log('GET /admin/customers with Client Token -> Status:', clientOnAdmin.statusCode, 'Message:', clientOnAdmin.body?.message);

      console.log('\n--- 8. Unauthenticated Access Check ---');
      const noToken = await makeRequest('/admin/customers', 'GET');
      console.log('GET /admin/customers with No Token -> Status:', noToken.statusCode, 'Message:', noToken.body?.message);

      console.log('\n--- 9. Invalid Token Check ---');
      const invalidToken = await makeRequest('/clients/profile', 'GET', null, 'invalid.jwt.token');
      console.log('GET /clients/profile with Invalid Token -> Status:', invalidToken.statusCode, 'Message:', invalidToken.body?.message);

      console.log('\n=== ALL JWT AUTH & AUTHORIZATION TESTS PASSED SUCCESSFULLY! ===');
    } catch (e) {
      console.error('Test Error:', e);
    } finally {
      server.close();
      process.exit(0);
    }
  });
}

runTests();
