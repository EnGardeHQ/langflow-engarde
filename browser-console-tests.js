/**
 * Browser Console Error Monitoring Tests
 * Uses Playwright to monitor browser console for CSP violations and errors
 */

const { chromium, firefox, webkit } = require('playwright');
const fs = require('fs');
const path = require('path');

class BrowserConsoleTestSuite {
  constructor(baseUrl = 'http://localhost:3001') {
    this.baseUrl = baseUrl;
    this.results = {
      timestamp: new Date().toISOString(),
      baseUrl: baseUrl,
      tests: [],
      summary: {
        total: 0,
        passed: 0,
        failed: 0,
        warnings: 0
      },
      consoleErrors: [],
      cspViolations: []
    };
  }

  log(message, type = 'info') {
    const timestamp = new Date().toISOString();
    const prefix = {
      'info': '🔍',
      'success': '✅',
      'error': '❌',
      'warning': '⚠️',
      'debug': '🐛'
    }[type] || 'ℹ️';

    console.log(`${prefix} [${timestamp}] ${message}`);
  }

  addTestResult(name, passed, details = {}, warnings = []) {
    const result = {
      name,
      passed,
      details,
      warnings,
      timestamp: new Date().toISOString()
    };

    this.results.tests.push(result);
    this.results.summary.total++;

    if (passed) {
      this.results.summary.passed++;
      this.log(`${name}: PASSED`, 'success');
    } else {
      this.results.summary.failed++;
      this.log(`${name}: FAILED`, 'error');
    }

    if (warnings.length > 0) {
      this.results.summary.warnings += warnings.length;
      warnings.forEach(warning => this.log(`  Warning: ${warning}`, 'warning'));
    }

    if (details.description) {
      this.log(`  ${details.description}`, 'debug');
    }
  }

  /**
   * Setup console monitoring for a page
   */
  setupConsoleMonitoring(page, testName) {
    const consoleMessages = [];
    const cspViolations = [];

    // Monitor console messages
    page.on('console', msg => {
      const message = {
        type: msg.type(),
        text: msg.text(),
        timestamp: new Date().toISOString(),
        testName
      };

      consoleMessages.push(message);

      // Check for CSP violations
      if (msg.text().toLowerCase().includes('content security policy') ||
          msg.text().toLowerCase().includes('csp') ||
          msg.text().toLowerCase().includes('unsafe-eval') ||
          msg.text().toLowerCase().includes('eval()')) {
        cspViolations.push(message);
        this.log(`CSP Violation detected: ${msg.text()}`, 'warning');
      }

      // Log errors and warnings
      if (msg.type() === 'error') {
        this.log(`Console Error: ${msg.text()}`, 'error');
      } else if (msg.type() === 'warning') {
        this.log(`Console Warning: ${msg.text()}`, 'warning');
      }
    });

    // Monitor page errors
    page.on('pageerror', error => {
      const errorMessage = {
        type: 'pageerror',
        text: error.message,
        stack: error.stack,
        timestamp: new Date().toISOString(),
        testName
      };

      consoleMessages.push(errorMessage);
      this.log(`Page Error: ${error.message}`, 'error');
    });

    return { consoleMessages, cspViolations };
  }

  /**
   * Test 1: Check for CSP violations on homepage
   */
  async testHomepageCSPViolations(browser) {
    this.log('Testing homepage for CSP violations...', 'info');

    const context = await browser.newContext();
    const page = await context.newPage();

    try {
      const { consoleMessages, cspViolations } = this.setupConsoleMonitoring(page, 'Homepage CSP');

      // Navigate to homepage and wait for load
      await page.goto(this.baseUrl, { waitUntil: 'networkidle' });
      await page.waitForTimeout(3000); // Give time for any async operations

      // Check for CSP violations
      const warnings = [];

      cspViolations.forEach(violation => {
        warnings.push(`CSP violation: ${violation.text}`);
      });

      // Check for eval-related errors
      const evalErrors = consoleMessages.filter(msg =>
        msg.text.toLowerCase().includes('eval') &&
        msg.type === 'error'
      );

      evalErrors.forEach(error => {
        warnings.push(`Eval-related error: ${error.text}`);
      });

      // Store violations for summary
      this.results.cspViolations.push(...cspViolations);
      this.results.consoleErrors.push(...consoleMessages.filter(msg => msg.type === 'error'));

      const passed = cspViolations.length === 0 && evalErrors.length === 0;

      this.addTestResult(
        'Homepage CSP Violations',
        passed,
        {
          description: 'Checks homepage for CSP violations and eval-related errors',
          url: this.baseUrl,
          totalConsoleMessages: consoleMessages.length,
          cspViolations: cspViolations.length,
          evalErrors: evalErrors.length,
          errorMessages: consoleMessages.filter(msg => msg.type === 'error').map(msg => msg.text)
        },
        warnings
      );

    } catch (error) {
      this.addTestResult(
        'Homepage CSP Violations',
        false,
        {
          error: error.message,
          description: 'Failed to test homepage for CSP violations'
        }
      );
    } finally {
      await context.close();
    }
  }

