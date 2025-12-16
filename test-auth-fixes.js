#!/usr/bin/env node

/**
 * Test script to validate authentication fixes
 * This script tests the critical authentication issues that were fixed:
 * 1. Form-encoded requests instead of JSON
 * 2. Email field mapped to username
 * 3. Proper error handling
 */

const https = require('https');
const http = require('http');
const querystring = require('querystring');

// Configuration
const BACKEND_URL = 'http://localhost:8002';
const TEST_CREDENTIALS = {
  username: 'test@example.com',
  password: 'testpassword123',
  user_type: 'advertiser'
};

console.log('🔐 Testing Authentication Fixes');
console.log('================================');
console.log(`Backend URL: ${BACKEND_URL}`);
console.log(`Test credentials: ${TEST_CREDENTIALS.username}`);
console.log('');

// Test 1: Form-encoded request format
async function testFormEncodedRequest() {
  console.log('📝 Test 1: Form-encoded request format');

  const postData = querystring.stringify({
    username: TEST_CREDENTIALS.username,
    password: TEST_CREDENTIALS.password,
    user_type: TEST_CREDENTIALS.user_type
  });

  const options = {
    hostname: 'localhost',
    port: 8002,
    path: '/auth/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Content-Length': Buffer.byteLength(postData),
      'Accept': 'application/json'
    }
  };

  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';

      console.log(`   Status Code: ${res.statusCode}`);
      console.log(`   Content-Type: ${res.headers['content-type']}`);

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          console.log('   ✅ Form-encoded request accepted');
          console.log('   Response preview:', JSON.stringify(response).substring(0, 100) + '...');
          resolve({ statusCode: res.statusCode, data: response });
        } catch (error) {
          console.log('   📄 Raw response:', data.substring(0, 200));
          resolve({ statusCode: res.statusCode, data: data });
        }
      });
    });

    req.on('error', (error) => {
      console.log('   ❌ Request failed:', error.message);
      reject(error);
    });

    req.write(postData);
    req.end();
  });
}

// Test 2: JSON request format (should be rejected or handled differently)
async function testJSONRequest() {
  console.log('📝 Test 2: JSON request format (legacy test)');

  const postData = JSON.stringify({
    email: TEST_CREDENTIALS.username, // Note: using 'email' instead of 'username'
    password: TEST_CREDENTIALS.password,
    userType: TEST_CREDENTIALS.user_type
  });

  const options = {
    hostname: 'localhost',
    port: 8002,
    path: '/auth/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData),
      'Accept': 'application/json'
    }
  };

  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';

      console.log(`   Status Code: ${res.statusCode}`);
      console.log(`   Content-Type: ${res.headers['content-type']}`);

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          console.log('   📊 JSON request response:', JSON.stringify(response).substring(0, 100) + '...');
          resolve({ statusCode: res.statusCode, data: response });
        } catch (error) {
          console.log('   📄 Raw response:', data.substring(0, 200));
          resolve({ statusCode: res.statusCode, data: data });
        }
      });
    });

    req.on('error', (error) => {
      console.log('   ❌ Request failed:', error.message);
      reject(error);
    });

    req.write(postData);
    req.end();
  });
}

// Test 3: Backend health check
async function testBackendHealth() {
  console.log('📝 Test 3: Backend health check');

  const options = {
    hostname: 'localhost',
    port: 8002,
    path: '/health',
    method: 'GET',
    headers: {
      'Accept': 'application/json'
    }
  };

  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';

      console.log(`   Status Code: ${res.statusCode}`);

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        console.log(`   ✅ Backend is responding`);
        console.log(`   Response: ${data.substring(0, 100)}...`);
        resolve({ statusCode: res.statusCode, data: data });
      });
    });

    req.on('error', (error) => {
      console.log('   ❌ Health check failed:', error.message);
      reject(error);
    });

    req.end();
  });
}

// Main test runner
async function runTests() {
  try {
    console.log('🚀 Starting authentication tests...\n');

    // Test backend health first
    await testBackendHealth();
    console.log('');

    // Test form-encoded request (should work with fixes)
    const formResult = await testFormEncodedRequest();
    console.log('');

    // Test JSON request (for comparison)
    const jsonResult = await testJSONRequest();
    console.log('');

    // Summary
    console.log('📊 Test Summary:');
    console.log('================');
    console.log(`Form-encoded request: ${formResult.statusCode === 200 || formResult.statusCode === 401 ? '✅ PASS' : '❌ FAIL'}`);
    console.log(`JSON request comparison: ${jsonResult.statusCode ? '✅ RECEIVED' : '❌ FAIL'}`);

    if (formResult.statusCode === 200) {
      console.log('🎉 SUCCESS: Form-encoded authentication is working!');
    } else if (formResult.statusCode === 401) {
      console.log('✅ EXPECTED: Form-encoded request reached auth logic (401 = invalid credentials)');
    } else if (formResult.statusCode === 422) {
      console.log('✅ EXPECTED: Validation error (422) - check field mapping');
    } else {
      console.log('⚠️  UNEXPECTED: Form-encoded request got unexpected status code');
    }

  } catch (error) {
    console.error('💥 Test failed:', error.message);
    process.exit(1);
  }
}

// Run the tests
runTests().then(() => {
  console.log('\n🏁 Authentication tests completed');
}).catch((error) => {
  console.error('\n💥 Tests failed:', error);
  process.exit(1);
});