/**
 * Comprehensive Authentication Analysis for EnGarde Platform
 *
 * This test thoroughly investigates all aspects of the authentication system
 * to identify root causes of login failures.
 */

const { test, expect } = require('@playwright/test');

test.describe('Comprehensive Authentication Analysis', () => {

  test('should analyze complete authentication flow and identify blocking issues', async ({ page }) => {
    console.log('=== COMPREHENSIVE AUTHENTICATION ANALYSIS ===\n');

    // Set up request/response monitoring
    const networkRequests = [];
    const networkResponses = [];
    const consoleMessages = [];
    const errors = [];

    page.on('request', request => {
      networkRequests.push({
        url: request.url(),
        method: request.method(),
        headers: request.headers(),
        postData: request.postDataJSON() || request.postData()
      });
    });

    page.on('response', response => {
      networkResponses.push({
        url: response.url(),
        status: response.status(),
        headers: response.headers()
      });
    });

    page.on('console', msg => consoleMessages.push(msg.text()));
    page.on('pageerror', error => errors.push(error.message));

    console.log('1. FRONTEND CONNECTIVITY TEST');
    console.log('==============================');

    try {
      await page.goto('http://localhost:3001/login');
      await page.waitForLoadState('networkidle');

      console.log('✓ Frontend accessible at http://localhost:3001/login');
      console.log(`✓ Page title: ${await page.title()}`);
      console.log(`✓ Current URL: ${page.url()}`);

    } catch (error) {
      console.log(`✗ Frontend connection failed: ${error.message}`);
    }

    console.log('\n2. LOGIN FORM ANALYSIS');
    console.log('======================');

    // Wait for any async loading to complete
    await page.waitForTimeout(3000);

    // Check if page is still loading
    const isLoading = await page.locator('text=Loading').count() > 0;
    console.log(`Loading state: ${isLoading ? 'Still loading' : 'Completed'}`);

    // Screenshot current state
    await page.screenshot({
      path: '/Users/cope/EnGardeHQ/playwright-testing/screenshots/auth-analysis-initial.png',
      fullPage: true
    });

    // Analyze form elements
    const formElements = {
      forms: await page.locator('form').count(),
      emailInputs: await page.locator('input[type="email"], input[name="email"], input[placeholder*="email" i]').count(),
      passwordInputs: await page.locator('input[type="password"], input[name="password"]').count(),
      submitButtons: await page.locator('button[type="submit"], input[type="submit"], button:has-text("Sign In"), button:has-text("Login")').count()
    };

    console.log('Form elements found:');
    Object.entries(formElements).forEach(([key, value]) => {
      console.log(`  ${key}: ${value}`);
    });

    // Check for specific login form selectors
    const loginSelectors = [
      '[data-testid="login-form"]',
      '[data-testid="email-input"]',
      '[data-testid="password-input"]',
      '[data-testid="login-button"]'
    ];

    console.log('\nTest-specific selectors:');
    for (const selector of loginSelectors) {
      const count = await page.locator(selector).count();
      console.log(`  ${selector}: ${count > 0 ? '✓ Found' : '✗ Missing'}`);
    }

    console.log('\n3. AUTHENTICATION ATTEMPT');
    console.log('==========================');

    // Clear previous network logs
    networkRequests.length = 0;
    networkResponses.length = 0;

    // Try to fill and submit the login form
    try {
      const emailInputs = await page.locator('input[type="email"], input[name="email"]').all();
      const passwordInputs = await page.locator('input[type="password"], input[name="password"]').all();
      const submitButtons = await page.locator('button[type="submit"], button:has-text("Sign In"), button:has-text("Login")').all();

      if (emailInputs.length > 0 && passwordInputs.length > 0 && submitButtons.length > 0) {
        console.log('Attempting to fill login form...');

        await emailInputs[0].fill('admin@example.com');
        await passwordInputs[0].fill('admin123');

        console.log('Form filled, attempting to submit...');
        await submitButtons[0].click();

        // Wait for network activity
        await page.waitForTimeout(3000);

        console.log('✓ Form submission attempted');
      } else {
        console.log('✗ Login form elements not found or not ready');
      }
    } catch (error) {
      console.log(`✗ Form submission failed: ${error.message}`);
    }

    console.log('\n4. NETWORK ANALYSIS');
    console.log('===================');

    console.log('Authentication-related requests:');
    const authRequests = networkRequests.filter(req =>
      req.url.includes('token') ||
      req.url.includes('auth') ||
      req.url.includes('login') ||
      req.method === 'POST'
    );

    authRequests.forEach(req => {
      console.log(`  ${req.method} ${req.url}`);
      if (req.postData) {
        console.log(`    Data: ${JSON.stringify(req.postData)}`);
      }
    });

    console.log('\nAuthentication-related responses:');
    const authResponses = networkResponses.filter(res =>
      res.url.includes('token') ||
      res.url.includes('auth') ||
      res.url.includes('login')
    );

    authResponses.forEach(res => {
      console.log(`  ${res.status} ${res.url}`);
    });

    console.log('\n5. CSP AND SECURITY ANALYSIS');
    console.log('=============================');

    const cspViolations = consoleMessages.filter(msg =>
      msg.includes('Content Security Policy') ||
      msg.includes('CSP') ||
      msg.includes('Refused to connect')
    );

    console.log(`CSP violations found: ${cspViolations.length}`);
    cspViolations.forEach(violation => {
      console.log(`  ${violation}`);
    });

    const corsErrors = consoleMessages.filter(msg =>
      msg.includes('CORS') ||
      msg.includes('Cross-Origin')
    );

    console.log(`CORS errors found: ${corsErrors.length}`);
    corsErrors.forEach(error => {
      console.log(`  ${error}`);
    });

    console.log('\n6. ERROR ANALYSIS');
    console.log('=================');

    console.log(`JavaScript errors found: ${errors.length}`);
    errors.forEach(error => {
      console.log(`  ${error}`);
    });

    console.log(`Console messages: ${consoleMessages.length}`);

    console.log('\n7. BACKEND ENDPOINT VERIFICATION');
    console.log('=================================');

    // Test backend endpoints directly
    const endpointsToTest = [
      'http://localhost:8000/health',
      'http://localhost:8000/token',
      'http://localhost:8000/users/'
    ];

    for (const endpoint of endpointsToTest) {
      try {
        const response = await page.request.get(endpoint);
        console.log(`  ${endpoint}: ${response.status()} ${response.statusText()}`);
      } catch (error) {
        console.log(`  ${endpoint}: ERROR - ${error.message}`);
      }
    }

    // Test POST to token endpoint
    try {
      const tokenResponse = await page.request.post('http://localhost:8000/token', {
        form: {
          grant_type: 'password',
          username: 'admin@example.com',
          password: 'admin123'
        }
      });
      console.log(`  POST /token: ${tokenResponse.status()} ${tokenResponse.statusText()}`);
      const tokenBody = await tokenResponse.text();
      console.log(`    Response: ${tokenBody}`);
    } catch (error) {
      console.log(`  POST /token: ERROR - ${error.message}`);
    }

    console.log('\n8. SUMMARY AND RECOMMENDATIONS');
    console.log('===============================');

    // Final screenshot
    await page.screenshot({
      path: '/Users/cope/EnGardeHQ/playwright-testing/screenshots/auth-analysis-final.png',
      fullPage: true
    });

    console.log('Analysis complete. Check screenshots for visual verification.');
  });

  test('should test user creation and authentication flow', async ({ page }) => {
    console.log('\n=== USER CREATION AND AUTHENTICATION TEST ===\n');

    // Test user creation first
    console.log('1. TESTING USER CREATION');
    console.log('=========================');

    const testUsers = [
      {
        email: 'testadmin@gmail.com',
        password: 'admin123',
        first_name: 'Test',
        last_name: 'Admin'
      },
      {
        email: 'testcoach@gmail.com',
        password: 'coach123',
        first_name: 'Test',
        last_name: 'Coach'
      }
    ];

    for (const user of testUsers) {
      try {
        const response = await page.request.post('http://localhost:8000/users/', {
          data: user
        });

        console.log(`  Creating ${user.email}: ${response.status()} ${response.statusText()}`);

        if (response.status() !== 200) {
          const errorBody = await response.text();
          console.log(`    Error: ${errorBody}`);
        } else {
          const userResponse = await response.json();
          console.log(`    ✓ User created with ID: ${userResponse.id || 'Unknown'}`);
        }
      } catch (error) {
        console.log(`  Creating ${user.email}: ERROR - ${error.message}`);
      }
    }

    console.log('\n2. TESTING AUTHENTICATION WITH CREATED USERS');
    console.log('==============================================');

    for (const user of testUsers) {
      try {
        const response = await page.request.post('http://localhost:8000/token', {
          form: {
            grant_type: 'password',
            username: user.email,
            password: user.password
          }
        });

        console.log(`  Authenticating ${user.email}: ${response.status()} ${response.statusText()}`);

        if (response.status() === 200) {
          const tokenData = await response.json();
          console.log(`    ✓ Authentication successful`);
          console.log(`    Token type: ${tokenData.token_type || 'Unknown'}`);
          console.log(`    Access token: ${tokenData.access_token ? 'Present' : 'Missing'}`);
        } else {
          const errorBody = await response.text();
          console.log(`    ✗ Authentication failed: ${errorBody}`);
        }
      } catch (error) {
        console.log(`  Authenticating ${user.email}: ERROR - ${error.message}`);
      }
    }
  });

});