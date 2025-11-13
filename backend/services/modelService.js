const axios = require('axios');
const FormData = require('form-data');

const ML_URL = process.env.ML_URL || 'http://localhost:8001/predict';

async function predictImage(buffer, filename, mimeType = 'image/jpeg') {
  const form = new FormData();
  form.append('file', buffer, { filename, contentType: mimeType });

  const resp = await axios.post(ML_URL, form, {
    headers: form.getHeaders(),
    maxContentLength: Infinity,
    maxBodyLength: Infinity,
    timeout: 30000,
  });

  return resp.data;
}

module.exports = { predictImage };