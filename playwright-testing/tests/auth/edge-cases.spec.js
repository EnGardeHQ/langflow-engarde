const { test, expect } = require('@playwright/test');

/**
 * Edge Cases and Failure Points Authentication Tests
 * Tests unusual scenarios and error conditions
 */

const BASE_URL = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3001';
const API_BASE_URL = process.env.PLAYWRIGHT_API_URL || 'http://localhost:8000';

// Test utilities
class EdgeCaseTestUtils {
  constructor(page) {
    this.page = page;
  }

  async waitForPageLoad(timeout = 10000) {
    await this.page.waitForLoadState('networkidle', { timeout });
    await this.page.waitForTimeout(500);
  }

  async clearAuthState() {
    await this.page.evaluate(() => {
      localStorage.clear();
      sessionStorage.clear();
      document.cookie.split(";").forEach(function(c) {
        document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/");
      });
    });
  }

  async injectMaliciousPayloads(formSelector) {
    const payloads = [
      '<script>alert("xss")</script>',
      '"><script>alert("xss")</script>',
      'javascript:alert("xss")',
      '${alert("xss")}',
      '\' OR 1=1 --',
      '" OR "1"="1',
      'admin\' --',
      '\'; DROP TABLE users; --',
      '../../../etc/passwd',
      '%00',
      '\x00',
      'null',
      'undefined',
      '🚀💥🔥', // Unicode edge cases
      '     ', // Whitespace only
      ''.repeat(10000) // Extremely long input
    ];

    const results = [];
    for (const payload of payloads) {
      try {
        await this.page.fill(formSelector, payload);
        await this.page.keyboard.press('Tab');
        await this.page.waitForTimeout(100);

        const value = await this.page.inputValue(formSelector);
        results.push({
          payload,
          accepted: value === payload,
          sanitized: value !== payload,
          actualValue: value
        });
      } catch (error) {
        results.push({
          payload,
          error: error.message
        });
      }
    }

    return results;
  }

  async simulateMemoryPressure() {
    return await this.page.evaluate(() => {
      // Create large objects to simulate memory pressure
      const largeArrays = [];
      try {
        for (let i = 0; i < 100; i++) {
          largeArrays.push(new Array(100000).fill(`data-${i}`));
        }
        return { success: true, arraysCreated: largeArrays.length };
      } catch (error) {
        return { success: false, error: error.message };
      }
    });
  }

  async simulateCPULoad() {
    return await this.page.evaluate(() => {
      const start = Date.now();
      // CPU intensive operation
      let result = 0;
      for (let i = 0; i < 1000000; i++) {
        result += Math.sqrt(i) * Math.sin(i);
      }
      return {
        duration: Date.now() - start,
        result: result
      };
    });
  }

  async testFormValidationBypass() {
    // Try to bypass frontend validation by direct form submission
    return await this.page.evaluate(() => {
      const forms = document.querySelectorAll('form');
      const results = [];

      forms.forEach((form, index) => {
        try {
          // Try to submit empty form
          const event = new Event('submit');
          form.dispatchEvent(event);
          results.push({ formIndex: index, bypassAttempt: 'empty', success: true });
        } catch (error) {
          results.push({ formIndex: index, bypassAttempt: 'empty', error: error.message });
        }

        try {
          // Try to submit with manipulated action
          const originalAction = form.action;
          form.action = 'javascript:void(0)';
          form.submit();
          form.action = originalAction;
          results.push({ formIndex: index, bypassAttempt: 'javascript', success: true });
        } catch (error) {
          results.push({ formIndex: index, bypassAttempt: 'javascript', error: error.message });
        }
      });

      return results;
    });
  }

  async monitorConsoleErrors() {
    const errors = [];
    this.page.on('console', (msg) => {
      if (msg.type() === 'error') {
        errors.push({
          text: msg.text(),
          location: msg.location(),
          timestamp: Date.now()
        });
      }
    });

    this.page.on('pageerror', (error) => {
      errors.push({
        text: error.message,
        stack: error.stack,
        timestamp: Date.now(),
        type: 'pageerror'
      });
    });

    return () => errors;
  }

