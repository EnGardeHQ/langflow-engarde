# EnGarde Playwright MCP Testing Suite

A comprehensive end-to-end testing solution for the EnGarde fencing tournament management platform using Microsoft's official Playwright MCP (Model Context Protocol) server.

## Overview

This testing suite provides production-ready automated testing capabilities for the EnGarde platform, including:

- **Authentication Testing**: User login, logout, and role-based access control
- **Tournament Management**: Tournament creation, editing, and lifecycle management
- **Bout Scoring**: Real-time scoring, timer management, and bout completion
- **Cross-browser Testing**: Support for Chrome, Firefox, Safari, and Edge
- **Mobile Testing**: iOS and Android viewport testing
- **Visual Testing**: Screenshot comparison and visual regression detection
- **API Testing**: Backend API endpoint validation
- **Performance Testing**: Load time and response time monitoring

## Architecture

### Components

- **Playwright MCP Server**: Microsoft's official MCP server for browser automation
- **Test Framework**: Playwright Test with comprehensive configuration
- **Test Suites**: Organized by feature areas (auth, tournaments, scoring)
- **Reporting**: HTML, JSON, and JUnit reports with visual artifacts
- **CI/CD Integration**: Ready for GitHub Actions, GitLab CI, and Jenkins

### Directory Structure

```
playwright-testing/
├── config/
│   ├── playwright-mcp.config.js    # MCP server configuration
│   ├── playwright.config.js        # Test framework configuration
│   ├── global-setup.js             # Global test setup
│   ├── global-teardown.js          # Global test cleanup
│   └── test-data/                  # Test data files
├── tests/
│   ├── auth/                       # Authentication tests
│   ├── tournaments/                # Tournament management tests
│   ├── scoring/                    # Bout scoring tests
│   └── api/                        # API tests
├── reports/                        # Test reports and artifacts
├── screenshots/                    # Test screenshots
├── user-data/                      # Browser user data
├── package.json                    # Node.js dependencies
├── start-mcp-server.sh            # MCP server startup script
└── README.md                       # This file
```

## Prerequisites

- **Node.js**: Version 18.0.0 or higher
- **EnGarde Platform**: Frontend running on localhost:3000
- **EnGarde API**: Backend running on localhost:8000
- **Operating System**: macOS, Windows, or Linux

## Installation

### 1. Install Dependencies

```bash
cd /Users/cope/EnGardeHQ/playwright-testing
npm install
```

### 2. Install Browser Binaries

```bash
npx playwright install
```

### 3. Verify Installation

```bash
# Check Playwright MCP server version
npx @playwright/mcp --version

# Check Playwright test framework version
npx playwright --version

# List available tests
npx playwright test --list
```

## Configuration

### MCP Server Configuration

The MCP server is configured via `/Users/cope/EnGardeHQ/playwright-testing/config/playwright-mcp.config.js`:

```javascript
module.exports = {
  server: {
    host: 'localhost',
    port: 3001
  },
  browser: {
    type: 'chrome',
    headless: false,
    viewport: { width: 1920, height: 1080 }
  },
  security: {
    allowedOrigins: [
      'http://localhost:3000',
      'http://localhost:8000'
    ]
  },
  capabilities: ['vision', 'pdf']
};
```

### Test Framework Configuration

The test framework is configured via `/Users/cope/EnGardeHQ/playwright-testing/config/playwright.config.js` with:

- Multi-browser support (Chrome, Firefox, Safari, Edge)
- Mobile device emulation
- Comprehensive reporting
- Screenshot and video capture on failure
- Trace recording for debugging

## Usage

### Starting the MCP Server

```bash
# Using the startup script (recommended)
./start-mcp-server.sh

# Manual startup
npx @playwright/mcp \
    --browser chrome \
    --viewport-size "1920,1080" \
    --caps vision,pdf \
    --host localhost \
    --port 3001
```

### Running Tests

```bash
# Run all tests
npm test

# Run tests in headed mode (visible browser)
npm run test:headed

# Run specific test suites
npm run test:auth           # Authentication tests
npm run test:tournaments    # Tournament management tests
npm run test:scoring        # Bout scoring tests

# Run tests with UI mode (interactive)
npm run test:ui

# Debug tests
npm run test:debug

# View test reports
npm run test:report
```

### Test Execution Options

```bash
# Run tests on specific browser
npx playwright test --project=chromium
npx playwright test --project=firefox
npx playwright test --project=webkit

# Run tests on mobile devices
npx playwright test --project="Mobile Chrome"
npx playwright test --project="Mobile Safari"

# Run specific test file
npx playwright test tests/auth/login.spec.js

# Run tests matching pattern
npx playwright test --grep "login"

# Run tests with specific configuration
npx playwright test --config=config/playwright.config.js
```

## Test Structure

### Authentication Tests (`tests/auth/login.spec.js`)

- Login form validation
- Successful authentication for different roles (admin, coach, fencer)
- Invalid credentials handling
- Session management and logout
- Role-based access control

### Tournament Management Tests (`tests/tournaments/tournament-management.spec.js`)

- Tournament creation and editing
- Tournament listing and filtering
- Tournament deletion with confirmation
- Tournament status management
- Tournament search and sorting

### Bout Scoring Tests (`tests/scoring/bout-scoring.spec.js`)

- Bout timer functionality
- Touch recording for both fencers
- Double touch and no touch handling
- Penalty card management
- Bout completion scenarios
- Score validation and undo functionality

## Reporting and Artifacts

### Available Reports

