/**
 * @openapi
 * /coupons:
 *   get:
 *     tags:
 *       - Coupons
 *     summary: List unused coupons
 *     description: Returns a list of active, unused coupons, optionally filtered by `clientId`.
 *     parameters:
 *       - in: query
 *         name: clientId
 *         schema:
 *           type: string
 *         description: Filter coupons by client ID
 *         example: 650000000000000000000006
 *     responses:
 *       200:
 *         description: List of available coupons
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
 *                     $ref: '#/components/schemas/Coupon'
 *       500:
 *         description: Server error
 *
 * /coupons/validate:
 *   post:
 *     tags:
 *       - Coupons
 *     summary: Validate coupon code
 *     description: Validates coupon codes (e.g. WELCOME20, BURGER50, FREESHIP or DB coupons) against order subtotal and calculates discount amount.
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - code
 *             properties:
 *               code:
 *                 type: string
 *                 example: WELCOME20
 *               subtotal:
 *                 type: number
 *                 example: 150
 *     responses:
 *       200:
 *         description: Coupon validated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: object
 *                   properties:
 *                     code:
 *                       type: string
 *                       example: WELCOME20
 *                     discountType:
 *                       type: string
 *                       example: percentage
 *                     value:
 *                       type: number
 *                       example: 20
 *                     discount:
 *                       type: number
 *                       example: 30
 *       400:
 *         description: Missing code or subtotal threshold not met
 *       404:
 *         description: Invalid, used, or expired coupon code
 *       500:
 *         description: Server error
 */
