const { chromium, devices } = require('playwright');
const fs = require('fs');
const path = require('path');

// Mobile devices to test
const mobileDevices = [
  { name: 'iPhone 14 Pro', device: devices['iPhone 14 Pro'] },
  { name: 'iPhone 12', device: devices['iPhone 12'] },
  { name: 'Galaxy S21', device: devices['Galaxy S21'] },
  { name: 'iPad Mini', device: devices['iPad Mini'] }
];

// Pages to capture (for non-admin users)
const pagesToCapture = [
  { name: 'landing', path: '/landing' },
  { name: 'dashboard', path: '/dashboard' },
  { name: 'agent-suite', path: '/agent-suite' },
  { name: 'insights', path: '/insights' },
  { name: 'profile', path: '/profile' },
  { name: 'settings', path: '/settings' }
];

async function captureScreenshots() {
  const outputDir = '/tmp/mobile-screenshots';
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const browser = await chromium.launch({ headless: true });

  for (const mobileDevice of mobileDevices) {
    console.log(`\n📱 Testing on ${mobileDevice.name}...`);

    const context = await browser.newContext({
      ...mobileDevice.device,
      viewport: mobileDevice.device.viewport
    });

    const page = await context.newPage();

    for (const pageInfo of pagesToCapture) {
      try {
        console.log(`  📸 Capturing ${pageInfo.name}...`);

        // Navigate to page
        await page.goto(`http://localhost:3003${pageInfo.path}`, {
          waitUntil: 'networkidle',
          timeout: 10000
        });

        // Wait a bit for any animations
        await page.waitForTimeout(2000);

        // Take full page screenshot
        const screenshotPath = path.join(
          outputDir,
          `${mobileDevice.name.replace(/\s+/g, '-')}-${pageInfo.name}.png`
        );

        await page.screenshot({
          path: screenshotPath,
          fullPage: true
        });

        console.log(`  ✅ Saved: ${screenshotPath}`);

        // Collect some metrics
        const metrics = await page.evaluate(() => {
          return {
            hasHorizontalScroll: document.documentElement.scrollWidth > document.documentElement.clientWidth,
            viewportWidth: window.innerWidth,
            contentWidth: document.documentElement.scrollWidth,
            hasOverflow: document.documentElement.scrollWidth > window.innerWidth
          };
        });

        if (metrics.hasHorizontalScroll) {
          console.log(`  ⚠️  Horizontal scroll detected! Content: ${metrics.contentWidth}px, Viewport: ${metrics.viewportWidth}px`);
        }

      } catch (error) {
        console.log(`  ❌ Error capturing ${pageInfo.name}: ${error.message}`);
      }
    }

    await context.close();
  }

  await browser.close();
  console.log(`\n✅ All screenshots saved to ${outputDir}`);
}

captureScreenshots().catch(console.error);
