const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const ScanResult = require('../models/ScanResult');
const auth = require('../middleware/auth');

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads/';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const fileFilter = (req, file, cb) => {
  const allowedTypes = /jpeg|jpg|png/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedTypes.test(file.mimetype);

  if (mimetype && extname) {
    return cb(null, true);
  } else {
    cb(new Error('Only JPEG, JPG, and PNG files are allowed'));
  }
};

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: fileFilter
});

// Mock AI analysis function (replace with actual AI model integration)
const analyzeImage = async (imagePath) => {
  // Simulate AI processing time
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  // Mock analysis results
  const predictions = ['Benign', 'Malignant', 'Suspicious'];
  const prediction = predictions[Math.floor(Math.random() * predictions.length)];
  const confidence = Math.random() * 0.4 + 0.6; // 0.6 to 1.0
  
  let riskLevel = 'Low';
  let recommendations = [];
  
  if (prediction === 'Malignant') {
    riskLevel = confidence > 0.7 ? 'High' : 'Medium';
    recommendations = [
      'Consult a dermatologist immediately',
      'Schedule a biopsy if recommended',
      'Monitor the area closely for changes',
      'Avoid sun exposure to the affected area'
    ];
  } else if (prediction === 'Suspicious') {
    riskLevel = confidence > 0.6 ? 'Medium' : 'Low';
    recommendations = [
      'Schedule an appointment with a dermatologist',
      'Monitor the area for any changes',
      'Take photos to track changes over time',
      'Use sunscreen regularly'
    ];
  } else {
    riskLevel = 'Low';
    recommendations = [
      'Continue regular skin self-examinations',
      'Use sunscreen daily',
      'Schedule routine dermatology check-ups',
      'Monitor for any changes in size, color, or shape'
    ];
  }
  
  return {
    prediction,
    confidence,
    riskLevel,
    recommendations
  };
};

// Upload and analyze image
router.post('/upload', auth, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file provided' });
    }

    const imagePath = req.file.path;
    const imageUrl = `/uploads/${req.file.filename}`;
    
    // Perform AI analysis
    const analysisResult = await analyzeImage(imagePath);
    
    // Save scan result to database
    const scanResult = new ScanResult({
      userId: req.user.userId,
      imagePath: imagePath,
      imageUrl: imageUrl,
      prediction: analysisResult.prediction,
      confidence: analysisResult.confidence,
      riskLevel: analysisResult.riskLevel,
      recommendations: analysisResult.recommendations
    });
    
    await scanResult.save();
    
    res.json({
      success: true,
      message: 'Image analyzed successfully',
      scanId: scanResult._id,
      result: {
        prediction: analysisResult.prediction,
        confidence: analysisResult.confidence,
        confidencePercentage: Math.round(analysisResult.confidence * 100),
        riskLevel: analysisResult.riskLevel,
        recommendations: analysisResult.recommendations,
        imageUrl: imageUrl,
        scanDate: scanResult.scanDate
      }
    });
  } catch (error) {
    console.error('Image analysis error:', error);
    
    // Clean up uploaded file if analysis fails
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    
    res.status(500).json({ 
      error: 'Failed to analyze image',
      details: error.message 
    });
  }
});

// Get scan result by ID
router.get('/scan/:scanId', auth, async (req, res) => {
  try {
    const scanResult = await ScanResult.findOne({
      _id: req.params.scanId,
      userId: req.user.userId
    });
    
    if (!scanResult) {
      return res.status(404).json({ error: 'Scan result not found' });
    }
    
    res.json({
      success: true,
      result: scanResult
    });
  } catch (error) {
    console.error('Get scan result error:', error);
    res.status(500).json({ 
      error: 'Failed to retrieve scan result',
      details: error.message 
    });
  }
});

// Get user's scan history
router.get('/history', auth, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const riskLevel = req.query.riskLevel;
    const sortBy = req.query.sortBy || 'scanDate';
    const sortOrder = req.query.sortOrder === 'asc' ? 1 : -1;
    
    const query = { userId: req.user.userId };
    if (riskLevel && riskLevel !== 'All') {
      query.riskLevel = riskLevel;
    }
    
    const scanResults = await ScanResult.find(query)
      .sort({ [sortBy]: sortOrder })
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .exec();
    
    const total = await ScanResult.countDocuments(query);
    
    res.json({
      success: true,
      results: scanResults,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(total / limit),
        totalResults: total,
        hasNext: page < Math.ceil(total / limit),
        hasPrev: page > 1
      }
    });
  } catch (error) {
    console.error('Get scan history error:', error);
    res.status(500).json({ 
      error: 'Failed to retrieve scan history',
      details: error.message 
    });
  }
});

// Delete scan result
router.delete('/scan/:scanId', auth, async (req, res) => {
  try {
    const scanResult = await ScanResult.findOne({
      _id: req.params.scanId,
      userId: req.user.userId
    });
    
    if (!scanResult) {
      return res.status(404).json({ error: 'Scan result not found' });
    }
    
    // Delete associated image file
    if (fs.existsSync(scanResult.imagePath)) {
      fs.unlinkSync(scanResult.imagePath);
    }
    
    await ScanResult.findByIdAndDelete(req.params.scanId);
    
    res.json({
      success: true,
      message: 'Scan result deleted successfully'
    });
  } catch (error) {
    console.error('Delete scan result error:', error);
    res.status(500).json({ 
      error: 'Failed to delete scan result',
      details: error.message 
    });
  }
});

module.exports = router;