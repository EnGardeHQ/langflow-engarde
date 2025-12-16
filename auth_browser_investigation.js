/**
 * CRITICAL INVESTIGATION: Frontend-Backend Authentication Integration Failure
 *
 * This test performs REAL browser testing to identify why login fails in actual browsers
 * despite backend API working via curl and frontend loading properly.
 */

const { chromium } = require('playwright');

class AuthenticationInvestigator {
  constructor() {
    this.results = {
      networkRequests: [],
      errors: [],
      consoleMessages: [],
      screenshots: [],
      findings: [],
      apiCalls: []
    };
  }

  async investigate() {
    console.log('🔍 STARTING CRITICAL AUTHENTICATION INVESTIGATION');
    console.log('==================================================');

    const browser = await chromium.launch({
      headless: false, // Show browser for visual debugging
      slowMo: 1000 // Slow down for observation
    });

    const context = await browser.newContext({
      recordVideo: { dir: 'investigation-videos/' }
    });

    const page = await context.newPage();

    // Enable request/response logging
    page.on('request', this.logRequest.bind(this));
    page.on('response', this.logResponse.bind(this));
    page.on('console', this.logConsole.bind(this));
    page.on('pageerror', this.logPageError.bind(this));

    try {
      await this.step1_NavigateToLoginPage(page);
      await this.step2_InspectPageLoad(page);
      await this.step3_TestFormFunctionality(page);
      await this.step4_AttemptLogin(page);
      await this.step5_AnalyzeFailure(page);

    } catch (error) {
      this.results.errors.push(`Investigation failed: ${error.message}`);
      console.error('❌ Investigation failed:', error);
    } finally {
      await browser.close();
      this.generateReport();
    }
  }

  async step1_NavigateToLoginPage(page) {
    console.log('\n📍 STEP 1: Navigate to Login Page');
    console.log('=================================');

    try {
      await page.goto('http://localhost:3001/login', {
        waitUntil: 'domcontentloaded',
        timeout: 30000
      });

      await page.screenshot({ path: 'investigation-1-login-page.png' });
      this.results.screenshots.push('investigation-1-login-page.png');

      const title = await page.title();
      console.log(`✅ Page loaded successfully. Title: "${title}"`);
      this.results.findings.push(`Login page loaded with title: "${title}"`);

    } catch (error) {
      console.error('❌ Failed to load login page:', error.message);
      this.results.errors.push(`Failed to load login page: ${error.message}`);
      throw error;
    }
  }

  async step2_InspectPageLoad(page) {
    console.log('\n🔍 STEP 2: Inspect Page Elements and Configuration');
    console.log('=================================================');

    // Check for critical elements
    const emailInput = await page.locator('[data-testid="email-input"]').count();
    const passwordInput = await page.locator('[data-testid="password-input"]').count();
    const loginButton = await page.locator('[data-testid="login-button"]').count();

    console.log(`📋 Form elements found:`);
    console.log(`   - Email input: ${emailInput}`);
    console.log(`   - Password input: ${passwordInput}`);
    console.log(`   - Login button: ${loginButton}`);

    this.results.findings.push(`Form elements: email=${emailInput}, password=${passwordInput}, button=${loginButton}`);

    // Check for environment variables in the client
    const apiUrl = await page.evaluate(() => {
      return {
        processEnv: window.process?.env?.NEXT_PUBLIC_API_URL || 'not found',
        windowLocation: window.location.href,
        userAgent: navigator.userAgent
      };
    });

    console.log(`🔧 Environment check:`);
    console.log(`   - API URL: ${apiUrl.processEnv}`);
    console.log(`   - Current URL: ${apiUrl.windowLocation}`);

    this.results.findings.push(`API URL configured as: ${apiUrl.processEnv}`);
  }

