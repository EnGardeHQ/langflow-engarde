/**
 * Playwright MCP Server Configuration for EnGarde Platform Testing
 *
 * This configuration file provides comprehensive settings for the Playwright MCP server
 * to support end-to-end testing of the EnGarde platform.
 */

module.exports = {
  // Server Configuration
  server: {
    host: 'localhost',
    port: 3001,
    outputDir: '/Users/cope/EnGardeHQ/playwright-testing/reports'
  },

  // Browser Configuration
  browser: {
    type: 'chrome', // Options: chrome, firefox, webkit, msedge
    headless: false, // Set to true for CI/CD environments
    device: null, // Can specify device like "iPhone 15" for mobile testing
    viewport: {
      width: 1920,
      height: 1080
    },
    userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 EnGarde-Testing'
  },

  // Security & Network Configuration
  security: {
    allowedOrigins: [
      'http://localhost:3001',
      'http://localhost:8000',
      'https://engarde.local',
      'https://staging.engarde.com',
      'https://app.engarde.com'
    ],
    blockedOrigins: [
      'https://analytics.google.com',
      'https://googletagmanager.com',
      'https://facebook.com',
      'https://doubleclick.net'
    ],
    blockServiceWorkers: true,
    ignoreHttpsErrors: true,
    noSandbox: false
  },

  // Timeout Configuration
  timeouts: {
    action: 10000, // 10 seconds for actions
    navigation: 30000, // 30 seconds for navigation
    assertion: 5000 // 5 seconds for assertions
  },

  // Storage and Session Configuration
  session: {
    isolated: false, // Set to true for completely isolated sessions
    saveSession: true,
    saveTrace: true,
    storageStatePath: '/Users/cope/EnGardeHQ/playwright-testing/config/storage-state.json',
    userDataDir: '/Users/cope/EnGardeHQ/playwright-testing/user-data'
  },

  // Capabilities
  capabilities: [
    'vision', // Enable vision capabilities for visual testing
    'pdf'     // Enable PDF generation capabilities
  ],

  // EnGarde Platform Specific Configuration
  enGarde: {
    baseUrl: 'http://localhost:3001',
    apiBaseUrl: 'http://localhost:8000',
    testUserCredentials: {
      admin: {
        email: 'admin@engarde.test',
        password: 'admin123'
      },
      coach: {
        email: 'coach@engarde.test',
        password: 'coach123'
      },
      fencer: {
        email: 'fencer@engarde.test',
        password: 'fencer123'
      }
    },
    testData: {
      tournament: {
        name: 'Test Tournament',
        date: '2024-12-01',
        location: 'Test Venue'
      },
      bout: {
        weapon: 'epee',
        duration: 180,
        targetScore: 15
      }
    }
  },

  // Reporting Configuration
  reporting: {
    screenshots: true,
    screenshotPath: '/Users/cope/EnGardeHQ/playwright-testing/screenshots',
    video: true,
    videoPath: '/Users/cope/EnGardeHQ/playwright-testing/reports/videos',
    trace: true,
    tracePath: '/Users/cope/EnGardeHQ/playwright-testing/reports/traces'
  }
};