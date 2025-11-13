const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  username: {
    type: String,
    required: true,
    unique: true,
    trim: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true,
  },
  password: {
    type: String,
    required: true,
    minlength: 6,
  },
  role: {
    type: String,
    enum: ['user', 'admin'],
    default: 'user'
  },
  profileImage: {
    type: String,
    default: null
  },
  firstName: {
    type: String,
    trim: true,
    default: ''
  },
  lastName: {
    type: String,
    trim: true,
    default: ''
  },
  dateOfBirth: {
    type: Date,
    default: null
  },
  phoneNumber: {
    type: String,
    trim: true,
    default: ''
  },
  preferences: {
    notifications: {
      email: {
        type: Boolean,
        default: true
      },
      push: {
        type: Boolean,
        default: true
      },
      reminders: {
        type: Boolean,
        default: true
      }
    },
    privacy: {
      shareData: {
        type: Boolean,
        default: false
      },
      publicProfile: {
        type: Boolean,
        default: false
      }
    },
    theme: {
      type: String,
      enum: ['light', 'dark', 'system'],
      default: 'system'
    }
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isSuspended: {
    type: Boolean,
    default: false
  },
  suspensionExpiry: {
    type: Date,
    default: null
  },
  suspensionReason: {
    type: String,
    default: null
  },
  lastLogin: {
    type: Date,
    default: null
  },
  createdAt: {
    type: Date,
    default: Date.now,
  }
}, {
  timestamps: true
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Method to compare password
userSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Virtual for full name
userSchema.virtual('fullName').get(function() {
  return `${this.firstName} ${this.lastName}`.trim() || this.username;
});

// Method to get user profile data (excluding sensitive information)
userSchema.methods.getPublicProfile = function() {
  const userObject = this.toObject();
  delete userObject.password;
  return userObject;
};

// Method to update last login
userSchema.methods.updateLastLogin = function() {
  this.lastLogin = new Date();
  return this.save();
};

// Static method to find active users
userSchema.statics.findActive = function() {
  return this.find({ isActive: true });
};

// Method to check if suspension has expired and update status
userSchema.methods.checkSuspensionStatus = function() {
  if (this.isSuspended && this.suspensionExpiry && new Date() > this.suspensionExpiry) {
    this.isSuspended = false;
    this.suspensionExpiry = null;
    this.suspensionReason = null;
    return this.save();
  }
  return Promise.resolve(this);
};

// Method to suspend user for specified days
userSchema.methods.suspendUser = function(days, reason) {
  this.isSuspended = true;
  this.suspensionExpiry = new Date(Date.now() + (days * 24 * 60 * 60 * 1000));
  this.suspensionReason = reason || 'Account suspended by admin';
  return this.save();
};

const User = mongoose.model('User', userSchema);
module.exports = User;