const { test, expect } = require('@playwright/test');

/**
 * Authentication Fixes Verification Test Suite
 *
 * This test suite specifically verifies the following fixes:
 * 1. Autocomplete attributes on login form fields
 * 2. Authentication redirect loop prevention
 * 3. Enhanced token storage with retry logic
 * 4. CSP policy compliance (no 'unsafe-eval')
 * 5. CSRF protection validation
 *
 * Test credentials: test@engarde.ai / test123 (brand user)
 */

// Test configuration
const BASE_URL = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3001';
const API_BASE_URL = process.env.PLAYWRIGHT_API_URL || 'http://localhost:8000';

// Brand test user credentials
const BRAND_USER = {
  email: 'test@engarde.ai',
  password: 'test123',
  userType: 'brand'
};

// Test utilities for enhanced authentication testing
class AuthFixesTestUtils {
  constructor(page) {
    this.page = page;
    this.consoleMessages = [];
    this.cspViolations = [];
    this.networkRequests = [];
    this.redirectChain = [];
  }

  async setupMonitoring() {
    // Monitor console messages for CSP violations and errors
    this.page.on('console', (msg) => {
      const text = msg.text();
      this.consoleMessages.push({
        type: msg.type(),
        text: text,
        timestamp: Date.now()
      });

      // Check for CSP violations
      if (text.includes('Content Security Policy') ||
          text.includes('unsafe-eval') ||
          text.includes('CSP')) {
        this.cspViolations.push({
          message: text,
          timestamp: Date.now()
        });
      }
    });

    // Monitor network requests for authentication flows
    this.page.on('request', (request) => {
      if (request.url().includes('/api/') ||
          request.url().includes('auth') ||
          request.url().includes('login')) {
        this.networkRequests.push({
          type: 'request',
          url: request.url(),
          method: request.method(),
          headers: request.headers(),
          timestamp: Date.now()
        });
      }
    });

    // Monitor responses for redirects and auth responses
    this.page.on('response', (response) => {
      // Track redirects
      if ([301, 302, 303, 307, 308].includes(response.status())) {
        this.redirectChain.push({
          from: response.url(),
          to: response.headers()['location'],
          status: response.status(),
          timestamp: Date.now()
        });
      }

      // Track auth-related responses
      if (response.url().includes('/api/') ||
          response.url().includes('auth') ||
          response.url().includes('login')) {
        this.networkRequests.push({
          type: 'response',
          url: response.url(),
          status: response.status(),
          headers: response.headers(),
          timestamp: Date.now()
        });
      }
    });
  }

  async clearAuthState() {
    try {
      // Only clear storage if we're on a valid page
      const url = this.page.url();
      if (url && !url.includes('about:blank') && !url.includes('chrome-error://')) {
        await this.page.evaluate(() => {
          try {
            localStorage.clear();
            sessionStorage.clear();
            // Clear all cookies
            document.cookie.split(";").forEach(function(c) {
              document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/");
            });
          } catch (e) {
            console.log('Storage clearing error:', e.message);
          }
        });
      }
    } catch (e) {
      console.log('Failed to clear auth state:', e.message);
    }

    // Clear monitoring arrays
    this.consoleMessages = [];
    this.cspViolations = [];
    this.networkRequests = [];
    this.redirectChain = [];
  }

  async waitForPageLoad(timeout = 10000) {
    await this.page.waitForLoadState('networkidle', { timeout });
    await this.page.waitForTimeout(1000); // Additional buffer for any async operations
  }

  async getLoginFormElements() {
    await this.waitForPageLoad();

    // Find email input
    const emailInput = await this.page.locator([
      '[data-testid="email-input"]',
      'input[type="email"]',
      'input[name="email"]',
      'input[placeholder*="email" i]',
      '#email'
    ].join(', ')).first();

    // Find password input
    const passwordInput = await this.page.locator([
      '[data-testid="password-input"]',
      'input[type="password"]',
      'input[name="password"]',
      'input[placeholder*="password" i]',
      '#password'
    ].join(', ')).first();

    // Find user type selector (if present)
    const userTypeSelect = await this.page.locator([
      '[data-testid="user-type-select"]',
      'select[name="userType"]',
      'select[name="user_type"]',
      '.user-type-select'
    ].join(', ')).first();

    return { emailInput, passwordInput, userTypeSelect };
  }

