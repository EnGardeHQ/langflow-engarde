/**
 * Playwright Test Configuration for EnGarde Platform
 *
 * This configuration file sets up comprehensive end-to-end testing
 * for the EnGarde fencing tournament management platform.
 */

const { defineConfig, devices } = require('@playwright/test');

/**
 * @see https://playwright.dev/docs/test-configuration
 */
module.exports = defineConfig({
  testDir: '/Users/cope/EnGardeHQ/playwright-testing/tests',

  /* Run tests in files in parallel */
  fullyParallel: true,

  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,

  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,

  /* Opt out of parallel tests on CI. */
  workers: process.env.CI ? 1 : undefined,

  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: [
    ['html', { outputFolder: '/Users/cope/EnGardeHQ/playwright-testing/reports/html-report' }],
    ['json', { outputFile: '/Users/cope/EnGardeHQ/playwright-testing/reports/test-results.json' }],
    ['junit', { outputFile: '/Users/cope/EnGardeHQ/playwright-testing/reports/junit-report.xml' }],
    ['list']
  ],

  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    baseURL: 'http://localhost:3001',

    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'on-first-retry',

    /* Take screenshot on failure */
    screenshot: 'only-on-failure',

    /* Record video on failure */
    video: 'retain-on-failure',

    /* Timeout for each action */
    actionTimeout: 10000,

    /* Timeout for navigation */
    navigationTimeout: 30000,

    /* Global test timeout */
    testTimeout: 60000,

    /* Custom user agent */
    userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 EnGarde-Testing',

    /* Ignore HTTPS errors */
    ignoreHTTPSErrors: true,

    /* Viewport size */
    viewport: { width: 1920, height: 1080 },

    /* Locale */
    locale: 'en-US',

    /* Timezone */
    timezoneId: 'America/New_York'
  },

  /* Configure projects for major browsers */
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },

    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },

    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },

    /* Test against mobile viewports. */
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },

    /* Test against branded browsers. */
    {
      name: 'Microsoft Edge',
      use: { ...devices['Desktop Edge'], channel: 'msedge' },
    },
    {
      name: 'Google Chrome',
      use: { ...devices['Desktop Chrome'], channel: 'chrome' },
    },
  ],

  /* Global Setup */
  globalSetup: '/Users/cope/EnGardeHQ/playwright-testing/config/global-setup.js',

  /* Global Teardown */
  globalTeardown: '/Users/cope/EnGardeHQ/playwright-testing/config/global-teardown.js',

  /* Run your local dev server before starting the tests */
  webServer: [
    {
      command: 'cd /Users/cope/EnGardeHQ && npm run dev:frontend',
      port: 3001,
      reuseExistingServer: !process.env.CI,
      timeout: 120000,
      env: {
        NODE_ENV: 'test'
      }
    },
    {
      command: 'cd /Users/cope/EnGardeHQ && npm run dev:backend',
      port: 8000,
      reuseExistingServer: !process.env.CI,
      timeout: 120000,
      env: {
        NODE_ENV: 'test'
      }
    }
  ],

  /* Output directory for test artifacts */
  outputDir: '/Users/cope/EnGardeHQ/playwright-testing/reports/test-results',

  /* EnGarde Platform specific configuration */
  expect: {
    /* Timeout for expect() calls */
    timeout: 5000,
    /* Take screenshot on assertion failure */
    toHaveScreenshot: { mode: 'only-on-failure' }
  }
});