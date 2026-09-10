const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

const port = process.env.PORT || 5000;
const defaultUrl = `http://localhost:${port}`;

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Wassim Food API',
      version: '1.0.0',
      description: 'REST API for the Wassim Food mobile food ordering and delivery application.',
    },
    servers: [
      {
        url: process.env.SWAGGER_SERVER_URL || process.env.RENDER_EXTERNAL_URL || defaultUrl,
        description: 'Server Endpoint',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Enter JWT bearer token (e.g. Bearer <token>)',
        },
      },
    },
    tags: [
      { name: 'Authentication', description: 'Client authentication & profile management' },
      { name: 'Branches', description: 'Restaurant branch locations & QR codes' },
      { name: 'Categories', description: 'Food menu categories' },
      { name: 'Menu', description: 'Menu items & product offerings' },
      { name: 'Cart', description: 'Shopping cart session management' },
      { name: 'Orders', description: 'Order creation & tracking' },
      { name: 'Clients', description: 'Client details & profile management' },
      { name: 'Admin', description: 'Admin authentication, customer management & analytics' },
      { name: 'Offers', description: 'Special discounts & promotional deals' },
      { name: 'Coupons', description: 'Discount codes & coupon validation' },
      { name: 'Loyalty', description: 'Loyalty points & reward redemptions' },
      { name: 'Notifications', description: 'Client notification updates' },
      { name: 'AI', description: 'AI Food Assistant & personalized meal planning' },
    ],
  },
  apis: [
    './docs/openapi/schemas/*.js',
    './docs/openapi/paths/*.js',
    './routes/*.js',
  ],
};

const swaggerSpec = swaggerJsdoc(options);

module.exports = {
  swaggerUi,
  swaggerSpec,
};
