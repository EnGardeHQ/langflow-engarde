/**
 * HTTP Response Header Tests for CSP Verification
 * Tests actual HTTP responses to verify CSP headers are correctly applied
 */

const http = require('http');
const https = require('https');
const { URL } = require('url');

class HTTPHeaderTestSuite {
  constructor(baseUrl = 'http://localhost:3001') {
    this.baseUrl = baseUrl;
    this.results = {
      timestamp: new Date().toISOString(),
      baseUrl: baseUrl,
      tests: [],
      summary: {
        total: 0,
        passed: 0,
        failed: 0,
        warnings: 0
      }
    };
  }

  log(message, type = 'info') {
    const timestamp = new Date().toISOString();
    const prefix = {
      'info': '🔍',
      'success': '✅',
      'error': '❌',
      'warning': '⚠️',
      'debug': '🐛'
    }[type] || 'ℹ️';

    console.log(`${prefix} [${timestamp}] ${message}`);
  }

  addTestResult(name, passed, details = {}, warnings = []) {
    const result = {
      name,
      passed,
      details,
      warnings,
      timestamp: new Date().toISOString()
    };

    this.results.tests.push(result);
    this.results.summary.total++;

    if (passed) {
      this.results.summary.passed++;
      this.log(`${name}: PASSED`, 'success');
    } else {
      this.results.summary.failed++;
      this.log(`${name}: FAILED`, 'error');
    }

    if (warnings.length > 0) {
      this.results.summary.warnings += warnings.length;
      warnings.forEach(warning => this.log(`  Warning: ${warning}`, 'warning'));
    }

    if (details.description) {
      this.log(`  ${details.description}`, 'debug');
    }
  }

