/**
 * Global Setup for EnGarde Platform Testing
 *
 * This file handles global setup tasks that need to run before all tests,
 * including database seeding, authentication setup, and test data preparation.
 */

const { chromium } = require('@playwright/test');
const path = require('path');
const fs = require('fs');

async function globalSetup(config) {
  console.log('🚀 Starting global setup for EnGarde platform testing...');

  // Launch browser for authentication setup
  const browser = await chromium.launch();
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    // Wait for services to be ready
    console.log('⏳ Waiting for EnGarde services to be ready...');

    // Check frontend service
    await page.goto('http://localhost:3000', { waitUntil: 'networkidle', timeout: 60000 });
    console.log('✅ Frontend service is ready');

    // Check backend API
    const apiResponse = await page.request.get('http://localhost:8000/api/health');
    if (apiResponse.ok()) {
      console.log('✅ Backend API service is ready');
    } else {
      console.warn('⚠️ Backend API might not be fully ready');
    }

    // Setup test authentication states
    await setupAuthenticationStates(page);

    // Setup test data
    await setupTestData();

    console.log('✅ Global setup completed successfully');

  } catch (error) {
    console.error('❌ Global setup failed:', error);
    throw error;
  } finally {
    await context.close();
    await browser.close();
  }
}

async function setupAuthenticationStates(page) {
  console.log('🔑 Setting up authentication states...');

  const authStates = [
    {
      name: 'admin',
      email: 'admin@engarde.test',
      password: 'admin123',
      role: 'admin'
    },
    {
      name: 'coach',
      email: 'coach@engarde.test',
      password: 'coach123',
      role: 'coach'
    },
    {
      name: 'fencer',
      email: 'fencer@engarde.test',
      password: 'fencer123',
      role: 'fencer'
    }
  ];

  for (const auth of authStates) {
    try {
      console.log(`Setting up ${auth.role} authentication...`);

      // Navigate to login page
      await page.goto('/login');

      // Fill login form
      await page.fill('[data-testid="email-input"]', auth.email);
      await page.fill('[data-testid="password-input"]', auth.password);
      await page.click('[data-testid="login-button"]');

      // Wait for successful login
      await page.waitForURL('/dashboard', { timeout: 10000 });

      // Save authentication state
      const storageStatePath = path.join(
        '/Users/cope/EnGardeHQ/playwright-testing/config',
        `auth-${auth.name}.json`
      );
      await page.context().storageState({ path: storageStatePath });

      console.log(`✅ ${auth.role} authentication state saved`);

    } catch (error) {
      console.warn(`⚠️ Failed to setup ${auth.role} authentication:`, error.message);
      // Don't fail the entire setup for auth issues - tests can handle this
    }
  }
}

async function setupTestData() {
  console.log('📊 Setting up test data...');

  // Create test data directory if it doesn't exist
  const testDataDir = '/Users/cope/EnGardeHQ/playwright-testing/config/test-data';
  if (!fs.existsSync(testDataDir)) {
    fs.mkdirSync(testDataDir, { recursive: true });
  }

  // Create sample tournament data
  const tournamentData = {
    id: 'test-tournament-001',
    name: 'Playwright Test Tournament',
    date: '2024-12-01',
    location: 'Test Venue',
    weapon: 'epee',
    entries: [
      {
        id: 'fencer-001',
        name: 'Test Fencer 1',
        club: 'Test Club A',
        rating: 'A'
      },
      {
        id: 'fencer-002',
        name: 'Test Fencer 2',
        club: 'Test Club B',
        rating: 'B'
      }
    ]
  };

  const tournamentDataPath = path.join(testDataDir, 'tournament.json');
  fs.writeFileSync(tournamentDataPath, JSON.stringify(tournamentData, null, 2));

  // Create sample bout data
  const boutData = {
    id: 'test-bout-001',
    tournamentId: 'test-tournament-001',
    fencer1: 'fencer-001',
    fencer2: 'fencer-002',
    weapon: 'epee',
    targetScore: 15,
    timeLimit: 180,
    status: 'pending'
  };

  const boutDataPath = path.join(testDataDir, 'bout.json');
  fs.writeFileSync(boutDataPath, JSON.stringify(boutData, null, 2));

  console.log('✅ Test data setup completed');
}

module.exports = globalSetup;