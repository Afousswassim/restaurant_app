const Branch = require('../models/Branch');

exports.getBranches = async (req, res) => {
  try {
    const branches = await Branch.find({});
    res.status(200).json({
      success: true,
      data: branches,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.getBranchBySlug = async (req, res) => {
  try {
    const { slug } = req.params;
    const branch = await Branch.findOne({ slug });
    if (!branch) {
      return res.status(404).json({ success: false, message: 'Branch not found' });
    }
    res.status(200).json({ success: true, data: branch });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
