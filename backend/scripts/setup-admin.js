const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
require('dotenv').config();

const setupAdmin = async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/spotcancerai');
    console.log('Connected to MongoDB');

    // Check if admin already exists
    const existingAdmin = await User.findOne({ email: 'admin@spotcancerai.com' });
    
    if (existingAdmin) {
      console.log('Admin user already exists');
      
      // Update password if needed (let the model handle hashing)
      existingAdmin.password = 'spotcancerai123';
      existingAdmin.role = 'admin';
      await existingAdmin.save();
      
      console.log('Admin password updated successfully');
    } else {
      // Create new admin user (let the model handle hashing)
      const adminUser = new User({
        username: 'admin',
        email: 'admin@spotcancerai.com',
        password: 'spotcancerai123',
        role: 'admin',
        firstName: 'System',
        lastName: 'Administrator',
        isActive: true
      });

      await adminUser.save();
      console.log('Admin user created successfully');
      console.log('Email: admin@spotcancerai.com');
      console.log('Password: spotcancerai123');
      console.log('Role: admin');
    }

    await mongoose.disconnect();
    console.log('Setup completed');
    
  } catch (error) {
    console.error('Error setting up admin:', error);
    process.exit(1);
  }
};

// Run the setup
setupAdmin();