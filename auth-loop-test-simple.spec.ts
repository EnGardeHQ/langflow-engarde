import { test, expect, chromium } from '@playwright/test';

test.describe('Authentication Loop Fix Verification', () => {
  test('Login flow without authentication loops', async () => {
    // Launch browser
    const browser = await chromium.launch({ headless: false });
    const context = await browser.newContext();
    const page = await context.newPage();

    // Monitor console logs
    page.on('console', msg => {
      const text = msg.text();
      if (text.includes('AUTH') || text.includes('PROTECTED') || text.includes('LOGIN')) {
        console.log(`[Console]: ${text}`);
      }
    });

    // Track navigation history
    const navigationHistory: string[] = [];
    page.on('framenavigated', frame => {
      if (frame === page.mainFrame()) {
        const url = new URL(frame.url()).pathname;
        navigationHistory.push(url);
        console.log(`[Navigation]: ${url}`);

        // Check for loop pattern
        if (navigationHistory.length >= 4) {
          const recent = navigationHistory.slice(-4);
          if (recent[0] === '/login' && recent[1] === '/dashboard' &&
              recent[2] === '/login' && recent[3] === '/dashboard') {
            throw new Error(`Authentication loop detected: ${recent.join(' -> ')}`);
          }
        }
      }
    });

    try {
      // Step 1: Navigate to login page
      console.log('\n=== Step 1: Navigating to login page ===');
      await page.goto('http://localhost:3000/login', { waitUntil: 'networkidle' });
      await page.waitForTimeout(2000);

      // Step 2: Fill login form
      console.log('\n=== Step 2: Filling login form ===');

      // Try to find and click Brand tab if it exists
      const brandTab = page.locator('text=Brand').first();
      if (await brandTab.isVisible({ timeout: 2000 }).catch(() => false)) {
        await brandTab.click();
        console.log('Clicked Brand tab');
      }

      // Fill in credentials
      await page.fill('input[type="email"]', 'test@example.com');
      await page.fill('input[type="password"]', 'password123');
      console.log('Filled credentials');

      // Step 3: Submit form
      console.log('\n=== Step 3: Submitting login form ===');
      const loginButton = page.locator('button:has-text("Sign In"), button:has-text("Login")').first();
      await loginButton.click();
      console.log('Clicked login button');

      // Step 4: Wait for navigation (with timeout to detect loops)
      console.log('\n=== Step 4: Waiting for navigation ===');
      await page.waitForTimeout(5000);

      // Step 5: Check final state
      const finalUrl = new URL(page.url()).pathname;
      console.log(`\n=== Final URL: ${finalUrl} ===`);
      console.log(`Navigation history: ${navigationHistory.join(' -> ')}`);

      // Verify no loops occurred
      const loopDetected = navigationHistory.some((_, i, arr) => {
        if (i >= 3) {
          const pattern = arr.slice(i-3, i+1);
          return pattern[0] === '/login' && pattern[1] === '/dashboard' &&
                 pattern[2] === '/login' && pattern[3] === '/dashboard';
        }
        return false;
      });

      if (loopDetected) {
        throw new Error('Authentication loop detected in navigation history');
      }

      // Verify we ended up on dashboard
      if (finalUrl === '/dashboard') {
        console.log('\n✅ SUCCESS: Logged in and on dashboard without loops');
      } else if (finalUrl === '/login') {
        console.log('\n⚠️ WARNING: Still on login page - authentication may have failed');
      } else {
        console.log(`\n⚠️ WARNING: Ended up on unexpected page: ${finalUrl}`);
      }

      // Step 6: Test page refresh
      console.log('\n=== Step 6: Testing page refresh ===');
      if (finalUrl === '/dashboard') {
        await page.reload();
        await page.waitForTimeout(3000);
        const urlAfterRefresh = new URL(page.url()).pathname;
        console.log(`URL after refresh: ${urlAfterRefresh}`);

        if (urlAfterRefresh === '/dashboard') {
          console.log('✅ Still on dashboard after refresh');
        } else {
          console.log(`⚠️ Redirected to ${urlAfterRefresh} after refresh`);
        }
      }

    } catch (error) {
      console.error('\n❌ Test failed:', error);
      throw error;
    } finally {
      // Clean up
      await browser.close();
    }
  });
});