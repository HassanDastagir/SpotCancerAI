const mongoose = require('mongoose');
const User = require('../models/User');
const jwt = require('jsonwebtoken');
require('dotenv').config();

async function testProfileAPI() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find the user with email ch.muhammad.usman21@gmail.com
    const user = await User.findOne({ email: 'ch.muhammad.usman21@gmail.com' });
    
    if (!user) {
      console.log('User not found!');
      return;
    }

    console.log('\n=== User Found ===');
    console.log(`ID: ${user._id}`);
    console.log(`Username: ${user.username}`);
    console.log(`Email: ${user.email}`);
    console.log(`Role: ${user.role}`);

    // Test what getPublicProfile returns
    const publicProfile = user.getPublicProfile();
    console.log('\n=== Public Profile Data ===');
    console.log(JSON.stringify(publicProfile, null, 2));

    // Generate a token for this user (simulate login)
    const token = jwt.sign(
      { userId: user._id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    console.log('\n=== Generated Token ===');
    console.log(`Token: ${token.substring(0, 50)}...`);

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    console.log('\n=== Decoded Token ===');
    console.log(`User ID: ${decoded.userId}`);
    console.log(`Email: ${decoded.email}`);
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

testProfileAPI();