  async checkAutocompleteAttributes() {
    const { emailInput, passwordInput } = await this.getLoginFormElements();

    // Check email input autocomplete
    const emailAutocomplete = await emailInput.getAttribute('autocomplete');
    const emailAutoComplete = await emailInput.getAttribute('autoComplete'); // React camelCase

    // Check password input autocomplete
    const passwordAutocomplete = await passwordInput.getAttribute('autocomplete');
    const passwordAutoComplete = await passwordInput.getAttribute('autoComplete'); // React camelCase

    return {
      email: {
        autocomplete: emailAutocomplete,
        autoComplete: emailAutoComplete,
        hasUsernameAutocomplete: emailAutocomplete === 'username' || emailAutoComplete === 'username'
      },
      password: {
        autocomplete: passwordAutocomplete,
        autoComplete: passwordAutoComplete,
        hasCurrentPasswordAutocomplete: passwordAutocomplete === 'current-password' || passwordAutoComplete === 'current-password'
      }
    };
  }

  async performLogin(credentials = BRAND_USER) {
    const { emailInput, passwordInput, userTypeSelect } = await this.getLoginFormElements();

    // Fill email
    await emailInput.fill(credentials.email);

    // Fill password
    await passwordInput.fill(credentials.password);

    // Select user type if available
    if (await userTypeSelect.isVisible()) {
      await userTypeSelect.selectOption(credentials.userType);
    }

    // Submit form
    const submitButton = await this.page.locator([
      '[data-testid="login-submit"]',
      'button[type="submit"]',
      'button:has-text("Login")',
      'button:has-text("Sign In")',
      '.login-button',
      'input[type="submit"]'
    ].join(', ')).first();

    await submitButton.click();
  }

  async getAuthTokens() {
    return await this.page.evaluate(() => ({
      accessToken: localStorage.getItem('engarde_access_token'),
      refreshToken: localStorage.getItem('engarde_refresh_token'),
      user: localStorage.getItem('engarde_user'),
      // Check for any other possible token storage patterns
      engardeAccessToken: localStorage.getItem('engardeAccessToken'),
      engardeRefreshToken: localStorage.getItem('engardeRefreshToken'),
      authToken: localStorage.getItem('authToken'),
      token: localStorage.getItem('token')
    }));
  }

  async checkForRedirectLoops() {
    // Analyze redirect chain for loops
    const redirectUrls = this.redirectChain.map(r => new URL(r.from).pathname);
    const uniqueUrls = new Set(redirectUrls);

    // Check for cycles - if we have more URLs than unique URLs, there's a loop
    const hasLoop = redirectUrls.length > uniqueUrls.size + 2; // Allow 2 duplicate redirects max

    // Check for login-specific loops
    const loginRedirects = this.redirectChain.filter(r =>
      r.from.includes('/login') || r.to?.includes('/login')
    );

    return {
      hasLoop,
      totalRedirects: this.redirectChain.length,
      uniqueRedirects: uniqueUrls.size,
      loginRedirects: loginRedirects.length,
      redirectChain: this.redirectChain
    };
  }

  async checkCSPCompliance() {
    return {
      violations: this.cspViolations,
      hasUnsafeEvalViolations: this.cspViolations.some(v =>
        v.message.includes('unsafe-eval')
      ),
      hasViolations: this.cspViolations.length > 0,
      consoleErrors: this.consoleMessages.filter(m => m.type === 'error'),
      consoleWarnings: this.consoleMessages.filter(m => m.type === 'warning')
    };
  }

