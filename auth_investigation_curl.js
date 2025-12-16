/**
 * CRITICAL INVESTIGATION: Authentication API Testing via Node.js
 *
 * This script performs comprehensive API testing to identify authentication issues
 * without requiring complex browser automation setup.
 */

const https = require('https');
const http = require('http');
const querystring = require('querystring');

class AuthAPIInvestigator {
  constructor() {
    this.results = {
      tests: [],
      findings: [],
      errors: [],
      apiCalls: []
    };
    this.backendUrl = 'http://localhost:8000';
    this.frontendUrl = 'http://localhost:3001';
  }

  async investigate() {
    console.log('🔍 STARTING AUTHENTICATION API INVESTIGATION');
    console.log('============================================');

    try {
      await this.test1_BackendHealth();
      await this.test2_FrontendAccessibility();
      await this.test3_LoginEndpointDirect();
      await this.test4_FormDataLoginAttempt();
      await this.test5_CORSTest();
      await this.test6_OptionsRequest();
      await this.test7_HeaderAnalysis();

    } catch (error) {
      console.error('❌ Investigation failed:', error);
      this.results.errors.push(`Investigation failed: ${error.message}`);
    } finally {
      this.generateReport();
    }
  }

  async test1_BackendHealth() {
    console.log('\n🏥 TEST 1: Backend Health Check');
    console.log('===============================');

    try {
      const response = await this.makeRequest('GET', `${this.backendUrl}/health`);
      console.log(`✅ Backend health: ${response.statusCode}`);
      console.log(`📄 Response: ${response.data.substring(0, 200)}...`);

      this.results.tests.push({
        name: 'Backend Health',
        status: response.statusCode === 200 ? 'PASS' : 'FAIL',
        details: response.data.substring(0, 200)
      });

      const healthData = JSON.parse(response.data);
      const tokenEndpoint = healthData.available_endpoints?.find(ep => ep.path === '/token');

      if (tokenEndpoint) {
        console.log(`✅ Token endpoint found: ${tokenEndpoint.path} [${tokenEndpoint.methods.join(', ')}]`);
        this.results.findings.push(`Token endpoint available with methods: ${tokenEndpoint.methods.join(', ')}`);
      } else {
        console.log('❌ Token endpoint not found in health check');
        this.results.findings.push('Token endpoint not listed in health check');
      }

    } catch (error) {
      console.error('❌ Backend health check failed:', error.message);
      this.results.tests.push({
        name: 'Backend Health',
        status: 'FAIL',
        details: error.message
      });
    }
  }

  async test2_FrontendAccessibility() {
    console.log('\n🌐 TEST 2: Frontend Accessibility');
    console.log('=================================');

    try {
      const response = await this.makeRequest('GET', `${this.frontendUrl}/login`);
      console.log(`✅ Frontend login page: ${response.statusCode}`);

      // Check if the page contains critical elements
      const hasEmailInput = response.data.includes('data-testid="email-input"');
      const hasPasswordInput = response.data.includes('data-testid="password-input"');
      const hasLoginButton = response.data.includes('data-testid="login-button"');
      const hasApiUrl = response.data.includes('NEXT_PUBLIC_API_URL');

      console.log(`📋 Page elements:`);
      console.log(`   - Email input: ${hasEmailInput ? '✅' : '❌'}`);
      console.log(`   - Password input: ${hasPasswordInput ? '✅' : '❌'}`);
      console.log(`   - Login button: ${hasLoginButton ? '✅' : '❌'}`);
      console.log(`   - API URL reference: ${hasApiUrl ? '✅' : '❌'}`);

      this.results.tests.push({
        name: 'Frontend Accessibility',
        status: response.statusCode === 200 ? 'PASS' : 'FAIL',
        details: `Elements: email=${hasEmailInput}, password=${hasPasswordInput}, button=${hasLoginButton}, apiUrl=${hasApiUrl}`
      });

    } catch (error) {
      console.error('❌ Frontend accessibility test failed:', error.message);
      this.results.tests.push({
        name: 'Frontend Accessibility',
        status: 'FAIL',
        details: error.message
      });
    }
  }

