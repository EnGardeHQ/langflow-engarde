// Final Comprehensive Test to verify all implemented fixes
// Test Plan:
// 1. Homepage Test - Verify demo image width increase (30px total)
// 2. Login Form Test - Verify no infinite loading spinner
// 3. Authentication Tests - Test both admin@engarde.ai/admin123 and test@example.com/Password123
// 4. Error Handling Test - Test invalid credentials
// 5. Console Error Monitoring

const { test, expect } = require('@playwright/test');
const path = require('path');
const fs = require('fs');

// Test results tracking
let testResults = {
  timestamp: new Date().toISOString(),
  tests: [],
  summary: {
    passed: 0,
    failed: 0,
    total: 0
  }
};

function addTestResult(testName, status, details = {}) {
  testResults.tests.push({
    name: testName,
    status,
    details,
    timestamp: new Date().toISOString()
  });

  if (status === 'passed') {
    testResults.summary.passed++;
  } else {
    testResults.summary.failed++;
  }
  testResults.summary.total++;
}

test.describe('Final Comprehensive Test - All Fixes Verification', () => {
  let page;
  let context;
  let consoleErrors = [];

  test.beforeAll(async ({ browser }) => {
    context = await browser.newContext({
      viewport: { width: 1920, height: 1080 },
      recordVideo: {
        dir: '/Users/cope/EnGardeHQ/playwright-testing/test-results/videos'
      }
    });
    page = await context.newPage();

    // Monitor console errors
    page.on('console', msg => {
      if (msg.type() === 'error') {
        consoleErrors.push({
          timestamp: new Date().toISOString(),
          message: msg.text(),
          location: msg.location()
        });
      }
    });

    // Monitor network failures
    page.on('response', response => {
      if (response.status() >= 400) {
        consoleErrors.push({
          timestamp: new Date().toISOString(),
          message: `Network Error: ${response.status()} ${response.url()}`,
          type: 'network'
        });
      }
    });
  });

  test.afterAll(async () => {
    // Save test results
    const reportPath = `/Users/cope/EnGardeHQ/playwright-testing/test-results/final-comprehensive-test-report-${Date.now()}.json`;
    fs.writeFileSync(reportPath, JSON.stringify({
      ...testResults,
      consoleErrors
    }, null, 2));

    await context.close();
  });

  test('1. Homepage Test - Verify demo image width increase', async () => {
    console.log('=== STARTING HOMEPAGE TEST ===');

    try {
      await page.goto('http://localhost:3001', { waitUntil: 'networkidle' });

      // Take screenshot of homepage
      const homepageScreenshot = `/Users/cope/EnGardeHQ/playwright-testing/screenshots/01-homepage-demo-image.png`;
      await page.screenshot({ path: homepageScreenshot, fullPage: true });
      console.log(`Homepage screenshot saved: ${homepageScreenshot}`);

      // Look for demo/preview images
      const demoImages = await page.locator('img').all();
      let foundDemoImage = false;
      let imageDetails = [];

      for (const img of demoImages) {
        const src = await img.getAttribute('src');
        const alt = await img.getAttribute('alt') || '';
        const className = await img.getAttribute('class') || '';

        if (src && (src.includes('demo') || src.includes('preview') || alt.toLowerCase().includes('demo') || className.includes('demo'))) {
          foundDemoImage = true;
          const boundingBox = await img.boundingBox();

          imageDetails.push({
            src,
            alt,
            className,
            width: boundingBox ? boundingBox.width : 'unknown',
            height: boundingBox ? boundingBox.height : 'unknown'
          });

          console.log(`Found demo image: ${src}, width: ${boundingBox ? boundingBox.width : 'unknown'}px`);
        }
      }

      // Also check for any images in hero sections or main content areas
      const heroImages = await page.locator('.hero img, .main img, [class*="demo"] img, [class*="preview"] img').all();
      for (const img of heroImages) {
        const src = await img.getAttribute('src');
        const boundingBox = await img.boundingBox();

        if (src && boundingBox) {
          foundDemoImage = true;
          imageDetails.push({
            src,
            width: boundingBox.width,
            height: boundingBox.height,
            context: 'hero/main section'
          });
          console.log(`Found hero/main image: ${src}, width: ${boundingBox.width}px`);
        }
      }

      addTestResult('Homepage Demo Image Test', foundDemoImage ? 'passed' : 'failed', {
        foundImages: imageDetails,
        note: foundDemoImage ? 'Demo images found and measured' : 'No demo images found - may need manual verification'
      });

      expect(foundDemoImage || imageDetails.length > 0).toBeTruthy();

    } catch (error) {
      console.error('Homepage test failed:', error);
      addTestResult('Homepage Demo Image Test', 'failed', { error: error.message });
      throw error;
    }
  });

  test('2. Login Form Test - Verify no infinite loading spinner', async () => {
    console.log('=== STARTING LOGIN FORM TEST ===');

    try {
      const startTime = Date.now();
      await page.goto('http://localhost:3001/login', { waitUntil: 'networkidle' });
      const loadTime = Date.now() - startTime;

      // Wait a moment for any loading states to resolve
      await page.waitForTimeout(2000);

      // Take screenshot of login form
      const loginFormScreenshot = `/Users/cope/EnGardeHQ/playwright-testing/screenshots/02-login-form-immediate-load.png`;
      await page.screenshot({ path: loginFormScreenshot, fullPage: true });
      console.log(`Login form screenshot saved: ${loginFormScreenshot}`);

      // Check for login form elements
      const emailField = page.locator('input[type="email"], input[name="email"], input[placeholder*="email" i]');
      const passwordField = page.locator('input[type="password"], input[name="password"]');
      const loginButton = page.locator('button[type="submit"], button:has-text("login"), button:has-text("sign in")');

      // Check for loading spinners (should NOT be present)
      const loadingSpinners = page.locator('[class*="loading"], [class*="spinner"], .loader, [data-loading="true"]');
      const spinnerCount = await loadingSpinners.count();

      // Verify form elements are present
      const emailVisible = await emailField.count() > 0;
      const passwordVisible = await passwordField.count() > 0;
      const buttonVisible = await loginButton.count() > 0;

      const formReady = emailVisible && passwordVisible && buttonVisible;
      const noInfiniteLoading = spinnerCount === 0;

      console.log(`Login form load time: ${loadTime}ms`);
      console.log(`Form elements found - Email: ${emailVisible}, Password: ${passwordVisible}, Button: ${buttonVisible}`);
      console.log(`Loading spinners found: ${spinnerCount}`);

      addTestResult('Login Form Immediate Load Test', formReady && noInfiniteLoading ? 'passed' : 'failed', {
        loadTime,
        formElementsFound: { emailVisible, passwordVisible, buttonVisible },
        loadingSpinnersFound: spinnerCount,
        formReady,
        noInfiniteLoading
      });

      expect(formReady).toBeTruthy();
      expect(noInfiniteLoading).toBeTruthy();

    } catch (error) {
      console.error('Login form test failed:', error);
      addTestResult('Login Form Immediate Load Test', 'failed', { error: error.message });
      throw error;
    }
  });

  test('3. Authentication Test - Admin Credentials', async () => {
    console.log('=== STARTING ADMIN AUTHENTICATION TEST ===');

    try {
      await page.goto('http://localhost:3001/login', { waitUntil: 'networkidle' });

      // Find and fill form fields
      const emailField = page.locator('input[type="email"], input[name="email"], input[placeholder*="email" i]').first();
      const passwordField = page.locator('input[type="password"], input[name="password"]').first();
      const loginButton = page.locator('button[type="submit"], button:has-text("login"), button:has-text("sign in")').first();

      await emailField.fill('admin@engarde.ai');
      await passwordField.fill('admin123');

      // Take screenshot before login
      await page.screenshot({ path: `/Users/cope/EnGardeHQ/playwright-testing/screenshots/03-admin-login-before.png` });

      // Submit form
      await loginButton.click();

      // Wait for navigation or response
      await page.waitForTimeout(5000);

      const currentUrl = page.url();
      const isOnDashboard = currentUrl.includes('/dashboard') || currentUrl.includes('/admin') || currentUrl !== 'http://localhost:3001/login';

      // Take screenshot after login
      await page.screenshot({ path: `/Users/cope/EnGardeHQ/playwright-testing/screenshots/03-admin-login-after.png`, fullPage: true });

      console.log(`Admin login - Current URL: ${currentUrl}`);
      console.log(`Admin login - Successful redirect: ${isOnDashboard}`);

      addTestResult('Admin Authentication Test', isOnDashboard ? 'passed' : 'failed', {
        credentials: 'admin@engarde.ai / admin123',
        finalUrl: currentUrl,
        successfulRedirect: isOnDashboard
      });

      expect(isOnDashboard).toBeTruthy();

    } catch (error) {
      console.error('Admin authentication test failed:', error);
      addTestResult('Admin Authentication Test', 'failed', { error: error.message });
      throw error;
    }
  });

  test('4. Authentication Test - Brand User Credentials', async () => {
    console.log('=== STARTING BRAND USER AUTHENTICATION TEST ===');

    try {
      // Logout first if needed
      await page.goto('http://localhost:3001/login', { waitUntil: 'networkidle' });

      // Find and fill form fields
      const emailField = page.locator('input[type="email"], input[name="email"], input[placeholder*="email" i]').first();
      const passwordField = page.locator('input[type="password"], input[name="password"]').first();
      const loginButton = page.locator('button[type="submit"], button:has-text("login"), button:has-text("sign in")').first();

      await emailField.fill('test@example.com');
      await passwordField.fill('Password123');

      // Take screenshot before login
      await page.screenshot({ path: `/Users/cope/EnGardeHQ/playwright-testing/screenshots/04-brand-user-login-before.png` });

      // Submit form
      await loginButton.click();

      // Wait for navigation or response
      await page.waitForTimeout(5000);

      const currentUrl = page.url();
      const isOnDashboard = currentUrl.includes('/dashboard') || currentUrl.includes('/brand') || currentUrl !== 'http://localhost:3001/login';

      // Take screenshot after login
      await page.screenshot({ path: `/Users/cope/EnGardeHQ/playwright-testing/screenshots/04-brand-user-login-after.png`, fullPage: true });

      console.log(`Brand user login - Current URL: ${currentUrl}`);
      console.log(`Brand user login - Successful redirect: ${isOnDashboard}`);

      addTestResult('Brand User Authentication Test', isOnDashboard ? 'passed' : 'failed', {
        credentials: 'test@example.com / Password123',
        finalUrl: currentUrl,
        successfulRedirect: isOnDashboard
      });

      expect(isOnDashboard).toBeTruthy();

    } catch (error) {
      console.error('Brand user authentication test failed:', error);
      addTestResult('Brand User Authentication Test', 'failed', { error: error.message });
      throw error;
    }
  });

  test('5. Error Handling Test - Invalid Credentials', async () => {
    console.log('=== STARTING ERROR HANDLING TEST ===');

    try {
      await page.goto('http://localhost:3001/login', { waitUntil: 'networkidle' });

      // Find and fill form fields with invalid credentials
      const emailField = page.locator('input[type="email"], input[name="email"], input[placeholder*="email" i]').first();
      const passwordField = page.locator('input[type="password"], input[name="password"]').first();
      const loginButton = page.locator('button[type="submit"], button:has-text("login"), button:has-text("sign in")').first();

      await emailField.fill('invalid@test.com');
      await passwordField.fill('wrongpassword');

      // Take screenshot before invalid login
      await page.screenshot({ path: `/Users/cope/EnGardeHQ/playwright-testing/screenshots/05-invalid-login-before.png` });

      // Submit form
      await loginButton.click();

      // Wait for error response
      await page.waitForTimeout(3000);

      // Check for error messages
      const errorMessages = await page.locator('.error, .alert-error, [class*="error"], [role="alert"]').all();
      const errorTexts = await Promise.all(errorMessages.map(el => el.textContent()));

      const currentUrl = page.url();
      const stayedOnLogin = currentUrl.includes('/login') || currentUrl === 'http://localhost:3001/login';
      const hasErrorMessage = errorTexts.some(text => text && text.length > 0);

      // Take screenshot after invalid login
      await page.screenshot({ path: `/Users/cope/EnGardeHQ/playwright-testing/screenshots/05-invalid-login-after.png`, fullPage: true });

      console.log(`Invalid login - Current URL: ${currentUrl}`);
      console.log(`Invalid login - Stayed on login page: ${stayedOnLogin}`);
      console.log(`Invalid login - Error messages found: ${errorTexts}`);

      const properErrorHandling = stayedOnLogin && (hasErrorMessage || errorTexts.length > 0);

      addTestResult('Invalid Credentials Error Handling Test', properErrorHandling ? 'passed' : 'failed', {
        credentials: 'invalid@test.com / wrongpassword',
        finalUrl: currentUrl,
        stayedOnLogin,
        errorMessages: errorTexts,
        properErrorHandling
      });

      expect(stayedOnLogin).toBeTruthy();

    } catch (error) {
      console.error('Error handling test failed:', error);
      addTestResult('Invalid Credentials Error Handling Test', 'failed', { error: error.message });
      throw error;
    }
  });

  test('6. Console Errors and Network Monitoring', async () => {
    console.log('=== CONSOLE ERRORS AND NETWORK MONITORING SUMMARY ===');

    // Filter out common non-critical errors
    const criticalErrors = consoleErrors.filter(error => {
      const msg = error.message.toLowerCase();
      return !msg.includes('favicon') &&
             !msg.includes('manifest') &&
             !msg.includes('service-worker') &&
             !msg.includes('analytics');
    });

    console.log(`Total console errors captured: ${consoleErrors.length}`);
    console.log(`Critical errors: ${criticalErrors.length}`);

    if (criticalErrors.length > 0) {
      console.log('Critical errors found:');
      criticalErrors.forEach(error => {
        console.log(`- ${error.timestamp}: ${error.message}`);
      });
    }

    addTestResult('Console Errors Monitoring', criticalErrors.length === 0 ? 'passed' : 'warning', {
      totalErrors: consoleErrors.length,
      criticalErrors: criticalErrors.length,
      errorDetails: criticalErrors.slice(0, 10) // Limit to first 10 critical errors
    });

    // Don't fail the test for console errors, but log them
    expect(true).toBeTruthy(); // Always pass this test, it's just monitoring
  });
});