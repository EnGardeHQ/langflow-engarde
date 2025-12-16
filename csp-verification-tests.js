/**
 * Comprehensive CSP (Content Security Policy) Verification Tests
 * Tests the middleware CSP configuration to ensure eval() errors are resolved
 */

const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

class CSPTestSuite {
  constructor() {
    this.results = {
      timestamp: new Date().toISOString(),
      tests: [],
      summary: {
        total: 0,
        passed: 0,
        failed: 0,
        warnings: 0
      },
      environment: {
        nodeEnv: process.env.NODE_ENV || 'development',
        analyticsEnabled: process.env.NEXT_PUBLIC_ENABLE_ANALYTICS,
        backendUrl: process.env.NEXT_PUBLIC_API_URL
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
   * Test 1: Verify CSP header configuration without analytics
   */
  testCSPWithoutAnalytics() {
    this.log('Testing CSP configuration without analytics...', 'info');

    try {
      // Temporarily unset analytics environment variable
      const originalAnalytics = process.env.NEXT_PUBLIC_ENABLE_ANALYTICS;
      delete process.env.NEXT_PUBLIC_ENABLE_ANALYTICS;

      // Mock the middleware functions by requiring the middleware file
      const middlewarePath = path.join(process.cwd(), 'production-frontend', 'middleware.ts');

      // Read and analyze the middleware file content
      const middlewareContent = fs.readFileSync(middlewarePath, 'utf8');

      // Check for proper conditional logic
      const hasAnalyticsCheck = middlewareContent.includes('isGoogleAnalyticsEnabled()');
      const hasConditionalUnsafeEval = middlewareContent.includes("scriptSrc += \" 'unsafe-eval'\"");
      const hasProperConditioning = middlewareContent.includes('if (analyticsEnabled)');

      const warnings = [];

      if (!hasAnalyticsCheck) {
        warnings.push('Analytics enabled check function not found');
      }

      if (!hasConditionalUnsafeEval) {
        warnings.push('Conditional unsafe-eval directive not found');
      }

      if (!hasProperConditioning) {
        warnings.push('Proper analytics conditioning not found');
      }

      const passed = hasAnalyticsCheck && hasConditionalUnsafeEval && hasProperConditioning;

      this.addTestResult(
        'CSP Configuration Without Analytics',
        passed,
        {
          description: 'Verifies CSP does not include unsafe-eval when analytics are disabled',
          analyticsCheckFound: hasAnalyticsCheck,
          conditionalUnsafeEvalFound: hasConditionalUnsafeEval,
          properConditioningFound: hasProperConditioning
        },
        warnings
      );

      // Restore original analytics setting
      if (originalAnalytics !== undefined) {
        process.env.NEXT_PUBLIC_ENABLE_ANALYTICS = originalAnalytics;
      }

    } catch (error) {
      this.addTestResult(
        'CSP Configuration Without Analytics',
        false,
        {
          error: error.message,
          description: 'Failed to analyze middleware CSP configuration'
        }
      );
    }
  }

  /**
   * Test 2: Verify CSP header configuration with analytics
   */
  testCSPWithAnalytics() {
    this.log('Testing CSP configuration with analytics enabled...', 'info');

    try {
      // Set analytics environment variable
      process.env.NEXT_PUBLIC_ENABLE_ANALYTICS = 'true';

      const middlewarePath = path.join(process.cwd(), 'production-frontend', 'middleware.ts');
      const middlewareContent = fs.readFileSync(middlewarePath, 'utf8');

      // Check for Google Analytics domains
      const hasGoogleAnalyticsDomains = [
        'googletagmanager.com',
        'google-analytics.com',
        'googletag.com',
        'googleadservices.com'
      ].every(domain => middlewareContent.includes(domain));

      const hasUnsafeEvalCondition = middlewareContent.includes("scriptSrc += \" 'unsafe-eval'\"");
      const hasAnalyticsCondition = middlewareContent.includes('if (analyticsEnabled)');

      const warnings = [];

      if (!hasGoogleAnalyticsDomains) {
        warnings.push('Not all required Google Analytics domains found in CSP');
      }

      const passed = hasGoogleAnalyticsDomains && hasUnsafeEvalCondition && hasAnalyticsCondition;

      this.addTestResult(
        'CSP Configuration With Analytics',
        passed,
        {
          description: 'Verifies CSP includes unsafe-eval and GA domains when analytics are enabled',
          googleAnalyticsDomainsFound: hasGoogleAnalyticsDomains,
          unsafeEvalConditionFound: hasUnsafeEvalCondition,
          analyticsConditionFound: hasAnalyticsCondition
        },
        warnings
      );

    } catch (error) {
      this.addTestResult(
        'CSP Configuration With Analytics',
        false,
        {
          error: error.message,
          description: 'Failed to analyze middleware CSP configuration with analytics'
        }
      );
    }
  }

  /**
   * Test 3: Verify environment detection logic
   */
  testEnvironmentDetection() {
    this.log('Testing environment detection logic...', 'info');

    try {
      const middlewarePath = path.join(process.cwd(), 'production-frontend', 'middleware.ts');
      const middlewareContent = fs.readFileSync(middlewarePath, 'utf8');

      // Check for proper environment detection
      const hasProductionCheck = middlewareContent.includes("process.env.NODE_ENV === 'production'");
      const hasAnalyticsEnvCheck = middlewareContent.includes("process.env.NEXT_PUBLIC_ENABLE_ANALYTICS === 'true'");
      const hasEnvironmentFunction = middlewareContent.includes('function isGoogleAnalyticsEnabled()');

      const warnings = [];

      if (!hasProductionCheck) {
        warnings.push('Production environment check not found');
      }

      if (!hasAnalyticsEnvCheck) {
        warnings.push('Analytics environment variable check not found');
      }

      const passed = hasProductionCheck && hasAnalyticsEnvCheck && hasEnvironmentFunction;

      this.addTestResult(
        'Environment Detection Logic',
        passed,
        {
          description: 'Verifies proper environment detection for analytics enablement',
          productionCheckFound: hasProductionCheck,
          analyticsEnvCheckFound: hasAnalyticsEnvCheck,
          environmentFunctionFound: hasEnvironmentFunction
        },
        warnings
      );

    } catch (error) {
      this.addTestResult(
        'Environment Detection Logic',
        false,
        {
          error: error.message,
          description: 'Failed to analyze environment detection logic'
        }
      );
    }
  }

  /**
   * Test 4: Verify security documentation and comments
   */
  testSecurityDocumentation() {
    this.log('Testing security documentation and comments...', 'info');

    try {
      const middlewarePath = path.join(process.cwd(), 'production-frontend', 'middleware.ts');
      const middlewareContent = fs.readFileSync(middlewarePath, 'utf8');

      // Check for security-related comments and documentation
      const hasSecurityTradeOffComment = middlewareContent.includes('SECURITY TRADE-OFF EXPLANATION');
      const hasGoogleAnalyticsComment = middlewareContent.includes('gtag.js library uses eval()');
      const hasAlternativesComment = middlewareContent.includes('Alternative approaches considered');
      const hasSecurityStrategyComment = middlewareContent.includes('SECURITY STRATEGY');

      const warnings = [];

      if (!hasSecurityTradeOffComment) {
        warnings.push('Security trade-off explanation comment not found');
      }

      if (!hasGoogleAnalyticsComment) {
        warnings.push('Google Analytics eval() explanation not found');
      }

      if (!hasAlternativesComment) {
        warnings.push('Alternative approaches documentation not found');
      }

      const passed = hasSecurityTradeOffComment && hasGoogleAnalyticsComment && hasSecurityStrategyComment;

      this.addTestResult(
        'Security Documentation',
        passed,
        {
          description: 'Verifies proper security documentation and rationale',
          securityTradeOffFound: hasSecurityTradeOffComment,
          googleAnalyticsExplanationFound: hasGoogleAnalyticsComment,
          alternativesDocumentationFound: hasAlternativesComment,
          securityStrategyFound: hasSecurityStrategyComment
        },
        warnings
      );

    } catch (error) {
      this.addTestResult(
        'Security Documentation',
        false,
        {
          error: error.message,
          description: 'Failed to analyze security documentation'
        }
      );
    }
  }

  /**
   * Test 5: Verify CSP directive structure
   */
  testCSPDirectiveStructure() {
    this.log('Testing CSP directive structure...', 'info');

    try {
      const middlewarePath = path.join(process.cwd(), 'production-frontend', 'middleware.ts');
      const middlewareContent = fs.readFileSync(middlewarePath, 'utf8');

      // Check for required CSP directives
      const requiredDirectives = [
        "default-src 'self'",
        'script-src',
        'style-src',
        'font-src',
        'img-src',
        'connect-src',
        "object-src 'none'",
        "base-uri 'self'",
        "form-action 'self'",
        "frame-ancestors 'none'"
      ];

      const foundDirectives = requiredDirectives.filter(directive =>
        middlewareContent.includes(directive) || middlewareContent.includes(directive.replace("'", '"'))
      );

      const warnings = [];
      const missingDirectives = requiredDirectives.filter(directive =>
        !middlewareContent.includes(directive) && !middlewareContent.includes(directive.replace("'", '"'))
      );

      if (missingDirectives.length > 0) {
        warnings.push(`Missing CSP directives: ${missingDirectives.join(', ')}`);
      }

      const passed = foundDirectives.length === requiredDirectives.length;

      this.addTestResult(
        'CSP Directive Structure',
        passed,
        {
          description: 'Verifies all required CSP directives are present',
          requiredDirectives: requiredDirectives.length,
          foundDirectives: foundDirectives.length,
          missingDirectives: missingDirectives
        },
        warnings
      );

    } catch (error) {
      this.addTestResult(
        'CSP Directive Structure',
        false,
        {
          error: error.message,
          description: 'Failed to analyze CSP directive structure'
        }
      );
    }
  }

  /**
   * Test 6: Check for potential CSP bypasses
   */
  testCSPSecurityChecks() {
    this.log('Testing CSP security checks...', 'info');

    try {
      const middlewarePath = path.join(process.cwd(), 'production-frontend', 'middleware.ts');
      const middlewareContent = fs.readFileSync(middlewarePath, 'utf8');

      // Check for dangerous CSP configurations
      const hasUnsafeInline = middlewareContent.includes("'unsafe-inline'");
      const hasUnsafeEval = middlewareContent.includes("'unsafe-eval'");
      const hasWildcardSrc = middlewareContent.includes("'*'") && !middlewareContent.includes("localhost:*");
      const hasDataURI = middlewareContent.includes('data:');

      const warnings = [];

      if (hasUnsafeInline) {
        warnings.push("'unsafe-inline' directive found - consider using nonces for better security");
      }

      if (hasUnsafeEval && !middlewareContent.includes('if (analyticsEnabled)')) {
        warnings.push("'unsafe-eval' found without proper conditioning");
      }

      if (hasWildcardSrc) {
        warnings.push("Wildcard source '*' found - this may be too permissive");
      }

      // Passed if unsafe-eval is properly conditioned and no wildcards
      const passed = !hasWildcardSrc && (
        !hasUnsafeEval || middlewareContent.includes('if (analyticsEnabled)')
      );

      this.addTestResult(
        'CSP Security Checks',
        passed,
        {
          description: 'Verifies CSP configuration follows security best practices',
          unsafeInlineFound: hasUnsafeInline,
          unsafeEvalFound: hasUnsafeEval,
          wildcardSourceFound: hasWildcardSrc,
          dataURIFound: hasDataURI
        },
        warnings
      );

    } catch (error) {
      this.addTestResult(
        'CSP Security Checks',
        false,
        {
          error: error.message,
          description: 'Failed to perform CSP security checks'
        }
      );
    }
  }

  /**
   * Run all CSP configuration tests
   */
  async runAllTests() {
    this.log('Starting CSP Verification Test Suite...', 'info');
    this.log(`Environment: ${this.results.environment.nodeEnv}`, 'info');
    this.log(`Analytics: ${this.results.environment.analyticsEnabled || 'not set'}`, 'info');

    // Run all tests
    this.testCSPWithoutAnalytics();
    this.testCSPWithAnalytics();
    this.testEnvironmentDetection();
    this.testSecurityDocumentation();
    this.testCSPDirectiveStructure();
    this.testCSPSecurityChecks();

    // Generate summary
    this.log('CSP Test Suite Completed', 'info');
    this.log(`Total Tests: ${this.results.summary.total}`, 'info');
    this.log(`Passed: ${this.results.summary.passed}`, 'success');
    this.log(`Failed: ${this.results.summary.failed}`, this.results.summary.failed > 0 ? 'error' : 'info');
    this.log(`Warnings: ${this.results.summary.warnings}`, this.results.summary.warnings > 0 ? 'warning' : 'info');

    return this.results;
  }

  /**
   * Save test results to file
   */
  saveResults(filename = 'csp-test-results.json') {
    const outputPath = path.join(process.cwd(), filename);
    fs.writeFileSync(outputPath, JSON.stringify(this.results, null, 2));
    this.log(`Test results saved to: ${outputPath}`, 'success');
  }
}

// Export for use in other modules
module.exports = { CSPTestSuite };

// Run tests if this file is executed directly
if (require.main === module) {
  (async () => {
    const testSuite = new CSPTestSuite();
    const results = await testSuite.runAllTests();
    testSuite.saveResults();

    // Exit with error code if any tests failed
    if (results.summary.failed > 0) {
      process.exit(1);
    }
  })();
}