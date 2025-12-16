const { test, expect } = require('@playwright/test');

/**
 * Comprehensive Authentication Test Suite
 * Tests the complete authentication flow and identifies login loop issues
 */

// Test configuration
const BASE_URL = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3001';
const API_BASE_URL = process.env.PLAYWRIGHT_API_URL || 'http://localhost:8000';

// Test users
const TEST_USERS = {
  publisher: {
    email: 'publisher@test.com',
    password: 'TestPassword123!',
    userType: 'publisher'
  },
  advertiser: {
    email: 'advertiser@test.com',
    password: 'TestPassword123!',
    userType: 'advertiser'
  },
  invalid: {
    email: 'invalid@test.com',
    password: 'wrongpassword',
    userType: 'publisher'
  }
};

// Test utilities
class AuthTestUtils {
  constructor(page) {
    this.page = page;
  }

  async waitForPageLoad(timeout = 10000) {
    await this.page.waitForLoadState('networkidle', { timeout });
    await this.page.waitForTimeout(500); // Additional buffer
  }

  async clearAuthState() {
    // Clear all storage
    await this.page.evaluate(() => {
      localStorage.clear();
      sessionStorage.clear();
      // Clear all cookies
      document.cookie.split(";").forEach(function(c) {
        document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/");
      });
    });
  }

  async getAuthTokens() {
    return await this.page.evaluate(() => ({
      accessToken: localStorage.getItem('engarde_access_token'),
      refreshToken: localStorage.getItem('engarde_refresh_token'),
      user: localStorage.getItem('engarde_user')
    }));
  }

  async setAuthTokens(tokens) {
    await this.page.evaluate((tokens) => {
      if (tokens.accessToken) localStorage.setItem('engarde_access_token', tokens.accessToken);
      if (tokens.refreshToken) localStorage.setItem('engarde_refresh_token', tokens.refreshToken);
      if (tokens.user) localStorage.setItem('engarde_user', JSON.stringify(tokens.user));
    }, tokens);
  }

  async fillLoginForm(credentials) {
    await this.page.fill('[data-testid="email-input"], input[type="email"], input[name="email"]', credentials.email);
    await this.page.fill('[data-testid="password-input"], input[type="password"], input[name="password"]', credentials.password);

    // Select user type if available
    if (credentials.userType) {
      const userTypeSelector = await this.page.$('[data-testid="user-type-select"], select[name="userType"]');
      if (userTypeSelector) {
        await this.page.selectOption('[data-testid="user-type-select"], select[name="userType"]', credentials.userType);
      }
    }
  }

  async submitLoginForm() {
    // Try different possible submit buttons
    const submitSelectors = [
      '[data-testid="login-submit"]',
      'button[type="submit"]',
      'button:has-text("Login")',
      'button:has-text("Sign In")',
      '.login-button',
      'input[type="submit"]'
    ];

    for (const selector of submitSelectors) {
      const button = await this.page.$(selector);
      if (button) {
        await button.click();
        return;
      }
    }

    // If no submit button found, try pressing Enter
    await this.page.keyboard.press('Enter');
  }

  async detectCurrentPage() {
    await this.waitForPageLoad();
    const url = this.page.url();
    const title = await this.page.title();

    // Check for specific page indicators
    const indicators = {
      login: ['/login', 'sign in', 'login', 'authentication'],
      dashboard: ['/dashboard', 'dashboard'],
      home: ['/', 'home'],
      onboarding: ['/onboarding', 'welcome', 'get started']
    };

    for (const [pageType, patterns] of Object.entries(indicators)) {
      if (patterns.some(pattern =>
        url.toLowerCase().includes(pattern) ||
        title.toLowerCase().includes(pattern)
      )) {
        return pageType;
      }
    }

    return 'unknown';
  }

  async trackRedirectChain() {
    const redirects = [];

    this.page.on('response', (response) => {
      if ([301, 302, 303, 307, 308].includes(response.status())) {
        redirects.push({
          from: response.url(),
          to: response.headers()['location'],
          status: response.status(),
          timestamp: Date.now()
        });
      }
    });

    return redirects;
  }