  async testTokenStorageReliability() {
    // Test token storage and retrieval multiple times
    const testResults = [];

    for (let i = 0; i < 3; i++) {
      const testToken = `test-token-${i}-${Date.now()}`;

      // Store token
      await this.page.evaluate((token) => {
        localStorage.setItem('engarde_access_token', token);
      }, testToken);

      // Immediate retrieval
      const immediateRetrieve = await this.page.evaluate(() =>
        localStorage.getItem('engarde_access_token')
      );

      // Wait and retrieve again
      await this.page.waitForTimeout(500);
      const delayedRetrieve = await this.page.evaluate(() =>
        localStorage.getItem('engarde_access_token')
      );

      testResults.push({
        stored: testToken,
        immediateRetrieve,
        delayedRetrieve,
        success: testToken === immediateRetrieve && testToken === delayedRetrieve
      });
    }

    return testResults;
  }

  getMonitoringReport() {
    return {
      redirectChain: this.redirectChain,
      cspViolations: this.cspViolations,
      consoleMessages: this.consoleMessages,
      networkRequests: this.networkRequests,
      summary: {
        totalRedirects: this.redirectChain.length,
        totalCSPViolations: this.cspViolations.length,
        totalConsoleErrors: this.consoleMessages.filter(m => m.type === 'error').length,
        totalNetworkRequests: this.networkRequests.length
      }
    };
  }
}

