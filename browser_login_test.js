#!/usr/bin/env node

/**
 * Browser-based Login Test for EnGarde Frontend
 * Uses Puppeteer to test actual browser login functionality
 */

const puppeteer = require('puppeteer');

async function testLoginWithBrowser() {
  let browser;

  try {
    console.log('🔍 Starting Browser-based Login Test...\n');

    // Launch browser
    browser = await puppeteer.launch({
      headless: false, // Set to true for headless mode
      devtools: true,  // Open DevTools
      slowMo: 1000,    // Slow down by 1 second
      args: [
        '--disable-web-security',
        '--disable-features=VizDisplayCompositor',
        '--no-sandbox'
      ]
    });

    const page = await browser.newPage();

    // Set viewport
    await page.setViewport({ width: 1280, height: 720 });

    // Enable console logging
    page.on('console', (msg) => {
      const type = msg.type().toUpperCase();
      const args = msg.args().map(arg => arg.toString());
      console.log(`[BROWSER ${type}]`, ...args);
    });

    // Enable network request logging
    page.on('request', (request) => {
      console.log(`[NETWORK REQUEST] ${request.method()} ${request.url()}`);
    });

    page.on('response', (response) => {
      const status = response.status();
      const url = response.url();
      if (status >= 400 || url.includes('/auth/oauth/connections')) {
        console.log(`[NETWORK RESPONSE] ${status} ${url}`);
      }
    });

    // Enable error logging
    page.on('pageerror', (error) => {
      console.log(`[PAGE ERROR] ${error.message}`);
    });

    console.log('1. Navigating to login page...');
    await page.goto('http://localhost:3001/login', {
      waitUntil: 'networkidle0',
      timeout: 30000
    });

    // Wait a bit and check if page is stuck in loading
    await page.waitForTimeout(5000);

    // Check if loading spinner is present
    const loadingSpinner = await page.$('[data-testid="loading-spinner"]');
    if (loadingSpinner) {
      console.log('❌ Page stuck in loading state - confirming our hypothesis');
      console.log('   The OAuth connections API call is likely hanging');

      // Try to check network requests
      console.log('\n2. Checking network activity...');

      // Wait for potential network requests to complete or timeout
      try {
        await page.waitForSelector('[data-testid="email-input"]', { timeout: 10000 });
        console.log('✓ Login form loaded successfully after delay');
      } catch (timeoutError) {
        console.log('❌ Login form never appeared - initialization completely blocked');

        // Get page content to analyze
        const pageContent = await page.content();
        if (pageContent.includes('Loading...')) {
          console.log('   Confirmed: Page showing loading state');
        }

        await browser.close();
        return;
      }
    }

    console.log('✓ Login page loaded successfully');

    // Test login form interaction
    console.log('\n3. Testing login form...');

    // Fill in credentials
    await page.type('[data-testid="email-input"]', 'admin@engarde.ai');
    await page.type('[data-testid="password-input"]', 'admin123');

    console.log('✓ Credentials entered');

    // Click login button
    console.log('\n4. Attempting login...');
    await page.click('[data-testid="login-button"]');

    // Wait for login response
    try {
      await page.waitForNavigation({
        waitUntil: 'networkidle0',
        timeout: 15000
      });

      const currentUrl = page.url();
      console.log(`✓ Login successful - redirected to: ${currentUrl}`);
    } catch (navigationError) {
      // Check if there are error messages
      const errorMessage = await page.$('[data-testid="error-message"]');
      if (errorMessage) {
        const errorText = await page.evaluate(el => el.textContent, errorMessage);
        console.log(`❌ Login failed with error: ${errorText}`);
      } else {
        console.log('❌ Login attempt timed out or failed silently');
      }
    }

  } catch (error) {
    console.error(`❌ Browser test failed: ${error.message}`);

    if (error.message.includes('Target closed')) {
      console.log('   Browser was closed during test');
    } else if (error.message.includes('Navigation timeout')) {
      console.log('   Page took too long to load - likely due to initialization hanging');
    }
  } finally {
    if (browser) {
      await browser.close();
    }
  }
}

// Check if Puppeteer is available
async function checkPuppeteerAvailability() {
  try {
    require('puppeteer');
    return true;
  } catch (error) {
    console.log('⚠️ Puppeteer not available. Install with: npm install puppeteer');
    console.log('   Falling back to manual browser testing instructions...\n');

    console.log('📋 Manual Browser Testing Instructions:');
    console.log('   1. Open Chrome/Firefox Developer Tools');
    console.log('   2. Go to http://localhost:3001/login');
    console.log('   3. Check Console tab for errors');
    console.log('   4. Check Network tab for hanging requests');
    console.log('   5. Look for requests to /auth/oauth/connections that return 404');
    console.log('   6. Try login with admin@engarde.ai / admin123');
    console.log('   7. Check if page is stuck in loading state\n');

    return false;
  }
}

// Run the test
(async () => {
  const puppeteerAvailable = await checkPuppeteerAvailability();

  if (puppeteerAvailable) {
    await testLoginWithBrowser();
  }

  console.log('🎯 Expected Issues Based on Code Analysis:');
  console.log('   1. Page stuck in loading state due to AuthContext initialization');
  console.log('   2. OAuth connections endpoint (/auth/oauth/connections) returning 404');
  console.log('   3. This causes getOAuthConnections() to hang or fail');
  console.log('   4. AuthContext never completes initialization (initializing: true)');
  console.log('   5. Login form never appears because of loading spinner');
  console.log('\n✅ Solution: Fix OAuth connections endpoint or handle the error gracefully');
})();