const { test, expect } = require('@playwright/test');

/**
 * Performance and Reliability Authentication Tests
 * Tests authentication under various load and stress conditions
 */

const BASE_URL = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3001';
const API_BASE_URL = process.env.PLAYWRIGHT_API_URL || 'http://localhost:8000';

// Test configuration
const PERFORMANCE_THRESHOLDS = {
  maxLoginTime: 10000,        // 10 seconds
  maxPageLoadTime: 5000,      // 5 seconds
  maxApiResponseTime: 3000,   // 3 seconds
  maxTokenValidationTime: 2000 // 2 seconds
};

const TEST_USER = {
  email: 'publisher@test.com',
  password: 'TestPassword123!',
  userType: 'publisher'
};

class PerformanceMonitor {
  constructor(page) {
    this.page = page;
    this.metrics = {
      pageLoads: [],
      apiCalls: [],
      authOperations: [],
      redirects: [],
      errors: []
    };
    this.startMonitoring();
  }

  startMonitoring() {
    // Monitor page load performance
    this.page.on('load', () => {
      this.page.evaluate(() => {
        const navigation = performance.getEntriesByType('navigation')[0];
        window._pageLoadMetrics = {
          domContentLoaded: navigation.domContentLoadedEventEnd - navigation.domContentLoadedEventStart,
          loadComplete: navigation.loadEventEnd - navigation.loadEventStart,
          totalTime: navigation.loadEventEnd - navigation.navigationStart,
          timestamp: Date.now()
        };
      });
    });

    // Monitor API calls
    this.page.on('response', (response) => {
      if (response.url().includes('/api/')) {
        const timing = response.timing();
        this.metrics.apiCalls.push({
          url: response.url(),
          status: response.status(),
          method: response.request().method(),
          responseTime: timing.responseEnd - timing.requestStart,
          timestamp: Date.now()
        });
      }

      // Monitor redirects
      if ([301, 302, 303, 307, 308].includes(response.status())) {
        this.metrics.redirects.push({
          from: response.url(),
          to: response.headers()['location'],
          status: response.status(),
          timestamp: Date.now()
        });
      }
    });

    // Monitor console errors
    this.page.on('console', (msg) => {
      if (msg.type() === 'error') {
        this.metrics.errors.push({
          text: msg.text(),
          location: msg.location(),
          timestamp: Date.now()
        });
      }
    });

    // Monitor page errors
    this.page.on('pageerror', (error) => {
      this.metrics.errors.push({
        text: error.message,
        stack: error.stack,
        type: 'pageerror',
        timestamp: Date.now()
      });
    });
  }

  async recordAuthOperation(operation, startTime) {
    const endTime = Date.now();
    const duration = endTime - startTime;

    this.metrics.authOperations.push({
      operation,
      duration,
      timestamp: endTime
    });

    return duration;
  }

  async getPageLoadMetrics() {
    try {
      const metrics = await this.page.evaluate(() => window._pageLoadMetrics);
      if (metrics) {
        this.metrics.pageLoads.push(metrics);
      }
      return metrics;
    } catch (error) {
      return null;
    }
  }

  async measureResourceUsage() {
    return await this.page.evaluate(() => {
      const memory = performance.memory || {};
      return {
        usedJSHeapSize: memory.usedJSHeapSize || 0,
        totalJSHeapSize: memory.totalJSHeapSize || 0,
        jsHeapSizeLimit: memory.jsHeapSizeLimit || 0,
        timestamp: Date.now()
      };
    });
  }

  getPerformanceReport() {
    const report = {
      summary: {
        totalPageLoads: this.metrics.pageLoads.length,
        totalApiCalls: this.metrics.apiCalls.length,
        totalAuthOperations: this.metrics.authOperations.length,
        totalRedirects: this.metrics.redirects.length,
        totalErrors: this.metrics.errors.length
      },
      performance: {
        avgPageLoadTime: this.calculateAverage(this.metrics.pageLoads, 'totalTime'),
        avgApiResponseTime: this.calculateAverage(this.metrics.apiCalls, 'responseTime'),
        avgAuthOperationTime: this.calculateAverage(this.metrics.authOperations, 'duration'),
        slowestApiCall: this.findSlowest(this.metrics.apiCalls, 'responseTime'),
        slowestAuthOperation: this.findSlowest(this.metrics.authOperations, 'duration')
      },
      thresholdViolations: this.checkThresholds(),
      errors: this.metrics.errors,
      recommendations: this.generateRecommendations()
    };

    return report;
  }

