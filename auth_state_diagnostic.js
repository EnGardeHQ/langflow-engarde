/**
 * AUTH STATE DIAGNOSTIC SCRIPT
 *
 * This script investigates why the login page is stuck in loading state
 */

const https = require('https');
const http = require('http');

class AuthStateDiagnostic {
  constructor() {
    this.results = [];
  }

  async investigate() {
    console.log('🔍 DIAGNOSING AUTH STATE ISSUE');
    console.log('===============================');

    try {
      // Test 1: Check if localStorage has any stuck tokens
      await this.checkLocalStorageIssue();

      // Test 2: Check if the API client is hanging
      await this.checkAPIClientHang();

      // Test 3: Check environment variables
      await this.checkEnvironmentVariables();

      // Test 4: Check if auth service is accessible
      await this.checkAuthServiceIssues();

    } catch (error) {
      console.error('❌ Diagnostic failed:', error);
    }

    this.generateReport();
  }

  async checkLocalStorageIssue() {
    console.log('\n📦 TEST 1: LocalStorage Token Check');
    console.log('====================================');

    // Since we can't access localStorage directly, we'll check the auth service logic
    console.log('✅ This test would check if corrupted tokens in localStorage');
    console.log('   are causing the auth service to hang or fail');
    console.log('   Recommendation: Clear browser localStorage for localhost:3001');

    this.results.push({
      test: 'LocalStorage Check',
      status: 'INFO',
      details: 'Check for corrupted tokens in browser localStorage'
    });
  }

  async checkAPIClientHang() {
    console.log('\n⏱️  TEST 2: API Client Hang Check');
    console.log('==================================');

    try {
      // Test if the /me endpoint hangs when called
      const startTime = Date.now();

      const meResponse = await Promise.race([
        this.makeRequest('GET', 'http://localhost:8000/me', {
          'Authorization': 'Bearer fake-token'
        }),
        new Promise((resolve) => setTimeout(() => resolve({ timeout: true }), 3000))
      ]);

      const endTime = Date.now();
      const duration = endTime - startTime;

      if (meResponse.timeout) {
        console.log('❌ /me endpoint timed out after 3 seconds');
        this.results.push({
          test: 'API Client Hang',
          status: 'FAIL',
          details: '/me endpoint hangs, causing auth initialization to freeze'
        });
      } else {
        console.log(`✅ /me endpoint responded in ${duration}ms with status ${meResponse.statusCode}`);
        this.results.push({
          test: 'API Client Hang',
          status: 'PASS',
          details: `/me endpoint responds quickly (${duration}ms)`
        });
      }

    } catch (error) {
      console.log(`⚠️ /me endpoint error: ${error.message}`);
      this.results.push({
        test: 'API Client Hang',
        status: 'ERROR',
        details: error.message
      });
    }
  }

  async checkEnvironmentVariables() {
    console.log('\n🔧 TEST 3: Environment Variables Check');
    console.log('======================================');

    try {
      // Check if the frontend properly serves environment variables
      const response = await this.makeRequest('GET', 'http://localhost:3001/login');

      // Look for signs of environment variable issues
      const hasNextPublicApiUrl = response.data.includes('NEXT_PUBLIC_API_URL');
      const hasLocalhost8000 = response.data.includes('localhost:8000');
      const hasProcessEnv = response.data.includes('process.env');

      console.log('🔍 Environment variable analysis:');
      console.log(`   - Contains NEXT_PUBLIC_API_URL reference: ${hasNextPublicApiUrl}`);
      console.log(`   - Contains localhost:8000 reference: ${hasLocalhost8000}`);
      console.log(`   - Contains process.env reference: ${hasProcessEnv}`);

      if (!hasLocalhost8000 && !hasNextPublicApiUrl) {
        console.log('❌ API URL may not be properly configured');
        this.results.push({
          test: 'Environment Variables',
          status: 'FAIL',
          details: 'API URL not found in frontend configuration'
        });
      } else {
        console.log('✅ Environment variables appear to be configured');
        this.results.push({
          test: 'Environment Variables',
          status: 'PASS',
          details: 'API URL configuration found'
        });
      }

    } catch (error) {
      console.log(`❌ Environment check failed: ${error.message}`);
      this.results.push({
        test: 'Environment Variables',
        status: 'ERROR',
        details: error.message
      });
    }
  }

