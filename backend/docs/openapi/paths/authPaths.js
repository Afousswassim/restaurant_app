/**
 * @openapi
 * /clients/register:
 *   post:
 *     tags:
 *       - Authentication
 *     summary: Register a new client account
 *     description: Creates a new client profile with hashed password and returns a JWT authentication token.
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - fullName
 *               - phone
 *               - email
 *               - password
 *             properties:
 *               fullName:
 *                 type: string
 *                 example: Wassim Client
 *               phone:
 *                 type: string
 *                 example: "+212 612345678"
 *               email:
 *                 type: string
 *                 example: client@wassimfood.com
 *               password:
 *                 type: string
 *                 format: password
 *                 example: securePassword123
 *     responses:
 *       201:
 *         description: Client registered successfully
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
 *                     token:
 *                       type: string
 *                       example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
 *                     client:
 *                       $ref: '#/components/schemas/Client'
 *       400:
 *         description: Missing required fields or email already registered
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *
 * /clients/login:
 *   post:
 *     tags:
 *       - Authentication
 *     summary: Client login
 *     description: Authenticates a client using email and password, updating `lastLoginAt` and returning a JWT token.
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 example: client@wassimfood.com
 *               password:
 *                 type: string
 *                 format: password
 *                 example: securePassword123
 *     responses:
 *       200:
 *         description: Login successful
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
 *                     token:
 *                       type: string
 *                       example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
 *                     client:
 *                       $ref: '#/components/schemas/Client'
 *       400:
 *         description: Email and password are required
 *       401:
 *         description: Invalid email or password
 *       403:
 *         description: Account deactivated or blocked
 *       500:
 *         description: Server error
 *
 * /clients/profile:
 *   get:
 *     tags:
 *       - Clients
 *     summary: Get authenticated client profile
 *     description: Returns the full profile details for the currently authenticated client token. Requires Client role.
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Client profile data
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Client'
 *       401:
 *         description: Unauthorized - missing or invalid token
 *       403:
 *         description: Forbidden - requires Client role or account is deactivated
 *       500:
 *         description: Server error
 *
 *   put:
 *     tags:
 *       - Clients
 *     summary: Update client profile
 *     description: Updates full name, phone number, delivery address, or landmark for the authenticated client.
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               fullName:
 *                 type: string
 *                 example: Wassim Client Updated
 *               phone:
 *                 type: string
 *                 example: "+212 699887766"
 *               address:
 *                 type: string
 *                 example: Boulevard Mohammed V, Agadir
 *               landmark:
 *                 type: string
 *                 example: Opposite Wilaya
 *     responses:
 *       200:
 *         description: Profile updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Client'
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       500:
 *         description: Server error
 */
