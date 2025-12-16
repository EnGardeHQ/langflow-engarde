#!/usr/bin/env node

/**
 * Frontend Configuration Test Script
 * Verifies that the frontend is properly configured to connect to the backend
 */

const https = require('https');
const http = require('http');

// Test configuration
const FRONTEND_URL = 'http://localhost:3000';
const BACKEND_URL = 'http://localhost:8000';

// Create HTTP agent that allows self-signed certificates
const agent = new https.Agent({
  rejectUnauthorized: false
});

/**
 * Make an HTTP request with promise wrapper
 */
function makeRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    const protocol = url.startsWith('https') ? https : http;
    const requestOptions = {
      ...options,
      agent: url.startsWith('https') ? agent : undefined
    };

    const req = protocol.request(url, requestOptions, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({
            status: res.statusCode,
            headers: res.headers,
            data: data,
            json: res.headers['content-type']?.includes('application/json') ? JSON.parse(data) : null
          });
        } catch (e) {
          resolve({
            status: res.statusCode,
            headers: res.headers,
            data: data,
            json: null
          });
        }
      });
    });

    req.on('error', reject);

    if (options.body) {
      req.write(options.body);
    }

    req.end();
  });
}

/**
 * Test suite
 */
async function runTests() {
  console.log('🚀 Frontend Configuration Test Suite');
  console.log('=====================================\n');

  const results = {
    passed: 0,
    failed: 0,
    tests: []
  };

  // Test 1: Frontend homepage loads
  try {
    console.log('1. Testing frontend homepage...');
    const response = await makeRequest(FRONTEND_URL);
    if (response.status === 200) {
      console.log('   ✅ Frontend homepage loads successfully');
      results.passed++;
      results.tests.push({ name: 'Frontend Homepage', status: 'PASS' });
    } else {
      throw new Error(`Unexpected status: ${response.status}`);
    }
  } catch (error) {
    console.log(`   ❌ Frontend homepage failed: ${error.message}`);
    results.failed++;
    results.tests.push({ name: 'Frontend Homepage', status: 'FAIL', error: error.message });
  }

  // Test 2: Frontend login page loads
  try {
    console.log('2. Testing frontend login page...');
    const response = await makeRequest(`${FRONTEND_URL}/login`);
    if (response.status === 200) {
      console.log('   ✅ Login page loads successfully');
      results.passed++;
      results.tests.push({ name: 'Login Page', status: 'PASS' });
    } else {
      throw new Error(`Unexpected status: ${response.status}`);
    }
  } catch (error) {
    console.log(`   ❌ Login page failed: ${error.message}`);
    results.failed++;
    results.tests.push({ name: 'Login Page', status: 'FAIL', error: error.message });
  }

  // Test 3: Backend direct access
  try {
    console.log('3. Testing backend direct access...');
    const response = await makeRequest(`${BACKEND_URL}/health`);
    if (response.status === 200 && response.json?.status === 'healthy') {
      console.log('   ✅ Backend is accessible and healthy');
      results.passed++;
      results.tests.push({ name: 'Backend Direct Access', status: 'PASS' });
    } else {
      throw new Error(`Backend not healthy: status=${response.status}, health=${response.json?.status}`);
    }
  } catch (error) {
    console.log(`   ❌ Backend direct access failed: ${error.message}`);
    results.failed++;
    results.tests.push({ name: 'Backend Direct Access', status: 'FAIL', error: error.message });
  }

  // Test 4: Frontend auth API
  try {
    console.log('4. Testing frontend auth API...');
    const response = await makeRequest(`${FRONTEND_URL}/api/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        username: 'demo@engarde.com',
        password: 'demo123'
      })
    });

    if (response.status === 200 && response.json?.access_token) {
      console.log('   ✅ Authentication API works (demo credentials)');
      results.passed++;
      results.tests.push({ name: 'Authentication API', status: 'PASS' });
    } else {
      throw new Error(`Auth failed: status=${response.status}, has_token=${!!response.json?.access_token}`);
    }
  } catch (error) {
    console.log(`   ❌ Authentication API failed: ${error.message}`);
    results.failed++;
    results.tests.push({ name: 'Authentication API', status: 'FAIL', error: error.message });
  }

  // Test 5: Frontend health API (proxy to backend)
  try {
    console.log('5. Testing frontend health API proxy...');
    const response = await makeRequest(`${FRONTEND_URL}/api/health`);
    if (response.status === 200 && response.json?.status) {
      console.log('   ✅ Frontend health API works (includes backend connectivity)');
      results.passed++;
      results.tests.push({ name: 'Health API Proxy', status: 'PASS' });
    } else {
      throw new Error(`Health API failed: status=${response.status}`);
    }
  } catch (error) {
    console.log(`   ❌ Frontend health API failed: ${error.message}`);
    results.failed++;
    results.tests.push({ name: 'Health API Proxy', status: 'FAIL', error: error.message });
  }

  // Test 6: API routing (campaigns endpoint)
  try {
    console.log('6. Testing API routing (campaigns)...');
    const response = await makeRequest(`${FRONTEND_URL}/api/campaigns`);
    // We expect authentication error (401 or 422), not 404
    if ([401, 422].includes(response.status) || (response.json?.detail && response.json.detail.includes('credential'))) {
      console.log('   ✅ API routing works (campaigns endpoint reachable)');
      results.passed++;
      results.tests.push({ name: 'API Routing', status: 'PASS' });
    } else {
      throw new Error(`Unexpected response: status=${response.status}, detail=${response.json?.detail}`);
    }
  } catch (error) {
    console.log(`   ❌ API routing failed: ${error.message}`);
    results.failed++;
    results.tests.push({ name: 'API Routing', status: 'FAIL', error: error.message });
  }

  // Summary
  console.log('\n=====================================');
  console.log('📊 Test Results Summary');
  console.log('=====================================');
  console.log(`✅ Passed: ${results.passed}`);
  console.log(`❌ Failed: ${results.failed}`);
  console.log(`📋 Total:  ${results.passed + results.failed}`);

  if (results.failed === 0) {
    console.log('\n🎉 All tests passed! Frontend is properly configured.');
  } else {
    console.log('\n⚠️  Some tests failed. Check the configuration.');
  }

  return results;
}

// Run tests if this script is executed directly
if (require.main === module) {
  runTests().catch(console.error);
}

module.exports = { runTests };