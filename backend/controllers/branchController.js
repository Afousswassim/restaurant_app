const Branch = require('../models/Branch');

exports.getBranches = async (req, res) => {
  try {
    const branches = await Branch.find({});
    
    // Auto-generate qrUrl if missing
    let modified = false;
    for (let branch of branches) {
      if (!branch.qrUrl) {
        // Assume frontend lives at the same host or a known base URL. 
        // For Wassim Food, the user specified https://wassimfood.com/menu/:slug
        branch.qrUrl = `https://wassimfood.com/menu/${branch.slug}`;
        await branch.save();
        modified = true;
      }
    }
    
    // Re-fetch if modified to ensure we send the latest
    const finalBranches = modified ? await Branch.find({}) : branches;

    res.status(200).json({
      success: true,
      data: finalBranches,
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

exports.getBranchQR = async (req, res) => {
  try {
    const { id } = req.params;
    const branch = await Branch.findById(id);
    if (!branch) {
      return res.status(404).json({ success: false, message: 'Branch not found' });
    }
    
    if (!branch.qrUrl) {
      branch.qrUrl = `https://wassimfood.com/menu/${branch.slug}`;
      await branch.save();
    }
    
    res.status(200).json({ success: true, qrUrl: branch.qrUrl });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateBranchQR = async (req, res) => {
  try {
    const { id } = req.params;
    const { qrUrl } = req.body;
    
    const branch = await Branch.findById(id);
    if (!branch) {
      return res.status(404).json({ success: false, message: 'Branch not found' });
    }
    
    branch.qrUrl = qrUrl;
    await branch.save();
    
    res.status(200).json({ success: true, data: branch });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
