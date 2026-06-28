const { generateFoodAssistantPlan } = require('../services/aiFoodAssistant');

exports.generateFoodAssistantPlan = async (req, res) => {
  try {
    const plan = await generateFoodAssistantPlan(req.body);

    res.status(200).json({
      success: true,
      data: plan,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
