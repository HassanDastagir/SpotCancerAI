const mongoose = require('mongoose');
const Contact = require('./models/Contact');
const User = require('./models/User');
require('dotenv').config();

async function testContacts() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');
    
    const count = await Contact.countDocuments();
    console.log('Total contacts:', count);
    
    const contacts = await Contact.find().populate('userId', 'username email').sort({ createdAt: -1 }).limit(3);
    console.log('Recent contacts:');
    contacts.forEach((contact, i) => {
      console.log(`${i+1}. Subject: ${contact.subject}`);
      console.log(`   User: ${contact.userId?.username || 'Unknown'} (${contact.userId?.email || 'No email'})`);
      console.log(`   Message: ${contact.message.substring(0, 100)}...`);
      console.log(`   Created: ${contact.createdAt}`);
      console.log(`   Status: ${contact.status}`);
      console.log('---');
    });
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

testContacts();