  async checkAuthServiceIssues() {
    console.log('\n🔐 TEST 4: Auth Service Access Check');
    console.log('====================================');

    try {
      // Check key auth endpoints that could be causing hangs
      const endpoints = [
        { path: '/me', name: 'Current User' },
        { path: '/auth/refresh', name: 'Token Refresh' },
        { path: '/health', name: 'Health Check' }
      ];

      for (const endpoint of endpoints) {
        try {
          const startTime = Date.now();
          const response = await Promise.race([
            this.makeRequest('GET', `http://localhost:8000${endpoint.path}`),
            new Promise((resolve) => setTimeout(() => resolve({ timeout: true }), 2000))
          ]);
          const duration = Date.now() - startTime;

          if (response.timeout) {
            console.log(`❌ ${endpoint.name} (${endpoint.path}): TIMEOUT (>2s)`);
          } else {
            console.log(`✅ ${endpoint.name} (${endpoint.path}): ${response.statusCode} (${duration}ms)`);
          }

        } catch (error) {
          console.log(`⚠️ ${endpoint.name} (${endpoint.path}): ERROR - ${error.message}`);
        }
      }

      this.results.push({
        test: 'Auth Service Access',
        status: 'CHECKED',
        details: 'See individual endpoint results above'
      });

    } catch (error) {
      console.log(`❌ Auth service check failed: ${error.message}`);
      this.results.push({
        test: 'Auth Service Access',
        status: 'ERROR',
        details: error.message
      });
    }
  }

  makeRequest(method, url, headers = {}) {
    return new Promise((resolve, reject) => {
      const urlObj = new URL(url);
      const isHttps = urlObj.protocol === 'https:';
      const client = isHttps ? https : http;

      const options = {
        hostname: urlObj.hostname,
        port: urlObj.port,
        path: urlObj.pathname + urlObj.search,
        method: method,
        headers: {
          'User-Agent': 'AuthStateDiagnostic/1.0',
          ...headers
        }
      };

      const req = client.request(options, (res) => {
        let data = '';

        res.on('data', (chunk) => {
          data += chunk;
        });

        res.on('end', () => {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            data: data
          });
        });
      });

      req.on('error', (error) => {
        reject(error);
      });

      req.end();
    });
  }

  generateReport() {
    console.log('\n📋 DIAGNOSTIC REPORT');
    console.log('====================');

    console.log('\n🧪 TEST RESULTS:');
    this.results.forEach((result, index) => {
      const statusIcon = result.status === 'PASS' ? '✅' :
                        result.status === 'FAIL' ? '❌' :
                        result.status === 'ERROR' ? '💥' : '📋';
      console.log(`   ${index + 1}. ${statusIcon} ${result.test}: ${result.status}`);
      console.log(`      ${result.details}`);
    });

    console.log('\n🎯 MOST LIKELY ROOT CAUSES:');
    console.log('   1. 🔄 Auth Context is stuck in initializing state');
    console.log('   2. 📦 Corrupted tokens in browser localStorage');
    console.log('   3. ⏱️  Auth service getCurrentUser() call is hanging');
    console.log('   4. 🔧 Environment variable configuration issue');

    console.log('\n🛠️  IMMEDIATE FIXES TO TRY:');
    console.log('   1. Clear browser localStorage: localStorage.clear()');
    console.log('   2. Check if auth initialization is dispatching INIT_START');
    console.log('   3. Add timeout protection to getCurrentUser() calls');
    console.log('   4. Verify NEXT_PUBLIC_API_URL is properly set');

    console.log('\n🔧 DETAILED INVESTIGATION NEEDED:');
    console.log('   - Browser developer tools console for JavaScript errors');
    console.log('   - Network tab to see if API calls are being made');
    console.log('   - React DevTools to inspect AuthContext state');
    console.log('   - Check if auth reducer is receiving unexpected actions');
  }
}

// Run the diagnostic
async function main() {
  const diagnostic = new AuthStateDiagnostic();
  await diagnostic.investigate();
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = { AuthStateDiagnostic };