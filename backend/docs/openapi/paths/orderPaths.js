/**
 * @openapi
 * /orders:
 *   post:
 *     tags:
 *       - Orders
 *     summary: Place a new order
 *     description: Converts active session cart items into a submitted order, calculates subtotals, applies coupons/discounts, clears cart items, and updates client loyalty points.
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - sessionId
 *               - customerName
 *               - phone
 *               - address
 *               - branch
 *             properties:
 *               sessionId:
 *                 type: string
 *                 example: sess_123456789
 *               customerName:
 *                 type: string
 *                 example: Wassim Client
 *               phone:
 *                 type: string
 *                 example: "+212 612345678"
 *               address:
 *                 type: string
 *                 example: Avenue Hassan II, Agadir
 *               branch:
 *                 type: object
 *                 required:
 *                   - name
 *                 properties:
 *                   id:
 *                     type: string
 *                     example: 650000000000000000000001
 *                   name:
 *                     type: string
 *                     example: Wassim Food Downtown
 *                   address:
 *                     type: string
 *                     example: 123 Main Street, Agadir
 *                   deliveryFee:
 *                     type: number
 *                     example: 15
 *                   deliveryTime:
 *                     type: string
 *                     example: 25-35 min
 *               paymentMethod:
 *                 type: string
 *                 example: cash
 *               notes:
 *                 type: string
 *                 example: Call upon arrival
 *               clientId:
 *                 type: string
 *                 example: 650000000000000000000006
 *               discount:
 *                 type: number
 *                 example: 20
 *               couponCode:
 *                 type: string
 *                 example: WELCOME20
 *     responses:
 *       201:
 *         description: Order placed successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Order'
 *       400:
 *         description: Missing required fields or cart is empty
 *       500:
 *         description: Server error
 *
 *   get:
 *     tags:
 *       - Orders
 *       - Admin
 *     summary: List all orders (Admin)
 *     description: Requires Admin role. Retrieves all platform orders, optionally filtered by `clientId`.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: clientId
 *         schema:
 *           type: string
 *         description: Filter orders by client ID
 *         example: 650000000000000000000006
 *     responses:
 *       200:
 *         description: List of orders
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
 *                     $ref: '#/components/schemas/Order'
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - requires Admin role
 *       500:
 *         description: Server error
 *
 * /orders/{id}:
 *   get:
 *     tags:
 *       - Orders
 *     summary: Get order details by ID
 *     description: Retrieves details of a specific order by order ID.
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000005
 *     responses:
 *       200:
 *         description: Order details
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Order'
 *       404:
 *         description: Order not found
 *       500:
 *         description: Server error
 *
 * /orders/{id}/status:
 *   put:
 *     tags:
 *       - Orders
 *       - Admin
 *     summary: Update order status (Admin)
 *     description: Requires Admin role. Updates order status (`pending`, `preparing`, `delivering`, `delivered`) and automatically triggers client status notifications.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000005
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
 *                 enum: [pending, preparing, delivering, delivered, cancelled]
 *                 example: preparing
 *     responses:
 *       200:
 *         description: Order status updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Order'
 *       400:
 *         description: Status is required
 *       404:
 *         description: Order not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - requires Admin role
 *       500:
 *         description: Server error
 */
