/**
 * @openapi
 * /loyalty/redeem:
 *   post:
 *     tags:
 *       - Loyalty
 *     summary: Redeem client loyalty points for rewards
 *     description: Requires Client role. Deducts loyalty points (drink=300pts, burger=500pts, meal=1000pts) and generates a reward redemption order.
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - clientId
 *               - rewardType
 *             properties:
 *               clientId:
 *                 type: string
 *                 example: 650000000000000000000006
 *               rewardType:
 *                 type: string
 *                 enum: [drink, burger, meal]
 *                 example: burger
 *     responses:
 *       200:
 *         description: Reward redeemed successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Reward redeemed successfully!
 *                 data:
 *                   type: object
 *                   properties:
 *                     client:
 *                       $ref: '#/components/schemas/Client'
 *                     reward:
 *                       type: object
 *                       properties:
 *                         type:
 *                           type: string
 *                           example: burger
 *                         name:
 *                           type: string
 *                           example: Free Burger
 *                         pointsRequired:
 *                           type: number
 *                           example: 500
 *                         value:
 *                           type: number
 *                           example: 55
 *                     order:
 *                       $ref: '#/components/schemas/Order'
 *       400:
 *         description: Missing fields, invalid reward type, or insufficient points
 *       404:
 *         description: Client not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - requires Client role
 *       500:
 *         description: Server error
 */
