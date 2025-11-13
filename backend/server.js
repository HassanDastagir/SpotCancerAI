const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const authRoutes = require('./routes/auth');
const imageRoutes = require('./routes/images');
const userRoutes = require('./routes/users');
const adminRoutes = require('./routes/admin');
const contactRoutes = require('./routes/contact');
const chatRoutes = require('./routes/chat');
const predictRoutes = require('./routes/predict');

dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Serve static files (uploaded images)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Serve Flutter web build as static files
app.use(express.static(path.join(__dirname, '../build/web')));

// MongoDB Connection with improved settings
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 15000, // 15 seconds
      connectTimeoutMS: 15000,
      socketTimeoutMS: 15000,
      maxPoolSize: 10, // Maintain up to 10 socket connections
      heartbeatFrequencyMS: 10000, // Send a ping every 10 seconds
      bufferCommands: false, // Disable mongoose buffering
    });
    
    console.log('✅ Connected to MongoDB Atlas successfully');
    console.log('Database ready for operations');
    return true;
  } catch (err) {
    console.error('❌ MongoDB connection error:', err.message);
    console.error('Server cannot start without database connection');
    process.exit(1);
  }
};

// Handle connection events
mongoose.connection.on('connected', () => {
  console.log('📡 Mongoose connected to MongoDB');
});

mongoose.connection.on('error', (err) => {
  console.error('📡 Mongoose connection error:', err.message);
});

mongoose.connection.on('disconnected', () => {
  console.log('📡 Mongoose disconnected from MongoDB');
});

mongoose.connection.on('reconnected', () => {
  console.log('📡 Mongoose reconnected to MongoDB');
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/images', imageRoutes);
app.use('/api/users', userRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/contact', contactRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api', predictRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'SpotCancerAI Backend is running',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Global error handler:', error);
  
  if (error.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({
      error: 'File too large',
      details: 'Maximum file size is 5MB'
    });
  }
  
  if (error.message.includes('Only JPEG, JPG, and PNG files are allowed')) {
    return res.status(400).json({
      error: 'Invalid file type',
      details: error.message
    });
  }
  
  res.status(500).json({
    error: 'Internal server error',
    details: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});

// 404 handler - Serve Flutter app for client-side routing
app.use('*', (req, res) => {
  // If it's an API request, return 404
  if (req.originalUrl.startsWith('/api/')) {
    return res.status(404).json({
      error: 'Route not found',
      message: `Cannot ${req.method} ${req.originalUrl}`
    });
  }
  
  // For all other requests, serve the Flutter app (client-side routing)
  res.sendFile(path.join(__dirname, '../build/web/index.html'));
});

const PORT = process.env.PORT || 5000;

// Start server function
const startServer = async () => {
  try {
    // Wait for database connection first
    await connectDB();
    
    // Start the server only after database is connected
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
      console.log(`Health check available at: http://localhost:${PORT}/api/health`);
    });
  } catch (error) {
    console.error('Failed to start server:', error.message);
    process.exit(1);
  }
};

// Start the application
startServer();