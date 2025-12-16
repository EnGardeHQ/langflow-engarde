/**
 * Debug Authentication Test for EnGarde Platform
 *
 * This test directly investigates authentication issues and connectivity problems.
 */

const { test, expect } = require('@playwright/test');

test.describe('Authentication Debug Tests', () => {

  test('should connect to frontend and identify login issues', async ({ page }) => {
    console.log('Testing frontend connectivity...');

    // Navigate directly with full URL to avoid baseURL issues
    await page.goto('http://localhost:3001/login');

    // Check if the page loads at all
    console.log('Page title:', await page.title());
    console.log('Page URL:', page.url());

    // Wait for the page to fully load
    await page.waitForLoadState('networkidle');

    // Check for loading states and actual form elements
    const bodyContent = await page.textContent('body');
    console.log('Page content includes "Loading":', bodyContent.includes('Loading'));

    // Take a screenshot for debugging
    await page.screenshot({ path: '/Users/cope/EnGardeHQ/playwright-testing/screenshots/login-page-debug.png', fullPage: true });

    // Look for any form elements with different selectors
    const forms = await page.locator('form').count();
    console.log('Number of forms found:', forms);

    // Check for input fields
    const inputs = await page.locator('input').count();
    console.log('Number of input fields found:', inputs);

    // Check for buttons
    const buttons = await page.locator('button').count();
    console.log('Number of buttons found:', buttons);

    // Look for specific text that might indicate the login form
    const hasSignIn = await page.locator('text=Sign In').count() > 0;
    const hasLogin = await page.locator('text=Login').count() > 0;
    const hasEmail = await page.locator('input[type="email"]').count() > 0;
    const hasPassword = await page.locator('input[type="password"]').count() > 0;

    console.log('Has "Sign In" text:', hasSignIn);
    console.log('Has "Login" text:', hasLogin);
    console.log('Has email input:', hasEmail);
    console.log('Has password input:', hasPassword);

    // Check for any error messages or console errors
    page.on('console', msg => console.log('Browser console:', msg.text()));
    page.on('pageerror', error => console.log('Page error:', error.message));

    // Check network requests
    page.on('request', request => {
      if (request.url().includes('api') || request.url().includes('auth')) {
        console.log('API Request:', request.method(), request.url());
      }
    });

    page.on('response', response => {
      if (response.url().includes('api') || response.url().includes('auth')) {
        console.log('API Response:', response.status(), response.url());
      }
    });

    // Try to find login form elements with various selectors
    const loginFormSelectors = [
      '[data-testid="login-form"]',
      '#login-form',
      '.login-form',
      'form[action*="login"]',
      'form[action*="auth"]',
      'form:has(input[type="email"])',
      'form:has(input[type="password"])'
    ];

    for (const selector of loginFormSelectors) {
      const elementCount = await page.locator(selector).count();
      console.log(`Selector "${selector}": ${elementCount} elements found`);
    }

    // Check if we can access the actual login page or if it's still loading
    await page.waitForTimeout(3000);

    // Take another screenshot after waiting
    await page.screenshot({ path: '/Users/cope/EnGardeHQ/playwright-testing/screenshots/login-page-after-wait.png', fullPage: true });

    // Try to interact with any email input we can find
    const emailInputs = await page.locator('input[type="email"], input[name="email"], input[placeholder*="email" i]').all();
    console.log('Found email inputs:', emailInputs.length);

    if (emailInputs.length > 0) {
      console.log('Attempting to fill email input...');
      try {
        await emailInputs[0].fill('admin@engarde.test');
        console.log('Successfully filled email input');
      } catch (error) {
        console.log('Error filling email input:', error.message);
      }
    }

    // Check for password inputs
    const passwordInputs = await page.locator('input[type="password"], input[name="password"]').all();
    console.log('Found password inputs:', passwordInputs.length);

    if (passwordInputs.length > 0) {
      console.log('Attempting to fill password input...');
      try {
        await passwordInputs[0].fill('admin123');
        console.log('Successfully filled password input');
      } catch (error) {
        console.log('Error filling password input:', error.message);
      }
    }

    // Look for submit buttons
    const submitButtons = await page.locator('button[type="submit"], input[type="submit"], button:has-text("Sign In"), button:has-text("Login")').all();
    console.log('Found submit buttons:', submitButtons.length);

    if (submitButtons.length > 0) {
      console.log('Attempting to click submit button...');
      try {
        await submitButtons[0].click();
        console.log('Successfully clicked submit button');

        // Wait for navigation or response
        await page.waitForTimeout(2000);
        console.log('Current URL after submit:', page.url());

        // Take screenshot after submit
        await page.screenshot({ path: '/Users/cope/EnGardeHQ/playwright-testing/screenshots/after-login-attempt.png', fullPage: true });

      } catch (error) {
        console.log('Error clicking submit button:', error.message);
      }
    }
  });

  test('should test backend API connectivity', async ({ page }) => {
    console.log('Testing backend API connectivity...');

    // Test direct API calls
    const apiUrls = [
      'http://localhost:8000/api/health',
      'http://localhost:8000/health',
      'http://localhost:8000/api/auth/login',
      'http://localhost:8000/auth/login',
      'http://localhost:8000/api/users',
      'http://localhost:8000/api/status'
    ];

    for (const url of apiUrls) {
      try {
        const response = await page.request.get(url);
        console.log(`${url}: ${response.status()} ${response.statusText()}`);

        if (response.status() !== 404) {
          const contentType = response.headers()['content-type'];
          console.log(`  Content-Type: ${contentType}`);

          try {
            const body = await response.text();
            console.log(`  Response: ${body.substring(0, 200)}...`);
          } catch (e) {
            console.log(`  Unable to read response body`);
          }
        }
      } catch (error) {
        console.log(`${url}: ERROR - ${error.message}`);
      }
    }
  });

  test('should test CORS and CSP issues', async ({ page }) => {
    console.log('Testing for CORS and CSP issues...');

    // Navigate to login page and monitor network failures
    const failedRequests = [];
    const corsErrors = [];
    const cspViolations = [];

    page.on('requestfailed', request => {
      failedRequests.push({
        url: request.url(),
        failure: request.failure()
      });
      console.log('Request failed:', request.url(), request.failure());
    });

    page.on('console', msg => {
      if (msg.text().includes('CORS') || msg.text().includes('Cross-Origin')) {
        corsErrors.push(msg.text());
        console.log('CORS Error:', msg.text());
      }
      if (msg.text().includes('Content Security Policy') || msg.text().includes('CSP')) {
        cspViolations.push(msg.text());
        console.log('CSP Violation:', msg.text());
      }
    });

    await page.goto('http://localhost:3001/login');
    await page.waitForTimeout(5000);

    console.log('Failed requests count:', failedRequests.length);
    console.log('CORS errors count:', corsErrors.length);
    console.log('CSP violations count:', cspViolations.length);
  });

});