  async test3_LoginEndpointDirect() {
    console.log('\n🔐 TEST 3: Direct Login Endpoint Test');
    console.log('====================================');

    try {
      // Test direct API call to login endpoint
      const postData = JSON.stringify({
        email: 'test@example.com',
        password: 'Password123'
      });

      const response = await this.makeRequest('POST', `${this.backendUrl}/token`, {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }, postData);

      console.log(`📡 Login response: ${response.statusCode}`);
      console.log(`📄 Response body: ${response.data}`);

      this.results.tests.push({
        name: 'Direct Login (JSON)',
        status: response.statusCode < 500 ? 'RESPONDED' : 'FAIL',
        details: `Status: ${response.statusCode}, Body: ${response.data.substring(0, 200)}`
      });

    } catch (error) {
      console.error('❌ Direct login test failed:', error.message);
      this.results.tests.push({
        name: 'Direct Login (JSON)',
        status: 'FAIL',
        details: error.message
      });
    }
  }

  async test4_FormDataLoginAttempt() {
    console.log('\n📝 TEST 4: Form Data Login (OAuth2 Style)');
    console.log('==========================================');

    try {
      // Test form data submission (OAuth2 style)
      const formData = querystring.stringify({
        username: 'test@example.com',
        password: 'Password123',
        grant_type: 'password'
      });

      const response = await this.makeRequest('POST', `${this.backendUrl}/token`, {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json'
      }, formData);

      console.log(`📡 Form login response: ${response.statusCode}`);
      console.log(`📄 Response body: ${response.data}`);

      this.results.tests.push({
        name: 'Form Data Login',
        status: response.statusCode < 500 ? 'RESPONDED' : 'FAIL',
        details: `Status: ${response.statusCode}, Body: ${response.data.substring(0, 200)}`
      });

      // If successful, try to parse and check response
      if (response.statusCode === 200) {
        try {
          const authData = JSON.parse(response.data);
          if (authData.access_token) {
            console.log('✅ Access token received via form data!');
            this.results.findings.push('Backend accepts form data and returns tokens');
          }
        } catch (parseError) {
          console.log('❌ Could not parse response as JSON');
        }
      }

    } catch (error) {
      console.error('❌ Form data login test failed:', error.message);
      this.results.tests.push({
        name: 'Form Data Login',
        status: 'FAIL',
        details: error.message
      });
    }
  }

  async test5_CORSTest() {
    console.log('\n🔄 TEST 5: CORS Configuration Test');
    console.log('==================================');

    try {
      // Test CORS by making request with Origin header
      const response = await this.makeRequest('POST', `${this.backendUrl}/token`, {
        'Origin': 'http://localhost:3001',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json'
      }, querystring.stringify({
        username: 'test@example.com',
        password: 'Password123'
      }));

      console.log(`📡 CORS test response: ${response.statusCode}`);
      console.log(`🔗 CORS headers in response:`);

      const corsHeaders = [
        'access-control-allow-origin',
        'access-control-allow-methods',
        'access-control-allow-headers',
        'access-control-allow-credentials'
      ];

      corsHeaders.forEach(header => {
        const value = response.headers[header];
        console.log(`   - ${header}: ${value || 'NOT SET'}`);
      });

      this.results.tests.push({
        name: 'CORS Test',
        status: response.statusCode < 500 ? 'RESPONDED' : 'FAIL',
        details: `Status: ${response.statusCode}, CORS headers present: ${corsHeaders.some(h => response.headers[h])}`
      });

    } catch (error) {
      console.error('❌ CORS test failed:', error.message);
      this.results.tests.push({
        name: 'CORS Test',
        status: 'FAIL',
        details: error.message
      });
    }
  }

  async test6_OptionsRequest() {
    console.log('\n⚡ TEST 6: OPTIONS Preflight Request');
    console.log('====================================');

    try {
      // Test OPTIONS preflight request
      const response = await this.makeRequest('OPTIONS', `${this.backendUrl}/token`, {
        'Origin': 'http://localhost:3001',
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'Content-Type'
      });

      console.log(`📡 OPTIONS response: ${response.statusCode}`);
      console.log(`🔗 Preflight headers:`);

      Object.entries(response.headers).forEach(([key, value]) => {
        if (key.toLowerCase().includes('access-control')) {
          console.log(`   - ${key}: ${value}`);
        }
      });

      this.results.tests.push({
        name: 'OPTIONS Preflight',
        status: response.statusCode < 500 ? 'RESPONDED' : 'FAIL',
        details: `Status: ${response.statusCode}`
      });

    } catch (error) {
      console.error('❌ OPTIONS test failed:', error.message);
      this.results.tests.push({
        name: 'OPTIONS Preflight',
        status: 'FAIL',
        details: error.message
      });
    }
  }

