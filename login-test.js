const { chromium } = require('playwright');

async function testLogin() {
  console.log('Starting login test...');

  const browser = await chromium.launch({
    headless: false,
    devtools: true
  });

  const context = await browser.newContext();
  const page = await context.newPage();

  // Capture console errors
  const consoleErrors = [];
  page.on('console', msg => {
    if (msg.type() === 'error') {
      consoleErrors.push(msg.text());
      console.log('Console Error:', msg.text());
    }
  });

  // Capture network failures
  const networkErrors = [];
  page.on('requestfailed', request => {
    networkErrors.push({
      url: request.url(),
      failure: request.failure()
    });
    console.log('Network Error:', request.url(), request.failure());
  });

  try {
    console.log('Navigating to http://localhost:3001...');
    await page.goto('http://localhost:3001', { waitUntil: 'networkidle' });

    // Wait for page to load
    await page.waitForTimeout(2000);

    console.log('Page loaded, checking for login link...');

    // Click login link
    await page.click('a[href="/login"]');
    console.log('Clicked login link');

    // Wait for login page
    await page.waitForURL('**/login');
    console.log('Login page loaded');

    // Wait for login form
    await page.waitForSelector('input[type="email"]', { timeout: 10000 });
    console.log('Login form found');

    // Fill in demo credentials
    await page.fill('input[type="email"]', 'demo@engarde.com');
    await page.fill('input[type="password"]', 'demo123');
    console.log('Filled credentials');

    // Click submit
    await page.click('button[type="submit"]');
    console.log('Clicked submit button');

    // Wait for response
    await page.waitForTimeout(3000);

    console.log('\n=== CONSOLE ERRORS ===');
    consoleErrors.forEach(error => console.log(error));

    console.log('\n=== NETWORK ERRORS ===');
    networkErrors.forEach(error => console.log(error));

    // Take screenshot
    await page.screenshot({ path: 'login-test-result.png' });
    console.log('Screenshot saved as login-test-result.png');

  } catch (error) {
    console.error('Test failed:', error);
  } finally {
    await browser.close();
  }
}

testLogin().catch(console.error);