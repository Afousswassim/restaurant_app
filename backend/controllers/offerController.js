const MenuItem = require('../models/MenuItem');

const normalizeOfferLabel = (label, discountPercentage) => {
  if (label && label.toString().trim().length > 0) {
    return label.toString().trim();
  }
  if (discountPercentage !== undefined && discountPercentage !== null) {
    return `${discountPercentage}% OFF`;
  }
  return 'OFFER';
};

const isOfferCurrentlyActive = (item) => {
  if (!item.hasOffer || !item.isOfferActive || item.offerPrice == null) {
    return false;
  }

  const now = new Date();
  if (item.offerStartDate && new Date(item.offerStartDate) > now) {
    return false;
  }
  if (item.offerExpiresAt && new Date(item.offerExpiresAt) <= now) {
    return false;
  }
  return true;
};

exports.getAdminOffers = async (req, res) => {
  try {
    const offers = await MenuItem.find({ hasOffer: true }).sort({ offerExpiresAt: 1, category: 1, name: 1 });
    res.status(200).json({ success: true, data: offers });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.createOffer = async (req, res) => {
  try {
    const {
      productId,
      offerTitle,
      offerDescription,
      discountPercentage,
      oldPrice,
      offerPrice,
      offerLabel,
      offerStartDate,
      offerExpiresAt,
      isOfferActive,
    } = req.body;

    if (!productId) {
      return res.status(400).json({ success: false, message: 'Product selection is required.' });
    }

    if (!offerTitle || !offerTitle.toString().trim()) {
      return res.status(400).json({ success: false, message: 'Offer title is required.' });
    }

    if (offerPrice == null || oldPrice == null) {
      return res.status(400).json({ success: false, message: 'Old price and offer price are required.' });
    }

    if (Number(offerPrice) >= Number(oldPrice)) {
      return res.status(400).json({ success: false, message: 'Offer price must be less than old price.' });
    }

    const startDate = offerStartDate ? new Date(offerStartDate) : new Date();
    const expiresAt = offerExpiresAt ? new Date(offerExpiresAt) : null;

    if (expiresAt && expiresAt <= startDate) {
      return res.status(400).json({ success: false, message: 'Expiration date must be after the start date.' });
    }

    const item = await MenuItem.findById(productId);
    if (!item) {
      return res.status(404).json({ success: false, message: 'Selected product not found.' });
    }

    item.hasOffer = true;
    item.offerTitle = offerTitle.toString().trim();
    item.offerDescription = offerDescription?.toString().trim() || '';
    item.oldPrice = Number(oldPrice);
    item.offerPrice = Number(offerPrice);
    item.offerLabel = normalizeOfferLabel(offerLabel, discountPercentage);
    item.offerStartDate = startDate;
    item.offerExpiresAt = expiresAt;
    item.isOfferActive = isOfferActive !== undefined ? Boolean(isOfferActive) : true;

    await item.save();

    res.status(201).json({ success: true, data: item });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateOffer = async (req, res) => {
  try {
    const { productId } = req.params;
    const {
      offerTitle,
      offerDescription,
      discountPercentage,
      oldPrice,
      offerPrice,
      offerLabel,
      offerStartDate,
      offerExpiresAt,
      isOfferActive,
    } = req.body;

    if (!offerTitle || !offerTitle.toString().trim()) {
      return res.status(400).json({ success: false, message: 'Offer title is required.' });
    }

    if (offerPrice == null || oldPrice == null) {
      return res.status(400).json({ success: false, message: 'Old price and offer price are required.' });
    }

    if (Number(offerPrice) >= Number(oldPrice)) {
      return res.status(400).json({ success: false, message: 'Offer price must be less than old price.' });
    }

    const startDate = offerStartDate ? new Date(offerStartDate) : new Date();
    const expiresAt = offerExpiresAt ? new Date(offerExpiresAt) : null;

    if (expiresAt && expiresAt <= startDate) {
      return res.status(400).json({ success: false, message: 'Expiration date must be after the start date.' });
    }

    const item = await MenuItem.findById(productId);
    if (!item) {
      return res.status(404).json({ success: false, message: 'Offer product not found.' });
    }

    item.hasOffer = true;
    item.offerTitle = offerTitle.toString().trim();
    item.offerDescription = offerDescription?.toString().trim() || item.offerDescription || '';
    item.oldPrice = Number(oldPrice);
    item.offerPrice = Number(offerPrice);
    item.offerLabel = normalizeOfferLabel(offerLabel, discountPercentage);
    item.offerStartDate = startDate;
    item.offerExpiresAt = expiresAt;
    item.isOfferActive = isOfferActive !== undefined ? Boolean(isOfferActive) : item.isOfferActive;

    await item.save();

    res.status(200).json({ success: true, data: item });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.deleteOffer = async (req, res) => {
  try {
    const { productId } = req.params;
    const item = await MenuItem.findById(productId);
    if (!item) {
      return res.status(404).json({ success: false, message: 'Offer product not found.' });
    }

    item.hasOffer = false;
    item.offerTitle = undefined;
    item.offerDescription = undefined;
    item.oldPrice = undefined;
    item.offerPrice = undefined;
    item.offerLabel = undefined;
    item.offerStartDate = undefined;
    item.offerExpiresAt = undefined;
    item.isOfferActive = false;

    await item.save();

    res.status(200).json({ success: true, data: item });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.toggleOfferStatus = async (req, res) => {
  try {
    const { productId } = req.params;
    if (!productId) {
      return res.status(400).json({ success: false, message: 'Product ID is required.' });
    }

    const item = await MenuItem.findById(productId);
    if (!item) {
      return res.status(404).json({ success: false, message: 'Offer product not found.' });
    }

    item.isOfferActive = req.body.active !== undefined ? Boolean(req.body.active) : !item.isOfferActive;
    item.hasOffer = true;

    await item.save();

    res.status(200).json({
      success: true,
      message: 'Offer status updated',
      data: item,
      offer: item,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getActiveOffers = async (req, res) => {
  try {
    const now = new Date();
    const offers = await MenuItem.find({
      hasOffer: true,
      isOfferActive: true,
      offerPrice: { $ne: null },
      $and: [
        {
          $or: [
            { offerStartDate: { $exists: false } },
            { offerStartDate: null },
            { offerStartDate: { $lte: now } },
          ],
        },
        {
          $or: [
            { offerExpiresAt: { $exists: false } },
            { offerExpiresAt: null },
            { offerExpiresAt: { $gt: now } },
          ],
        },
      ],
    }).sort({ offerExpiresAt: 1, category: 1, name: 1 });

    res.status(200).json({ success: true, data: offers });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
