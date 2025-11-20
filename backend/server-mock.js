const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { mockUsers } = require('./mock-data');
const multer = require('multer');
const upload = multer();
const { predictImage } = require('./services/modelService');

dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Serve static files (uploaded images)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Mock database
let users = [...mockUsers];

// JWT middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, message: 'Access token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ success: false, message: 'Invalid token' });
    }
    req.user = user;
    next();
  });
};

// Admin middleware
const requireAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ success: false, message: 'Admin access required' });
  }
  next();
};

// Auth Routes
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = users.find(u => u.email === email);
    if (!user) {
      return res.status(400).json({ success: false, message: 'Invalid credentials' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ success: false, message: 'Invalid credentials' });
    }

    // Check if user is suspended
    if (user.isSuspended && user.suspensionExpiry && new Date() < new Date(user.suspensionExpiry)) {
      return res.status(403).json({
        success: false,
        message: 'Account suspended',
        suspensionReason: user.suspensionReason,
        suspensionExpiry: user.suspensionExpiry
      });
    }

    const token = jwt.sign(
      { userId: user._id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    const userResponse = {
      id: user._id,
      username: user.username,
      email: user.email,
      role: user.role,
      createdAt: user.createdAt,
      profileImage: user.profileImage,
      isActive: user.isActive,
      isSuspended: user.isSuspended,
      suspensionExpiry: user.suspensionExpiry,
      suspensionReason: user.suspensionReason
    };

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: userResponse
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Register user
app.post('/api/auth/register', async (req, res) => {
  try {
    const { username, email, password } = req.body;

    // Validation
    if (!username || !email || !password) {
      return res.status(400).json({ 
        success: false,
        message: 'Username, email, and password are required' 
      });
    }

    if (password.length < 6) {
      return res.status(400).json({ 
        success: false,
        message: 'Password must be at least 6 characters long' 
      });
    }

    // Check if user already exists
    const existingUser = users.find(u => u.email === email || u.username === username);
    if (existingUser) {
      if (existingUser.email === email) {
        return res.status(400).json({ success: false, message: 'Email already registered' });
      }
      if (existingUser.username === username) {
        return res.status(400).json({ success: false, message: 'Username already taken' });
      }
    }

    // Create new user
    const newUser = {
      _id: (users.length + 1).toString(),
      username,
      email,
      password: await bcrypt.hash(password, 12),
      role: 'user',
      firstName: '',
      lastName: '',
      isActive: true,
      isSuspended: false,
      createdAt: new Date(),
      profileImage: null
    };

    users.push(newUser);

    // Generate JWT token
    const token = jwt.sign(
      { userId: newUser._id, email: newUser.email, role: newUser.role },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    const userResponse = {
      id: newUser._id,
      username: newUser.username,
      email: newUser.email,
      role: newUser.role,
      createdAt: newUser.createdAt,
      profileImage: newUser.profileImage,
      isActive: newUser.isActive,
      isSuspended: newUser.isSuspended
    };

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      token,
      user: userResponse
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Admin Routes
app.get('/api/admin/dashboard', authenticateToken, requireAdmin, (req, res) => {
  try {
    const totalUsers = users.length;
    const activeUsers = users.filter(u => u.isActive && !u.isSuspended).length;
    const suspendedUsers = users.filter(u => u.isSuspended).length;
    
    // New users in last 30 days
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const newUsers = users.filter(u => new Date(u.createdAt) > thirtyDaysAgo).length;

    res.json({
      success: true,
      data: {
        totalUsers,
        activeUsers,
        suspendedUsers,
        newUsers
      }
    });
  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

app.get('/api/admin/users', authenticateToken, requireAdmin, (req, res) => {
  try {
    const usersResponse = users.map(user => ({
      id: user._id,
      username: user.username,
      email: user.email,
      role: user.role,
      isActive: user.isActive,
      isSuspended: user.isSuspended,
      suspensionExpiry: user.suspensionExpiry,
      suspensionReason: user.suspensionReason,
      createdAt: user.createdAt,
      profileImage: user.profileImage
    }));

    res.json({
      success: true,
      users: usersResponse
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

app.delete('/api/admin/users/:userId', authenticateToken, requireAdmin, (req, res) => {
  try {
    const { userId } = req.params;
    
    const userIndex = users.findIndex(u => u._id === userId);
    if (userIndex === -1) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const user = users[userIndex];
    if (user.role === 'admin') {
      return res.status(400).json({ success: false, message: 'Cannot delete admin user' });
    }

    users.splice(userIndex, 1);

    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

app.post('/api/admin/users/:userId/suspend', authenticateToken, requireAdmin, (req, res) => {
  try {
    const { userId } = req.params;
    const { days, reason } = req.body;

    const user = users.find(u => u._id === userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (user.role === 'admin') {
      return res.status(400).json({ success: false, message: 'Cannot suspend admin user' });
    }

    const suspensionExpiry = new Date();
    suspensionExpiry.setDate(suspensionExpiry.getDate() + parseInt(days));

    user.isSuspended = true;
    user.suspensionExpiry = suspensionExpiry;
    user.suspensionReason = reason || 'No reason provided';

    res.json({
      success: true,
      message: 'User suspended successfully'
    });
  } catch (error) {
    console.error('Suspend user error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

app.post('/api/admin/users/:userId/unsuspend', authenticateToken, requireAdmin, (req, res) => {
  try {
    const { userId } = req.params;

    const user = users.find(u => u._id === userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    user.isSuspended = false;
    user.suspensionExpiry = null;
    user.suspensionReason = null;

    res.json({
      success: true,
      message: 'User unsuspended successfully'
    });
  } catch (error) {
    console.error('Unsuspend user error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Predict Route (mock server -> forwards to ML service)
// Mirrors real backend: POST /api/predict with multipart field 'file'
app.post('/api/predict', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No file uploaded' });
    }

    const mimeType = req.file.mimetype || 'application/octet-stream';
    const buffer = req.file.buffer;
    const filename = req.file.originalname || 'upload.jpg';

    // Forward to ML service (FastAPI) via modelService
    const result = await predictImage(buffer, filename, mimeType);

    // Ensure consistent response shape
    return res.json({ success: true, ...result });
  } catch (error) {
    console.error('Predict error (mock):', error?.response?.data || error.message);
    return res.status(500).json({ success: false, message: 'Inference failed', details: error?.message });
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'SpotCancerAI Backend is running (Mock Mode)',
    timestamp: new Date().toISOString(),
    version: '1.0.0-mock'
  });
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Global error handler:', error);
  res.status(500).json({
    success: false,
    message: 'Internal server error'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT} (Mock Mode)`);
  console.log(`Health check available at: http://localhost:${PORT}/api/health`);
  console.log('Mock Admin Credentials:');
  console.log('Email: admin@spotcancerai.com');
  console.log('Password: spotcancerai123');
});