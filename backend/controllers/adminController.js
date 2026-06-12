/**
 * Admin authentication controller.
 * Handles simple backend login for administrative portal.
 */

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required',
      });
    }

    if (email === 'admin@wassimfood.com' && password === 'admin123') {
      return res.status(200).json({
        success: true,
        token: 'simple-admin-token',
        admin: {
          email: 'admin@wassimfood.com',
          name: 'Admin Wassim Food',
        },
      });
    } else {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Internal server error during login',
    });
  }
};
