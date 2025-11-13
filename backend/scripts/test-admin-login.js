const mongoose = require('mongoose');
const User = require('../models/User');
require('dotenv').config();

const testAdminLogin = async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/spotcancerai');
    console.log('Connected to MongoDB');

    // Find admin user
    const admin = await User.findOne({ email: 'admin@spotcancerai.com' });
    
    if (!admin) {
      console.log('❌ Admin user not found');
      return;
    }

    console.log('✅ Admin user found');
    console.log('Email:', admin.email);
    console.log('Role:', admin.role);
    console.log('Active:', admin.isActive);
    console.log('Suspended:', admin.isSuspended);

    // Test password comparison
    const testPassword = 'spotcancerai123';
    const isMatch = await admin.comparePassword(testPassword);
    
    if (isMatch) {
      console.log('✅ Password verification successful');
      console.log('Admin login should work with:');
      console.log('Email: admin@spotcancerai.com');
      console.log('Password: spotcancerai123');
    } else {
      console.log('❌ Password verification failed');
    }

    await mongoose.disconnect();
    console.log('Test completed');
    
  } catch (error) {
    console.error('Error testing admin login:', error);
    process.exit(1);
  }
};

testAdminLogin();