  /**
   * Make HTTP request and return headers
   */
  async makeRequest(path = '/', method = 'GET', headers = {}) {
    return new Promise((resolve, reject) => {
      const url = new URL(path, this.baseUrl);
      const isHttps = url.protocol === 'https:';
      const client = isHttps ? https : http;

      const options = {
        hostname: url.hostname,
        port: url.port || (isHttps ? 443 : 80),
        path: url.pathname + url.search,
        method,
        headers: {
          'User-Agent': 'CSP-Test-Suite/1.0',
          ...headers
        }
      };

      const req = client.request(options, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: data
          });
        });
      });

      req.on('error', reject);
      req.setTimeout(10000, () => {
        req.destroy();
        reject(new Error('Request timeout'));
      });

      req.end();
    });
  }

  /**
   * Test 1: Verify CSP header is present
   */
  async testCSPHeaderPresence() {
    this.log('Testing CSP header presence...', 'info');

    try {
      const response = await this.makeRequest('/');
      const cspHeader = response.headers['content-security-policy'];

      const warnings = [];
      if (response.statusCode !== 200) {
        warnings.push(`Unexpected status code: ${response.statusCode}`);
      }

      const passed = !!cspHeader;

      this.addTestResult(
        'CSP Header Presence',
        passed,
        {
          description: 'Verifies Content-Security-Policy header is present in HTTP response',
          statusCode: response.statusCode,
          cspHeaderFound: !!cspHeader,
          cspHeaderValue: cspHeader ? cspHeader.substring(0, 100) + '...' : null
        },
        warnings
      );

      return cspHeader;

    } catch (error) {
      this.addTestResult(
        'CSP Header Presence',
        false,
        {
          error: error.message,
          description: 'Failed to make HTTP request to test CSP header'
        }
      );
      return null;
    }
  }

  /**
   * Test 2: Verify CSP without analytics (default behavior)
   */
  async testCSPWithoutAnalytics() {
    this.log('Testing CSP header without analytics...', 'info');

    try {
      // Make request without analytics enabled
      const response = await this.makeRequest('/', 'GET', {
        'X-Test-Analytics': 'disabled'
      });

      const cspHeader = response.headers['content-security-policy'];
      const warnings = [];

      if (!cspHeader) {
        this.addTestResult(
          'CSP Without Analytics',
          false,
          {
            description: 'CSP header not found in response',
            statusCode: response.statusCode
          }
        );
        return;
      }

      // Check if unsafe-eval is present (it shouldn't be without analytics)
      const hasUnsafeEval = cspHeader.includes("'unsafe-eval'");
      const hasGoogleDomains = cspHeader.includes('googletagmanager.com') ||
                              cspHeader.includes('google-analytics.com');

      // Check for required directives
      const hasDefaultSrc = cspHeader.includes("default-src 'self'");
      const hasScriptSrc = cspHeader.includes('script-src');
      const hasObjectSrcNone = cspHeader.includes("object-src 'none'");

      if (hasUnsafeEval) {
        warnings.push("'unsafe-eval' found in CSP when analytics should be disabled");
      }

      if (hasGoogleDomains) {
        warnings.push('Google Analytics domains found when analytics should be disabled');
      }

      if (!hasDefaultSrc) {
        warnings.push("default-src 'self' directive not found");
      }

      if (!hasScriptSrc) {
        warnings.push('script-src directive not found');
      }

      // Check for analytics environment header (if in development)
      const analyticsEnabled = response.headers['x-analytics-enabled'];
      if (analyticsEnabled === 'true') {
        warnings.push('Analytics reported as enabled when expected to be disabled');
      }

      const passed = !hasUnsafeEval && !hasGoogleDomains && hasDefaultSrc && hasScriptSrc;

      this.addTestResult(
        'CSP Without Analytics',
        passed,
        {
          description: 'Verifies CSP does not include unsafe-eval when analytics are disabled',
          statusCode: response.statusCode,
          unsafeEvalFound: hasUnsafeEval,
          googleDomainsFound: hasGoogleDomains,
          defaultSrcFound: hasDefaultSrc,
          scriptSrcFound: hasScriptSrc,
          analyticsEnabledHeader: analyticsEnabled,
          cspHeader: cspHeader
        },
        warnings
      );

    } catch (error) {
      this.addTestResult(
        'CSP Without Analytics',
        false,
        {
          error: error.message,
          description: 'Failed to test CSP without analytics'
        }
      );
    }
  }

  /**
   * Test 3: Verify security headers
   */
  async testSecurityHeaders() {
    this.log('Testing security headers...', 'info');

    try {
      const response = await this.makeRequest('/');
      const warnings = [];

      const securityHeaders = {
        'content-security-policy': 'Content Security Policy',
        'x-frame-options': 'X-Frame-Options',
        'x-content-type-options': 'X-Content-Type-Options',
        'x-xss-protection': 'X-XSS-Protection',
        'referrer-policy': 'Referrer Policy',
        'permissions-policy': 'Permissions Policy'
      };

      const foundHeaders = {};
      const missingHeaders = [];

      Object.entries(securityHeaders).forEach(([header, description]) => {
        const value = response.headers[header];
        if (value) {
          foundHeaders[header] = value;
        } else {
          missingHeaders.push(description);
          warnings.push(`${description} header not found`);
        }
      });

      // Check for insecure configurations
      const frameOptions = response.headers['x-frame-options'];
      if (frameOptions && !['DENY', 'SAMEORIGIN'].includes(frameOptions.toUpperCase())) {
        warnings.push(`Insecure X-Frame-Options value: ${frameOptions}`);
      }

      const contentTypeOptions = response.headers['x-content-type-options'];
      if (contentTypeOptions && contentTypeOptions.toLowerCase() !== 'nosniff') {
        warnings.push(`Unexpected X-Content-Type-Options value: ${contentTypeOptions}`);
      }

      const passed = missingHeaders.length === 0;

      this.addTestResult(
        'Security Headers',
        passed,
        {
          description: 'Verifies presence and configuration of security headers',
          statusCode: response.statusCode,
          foundHeaders: Object.keys(foundHeaders).length,
          totalExpected: Object.keys(securityHeaders).length,
          missingHeaders,
          headerValues: foundHeaders
        },
        warnings
      );

    } catch (error) {
      this.addTestResult(
        'Security Headers',
        false,
        {
          error: error.message,
          description: 'Failed to test security headers'
        }
      );
    }
  }

  /**
   * Test 4: Test different routes for consistent CSP
   */
  async testCSPConsistency() {
    this.log('Testing CSP consistency across routes...', 'info');

    const routes = ['/', '/login', '/dashboard', '/api/health'];
    const cspValues = [];
    const warnings = [];

    try {
      for (const route of routes) {
        try {
          const response = await this.makeRequest(route);
          const csp = response.headers['content-security-policy'];

          cspValues.push({
            route,
            statusCode: response.statusCode,
            cspPresent: !!csp,
            cspLength: csp ? csp.length : 0
          });

          if (!csp) {
            warnings.push(`CSP header missing for route: ${route}`);
          }
        } catch (error) {
          warnings.push(`Failed to test route ${route}: ${error.message}`);
          cspValues.push({
            route,
            error: error.message,
            cspPresent: false
          });
        }
      }

      // Check if CSP values are consistent (allowing for some variation in length)
      const cspLengths = cspValues
        .filter(v => v.cspPresent && !v.error)
        .map(v => v.cspLength);

      const avgLength = cspLengths.reduce((a, b) => a + b, 0) / cspLengths.length;
      const maxVariation = Math.max(...cspLengths) - Math.min(...cspLengths);

      if (maxVariation > avgLength * 0.1) { // More than 10% variation
        warnings.push(`Significant CSP variation across routes: ${maxVariation} characters`);
      }

      const passed = cspValues.every(v => v.cspPresent || v.error) && warnings.length === 0;

      this.addTestResult(
        'CSP Consistency',
        passed,
        {
          description: 'Verifies CSP headers are consistently applied across different routes',
          testedRoutes: routes.length,
          successfulRequests: cspValues.filter(v => !v.error).length,
          averageCSPLength: Math.round(avgLength),
          maxVariation: maxVariation,
          routeResults: cspValues
        },
        warnings
      );

    } catch (error) {
      this.addTestResult(
        'CSP Consistency',
        false,
        {
          error: error.message,
          description: 'Failed to test CSP consistency across routes'
        }
      );
    }
  }

  /**
   * Test 5: Development headers
   */
  async testDevelopmentHeaders() {
    this.log('Testing development-specific headers...', 'info');

    try {
      const response = await this.makeRequest('/');
      const warnings = [];

      const devHeaders = {
        'x-development-mode': response.headers['x-development-mode'],
        'x-environment': response.headers['x-environment'],
        'x-backend-url': response.headers['x-backend-url'],
        'x-analytics-enabled': response.headers['x-analytics-enabled'],
        'x-csp-debug': response.headers['x-csp-debug']
      };

      const foundDevHeaders = Object.entries(devHeaders)
        .filter(([key, value]) => value !== undefined)
        .length;

      // In development, we should see debug headers
      if (process.env.NODE_ENV === 'development' && foundDevHeaders === 0) {
        warnings.push('No development headers found in development environment');
      }

      // In production, we should NOT see debug headers
      if (process.env.NODE_ENV === 'production' && foundDevHeaders > 0) {
        warnings.push('Development headers found in production environment');
      }

      const passed = warnings.length === 0;

      this.addTestResult(
        'Development Headers',
        passed,
        {
          description: 'Verifies appropriate development headers are present/absent',
          statusCode: response.statusCode,
          foundDevHeaders,
          nodeEnv: process.env.NODE_ENV,
          devHeaderValues: devHeaders
        },
        warnings
      );

    } catch (error) {
      this.addTestResult(
        'Development Headers',
        false,
        {
          error: error.message,
          description: 'Failed to test development headers'
        }
      );
    }
  }

  /**
   * Run all HTTP header tests
   */
  async runAllTests() {
    this.log('Starting HTTP Header Test Suite...', 'info');
    this.log(`Target URL: ${this.baseUrl}`, 'info');

    try {
      // Test if server is running
      await this.makeRequest('/');
      this.log('Server is responding', 'success');
    } catch (error) {
      this.log(`Server not accessible: ${error.message}`, 'error');
      this.log('Please ensure the application is running on the specified URL', 'warning');
      return this.results;
    }

    // Run all tests
    await this.testCSPHeaderPresence();
    await this.testCSPWithoutAnalytics();
    await this.testSecurityHeaders();
    await this.testCSPConsistency();
    await this.testDevelopmentHeaders();

    // Generate summary
    this.log('HTTP Header Test Suite Completed', 'info');
    this.log(`Total Tests: ${this.results.summary.total}`, 'info');
    this.log(`Passed: ${this.results.summary.passed}`, 'success');
    this.log(`Failed: ${this.results.summary.failed}`, this.results.summary.failed > 0 ? 'error' : 'info');
    this.log(`Warnings: ${this.results.summary.warnings}`, this.results.summary.warnings > 0 ? 'warning' : 'info');

    return this.results;
  }

  /**
   * Save test results to file
   */
  saveResults(filename = 'http-header-test-results.json') {
    const fs = require('fs');
    const path = require('path');
    const outputPath = path.join(process.cwd(), filename);
    fs.writeFileSync(outputPath, JSON.stringify(this.results, null, 2));
    this.log(`Test results saved to: ${outputPath}`, 'success');
  }
}

// Export for use in other modules
module.exports = { HTTPHeaderTestSuite };

// Run tests if this file is executed directly
if (require.main === module) {
  (async () => {
    const baseUrl = process.argv[2] || 'http://localhost:3001';
    const testSuite = new HTTPHeaderTestSuite(baseUrl);
    const results = await testSuite.runAllTests();
    testSuite.saveResults();

    // Exit with error code if any tests failed
    if (results.summary.failed > 0) {
      process.exit(1);
    }
  })();
}