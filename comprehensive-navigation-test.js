const { chromium } = require('playwright');

async function comprehensiveNavigationTest() {
  console.log('Starting comprehensive navigation test...');

  const browser = await chromium.launch({
    headless: false,
    devtools: true,
    slowMo: 500 // Slow down operations for visibility
  });

  const context = await browser.newContext();
  const page = await context.newPage();

  // Track errors and results
  const results = {
    login: false,
    navigationTests: [],
    errors: {
      console: [],
      network: [],
      navigation: []
    }
  };

  // Capture console errors
  page.on('console', msg => {
    if (msg.type() === 'error') {
      results.errors.console.push(msg.text());
      console.log('Console Error:', msg.text());
    }
  });

  // Capture network failures
  page.on('requestfailed', request => {
    results.errors.network.push({
      url: request.url(),
      failure: request.failure()?.errorText || 'Unknown error'
    });
    console.log('Network Error:', request.url(), request.failure()?.errorText);
  });

  try {
    console.log('\n=== STEP 1: Login ===');
    await page.goto('http://localhost:3001', { waitUntil: 'networkidle' });
    await page.waitForTimeout(2000);

    // Click login link
    await page.click('a[href="/login"]');
    await page.waitForURL('**/login');

    // Login with demo credentials
    await page.waitForSelector('input[type="email"]', { timeout: 10000 });
    await page.fill('input[type="email"]', 'demo@engarde.com');
    await page.fill('input[type="password"]', 'demo123');
    await page.click('button[type="submit"]');

    // Wait for successful login (look for dashboard elements)
    try {
      await page.waitForSelector('[data-testid="dashboard"], .dashboard, nav[role="navigation"]', { timeout: 10000 });
      results.login = true;
      console.log('✅ Login successful');
    } catch (error) {
      console.log('❌ Login may have failed or dashboard not found');
      results.errors.navigation.push('Login verification failed');
    }

    // Take screenshot after login
    await page.screenshot({ path: 'after-login.png' });

    console.log('\n=== STEP 2: Test Sidebar Navigation ===');

    // Define navigation items to test
    const navigationItems = [
      { name: 'Dashboard', selector: 'a[href="/dashboard"], a[href="/"], [data-testid="nav-dashboard"]' },
      { name: 'Campaigns', selector: 'a[href="/campaigns"], [data-testid="nav-campaigns"]' },
      { name: 'Analytics', selector: 'a[href="/analytics"], [data-testid="nav-analytics"]' },
      { name: 'Workflows', selector: 'a[href="/workflows"], [data-testid="nav-workflows"]' },
      { name: 'Agents', selector: 'a[href="/agents"], [data-testid="nav-agents"]' },
      { name: 'Settings', selector: 'a[href="/settings"], [data-testid="nav-settings"]' },
      { name: 'Profile', selector: 'a[href="/profile"], [data-testid="nav-profile"]' }
    ];

    for (const navItem of navigationItems) {
      const testResult = {
        name: navItem.name,
        found: false,
        clickable: false,
        navigated: false,
        error: null
      };

      try {
        console.log(`\n--- Testing ${navItem.name} navigation ---`);

        // Look for the navigation item
        const element = await page.locator(navItem.selector).first();
        const count = await element.count();

        if (count > 0) {
          testResult.found = true;
          console.log(`✅ Found ${navItem.name} navigation element`);

          // Try to click it
          try {
            await element.click();
            testResult.clickable = true;
            console.log(`✅ Successfully clicked ${navItem.name}`);

            // Wait for navigation to complete
            await page.waitForTimeout(2000);

            // Check if URL changed or page content loaded
            const currentURL = page.url();
            console.log(`Current URL: ${currentURL}`);

            // Look for page-specific content
            const pageLoaded = await page.locator('main, .main-content, [role="main"]').count() > 0;
            if (pageLoaded) {
              testResult.navigated = true;
              console.log(`✅ ${navItem.name} page loaded successfully`);
            } else {
              console.log(`⚠️  ${navItem.name} page may not have loaded properly`);
            }

            // Take screenshot of the page
            await page.screenshot({ path: `${navItem.name.toLowerCase()}-page.png` });

          } catch (clickError) {
            testResult.error = `Click failed: ${clickError.message}`;
            console.log(`❌ Failed to click ${navItem.name}: ${clickError.message}`);
          }
        } else {
          console.log(`❌ ${navItem.name} navigation element not found`);
          testResult.error = 'Navigation element not found';
        }

      } catch (error) {
        testResult.error = error.message;
        console.log(`❌ Error testing ${navItem.name}: ${error.message}`);
      }

      results.navigationTests.push(testResult);
    }

    console.log('\n=== STEP 3: Test API Integration ===');

    // Test if API calls are working by checking network requests
    const apiCalls = [];
    page.on('response', response => {
      if (response.url().includes('localhost:8000') || response.url().includes('/api/')) {
        apiCalls.push({
          url: response.url(),
          status: response.status(),
          statusText: response.statusText()
        });
      }
    });

    // Navigate to dashboard to trigger API calls
    try {
      await page.goto('http://localhost:3001/dashboard', { waitUntil: 'networkidle' });
      await page.waitForTimeout(3000);
    } catch (error) {
      console.log('Could not navigate to dashboard:', error.message);
    }

    console.log('\n=== API Calls Detected ===');
    apiCalls.forEach(call => {
      console.log(`${call.status} - ${call.url}`);
    });

  } catch (error) {
    console.error('Test failed:', error);
    results.errors.navigation.push(`Test failure: ${error.message}`);
  } finally {
    // Generate final report
    console.log('\n' + '='.repeat(60));
    console.log('COMPREHENSIVE NAVIGATION TEST REPORT');
    console.log('='.repeat(60));

    console.log(`\n🔐 Login: ${results.login ? '✅ SUCCESS' : '❌ FAILED'}`);

    console.log('\n📱 Navigation Tests:');
    results.navigationTests.forEach(test => {
      const status = test.navigated ? '✅' : test.clickable ? '⚠️' : test.found ? '🔍' : '❌';
      console.log(`  ${status} ${test.name}: Found=${test.found}, Clickable=${test.clickable}, Navigated=${test.navigated}`);
      if (test.error) console.log(`     Error: ${test.error}`);
    });

    console.log(`\n🚨 Console Errors: ${results.errors.console.length}`);
    results.errors.console.forEach(error => console.log(`  - ${error}`));

    console.log(`\n🌐 Network Errors: ${results.errors.network.length}`);
    results.errors.network.forEach(error => console.log(`  - ${error.url}: ${error.failure}`));

    console.log(`\n⚠️  Navigation Errors: ${results.errors.navigation.length}`);
    results.errors.navigation.forEach(error => console.log(`  - ${error}`));

    // Save detailed results to JSON
    require('fs').writeFileSync('navigation-test-results.json', JSON.stringify(results, null, 2));
    console.log('\n📄 Detailed results saved to navigation-test-results.json');

    await browser.close();
  }
}

comprehensiveNavigationTest().catch(console.error);