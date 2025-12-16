const { chromium } = require('playwright');

async function verifyLoginAndDashboard() {
  console.log('Verifying login process and dashboard access...');

  const browser = await chromium.launch({
    headless: false,
    devtools: true
  });

  const context = await browser.newContext();
  const page = await context.newPage();

  // Track authentication state
  const authState = {
    loginAttempted: false,
    loginSuccessful: false,
    dashboardAccessible: false,
    currentURL: '',
    errors: []
  };

  // Monitor network requests for authentication
  page.on('response', response => {
    if (response.url().includes('/token') || response.url().includes('/login') || response.url().includes('/auth')) {
      console.log(`AUTH REQUEST: ${response.status()} - ${response.url()}`);
    }
  });

  try {
    console.log('\n=== Step 1: Navigate to homepage ===');
    await page.goto('http://localhost:3001', { waitUntil: 'networkidle' });
    await page.waitForTimeout(2000);
    authState.currentURL = page.url();
    console.log(`Current URL: ${authState.currentURL}`);

    console.log('\n=== Step 2: Click login link ===');
    try {
      await page.click('a[href="/login"]');
      await page.waitForURL('**/login', { timeout: 5000 });
      console.log('✅ Successfully navigated to login page');
    } catch (error) {
      console.log('❌ Could not navigate to login page:', error.message);
      authState.errors.push('Login navigation failed');
    }

    authState.currentURL = page.url();
    console.log(`Current URL: ${authState.currentURL}`);

    console.log('\n=== Step 3: Fill login form ===');
    try {
      await page.waitForSelector('input[type="email"]', { timeout: 10000 });
      await page.fill('input[type="email"]', 'demo@engarde.com');
      await page.fill('input[type="password"]', 'demo123');

      console.log('Filled credentials, clicking submit...');
      await page.click('button[type="submit"]');
      authState.loginAttempted = true;

      // Wait for navigation or response
      await page.waitForTimeout(5000);

    } catch (error) {
      console.log('❌ Login form interaction failed:', error.message);
      authState.errors.push('Login form failed');
    }

    authState.currentURL = page.url();
    console.log(`Current URL after login: ${authState.currentURL}`);

    console.log('\n=== Step 4: Check for successful login indicators ===');

    // Check if we're redirected or if there are auth tokens
    const hasAuthToken = await page.evaluate(() => {
      return localStorage.getItem('token') ||
             localStorage.getItem('authToken') ||
             localStorage.getItem('accessToken') ||
             sessionStorage.getItem('token') ||
             sessionStorage.getItem('authToken') ||
             sessionStorage.getItem('accessToken') ||
             document.cookie.includes('token') ||
             document.cookie.includes('auth');
    });

    console.log(`Auth token found: ${hasAuthToken}`);

    // Look for dashboard elements or user profile info
    const dashboardElements = await page.locator('nav, .dashboard, [data-testid*="dashboard"], .sidebar, [role="main"]').count();
    console.log(`Dashboard/navigation elements found: ${dashboardElements}`);

    console.log('\n=== Step 5: Try different dashboard routes ===');

    const dashboardRoutes = [
      '/dashboard',
      '/app',
      '/app/dashboard',
      '/home',
      '/main'
    ];

    for (const route of dashboardRoutes) {
      try {
        console.log(`Trying route: ${route}`);
        await page.goto(`http://localhost:3001${route}`, { waitUntil: 'networkidle' });
        await page.waitForTimeout(2000);

        const url = page.url();
        console.log(`Result URL: ${url}`);

        // Check if we have navigation elements
        const navElements = await page.locator('nav, .sidebar, aside, [role="navigation"]').count();
        console.log(`Navigation elements found: ${navElements}`);

        if (navElements > 0 && !url.includes('/login')) {
          authState.dashboardAccessible = true;
          authState.currentURL = url;

          // Look for specific navigation links
          const links = await page.locator('a').all();
          const navLinks = [];

          for (const link of links) {
            try {
              const href = await link.getAttribute('href');
              const text = await link.textContent();
              if (href && text && (
                href.includes('/campaign') ||
                href.includes('/analytic') ||
                href.includes('/dashboard') ||
                text.toLowerCase().includes('campaign') ||
                text.toLowerCase().includes('analytic') ||
                text.toLowerCase().includes('dashboard')
              )) {
                navLinks.push({ href, text: text.trim() });
              }
            } catch (e) {
              // Skip problematic links
            }
          }

          console.log('✅ Dashboard accessible with navigation links:');
          navLinks.forEach(link => console.log(`  - "${link.text}" -> ${link.href}`));

          // Take screenshot of the dashboard
          await page.screenshot({ path: `dashboard-${route.replace('/', '')}.png` });
          break;
        }

      } catch (error) {
        console.log(`❌ Route ${route} failed: ${error.message}`);
      }
    }

    console.log('\n=== Step 6: Check page source for navigation elements ===');

    // Get all anchor tags and their attributes
    const allLinks = await page.evaluate(() => {
      const links = Array.from(document.querySelectorAll('a'));
      return links.map(link => ({
        href: link.href,
        text: link.textContent?.trim(),
        className: link.className,
        id: link.id
      })).filter(link => link.href && link.text);
    });

    console.log('\nAll links found on page:');
    allLinks.slice(0, 20).forEach((link, index) => {
      console.log(`  ${index + 1}. "${link.text}" -> ${link.href}`);
    });

    // Take final screenshot
    await page.screenshot({ path: 'final-state.png', fullPage: true });

  } catch (error) {
    console.error('Test failed:', error);
    authState.errors.push(`Test failure: ${error.message}`);
  } finally {
    // Generate report
    console.log('\n' + '='.repeat(60));
    console.log('LOGIN AND DASHBOARD VERIFICATION REPORT');
    console.log('='.repeat(60));

    console.log(`🔐 Login attempted: ${authState.loginAttempted}`);
    console.log(`✅ Login successful: ${authState.loginSuccessful}`);
    console.log(`📊 Dashboard accessible: ${authState.dashboardAccessible}`);
    console.log(`🌐 Final URL: ${authState.currentURL}`);

    if (authState.errors.length > 0) {
      console.log('\n❌ Errors encountered:');
      authState.errors.forEach(error => console.log(`  - ${error}`));
    }

    // Save results
    require('fs').writeFileSync('login-verification-results.json', JSON.stringify(authState, null, 2));
    console.log('\n📄 Results saved to login-verification-results.json');

    await browser.close();
  }
}

verifyLoginAndDashboard().catch(console.error);