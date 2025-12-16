/**
 * Manual Browser Test for EnGarde Authentication
 * This will launch a browser, navigate to login page, and test the authentication flow
 */

const { chromium } = require('playwright');
const fs = require('fs');

async function testLogin() {
    console.log('🚀 Starting manual browser test...');

    const browser = await chromium.launch({
        headless: false, // Show browser for debugging
        devtools: true   // Open DevTools
    });

    const context = await browser.newContext();
    const page = await context.newPage();

    const logs = [];
    const errors = [];
    const networkLogs = [];

    // Capture console logs
    page.on('console', msg => {
        const log = `[${msg.type()}] ${msg.text()}`;
        logs.push(log);
        console.log(log);
    });

    // Capture errors
    page.on('pageerror', error => {
        const errorMsg = `PAGE ERROR: ${error.message}`;
        errors.push(errorMsg);
        console.error(errorMsg);
    });

    // Capture network requests
    page.on('request', request => {
        if (request.url().includes('localhost') || request.url().includes('api')) {
            networkLogs.push(`REQUEST: ${request.method()} ${request.url()}`);
        }
    });

    page.on('response', response => {
        if (response.url().includes('localhost') || response.url().includes('api')) {
            networkLogs.push(`RESPONSE: ${response.status()} ${response.url()}`);
        }
    });

    try {
        console.log('📍 Navigating to login page...');
        await page.goto('http://localhost:3000/login');

        console.log('📍 Waiting for page to load...');
        await page.waitForTimeout(5000);

        console.log('📍 Taking initial screenshot...');
        await page.screenshot({ path: '/Users/cope/EnGardeHQ/login-page-loaded.png' });

        console.log('📍 Looking for email input...');
        const emailInput = await page.locator('input[type="email"]').first();
        await emailInput.waitFor({ timeout: 10000 });

        console.log('📍 Looking for password input...');
        const passwordInput = await page.locator('input[type="password"]').first();
        await passwordInput.waitFor({ timeout: 10000 });

        console.log('📍 Looking for submit button...');
        const submitButton = await page.locator('button[type="submit"]').first();
        await submitButton.waitFor({ timeout: 10000 });

        console.log('📍 Filling in credentials...');
        await emailInput.fill('admin@engarde.ai');
        await passwordInput.fill('admin123');

        console.log('📍 Taking screenshot before submit...');
        await page.screenshot({ path: '/Users/cope/EnGardeHQ/before-login-submit.png' });

        console.log('📍 Submitting login form...');
        await submitButton.click();

        console.log('📍 Waiting for response...');
        await page.waitForTimeout(8000);

        console.log('📍 Taking screenshot after submit...');
        await page.screenshot({ path: '/Users/cope/EnGardeHQ/after-login-submit.png' });

        // Check current URL
        const currentUrl = page.url();
        console.log(`📍 Current URL: ${currentUrl}`);

        // Check for any error messages on page
        const errorElements = await page.locator('[data-testid="error-message"]').count();
        console.log(`📍 Error messages found: ${errorElements}`);

        if (errorElements > 0) {
            const errorText = await page.locator('[data-testid="error-message"]').first().textContent();
            console.log(`📍 Error message: ${errorText}`);
        }

        console.log('✅ Test completed successfully!');

    } catch (error) {
        console.error('❌ Test failed:', error);
        await page.screenshot({ path: '/Users/cope/EnGardeHQ/test-error.png' });
        errors.push(`TEST ERROR: ${error.message}`);
    }

    // Wait a bit longer to capture any delayed network activity
    await page.waitForTimeout(3000);

    console.log('\n📊 SUMMARY:');
    console.log(`Console logs: ${logs.length}`);
    console.log(`Errors: ${errors.length}`);
    console.log(`Network requests: ${networkLogs.length}`);

    // Save detailed report
    const report = {
        timestamp: new Date().toISOString(),
        currentUrl: await page.url().catch(() => 'unknown'),
        logs: logs,
        errors: errors,
        networkLogs: networkLogs
    };

    fs.writeFileSync('/Users/cope/EnGardeHQ/manual-browser-test-report.json', JSON.stringify(report, null, 2));
    console.log('📄 Report saved to manual-browser-test-report.json');

    console.log('🔍 Keeping browser open for 30 seconds for manual inspection...');
    await page.waitForTimeout(30000);

    await browser.close();
    console.log('🏁 Test completed!');
}

// Run the test
testLogin().catch(console.error);