  async step3_TestFormFunctionality(page) {
    console.log('\n✋ STEP 3: Test Form Functionality');
    console.log('==================================');

    try {
      // Fill in test credentials
      await page.fill('[data-testid="email-input"]', 'test@example.com');
      await page.fill('[data-testid="password-input"]', 'Password123');

      await page.screenshot({ path: 'investigation-2-form-filled.png' });
      this.results.screenshots.push('investigation-2-form-filled.png');

      console.log('✅ Successfully filled form with test credentials');
      this.results.findings.push('Form can be filled with test credentials');

    } catch (error) {
      console.error('❌ Failed to fill form:', error.message);
      this.results.errors.push(`Failed to fill form: ${error.message}`);
    }
  }

  async step4_AttemptLogin(page) {
    console.log('\n🚀 STEP 4: Attempt Login and Monitor Network');
    console.log('=============================================');

    // Clear previous network logs
    this.results.networkRequests = [];
    this.results.apiCalls = [];

    try {
      // Click login button and wait for network activity
      const loginPromise = page.click('[data-testid="login-button"]');

      // Wait for potential API call
      await Promise.race([
        page.waitForResponse(response =>
          response.url().includes('/token') ||
          response.url().includes('/login') ||
          response.url().includes('/auth')
        ).catch(() => null),
        page.waitForTimeout(5000) // Wait max 5 seconds
      ]);

      await loginPromise;

      // Take screenshot after login attempt
      await page.screenshot({ path: 'investigation-3-after-login-attempt.png' });
      this.results.screenshots.push('investigation-3-after-login-attempt.png');

      console.log('✅ Login button clicked, analyzing results...');

    } catch (error) {
      console.error('❌ Login attempt failed:', error.message);
      this.results.errors.push(`Login attempt failed: ${error.message}`);
    }
  }

  async step5_AnalyzeFailure(page) {
    console.log('\n🔬 STEP 5: Analyze Failure Points');
    console.log('=================================');

    // Check for error messages
    const errorMessage = await page.locator('[data-testid="error-message"]').textContent().catch(() => null);
    if (errorMessage) {
      console.log(`❌ Error message displayed: "${errorMessage}"`);
      this.results.findings.push(`Error message: "${errorMessage}"`);
    }

    // Check current URL (did we redirect?)
    const currentUrl = page.url();
    console.log(`📍 Current URL after login attempt: ${currentUrl}`);
    this.results.findings.push(`URL after login: ${currentUrl}`);

    // Check local storage for tokens
    const localStorage = await page.evaluate(() => {
      return {
        engardeTokens: localStorage.getItem('engarde_tokens'),
        engardeUser: localStorage.getItem('engarde_user'),
        allKeys: Object.keys(localStorage)
      };
    });

    console.log(`💾 Local storage check:`);
    console.log(`   - Tokens: ${localStorage.engardeTokens ? 'Found' : 'Not found'}`);
    console.log(`   - User: ${localStorage.engardeUser ? 'Found' : 'Not found'}`);
    console.log(`   - All keys: ${localStorage.allKeys.join(', ')}`);

    this.results.findings.push(`Local storage - Tokens: ${!!localStorage.engardeTokens}, User: ${!!localStorage.engardeUser}`);

    // Analyze network requests
    this.analyzeNetworkRequests();
  }

  logRequest(request) {
    const url = request.url();
    const method = request.method();

    // Focus on API requests
    if (url.includes('localhost:8000') || url.includes('/token') || url.includes('/auth')) {
      console.log(`🌐 REQUEST: ${method} ${url}`);

      const requestData = {
        url,
        method,
        headers: request.headers(),
        timestamp: new Date().toISOString()
      };

      this.results.networkRequests.push(requestData);
      this.results.apiCalls.push(requestData);
    }
  }

  logResponse(response) {
    const url = response.url();
    const status = response.status();

    // Focus on API responses
    if (url.includes('localhost:8000') || url.includes('/token') || url.includes('/auth')) {
      console.log(`📡 RESPONSE: ${status} ${url}`);

      // Try to get response body for API calls
      response.text().then(body => {
        console.log(`📄 Response body: ${body.substring(0, 200)}${body.length > 200 ? '...' : ''}`);

        this.results.apiCalls.push({
          url,
          status,
          body: body.substring(0, 500),
          headers: response.headers(),
          timestamp: new Date().toISOString()
        });
      }).catch(() => {
        console.log(`📄 Response body: [Unable to read]`);
      });
    }
  }

