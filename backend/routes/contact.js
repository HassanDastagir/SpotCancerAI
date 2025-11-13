const express = require('express');
const Contact = require('../models/Contact');
const auth = require('../middleware/auth');

const router = express.Router();

// Submit a new contact query (User)
router.post('/submit', auth, async (req, res) => {
  try {
    const { subject, message, priority } = req.body;

    // Validation
    if (!subject || !message) {
      return res.status(400).json({ 
        error: 'Subject and message are required' 
      });
    }

    if (subject.length > 200) {
      return res.status(400).json({ 
        error: 'Subject must be less than 200 characters' 
      });
    }

    if (message.length > 2000) {
      return res.status(400).json({ 
        error: 'Message must be less than 2000 characters' 
      });
    }

    const contact = new Contact({
      userId: req.user.userId,
      subject: subject.trim(),
      message: message.trim(),
      priority: priority || 'medium'
    });

    await contact.save();

    // Populate user information for response
    await contact.populate('userId', 'username email');

    res.status(201).json({
      success: true,
      message: 'Your query has been submitted successfully',
      contact: contact
    });

  } catch (error) {
    console.error('Submit contact error:', error);
    res.status(500).json({ 
      error: 'Failed to submit contact query',
      details: error.message 
    });
  }
});

// Get user's own contact queries (User)
router.get('/my-queries', auth, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const contacts = await Contact.find({ userId: req.user.userId })
      .populate('adminReply.repliedBy', 'username')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Contact.countDocuments({ userId: req.user.userId });

    res.json({
      success: true,
      contacts,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(total / limit),
        totalContacts: total,
        hasNext: page < Math.ceil(total / limit),
        hasPrev: page > 1
      }
    });

  } catch (error) {
    console.error('Get user queries error:', error);
    res.status(500).json({ 
      error: 'Failed to retrieve your queries',
      details: error.message 
    });
  }
});

// Get all contact queries (Admin only)
router.get('/all', auth, async (req, res) => {
  try {
    // Check if user is admin
    const User = require('../models/User');
    const user = await User.findById(req.user.userId);
    
    if (!user || user.role !== 'admin') {
      return res.status(403).json({ error: 'Access denied. Admin only.' });
    }

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;
    const status = req.query.status;
    const priority = req.query.priority;

    // Build filter
    let filter = {};
    if (status) filter.status = status;
    if (priority) filter.priority = priority;

    const contacts = await Contact.find(filter)
      .populate('userId', 'username email')
      .populate('adminReply.repliedBy', 'username')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Contact.countDocuments(filter);

    res.json({
      success: true,
      contacts,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(total / limit),
        totalContacts: total,
        hasNext: page < Math.ceil(total / limit),
        hasPrev: page > 1
      }
    });

  } catch (error) {
    console.error('Get all contacts error:', error);
    res.status(500).json({ 
      error: 'Failed to retrieve contact queries',
      details: error.message 
    });
  }
});

// Update contact status (Admin only)
router.put('/:id/status', auth, async (req, res) => {
  try {
    // Check if user is admin
    const User = require('../models/User');
    const user = await User.findById(req.user.userId);
    
    if (!user || user.role !== 'admin') {
      return res.status(403).json({ error: 'Access denied. Admin only.' });
    }

    const { status } = req.body;
    
    if (!['pending', 'in_progress', 'resolved'].includes(status)) {
      return res.status(400).json({ 
        error: 'Invalid status. Must be pending, in_progress, or resolved' 
      });
    }

    const contact = await Contact.findById(req.params.id);
    
    if (!contact) {
      return res.status(404).json({ error: 'Contact query not found' });
    }

    contact.status = status;
    await contact.save();

    await contact.populate([
      { path: 'userId', select: 'username email' },
      { path: 'adminReply.repliedBy', select: 'username' }
    ]);

    res.json({
      success: true,
      message: 'Contact status updated successfully',
      contact
    });

  } catch (error) {
    console.error('Update contact status error:', error);
    res.status(500).json({ 
      error: 'Failed to update contact status',
      details: error.message 
    });
  }
});

// Reply to contact query (Admin only)
router.post('/:id/reply', auth, async (req, res) => {
  try {
    // Check if user is admin
    const User = require('../models/User');
    const user = await User.findById(req.user.userId);
    
    if (!user || user.role !== 'admin') {
      return res.status(403).json({ error: 'Access denied. Admin only.' });
    }

    const { message } = req.body;
    
    if (!message || message.trim().length === 0) {
      return res.status(400).json({ error: 'Reply message is required' });
    }

    if (message.length > 2000) {
      return res.status(400).json({ 
        error: 'Reply message must be less than 2000 characters' 
      });
    }

    const contact = await Contact.findById(req.params.id);
    
    if (!contact) {
      return res.status(404).json({ error: 'Contact query not found' });
    }

    // Add reply using the model method
    await contact.addReply(message.trim(), req.user.userId);

    await contact.populate([
      { path: 'userId', select: 'username email' },
      { path: 'adminReply.repliedBy', select: 'username' }
    ]);

    res.json({
      success: true,
      message: 'Reply sent successfully',
      contact
    });

  } catch (error) {
    console.error('Reply to contact error:', error);
    res.status(500).json({ 
      error: 'Failed to send reply',
      details: error.message 
    });
  }
});

// Get contact statistics (Admin only)
router.get('/stats', auth, async (req, res) => {
  try {
    // Check if user is admin
    const User = require('../models/User');
    const user = await User.findById(req.user.userId);
    
    if (!user || user.role !== 'admin') {
      return res.status(403).json({ error: 'Access denied. Admin only.' });
    }

    const stats = await Contact.getStats();

    res.json({
      success: true,
      statistics: stats
    });

  } catch (error) {
    console.error('Get contact stats error:', error);
    res.status(500).json({ 
      error: 'Failed to retrieve contact statistics',
      details: error.message 
    });
  }
});

module.exports = router;