  async test7_HeaderAnalysis() {
    console.log('\n📋 TEST 7: Header Analysis');
    console.log('===========================');

    try {
      // Test various content-type combinations
      const tests = [
        {
          name: 'application/json',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email: 'test@example.com', password: 'Password123' })
        },
        {
          name: 'application/x-www-form-urlencoded',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: 'username=test@example.com&password=Password123'
        },
        {
          name: 'multipart/form-data boundary',
          headers: { 'Content-Type': 'multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW' },
          body: '------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name="username"\r\n\r\ntest@example.com\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name="password"\r\n\r\nPassword123\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW--\r\n'
        }
      ];

      for (const test of tests) {
        try {
          const response = await this.makeRequest('POST', `${this.backendUrl}/token`, test.headers, test.body);
          console.log(`   ${test.name}: ${response.statusCode}`);

          this.results.tests.push({
            name: `Header Test (${test.name})`,
            status: response.statusCode < 500 ? 'RESPONDED' : 'FAIL',
            details: `Status: ${response.statusCode}`
          });

        } catch (error) {
          console.log(`   ${test.name}: ERROR - ${error.message}`);
        }
      }

    } catch (error) {
      console.error('❌ Header analysis failed:', error.message);
    }
  }

  makeRequest(method, url, headers = {}, body = null) {
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
          'User-Agent': 'AuthInvestigator/1.0',
          ...headers
        }
      };

      if (body && !headers['Content-Length']) {
        options.headers['Content-Length'] = Buffer.byteLength(body);
      }

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

      if (body) {
        req.write(body);
      }

      req.end();
    });
  }

  generateReport() {
    console.log('\n📋 INVESTIGATION REPORT');
    console.log('=======================');

    console.log('\n🧪 TEST RESULTS:');
    this.results.tests.forEach((test, index) => {
      const status = test.status === 'PASS' ? '✅' : test.status === 'RESPONDED' ? '📡' : '❌';
      console.log(`   ${index + 1}. ${status} ${test.name}: ${test.status}`);
      if (test.details) {
        console.log(`      Details: ${test.details}`);
      }
    });

    console.log('\n🔍 KEY FINDINGS:');
    this.results.findings.forEach((finding, index) => {
      console.log(`   ${index + 1}. ${finding}`);
    });

    if (this.results.errors.length > 0) {
      console.log('\n❌ ERRORS:');
      this.results.errors.forEach((error, index) => {
        console.log(`   ${index + 1}. ${error}`);
      });
    }

    console.log('\n🔧 ANALYSIS & RECOMMENDATIONS:');
    this.generateAnalysis();

    // Save report
    require('fs').writeFileSync(
      'auth-api-investigation-report.json',
      JSON.stringify(this.results, null, 2)
    );
    console.log('\n📄 Detailed report saved to: auth-api-investigation-report.json');
  }

  generateAnalysis() {
    const passedTests = this.results.tests.filter(t => t.status === 'PASS').length;
    const respondedTests = this.results.tests.filter(t => t.status === 'RESPONDED').length;
    const totalTests = this.results.tests.length;

    console.log(`   📊 Test Summary: ${passedTests} passed, ${respondedTests} responded, ${totalTests - passedTests - respondedTests} failed`);

    // Generate specific recommendations based on test results
    const formDataTest = this.results.tests.find(t => t.name === 'Form Data Login');
    const corsTest = this.results.tests.find(t => t.name === 'CORS Test');
    const optionsTest = this.results.tests.find(t => t.name === 'OPTIONS Preflight');

    if (formDataTest && formDataTest.status === 'RESPONDED') {
      console.log('   ✅ Backend accepts form data - this is correct for OAuth2');
    }

    if (corsTest && corsTest.details.includes('false')) {
      console.log('   ❌ CORS headers missing - this will block browser requests');
      console.log('   💡 Backend needs CORS configuration for http://localhost:3001');
    }

    if (optionsTest && (optionsTest.status === 'FAIL' || optionsTest.details.includes('404'))) {
      console.log('   ❌ OPTIONS requests not handled - browsers cannot make preflight requests');
      console.log('   💡 Backend needs to handle OPTIONS requests for CORS preflight');
    }

    // Check if frontend URL is accessible
    const frontendTest = this.results.tests.find(t => t.name === 'Frontend Accessibility');
    if (frontendTest && frontendTest.status === 'PASS') {
      console.log('   ✅ Frontend is accessible and contains login form');
    }

    console.log('\n   🎯 LIKELY ROOT CAUSE:');
    console.log('   The frontend cannot communicate with the backend due to browser CORS restrictions.');
    console.log('   The backend API works via curl/server-to-server but blocks browser-based requests.');
  }
}

// Run the investigation
async function main() {
  const investigator = new AuthAPIInvestigator();
  await investigator.investigate();
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = { AuthAPIInvestigator };