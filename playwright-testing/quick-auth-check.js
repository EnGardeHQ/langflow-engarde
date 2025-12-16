#!/usr/bin/env node

/**
 * Quick Authentication Check Script
 *
 * This script provides a quick overview of the authentication system status
 * and the implementation of the key fixes.
 */

const { test, expect } = require('@playwright/test');
const { chromium } = require('playwright');

async function quickAuthCheck() {
  console.log('🔍 EnGarde Authentication Quick Check');
  console.log('=====================================\n');

  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    // Check servers are running
    console.log('1. 🌐 Checking server availability...');

    try {
      await page.goto('http://localhost:3001/login', { timeout: 10000 });
      console.log('   ✅ Frontend server (localhost:3001) - ACCESSIBLE');
    } catch (e) {
      console.log('   ❌ Frontend server (localhost:3001) - NOT ACCESSIBLE');
      return;
    }

    // Check autocomplete attributes
    console.log('\n2. 🔧 Checking autocomplete attributes...');

    const emailInput = page.locator('[data-testid="email-input"]');
    const passwordInput = page.locator('[data-testid="password-input"]');

    const emailAutocomplete = await emailInput.getAttribute('autoComplete');
    const passwordAutocomplete = await passwordInput.getAttribute('autoComplete');

    if (emailAutocomplete === 'username') {
      console.log('   ✅ Email field has autoComplete="username"');
    } else {
      console.log(`   ❌ Email field missing autoComplete="username" (current: ${emailAutocomplete})`);
    }

    if (passwordAutocomplete === 'current-password') {
      console.log('   ✅ Password field has autoComplete="current-password"');
    } else {
      console.log(`   ❌ Password field missing autoComplete="current-password" (current: ${passwordAutocomplete})`);
    }

    // Check form structure
    console.log('\n3. 📋 Checking form structure...');

    const brandTab = page.locator('button[role="tab"]:has-text("Brand")');
    const submitButton = page.locator('[data-testid="login-button"]:has-text("Sign In as Brand")');

    if (await brandTab.isVisible()) {
      console.log('   ✅ Brand tab present');
    } else {
      console.log('   ❌ Brand tab not found');
    }

    if (await submitButton.isVisible()) {
      console.log('   ✅ Submit button present');
    } else {
      console.log('   ❌ Submit button not found');
    }

    // Test basic interaction
    console.log('\n4. 🧪 Testing basic form interaction...');

    try {
      await brandTab.click();
      await emailInput.fill('test@engarde.ai');
      await passwordInput.fill('test123');
      console.log('   ✅ Form can be filled with test credentials');
    } catch (e) {
      console.log('   ❌ Form interaction failed:', e.message);
    }

    // Check for console errors
    console.log('\n5. 🐛 Monitoring for console errors...');

    const errors = [];
    page.on('console', (msg) => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });

    await page.waitForTimeout(2000);

    if (errors.length === 0) {
      console.log('   ✅ No console errors detected');
    } else {
      console.log(`   ⚠️ ${errors.length} console errors detected`);
      errors.slice(0, 3).forEach((error, i) => {
        console.log(`      ${i + 1}. ${error.substring(0, 100)}...`);
      });
    }

    // Test authentication attempt
    console.log('\n6. 🔐 Testing authentication attempt...');

    try {
      await submitButton.click();
      await page.waitForTimeout(5000);

      const currentUrl = page.url();
      if (currentUrl.includes('dashboard')) {
        console.log('   ✅ Authentication successful - redirected to dashboard');
      } else if (currentUrl.includes('login')) {
        console.log('   ❌ Authentication failed - remained on login page');
      } else {
        console.log(`   ⚠️ Unexpected redirect: ${currentUrl}`);
      }
    } catch (e) {
      console.log('   ❌ Authentication test failed:', e.message);
    }

    // Summary
    console.log('\n📊 QUICK CHECK SUMMARY');
    console.log('======================');
    console.log('✅ = Working correctly');
    console.log('❌ = Needs attention');
    console.log('⚠️ = Needs investigation');

    console.log('\n🔧 Priority Actions:');
    console.log('1. Add autoComplete="username" to email input');
    console.log('2. Add autoComplete="current-password" to password input');
    console.log('3. Investigate authentication backend connectivity');
    console.log('4. Verify test credentials are valid');

  } catch (error) {
    console.log('❌ Quick check failed:', error.message);
  } finally {
    await browser.close();
  }
}

// Run if called directly
if (require.main === module) {
  quickAuthCheck().catch(console.error);
}

module.exports = { quickAuthCheck };