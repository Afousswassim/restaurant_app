/**
 * @openapi
 * /cart:
 *   get:
 *     tags:
 *       - Cart
 *     summary: Get cart items for session
 *     description: Returns populated cart items associated with the provided `sessionId`.
 *     parameters:
 *       - in: query
 *         name: sessionId
 *         required: true
 *         schema:
 *           type: string
 *         example: sess_123456789
 *     responses:
 *       200:
 *         description: List of cart items
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
 *                     $ref: '#/components/schemas/CartItem'
 *       400:
 *         description: Session ID is required
 *       500:
 *         description: Server error
 *
 *   post:
 *     tags:
 *       - Cart
 *     summary: Add item to cart
 *     description: Adds a product with optional selected extras to the shopping cart session. Merges quantity if matching item and extras already exist.
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - sessionId
 *               - menuItemId
 *               - branchId
 *               - quantity
 *             properties:
 *               sessionId:
 *                 type: string
 *                 example: sess_123456789
 *               menuItemId:
 *                 type: string
 *                 example: 650000000000000000000003
 *               branchId:
 *                 type: string
 *                 example: 650000000000000000000001
 *               quantity:
 *                 type: integer
 *                 example: 2
 *               selectedExtras:
 *                 type: array
 *                 items:
 *                   $ref: '#/components/schemas/ExtraItem'
 *     responses:
 *       200:
 *         description: Item added and updated cart returned
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
 *                     $ref: '#/components/schemas/CartItem'
 *       400:
 *         description: Missing required fields
 *       404:
 *         description: Menu item not found
 *       500:
 *         description: Server error
 *
 *   delete:
 *     tags:
 *       - Cart
 *     summary: Clear entire cart
 *     description: Removes all items associated with the specified `sessionId`.
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               sessionId:
 *                 type: string
 *                 example: sess_123456789
 *     parameters:
 *       - in: query
 *         name: sessionId
 *         schema:
 *           type: string
 *         example: sess_123456789
 *     responses:
 *       200:
 *         description: Cart cleared successfully
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
 *                   example: []
 *       400:
 *         description: Session ID is required
 *       500:
 *         description: Server error
 *
 * /cart/{id}:
 *   put:
 *     tags:
 *       - Cart
 *     summary: Update cart item quantity
 *     description: Updates the quantity of a specific cart item by `_id` or `menuItemId`. If quantity <= 0, the item is removed.
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Cart item _id or menuItemId
 *         example: 650000000000000000000004
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - sessionId
 *               - quantity
 *             properties:
 *               sessionId:
 *                 type: string
 *                 example: sess_123456789
 *               quantity:
 *                 type: integer
 *                 example: 3
 *     responses:
 *       200:
 *         description: Cart item updated and active cart returned
 *       400:
 *         description: Session ID is required
 *       404:
 *         description: Cart item not found
 *       500:
 *         description: Server error
 *
 *   delete:
 *     tags:
 *       - Cart
 *     summary: Remove single item from cart
 *     description: Deletes a specific cart item by `_id` or `menuItemId`.
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000004
 *       - in: query
 *         name: sessionId
 *         schema:
 *           type: string
 *         example: sess_123456789
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               sessionId:
 *                 type: string
 *                 example: sess_123456789
 *     responses:
 *       200:
 *         description: Cart item removed and updated cart returned
 *       400:
 *         description: Session ID is required
 *       404:
 *         description: Cart item not found
 *       500:
 *         description: Server error
 */
