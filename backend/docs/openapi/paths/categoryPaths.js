/**
 * @openapi
 * /categories:
 *   get:
 *     tags:
 *       - Categories
 *     summary: List all active categories
 *     description: Returns a list of active menu categories sorted by sort order, including live product counts for each category.
 *     responses:
 *       200:
 *         description: List of active categories
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
 *                     $ref: '#/components/schemas/Category'
 *       500:
 *         description: Server error
 *
 *   post:
 *     tags:
 *       - Categories
 *     summary: Create a new category
 *     description: Requires Admin role. Creates a new category for food menu items.
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
 *                 example: Desserts
 *               description:
 *                 type: string
 *                 example: Delicious crêpes, ice cream, and cakes
 *               image:
 *                 type: string
 *                 example: https://images.unsplash.com/photo-1551024709-8f23befc6f87
 *               icon:
 *                 type: string
 *                 example: icecream
 *               status:
 *                 type: string
 *                 enum: [Active, Inactive, Hidden, Empty]
 *                 example: Active
 *               sortOrder:
 *                 type: integer
 *                 example: 5
 *     responses:
 *       201:
 *         description: Category created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Category'
 *       400:
 *         description: Category name is required
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - requires Admin role
 *       500:
 *         description: Server error
 *
 * /categories/{id}:
 *   put:
 *     tags:
 *       - Categories
 *     summary: Update category
 *     description: Requires Admin role. Updates category details and syncs category name changes across menu items.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000002
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
 *                 example: Gourmet Burgers
 *               description:
 *                 type: string
 *                 example: Premium hand-crafted burgers
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
 *       200:
 *         description: Category updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Category'
 *       400:
 *         description: Category name is required
 *       404:
 *         description: Category not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 *
 *   delete:
 *     tags:
 *       - Categories
 *     summary: Delete category
 *     description: Requires Admin role. Deletes a category if no menu items are currently linked to it.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         example: 650000000000000000000002
 *     responses:
 *       200:
 *         description: Category deleted successfully
 *       404:
 *         description: Category not found
 *       409:
 *         description: Conflict - Category has linked products
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 */