  /**
   * Test 2: Test login flow for CSP violations
   */
  async testLoginFlowCSPViolations(browser) {
    this.log('Testing login flow for CSP violations...', 'info');

    const context = await browser.newContext();
    const page = await context.newPage();

    try {
      const { consoleMessages, cspViolations } = this.setupConsoleMonitoring(page, 'Login Flow CSP');

      // Navigate to login page
      await page.goto(`${this.baseUrl}/login`, { waitUntil: 'networkidle' });
      await page.waitForTimeout(2000);

      // Try to interact with login form (if it exists)
      try {
        const emailInput = page.locator('input[type="email"], input[name="email"], input[placeholder*="email" i]');
        const passwordInput = page.locator('input[type="password"], input[name="password"]');

        if (await emailInput.count() > 0 && await passwordInput.count() > 0) {
          await emailInput.fill('test@example.com');
          await passwordInput.fill('testpassword');
          await page.waitForTimeout(1000);

          // Look for submit button and click if found
          const submitButton = page.locator('button[type="submit"], button:has-text("sign in"), button:has-text("login")');
          if (await submitButton.count() > 0) {
            await submitButton.click();
            await page.waitForTimeout(2000);
          }
        }
      } catch (interactionError) {
        // Login form interaction failed, but that's not necessarily a CSP issue
        this.log(`Login form interaction failed: ${interactionError.message}`, 'debug');
      }

      const warnings = [];

      cspViolations.forEach(violation => {
        warnings.push(`CSP violation in login flow: ${violation.text}`);
      });

      const evalErrors = consoleMessages.filter(msg =>
        msg.text.toLowerCase().includes('eval') &&
        msg.type === 'error'
      );

      evalErrors.forEach(error => {
        warnings.push(`Eval-related error in login: ${error.text}`);
      });

      this.results.cspViolations.push(...cspViolations);
      this.results.consoleErrors.push(...consoleMessages.filter(msg => msg.type === 'error'));

      const passed = cspViolations.length === 0 && evalErrors.length === 0;

      this.addTestResult(
        'Login Flow CSP Violations',
        passed,
        {
          description: 'Checks login flow for CSP violations and eval-related errors',
          url: `${this.baseUrl}/login`,
          totalConsoleMessages: consoleMessages.length,
          cspViolations: cspViolations.length,
          evalErrors: evalErrors.length,
          errorMessages: consoleMessages.filter(msg => msg.type === 'error').map(msg => msg.text)
        },
        warnings
      );

    } catch (error) {
      this.addTestResult(
        'Login Flow CSP Violations',
        false,
        {
          error: error.message,
          description: 'Failed to test login flow for CSP violations'
        }
      );
    } finally {
      await context.close();
    }
  }

