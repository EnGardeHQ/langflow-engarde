const { test, expect } = require('@playwright/test');

/**
 * Login Loop Detection and Prevention Tests
 * Specifically tests for and prevents infinite redirect loops
 */

const BASE_URL = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3001';
const API_BASE_URL = process.env.PLAYWRIGHT_API_URL || 'http://localhost:8000';

// Test user for login loop tests
const TEST_USER = {
  email: 'publisher@test.com',
  password: 'TestPassword123!',
  userType: 'publisher'
};

class LoginLoopDetector {
  constructor(page) {
    this.page = page;
    this.redirectHistory = [];
    this.networkActivity = [];
    this.authStateChanges = [];
    this.pageNavigations = [];
  }

  startMonitoring() {
    // Track all redirects
    this.page.on('response', (response) => {
      if ([301, 302, 303, 307, 308].includes(response.status())) {
        const redirect = {
          from: response.url(),
          to: response.headers()['location'],
          status: response.status(),
          timestamp: Date.now()
        };
        this.redirectHistory.push(redirect);
        console.log('🔄 REDIRECT:', redirect);
      }
    });

    // Track all navigation events
    this.page.on('framenavigated', (frame) => {
      if (frame === this.page.mainFrame()) {
        const navigation = {
          url: frame.url(),
          timestamp: Date.now()
        };
        this.pageNavigations.push(navigation);
        console.log('🧭 NAVIGATION:', navigation);
      }
    });

    // Track auth-related network requests
    this.page.on('request', (request) => {
      if (request.url().includes('/api/auth/') || request.url().includes('/api/me')) {
        this.networkActivity.push({
          type: 'request',
          url: request.url(),
          method: request.method(),
          timestamp: Date.now()
        });
      }
    });

    this.page.on('response', (response) => {
      if (response.url().includes('/api/auth/') || response.url().includes('/api/me')) {
        this.networkActivity.push({
          type: 'response',
          url: response.url(),
          status: response.status(),
          timestamp: Date.now()
        });
      }
    });

    // Monitor localStorage changes
    this.page.evaluateOnNewDocument(() => {
      const originalSetItem = localStorage.setItem;
      const originalRemoveItem = localStorage.removeItem;
      const originalClear = localStorage.clear;

      window._authStateChanges = window._authStateChanges || [];

      localStorage.setItem = function(key, value) {
        if (key.includes('engarde')) {
          window._authStateChanges.push({
            action: 'set',
            key,
            value,
            timestamp: Date.now()
          });
        }
        return originalSetItem.apply(this, arguments);
      };

      localStorage.removeItem = function(key) {
        if (key.includes('engarde')) {
          window._authStateChanges.push({
            action: 'remove',
            key,
            timestamp: Date.now()
          });
        }
        return originalRemoveItem.apply(this, arguments);
      };

      localStorage.clear = function() {
        window._authStateChanges.push({
          action: 'clear',
          timestamp: Date.now()
        });
        return originalClear.apply(this, arguments);
      };
    });
  }

  async getAuthStateChanges() {
    const changes = await this.page.evaluate(() => window._authStateChanges || []);
    this.authStateChanges = changes;
    return changes;
  }

  analyzeForLoops() {
    const analysis = {
      hasRedirectLoop: false,
      hasNavigationLoop: false,
      hasAuthStateLoop: false,
      redirectLoopDetails: null,
      navigationLoopDetails: null,
      authStateLoopDetails: null,
      summary: {}
    };

    // Analyze redirect loops
    const redirectUrls = this.redirectHistory.map(r => r.from);
    const redirectCounts = {};
    redirectUrls.forEach(url => {
      redirectCounts[url] = (redirectCounts[url] || 0) + 1;
    });

    const loopingRedirects = Object.entries(redirectCounts).filter(([url, count]) => count > 2);
    if (loopingRedirects.length > 0) {
      analysis.hasRedirectLoop = true;
      analysis.redirectLoopDetails = {
        loopingUrls: loopingRedirects,
        totalRedirects: this.redirectHistory.length,
        redirectChain: this.redirectHistory
      };
    }

    // Analyze navigation loops
    const navigationUrls = this.pageNavigations.map(n => n.url);
    const navigationCounts = {};
    navigationUrls.forEach(url => {
      navigationCounts[url] = (navigationCounts[url] || 0) + 1;
    });

    const loopingNavigations = Object.entries(navigationCounts).filter(([url, count]) => count > 3);
    if (loopingNavigations.length > 0) {
      analysis.hasNavigationLoop = true;
      analysis.navigationLoopDetails = {
        loopingUrls: loopingNavigations,
        totalNavigations: this.pageNavigations.length,
        navigationChain: this.pageNavigations
      };
    }

    // Analyze auth state changes for loops
    const authChanges = this.authStateChanges;
    const tokenSets = authChanges.filter(c => c.action === 'set' && c.key === 'engarde_access_token');
    const tokenRemoves = authChanges.filter(c => c.action === 'remove' && c.key === 'engarde_access_token');

    if (tokenSets.length > 2 || tokenRemoves.length > 2) {
      analysis.hasAuthStateLoop = true;
      analysis.authStateLoopDetails = {
        tokenSets: tokenSets.length,
        tokenRemoves: tokenRemoves.length,
        authChanges: authChanges
      };
    }

    // Create summary
    analysis.summary = {
      totalRedirects: this.redirectHistory.length,
      totalNavigations: this.pageNavigations.length,
      totalNetworkRequests: this.networkActivity.filter(a => a.type === 'request').length,
      totalAuthStateChanges: this.authStateChanges.length,
      hasAnyLoop: analysis.hasRedirectLoop || analysis.hasNavigationLoop || analysis.hasAuthStateLoop
    };

    return analysis;
  }

