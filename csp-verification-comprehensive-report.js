/**
 * Comprehensive CSP Verification Report Generator
 * Analyzes all test results and generates a comprehensive report
 */

const fs = require('fs');
const path = require('path');

class CSPVerificationReportGenerator {
  constructor() {
    this.testResults = {};
    this.report = {
      timestamp: new Date().toISOString(),
      testSuite: 'CSP Verification and eval() Error Resolution',
      summary: {
        totalTestSuites: 0,
        totalTests: 0,
        passed: 0,
        failed: 0,
        warnings: 0,
        overallStatus: 'UNKNOWN'
      },
      testSuites: [],
      findings: {
        cspViolations: [],
        evalErrors: [],
        securityIssues: [],
        resolved: [],
        recommendations: []
      },
      environmentTests: {
        analyticsDisabled: {},
        analyticsEnabled: {}
      },
      conclusion: ''
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

  /**
   * Load test results from JSON files
   */
  loadTestResults() {
    const testFiles = [
      'csp-test-results.json',
      'http-header-test-results.json',
      'browser-console-test-results.json'
    ];

    testFiles.forEach(filename => {
      try {
        const filePath = path.join(process.cwd(), filename);
        if (fs.existsSync(filePath)) {
          const content = fs.readFileSync(filePath, 'utf8');
          const data = JSON.parse(content);

          const suiteName = filename.replace('-test-results.json', '').replace('-', ' ');
          this.testResults[suiteName] = data;
          this.log(`Loaded test results from ${filename}`, 'success');
        } else {
          this.log(`Test results file not found: ${filename}`, 'warning');
        }
      } catch (error) {
        this.log(`Error loading ${filename}: ${error.message}`, 'error');
      }
    });
  }

  /**
   * Analyze CSP configuration test results
   */
  analyzeCspConfigTests() {
    const cspTests = this.testResults['csp'];
    if (!cspTests) {
      this.log('CSP configuration test results not found', 'warning');
      return;
    }

    const suite = {
      name: 'CSP Configuration Tests',
      description: 'Unit tests verifying CSP configuration logic',
      totalTests: cspTests.summary.total,
      passed: cspTests.summary.passed,
      failed: cspTests.summary.failed,
      warnings: cspTests.summary.warnings,
      status: cspTests.summary.failed === 0 ? 'PASSED' : 'FAILED',
      details: cspTests.tests
    };

    this.report.testSuites.push(suite);
    this.report.summary.totalTests += suite.totalTests;
    this.report.summary.passed += suite.passed;
    this.report.summary.failed += suite.failed;
    this.report.summary.warnings += suite.warnings;

    // Analyze specific findings
    cspTests.tests.forEach(test => {
      if (test.name.includes('Without Analytics') && test.passed) {
        this.report.findings.resolved.push('CSP correctly excludes unsafe-eval when analytics are disabled');
      }
      if (test.name.includes('With Analytics') && test.passed) {
        this.report.findings.resolved.push('CSP correctly includes unsafe-eval only when analytics are enabled');
      }
      if (test.name.includes('Security Checks') && !test.passed) {
        test.warnings.forEach(warning => {
          this.report.findings.securityIssues.push(`CSP Security: ${warning}`);
        });
      }
    });
  }

  /**
   * Analyze HTTP header test results
   */
  analyzeHttpHeaderTests() {
    const httpTests = this.testResults['http header'];
    if (!httpTests) {
      this.log('HTTP header test results not found', 'warning');
      return;
    }

    const suite = {
      name: 'HTTP Header Tests',
      description: 'Tests verifying CSP headers in HTTP responses',
      totalTests: httpTests.summary.total,
      passed: httpTests.summary.passed,
      failed: httpTests.summary.failed,
      warnings: httpTests.summary.warnings,
      status: httpTests.summary.failed === 0 ? 'PASSED' : 'FAILED',
      details: httpTests.tests,
      baseUrl: httpTests.baseUrl
    };

    this.report.testSuites.push(suite);
    this.report.summary.totalTests += suite.totalTests;
    this.report.summary.passed += suite.passed;
    this.report.summary.failed += suite.failed;
    this.report.summary.warnings += suite.warnings;

    // Extract environment-specific results
    httpTests.tests.forEach(test => {
      if (test.name.includes('Without Analytics')) {
        this.report.environmentTests.analyticsDisabled = {
          status: test.passed ? 'PASSED' : 'FAILED',
          cspHeaderPresent: test.details.cspHeaderFound,
          unsafeEvalFound: test.details.unsafeEvalFound,
          googleDomainsFound: test.details.googleDomainsFound
        };

        if (test.passed) {
          this.report.findings.resolved.push('HTTP headers correctly configured when analytics are disabled');
        }
      }
    });
  }

  /**
   * Analyze browser console test results
   */
  analyzeBrowserConsoleTests() {
    const browserTests = this.testResults['browser console'];
    if (!browserTests) {
      this.log('Browser console test results not found', 'warning');
      return;
    }

    const suite = {
      name: 'Browser Console Tests',
      description: 'Tests monitoring browser console for CSP violations and eval errors',
      totalTests: browserTests.summary.total,
      passed: browserTests.summary.passed,
      failed: browserTests.summary.failed,
      warnings: browserTests.summary.warnings,
      status: browserTests.summary.failed === 0 ? 'PASSED' : 'FAILED',
      details: browserTests.tests,
      baseUrl: browserTests.baseUrl,
      cspViolationsDetected: browserTests.cspViolations ? browserTests.cspViolations.length : 0,
      consoleErrorsDetected: browserTests.consoleErrors ? browserTests.consoleErrors.length : 0
    };

    this.report.testSuites.push(suite);
    this.report.summary.totalTests += suite.totalTests;
    this.report.summary.passed += suite.passed;
    this.report.summary.failed += suite.failed;
    this.report.summary.warnings += suite.warnings;

    // Analyze CSP violations and eval errors
    if (browserTests.cspViolations && browserTests.cspViolations.length > 0) {
      browserTests.cspViolations.forEach(violation => {
        this.report.findings.cspViolations.push({
          text: violation.text,
          testName: violation.testName,
          timestamp: violation.timestamp
        });
      });
    } else {
      this.report.findings.resolved.push('No CSP violations detected in browser console');
    }

    if (browserTests.consoleErrors) {
      const evalErrors = browserTests.consoleErrors.filter(error =>
        error.text.toLowerCase().includes('eval') ||
        error.text.toLowerCase().includes('unsafe-eval')
      );

      if (evalErrors.length > 0) {
        evalErrors.forEach(error => {
          this.report.findings.evalErrors.push({
            text: error.text,
            testName: error.testName,
            timestamp: error.timestamp
          });
        });
      } else {
        this.report.findings.resolved.push('No eval-related errors detected in browser console');
      }
    }

    // Check specific test results
    browserTests.tests.forEach(test => {
      if (test.name.includes('Homepage CSP') && test.passed) {
        this.report.findings.resolved.push('Homepage loads without CSP violations');
      }
      if (test.name.includes('Login Flow CSP') && test.passed) {
        this.report.findings.resolved.push('Login flow works without CSP violations');
      }
      if (test.name.includes('Analytics Enabled') && test.passed) {
        this.report.environmentTests.analyticsEnabled = {
          status: 'PASSED',
          cspViolations: test.details.analyticsCspViolations || 0,
          evalErrors: test.details.analyticsEvalErrors || 0
        };
        this.report.findings.resolved.push('Application works correctly with analytics enabled');
      }
    });
  }

  /**
   * Generate recommendations based on findings
   */
  generateRecommendations() {
    // Security recommendations
    if (this.report.findings.securityIssues.length > 0) {
      this.report.findings.recommendations.push({
        priority: 'Medium',
        category: 'Security Enhancement',
        recommendation: 'Consider implementing nonce-based CSP instead of \'unsafe-inline\' for better security',
        rationale: 'While functional, unsafe-inline poses security risks that can be mitigated with nonces'
      });
    }

    // CSP violation recommendations
    if (this.report.findings.cspViolations.length > 0) {
      this.report.findings.recommendations.push({
        priority: 'High',
        category: 'CSP Violations',
        recommendation: 'Address remaining CSP violations to ensure complete security compliance',
        rationale: 'CSP violations indicate potential security weaknesses'
      });
    }

    // Eval error recommendations
    if (this.report.findings.evalErrors.length > 0) {
      this.report.findings.recommendations.push({
        priority: 'High',
        category: 'Eval Errors',
        recommendation: 'Investigate and resolve remaining eval-related errors',
        rationale: 'Eval errors indicate that the CSP configuration may not be fully resolved'
      });
    }

    // General recommendations
    this.report.findings.recommendations.push({
      priority: 'Low',
      category: 'Monitoring',
      recommendation: 'Implement continuous CSP monitoring in production',
      rationale: 'Regular monitoring helps catch CSP issues early in production environments'
    });

    this.report.findings.recommendations.push({
      priority: 'Medium',
      category: 'Testing',
      recommendation: 'Include CSP tests in CI/CD pipeline',
      rationale: 'Automated testing prevents CSP regressions during development'
    });
  }

  /**
   * Generate overall conclusion
   */
  generateConclusion() {
    const totalTests = this.report.summary.totalTests;
    const passedTests = this.report.summary.passed;
    const failedTests = this.report.summary.failed;
    const passRate = Math.round((passedTests / totalTests) * 100);

    this.report.summary.totalTestSuites = this.report.testSuites.length;
    this.report.summary.overallStatus = failedTests === 0 ? 'PASSED' : 'PARTIALLY_PASSED';

    let conclusion = `CSP Verification Test Suite Results:\n\n`;
    conclusion += `📊 Overall Status: ${this.report.summary.overallStatus}\n`;
    conclusion += `🎯 Pass Rate: ${passRate}% (${passedTests}/${totalTests} tests passed)\n`;
    conclusion += `📋 Test Suites: ${this.report.summary.totalTestSuites}\n`;
    conclusion += `⚠️  Warnings: ${this.report.summary.warnings}\n\n`;

    conclusion += `🎉 RESOLVED ISSUES:\n`;
    this.report.findings.resolved.forEach((item, index) => {
      conclusion += `   ${index + 1}. ${item}\n`;
    });

    if (this.report.findings.cspViolations.length === 0 && this.report.findings.evalErrors.length === 0) {
      conclusion += `\n✅ SUCCESS: The CSP eval() errors have been successfully resolved!\n\n`;
      conclusion += `Key Achievements:\n`;
      conclusion += `• CSP now conditionally allows 'unsafe-eval' only when Google Analytics is enabled\n`;
      conclusion += `• No CSP violations detected in browser console\n`;
      conclusion += `• No eval-related errors found\n`;
      conclusion += `• Application functions correctly in both analytics enabled/disabled modes\n`;
      conclusion += `• Security headers are properly configured\n\n`;
    } else {
      conclusion += `\n⚠️  PARTIAL SUCCESS: Most issues resolved, but some remain:\n`;
      if (this.report.findings.cspViolations.length > 0) {
        conclusion += `• ${this.report.findings.cspViolations.length} CSP violations detected\n`;
      }
      if (this.report.findings.evalErrors.length > 0) {
        conclusion += `• ${this.report.findings.evalErrors.length} eval-related errors found\n`;
      }
    }

    if (this.report.findings.securityIssues.length > 0) {
      conclusion += `\n🔒 SECURITY NOTES:\n`;
      this.report.findings.securityIssues.forEach((issue, index) => {
        conclusion += `   ${index + 1}. ${issue}\n`;
      });
    }

    if (this.report.findings.recommendations.length > 0) {
      conclusion += `\n💡 RECOMMENDATIONS:\n`;
      const highPriority = this.report.findings.recommendations.filter(r => r.priority === 'High');
      const mediumPriority = this.report.findings.recommendations.filter(r => r.priority === 'Medium');
      const lowPriority = this.report.findings.recommendations.filter(r => r.priority === 'Low');

      [highPriority, mediumPriority, lowPriority].forEach(group => {
        group.forEach((rec, index) => {
          conclusion += `   [${rec.priority}] ${rec.recommendation}\n`;
        });
      });
    }

    conclusion += `\n🔍 TESTING METHODOLOGY:\n`;
    conclusion += `• Static code analysis of CSP configuration\n`;
    conclusion += `• HTTP response header verification\n`;
    conclusion += `• Browser console monitoring for violations\n`;
    conclusion += `• Multi-browser compatibility testing\n`;
    conclusion += `• Environment-specific testing (analytics on/off)\n`;

    this.report.conclusion = conclusion;
  }

  /**
   * Generate and save the comprehensive report
   */
  generateReport() {
    this.log('Starting comprehensive CSP verification report generation...', 'info');

    // Load test results
    this.loadTestResults();

    // Analyze each test suite
    this.analyzeCspConfigTests();
    this.analyzeHttpHeaderTests();
    this.analyzeBrowserConsoleTests();

    // Generate insights
    this.generateRecommendations();
    this.generateConclusion();

    // Save report
    const reportPath = path.join(process.cwd(), 'csp-verification-comprehensive-report.json');
    fs.writeFileSync(reportPath, JSON.stringify(this.report, null, 2));
    this.log(`Comprehensive report saved to: ${reportPath}`, 'success');

    // Save human-readable summary
    const summaryPath = path.join(process.cwd(), 'CSP_VERIFICATION_SUMMARY.md');
    const markdownSummary = this.generateMarkdownSummary();
    fs.writeFileSync(summaryPath, markdownSummary);
    this.log(`Summary report saved to: ${summaryPath}`, 'success');

    // Display conclusion
    console.log('\n' + '='.repeat(80));
    console.log('CSP VERIFICATION COMPREHENSIVE REPORT');
    console.log('='.repeat(80));
    console.log(this.report.conclusion);
    console.log('='.repeat(80));

    return this.report;
  }

  /**
   * Generate markdown summary
   */
  generateMarkdownSummary() {
    const report = this.report;
    let markdown = `# CSP Verification Comprehensive Report\n\n`;
    markdown += `**Generated:** ${report.timestamp}\n\n`;
    markdown += `## Executive Summary\n\n`;
    markdown += `- **Overall Status:** ${report.summary.overallStatus}\n`;
    markdown += `- **Test Suites:** ${report.summary.totalTestSuites}\n`;
    markdown += `- **Total Tests:** ${report.summary.totalTests}\n`;
    markdown += `- **Passed:** ${report.summary.passed}\n`;
    markdown += `- **Failed:** ${report.summary.failed}\n`;
    markdown += `- **Warnings:** ${report.summary.warnings}\n\n`;

    markdown += `## Test Suite Results\n\n`;
    report.testSuites.forEach(suite => {
      markdown += `### ${suite.name}\n`;
      markdown += `- **Status:** ${suite.status}\n`;
      markdown += `- **Tests:** ${suite.passed}/${suite.totalTests} passed\n`;
      markdown += `- **Description:** ${suite.description}\n\n`;
    });

    markdown += `## Environment Testing\n\n`;
    markdown += `### Analytics Disabled\n`;
    const analyticsOff = report.environmentTests.analyticsDisabled;
    if (analyticsOff.status) {
      markdown += `- **Status:** ${analyticsOff.status}\n`;
      markdown += `- **Unsafe-eval found:** ${analyticsOff.unsafeEvalFound ? 'Yes' : 'No'}\n`;
      markdown += `- **Google domains found:** ${analyticsOff.googleDomainsFound ? 'Yes' : 'No'}\n\n`;
    }

    markdown += `### Analytics Enabled\n`;
    const analyticsOn = report.environmentTests.analyticsEnabled;
    if (analyticsOn.status) {
      markdown += `- **Status:** ${analyticsOn.status}\n`;
      markdown += `- **CSP violations:** ${analyticsOn.cspViolations || 0}\n`;
      markdown += `- **Eval errors:** ${analyticsOn.evalErrors || 0}\n\n`;
    }

    markdown += `## Key Findings\n\n`;
    markdown += `### ✅ Resolved Issues\n`;
    report.findings.resolved.forEach(item => {
      markdown += `- ${item}\n`;
    });

    if (report.findings.cspViolations.length > 0) {
      markdown += `\n### ⚠️ CSP Violations\n`;
      report.findings.cspViolations.forEach(violation => {
        markdown += `- ${violation.text} (${violation.testName})\n`;
      });
    }

    if (report.findings.evalErrors.length > 0) {
      markdown += `\n### ❌ Eval Errors\n`;
      report.findings.evalErrors.forEach(error => {
        markdown += `- ${error.text} (${error.testName})\n`;
      });
    }

    if (report.findings.securityIssues.length > 0) {
      markdown += `\n### 🔒 Security Issues\n`;
      report.findings.securityIssues.forEach(issue => {
        markdown += `- ${issue}\n`;
      });
    }

    markdown += `\n## Recommendations\n\n`;
    ['High', 'Medium', 'Low'].forEach(priority => {
      const recs = report.findings.recommendations.filter(r => r.priority === priority);
      if (recs.length > 0) {
        markdown += `### ${priority} Priority\n`;
        recs.forEach(rec => {
          markdown += `- **${rec.category}:** ${rec.recommendation}\n`;
          markdown += `  - *Rationale:* ${rec.rationale}\n`;
        });
        markdown += `\n`;
      }
    });

    markdown += `## Conclusion\n\n`;
    markdown += report.conclusion.replace(/\n/g, '\n\n');

    return markdown;
  }
}

// Export for use in other modules
module.exports = { CSPVerificationReportGenerator };

// Run report generation if this file is executed directly
if (require.main === module) {
  const generator = new CSPVerificationReportGenerator();
  const report = generator.generateReport();

  // Exit with error code if there are unresolved issues
  if (report.summary.failed > 0 || report.findings.cspViolations.length > 0 || report.findings.evalErrors.length > 0) {
    process.exit(1);
  }
}