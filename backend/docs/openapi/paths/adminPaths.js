/**
 * @openapi
 * /admin/login:
 *   post:
 *     tags:
 *       - Admin
 *       - Authentication
 *     summary: Admin portal login
 *     description: Authenticates admin credentials (`admin@wassimfood.com` / `admin123`) and returns an Admin JWT token.
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 example: admin@wassimfood.com
 *               password:
 *                 type: string
 *                 format: password
 *                 example: admin123
 *     responses:
 *       200:
 *         description: Admin login successful
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 token:
 *                   type: string
 *                   example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
 *                 admin:
 *                   type: object
 *                   properties:
 *                     email:
 *                       type: string
 *                       example: admin@wassimfood.com
 *                     name:
 *                       type: string
 *                       example: Admin Wassim Food
 *                     role:
 *                       type: string
 *                       example: admin
 *       400:
 *         description: Email and password are required
 *       401:
 *         description: Invalid email or password
 *       500:
 *         description: Server error
 *
 * /admin/customers:
 *   get:
 *     tags:
 *       - Admin
 *       - Clients
 *     summary: List all customers with spending & order analytics (Admin)
 *     description: Requires Admin role. Returns all client accounts augmented with lifetime order count, total spending, favorite product, favorite category, and last order date.
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Customer list with analytics
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: string
 *                       fullName:
 *                         type: string
 *                       email:
 *                         type: string
 *                       phone:
 *                         type: string
 *                       status:
 *                         type: string
 *                       loyaltyPoints:
 *                         type: number
 *                       totalOrders:
 *                         type: number
 *                       totalSpent:
 *                         type: number
 *                       favoriteProduct:
 *                         type: string
 *                       favoriteCategory:
 *                         type: string
 *                       lastOrder:
 *                         type: string
 *                         format: date-time
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - requires Admin role
 *       500:
 *         description: Server error
 *
 *   post:
 *     tags:
 *       - Admin
 *       - Clients
 *     summary: Create customer profile manually (Admin)
 *     description: Requires Admin role. Creates a client account from the administrative dashboard.
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - phone
 *               - email
 *             properties:
 *               fullName:
 *                 type: string
 *                 example: New Customer
 *               phone:
 *                 type: string
 *                 example: "+212 611223344"
 *               email:
 *                 type: string
 *                 example: newcust@wassimfood.com
 *               password:
 *                 type: string
 *                 example: customer123
 *               address:
 *                 type: string
 *               city:
 *                 type: string
 *               status:
 *                 type: string
 *                 enum: [Active, Inactive, VIP, Blocked]
 *                 example: Active
 *               loyaltyPoints:
 *                 type: number
 *                 example: 100
 *     responses:
 *       201:
 *         description: Customer created
 *       400:
 *         description: Name, Phone, Email required or email already registered
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 *
 * /admin/customers/{id}:
 *   get:
 *     tags:
 *       - Admin
 *       - Clients
 *     summary: Get customer detail & statistics (Admin)
 *     description: Requires Admin role. Returns customer profile, order statistics, order history, loyalty level, and top favorite products.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000006
 *     responses:
 *       200:
 *         description: Customer detailed analytics
 *       404:
 *         description: Customer not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 *
 *   put:
 *     tags:
 *       - Admin
 *       - Clients
 *     summary: Update customer profile (Admin)
 *     description: Requires Admin role. Updates customer details, status, loyalty points, or note.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000006
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               fullName:
 *                 type: string
 *               phone:
 *                 type: string
 *               email:
 *                 type: string
 *               address:
 *                 type: string
 *               city:
 *                 type: string
 *               status:
 *                 type: string
 *                 enum: [Active, Inactive, VIP, Blocked]
 *               loyaltyPoints:
 *                 type: number
 *               note:
 *                 type: string
 *     responses:
 *       200:
 *         description: Customer updated
 *       404:
 *         description: Customer not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 *
 *   delete:
 *     tags:
 *       - Admin
 *       - Clients
 *     summary: Delete customer account (Admin)
 *     description: Requires Admin role. Deletes customer account.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000006
 *     responses:
 *       200:
 *         description: Customer deleted
 *       404:
 *         description: Customer not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 *
 * /admin/customers/{id}/status:
 *   patch:
 *     tags:
 *       - Admin
 *       - Clients
 *     summary: Update customer status (Admin)
 *     description: Requires Admin role. Changes status to Active, Inactive, VIP, or Blocked.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000006
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [Active, Inactive, VIP, Blocked]
 *                 example: VIP
 *     responses:
 *       200:
 *         description: Status updated successfully
 *       400:
 *         description: Invalid status value
 *       404:
 *         description: Customer not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 *
 * /admin/customers/{id}/vip:
 *   patch:
 *     tags:
 *       - Admin
 *       - Clients
 *     summary: Toggle customer VIP status (Admin)
 *     description: Requires Admin role. Updates customer status to VIP or Active.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000006
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               vip:
 *                 type: boolean
 *                 example: true
 *     responses:
 *       200:
 *         description: VIP status updated
 *       404:
 *         description: Customer not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 *
 * /admin/customers/{id}/rewards:
 *   patch:
 *     tags:
 *       - Admin
 *       - Clients
 *     summary: Adjust customer loyalty points (Admin)
 *     description: Requires Admin role. Perform points action (`add`, `reset`, or `set`).
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000006
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               action:
 *                 type: string
 *                 enum: [add, reset, set]
 *                 example: add
 *               points:
 *                 type: number
 *                 example: 200
 *     responses:
 *       200:
 *         description: Rewards points updated
 *       404:
 *         description: Customer not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 *
 * /admin/categories:
 *   get:
 *     tags:
 *       - Admin
 *       - Categories
 *     summary: List admin categories with revenue & sales analytics (Admin)
 *     description: Requires Admin role. Lists categories with total product counts, sales quantities, and calculated sales revenue.
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Admin category list
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 *
 *   post:
 *     tags:
 *       - Admin
 *       - Categories
 *     summary: Create category from admin portal (Admin)
 *     description: Requires Admin role. Creates category via admin route.
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *             properties:
 *               name:
 *                 type: string
 *                 example: Drinks & Juices
 *               description:
 *                 type: string
 *               image:
 *                 type: string
 *               icon:
 *                 type: string
 *               status:
 *                 type: string
 *                 enum: [Active, Inactive, Hidden, Empty]
 *               sortOrder:
 *                 type: integer
 *     responses:
 *       201:
 *         description: Category created
 *       400:
 *         description: Name is required
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 *
 * /admin/debug/categories:
 *   get:
 *     tags:
 *       - Admin
 *       - Categories
 *     summary: Debug raw categories (Admin)
 *     description: Requires Admin role. Returns raw database category documents.
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Raw categories
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 */
