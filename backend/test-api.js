const mongoose = require('mongoose');
const Contact = require('./models/Contact');
const User = require('./models/User');
require('dotenv').config();

async function testAPI() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');
    
    // Simulate the exact query that the /all endpoint makes
    const page = 1;
    const limit = 5;
    const skip = (page - 1) * limit;
    
    const contacts = await Contact.find({})
      .populate('userId', 'username email')
      .populate('adminReply.repliedBy', 'username')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Contact.countDocuments({});
    
    console.log('API Response simulation:');
    console.log('Total contacts:', total);
    console.log('Contacts returned:', contacts.length);
    
    const response = {
      success: true,
      contacts,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(total / limit),
        totalContacts: total,
        hasNext: page < Math.ceil(total / limit),
        hasPrev: page > 1
      }
    };
    
    console.log('\nFormatted for admin dashboard:');
    const messages = contacts.map((contact) => {
      return {
        title: contact.subject || 'No Subject',
        description: `by ${contact.userId?.username || 'Unknown User'} | ${contact.message?.substring(0, 50) || ''}${(contact.message?.length || 0) > 50 ? '...' : ''}`,
        timestamp: contact.createdAt.toISOString(),
      };
    });
    
    console.log('Messages for dashboard:', JSON.stringify(messages, null, 2));
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

testAPI();