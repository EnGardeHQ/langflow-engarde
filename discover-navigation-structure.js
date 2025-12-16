const { chromium } = require('playwright');

async function discoverNavigationStructure() {
  console.log('Discovering navigation structure...');

  const browser = await chromium.launch({
    headless: false,
    devtools: true
  });

  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    console.log('\n=== Login Process ===');
    await page.goto('http://localhost:3001', { waitUntil: 'networkidle' });
    await page.waitForTimeout(2000);

    // Login
    await page.click('a[href="/login"]');
    await page.waitForURL('**/login');
    await page.waitForSelector('input[type="email"]', { timeout: 10000 });
    await page.fill('input[type="email"]', 'demo@engarde.com');
    await page.fill('input[type="password"]', 'demo123');
    await page.click('button[type="submit"]');
    await page.waitForTimeout(3000);

    console.log('\n=== Discovering Navigation Elements ===');

    // Try to find various navigation containers
    const navSelectors = [
      'nav',
      '[role="navigation"]',
      '.sidebar',
      '.nav',
      '.navigation',
      'aside',
      '.menu',
      '[data-testid*="nav"]',
      '[data-testid*="sidebar"]',
      '.css-*' // For styled components
    ];

    for (const selector of navSelectors) {
      try {
        const elements = await page.locator(selector).all();
        if (elements.length > 0) {
          console.log(`\n📍 Found ${elements.length} element(s) with selector: ${selector}`);

          for (let i = 0; i < elements.length; i++) {
            const element = elements[i];
            const boundingBox = await element.boundingBox();
            const innerHTML = await element.innerHTML().catch(() => '[Could not get innerHTML]');
            const textContent = await element.textContent().catch(() => '[Could not get textContent]');

            console.log(`  Element ${i + 1}:`);
            console.log(`    Bounding box: ${JSON.stringify(boundingBox)}`);
            console.log(`    Text content: ${textContent?.slice(0, 200)}...`);
            console.log(`    HTML length: ${innerHTML.length} characters`);
          }
        }
      } catch (error) {
        // Silent fail for CSS selectors that don't exist
      }
    }

    console.log('\n=== Looking for Clickable Links ===');

    // Find all links and buttons
    const links = await page.locator('a').all();
    const buttons = await page.locator('button').all();

    console.log(`Found ${links.length} links and ${buttons.length} buttons`);

    const relevantLinks = [];
    for (const link of links) {
      try {
        const href = await link.getAttribute('href');
        const text = await link.textContent();
        const boundingBox = await link.boundingBox();

        if (href && boundingBox && (
          href.includes('/campaigns') ||
          href.includes('/analytics') ||
          href.includes('/workflow') ||
          href.includes('/agent') ||
          href.includes('/setting') ||
          href.includes('/profile') ||
          href.includes('/dashboard') ||
          text?.toLowerCase().includes('campaign') ||
          text?.toLowerCase().includes('analytic') ||
          text?.toLowerCase().includes('workflow') ||
          text?.toLowerCase().includes('agent') ||
          text?.toLowerCase().includes('setting') ||
          text?.toLowerCase().includes('profile') ||
          text?.toLowerCase().includes('dashboard')
        )) {
          relevantLinks.push({
            href,
            text: text?.trim(),
            boundingBox
          });
        }
      } catch (error) {
        // Skip problematic links
      }
    }

    console.log('\n📎 Relevant Navigation Links Found:');
    relevantLinks.forEach((link, index) => {
      console.log(`  ${index + 1}. "${link.text}" -> ${link.href}`);
      console.log(`     Position: ${JSON.stringify(link.boundingBox)}`);
    });

    console.log('\n=== Page Structure Analysis ===');

    // Get the page structure
    const pageStructure = await page.evaluate(() => {
      function getElementInfo(element, depth = 0) {
        if (depth > 5) return null; // Limit depth

        const info = {
          tagName: element.tagName.toLowerCase(),
          id: element.id || null,
          classes: Array.from(element.classList),
          childCount: element.children.length,
          textContent: element.textContent?.slice(0, 50) || null
        };

        if (element.children.length > 0 && depth < 3) {
          info.children = Array.from(element.children)
            .slice(0, 10) // Limit children
            .map(child => getElementInfo(child, depth + 1))
            .filter(Boolean);
        }

        return info;
      }

      // Get main containers
      const body = getElementInfo(document.body, 0);
      const main = document.querySelector('main');
      const mainInfo = main ? getElementInfo(main, 0) : null;

      return {
        body,
        main: mainInfo,
        url: window.location.href
      };
    });

    console.log('Current URL:', pageStructure.url);
    console.log('Main element structure:', JSON.stringify(pageStructure.main, null, 2));

    // Take a screenshot for manual inspection
    await page.screenshot({ path: 'navigation-discovery.png', fullPage: true });
    console.log('\n📸 Full page screenshot saved as navigation-discovery.png');

    // Save the discovered structure
    require('fs').writeFileSync('navigation-structure.json', JSON.stringify({
      relevantLinks,
      pageStructure,
      timestamp: new Date().toISOString()
    }, null, 2));

    console.log('📄 Navigation structure saved to navigation-structure.json');

  } catch (error) {
    console.error('Discovery failed:', error);
  } finally {
    await browser.close();
  }
}

discoverNavigationStructure().catch(console.error);