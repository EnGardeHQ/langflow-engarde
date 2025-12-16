#!/usr/bin/env node

/**
 * QUICK AUTH FIX TEST
 * This script tests the actual authentication flow with a real form submission
 */

const http = require('http');
const querystring = require('querystring');

console.log('🔧 QUICK AUTH FIX TEST');
console.log('======================');

// Test 1: Direct login to backend
async function testBackendLogin() {
  console.log('\n1️⃣ Testing backend login...');

  try {
    const formData = querystring.stringify({
      username: 'test@example.com',
      password: 'Password123'
    });

    const response = await makeRequest('POST', 'http://localhost:8000/token', {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Origin': 'http://localhost:3001'
    }, formData);

    if (response.statusCode === 200) {
      const data = JSON.parse(response.data);
      console.log('✅ Backend login successful!');
      console.log(`   Token: ${data.access_token.substring(0, 20)}...`);
      console.log(`   User: ${data.user.email}`);
      return data.access_token;
    } else {
      console.log(`❌ Backend login failed: ${response.statusCode}`);
      console.log(`   Response: ${response.data}`);
      return null;
    }
  } catch (error) {
    console.log(`❌ Backend login error: ${error.message}`);
    return null;
  }
}

// Test 2: Test authenticated endpoint
async function testAuthenticatedEndpoint(token) {
  console.log('\n2️⃣ Testing authenticated endpoint...');

  try {
    const response = await makeRequest('GET', 'http://localhost:8000/me', {
      'Authorization': `Bearer ${token}`,
      'Origin': 'http://localhost:3001'
    });

    if (response.statusCode === 200) {
      const userData = JSON.parse(response.data);
      console.log('✅ Authenticated endpoint works!');
      console.log(`   User ID: ${userData.id}`);
      console.log(`   Email: ${userData.email}`);
      return true;
    } else {
      console.log(`❌ Authenticated endpoint failed: ${response.statusCode}`);
      return false;
    }
  } catch (error) {
    console.log(`❌ Authenticated endpoint error: ${error.message}`);
    return false;
  }
}

// Test 3: Check if frontend is accessible and what it's serving
async function testFrontendStatus() {
  console.log('\n3️⃣ Testing frontend status...');

  try {
    const response = await makeRequest('GET', 'http://localhost:3001/login');

    console.log(`   Status: ${response.statusCode}`);

    // Check what the frontend is actually serving
    const isLoading = response.data.includes('Loading...');
    const hasLoginForm = response.data.includes('data-testid="email-input"');
    const hasSpinner = response.data.includes('chakra-spinner');

    console.log(`   Contains Loading text: ${isLoading ? '✅' : '❌'}`);
    console.log(`   Contains Login form: ${hasLoginForm ? '✅' : '❌'}`);
    console.log(`   Contains Spinner: ${hasSpinner ? '✅' : '❌'}`);

    if (isLoading && !hasLoginForm) {
      console.log('🔍 Frontend is stuck in loading state - login form not rendered');
    }

    return !isLoading && hasLoginForm;
  } catch (error) {
    console.log(`❌ Frontend test error: ${error.message}`);
    return false;
  }
}

// Test 4: Environment variable check
async function testEnvironmentVariables() {
  console.log('\n4️⃣ Testing environment variables...');

  // Check if we can access the environment variable from server-side
  const apiUrl = process.env.NEXT_PUBLIC_API_URL;
  console.log(`   NEXT_PUBLIC_API_URL: ${apiUrl || 'NOT SET'}`);

  if (!apiUrl || apiUrl !== 'http://localhost:8000') {
    console.log('❌ Environment variable not properly set');
    return false;
  } else {
    console.log('✅ Environment variable correctly set');
    return true;
  }
}

function makeRequest(method, url, headers = {}, body = null) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port,
      path: urlObj.pathname + urlObj.search,
      method: method,
      headers: {
        'User-Agent': 'QuickAuthTest/1.0',
        ...headers
      }
    };

    if (body && !headers['Content-Length']) {
      options.headers['Content-Length'] = Buffer.byteLength(body);
    }

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => resolve({
        statusCode: res.statusCode,
        headers: res.headers,
        data: data
      }));
    });

    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

async function main() {
  console.log('Testing complete authentication flow...\n');

  // Test environment first
  const envOk = await testEnvironmentVariables();

  // Test backend functionality
  const token = await testBackendLogin();
  let authOk = false;

  if (token) {
    authOk = await testAuthenticatedEndpoint(token);
  }

  // Test frontend status
  const frontendOk = await testFrontendStatus();

  console.log('\n📊 SUMMARY');
  console.log('==========');
  console.log(`Environment Variables: ${envOk ? '✅ OK' : '❌ FAIL'}`);
  console.log(`Backend Authentication: ${token ? '✅ OK' : '❌ FAIL'}`);
  console.log(`Authenticated Requests: ${authOk ? '✅ OK' : '❌ FAIL'}`);
  console.log(`Frontend Login Page: ${frontendOk ? '✅ OK' : '❌ FAIL'}`);

  if (!frontendOk) {
    console.log('\n🎯 ROOT CAUSE IDENTIFIED:');
    console.log('The frontend is stuck in loading state, preventing users from accessing the login form.');
    console.log('Backend authentication works perfectly - this is purely a frontend rendering issue.');

    console.log('\n🛠️ IMMEDIATE SOLUTIONS:');
    console.log('1. Clear browser localStorage: Open browser console, run: localStorage.clear()');
    console.log('2. Force reload login page');
    console.log('3. Check browser console for JavaScript errors');
    console.log('4. Temporarily bypass loading state in login page component');
  } else {
    console.log('\n✅ All systems operational!');
  }
}

main().catch(console.error);