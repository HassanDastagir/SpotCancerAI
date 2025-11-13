const mongoose = require('mongoose');

const scanResultSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  imagePath: {
    type: String,
    required: true
  },
  imageUrl: {
    type: String,
    required: true
  },
  prediction: {
    type: String,
    required: true
  },
  confidence: {
    type: Number,
    required: true,
    min: 0,
    max: 1
  },
  riskLevel: {
    type: String,
    required: true,
    enum: ['Low', 'Medium', 'High']
  },
  recommendations: [{
    type: String
  }],
  additionalData: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },
  scanDate: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Index for efficient queries
scanResultSchema.index({ userId: 1, scanDate: -1 });
scanResultSchema.index({ prediction: 1 });
scanResultSchema.index({ riskLevel: 1 });

// Virtual for confidence percentage
scanResultSchema.virtual('confidencePercentage').get(function() {
  return Math.round(this.confidence * 100);
});

// Method to get risk level based on confidence and prediction
scanResultSchema.methods.calculateRiskLevel = function() {
  if (this.prediction === 'Malignant') {
    return this.confidence > 0.7 ? 'High' : 'Medium';
  } else if (this.prediction === 'Suspicious') {
    return this.confidence > 0.6 ? 'Medium' : 'Low';
  } else {
    return 'Low';
  }
};

// Static method to get user statistics
scanResultSchema.statics.getUserStats = async function(userId) {
  const stats = await this.aggregate([
    { $match: { userId: new mongoose.Types.ObjectId(userId) } },
    {
      $group: {
        _id: null,
        totalScans: { $sum: 1 },
        highRisk: {
          $sum: { $cond: [{ $eq: ['$riskLevel', 'High'] }, 1, 0] }
        },
        mediumRisk: {
          $sum: { $cond: [{ $eq: ['$riskLevel', 'Medium'] }, 1, 0] }
        },
        lowRisk: {
          $sum: { $cond: [{ $eq: ['$riskLevel', 'Low'] }, 1, 0] }
        },
        avgConfidence: { $avg: '$confidence' },
        lastScan: { $max: '$scanDate' }
      }
    }
  ]);
  
  return stats.length > 0 ? stats[0] : {
    totalScans: 0,
    highRisk: 0,
    mediumRisk: 0,
    lowRisk: 0,
    avgConfidence: 0,
    lastScan: null
  };
};

module.exports = mongoose.model('ScanResult', scanResultSchema);