  /**
   * Test 3: Test with analytics environment variable
   */
  async testWithAnalyticsEnabled(browser) {
    this.log('Testing with analytics enabled...', 'info');

    const context = await browser.newContext({
      extraHTTPHeaders: {
        'X-Test-Analytics': 'enabled'
      }
    });
    const page = await context.newPage();

    try {
      const { consoleMessages, cspViolations } = this.setupConsoleMonitoring(page, 'Analytics Enabled');

      // Navigate to homepage
      await page.goto(this.baseUrl, { waitUntil: 'networkidle' });
      await page.waitForTimeout(5000); // Give more time for analytics to load

      // Look for Google Analytics script
      const gtmScript = await page.locator('script[src*="googletagmanager.com"]').count();
      const gaScript = await page.locator('script[src*="google-analytics.com"]').count();

      const warnings = [];

      // Check for CSP violations related to analytics
      const analyticsCspViolations = cspViolations.filter(violation =>
        violation.text.toLowerCase().includes('google') ||
        violation.text.toLowerCase().includes('gtag') ||
        violation.text.toLowerCase().includes('analytics')
      );

      analyticsCspViolations.forEach(violation => {
        warnings.push(`Analytics CSP violation: ${violation.text}`);
      });

      // Check for eval errors that might be from analytics
      const analyticsEvalErrors = consoleMessages.filter(msg =>
        msg.text.toLowerCase().includes('eval') &&
        msg.type === 'error' &&
        (msg.text.toLowerCase().includes('google') ||
         msg.text.toLowerCase().includes('gtag') ||
         msg.text.toLowerCase().includes('analytics'))
      );

      analyticsEvalErrors.forEach(error => {
        warnings.push(`Analytics eval error: ${error.text}`);
      });

      this.results.cspViolations.push(...cspViolations);
      this.results.consoleErrors.push(...consoleMessages.filter(msg => msg.type === 'error'));

      const passed = analyticsCspViolations.length === 0 && analyticsEvalErrors.length === 0;

      this.addTestResult(
        'Analytics Enabled CSP Test',
        passed,
        {
          description: 'Tests for CSP violations when analytics are enabled',
          url: this.baseUrl,
          gtmScriptsFound: gtmScript,
          gaScriptsFound: gaScript,
          totalConsoleMessages: consoleMessages.length,
          analyticsCspViolations: analyticsCspViolations.length,
          analyticsEvalErrors: analyticsEvalErrors.length,
          allCspViolations: cspViolations.length
        },
        warnings
      );

    } catch (error) {
      this.addTestResult(
        'Analytics Enabled CSP Test',
        false,
        {
          error: error.message,
          description: 'Failed to test with analytics enabled'
        }
      );
    } finally {
      await context.close();
    }
  }

  /**
   * Test 4: Monitor network requests for CSP-related failures
   */
  async testNetworkRequestFailures(browser) {
    this.log('Testing network requests for CSP-related failures...', 'info');

    const context = await browser.newContext();
    const page = await context.newPage();

    try {
      const { consoleMessages, cspViolations } = this.setupConsoleMonitoring(page, 'Network Requests');
      const failedRequests = [];

      // Monitor network responses
      page.on('response', response => {
        if (!response.ok() && response.status() !== 404) {
          failedRequests.push({
            url: response.url(),
            status: response.status(),
            statusText: response.statusText(),
            timestamp: new Date().toISOString()
          });
        }
      });

      // Navigate and wait for all network activity
      await page.goto(this.baseUrl, { waitUntil: 'networkidle' });
      await page.waitForTimeout(3000);

      const warnings = [];

      // Check for CSP-related request failures
      const cspRelatedFailures = failedRequests.filter(req =>
        req.url.includes('google') ||
        req.url.includes('analytics') ||
        req.url.includes('gtag') ||
        req.url.includes('gtm')
      );

      cspRelatedFailures.forEach(failure => {
        warnings.push(`CSP-related request failure: ${failure.url} (${failure.status})`);
      });

      // Check for console errors related to failed requests
      const requestErrors = consoleMessages.filter(msg =>
        msg.type === 'error' &&
        (msg.text.includes('Failed to load') ||
         msg.text.includes('net::ERR') ||
         msg.text.includes('blocked by'))
      );

      requestErrors.forEach(error => {
        warnings.push(`Network request error: ${error.text}`);
      });

      this.results.cspViolations.push(...cspViolations);
      this.results.consoleErrors.push(...consoleMessages.filter(msg => msg.type === 'error'));

      const passed = cspRelatedFailures.length === 0 && requestErrors.length === 0;

      this.addTestResult(
        'Network Request Failures',
        passed,
        {
          description: 'Monitors network requests for CSP-related failures',
          url: this.baseUrl,
          totalFailedRequests: failedRequests.length,
          cspRelatedFailures: cspRelatedFailures.length,
          requestErrors: requestErrors.length,
          failedRequestDetails: failedRequests
        },
        warnings
      );

    } catch (error) {
      this.addTestResult(
        'Network Request Failures',
        false,
        {
          error: error.message,
          description: 'Failed to monitor network requests'
        }
      );
    } finally {
      await context.close();
    }
  }