  calculateAverage(array, field) {
    if (array.length === 0) return 0;
    const sum = array.reduce((acc, item) => acc + (item[field] || 0), 0);
    return Math.round(sum / array.length);
  }

  findSlowest(array, field) {
    if (array.length === 0) return null;
    return array.reduce((slowest, item) => {
      return (item[field] || 0) > (slowest[field] || 0) ? item : slowest;
    });
  }

  checkThresholds() {
    const violations = [];

    // Check auth operation thresholds
    this.metrics.authOperations.forEach(op => {
      if (op.operation === 'login' && op.duration > PERFORMANCE_THRESHOLDS.maxLoginTime) {
        violations.push({
          type: 'login_time',
          threshold: PERFORMANCE_THRESHOLDS.maxLoginTime,
          actual: op.duration,
          severity: 'high'
        });
      }
    });

    // Check API response thresholds
    this.metrics.apiCalls.forEach(call => {
      if (call.responseTime > PERFORMANCE_THRESHOLDS.maxApiResponseTime) {
        violations.push({
          type: 'api_response_time',
          url: call.url,
          threshold: PERFORMANCE_THRESHOLDS.maxApiResponseTime,
          actual: call.responseTime,
          severity: 'medium'
        });
      }
    });

    // Check page load thresholds
    this.metrics.pageLoads.forEach(load => {
      if (load.totalTime > PERFORMANCE_THRESHOLDS.maxPageLoadTime) {
        violations.push({
          type: 'page_load_time',
          threshold: PERFORMANCE_THRESHOLDS.maxPageLoadTime,
          actual: load.totalTime,
          severity: 'medium'
        });
      }
    });

    return violations;
  }

  generateRecommendations() {
    const recommendations = [];
    const violations = this.checkThresholds();

    if (violations.find(v => v.type === 'login_time')) {
      recommendations.push('Consider optimizing login API performance or implementing progressive loading');
    }

    if (violations.find(v => v.type === 'api_response_time')) {
      recommendations.push('Implement API response caching or optimize backend performance');
    }

    if (violations.find(v => v.type === 'page_load_time')) {
      recommendations.push('Optimize frontend bundle size or implement code splitting');
    }

    if (this.metrics.errors.length > 5) {
      recommendations.push('Investigate and fix frequent console errors to improve stability');
    }

    return recommendations;
  }

  async clearAuthState() {
    await this.page.evaluate(() => {
      localStorage.clear();
      sessionStorage.clear();
      document.cookie.split(";").forEach(function(c) {
        document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/");
      });
    });
  }

  async fillAndSubmitLogin() {
    await this.page.fill('[data-testid="email-input"], input[type="email"], input[name="email"]', TEST_USER.email);
    await this.page.fill('[data-testid="password-input"], input[type="password"], input[name="password"]', TEST_USER.password);

    const userTypeSelector = await this.page.$('[data-testid="user-type-select"], select[name="userType"]');
    if (userTypeSelector) {
      await this.page.selectOption('[data-testid="user-type-select"], select[name="userType"]', TEST_USER.userType);
    }

    const submitButton = await this.page.$('[data-testid="login-submit"], button[type="submit"], button:has-text("Login")');
    if (submitButton) {
      await submitButton.click();
    } else {
      await this.page.keyboard.press('Enter');
    }
  }
}