  async waitForPageLoad(timeout = 10000) {
    await this.page.waitForLoadState('networkidle', { timeout });
    await this.page.waitForTimeout(500);
  }

  async clearAuthState() {
    await this.page.evaluate(() => {
      localStorage.clear();
      sessionStorage.clear();
      document.cookie.split(";").forEach(function(c) {
        document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/");
      });
      if (window._authStateChanges) {
        window._authStateChanges = [];
      }
    });
  }

  async fillAndSubmitLogin() {
    await this.page.fill('[data-testid="email-input"], input[type="email"], input[name="email"]', TEST_USER.email);
    await this.page.fill('[data-testid="password-input"], input[type="password"], input[name="password"]', TEST_USER.password);

    // Select user type if available
    const userTypeSelector = await this.page.$('[data-testid="user-type-select"], select[name="userType"]');
    if (userTypeSelector) {
      await this.page.selectOption('[data-testid="user-type-select"], select[name="userType"]', TEST_USER.userType);
    }

    // Submit the form
    const submitButton = await this.page.$('[data-testid="login-submit"], button[type="submit"], button:has-text("Login")');
    if (submitButton) {
      await submitButton.click();
    } else {
      await this.page.keyboard.press('Enter');
    }
  }

  async getCurrentPageType() {
    const url = this.page.url().toLowerCase();
    if (url.includes('/login')) return 'login';
    if (url.includes('/dashboard')) return 'dashboard';
    if (url.includes('/home') || url === BASE_URL + '/') return 'home';
    if (url.includes('/onboarding')) return 'onboarding';
    return 'unknown';
  }
}

