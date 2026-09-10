/**
 * @openapi
 * /ai/food-assistant:
 *   post:
 *     tags:
 *       - AI
 *     summary: Generate AI Food Assistant meal plan
 *     description: Generates intelligent meal plans and food recommendations based on mode (`history`, `nutrition`, or `meal_planner`), budget constraints, group size, and nutrition goals (`healthy`, `high protein`, `low calories`, `budget friendly`, `family meal`).
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               mode:
 *                 type: string
 *                 enum: [history, nutrition, meal_planner]
 *                 example: meal_planner
 *                 description: Assistant mode algorithm
 *               clientId:
 *                 type: string
 *                 example: 650000000000000000000006
 *               branchId:
 *                 type: string
 *                 example: 650000000000000000000001
 *               goal:
 *                 type: string
 *                 example: high protein
 *                 description: Nutrition goal tag
 *               budget:
 *                 type: number
 *                 example: 120
 *                 description: Maximum total DH budget for meal plan
 *               people:
 *                 type: integer
 *                 example: 2
 *                 description: Group size
 *               preference:
 *                 type: string
 *                 example: Burger
 *                 description: Food category preference
 *     responses:
 *       200:
 *         description: AI meal plan generated successfully
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
 *                     title:
 *                       type: string
 *                       example: AI Recommended Meal Plan
 *                     reason:
 *                       type: string
 *                       example: This plan respects your 120 DH budget and matches Burger preference for 2 people.
 *                     total:
 *                       type: number
 *                       example: 110
 *                     items:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/MenuItem'
 *       500:
 *         description: Server error
 */