  /**
   * Test multiple browsers for compatibility
   */
  async testMultipleBrowsers() {
    this.log('Testing multiple browsers for CSP compatibility...', 'info');

    const browsers = [
      { name: 'Chromium', launcher: chromium },
      { name: 'Firefox', launcher: firefox },
      { name: 'WebKit', launcher: webkit }
    ];

    const browserResults = [];

    for (const { name, launcher } of browsers) {
      try {
        this.log(`Testing ${name}...`, 'info');
        const browser = await launcher.launch();
        const context = await browser.newContext();
        const page = await context.newPage();

        const { consoleMessages, cspViolations } = this.setupConsoleMonitoring(page, `${name} Browser`);

        await page.goto(this.baseUrl, { waitUntil: 'networkidle' });
        await page.waitForTimeout(3000);

        const result = {
          browser: name,
          totalMessages: consoleMessages.length,
          cspViolations: cspViolations.length,
          errors: consoleMessages.filter(msg => msg.type === 'error').length,
          warnings: consoleMessages.filter(msg => msg.type === 'warning').length
        };

        browserResults.push(result);
        this.results.cspViolations.push(...cspViolations);

        await browser.close();

      } catch (error) {
        browserResults.push({
          browser: name,
          error: error.message
        });
        this.log(`Failed to test ${name}: ${error.message}`, 'warning');
      }
    }

    const warnings = [];
    const successfulTests = browserResults.filter(r => !r.error);
    const totalViolations = successfulTests.reduce((sum, r) => sum + r.cspViolations, 0);

    if (successfulTests.length < browsers.length) {
      warnings.push(`Only ${successfulTests.length}/${browsers.length} browsers tested successfully`);
    }

    if (totalViolations > 0) {
      warnings.push(`Total CSP violations across browsers: ${totalViolations}`);
    }

    const passed = totalViolations === 0 && successfulTests.length === browsers.length;

    this.addTestResult(
      'Multi-Browser CSP Compatibility',
      passed,
      {
        description: 'Tests CSP compliance across different browsers',
        browsersTests: browsers.length,
        successfulTests: successfulTests.length,
        totalViolations,
        browserResults
      },
      warnings
    );
  }

  /**
   * Run all browser console tests
   */
  async runAllTests() {
    this.log('Starting Browser Console Test Suite...', 'info');
    this.log(`Target URL: ${this.baseUrl}`, 'info');

    let browser;
    try {
      // Test if we can connect to the URL first
      browser = await chromium.launch();
      const context = await browser.newContext();
      const page = await context.newPage();

      try {
        await page.goto(this.baseUrl, { timeout: 10000 });
        this.log('Server is accessible', 'success');
      } catch (error) {
        this.log(`Server not accessible: ${error.message}`, 'error');
        this.log('Please ensure the application is running on the specified URL', 'warning');
        await browser.close();
        return this.results;
      }

      await context.close();
      await browser.close();

      // Run individual browser tests
      browser = await chromium.launch();
      await this.testHomepageCSPViolations(browser);
      await this.testLoginFlowCSPViolations(browser);
      await this.testWithAnalyticsEnabled(browser);
      await this.testNetworkRequestFailures(browser);
      await browser.close();

      // Run multi-browser test
      await this.testMultipleBrowsers();

      // Generate summary
      this.log('Browser Console Test Suite Completed', 'info');
      this.log(`Total Tests: ${this.results.summary.total}`, 'info');
      this.log(`Passed: ${this.results.summary.passed}`, 'success');
      this.log(`Failed: ${this.results.summary.failed}`, this.results.summary.failed > 0 ? 'error' : 'info');
      this.log(`Warnings: ${this.results.summary.warnings}`, this.results.summary.warnings > 0 ? 'warning' : 'info');
      this.log(`Total CSP Violations: ${this.results.cspViolations.length}`, this.results.cspViolations.length > 0 ? 'error' : 'success');
      this.log(`Total Console Errors: ${this.results.consoleErrors.length}`, this.results.consoleErrors.length > 0 ? 'warning' : 'success');

    } catch (error) {
      this.log(`Test suite error: ${error.message}`, 'error');
      if (browser) {
        await browser.close();
      }
    }

    return this.results;
  }

  /**
   * Save test results to file
   */
  saveResults(filename = 'browser-console-test-results.json') {
    const outputPath = path.join(process.cwd(), filename);
    fs.writeFileSync(outputPath, JSON.stringify(this.results, null, 2));
    this.log(`Test results saved to: ${outputPath}`, 'success');
  }
}

// Export for use in other modules
module.exports = { BrowserConsoleTestSuite };

// Run tests if this file is executed directly
if (require.main === module) {
  (async () => {
    const baseUrl = process.argv[2] || 'http://localhost:3001';
    const testSuite = new BrowserConsoleTestSuite(baseUrl);
    const results = await testSuite.runAllTests();
    testSuite.saveResults();

    // Exit with error code if any tests failed
    if (results.summary.failed > 0) {
      process.exit(1);
    }
  })();
}