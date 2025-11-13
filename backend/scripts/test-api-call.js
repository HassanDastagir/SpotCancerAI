const axios = require('axios');
const mongoose = require('mongoose');
const User = require('../models/User');
const jwt = require('jsonwebtoken');
require('dotenv').config();

async function testAPICall() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find the user
    const user = await User.findOne({ email: 'ch.muhammad.usman21@gmail.com' });
    
    if (!user) {
      console.log('User not found!');
      return;
    }

    // Generate a token for this user
    const token = jwt.sign(
      { userId: user._id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    console.log('=== Making API Call ===');
    console.log(`URL: http://localhost:5000/api/users/profile`);
    console.log(`Token: ${token.substring(0, 50)}...`);

    // Make the API call
    const response = await axios.get('http://localhost:5000/api/users/profile', {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      }
    });

    console.log('\n=== API Response ===');
    console.log(`Status: ${response.status}`);
    console.log('Data:');
    console.log(JSON.stringify(response.data, null, 2));

  } catch (error) {
    console.error('Error:', error.response?.data || error.message);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

testAPICall();