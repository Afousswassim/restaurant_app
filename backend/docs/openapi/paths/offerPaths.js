/**
 * @openapi
 * /offers:
 *   get:
 *     tags:
 *       - Offers
 *     summary: List active public promotional offers
 *     description: Returns a list of currently active, non-expired product offers for active categories.
 *     responses:
 *       200:
 *         description: List of active promotional offers
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
 * /admin/offers:
 *   get:
 *     tags:
 *       - Offers
 *       - Admin
 *     summary: List all promotional offers (Admin)
 *     description: Requires Admin role. Returns all menu items that have promotional offers.
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of offers
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
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - requires Admin role
 *       500:
 *         description: Server error
 *
 *   post:
 *     tags:
 *       - Offers
 *       - Admin
 *     summary: Create new promotional offer (Admin)
 *     description: Requires Admin role. Attaches an offer to a selected product.
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - productId
 *               - offerTitle
 *               - oldPrice
 *               - offerPrice
 *             properties:
 *               productId:
 *                 type: string
 *                 example: 650000000000000000000003
 *               offerTitle:
 *                 type: string
 *                 example: Special Burger Fest
 *               offerDescription:
 *                 type: string
 *                 example: 25% discount on double cheese burgers
 *               discountPercentage:
 *                 type: number
 *                 example: 25
 *               oldPrice:
 *                 type: number
 *                 example: 80
 *               offerPrice:
 *                 type: number
 *                 example: 60
 *               offerLabel:
 *                 type: string
 *                 example: 25% OFF
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
 *       201:
 *         description: Offer created successfully
 *       400:
 *         description: Validation error in prices or dates
 *       404:
 *         description: Product not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 *
 * /admin/offers/{productId}:
 *   put:
 *     tags:
 *       - Offers
 *       - Admin
 *     summary: Update existing offer (Admin)
 *     description: Requires Admin role. Updates promotional offer details on a product.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: productId
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
 *               - offerTitle
 *               - oldPrice
 *               - offerPrice
 *             properties:
 *               offerTitle:
 *                 type: string
 *                 example: Super Saver Deal
 *               offerDescription:
 *                 type: string
 *               discountPercentage:
 *                 type: number
 *               oldPrice:
 *                 type: number
 *               offerPrice:
 *                 type: number
 *               offerLabel:
 *                 type: string
 *               offerStartDate:
 *                 type: string
 *                 format: date-time
 *               offerExpiresAt:
 *                 type: string
 *                 format: date-time
 *               isOfferActive:
 *                 type: boolean
 *     responses:
 *       200:
 *         description: Offer updated successfully
 *       400:
 *         description: Invalid parameters
 *       404:
 *         description: Product not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 *
 *   delete:
 *     tags:
 *       - Offers
 *       - Admin
 *     summary: Delete offer from product (Admin)
 *     description: Requires Admin role. Removes promotional offer attributes from product.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: productId
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000003
 *     responses:
 *       200:
 *         description: Offer removed
 *       404:
 *         description: Product not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 *
 * /admin/offers/{productId}/toggle:
 *   patch:
 *     tags:
 *       - Offers
 *       - Admin
 *     summary: Toggle offer active status (Admin)
 *     description: Requires Admin role. Enables or disables offer visibility.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: productId
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000003
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               active:
 *                 type: boolean
 *                 example: false
 *     responses:
 *       200:
 *         description: Offer status updated
 *       404:
 *         description: Product not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 */
