const axios = require('axios');

async function testContactEndpoint() {
  try {
    console.log('Testing contact endpoint...');
    
    // Test without authentication (should fail)
    try {
      const response = await axios.post('http://localhost:5000/api/contact/submit', {
        subject: 'Test Subject',
        message: 'Test Message',
        priority: 'medium'
      });
      console.log('Unexpected success without auth:', response.data);
    } catch (error) {
      console.log('Expected auth error:', error.response?.status, error.response?.data?.error);
    }
    
    // Test with invalid token (should fail)
    try {
      const response = await axios.post('http://localhost:5000/api/contact/submit', {
        subject: 'Test Subject',
        message: 'Test Message',
        priority: 'medium'
      }, {
        headers: {
          'Authorization': 'Bearer invalid-token'
        }
      });
      console.log('Unexpected success with invalid token:', response.data);
    } catch (error) {
      console.log('Expected invalid token error:', error.response?.status, error.response?.data?.error);
    }
    
  } catch (error) {
    console.error('Test error:', error.message);
  }
}

testContactEndpoint();