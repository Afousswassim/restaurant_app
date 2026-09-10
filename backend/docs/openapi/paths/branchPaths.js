/**
 * @openapi
 * /branches:
 *   get:
 *     tags:
 *       - Branches
 *     summary: List all restaurant branches
 *     description: Returns a list of all active restaurant branches, auto-generating missing QR URLs if necessary.
 *     responses:
 *       200:
 *         description: List of branches
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
 *                     $ref: '#/components/schemas/Branch'
 *       500:
 *         description: Server error
 *
 * /branches/{slug}:
 *   get:
 *     tags:
 *       - Branches
 *     summary: Get branch by slug
 *     description: Retrieves branch details by URL slug (e.g. `wassim-food-downtown`).
 *     parameters:
 *       - in: path
 *         name: slug
 *         required: true
 *         schema:
 *           type: string
 *         example: wassim-food-downtown
 *     responses:
 *       200:
 *         description: Branch details
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Branch'
 *       404:
 *         description: Branch not found
 *       500:
 *         description: Server error
 *
 * /branches/{id}/qr:
 *   get:
 *     tags:
 *       - Branches
 *     summary: Get branch QR code URL
 *     description: Returns the QR code URL for a branch by ID.
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000001
 *     responses:
 *       200:
 *         description: QR code URL
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 qrUrl:
 *                   type: string
 *                   example: https://wassimfood.com/menu/wassim-food-downtown
 *       404:
 *         description: Branch not found
 *       500:
 *         description: Server error
 *
 *   patch:
 *     tags:
 *       - Branches
 *     summary: Update branch QR code URL
 *     description: Updates the custom QR URL for a branch.
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000001
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - qrUrl
 *             properties:
 *               qrUrl:
 *                 type: string
 *                 example: https://wassimfood.com/menu/wassim-food-downtown
 *     responses:
 *       200:
 *         description: Branch updated with new QR URL
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Branch'
 *       404:
 *         description: Branch not found
 *       500:
 *         description: Server error
 */
