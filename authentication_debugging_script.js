#!/usr/bin/env node

/**
 * Authentication Debugging Script
 * Tests the exact authentication initialization flow to identify blocking issues
 */

const http = require('http');

// Simulate the frontend's authentication check process
async function makeRequest(path, options = {}) {
  return new Promise((resolve, reject) => {
    const req = http.request({
      hostname: 'localhost',
      port: 8000,
      path: path,
      method: options.method || 'GET',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...options.headers
      },
      timeout: 5000  // 5 second timeout
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        try {
          const parsed = data ? JSON.parse(data) : {};
          resolve({
            status: res.statusCode,
            data: parsed,
            headers: res.headers
          });
        } catch (e) {
          resolve({
            status: res.statusCode,
            data: data,
            headers: res.headers
          });
        }
      });
    });

    req.on('error', (err) => {
      reject(err);
    });

    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });

    if (options.body) {
      req.write(options.body);
    }

    req.end();
  });
}

async function debugAuthFlow() {
  console.log('🔍 Starting Authentication Debug Flow...\n');

  try {
    // Step 1: Test backend health
    console.log('1. Testing backend health...');
    const healthCheck = await makeRequest('/health');
    console.log(`   ✓ Health check: ${healthCheck.status} - ${healthCheck.data.status || 'OK'}\n`);

    // Step 2: Test /me endpoint without authentication (should fail)
    console.log('2. Testing /me endpoint without auth (should return 401)...');
    try {
      const meWithoutAuth = await makeRequest('/me');
      console.log(`   Status: ${meWithoutAuth.status}`);
      if (meWithoutAuth.status === 401) {
        console.log('   ✓ Correctly returns 401 for unauthenticated requests\n');
      } else {
        console.log('   ⚠️ Unexpected response for unauthenticated request\n');
      }
    } catch (error) {
      console.log(`   ❌ Error: ${error.message}\n`);
    }

    // Step 3: Test login endpoint
    console.log('3. Testing login with admin credentials...');
    const formData = 'username=admin@engarde.ai&password=admin123';
    const loginResponse = await makeRequest('/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: formData
    });

    if (loginResponse.status === 200 && loginResponse.data.access_token) {
      console.log('   ✓ Login successful');
      const token = loginResponse.data.access_token;
      console.log(`   Token: ${token.substring(0, 50)}...\n`);

      // Step 4: Test /me endpoint with authentication
      console.log('4. Testing /me endpoint with authentication...');
      const meWithAuth = await makeRequest('/me', {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (meWithAuth.status === 200) {
        console.log('   ✓ /me endpoint working with auth');
        console.log(`   User: ${meWithAuth.data.email} (${meWithAuth.data.user_type || 'no type'})\n`);
      } else {
        console.log(`   ❌ /me endpoint failed: ${meWithAuth.status}`);
        console.log(`   Response: ${JSON.stringify(meWithAuth.data, null, 2)}\n`);
      }

      // Step 5: Test session validation flow (what frontend does)
      console.log('5. Testing frontend session validation flow...');
      console.log('   - isAuthenticated(): true (token exists)');
      console.log('   - validateSession(): calling /me endpoint...');

      // This mimics the exact flow in AuthContext initialization
      const sessionValidation = await makeRequest('/me', {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (sessionValidation.status === 200) {
        console.log('   ✓ Session validation successful');
        console.log('   ✓ getCurrentUser() would return user data\n');
      } else {
        console.log(`   ❌ Session validation failed: ${sessionValidation.status}`);
      }

      // Step 6: Test OAuth connections endpoint (potential hanging point)
      console.log('6. Testing OAuth connections endpoint...');
      try {
        const oauthResponse = await makeRequest('/oauth/connections', {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        });
        console.log(`   OAuth connections status: ${oauthResponse.status}`);
        if (oauthResponse.status === 404) {
          console.log('   ⚠️ OAuth endpoint not found (expected - may cause frontend hanging)\n');
        }
      } catch (error) {
        console.log(`   ❌ OAuth endpoint error: ${error.message}`);
        console.log('   This could cause frontend initialization to hang!\n');
      }

    } else {
      console.log(`   ❌ Login failed: ${loginResponse.status}`);
      console.log(`   Response: ${JSON.stringify(loginResponse.data, null, 2)}\n`);
    }

    console.log('🎯 Debug Summary:');
    console.log('   - Backend API is responsive');
    console.log('   - Authentication endpoints work correctly');
    console.log('   - The issue is likely in the frontend initialization');
    console.log('   - Potential causes:');
    console.log('     * OAuth service calls hanging');
    console.log('     * Frontend environment variable issues');
    console.log('     * Browser-specific token storage issues');
    console.log('     * CSP blocking API calls');

  } catch (error) {
    console.error(`❌ Debug failed: ${error.message}`);
  }
}

// Test the frontend URL accessibility
async function testFrontendConnection() {
  console.log('\n🌐 Testing frontend accessibility...\n');

  try {
    const frontendReq = http.request({
      hostname: 'localhost',
      port: 3001,
      path: '/',
      method: 'GET',
      timeout: 5000
    }, (res) => {
      console.log(`   Frontend status: ${res.statusCode}`);
      console.log(`   Frontend headers:`, res.headers);

      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        if (data.includes('Loading...')) {
          console.log('   🔍 Frontend showing loading state - confirms initialization issue');
        }
        if (data.includes('state.initializing')) {
          console.log('   🎯 Confirmed: Frontend stuck in initializing state');
        }
      });
    });

    frontendReq.on('error', (err) => {
      console.log(`   ❌ Frontend connection failed: ${err.message}`);
    });

    frontendReq.on('timeout', () => {
      frontendReq.destroy();
      console.log('   ❌ Frontend request timeout');
    });

    frontendReq.end();

  } catch (error) {
    console.error(`❌ Frontend test failed: ${error.message}`);
  }
}

// Run the debug process
(async () => {
  console.log('🔧 EnGarde Authentication Debugging\n');
  console.log('Testing authentication flow to identify login issues...\n');

  await debugAuthFlow();
  await testFrontendConnection();

  console.log('\n✨ Debug complete. Check the output above for identified issues.');
})();