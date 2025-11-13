const mongoose = require('mongoose');
const User = require('../models/User');
require('dotenv').config();

async function checkUsers() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find all users
    const users = await User.find({}).select('-password');
    
    console.log('\n=== All Users in Database ===');
    users.forEach((user, index) => {
      console.log(`\nUser ${index + 1}:`);
      console.log(`  ID: ${user._id}`);
      console.log(`  Username: ${user.username}`);
      console.log(`  Email: ${user.email}`);
      console.log(`  Role: ${user.role}`);
      console.log(`  First Name: ${user.firstName || 'Not set'}`);
      console.log(`  Last Name: ${user.lastName || 'Not set'}`);
      console.log(`  Created: ${user.createdAt}`);
      console.log(`  Active: ${user.isActive}`);
    });

    console.log(`\nTotal users: ${users.length}`);
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

checkUsers();