  logConsole(message) {
    const text = message.text();
    const type = message.type();

    console.log(`🖥️  CONSOLE [${type}]: ${text}`);

    this.results.consoleMessages.push({
      type,
      text,
      timestamp: new Date().toISOString()
    });
  }

  logPageError(error) {
    console.error(`💥 PAGE ERROR: ${error.message}`);
    this.results.errors.push(`Page error: ${error.message}`);
  }

  analyzeNetworkRequests() {
    console.log('\n📊 NETWORK ANALYSIS');
    console.log('===================');

    const apiRequests = this.results.apiCalls;

    if (apiRequests.length === 0) {
      console.log('❌ CRITICAL: No API requests were made to the backend!');
      this.results.findings.push('CRITICAL: No API requests to backend detected');
      return;
    }

    console.log(`✅ Found ${apiRequests.length} API request(s):`);

    apiRequests.forEach((req, index) => {
      console.log(`\n   Request ${index + 1}:`);
      console.log(`   - URL: ${req.url}`);
      console.log(`   - Method: ${req.method}`);
      console.log(`   - Status: ${req.status || 'No response'}`);
      if (req.body) {
        console.log(`   - Response: ${req.body.substring(0, 100)}...`);
      }
    });
  }

  generateReport() {
    console.log('\n📋 INVESTIGATION REPORT');
    console.log('=======================');

    console.log('\n🔍 KEY FINDINGS:');
    this.results.findings.forEach((finding, index) => {
      console.log(`   ${index + 1}. ${finding}`);
    });

    if (this.results.errors.length > 0) {
      console.log('\n❌ ERRORS ENCOUNTERED:');
      this.results.errors.forEach((error, index) => {
        console.log(`   ${index + 1}. ${error}`);
      });
    }

    console.log('\n📸 SCREENSHOTS CAPTURED:');
    this.results.screenshots.forEach(screenshot => {
      console.log(`   - ${screenshot}`);
    });

    console.log('\n🔧 RECOMMENDATIONS:');
    this.generateRecommendations();

    // Save detailed report to file
    require('fs').writeFileSync(
      'investigation-report.json',
      JSON.stringify(this.results, null, 2)
    );

    console.log('\n📄 Detailed report saved to: investigation-report.json');
  }

  generateRecommendations() {
    const recommendations = [];

    // Analyze findings to generate specific recommendations
    if (this.results.apiCalls.length === 0) {
      recommendations.push('Frontend is not making API calls to backend - check API client configuration');
      recommendations.push('Verify NEXT_PUBLIC_API_URL environment variable in frontend');
      recommendations.push('Check if auth service is properly initialized');
    }

    if (this.results.findings.some(f => f.includes('API URL configured as: not found'))) {
      recommendations.push('Environment variable NEXT_PUBLIC_API_URL is not properly set');
    }

    if (this.results.errors.some(e => e.includes('CORS'))) {
      recommendations.push('Backend CORS configuration needs to allow frontend origin');
    }

    if (this.results.consoleMessages.some(m => m.type === 'error')) {
      recommendations.push('Check console errors for JavaScript issues preventing API calls');
    }

    if (recommendations.length === 0) {
      recommendations.push('No obvious issues detected - may need deeper investigation');
    }

    recommendations.forEach((rec, index) => {
      console.log(`   ${index + 1}. ${rec}`);
    });
  }
}

// Run the investigation
async function main() {
  const investigator = new AuthenticationInvestigator();
  await investigator.investigate();
}

// Handle unhandled rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

if (require.main === module) {
  main().catch(console.error);
}

module.exports = { AuthenticationInvestigator };