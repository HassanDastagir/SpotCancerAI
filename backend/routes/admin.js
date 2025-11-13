const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const auth = require('../middleware/auth');

// Middleware to check if user is admin
const requireAdmin = async (req, res, next) => {
  try {
    const user = await User.findById(req.userId);
    if (!user || user.role !== 'admin') {
      return res.status(403).json({ error: 'Admin access required' });
    }
    req.user = user;
    next();
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
};

// Change admin password
router.put('/change-password', auth, requireAdmin, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    // Validation
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ 
        error: 'Current password and new password are required' 
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ 
        error: 'New password must be at least 6 characters long' 
      });
    }

    // Verify current password
    const isMatch = await req.user.comparePassword(currentPassword);
    if (!isMatch) {
      return res.status(400).json({ error: 'Current password is incorrect' });
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 12);
    
    // Update password
    req.user.password = hashedPassword;
    await req.user.save();

    res.json({
      success: true,
      message: 'Password changed successfully'
    });

  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ 
      error: 'Server error during password change',
      details: error.message 
    });
  }
});

// Get admin dashboard data
router.get('/dashboard', auth, requireAdmin, async (req, res) => {
  try {
    const totalUsers = await User.countDocuments({ role: 'user' });
    const activeUsers = await User.countDocuments({ role: 'user', isActive: true });
    const recentUsers = await User.find({ role: 'user' })
      .sort({ createdAt: -1 })
      .limit(5)
      .select('username email createdAt isActive');

    res.json({
      success: true,
      data: {
        totalUsers,
        activeUsers,
        recentUsers
      }
    });

  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).json({ 
      error: 'Server error fetching dashboard data',
      details: error.message 
    });
  }
});

// Get all users (admin only)
router.get('/users', auth, requireAdmin, async (req, res) => {
  try {
    const users = await User.find({ role: 'user' })
      .select('-password')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      users
    });

  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ 
      error: 'Server error fetching users',
      details: error.message 
    });
  }
});

// Delete user (admin only)
router.delete('/users/:userId', auth, requireAdmin, async (req, res) => {
  try {
    const { userId } = req.params;

    // Check if user exists and is not an admin
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (user.role === 'admin') {
      return res.status(403).json({ error: 'Cannot delete admin users' });
    }

    // Delete the user
    await User.findByIdAndDelete(userId);

    res.json({
      success: true,
      message: 'User deleted successfully'
    });

  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ 
      error: 'Server error deleting user',
      details: error.message 
    });
  }
});

// Suspend user (admin only)
router.put('/users/:userId/suspend', auth, requireAdmin, async (req, res) => {
  try {
    const { userId } = req.params;
    const { days = 7, reason } = req.body;

    // Check if user exists and is not an admin
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (user.role === 'admin') {
      return res.status(403).json({ error: 'Cannot suspend admin users' });
    }

    // Suspend the user
    await user.suspendUser(days, reason);

    res.json({
      success: true,
      message: `User suspended for ${days} days`,
      suspensionExpiry: user.suspensionExpiry
    });

  } catch (error) {
    console.error('Suspend user error:', error);
    res.status(500).json({ 
      error: 'Server error suspending user',
      details: error.message 
    });
  }
});

// Unsuspend user (admin only)
router.put('/users/:userId/unsuspend', auth, requireAdmin, async (req, res) => {
  try {
    const { userId } = req.params;

    // Check if user exists
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Unsuspend the user
    user.isSuspended = false;
    user.suspensionExpiry = null;
    user.suspensionReason = null;
    await user.save();

    res.json({
      success: true,
      message: 'User unsuspended successfully'
    });

  } catch (error) {
    console.error('Unsuspend user error:', error);
    res.status(500).json({ 
      error: 'Server error unsuspending user',
      details: error.message 
    });
  }
});

module.exports = router;