1. **HTML Report**: Interactive report with test results, screenshots, and videos
   - Location: `reports/html-report/index.html`
   - View: `npm run test:report`

2. **JSON Report**: Machine-readable test results
   - Location: `reports/test-results.json`

3. **JUnit Report**: CI/CD compatible XML format
   - Location: `reports/junit-report.xml`

### Test Artifacts

- **Screenshots**: Captured on test failure
- **Videos**: Recorded for failed tests
- **Traces**: Detailed execution traces for debugging
- **Logs**: Console logs and network activity

## Authentication States

The test suite supports persistent authentication states for different user roles:

```bash
config/auth-admin.json    # Administrator authentication
config/auth-coach.json    # Coach authentication
config/auth-fencer.json   # Fencer authentication
```

These are automatically generated during global setup and used in role-specific tests.

## Environment Variables

Configure the testing environment via the `.env` file:

```bash
# EnGarde Platform URLs
FRONTEND_URL=http://localhost:3000
API_URL=http://localhost:8000

# Test Configuration
TEST_TIMEOUT=60000
BROWSER_TIMEOUT=30000
HEADLESS_MODE=false

# Test Data
ADMIN_EMAIL=admin@engarde.test
ADMIN_PASSWORD=admin123
COACH_EMAIL=coach@engarde.test
COACH_PASSWORD=coach123
FENCER_EMAIL=fencer@engarde.test
FENCER_PASSWORD=fencer123
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: E2E Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: |
          cd playwright-testing
          npm install
          npx playwright install

      - name: Start EnGarde services
        run: |
          docker-compose up -d

      - name: Run Playwright tests
        run: |
          cd playwright-testing
          npm test

      - name: Upload test reports
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: playwright-report
          path: playwright-testing/reports/
```

## Troubleshooting

### Common Issues

1. **Tests failing to start**
   - Ensure EnGarde frontend is running on localhost:3000
   - Ensure EnGarde backend is running on localhost:8000
   - Check browser installation: `npx playwright install`

2. **Authentication errors**
   - Verify test user accounts exist in the database
   - Check credentials in environment variables
   - Clear authentication state files in `config/`

3. **Network timeouts**
   - Increase timeout values in `playwright.config.js`
   - Check network connectivity to EnGarde services
   - Verify firewall settings

4. **Browser launch failures**
   - Update browser binaries: `npx playwright install`
   - Check system dependencies: `npx playwright install-deps`
   - Try headless mode: `npm run test -- --headed=false`

### Debug Mode

```bash
# Run tests in debug mode
npm run test:debug

# Run specific test in debug mode
npx playwright test tests/auth/login.spec.js --debug

# Enable verbose logging
DEBUG=pw:api npm test
```

### Trace Analysis

```bash
# Generate trace files
npx playwright test --trace on

# View trace files
npx playwright show-trace reports/traces/trace.zip
```

## Performance Optimization

### Parallel Execution

Tests run in parallel by default. Configure workers in `playwright.config.js`:

```javascript
workers: process.env.CI ? 1 : undefined, // Adjust for your system
```

### Browser Context Reuse

Authentication states are preserved across tests to avoid repeated login operations.

### Selective Test Execution

```bash
# Run only changed tests
npx playwright test --only-changed

# Run tests by tag
npx playwright test --grep "@smoke"

# Skip expensive tests
npx playwright test --grep-invert "@slow"
```

## Security Considerations

### Test Data Isolation

- Tests use dedicated test data and user accounts
- Database state is reset between test runs
- Sensitive data is stored in environment variables

### Network Security

- MCP server restricts allowed origins
- Blocks known tracking and analytics domains
- Service workers are disabled for consistent behavior

### Authentication Security

- Test authentication states are temporary
- Credentials are managed via environment variables
- Sessions are cleaned up after test completion

## Advanced Features

### Visual Testing

```javascript
// Screenshot comparison
await expect(page).toHaveScreenshot('tournament-list.png');

// Element screenshot
await expect(page.locator('.scoring-panel')).toHaveScreenshot();
```

### API Testing Integration

```javascript
// API calls within browser context
const response = await page.request.get('/api/tournaments');
expect(response.ok()).toBeTruthy();
```

### Custom Fixtures

```javascript
// Page object model
const { test, expect } = require('@playwright/test');
const { LoginPage } = require('../pages/login-page');

test('login with page object', async ({ page }) => {
  const loginPage = new LoginPage(page);
  await loginPage.goto();
  await loginPage.login('admin@engarde.test', 'admin123');
  await expect(page).toHaveURL('/dashboard');
});
```

## Maintenance

### Regular Updates

```bash
# Update Playwright
npm update @playwright/test

# Update browser binaries
npx playwright install

# Update MCP server
npm update @playwright/mcp
```

### Test Maintenance

1. **Review test results regularly**
2. **Update selectors when UI changes**
3. **Maintain test data consistency**
4. **Monitor test execution times**
5. **Update browser configurations**

## Support and Documentation

- **Playwright Documentation**: https://playwright.dev/docs
- **MCP Server Documentation**: https://github.com/microsoft/playwright-mcp
- **EnGarde Platform Documentation**: Internal documentation
- **Issue Tracking**: GitHub Issues or internal bug tracker

## Contributing

1. Follow existing test patterns and naming conventions
2. Add comprehensive test coverage for new features
3. Update documentation for configuration changes
4. Test on multiple browsers before committing
5. Include proper error handling and cleanup

## License

This testing suite is part of the EnGarde platform and follows the same licensing terms.