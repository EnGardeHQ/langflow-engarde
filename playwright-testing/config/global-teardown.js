/**
 * Global Teardown for EnGarde Platform Testing
 *
 * This file handles cleanup tasks that need to run after all tests,
 * including cleaning up test data and generating final reports.
 */

const fs = require('fs');
const path = require('path');

async function globalTeardown(config) {
  console.log('🧹 Starting global teardown for EnGarde platform testing...');

  try {
    // Clean up temporary authentication files
    await cleanupAuthStates();

    // Clean up temporary test data
    await cleanupTestData();

    // Generate test summary
    await generateTestSummary();

    console.log('✅ Global teardown completed successfully');

  } catch (error) {
    console.error('❌ Global teardown failed:', error);
    // Don't throw - teardown failures shouldn't fail the entire test run
  }
}

async function cleanupAuthStates() {
  console.log('🔑 Cleaning up authentication states...');

  const authFiles = [
    '/Users/cope/EnGardeHQ/playwright-testing/config/auth-admin.json',
    '/Users/cope/EnGardeHQ/playwright-testing/config/auth-coach.json',
    '/Users/cope/EnGardeHQ/playwright-testing/config/auth-fencer.json'
  ];

  for (const file of authFiles) {
    try {
      if (fs.existsSync(file)) {
        fs.unlinkSync(file);
        console.log(`✅ Removed ${path.basename(file)}`);
      }
    } catch (error) {
      console.warn(`⚠️ Failed to remove ${file}:`, error.message);
    }
  }
}

async function cleanupTestData() {
  console.log('📊 Cleaning up test data...');

  const testDataDir = '/Users/cope/EnGardeHQ/playwright-testing/config/test-data';

  if (fs.existsSync(testDataDir)) {
    try {
      const files = fs.readdirSync(testDataDir);
      for (const file of files) {
        const filePath = path.join(testDataDir, file);
        fs.unlinkSync(filePath);
        console.log(`✅ Removed test data file: ${file}`);
      }

      // Remove the directory if it's empty
      if (fs.readdirSync(testDataDir).length === 0) {
        fs.rmdirSync(testDataDir);
        console.log('✅ Removed empty test data directory');
      }
    } catch (error) {
      console.warn('⚠️ Failed to clean up test data:', error.message);
    }
  }
}

async function generateTestSummary() {
  console.log('📋 Generating test summary...');

  const reportsDir = '/Users/cope/EnGardeHQ/playwright-testing/reports';
  const summaryPath = path.join(reportsDir, 'test-summary.txt');

  try {
    const timestamp = new Date().toISOString();
    const summary = [
      '='.repeat(60),
      'ENGARDE PLAYWRIGHT TESTING SUMMARY',
      '='.repeat(60),
      `Completed at: ${timestamp}`,
      `Reports directory: ${reportsDir}`,
      '',
      'Available Reports:',
      '- HTML Report: html-report/index.html',
      '- JSON Results: test-results.json',
      '- JUnit Report: junit-report.xml',
      '',
      'Test Artifacts:',
      '- Screenshots: Available for failed tests',
      '- Videos: Available for failed tests',
      '- Traces: Available for failed tests',
      '',
      'Next Steps:',
      '- Review HTML report for detailed test results',
      '- Check failed tests in test-results/ directory',
      '- Analyze traces for debugging failed tests',
      '='.repeat(60)
    ].join('\n');

    fs.writeFileSync(summaryPath, summary);
    console.log(`✅ Test summary generated: ${summaryPath}`);

  } catch (error) {
    console.warn('⚠️ Failed to generate test summary:', error.message);
  }
}

module.exports = globalTeardown;