const { test, expect } = require('@playwright/test');

/**
 * Simple Login Form Inspection Test
 * This test inspects the login form structure to understand current implementation
 */

const BASE_URL = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3001';

test.describe('Login Form Inspection', () => {
  test('should inspect login form elements and structure', async ({ page }) => {
    console.log('🔍 Inspecting login form structure...');

    // Navigate to login page
    await page.goto(`${BASE_URL}/login`);
    await page.waitForLoadState('networkidle');

    // Take a screenshot for reference
    await page.screenshot({ path: '/Users/cope/EnGardeHQ/playwright-testing/screenshots/login-form-inspection.png' });

    // Log page title and URL
    const title = await page.title();
    const url = page.url();
    console.log(`Page title: ${title}`);
    console.log(`Page URL: ${url}`);

    // Find all input elements
    const inputs = await page.locator('input').all();
    console.log(`Found ${inputs.length} input elements:`);

    for (let i = 0; i < inputs.length; i++) {
      const input = inputs[i];
      const type = await input.getAttribute('type');
      const name = await input.getAttribute('name');
      const id = await input.getAttribute('id');
      const placeholder = await input.getAttribute('placeholder');
      const autocomplete = await input.getAttribute('autocomplete');
      const autoComplete = await input.getAttribute('autoComplete');
      const testId = await input.getAttribute('data-testid');

      console.log(`Input ${i + 1}:`, {
        type,
        name,
        id,
        placeholder,
        autocomplete,
        autoComplete,
        testId
      });
    }

    // Find all button elements
    const buttons = await page.locator('button').all();
    console.log(`Found ${buttons.length} button elements:`);

    for (let i = 0; i < buttons.length; i++) {
      const button = buttons[i];
      const type = await button.getAttribute('type');
      const text = await button.textContent();
      const testId = await button.getAttribute('data-testid');

      console.log(`Button ${i + 1}:`, {
        type,
        text: text?.trim(),
        testId
      });
    }

    // Find all form elements
    const forms = await page.locator('form').all();
    console.log(`Found ${forms.length} form elements`);

    // Find all select elements (for user type)
    const selects = await page.locator('select').all();
    console.log(`Found ${selects.length} select elements:`);

    for (let i = 0; i < selects.length; i++) {
      const select = selects[i];
      const name = await select.getAttribute('name');
      const id = await select.getAttribute('id');
      const testId = await select.getAttribute('data-testid');
      const options = await select.locator('option').all();

      console.log(`Select ${i + 1}:`, {
        name,
        id,
        testId,
        optionCount: options.length
      });

      // Get option values
      for (let j = 0; j < options.length; j++) {
        const option = options[j];
        const value = await option.getAttribute('value');
        const text = await option.textContent();
        console.log(`  Option ${j + 1}: value="${value}", text="${text?.trim()}"`);
      }
    }

    // Check for specific brands test credentials hint
    const pageContent = await page.textContent('body');
    const hasTestUser = pageContent.includes('test@engarde.ai') ||
                       pageContent.includes('Test User') ||
                       pageContent.includes('brand');

    console.log(`Page contains test user hints: ${hasTestUser}`);

    // Test basic form interaction
    const emailInput = await page.locator('input[type="email"]').first();
    const passwordInput = await page.locator('input[type="password"]').first();

    if (await emailInput.isVisible()) {
      console.log('✅ Email input found and visible');
      await emailInput.fill('test@engarde.ai');
      console.log('✅ Email input can be filled');
    }

    if (await passwordInput.isVisible()) {
      console.log('✅ Password input found and visible');
      await passwordInput.fill('test123');
      console.log('✅ Password input can be filled');
    }

    // Look for user type selection
    const userTypeSelect = await page.locator('select').first();
    if (await userTypeSelect.isVisible()) {
      console.log('✅ User type select found');
      try {
        await userTypeSelect.selectOption('brand');
        console.log('✅ Brand user type can be selected');
      } catch (e) {
        console.log('⚠️ Could not select brand user type:', e.message);
      }
    }

    console.log('🔍 Login form inspection completed');
  });

  test('should check for autocomplete attributes specifically', async ({ page }) => {
    console.log('🔍 Checking autocomplete attributes...');

    await page.goto(`${BASE_URL}/login`);
    await page.waitForLoadState('networkidle');

    // Check email input autocomplete
    const emailInputs = await page.locator('input[type="email"]').all();
    for (let i = 0; i < emailInputs.length; i++) {
      const input = emailInputs[i];
      const autocomplete = await input.getAttribute('autocomplete');
      const autoComplete = await input.getAttribute('autoComplete');

      console.log(`Email input ${i + 1} autocomplete attributes:`, {
        autocomplete,
        autoComplete,
        hasUsername: autocomplete === 'username' || autoComplete === 'username'
      });
    }

    // Check password input autocomplete
    const passwordInputs = await page.locator('input[type="password"]').all();
    for (let i = 0; i < passwordInputs.length; i++) {
      const input = passwordInputs[i];
      const autocomplete = await input.getAttribute('autocomplete');
      const autoComplete = await input.getAttribute('autoComplete');

      console.log(`Password input ${i + 1} autocomplete attributes:`, {
        autocomplete,
        autoComplete,
        hasCurrentPassword: autocomplete === 'current-password' || autoComplete === 'current-password'
      });
    }

    console.log('🔍 Autocomplete attributes check completed');
  });

  test('should test actual login process with brand credentials', async ({ page }) => {
    console.log('🧪 Testing actual login process...');

    await page.goto(`${BASE_URL}/login`);
    await page.waitForLoadState('networkidle');

    // Fill login form
    const emailInput = await page.locator('input[type="email"]').first();
    const passwordInput = await page.locator('input[type="password"]').first();

    await emailInput.fill('test@engarde.ai');
    await passwordInput.fill('test123');

    // Try to select brand user type if available
    try {
      const userTypeSelect = await page.locator('select').first();
      if (await userTypeSelect.isVisible()) {
        await userTypeSelect.selectOption('brand');
        console.log('✅ Selected brand user type');
      }
    } catch (e) {
      console.log('⚠️ No user type selector found or selection failed');
    }

    // Take screenshot before submission
    await page.screenshot({ path: '/Users/cope/EnGardeHQ/playwright-testing/screenshots/before-login-submit.png' });

    // Submit form
    const submitButton = await page.locator('button[type="submit"]').first();
    if (await submitButton.isVisible()) {
      console.log('Submitting login form...');
      await submitButton.click();
    } else {
      // Try alternative submission methods
      console.log('No submit button found, trying Enter key...');
      await page.keyboard.press('Enter');
    }

    // Wait for response (either success or error)
    await page.waitForTimeout(5000);

    // Take screenshot after submission
    await page.screenshot({ path: '/Users/cope/EnGardeHQ/playwright-testing/screenshots/after-login-submit.png' });

    // Check current URL
    const currentUrl = page.url();
    console.log(`Current URL after login: ${currentUrl}`);

    // Check for success indicators
    const isDashboard = currentUrl.includes('dashboard');
    const isLogin = currentUrl.includes('login');

    if (isDashboard) {
      console.log('✅ Login successful - redirected to dashboard');
    } else if (isLogin) {
      console.log('❌ Login failed - remained on login page');

      // Look for error messages
      const errorSelectors = [
        '.error',
        '.alert',
        '[role="alert"]',
        '.chakra-alert',
        '.notification',
        '.toast'
      ];

      for (const selector of errorSelectors) {
        const errorElement = await page.locator(selector).first();
        if (await errorElement.isVisible()) {
          const errorText = await errorElement.textContent();
          console.log(`Error message: ${errorText}`);
        }
      }
    } else {
      console.log(`⚠️ Unexpected redirect: ${currentUrl}`);
    }

    console.log('🧪 Login process test completed');
  });
});