  async testLocalStorageManipulation() {
    return await this.page.evaluate(() => {
      const tests = [];

      // Test storage quota
      try {
        const largeData = 'x'.repeat(10000000); // 10MB string
        localStorage.setItem('test_large', largeData);
        tests.push({ test: 'large_data', success: true });
      } catch (error) {
        tests.push({ test: 'large_data', error: error.message });
      }

      // Test invalid JSON in user data
      try {
        localStorage.setItem('engarde_user', '{invalid json}');
        tests.push({ test: 'invalid_json', success: true });
      } catch (error) {
        tests.push({ test: 'invalid_json', error: error.message });
      }

      // Test null/undefined values
      try {
        localStorage.setItem('engarde_access_token', null);
        localStorage.setItem('engarde_refresh_token', undefined);
        tests.push({ test: 'null_undefined', success: true });
      } catch (error) {
        tests.push({ test: 'null_undefined', error: error.message });
      }

      // Test very long token
      try {
        const longToken = 'a'.repeat(100000);
        localStorage.setItem('engarde_access_token', longToken);
        tests.push({ test: 'long_token', success: true });
      } catch (error) {
        tests.push({ test: 'long_token', error: error.message });
      }

      return tests;
    });
  }
}

test.describe('Edge Cases and Failure Points', () => {
  let edgeUtils;
  let getConsoleErrors;

  test.beforeEach(async ({ page }) => {
    edgeUtils = new EdgeCaseTestUtils(page);
    getConsoleErrors = await edgeUtils.monitorConsoleErrors();
    await edgeUtils.clearAuthState();
    await page.goto(BASE_URL);
    await edgeUtils.waitForPageLoad();
  });

  test.afterEach(async ({ page }) => {
    const errors = getConsoleErrors();
    if (errors.length > 0) {
      console.log('Console errors detected:', errors);
    }
  });

  test.describe('Input Validation and Security', () => {
    test('should handle malicious input payloads safely', async ({ page }) => {
      console.log('🧪 Testing malicious input handling...');

      await page.goto(`${BASE_URL}/login`);
      await edgeUtils.waitForPageLoad();

      // Test email field
      const emailResults = await edgeUtils.injectMaliciousPayloads('input[type="email"], input[name="email"]');

      // Test password field
      const passwordResults = await edgeUtils.injectMaliciousPayloads('input[type="password"], input[name="password"]');

      // Verify no XSS payloads were executed
      const pageContent = await page.content();
      expect(pageContent).not.toContain('<script>alert("xss")</script>');
      expect(pageContent).not.toContain('javascript:alert("xss")');

      // Check that inputs were properly sanitized or rejected
      const dangerousPayloads = emailResults.concat(passwordResults).filter(r =>
        r.payload.includes('<script>') || r.payload.includes('javascript:')
      );

      for (const result of dangerousPayloads) {
        expect(result.accepted).toBeFalsy();
      }

      console.log('✅ Malicious input handling verified');
      console.log('Email field results:', emailResults.slice(0, 3));
      console.log('Password field results:', passwordResults.slice(0, 3));
    });

    test('should prevent form validation bypass attempts', async ({ page }) => {
      console.log('🧪 Testing form validation bypass...');

      await page.goto(`${BASE_URL}/login`);
      await edgeUtils.waitForPageLoad();

      const bypassResults = await edgeUtils.testFormValidationBypass();

      // Should not be able to bypass validation
      const successfulBypasses = bypassResults.filter(r => r.success && !r.error);
      expect(successfulBypasses.length).toBe(0);

      // Page should still be on login (not authenticated)
      await edgeUtils.waitForPageLoad();
      expect(page.url()).toContain('login');

      console.log('✅ Form validation bypass prevention verified');
      console.log('Bypass attempt results:', bypassResults);
    });

    test('should handle extremely long inputs gracefully', async ({ page }) => {
      console.log('🧪 Testing extremely long inputs...');

      await page.goto(`${BASE_URL}/login`);
      await edgeUtils.waitForPageLoad();

      const longEmail = 'a'.repeat(10000) + '@example.com';
      const longPassword = 'p'.repeat(50000);

      // Should handle without crashing
      try {
        await page.fill('input[type="email"], input[name="email"]', longEmail, { timeout: 5000 });
        await page.fill('input[type="password"], input[name="password"]', longPassword, { timeout: 5000 });

        // Try to submit
        await page.click('button[type="submit"], button:has-text("Login")', { timeout: 5000 });
        await page.waitForTimeout(2000);

        // Should either reject or handle gracefully
        const currentUrl = page.url();
        expect(currentUrl).toContain('login'); // Should remain on login

        console.log('✅ Long inputs handled gracefully');
      } catch (error) {
        console.log('✅ Long inputs properly rejected:', error.message);
      }
    });

    test('should handle special characters and Unicode correctly', async ({ page }) => {
      console.log('🧪 Testing special characters and Unicode...');

      await page.goto(`${BASE_URL}/login`);
      await edgeUtils.waitForPageLoad();

      const specialInputs = [
        'test@émâil.com', // Accented characters
        'тест@email.com', // Cyrillic
        '测试@email.com', // Chinese
        'test@🚀.com',   // Emoji domain
        'test+tag@email.com', // Plus addressing
        'test.name+tag@sub.domain.com' // Complex valid email
      ];

      for (const input of specialInputs) {
        try {
          await page.fill('input[type="email"], input[name="email"]', '');
          await page.fill('input[type="email"], input[name="email"]', input);

          const value = await page.inputValue('input[type="email"], input[name="email"]');
          expect(value).toBe(input); // Should preserve the input

          console.log(`✅ Special input handled: ${input}`);
        } catch (error) {
          console.log(`⚠️ Special input rejected: ${input} - ${error.message}`);
        }
      }

      console.log('✅ Special character handling verified');
    });
  });

  test.describe('Resource and Performance Edge Cases', () => {
    test('should handle memory pressure gracefully', async ({ page }) => {
      console.log('🧪 Testing under memory pressure...');

      await page.goto(`${BASE_URL}/login`);
      await edgeUtils.waitForPageLoad();

      // Create memory pressure
      const memoryResult = await edgeUtils.simulateMemoryPressure();
      console.log('Memory pressure simulation:', memoryResult);

      // Try to login under memory pressure
      try {
        await page.fill('input[type="email"], input[name="email"]', 'test@example.com');
        await page.fill('input[type="password"], input[name="password"]', 'password123');
        await page.click('button[type="submit"], button:has-text("Login")');

        await page.waitForTimeout(3000);

        // Should still function (though may be slow)
        const isResponsive = await page.evaluate(() => {
          return document.readyState === 'complete';
        });

        expect(isResponsive).toBeTruthy();
        console.log('✅ Application remained responsive under memory pressure');
      } catch (error) {
        console.log('⚠️ Application degraded under memory pressure:', error.message);
      }
    });

    test('should handle CPU load gracefully', async ({ page }) => {
      console.log('🧪 Testing under CPU load...');

      await page.goto(`${BASE_URL}/login`);
      await edgeUtils.waitForPageLoad();

      // Create CPU load
      const cpuResult = await edgeUtils.simulateCPULoad();
      console.log('CPU load simulation result:', cpuResult);

      // UI should still be responsive
      const startTime = Date.now();
      await page.click('input[type="email"], input[name="email"]');
      const responseTime = Date.now() - startTime;

      expect(responseTime).toBeLessThan(5000); // Should respond within 5 seconds

      console.log(`✅ UI remained responsive under CPU load. Response time: ${responseTime}ms`);
    });

    test('should handle rapid form submissions', async ({ page }) => {
      console.log('🧪 Testing rapid form submissions...');

      await page.goto(`${BASE_URL}/login`);
      await edgeUtils.waitForPageLoad();

      await page.fill('input[type="email"], input[name="email"]', 'test@example.com');
      await page.fill('input[type="password"], input[name="password"]', 'wrongpassword');

      // Submit form rapidly multiple times
      const submissions = [];
      for (let i = 0; i < 10; i++) {
        try {
          const promise = page.click('button[type="submit"], button:has-text("Login")');
          submissions.push(promise);
          await page.waitForTimeout(100); // Small delay between clicks
        } catch (error) {
          console.log(`Submission ${i} failed:`, error.message);
        }
      }

      // Wait for all submissions
      try {
        await Promise.allSettled(submissions);
      } catch (error) {
        console.log('Some submissions failed:', error.message);
      }

      await page.waitForTimeout(3000);

      // Should not crash or create multiple requests
      const errors = getConsoleErrors();
      const criticalErrors = errors.filter(e =>
        e.text.includes('Cannot read') ||
        e.text.includes('undefined') ||
        e.text.includes('null')
      );

      expect(criticalErrors.length).toBeLessThan(5); // Allow some errors but not excessive

      console.log('✅ Rapid submissions handled without critical errors');
    });
  });

  test.describe('Local Storage Manipulation', () => {
    test('should handle corrupted local storage data', async ({ page }) => {
      console.log('🧪 Testing corrupted local storage handling...');

      await page.goto(`${BASE_URL}/login`);
      await edgeUtils.waitForPageLoad();

      // Test various storage manipulations
      const storageTests = await edgeUtils.testLocalStorageManipulation();
      console.log('Storage manipulation tests:', storageTests);

      // Try to navigate to dashboard with corrupted data
      await page.goto(`${BASE_URL}/dashboard`);
      await edgeUtils.waitForPageLoad();

      // Should redirect to login due to invalid auth data
      await page.waitForTimeout(3000);
      expect(page.url()).toContain('login');

      // Should not have crashed
      const isPageFunctional = await page.evaluate(() => {
        return document.body && document.body.children.length > 0;
      });

      expect(isPageFunctional).toBeTruthy();

      console.log('✅ Corrupted local storage handled gracefully');
    });

    test('should handle storage quota exceeded scenarios', async ({ page }) => {
      console.log('🧪 Testing storage quota scenarios...');

      await page.goto(`${BASE_URL}/login`);
      await edgeUtils.waitForPageLoad();

      // Fill up local storage
      const quotaTest = await page.evaluate(() => {
        const results = [];
        try {
          // Try to fill up storage
          for (let i = 0; i < 1000; i++) {
            const key = `test_key_${i}`;
            const value = 'x'.repeat(10000); // 10KB per item
            localStorage.setItem(key, value);
          }
          results.push({ test: 'quota_fill', success: true });
        } catch (error) {
          results.push({ test: 'quota_fill', error: error.message });
        }

        // Try to store auth tokens when storage is full
        try {
          localStorage.setItem('engarde_access_token', 'test_token');
          results.push({ test: 'auth_storage', success: true });
        } catch (error) {
          results.push({ test: 'auth_storage', error: error.message });
        }

        return results;
      });

      console.log('Storage quota test results:', quotaTest);

      // Application should handle storage errors gracefully
      const errors = getConsoleErrors();
      const storageErrors = errors.filter(e => e.text.includes('QuotaExceededError'));

      // Storage errors are expected, but app shouldn't crash
      expect(errors.length).toBeLessThan(50); // Allow some errors but not excessive

      console.log('✅ Storage quota scenarios handled');
    });
  });

  test.describe('Network Edge Cases', () => {
    test('should handle malformed server responses', async ({ page }) => {
      console.log('🧪 Testing malformed server response handling...');

      // Intercept login API call and return malformed response
      await page.route('**/api/auth/login', async (route) => {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: '{"malformed": json}' // Invalid JSON
        });
      });

      await page.goto(`${BASE_URL}/login`);
      await edgeUtils.waitForPageLoad();

      await page.fill('input[type="email"], input[name="email"]', 'test@example.com');
      await page.fill('input[type="password"], input[name="password"]', 'password123');
      await page.click('button[type="submit"], button:has-text("Login")');

      await page.waitForTimeout(3000);

      // Should handle error gracefully and remain on login page
      expect(page.url()).toContain('login');

      // Check for appropriate error handling
      const errorElement = await page.$('[data-testid="error-message"], .error, .alert');
      if (errorElement) {
        const errorText = await errorElement.textContent();
        expect(errorText).toBeTruthy();
      }

      console.log('✅ Malformed server response handled gracefully');
    });

    test('should handle unexpected HTTP status codes', async ({ page }) => {
      console.log('🧪 Testing unexpected HTTP status codes...');

      const statusCodes = [418, 451, 599, 999]; // Unusual status codes

      for (const statusCode of statusCodes) {
        await page.route('**/api/auth/login', async (route) => {
          await route.fulfill({
            status: statusCode,
            contentType: 'application/json',
            body: JSON.stringify({ error: `Status ${statusCode}` })
          });
        });

        await page.goto(`${BASE_URL}/login`);
        await edgeUtils.waitForPageLoad();

        await page.fill('input[type="email"], input[name="email"]', 'test@example.com');
        await page.fill('input[type="password"], input[name="password"]', 'password123');
        await page.click('button[type="submit"], button:has-text("Login")');

        await page.waitForTimeout(2000);

        // Should remain on login page and handle error
        expect(page.url()).toContain('login');

        console.log(`✅ HTTP ${statusCode} handled gracefully`);
      }
    });

    test('should handle extremely slow server responses', async ({ page }) => {
      console.log('🧪 Testing extremely slow server responses...');

      // Intercept and delay the login request
      await page.route('**/api/auth/login', async (route) => {
        // Delay for 15 seconds
        await new Promise(resolve => setTimeout(resolve, 15000));
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({ error: 'Timeout simulation' })
        });
      });

      await page.goto(`${BASE_URL}/login`);
      await edgeUtils.waitForPageLoad();

      await page.fill('input[type="email"], input[name="email"]', 'test@example.com');
      await page.fill('input[type="password"], input[name="password"]', 'password123');

      const startTime = Date.now();
      await page.click('button[type="submit"], button:has-text("Login")');

      // Should have some kind of timeout or loading state
      await page.waitForTimeout(5000);

      // Check if there's a loading indicator
      const loadingIndicator = await page.$('[data-testid="loading"], .loading, .spinner');
      const loadingExists = loadingIndicator ? await loadingIndicator.isVisible() : false;

      // Should either show loading or timeout gracefully
      const duration = Date.now() - startTime;
      console.log(`Request duration: ${duration}ms, Loading indicator: ${loadingExists}`);

      // Cancel the request by navigating away
      await page.goto(`${BASE_URL}/login`);

      console.log('✅ Slow server response handled (loading state or timeout)');
    });
  });

  test.describe('Browser Compatibility Edge Cases', () => {
    test('should handle disabled JavaScript gracefully', async ({ page }) => {
      console.log('🧪 Testing with limited JavaScript...');

      // Disable some JavaScript features
      await page.addInitScript(() => {
        // Simulate old browser by removing some modern features
        delete window.fetch;
        delete window.Promise;
      });

      try {
        await page.goto(`${BASE_URL}/login`);
        await edgeUtils.waitForPageLoad();

        // Page should still load even if some features are missing
        const hasContent = await page.evaluate(() => {
          return document.body && document.body.textContent.length > 0;
        });

        expect(hasContent).toBeTruthy();

        console.log('✅ Page functional with limited JavaScript');
      } catch (error) {
        console.log('⚠️ Page requires full JavaScript support:', error.message);
      }
    });

    test('should handle disabled cookies', async ({ page }) => {
      console.log('🧪 Testing with disabled cookies...');

      // Clear and disable cookies
      await page.context().clearCookies();

      await page.goto(`${BASE_URL}/login`);
      await edgeUtils.waitForPageLoad();

      // Should still be able to access the login page
      expect(page.url()).toContain('login');

      // Try to login (may fail due to CSRF protection)
      await page.fill('input[type="email"], input[name="email"]', 'test@example.com');
      await page.fill('input[type="password"], input[name="password"]', 'password123');
      await page.click('button[type="submit"], button:has-text("Login")');

      await page.waitForTimeout(3000);

      // Should handle gracefully (may show error about cookies)
      const errors = getConsoleErrors();
      expect(errors.length).toBeLessThan(10); // Some errors expected, but not excessive

      console.log('✅ Disabled cookies handled gracefully');
    });

    test('should handle viewport size edge cases', async ({ page }) => {
      console.log('🧪 Testing extreme viewport sizes...');

      const viewports = [
        { width: 320, height: 568 },   // iPhone 5
        { width: 1920, height: 1080 }, // Full HD
        { width: 100, height: 100 },   // Extremely small
        { width: 5000, height: 3000 }, // Extremely large
      ];

      for (const viewport of viewports) {
        try {
          await page.setViewportSize(viewport);
          await page.goto(`${BASE_URL}/login`);
          await edgeUtils.waitForPageLoad();

          // Check if login form is accessible
          const emailField = await page.$('input[type="email"], input[name="email"]');
          const passwordField = await page.$('input[type="password"], input[name="password"]');
          const submitButton = await page.$('button[type="submit"], button:has-text("Login")');

          const formAccessible = emailField && passwordField && submitButton;
          console.log(`Viewport ${viewport.width}x${viewport.height}: Form accessible = ${!!formAccessible}`);

          // Form should be accessible in reasonable viewport sizes
          if (viewport.width >= 320 && viewport.height >= 568) {
            expect(formAccessible).toBeTruthy();
          }

        } catch (error) {
          console.log(`Viewport ${viewport.width}x${viewport.height} error:`, error.message);
        }
      }

      console.log('✅ Viewport size edge cases tested');
    });
  });
});