/**
 * @openapi
 * /notifications/{clientId}:
 *   get:
 *     tags:
 *       - Notifications
 *     summary: Get client notifications
 *     description: Retrieves up to 100 recent notifications for a given client ID.
 *     parameters:
 *       - in: path
 *         name: clientId
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000006
 *     responses:
 *       200:
 *         description: List of notifications
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
 *                     $ref: '#/components/schemas/Notification'
 *       500:
 *         description: Server error
 *
 * /notifications:
 *   post:
 *     tags:
 *       - Notifications
 *     summary: Create new notification
 *     description: Creates a new notification record for a client order update or system alert.
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - clientId
 *               - orderId
 *               - title
 *               - message
 *             properties:
 *               clientId:
 *                 type: string
 *                 example: 650000000000000000000006
 *               orderId:
 *                 type: string
 *                 example: 650000000000000000000005
 *               title:
 *                 type: string
 *                 example: Order #A1B2C3 is ready
 *               message:
 *                 type: string
 *                 example: Your food is being prepared and will arrive soon!
 *               isRead:
 *                 type: boolean
 *                 example: false
 *     responses:
 *       201:
 *         description: Notification created
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Notification'
 *       400:
 *         description: Missing required fields
 *       500:
 *         description: Server error
 *
 * /notifications/{id}/read:
 *   put:
 *     tags:
 *       - Notifications
 *     summary: Mark single notification as read
 *     description: Sets `isRead` to `true` for a specific notification ID.
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000008
 *     responses:
 *       200:
 *         description: Notification marked as read
 *       404:
 *         description: Notification not found
 *       500:
 *         description: Server error
 *
 * /notifications/{clientId}/read-all:
 *   put:
 *     tags:
 *       - Notifications
 *     summary: Mark all notifications as read for client
 *     description: Sets `isRead` to `true` across all unread notifications for the specified client ID.
 *     parameters:
 *       - in: path
 *         name: clientId
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000006
 *     responses:
 *       200:
 *         description: All client notifications marked as read
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
 *                     modifiedCount:
 *                       type: integer
 *                       example: 5
 *       500:
 *         description: Server error
 */