  async monitorNetworkActivity() {
    const networkActivity = [];

    this.page.on('request', (request) => {
      if (request.url().includes('/api/') || request.url().includes('auth')) {
        networkActivity.push({
          type: 'request',
          url: request.url(),
          method: request.method(),
          timestamp: Date.now()
        });
      }
    });

    this.page.on('response', (response) => {
      if (response.url().includes('/api/') || response.url().includes('auth')) {
        networkActivity.push({
          type: 'response',
          url: response.url(),
          status: response.status(),
          timestamp: Date.now()
        });
      }
    });

    return networkActivity;
  }
}

test.describe('Comprehensive Authentication Tests', () => {
  let authUtils;

  test.beforeEach(async ({ page }) => {
    authUtils = new AuthTestUtils(page);

    // Clear authentication state before each test
    await authUtils.clearAuthState();

    // Start from a clean slate
    await page.goto(BASE_URL);
    await authUtils.waitForPageLoad();
  });

  test.describe('Basic Authentication Flow', () => {
    test('should successfully login and redirect to dashboard', async ({ page }) => {
      console.log('🧪 Testing basic login flow...');

      // Navigate to login page
      await page.goto(`${BASE_URL}/login`);
      await authUtils.waitForPageLoad();

      // Track redirects to detect loops
      const redirects = await authUtils.trackRedirectChain();

      // Fill and submit login form
      await authUtils.fillLoginForm(TEST_USERS.publisher);
      await authUtils.submitLoginForm();

      // Wait for navigation after login
      await page.waitForURL('**/dashboard**', { timeout: 15000 });

      // Verify we're on the dashboard
      const currentPage = await authUtils.detectCurrentPage();
      expect(currentPage).toBe('dashboard');

      // Verify authentication tokens are stored
      const tokens = await authUtils.getAuthTokens();
      expect(tokens.accessToken).toBeTruthy();
      expect(tokens.user).toBeTruthy();

      // Verify no redirect loops
      const loginRedirects = redirects.filter(r => r.from.includes('login'));
      expect(loginRedirects.length).toBeLessThan(3); // Allow max 2 redirects

      console.log('✅ Basic login flow successful');
    });

    test('should reject invalid credentials', async ({ page }) => {
      console.log('🧪 Testing invalid credentials...');

      await page.goto(`${BASE_URL}/login`);
      await authUtils.waitForPageLoad();

      // Fill form with invalid credentials
      await authUtils.fillLoginForm(TEST_USERS.invalid);
      await authUtils.submitLoginForm();

      // Should remain on login page
      await page.waitForTimeout(3000);
      const currentPage = await authUtils.detectCurrentPage();
      expect(currentPage).toBe('login');

      // Check for error message
      const errorMessage = await page.locator('[data-testid="error-message"], .error, .alert-error').first();
      if (await errorMessage.isVisible()) {
        const errorText = await errorMessage.textContent();
        expect(errorText.toLowerCase()).toContain('invalid');
      }

      // Verify no tokens stored
      const tokens = await authUtils.getAuthTokens();
      expect(tokens.accessToken).toBeFalsy();

      console.log('✅ Invalid credentials properly rejected');
    });

    test('should successfully logout and redirect to login', async ({ page }) => {
      console.log('🧪 Testing logout flow...');

      // First login
      await page.goto(`${BASE_URL}/login`);
      await authUtils.fillLoginForm(TEST_USERS.publisher);
      await authUtils.submitLoginForm();
      await page.waitForURL('**/dashboard**', { timeout: 15000 });

      // Find and click logout
      const logoutSelectors = [
        '[data-testid="logout-button"]',
        'button:has-text("Logout")',
        'button:has-text("Sign Out")',
        '.logout-button',
        'a:has-text("Logout")'
      ];

      let loggedOut = false;
      for (const selector of logoutSelectors) {
        const button = await page.$(selector);
        if (button) {
          await button.click();
          loggedOut = true;
          break;
        }
      }

      if (!loggedOut) {
        // Try accessing user menu first
        const userMenus = ['[data-testid="user-menu"]', '.user-menu', '.profile-menu'];
        for (const menuSelector of userMenus) {
          const menu = await page.$(menuSelector);
          if (menu) {
            await menu.click();
            await page.waitForTimeout(500);
            // Try logout buttons again
            for (const selector of logoutSelectors) {
              const button = await page.$(selector);
              if (button) {
                await button.click();
                loggedOut = true;
                break;
              }
            }
            if (loggedOut) break;
          }
        }
      }

      // Verify logout
      if (loggedOut) {
        await page.waitForURL('**/login**', { timeout: 10000 });
        const currentPage = await authUtils.detectCurrentPage();
        expect(currentPage).toBe('login');

        // Verify tokens cleared
        const tokens = await authUtils.getAuthTokens();
        expect(tokens.accessToken).toBeFalsy();
      }

      console.log('✅ Logout flow completed');
    });
  });

  test.describe('Login Loop Detection Tests', () => {
    test('should not create infinite redirect loops', async ({ page }) => {
      console.log('🧪 Testing for redirect loops...');

      let redirectCount = 0;
      const redirectHistory = [];

      page.on('response', (response) => {
        if ([301, 302, 303, 307, 308].includes(response.status())) {
          redirectCount++;
          redirectHistory.push({
            from: response.url(),
            to: response.headers()['location'],
            status: response.status(),
            timestamp: Date.now()
          });

          // Fail fast if too many redirects
          if (redirectCount > 10) {
            throw new Error(`Too many redirects detected: ${redirectCount}`);
          }
        }
      });

      // Test login flow
      await page.goto(`${BASE_URL}/login`);
      await authUtils.fillLoginForm(TEST_USERS.publisher);
      await authUtils.submitLoginForm();

      // Wait for final destination
      await page.waitForTimeout(5000);

      // Analyze redirect chain
      expect(redirectCount).toBeLessThan(5); // Max 4 redirects allowed

      // Check for circular redirects
      const urls = redirectHistory.map(r => r.from);
      const uniqueUrls = new Set(urls);
      expect(urls.length - uniqueUrls.size).toBeLessThan(2); // Allow max 1 repeat

      console.log(`✅ Redirect test passed. Total redirects: ${redirectCount}`);
      console.log('Redirect chain:', redirectHistory);
    });

    test('should maintain authentication state across page reloads', async ({ page }) => {
      console.log('🧪 Testing authentication persistence...');

      // Login first
      await page.goto(`${BASE_URL}/login`);
      await authUtils.fillLoginForm(TEST_USERS.publisher);
      await authUtils.submitLoginForm();
      await page.waitForURL('**/dashboard**', { timeout: 15000 });

      // Get tokens before reload
      const tokensBefore = await authUtils.getAuthTokens();
      expect(tokensBefore.accessToken).toBeTruthy();

      // Reload page
      await page.reload();
      await authUtils.waitForPageLoad();

      // Should still be authenticated and on dashboard
      const currentPage = await authUtils.detectCurrentPage();
      expect(currentPage).toBe('dashboard');

      // Tokens should still exist
      const tokensAfter = await authUtils.getAuthTokens();
      expect(tokensAfter.accessToken).toBeTruthy();
      expect(tokensAfter.accessToken).toBe(tokensBefore.accessToken);

      console.log('✅ Authentication persisted across reload');
    });

    test('should redirect unauthenticated users to login', async ({ page }) => {
      console.log('🧪 Testing protected route access...');

      // Try to access protected dashboard without authentication
      await page.goto(`${BASE_URL}/dashboard`);
      await authUtils.waitForPageLoad();

      // Should be redirected to login
      await page.waitForURL('**/login**', { timeout: 10000 });
      const currentPage = await authUtils.detectCurrentPage();
      expect(currentPage).toBe('login');

      // Verify no auth tokens
      const tokens = await authUtils.getAuthTokens();
      expect(tokens.accessToken).toBeFalsy();

      console.log('✅ Protected route properly redirected to login');
    });
  });

  test.describe('Authentication State Consistency', () => {
    test('should handle concurrent login attempts', async ({ page, browser }) => {
      console.log('🧪 Testing concurrent login attempts...');

      // Create second page/context
      const context2 = await browser.newContext();
      const page2 = await context2.newPage();
      const authUtils2 = new AuthTestUtils(page2);
      await authUtils2.clearAuthState();

      try {
        // Start login on both pages simultaneously
        const loginPromise1 = (async () => {
          await page.goto(`${BASE_URL}/login`);
          await authUtils.fillLoginForm(TEST_USERS.publisher);
          await authUtils.submitLoginForm();
          return page.waitForURL('**/dashboard**', { timeout: 15000 });
        })();

        const loginPromise2 = (async () => {
          await page2.goto(`${BASE_URL}/login`);
          await authUtils2.fillLoginForm(TEST_USERS.publisher);
          await authUtils2.submitLoginForm();
          return page2.waitForURL('**/dashboard**', { timeout: 15000 });
        })();

        // Wait for both to complete
        await Promise.all([loginPromise1, loginPromise2]);

        // Both should be authenticated
        const tokens1 = await authUtils.getAuthTokens();
        const tokens2 = await authUtils2.getAuthTokens();

        expect(tokens1.accessToken).toBeTruthy();
        expect(tokens2.accessToken).toBeTruthy();

        console.log('✅ Concurrent login attempts handled successfully');
      } finally {
        await context2.close();
      }
    });

    test('should handle browser refresh during authentication', async ({ page }) => {
      console.log('🧪 Testing refresh during authentication...');

      await page.goto(`${BASE_URL}/login`);
      await authUtils.fillLoginForm(TEST_USERS.publisher);

      // Submit form and immediately refresh
      await authUtils.submitLoginForm();
      await page.waitForTimeout(1000); // Wait a bit for request to start
      await page.reload();

      await authUtils.waitForPageLoad();

      // Should be back on login page (auth interrupted)
      const currentPage = await authUtils.detectCurrentPage();
      expect(['login', 'dashboard'].includes(currentPage)).toBeTruthy();

      // If on login, try again
      if (currentPage === 'login') {
        await authUtils.fillLoginForm(TEST_USERS.publisher);
        await authUtils.submitLoginForm();
        await page.waitForURL('**/dashboard**', { timeout: 15000 });
      }

      const finalTokens = await authUtils.getAuthTokens();
      expect(finalTokens.accessToken).toBeTruthy();

      console.log('✅ Refresh during authentication handled');
    });

    test('should validate token expiration handling', async ({ page }) => {
      console.log('🧪 Testing token expiration...');

      // Login first
      await page.goto(`${BASE_URL}/login`);
      await authUtils.fillLoginForm(TEST_USERS.publisher);
      await authUtils.submitLoginForm();
      await page.waitForURL('**/dashboard**', { timeout: 15000 });

      // Get current tokens
      const validTokens = await authUtils.getAuthTokens();
      expect(validTokens.accessToken).toBeTruthy();

      // Simulate expired token by setting an invalid one
      await authUtils.setAuthTokens({
        accessToken: 'expired.token.here',
        refreshToken: validTokens.refreshToken,
        user: validTokens.user
      });

      // Try to access a protected API endpoint
      const response = await page.evaluate(async () => {
        try {
          const res = await fetch('/api/me', {
            headers: {
              'Authorization': `Bearer ${localStorage.getItem('engarde_access_token')}`
            }
          });
          return { status: res.status, ok: res.ok };
        } catch (error) {
          return { error: error.message };
        }
      });

      // Should handle expired token gracefully
      expect([401, 403].includes(response.status) || response.error).toBeTruthy();

      console.log('✅ Token expiration handling verified');
    });
  });

  test.describe('Network and Performance Tests', () => {
    test('should handle slow network during authentication', async ({ page }) => {
      console.log('🧪 Testing slow network conditions...');

      // Throttle network
      const client = await page.context().newCDPSession(page);
      await client.send('Network.emulateNetworkConditions', {
        offline: false,
        downloadThroughput: 50000, // 50kb/s
        uploadThroughput: 20000,   // 20kb/s
        latency: 2000              // 2s latency
      });

      try {
        await page.goto(`${BASE_URL}/login`);
        await authUtils.fillLoginForm(TEST_USERS.publisher);

        const startTime = Date.now();
        await authUtils.submitLoginForm();

        // Should eventually succeed despite slow network
        await page.waitForURL('**/dashboard**', { timeout: 30000 });
        const endTime = Date.now();

        const tokens = await authUtils.getAuthTokens();
        expect(tokens.accessToken).toBeTruthy();

        console.log(`✅ Slow network test passed. Duration: ${endTime - startTime}ms`);
      } finally {
        // Reset network conditions
        await client.send('Network.emulateNetworkConditions', {
          offline: false,
          downloadThroughput: -1,
          uploadThroughput: -1,
          latency: 0
        });
      }
    });

    test('should handle network interruption during login', async ({ page }) => {
      console.log('🧪 Testing network interruption...');

      await page.goto(`${BASE_URL}/login`);
      await authUtils.fillLoginForm(TEST_USERS.publisher);

      // Start form submission
      const submitPromise = authUtils.submitLoginForm();

      // Simulate network interruption
      const client = await page.context().newCDPSession(page);
      await client.send('Network.emulateNetworkConditions', {
        offline: true,
        downloadThroughput: 0,
        uploadThroughput: 0,
        latency: 0
      });

      await submitPromise;
      await page.waitForTimeout(3000);

      // Restore network
      await client.send('Network.emulateNetworkConditions', {
        offline: false,
        downloadThroughput: -1,
        uploadThroughput: -1,
        latency: 0
      });

      // Should handle gracefully - either stay on login or show error
      const currentPage = await authUtils.detectCurrentPage();
      expect(['login', 'dashboard'].includes(currentPage)).toBeTruthy();

      // If still on login, should be able to retry
      if (currentPage === 'login') {
        await authUtils.submitLoginForm();
        await page.waitForURL('**/dashboard**', { timeout: 15000 });

        const tokens = await authUtils.getAuthTokens();
        expect(tokens.accessToken).toBeTruthy();
      }

      console.log('✅ Network interruption handled gracefully');
    });

    test('should complete authentication within performance thresholds', async ({ page }) => {
      console.log('🧪 Testing authentication performance...');

      const startTime = Date.now();

      await page.goto(`${BASE_URL}/login`);
      await authUtils.fillLoginForm(TEST_USERS.publisher);
      await authUtils.submitLoginForm();
      await page.waitForURL('**/dashboard**', { timeout: 15000 });

      const endTime = Date.now();
      const totalTime = endTime - startTime;

      // Authentication should complete within 10 seconds under normal conditions
      expect(totalTime).toBeLessThan(10000);

      const tokens = await authUtils.getAuthTokens();
      expect(tokens.accessToken).toBeTruthy();

      console.log(`✅ Authentication performance test passed. Total time: ${totalTime}ms`);
    });
  });

  test.describe('Cross-Browser Authentication', () => {
    test('should work consistently across browser sessions', async ({ page, browser }) => {
      console.log('🧪 Testing cross-browser consistency...');

      // Login in first browser
      await page.goto(`${BASE_URL}/login`);
      await authUtils.fillLoginForm(TEST_USERS.publisher);
      await authUtils.submitLoginForm();
      await page.waitForURL('**/dashboard**', { timeout: 15000 });

      const tokens1 = await authUtils.getAuthTokens();
      expect(tokens1.accessToken).toBeTruthy();

      // Create new browser context (simulates different browser)
      const context2 = await browser.newContext();
      const page2 = await context2.newPage();
      const authUtils2 = new AuthTestUtils(page2);

      try {
        // Should not be authenticated in new context
        await page2.goto(`${BASE_URL}/dashboard`);
        await page2.waitForURL('**/login**', { timeout: 10000 });

        const currentPage = await authUtils2.detectCurrentPage();
        expect(currentPage).toBe('login');

        // Login should work in new context
        await authUtils2.fillLoginForm(TEST_USERS.publisher);
        await authUtils2.submitLoginForm();
        await page2.waitForURL('**/dashboard**', { timeout: 15000 });

        const tokens2 = await authUtils2.getAuthTokens();
        expect(tokens2.accessToken).toBeTruthy();

        console.log('✅ Cross-browser authentication working correctly');
      } finally {
        await context2.close();
      }
    });
  });
});