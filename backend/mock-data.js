// Mock data for testing admin interface without MongoDB connection
const bcrypt = require('bcryptjs');

// Mock users data
const mockUsers = [
  {
    _id: '1',
    username: 'admin',
    email: 'admin@spotcancerai.com',
    password: bcrypt.hashSync('spotcancerai123', 12),
    role: 'admin',
    firstName: 'System',
    lastName: 'Administrator',
    isActive: true,
    isSuspended: false,
    createdAt: new Date('2024-01-01'),
    profileImage: null
  },
  {
    _id: '2',
    username: 'john_doe',
    email: 'john@example.com',
    password: bcrypt.hashSync('password123', 12),
    role: 'user',
    firstName: 'John',
    lastName: 'Doe',
    isActive: true,
    isSuspended: false,
    createdAt: new Date('2024-01-15'),
    profileImage: null
  },
  {
    _id: '3',
    username: 'jane_smith',
    email: 'jane@example.com',
    password: bcrypt.hashSync('password123', 12),
    role: 'user',
    firstName: 'Jane',
    lastName: 'Smith',
    isActive: true,
    isSuspended: true,
    suspensionExpiry: new Date('2024-12-31'),
    suspensionReason: 'Violation of terms',
    createdAt: new Date('2024-02-01'),
    profileImage: null
  },
  {
    _id: '4',
    username: 'bob_wilson',
    email: 'bob@example.com',
    password: bcrypt.hashSync('password123', 12),
    role: 'user',
    firstName: 'Bob',
    lastName: 'Wilson',
    isActive: true,
    isSuspended: false,
    createdAt: new Date('2024-03-01'),
    profileImage: null
  }
];

module.exports = { mockUsers };