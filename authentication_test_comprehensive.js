const { chromium } = require('playwright');

async function runAuthenticationTest() {
  console.log('🚀 Starting comprehensive authentication testing...');

  const browser = await chromium.launch({
    headless: false,
    devtools: true,
    slowMo: 1000 // Slow down for better debugging
  });

  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 },
    recordVideo: {
      dir: '/Users/cope/EnGardeHQ/test-videos/',
      size: { width: 1280, height: 720 }
    }
  });

  const page = await context.newPage();

  // Collect console logs and errors
  const consoleLogs = [];
  const networkRequests = [];
  const networkResponses = [];

  page.on('console', msg => {
    const logEntry = {
      type: msg.type(),
      text: msg.text(),
      location: msg.location(),
      timestamp: new Date().toISOString()
    };
    consoleLogs.push(logEntry);
    console.log(`[CONSOLE ${msg.type().toUpperCase()}] ${msg.text()}`);
  });

  page.on('pageerror', error => {
    const errorEntry = {
      type: 'pageerror',
      text: error.message,
      stack: error.stack,
      timestamp: new Date().toISOString()
    };
    consoleLogs.push(errorEntry);
    console.log(`[PAGE ERROR] ${error.message}`);
  });

  page.on('request', request => {
    const requestEntry = {
      url: request.url(),
      method: request.method(),
      headers: request.headers(),
      timestamp: new Date().toISOString(),
      type: 'request'
    };
    networkRequests.push(requestEntry);
    console.log(`[REQUEST] ${request.method()} ${request.url()}`);
  });

  page.on('response', response => {
    const responseEntry = {
      url: response.url(),
      status: response.status(),
      statusText: response.statusText(),
      headers: response.headers(),
      timestamp: new Date().toISOString(),
      type: 'response'
    };
    networkResponses.push(responseEntry);
    console.log(`[RESPONSE] ${response.status()} ${response.url()}`);
  });

  try {
    console.log('📍 Step 1: Navigate to frontend home page');
    await page.goto('http://localhost:3000');

    console.log('📍 Step 2: Wait for page to load completely');
    await page.waitForLoadState('networkidle');

    console.log('📍 Step 3: Take screenshot of home page');
    await page.screenshot({ path: '/Users/cope/EnGardeHQ/screenshot_home.png', fullPage: true });

    console.log('📍 Step 4: Look for login form or login button');
    // Try to find login elements in various ways
    const loginElements = await page.evaluate(() => {
      const selectors = [
        'button[type="submit"]',
        'input[type="submit"]',
        '[data-testid*="login"]',
        '[class*="login"]',
        '[id*="login"]',
        'form',
        'input[type="email"]',
        'input[type="password"]',
        'button:has-text("Login")',
        'button:has-text("Sign in")',
        'a:has-text("Login")',
        'a:has-text("Sign in")'
      ];

      const found = [];
      selectors.forEach(selector => {
        const elements = document.querySelectorAll(selector);
        if (elements.length > 0) {
          found.push({
            selector,
            count: elements.length,
            elements: Array.from(elements).map(el => ({
              tagName: el.tagName,
              text: el.textContent?.trim(),
              id: el.id,
              className: el.className,
              type: el.type,
              outerHTML: el.outerHTML.substring(0, 200)
            }))
          });
        }
      });

      return {
        found,
        bodyText: document.body.textContent?.substring(0, 500),
        title: document.title,
        url: window.location.href
      };
    });

    console.log('📋 Page Analysis Results:', JSON.stringify(loginElements, null, 2));

    // Check if there's a specific login route
    console.log('📍 Step 5: Try to navigate to /login route');
    try {
      await page.goto('http://localhost:3000/login');
      await page.waitForLoadState('networkidle');

      console.log('📍 Step 6: Take screenshot of login page');
      await page.screenshot({ path: '/Users/cope/EnGardeHQ/screenshot_login_page.png', fullPage: true });

      console.log('📍 Step 7: Try to find login form fields');
      const emailField = await page.locator('input[type="email"], input[name="email"], input[placeholder*="email" i], input[id*="email"]').first();
      const passwordField = await page.locator('input[type="password"], input[name="password"], input[placeholder*="password" i], input[id*="password"]').first();
      const submitButton = await page.locator('button[type="submit"], input[type="submit"], button:has-text("Login"), button:has-text("Sign in"), button:has-text("Log in")').first();

      console.log('📍 Step 8: Check if form fields are visible');
      const emailVisible = await emailField.isVisible().catch(() => false);
      const passwordVisible = await passwordField.isVisible().catch(() => false);
      const submitVisible = await submitButton.isVisible().catch(() => false);

      console.log(`Email field visible: ${emailVisible}`);
      console.log(`Password field visible: ${passwordVisible}`);
      console.log(`Submit button visible: ${submitVisible}`);

      if (emailVisible && passwordVisible && submitVisible) {
        console.log('📍 Step 9: Fill in login form with test credentials');
        await emailField.fill('admin@engarde.ai');
        await passwordField.fill('admin123');

        console.log('📍 Step 10: Take screenshot before submitting');
        await page.screenshot({ path: '/Users/cope/EnGardeHQ/screenshot_before_submit.png', fullPage: true });

        console.log('📍 Step 11: Submit the login form');
        await submitButton.click();

        console.log('📍 Step 12: Wait for response and take screenshot');
        await page.waitForTimeout(5000); // Wait for 5 seconds to capture any errors
        await page.screenshot({ path: '/Users/cope/EnGardeHQ/screenshot_after_submit.png', fullPage: true });

      } else {
        console.log('❌ Login form fields not found or not visible');
      }

    } catch (error) {
      console.log(`❌ Error accessing /login route: ${error.message}`);

      // Try other common auth routes
      const routes = ['/auth', '/signin', '/sign-in', '/auth/signin', '/auth/login'];

      for (const route of routes) {
        try {
          console.log(`📍 Trying route: ${route}`);
          await page.goto(`http://localhost:3000${route}`);
          await page.waitForLoadState('networkidle');

          const title = await page.title();
          console.log(`Route ${route} title: ${title}`);

          if (!title.includes('404') && !title.includes('Not Found')) {
            await page.screenshot({ path: `/Users/cope/EnGardeHQ/screenshot${route.replace(/\//g, '_')}.png`, fullPage: true });
            break;
          }
        } catch (routeError) {
          console.log(`Route ${route} failed: ${routeError.message}`);
        }
      }
    }

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    await page.screenshot({ path: '/Users/cope/EnGardeHQ/screenshot_error.png', fullPage: true });
  } finally {
    // Generate comprehensive report
    const report = {
      timestamp: new Date().toISOString(),
      testDuration: Date.now(),
      consoleLogs,
      networkRequests,
      networkResponses,
      summary: {
        totalConsoleLogs: consoleLogs.length,
        totalNetworkRequests: networkRequests.length,
        totalNetworkResponses: networkResponses.length,
        errors: consoleLogs.filter(log => log.type === 'error' || log.type === 'pageerror'),
        warnings: consoleLogs.filter(log => log.type === 'warning'),
        apiCalls: networkRequests.filter(req => req.url.includes('/api/') || req.url.includes(':8000'))
      }
    };

    // Save report
    const fs = require('fs');
    fs.writeFileSync('/Users/cope/EnGardeHQ/authentication_test_report.json', JSON.stringify(report, null, 2));
    console.log('📊 Test report saved to authentication_test_report.json');

    await browser.close();
  }
}

// Run the test
runAuthenticationTest().catch(console.error);