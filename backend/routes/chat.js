const express = require('express');
const router = express.Router();
const Chat = require('../models/Chat');
const auth = require('../middleware/auth');

// Get all chat messages (with pagination)
router.get('/messages', auth, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const skip = (page - 1) * limit;

    const messages = await Chat.find({ isDeleted: false })
      .populate('sender', 'username email')
      .sort({ timestamp: -1 })
      .limit(limit)
      .skip(skip);

    const totalMessages = await Chat.countDocuments({ isDeleted: false });

    res.json({
      success: true,
      messages: messages.reverse(), // Reverse to show oldest first
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(totalMessages / limit),
        totalMessages,
        hasMore: skip + messages.length < totalMessages
      }
    });
  } catch (error) {
    console.error('Error fetching chat messages:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch chat messages'
    });
  }
});

// Send a new chat message
router.post('/send', auth, async (req, res) => {
  try {
    const { message } = req.body;

    if (!message || message.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Message content is required'
      });
    }

    if (message.length > 1000) {
      return res.status(400).json({
        success: false,
        message: 'Message is too long (max 1000 characters)'
      });
    }

    const newMessage = new Chat({
      message: message.trim(),
      sender: req.user.userId,
      senderName: req.user.username
    });

    await newMessage.save();

    // Populate sender info for response
    await newMessage.populate('sender', 'username email');

    res.status(201).json({
      success: true,
      message: 'Message sent successfully',
      data: newMessage
    });
  } catch (error) {
    console.error('Error sending chat message:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send message'
    });
  }
});

// Get recent messages (for real-time updates)
router.get('/recent', auth, async (req, res) => {
  try {
    const since = req.query.since ? new Date(req.query.since) : new Date(Date.now() - 60000); // Last minute by default
    
    const messages = await Chat.find({
      isDeleted: false,
      timestamp: { $gt: since }
    })
      .populate('sender', 'username email')
      .sort({ timestamp: 1 });

    res.json({
      success: true,
      messages
    });
  } catch (error) {
    console.error('Error fetching recent messages:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch recent messages'
    });
  }
});

// Delete a message (soft delete)
router.delete('/message/:messageId', auth, async (req, res) => {
  try {
    const { messageId } = req.params;
    
    const message = await Chat.findById(messageId);
    
    if (!message) {
      return res.status(404).json({
        success: false,
        message: 'Message not found'
      });
    }

    // Only allow users to delete their own messages
    if (message.sender.toString() !== req.user.userId) {
      return res.status(403).json({
        success: false,
        message: 'You can only delete your own messages'
      });
    }

    message.isDeleted = true;
    await message.save();

    res.json({
      success: true,
      message: 'Message deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting message:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete message'
    });
  }
});

// Get chat statistics
router.get('/stats', auth, async (req, res) => {
  try {
    const totalMessages = await Chat.countDocuments({ isDeleted: false });
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    
    const todayMessages = await Chat.countDocuments({
      isDeleted: false,
      timestamp: { $gte: todayStart }
    });

    const activeUsers = await Chat.distinct('sender', {
      isDeleted: false,
      timestamp: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) } // Last 24 hours
    });

    res.json({
      success: true,
      stats: {
        totalMessages,
        todayMessages,
        activeUsers: activeUsers.length
      }
    });
  } catch (error) {
    console.error('Error fetching chat stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch chat statistics'
    });
  }
});

module.exports = router;