test.describe('Login Loop Detection and Prevention', () => {
  let loopDetector;

  test.beforeEach(async ({ page }) => {
    loopDetector = new LoginLoopDetector(page);
    loopDetector.startMonitoring();
    await loopDetector.clearAuthState();
    await page.goto(BASE_URL);
    await loopDetector.waitForPageLoad();
  });

  test.afterEach(async ({ page }) => {
    // Get final auth state changes
    await loopDetector.getAuthStateChanges();

    // Analyze for loops
    const analysis = loopDetector.analyzeForLoops();
    console.log('🔍 Loop Analysis:', JSON.stringify(analysis, null, 2));

    // Report any detected loops
    if (analysis.hasAnyLoop) {
      console.error('🚨 LOOP DETECTED:', analysis);
    }
  });

  test('should complete login without redirect loops', async ({ page }) => {
    console.log('🧪 Testing login completion without redirect loops...');

    // Start timing
    const startTime = Date.now();

    // Navigate to login and perform login
    await page.goto(`${BASE_URL}/login`);
    await loopDetector.waitForPageLoad();

    await loopDetector.fillAndSubmitLogin();

    // Wait for final destination (with reasonable timeout)
    try {
      await page.waitForURL('**/dashboard**', { timeout: 15000 });
    } catch (error) {
      console.log('⚠️ Did not reach dashboard, checking current location...');
      const currentPage = await loopDetector.getCurrentPageType();
      console.log('Current page type:', currentPage);

      // If not on dashboard, check if we're stuck in a loop
      if (currentPage === 'login') {
        console.error('🚨 POTENTIAL LOGIN LOOP: Still on login page after submission');
      }
    }

    const endTime = Date.now();
    const totalTime = endTime - startTime;

    // Get auth state changes
    await loopDetector.getAuthStateChanges();

    // Analyze the journey
    const analysis = loopDetector.analyzeForLoops();

    // Assertions
    expect(analysis.hasRedirectLoop).toBe(false);
    expect(analysis.hasNavigationLoop).toBe(false);
    expect(analysis.summary.totalRedirects).toBeLessThan(5); // Max 4 redirects
    expect(totalTime).toBeLessThan(20000); // Max 20 seconds

    // Should end up authenticated
    const finalPageType = await loopDetector.getCurrentPageType();
    expect(['dashboard', 'home'].includes(finalPageType)).toBeTruthy();

    console.log(`✅ Login completed without loops in ${totalTime}ms`);
    console.log(`Final destination: ${finalPageType}`);
    console.log(`Total redirects: ${analysis.summary.totalRedirects}`);
    console.log(`Total navigations: ${analysis.summary.totalNavigations}`);
  });

  test('should not create loops when accessing protected routes while unauthenticated', async ({ page }) => {
    console.log('🧪 Testing protected route access without authentication...');

    // Try to access dashboard without authentication
    await page.goto(`${BASE_URL}/dashboard`);
    await loopDetector.waitForPageLoad();

    // Should redirect to login
    await page.waitForTimeout(3000);
    const currentPage = await loopDetector.getCurrentPageType();
    expect(currentPage).toBe('login');

    // Get auth state changes
    await loopDetector.getAuthStateChanges();

    // Analyze for loops
    const analysis = loopDetector.analyzeForLoops();

    // Should not have created any loops
    expect(analysis.hasRedirectLoop).toBe(false);
    expect(analysis.hasNavigationLoop).toBe(false);
    expect(analysis.summary.totalRedirects).toBeLessThan(3);

    console.log('✅ Protected route access handled without loops');
  });

  test('should prevent loops when session expires', async ({ page }) => {
    console.log('🧪 Testing session expiration handling...');

    // First, login successfully
    await page.goto(`${BASE_URL}/login`);
    await loopDetector.fillAndSubmitLogin();
    await page.waitForURL('**/dashboard**', { timeout: 15000 });

    // Verify we're authenticated
    let pageType = await loopDetector.getCurrentPageType();
    expect(pageType).toBe('dashboard');

    // Clear tracking data from login
    loopDetector.redirectHistory = [];
    loopDetector.pageNavigations = [];
    loopDetector.networkActivity = [];

    // Simulate session expiration by invalidating the token
    await page.evaluate(() => {
      localStorage.setItem('engarde_access_token', 'expired.token.here');
    });

    // Try to access a protected page or refresh
    await page.reload();
    await loopDetector.waitForPageLoad();

    // Should redirect to login without loops
    await page.waitForTimeout(5000);
    pageType = await loopDetector.getCurrentPageType();
    expect(['login', 'dashboard'].includes(pageType)).toBeTruthy();

    // Get auth state changes
    await loopDetector.getAuthStateChanges();

    // Analyze for loops
    const analysis = loopDetector.analyzeForLoops();

    // Should not create loops when handling expired sessions
    expect(analysis.hasRedirectLoop).toBe(false);
    expect(analysis.hasNavigationLoop).toBe(false);

    console.log('✅ Session expiration handled without loops');
  });

  test('should handle multiple rapid navigation attempts', async ({ page }) => {
    console.log('🧪 Testing rapid navigation attempts...');

    // Try to navigate to multiple protected routes rapidly
    const routes = ['/dashboard', '/profile', '/settings', '/admin'];

    for (const route of routes) {
      try {
        await page.goto(`${BASE_URL}${route}`);
        await page.waitForTimeout(500); // Brief pause between navigations
      } catch (error) {
        console.log(`Navigation to ${route} failed:`, error.message);
      }
    }

    // Wait for all navigations to settle
    await loopDetector.waitForPageLoad();

    // Should end up on login page
    const currentPage = await loopDetector.getCurrentPageType();
    expect(currentPage).toBe('login');

    // Get auth state changes
    await loopDetector.getAuthStateChanges();

    // Analyze for loops
    const analysis = loopDetector.analyzeForLoops();

    // Should handle multiple navigations without creating loops
    expect(analysis.hasRedirectLoop).toBe(false);
    expect(analysis.hasNavigationLoop).toBe(false);
    expect(analysis.summary.totalRedirects).toBeLessThan(10);

    console.log('✅ Rapid navigation attempts handled without loops');
  });

  test('should detect and prevent infinite redirect loops', async ({ page }) => {
    console.log('🧪 Testing infinite redirect loop detection...');

    // Set up a scenario that could cause loops by manipulating the auth state
    await page.evaluateOnNewDocument(() => {
      // Override router to simulate problematic redirects
      let redirectCount = 0;
      const originalPushState = history.pushState;
      const originalReplaceState = history.replaceState;

      history.pushState = function(...args) {
        redirectCount++;
        console.log(`Redirect ${redirectCount}:`, args[2]);

        // Prevent excessive redirects (circuit breaker)
        if (redirectCount > 10) {
          console.error('🚨 Circuit breaker: Too many redirects detected');
          return;
        }

        return originalPushState.apply(this, args);
      };

      history.replaceState = function(...args) {
        redirectCount++;
        console.log(`Replace ${redirectCount}:`, args[2]);

        // Prevent excessive redirects (circuit breaker)
        if (redirectCount > 10) {
          console.error('🚨 Circuit breaker: Too many redirects detected');
          return;
        }

        return originalReplaceState.apply(this, args);
      };
    });

    // Try to login
    await page.goto(`${BASE_URL}/login`);
    await loopDetector.fillAndSubmitLogin();

    // Wait with extended timeout to see if loops are prevented
    await page.waitForTimeout(10000);

    // Get auth state changes
    await loopDetector.getAuthStateChanges();

    // Analyze for loops
    const analysis = loopDetector.analyzeForLoops();

    // The application should have circuit breakers to prevent infinite loops
    expect(analysis.summary.totalRedirects).toBeLessThan(15);
    expect(analysis.summary.totalNavigations).toBeLessThan(20);

    // Should not be stuck in an infinite loop
    const currentPage = await loopDetector.getCurrentPageType();
    expect(['login', 'dashboard', 'home'].includes(currentPage)).toBeTruthy();

    console.log('✅ Infinite redirect loop prevention verified');
  });

  test('should handle browser back/forward during authentication', async ({ page }) => {
    console.log('🧪 Testing browser back/forward during authentication...');

    // Navigate through a sequence
    await page.goto(`${BASE_URL}/`);
    await loopDetector.waitForPageLoad();

    await page.goto(`${BASE_URL}/login`);
    await loopDetector.waitForPageLoad();

    // Start login process
    await loopDetector.fillAndSubmitLogin();
    await page.waitForTimeout(1000);

    // Use browser back during authentication
    await page.goBack();
    await page.waitForTimeout(1000);

    // Try to go forward
    await page.goForward();
    await page.waitForTimeout(1000);

    // Complete login process
    const currentPage = await loopDetector.getCurrentPageType();
    if (currentPage === 'login') {
      await loopDetector.fillAndSubmitLogin();
      await page.waitForTimeout(3000);
    }

    // Get final auth state changes
    await loopDetector.getAuthStateChanges();

    // Analyze for loops
    const analysis = loopDetector.analyzeForLoops();

    // Should handle browser navigation without creating loops
    expect(analysis.hasRedirectLoop).toBe(false);
    expect(analysis.hasNavigationLoop).toBe(false);

    console.log('✅ Browser back/forward handling verified');
  });

  test('should recover from authentication state corruption', async ({ page }) => {
    console.log('🧪 Testing recovery from auth state corruption...');

    // Login first
    await page.goto(`${BASE_URL}/login`);
    await loopDetector.fillAndSubmitLogin();
    await page.waitForURL('**/dashboard**', { timeout: 15000 });

    // Corrupt the authentication state
    await page.evaluate(() => {
      // Set conflicting auth states
      localStorage.setItem('engarde_access_token', 'valid-looking-token');
      localStorage.setItem('engarde_refresh_token', 'another-token');
      localStorage.setItem('engarde_user', '{"invalid": "json}'); // Invalid JSON
      sessionStorage.setItem('engarde_login_success', 'false');
      sessionStorage.setItem('engarde_redirect_path', '/login');
    });

    // Clear tracking data
    loopDetector.redirectHistory = [];
    loopDetector.pageNavigations = [];

    // Try to navigate to dashboard with corrupted state
    await page.goto(`${BASE_URL}/dashboard`);
    await loopDetector.waitForPageLoad();

    // Wait for the app to handle the corruption
    await page.waitForTimeout(5000);

    // Get auth state changes
    await loopDetector.getAuthStateChanges();

    // Analyze for loops
    const analysis = loopDetector.analyzeForLoops();

    // Should recover without creating loops
    expect(analysis.hasRedirectLoop).toBe(false);
    expect(analysis.hasNavigationLoop).toBe(false);

    // Should either be on login (state cleared) or dashboard (state recovered)
    const finalPage = await loopDetector.getCurrentPageType();
    expect(['login', 'dashboard'].includes(finalPage)).toBeTruthy();

    console.log(`✅ Auth state corruption recovered, final page: ${finalPage}`);
  });
});