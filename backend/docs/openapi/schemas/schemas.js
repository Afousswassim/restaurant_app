/**
 * @openapi
 * components:
 *   schemas:
 *     ApiResponse:
 *       type: object
 *       properties:
 *         success:
 *           type: boolean
 *           example: true
 *         message:
 *           type: string
 *           example: Operation completed successfully
 *         data:
 *           type: object
 * 
 *     ErrorResponse:
 *       type: object
 *       properties:
 *         success:
 *           type: boolean
 *           example: false
 *         message:
 *           type: string
 *           example: Error description message
 * 
 *     Branch:
 *       type: object
 *       properties:
 *         _id:
 *           type: string
 *           example: 650000000000000000000001
 *         name:
 *           type: string
 *           example: Wassim Food Downtown
 *         slug:
 *           type: string
 *           example: wassim-food-downtown
 *         address:
 *           type: string
 *           example: 123 Main Street, Agadir
 *         city:
 *           type: string
 *           example: Agadir
 *         phone:
 *           type: string
 *           example: "+212 600000000"
 *         openingHours:
 *           type: string
 *           example: 10:00 AM - 11:00 PM
 *         qrUrl:
 *           type: string
 *           example: https://wassimfood.com/menu/wassim-food-downtown
 *         deliveryFee:
 *           type: number
 *           example: 15
 *         deliveryTime:
 *           type: string
 *           example: 25-35 min
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 * 
 *     Category:
 *       type: object
 *       properties:
 *         _id:
 *           type: string
 *           example: 650000000000000000000002
 *         id:
 *           type: string
 *           example: 650000000000000000000002
 *         name:
 *           type: string
 *           example: Burgers
 *         description:
 *           type: string
 *           example: Delicious juicy gourmet burgers
 *         image:
 *           type: string
 *           example: https://images.unsplash.com/photo-1568901346375-23c9450c58cd
 *         icon:
 *           type: string
 *           example: fastfood
 *         status:
 *           type: string
 *           enum: [Active, Inactive, Hidden, Empty]
 *           example: Active
 *         sortOrder:
 *           type: integer
 *           example: 1
 *         productCount:
 *           type: integer
 *           example: 12
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 * 
 *     ExtraItem:
 *       type: object
 *       required:
 *         - name:
 *         - price:
 *       properties:
 *         name:
 *           type: string
 *           example: Extra Cheese
 *         price:
 *           type: number
 *           example: 5
 * 
 *     MenuItem:
 *       type: object
 *       properties:
 *         _id:
 *           type: string
 *           example: 650000000000000000000003
 *         branchId:
 *           type: string
 *           nullable: true
 *           example: 650000000000000000000001
 *         name:
 *           type: string
 *           example: Double Cheese Burger
 *         description:
 *           type: string
 *           example: Fresh beef patty with double cheddar cheese and secret sauce
 *         price:
 *           type: number
 *           example: 65
 *         hasOffer:
 *           type: boolean
 *           example: true
 *         oldPrice:
 *           type: number
 *           example: 80
 *         offerPrice:
 *           type: number
 *           example: 65
 *         offerTitle:
 *           type: string
 *           example: Special Weekend Deal
 *         offerDescription:
 *           type: string
 *           example: Save 15 DH on all burger combos
 *         offerStartDate:
 *           type: string
 *           format: date-time
 *         offerExpiresAt:
 *           type: string
 *           format: date-time
 *         offerLabel:
 *           type: string
 *           example: 18% OFF
 *         isOfferActive:
 *           type: boolean
 *           example: true
 *         imageUrl:
 *           type: string
 *           example: https://images.unsplash.com/photo-1568901346375-23c9450c58cd
 *         category:
 *           type: string
 *           example: Burgers
 *         calories:
 *           type: number
 *           example: 650
 *         protein:
 *           type: number
 *           example: 35
 *         carbs:
 *           type: number
 *           example: 45
 *         fat:
 *           type: number
 *           example: 28
 *         tags:
 *           type: array
 *           items:
 *             type: string
 *           example: ["high-protein", "popular"]
 *         extras:
 *           type: array
 *           items:
 *             $ref: '#/components/schemas/ExtraItem'
 *         isAvailable:
 *           type: boolean
 *           example: true
 *         rating:
 *           type: number
 *           example: 4.8
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 * 
 *     CartItem:
 *       type: object
 *       properties:
 *         _id:
 *           type: string
 *           example: 650000000000000000000004
 *         sessionId:
 *           type: string
 *           example: sess_123456789
 *         menuItemId:
 *           oneOf:
 *             - type: string
 *             - $ref: '#/components/schemas/MenuItem'
 *         branchId:
 *           type: string
 *           example: 650000000000000000000001
 *         quantity:
 *           type: integer
 *           example: 2
 *         selectedExtras:
 *           type: array
 *           items:
 *             $ref: '#/components/schemas/ExtraItem'
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 * 
 *     OrderItem:
 *       type: object
 *       properties:
 *         menuItemId:
 *           type: string
 *           example: 650000000000000000000003
 *         name:
 *           type: string
 *           example: Double Cheese Burger
 *         quantity:
 *           type: integer
 *           example: 2
 *         price:
 *           type: number
 *           example: 65
 *         originalPrice:
 *           type: number
 *           example: 80
 *         finalPrice:
 *           type: number
 *           example: 65
 *         offerApplied:
 *           type: boolean
 *           example: true
 *         selectedExtras:
 *           type: array
 *           items:
 *             $ref: '#/components/schemas/ExtraItem'
 * 
 *     Order:
 *       type: object
 *       properties:
 *         _id:
 *           type: string
 *           example: 650000000000000000000005
 *         customerName:
 *           type: string
 *           example: Wassim Dev
 *         phone:
 *           type: string
 *           example: "+212 612345678"
 *         address:
 *           type: string
 *           example: Avenue Hassan II, Agadir
 *         branch:
 *           type: object
 *           properties:
 *             id:
 *               type: string
 *               example: 650000000000000000000001
 *             name:
 *               type: string
 *               example: Wassim Food Downtown
 *             address:
 *               type: string
 *               example: 123 Main Street, Agadir
 *             deliveryFee:
 *               type: number
 *               example: 15
 *             deliveryTime:
 *               type: string
 *               example: 25-35 min
 *         items:
 *           type: array
 *           items:
 *             $ref: '#/components/schemas/OrderItem'
 *         subtotal:
 *           type: number
 *           example: 130
 *         deliveryFee:
 *           type: number
 *           example: 15
 *         discount:
 *           type: number
 *           example: 20
 *         couponCode:
 *           type: string
 *           example: WELCOME20
 *         totalAmount:
 *           type: number
 *           example: 125
 *         status:
 *           type: string
 *           enum: [pending, preparing, delivering, delivered, cancelled, reward_redeemed]
 *           example: pending
 *         paymentMethod:
 *           type: string
 *           example: cash
 *         notes:
 *           type: string
 *           example: Extra napkins please
 *         clientId:
 *           type: string
 *           nullable: true
 *           example: 650000000000000000000006
 *         orderType:
 *           type: string
 *           enum: [order, reward]
 *           example: order
 *         pointsUsed:
 *           type: number
 *           example: 0
 *         rewardName:
 *           type: string
 *           example: ""
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 * 
 *     Client:
 *       type: object
 *       properties:
 *         _id:
 *           type: string
 *           example: 650000000000000000000006
 *         fullName:
 *           type: string
 *           example: Wassim Client
 *         phone:
 *           type: string
 *           example: "+212 612345678"
 *         email:
 *           type: string
 *           example: client@wassimfood.com
 *         address:
 *           type: string
 *           example: Avenue Hassan II, Agadir
 *         landmark:
 *           type: string
 *           example: Near Supratours station
 *         loyaltyPoints:
 *           type: number
 *           example: 450
 *         status:
 *           type: string
 *           enum: [Active, Inactive, VIP, Blocked]
 *           example: Active
 *         city:
 *           type: string
 *           example: Agadir
 *         avatar:
 *           type: string
 *           example: https://i.pravatar.cc/150?u=wassim
 *         note:
 *           type: string
 *           example: VIP client
 *         lastLoginAt:
 *           type: string
 *           format: date-time
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 * 
 *     Coupon:
 *       type: object
 *       properties:
 *         _id:
 *           type: string
 *           example: 650000000000000000000007
 *         code:
 *           type: string
 *           example: WELCOME20
 *         type:
 *           type: string
 *           enum: [percentage, fixed, free_delivery]
 *           example: percentage
 *         value:
 *           type: number
 *           example: 20
 *         minOrderAmount:
 *           type: number
 *           example: 100
 *         applicableCategories:
 *           type: array
 *           items:
 *             type: string
 *           example: ["Burgers", "Pizza"]
 *         clientOnly:
 *           type: boolean
 *           example: false
 *         isActive:
 *           type: boolean
 *           example: true
 *         expiresAt:
 *           type: string
 *           format: date-time
 *           nullable: true
 *         isUsed:
 *           type: boolean
 *           example: false
 *         clientId:
 *           type: string
 *           nullable: true
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 * 
 *     Notification:
 *       type: object
 *       properties:
 *         _id:
 *           type: string
 *           example: 650000000000000000000008
 *         clientId:
 *           type: string
 *           example: 650000000000000000000006
 *         orderId:
 *           type: string
 *           example: 650000000000000000000005
 *         title:
 *           type: string
 *           example: Order #A1B2C3 status updated
 *         message:
 *           type: string
 *           example: Your order #A1B2C3 is now Preparing.
 *         isRead:
 *           type: boolean
 *           example: false
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 */
