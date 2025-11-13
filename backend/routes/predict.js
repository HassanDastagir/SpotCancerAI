const express = require('express');
const router = express.Router();
const multer = require('multer');
const upload = multer();
const { predictImage } = require('../services/modelService');
const crypto = require('crypto');

// POST /api/predict
router.post('/predict', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const mimeType = req.file.mimetype || 'application/octet-stream';
    const buffer = req.file.buffer;
    const filename = req.file.originalname;

    // Instrumentation: log hash of uploaded file and prediction summary
    const fileHash = crypto.createHash('sha256').update(buffer).digest('hex');
    console.log(`[predict] incoming file: name=${filename}, mime=${mimeType}, sha256=${fileHash.slice(0,16)}... size=${buffer.length}`);

    const result = await predictImage(buffer, filename, mimeType);

    // Log ML response summary for diagnosis
    if (result && result.success) {
      const topLabel = result.top_label || result.label;
      const topIndex = result.top_index;
      const probs = Array.isArray(result.probabilities) ? result.probabilities : null;
      console.log(`[predict] result: top_label=${topLabel} top_index=${topIndex} probs_sample=${probs ? probs.slice(0,3).map(p=>p.toFixed(4)).join(',') : 'n/a'}`);
    } else {
      console.log(`[predict] error:`, result);
    }

    res.json({ success: true, ...result });
  } catch (err) {
    console.error('Inference error', err?.response?.data || err.message);
    res.status(500).json({ error: 'Inference failed', details: err?.message });
  }
});

module.exports = router;