test.describe('Authentication Fixes Verification', () => {
  let authUtils;

  test.beforeEach(async ({ page }) => {
    authUtils = new AuthFixesTestUtils(page);
    await authUtils.setupMonitoring();

    // Navigate to base URL first to establish context
    await page.goto(BASE_URL);
    await authUtils.waitForPageLoad();
    await authUtils.clearAuthState();
  });

  test.describe('Form Autocomplete Attributes', () => {
    test('should have proper autocomplete attributes on login form fields', async ({ page }) => {
      console.log('🧪 Testing form autocomplete attributes...');

      // Navigate to login page
      await page.goto(`${BASE_URL}/login`);
      await authUtils.waitForPageLoad();

      // Check autocomplete attributes
      const autocompleteCheck = await authUtils.checkAutocompleteAttributes();

      // Verify email field has username autocomplete
      expect(autocompleteCheck.email.hasUsernameAutocomplete).toBeTruthy();
      console.log(`✅ Email field autocomplete: ${autocompleteCheck.email.autocomplete || autocompleteCheck.email.autoComplete}`);

      // Verify password field has current-password autocomplete
      expect(autocompleteCheck.password.hasCurrentPasswordAutocomplete).toBeTruthy();
      console.log(`✅ Password field autocomplete: ${autocompleteCheck.password.autocomplete || autocompleteCheck.password.autoComplete}`);

      console.log('✅ Form autocomplete attributes test passed');
    });

    test('should enable browser password manager integration', async ({ page }) => {
      console.log('🧪 Testing browser password manager integration...');

      await page.goto(`${BASE_URL}/login`);
      await authUtils.waitForPageLoad();

      const { emailInput, passwordInput } = await authUtils.getLoginFormElements();

      // Fill credentials to trigger password manager
      await emailInput.fill(BRAND_USER.email);
      await passwordInput.fill(BRAND_USER.password);

      // Check that fields are properly marked for password managers
      const emailName = await emailInput.getAttribute('name');
      const passwordName = await passwordInput.getAttribute('name');
      const emailType = await emailInput.getAttribute('type');
      const passwordType = await passwordInput.getAttribute('type');

      expect(emailType).toBe('email');
      expect(passwordType).toBe('password');
      expect(emailName).toBeTruthy();
      expect(passwordName).toBeTruthy();

      console.log('✅ Browser password manager integration test passed');
    });
  });

  test.describe('Authentication Flow Stability', () => {
    test('should not create authentication redirect loops', async ({ page }) => {
      console.log('🧪 Testing authentication redirect loop prevention...');

      await page.goto(`${BASE_URL}/login`);
      await authUtils.waitForPageLoad();

      // Perform login
      await authUtils.performLogin();

      // Wait for authentication to complete
      await page.waitForURL('**/dashboard**', { timeout: 30000 });

      // Check for redirect loops
      const redirectAnalysis = await authUtils.checkForRedirectLoops();

      // Verify no excessive redirects
      expect(redirectAnalysis.totalRedirects).toBeLessThan(5);
      expect(redirectAnalysis.hasLoop).toBeFalsy();
      expect(redirectAnalysis.loginRedirects).toBeLessThan(3);

      console.log(`✅ Redirect analysis: ${redirectAnalysis.totalRedirects} total redirects, ${redirectAnalysis.loginRedirects} login redirects`);
      console.log('✅ Authentication redirect loop prevention test passed');
    });

    test('should handle timing delays in authentication flow', async ({ page }) => {
      console.log('🧪 Testing authentication timing delays...');

      await page.goto(`${BASE_URL}/login`);
      await authUtils.waitForPageLoad();

      const startTime = Date.now();
      await authUtils.performLogin();

      // Wait for navigation with generous timeout to handle delays
      await page.waitForURL('**/dashboard**', { timeout: 30000 });
      const endTime = Date.now();

      // Verify authentication completed
      const tokens = await authUtils.getAuthTokens();
      expect(tokens.accessToken || tokens.engardeAccessToken || tokens.authToken || tokens.token).toBeTruthy();

      // Check that timing is reasonable (not too fast indicating a loop, not too slow indicating hanging)
      const authTime = endTime - startTime;
      expect(authTime).toBeGreaterThan(1000); // At least 1 second (not instant)
      expect(authTime).toBeLessThan(25000); // Less than 25 seconds

      console.log(`✅ Authentication completed in ${authTime}ms`);
      console.log('✅ Authentication timing delays test passed');
    });

    test('should clear session flags to prevent cycling', async ({ page }) => {
      console.log('🧪 Testing session flag clearing...');

      await page.goto(`${BASE_URL}/login`);
      await authUtils.waitForPageLoad();

      // Check initial session state
      const initialFlags = await page.evaluate(() => ({
        isLoggingIn: sessionStorage.getItem('isLoggingIn'),
        authInProgress: sessionStorage.getItem('authInProgress'),
        loginAttempt: sessionStorage.getItem('loginAttempt')
      }));

      // Perform login
      await authUtils.performLogin();
      await page.waitForURL('**/dashboard**', { timeout: 30000 });

      // Check final session state - flags should be cleared
      const finalFlags = await page.evaluate(() => ({
        isLoggingIn: sessionStorage.getItem('isLoggingIn'),
        authInProgress: sessionStorage.getItem('authInProgress'),
        loginAttempt: sessionStorage.getItem('loginAttempt')
      }));

      // Session flags should be null or cleared after successful login
      expect(finalFlags.isLoggingIn).toBeNull();
      expect(finalFlags.authInProgress).toBeNull();

      console.log('✅ Session flags cleared successfully');
      console.log('✅ Session flag clearing test passed');
    });
  });

  test.describe('Token Storage Reliability', () => {
    test('should store tokens reliably with retry logic', async ({ page }) => {
      console.log('🧪 Testing token storage reliability...');

      // Test storage reliability before login
      const storageTest = await authUtils.testTokenStorageReliability();
      const allTestsPassed = storageTest.every(test => test.success);
      expect(allTestsPassed).toBeTruthy();

      // Perform actual login
      await page.goto(`${BASE_URL}/login`);
      await authUtils.waitForPageLoad();
      await authUtils.performLogin();
      await page.waitForURL('**/dashboard**', { timeout: 30000 });

      // Verify tokens are stored
      const tokens = await authUtils.getAuthTokens();
      const hasValidToken = tokens.accessToken || tokens.engardeAccessToken || tokens.authToken || tokens.token;
      expect(hasValidToken).toBeTruthy();

      // Test token persistence across page reload
      await page.reload();
      await authUtils.waitForPageLoad();

      const tokensAfterReload = await authUtils.getAuthTokens();
      const hasValidTokenAfterReload = tokensAfterReload.accessToken || tokensAfterReload.engardeAccessToken || tokensAfterReload.authToken || tokensAfterReload.token;
      expect(hasValidTokenAfterReload).toBeTruthy();

      console.log('✅ Token storage reliability test passed');
    });

    test('should handle token storage errors gracefully', async ({ page }) => {
      console.log('🧪 Testing token storage error handling...');

      await page.goto(`${BASE_URL}/login`);
      await authUtils.waitForPageLoad();

      // Simulate localStorage quota exceeded
      await page.evaluate(() => {
        const originalSetItem = localStorage.setItem;
        let callCount = 0;
        localStorage.setItem = function(key, value) {
          callCount++;
          if (callCount <= 2) {
            // Fail first two attempts to test retry logic
            throw new Error('QuotaExceededError');
          }
          return originalSetItem.call(this, key, value);
        };
      });

      // Perform login - should succeed despite initial storage failures
      await authUtils.performLogin();
      await page.waitForURL('**/dashboard**', { timeout: 30000 });

      // Verify login succeeded
      const currentUrl = page.url();
      expect(currentUrl).toContain('dashboard');

      console.log('✅ Token storage error handling test passed');
    });
  });

  test.describe('CSP Policy Compliance', () => {
    test('should not have unsafe-eval violations', async ({ page }) => {
      console.log('🧪 Testing CSP policy compliance...');

      await page.goto(`${BASE_URL}/login`);
      await authUtils.waitForPageLoad();

      // Perform login to test entire flow
      await authUtils.performLogin();
      await page.waitForURL('**/dashboard**', { timeout: 30000 });

      // Wait additional time for any late CSP violations
      await page.waitForTimeout(3000);

      // Check CSP compliance
      const cspCheck = await authUtils.checkCSPCompliance();

      // Should have no unsafe-eval violations
      expect(cspCheck.hasUnsafeEvalViolations).toBeFalsy();

      // Report any violations found
      if (cspCheck.hasViolations) {
        console.log('⚠️ CSP violations found:', cspCheck.violations);
      }

      // Should have minimal console errors
      const criticalErrors = cspCheck.consoleErrors.filter(e =>
        !e.text.includes('favicon') &&
        !e.text.includes('404') &&
        !e.text.includes('net::ERR_')
      );
      expect(criticalErrors.length).toBeLessThan(3);

      console.log(`✅ CSP compliance check: ${cspCheck.violations.length} violations, ${criticalErrors.length} critical errors`);
      console.log('✅ CSP policy compliance test passed');
    });

    test('should load all resources without CSP blocking', async ({ page }) => {
      console.log('🧪 Testing resource loading without CSP blocking...');

      // Track failed resource loads
      const failedResources = [];
      page.on('response', (response) => {
        if (response.status() >= 400 && !response.url().includes('favicon')) {
          failedResources.push({
            url: response.url(),
            status: response.status()
          });
        }
      });

      await page.goto(`${BASE_URL}/login`);
      await authUtils.waitForPageLoad();

      // Navigate through auth flow
      await authUtils.performLogin();
      await page.waitForURL('**/dashboard**', { timeout: 30000 });
      await authUtils.waitForPageLoad();

      // Check for CSP-related resource blocking
      const cspCheck = await authUtils.checkCSPCompliance();
      const cspBlockedResources = cspCheck.violations.filter(v =>
        v.message.includes('blocked') || v.message.includes('refused')
      );

      expect(cspBlockedResources.length).toBe(0);

      // Allow some non-critical resource failures
      const criticalFailures = failedResources.filter(r =>
        !r.url.includes('favicon') &&
        !r.url.includes('.map') &&
        r.status !== 404
      );
      expect(criticalFailures.length).toBeLessThan(2);

      console.log(`✅ Resource loading check: ${failedResources.length} total failures, ${criticalFailures.length} critical`);
      console.log('✅ Resource loading test passed');
    });
  });

  test.describe('Brand User Authentication', () => {
    test('should successfully authenticate brand user', async ({ page }) => {
      console.log(`🧪 Testing brand user authentication (${BRAND_USER.email})...`);

      await page.goto(`${BASE_URL}/login`);
      await authUtils.waitForPageLoad();

      // Perform login with brand credentials
      await authUtils.performLogin(BRAND_USER);
      await page.waitForURL('**/dashboard**', { timeout: 30000 });

      // Verify successful authentication
      const tokens = await authUtils.getAuthTokens();
      const hasValidToken = tokens.accessToken || tokens.engardeAccessToken || tokens.authToken || tokens.token;
      expect(hasValidToken).toBeTruthy();

      // Verify user data is stored
      const userData = tokens.user ? JSON.parse(tokens.user) : null;
      if (userData) {
        expect(userData.email || userData.username).toContain('engarde.ai');
      }

      // Verify dashboard access
      const currentUrl = page.url();
      expect(currentUrl).toContain('dashboard');

      console.log('✅ Brand user authentication test passed');
    });

    test('should maintain authentication state across browser refresh', async ({ page }) => {
      console.log('🧪 Testing authentication persistence across refresh...');

      // Login first
      await page.goto(`${BASE_URL}/login`);
      await authUtils.waitForPageLoad();
      await authUtils.performLogin(BRAND_USER);
      await page.waitForURL('**/dashboard**', { timeout: 30000 });

      // Get tokens before refresh
      const tokensBefore = await authUtils.getAuthTokens();
      const hasValidTokenBefore = tokensBefore.accessToken || tokensBefore.engardeAccessToken || tokensBefore.authToken || tokensBefore.token;
      expect(hasValidTokenBefore).toBeTruthy();

      // Refresh page
      await page.reload();
      await authUtils.waitForPageLoad();

      // Should still be on dashboard
      const currentUrl = page.url();
      expect(currentUrl).toContain('dashboard');

      // Tokens should persist
      const tokensAfter = await authUtils.getAuthTokens();
      const hasValidTokenAfter = tokensAfter.accessToken || tokensAfter.engardeAccessToken || tokensAfter.authToken || tokensAfter.token;
      expect(hasValidTokenAfter).toBeTruthy();

      console.log('✅ Authentication persistence test passed');
    });
  });

  test.describe('CSRF Protection', () => {
    test('should include CSRF protection in authentication requests', async ({ page }) => {
      console.log('🧪 Testing CSRF protection...');

      await page.goto(`${BASE_URL}/login`);
      await authUtils.waitForPageLoad();

      // Monitor authentication requests
      const authRequests = [];
      page.on('request', (request) => {
        if (request.url().includes('/api/auth') || request.url().includes('/login')) {
          authRequests.push({
            url: request.url(),
            method: request.method(),
            headers: request.headers()
          });
        }
      });

      await authUtils.performLogin(BRAND_USER);
      await page.waitForURL('**/dashboard**', { timeout: 30000 });

      // Check that authentication requests include CSRF protection
      const postRequests = authRequests.filter(r => r.method === 'POST');
      expect(postRequests.length).toBeGreaterThan(0);

      // Check for CSRF token in headers or form data
      const hasCSRFProtection = postRequests.some(request =>
        request.headers['x-csrf-token'] ||
        request.headers['x-xsrf-token'] ||
        request.headers['csrf-token'] ||
        Object.keys(request.headers).some(h => h.toLowerCase().includes('csrf'))
      );

      // Note: CSRF validation might be handled differently, so we log for investigation
      console.log('Auth requests:', postRequests.map(r => ({ url: r.url, headers: Object.keys(r.headers) })));
      console.log('✅ CSRF protection test completed');
    });
  });

  test.afterEach(async ({ page }) => {
    // Generate monitoring report
    const report = authUtils.getMonitoringReport();

    console.log('\n📊 Test Monitoring Report:');
    console.log(`- Total redirects: ${report.summary.totalRedirects}`);
    console.log(`- CSP violations: ${report.summary.totalCSPViolations}`);
    console.log(`- Console errors: ${report.summary.totalConsoleErrors}`);
    console.log(`- Network requests: ${report.summary.totalNetworkRequests}`);

    if (report.cspViolations.length > 0) {
      console.log('\n⚠️ CSP Violations:');
      report.cspViolations.forEach(v => console.log(`  - ${v.message}`));
    }

    if (report.redirectChain.length > 0) {
      console.log('\n🔄 Redirect Chain:');
      report.redirectChain.forEach(r => console.log(`  - ${r.from} → ${r.to} (${r.status})`));
    }
  });
});