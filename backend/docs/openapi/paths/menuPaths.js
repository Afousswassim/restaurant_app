/**
 * @openapi
 * /menu:
 *   get:
 *     tags:
 *       - Menu
 *     summary: Get all menu items
 *     description: Returns a list of menu items. Supports optional search query and category filter.
 *     parameters:
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search query matching item name (case-insensitive regex)
 *         example: cheese
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *         description: Filter by category name (e.g. Burgers, Pizza, Crepe)
 *         example: Burgers
 *     responses:
 *       200:
 *         description: List of menu items
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
 *                     $ref: '#/components/schemas/MenuItem'
 *       500:
 *         description: Server error
 *
 *   post:
 *     tags:
 *       - Menu
 *     summary: Create menu item
 *     description: Requires Admin role. Adds a new product to the menu.
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
 *               - description
 *               - price
 *               - imageUrl
 *               - category
 *             properties:
 *               branchId:
 *                 type: string
 *                 nullable: true
 *                 example: 650000000000000000000001
 *               name:
 *                 type: string
 *                 example: Crispy Chicken Burger
 *               description:
 *                 type: string
 *                 example: Fried chicken breast with pickles and garlic sauce
 *               price:
 *                 type: number
 *                 example: 55
 *               imageUrl:
 *                 type: string
 *                 example: https://images.unsplash.com/photo-1568901346375-23c9450c58cd
 *               category:
 *                 type: string
 *                 example: Burgers
 *               extras:
 *                 type: array
 *                 items:
 *                   $ref: '#/components/schemas/ExtraItem'
 *               calories:
 *                 type: number
 *                 example: 550
 *               protein:
 *                 type: number
 *                 example: 30
 *               carbs:
 *                 type: number
 *                 example: 40
 *               fat:
 *                 type: number
 *                 example: 22
 *               tags:
 *                 type: array
 *                 items:
 *                   type: string
 *                 example: ["popular", "high-protein"]
 *               isAvailable:
 *                 type: boolean
 *                 example: true
 *     responses:
 *       201:
 *         description: Menu item created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/MenuItem'
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - requires Admin role
 *       500:
 *         description: Server error
 *
 * /menu/{branchId}:
 *   get:
 *     tags:
 *       - Menu
 *     summary: Get menu items by branch
 *     description: Returns menu items that either belong to the specified branch or are branch-independent (global).
 *     parameters:
 *       - in: path
 *         name: branchId
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000001
 *     responses:
 *       200:
 *         description: Branch-specific menu items
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
 *                     $ref: '#/components/schemas/MenuItem'
 *       500:
 *         description: Server error
 *
 * /menu/item/{id}:
 *   get:
 *     tags:
 *       - Menu
 *     summary: Get menu item by ID
 *     description: Retrieves detailed information for a single menu item.
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000003
 *     responses:
 *       200:
 *         description: Menu item details
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/MenuItem'
 *       404:
 *         description: Menu item not found
 *       500:
 *         description: Server error
 *
 * /menu/{id}:
 *   put:
 *     tags:
 *       - Menu
 *     summary: Update menu item
 *     description: Requires Admin role. Updates product details for an existing menu item.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000003
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/MenuItem'
 *     responses:
 *       200:
 *         description: Menu item updated successfully
 *       404:
 *         description: Menu item not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 *
 *   delete:
 *     tags:
 *       - Menu
 *     summary: Delete menu item
 *     description: Requires Admin role. Deletes a menu item from the database.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000003
 *     responses:
 *       200:
 *         description: Menu item deleted successfully
 *       404:
 *         description: Menu item not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 *
 * /menu/{id}/offer:
 *   put:
 *     tags:
 *       - Menu
 *       - Offers
 *     summary: Attach or update offer on menu item
 *     description: Requires Admin role. Sets offer price, expiration, and promotional label on a product.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000003
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - offerPrice
 *             properties:
 *               offerPrice:
 *                 type: number
 *                 example: 50
 *               discountPercentage:
 *                 type: number
 *                 example: 20
 *               offerLabel:
 *                 type: string
 *                 example: 20% OFF
 *               offerTitle:
 *                 type: string
 *                 example: Weekend Saver
 *               offerDescription:
 *                 type: string
 *                 example: Discounted price for weekend orders
 *               offerStartDate:
 *                 type: string
 *                 format: date-time
 *               offerExpiresAt:
 *                 type: string
 *                 format: date-time
 *               isOfferActive:
 *                 type: boolean
 *                 example: true
 *     responses:
 *       200:
 *         description: Offer attached successfully
 *       404:
 *         description: Menu item not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 *
 *   delete:
 *     tags:
 *       - Menu
 *       - Offers
 *     summary: Remove offer from menu item
 *     description: Requires Admin role. Deactivates and removes offer parameters from a menu item.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000003
 *     responses:
 *       200:
 *         description: Offer removed successfully
 *       404:
 *         description: Menu item not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 */