test.describe('Performance and Reliability Tests', () => {
  let perfMonitor;

  test.beforeEach(async ({ page }) => {
    perfMonitor = new PerformanceMonitor(page);
    await perfMonitor.clearAuthState();
    await page.goto(BASE_URL);
    await page.waitForLoadState('networkidle');
  });

  test.afterEach(async ({ page }) => {
    const report = perfMonitor.getPerformanceReport();
    console.log('📊 Performance Report:', JSON.stringify(report, null, 2));

    // Log any threshold violations
    if (report.thresholdViolations.length > 0) {
      console.warn('⚠️ Performance threshold violations:', report.thresholdViolations);
    }

    // Log recommendations
    if (report.recommendations.length > 0) {
      console.log('💡 Performance recommendations:', report.recommendations);
    }
  });

  test.describe('Authentication Performance', () => {
    test('should complete login within performance thresholds', async ({ page }) => {
      console.log('🧪 Testing login performance...');

      await page.goto(`${BASE_URL}/login`);
      await page.waitForLoadState('networkidle');

      const startTime = Date.now();
      await perfMonitor.fillAndSubmitLogin();

      // Wait for authentication to complete
      try {
        await page.waitForURL('**/dashboard**', { timeout: PERFORMANCE_THRESHOLDS.maxLoginTime });
      } catch (error) {
        console.log('⚠️ Login did not complete within threshold');
      }

      const loginDuration = await perfMonitor.recordAuthOperation('login', startTime);

      // Verify performance
      expect(loginDuration).toBeLessThan(PERFORMANCE_THRESHOLDS.maxLoginTime);

      // Get page load metrics
      const pageMetrics = await perfMonitor.getPageLoadMetrics();
      if (pageMetrics) {
        expect(pageMetrics.totalTime).toBeLessThan(PERFORMANCE_THRESHOLDS.maxPageLoadTime);
      }

      console.log(`✅ Login completed in ${loginDuration}ms`);
    });

    test('should validate tokens quickly', async ({ page }) => {
      console.log('🧪 Testing token validation performance...');

      // First login to get valid tokens
      await page.goto(`${BASE_URL}/login`);
      await perfMonitor.fillAndSubmitLogin();
      await page.waitForURL('**/dashboard**', { timeout: 15000 });

      // Measure token validation on page refresh
      const startTime = Date.now();
      await page.reload();
      await page.waitForLoadState('networkidle');

      const validationDuration = await perfMonitor.recordAuthOperation('token_validation', startTime);

      // Should validate quickly and remain authenticated
      expect(validationDuration).toBeLessThan(PERFORMANCE_THRESHOLDS.maxTokenValidationTime);
      expect(page.url()).toContain('dashboard');

      console.log(`✅ Token validation completed in ${validationDuration}ms`);
    });

    test('should handle authentication API calls efficiently', async ({ page }) => {
      console.log('🧪 Testing authentication API efficiency...');

      await page.goto(`${BASE_URL}/login`);
      await perfMonitor.fillAndSubmitLogin();

      // Wait for all API calls to complete
      await page.waitForTimeout(5000);

      // Analyze API performance
      const report = perfMonitor.getPerformanceReport();
      const authApiCalls = perfMonitor.metrics.apiCalls.filter(call =>
        call.url.includes('/auth/') || call.url.includes('/me')
      );

      // Should have reasonable number of auth API calls
      expect(authApiCalls.length).toBeLessThan(10);

      // All auth API calls should be reasonably fast
      authApiCalls.forEach(call => {
        expect(call.responseTime).toBeLessThan(PERFORMANCE_THRESHOLDS.maxApiResponseTime);
      });

      console.log(`✅ Authentication API calls: ${authApiCalls.length}, avg response time: ${report.performance.avgApiResponseTime}ms`);
    });
  });

  test.describe('Load and Stress Testing', () => {
    test('should handle multiple rapid login attempts', async ({ page }) => {
      console.log('🧪 Testing multiple rapid login attempts...');

      for (let i = 0; i < 5; i++) {
        await page.goto(`${BASE_URL}/login`);
        await page.waitForLoadState('networkidle');

        const startTime = Date.now();
        await perfMonitor.fillAndSubmitLogin();

        // Don't wait for full completion, just measure responsiveness
        await page.waitForTimeout(2000);

        await perfMonitor.recordAuthOperation(`rapid_login_${i}`, startTime);

        // Clear state for next attempt
        await perfMonitor.clearAuthState();
      }

      const report = perfMonitor.getPerformanceReport();

      // Should handle multiple attempts without significant degradation
      expect(report.summary.totalErrors).toBeLessThan(10);
      expect(report.performance.avgAuthOperationTime).toBeLessThan(PERFORMANCE_THRESHOLDS.maxLoginTime);

      console.log(`✅ Handled ${report.summary.totalAuthOperations} rapid login attempts`);
    });

    test('should maintain performance under memory pressure', async ({ page }) => {
      console.log('🧪 Testing performance under memory pressure...');

      // Create memory pressure
      await page.evaluate(() => {
        window._memoryPressure = [];
        for (let i = 0; i < 100; i++) {
          window._memoryPressure.push(new Array(50000).fill(`data-${i}`));
        }
      });

      const memoryBefore = await perfMonitor.measureResourceUsage();

      // Perform authentication under memory pressure
      await page.goto(`${BASE_URL}/login`);
      const startTime = Date.now();
      await perfMonitor.fillAndSubmitLogin();

      try {
        await page.waitForURL('**/dashboard**', { timeout: PERFORMANCE_THRESHOLDS.maxLoginTime * 2 });
      } catch (error) {
        console.log('⚠️ Login under memory pressure took longer than expected');
      }

      const loginDuration = await perfMonitor.recordAuthOperation('login_memory_pressure', startTime);
      const memoryAfter = await perfMonitor.measureResourceUsage();

      // Should still complete within reasonable time (allow 2x normal threshold)
      expect(loginDuration).toBeLessThan(PERFORMANCE_THRESHOLDS.maxLoginTime * 2);

      console.log(`✅ Login under memory pressure: ${loginDuration}ms`);
      console.log(`Memory usage - Before: ${Math.round(memoryBefore.usedJSHeapSize / 1024 / 1024)}MB, After: ${Math.round(memoryAfter.usedJSHeapSize / 1024 / 1024)}MB`);
    });

    test('should handle concurrent authentication operations', async ({ page, browser }) => {
      console.log('🧪 Testing concurrent authentication operations...');

      // Create multiple browser contexts for concurrent testing
      const contexts = await Promise.all([
        browser.newContext(),
        browser.newContext(),
        browser.newContext()
      ]);

      const pages = await Promise.all(contexts.map(ctx => ctx.newPage()));
      const monitors = pages.map(p => new PerformanceMonitor(p));

      try {
        // Clear auth state for all pages
        await Promise.all(monitors.map(m => m.clearAuthState()));

        // Perform concurrent logins
        const loginPromises = pages.map(async (page, index) => {
          const startTime = Date.now();
          await page.goto(`${BASE_URL}/login`);
          await monitors[index].fillAndSubmitLogin();

          try {
            await page.waitForURL('**/dashboard**', { timeout: PERFORMANCE_THRESHOLDS.maxLoginTime });
            return await monitors[index].recordAuthOperation(`concurrent_login_${index}`, startTime);
          } catch (error) {
            console.log(`Concurrent login ${index} failed:`, error.message);
            return null;
          }
        });

        const results = await Promise.allSettled(loginPromises);
        const successful = results.filter(r => r.status === 'fulfilled' && r.value !== null);

        // At least 2 out of 3 should succeed
        expect(successful.length).toBeGreaterThanOrEqual(2);

        // Successful logins should meet performance thresholds
        successful.forEach(result => {
          expect(result.value).toBeLessThan(PERFORMANCE_THRESHOLDS.maxLoginTime);
        });

        console.log(`✅ Concurrent authentication: ${successful.length}/3 successful`);
      } finally {
        // Clean up contexts
        await Promise.all(contexts.map(ctx => ctx.close()));
      }
    });
  });

  test.describe('Network Conditions Testing', () => {
    test('should maintain acceptable performance on slow 3G', async ({ page }) => {
      console.log('🧪 Testing performance on slow 3G...');

      // Simulate slow 3G network
      const client = await page.context().newCDPSession(page);
      await client.send('Network.emulateNetworkConditions', {
        offline: false,
        downloadThroughput: 50 * 1024,    // 50 KB/s
        uploadThroughput: 50 * 1024,      // 50 KB/s
        latency: 2000                     // 2s latency
      });

      try {
        await page.goto(`${BASE_URL}/login`);
        const startTime = Date.now();
        await perfMonitor.fillAndSubmitLogin();

        // Allow more time for slow network
        await page.waitForURL('**/dashboard**', { timeout: 30000 });

        const loginDuration = await perfMonitor.recordAuthOperation('login_slow_3g', startTime);

        // Should complete within 30 seconds on slow network
        expect(loginDuration).toBeLessThan(30000);

        console.log(`✅ Login on slow 3G: ${loginDuration}ms`);
      } finally {
        // Reset network conditions
        await client.send('Network.emulateNetworkConditions', {
          offline: false,
          downloadThroughput: -1,
          uploadThroughput: -1,
          latency: 0
        });
      }
    });

    test('should handle intermittent connectivity gracefully', async ({ page }) => {
      console.log('🧪 Testing intermittent connectivity...');

      const client = await page.context().newCDPSession(page);

      await page.goto(`${BASE_URL}/login`);
      await perfMonitor.fillAndSubmitLogin();

      // Simulate network disconnection during authentication
      await client.send('Network.emulateNetworkConditions', {
        offline: true,
        downloadThroughput: 0,
        uploadThroughput: 0,
        latency: 0
      });

      await page.waitForTimeout(3000);

      // Restore connectivity
      await client.send('Network.emulateNetworkConditions', {
        offline: false,
        downloadThroughput: -1,
        uploadThroughput: -1,
        latency: 0
      });

      // Should either complete authentication or gracefully handle the error
      await page.waitForTimeout(5000);

      const currentUrl = page.url();
      const isHandledGracefully = currentUrl.includes('login') || currentUrl.includes('dashboard');
      expect(isHandledGracefully).toBeTruthy();

      console.log(`✅ Intermittent connectivity handled gracefully: ${currentUrl}`);
    });
  });

  test.describe('Resource Optimization', () => {
    test('should not leak memory during repeated authentication', async ({ page }) => {
      console.log('🧪 Testing memory leaks during repeated authentication...');

      const memoryMeasurements = [];

      for (let i = 0; i < 3; i++) {
        // Login
        await page.goto(`${BASE_URL}/login`);
        await perfMonitor.fillAndSubmitLogin();
        await page.waitForURL('**/dashboard**', { timeout: 15000 });

        // Measure memory
        const memory = await perfMonitor.measureResourceUsage();
        memoryMeasurements.push(memory);

        // Logout
        try {
          const logoutButton = await page.$('[data-testid="logout-button"], button:has-text("Logout")');
          if (logoutButton) {
            await logoutButton.click();
            await page.waitForURL('**/login**', { timeout: 10000 });
          } else {
            await perfMonitor.clearAuthState();
          }
        } catch (error) {
          await perfMonitor.clearAuthState();
        }

        // Force garbage collection if available
        await page.evaluate(() => {
          if (window.gc) {
            window.gc();
          }
        });

        await page.waitForTimeout(1000);
      }

      // Analyze memory trend
      const memoryGrowth = memoryMeasurements[memoryMeasurements.length - 1].usedJSHeapSize -
                          memoryMeasurements[0].usedJSHeapSize;

      const memoryGrowthMB = memoryGrowth / 1024 / 1024;

      // Memory growth should be reasonable (less than 50MB)
      expect(memoryGrowthMB).toBeLessThan(50);

      console.log(`✅ Memory usage over ${memoryMeasurements.length} auth cycles: ${memoryGrowthMB.toFixed(2)}MB growth`);
      console.log('Memory measurements:', memoryMeasurements.map(m => `${Math.round(m.usedJSHeapSize / 1024 / 1024)}MB`));
    });

    test('should optimize API call patterns', async ({ page }) => {
      console.log('🧪 Testing API call optimization...');

      await page.goto(`${BASE_URL}/login`);
      await perfMonitor.fillAndSubmitLogin();
      await page.waitForURL('**/dashboard**', { timeout: 15000 });

      // Wait for all API calls to settle
      await page.waitForTimeout(3000);

      const apiCalls = perfMonitor.metrics.apiCalls;
      const authApiCalls = apiCalls.filter(call =>
        call.url.includes('/auth/') || call.url.includes('/me')
      );

      // Analyze for redundant calls
      const urlCounts = {};
      authApiCalls.forEach(call => {
        const key = `${call.method} ${call.url.split('?')[0]}`;
        urlCounts[key] = (urlCounts[key] || 0) + 1;
      });

      const redundantCalls = Object.entries(urlCounts).filter(([url, count]) => count > 2);

      // Should not have excessive redundant API calls
      expect(redundantCalls.length).toBeLessThan(3);

      console.log(`✅ API call analysis: ${authApiCalls.length} auth calls, ${redundantCalls.length} potentially redundant`);
      console.log('API call pattern:', urlCounts);
    });
  });
});