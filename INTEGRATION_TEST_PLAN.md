# Comprehensive Integration Test Plan
## Local Testing Suite for EnGarde Platform

**Version:** 1.0.0
**Last Updated:** 2025-10-05
**Test Environment:** Local Development
**Target Platform:** EnGarde Marketing Intelligence Platform

---

## Table of Contents

1. [Overview](#overview)
2. [Test Environment Setup](#test-environment-setup)
3. [Test Execution Strategy](#test-execution-strategy)
4. [Test Categories](#test-categories)
5. [Test Coverage Matrix](#test-coverage-matrix)
6. [Test Data Management](#test-data-management)
7. [Success Criteria](#success-criteria)
8. [Risk Assessment](#risk-assessment)

---

## Overview

### Purpose
This test plan defines comprehensive integration testing procedures for the EnGarde platform, focusing on local development environment validation before production deployment.

### Scope
The test suite covers:
- **Authentication & Authorization**: Login, logout, session management, token refresh
- **Connected Apps/Integrations**: Platform connections, OAuth flows, API key management
- **AI Content Creation**: Agent-powered content generation workflows
- **Audience Cohort Intelligence**: Segment creation, analysis, and insights
- **LangFlow Workflows**: Visual workflow builder, node configuration, execution
- **Campaign Management**: Campaign creation, execution, monitoring
- **Dashboard Functionality**: Analytics, metrics, real-time updates

### Testing Approach
- **Black Box Testing**: Validate user-facing functionality
- **Integration Testing**: Verify component interactions
- **End-to-End Testing**: Complete user journey validation
- **Performance Testing**: Load time, response time validation
- **Accessibility Testing**: WCAG 2.1 AA compliance
- **Security Testing**: Authentication, authorization, data protection

---

## Test Environment Setup

### Prerequisites
```bash
# 1. Install dependencies
npm install

# 2. Setup environment variables
cp .env.example .env.local

# 3. Start local development server
npm run dev

# 4. Install Playwright browsers
npx playwright install

# 5. Verify test environment
npm run test:e2e -- --list
```

### Required Services
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **Database**: PostgreSQL (local or Docker)
- **Redis**: Cache and session storage (optional)

### Test User Accounts
| Email | Password | Role | Purpose |
|-------|----------|------|---------|
| admin@engarde.test | Admin123! | Admin | Full system access |
| publisher@engarde.test | Publisher123! | Publisher | Content creation tests |
| advertiser@engarde.test | Advertiser123! | Advertiser | Campaign management tests |

---

## Test Execution Strategy

### Test Phases

#### Phase 1: Smoke Tests (5-10 minutes)
- Basic authentication
- Page load verification
- Critical path validation

#### Phase 2: Feature Tests (30-45 minutes)
- Authentication flows
- Integration management
- AI content creation
- Audience intelligence
- Workflow creation

#### Phase 3: Integration Tests (45-60 minutes)
- End-to-end user journeys
- Cross-feature workflows
- Real-time updates
- Data persistence

#### Phase 4: Non-Functional Tests (20-30 minutes)
- Performance benchmarks
- Accessibility validation
- Security checks
- Error handling

### Execution Commands

```bash
# Run all integration tests
npm run test:e2e

# Run specific test suite
npm run test:e2e -- local-auth-flow
npm run test:e2e -- connected-apps
npm run test:e2e -- ai-content-creation
npm run test:e2e -- audience-intelligence
npm run test:e2e -- workflow-creation

# Run with UI mode for debugging
npm run test:e2e -- --ui

# Run headed mode (see browser)
npm run test:e2e -- --headed

# Run with trace
npm run test:e2e -- --trace on

# Generate HTML report
npm run test:e2e -- --reporter=html
```

---

## Test Categories

### 1. Authentication Flow Tests

**File:** `e2e/local-auth-flow.spec.ts`

#### Test Scenarios

##### 1.1 Login Functionality
- **TC-AUTH-001**: Successful login with valid credentials
  - **Given**: User is on login page
  - **When**: User enters valid email and password
  - **Then**: User is redirected to dashboard
  - **And**: User menu is visible with user information

- **TC-AUTH-002**: Failed login with invalid credentials
  - **Given**: User is on login page
  - **When**: User enters invalid email or password
  - **Then**: Error message is displayed
  - **And**: User remains on login page

- **TC-AUTH-003**: Email validation
  - **Given**: User is on login page
  - **When**: User enters invalid email format
  - **Then**: Email format error is displayed
  - **And**: Login button remains disabled

- **TC-AUTH-004**: Password validation
  - **Given**: User is on login page
  - **When**: User enters password less than minimum length
  - **Then**: Password error is displayed

- **TC-AUTH-005**: Remember me functionality
  - **Given**: User is on login page
  - **When**: User checks "Remember Me" and logs in
  - **Then**: Session persists after browser close
  - **And**: User is auto-logged in on return

##### 1.2 Logout Functionality
- **TC-AUTH-010**: Successful logout
  - **Given**: User is authenticated
  - **When**: User clicks logout
  - **Then**: User is redirected to login page
  - **And**: Session is cleared
  - **And**: Protected routes redirect to login

##### 1.3 Session Management
- **TC-AUTH-020**: Session persistence across page refresh
  - **Given**: User is authenticated
  - **When**: User refreshes the page
  - **Then**: User remains authenticated
  - **And**: Dashboard data is visible

- **TC-AUTH-021**: Session timeout handling
  - **Given**: User session has expired
  - **When**: User attempts to access protected route
  - **Then**: User is redirected to login
  - **And**: Appropriate timeout message is shown

- **TC-AUTH-022**: Token refresh
  - **Given**: Access token is about to expire
  - **When**: User makes an authenticated request
  - **Then**: Token is automatically refreshed
  - **And**: Request completes successfully

##### 1.4 Protected Route Access
- **TC-AUTH-030**: Unauthenticated access prevention
  - **Given**: User is not authenticated
  - **When**: User attempts to access dashboard
  - **Then**: User is redirected to login
  - **And**: Return URL is preserved

---

### 2. Connected Apps/Integrations Tests

**File:** `e2e/connected-apps.spec.ts`

#### Test Scenarios

##### 2.1 Integration Marketplace
- **TC-INT-001**: View integration marketplace
  - **Given**: User is authenticated
  - **When**: User navigates to integrations page
  - **Then**: Integration cards are displayed
  - **And**: Category filters are visible

- **TC-INT-002**: Search integrations
  - **Given**: User is on integrations page
  - **When**: User enters search query "Salesforce"
  - **Then**: Filtered results show Salesforce integrations
  - **And**: Result count is updated

- **TC-INT-003**: Filter by category
  - **Given**: User is on integrations page
  - **When**: User selects "CRM" category
  - **Then**: Only CRM integrations are displayed
  - **And**: Other categories can be added

- **TC-INT-004**: View integration details
  - **Given**: User is on integrations page
  - **When**: User clicks integration card
  - **Then**: Integration detail modal opens
  - **And**: Features, pricing, and reviews are visible

##### 2.2 Integration Connection (OAuth)
- **TC-INT-010**: Connect OAuth integration
  - **Given**: User is viewing integration details
  - **When**: User clicks "Connect" button
  - **Then**: OAuth authorization flow initiates
  - **And**: User is redirected to provider login
  - **And**: After authorization, callback completes
  - **And**: Connection status shows "Connected"

- **TC-INT-011**: OAuth connection failure
  - **Given**: User initiates OAuth flow
  - **When**: User denies authorization
  - **Then**: User returns to integration page
  - **And**: Error message explains failure
  - **And**: Connection status remains "Not Connected"

- **TC-INT-012**: PKCE OAuth flow
  - **Given**: Integration requires PKCE
  - **When**: User initiates connection
  - **Then**: Code verifier is generated
  - **And**: Code challenge is sent to provider
  - **And**: Token exchange uses verifier
  - **And**: Connection succeeds securely

##### 2.3 Integration Connection (API Key)
- **TC-INT-020**: Connect API key integration
  - **Given**: User is viewing API key integration
  - **When**: User clicks "Connect"
  - **Then**: API key input modal appears
  - **And**: User enters valid API key
  - **And**: Connection is validated
  - **And**: Status shows "Connected"

- **TC-INT-021**: Invalid API key handling
  - **Given**: User is entering API key
  - **When**: User submits invalid key
  - **Then**: Validation error is shown
  - **And**: Connection fails gracefully
  - **And**: User can retry with correct key

##### 2.4 Integration Management
- **TC-INT-030**: View connected integrations
  - **Given**: User has connected integrations
  - **When**: User navigates to "My Integrations"
  - **Then**: All connected integrations are listed
  - **And**: Connection health status is shown
  - **And**: Last sync time is displayed

- **TC-INT-031**: Disconnect integration
  - **Given**: User has connected integration
  - **When**: User clicks "Disconnect"
  - **Then**: Confirmation modal appears
  - **And**: After confirmation, integration disconnects
  - **And**: Status changes to "Not Connected"

- **TC-INT-032**: Reconfigure integration settings
  - **Given**: Integration is connected
  - **When**: User opens settings
  - **Then**: Configuration options are displayed
  - **And**: User can modify sync frequency
  - **And**: Changes are saved successfully

##### 2.5 Real-time Status Updates
- **TC-INT-040**: Monitor integration health
  - **Given**: Integration is connected
  - **When**: Integration health changes
  - **Then**: Status badge updates in real-time
  - **And**: Health metrics are refreshed
  - **And**: Alerts are shown for critical issues

---

### 3. AI Content Creation Tests

**File:** `e2e/ai-content-creation.spec.ts`

#### Test Scenarios

##### 3.1 Content Creator Agent
- **TC-AI-001**: Access content creator
  - **Given**: User is authenticated
  - **When**: User navigates to content studio
  - **Then**: Content creator interface loads
  - **And**: AI agent options are displayed

- **TC-AI-002**: Generate content with AI agent
  - **Given**: User is in content creator
  - **When**: User enters content prompt
  - **And**: User selects tone and style
  - **Then**: AI generates content
  - **And**: Preview is shown
  - **And**: User can edit generated content

- **TC-AI-003**: Content tone selection
  - **Given**: User is creating content
  - **When**: User selects "Professional" tone
  - **Then**: Generated content matches tone
  - **And**: Tone can be changed
  - **And**: Content regenerates accordingly

- **TC-AI-004**: Multi-platform content adaptation
  - **Given**: Content is generated
  - **When**: User selects platforms (Twitter, LinkedIn)
  - **Then**: Content is adapted for each platform
  - **And**: Character limits are respected
  - **And**: Platform-specific formatting applied

##### 3.2 Content Templates
- **TC-AI-010**: Use content template
  - **Given**: User is in content creator
  - **When**: User selects "Product Launch" template
  - **Then**: Template fields are populated
  - **And**: User fills in custom variables
  - **And**: AI generates based on template

- **TC-AI-011**: Save custom template
  - **Given**: User has created content
  - **When**: User clicks "Save as Template"
  - **Then**: Template is saved
  - **And**: Template appears in library
  - **And**: Template can be reused

##### 3.3 Content Scheduling
- **TC-AI-020**: Schedule content post
  - **Given**: Content is generated
  - **When**: User schedules for future date/time
  - **Then**: Content is added to calendar
  - **And**: Scheduled time is confirmed
  - **And**: User receives confirmation

- **TC-AI-021**: Edit scheduled content
  - **Given**: Content is scheduled
  - **When**: User edits scheduled post
  - **Then**: Changes are saved
  - **And**: Schedule is maintained

---

### 4. Audience Cohort Intelligence Tests

**File:** `e2e/audience-intelligence.spec.ts`

#### Test Scenarios

##### 4.1 Segment Creation
- **TC-AUD-001**: Create new audience segment
  - **Given**: User is in audience manager
  - **When**: User clicks "Create Segment"
  - **Then**: Segment builder opens
  - **And**: User can add conditions
  - **And**: Segment is saved with name

- **TC-AUD-002**: Add segment conditions
  - **Given**: User is creating segment
  - **When**: User adds condition "Age > 25"
  - **And**: User adds condition "Location = US"
  - **Then**: Conditions are combined with AND/OR
  - **And**: Estimated audience size updates
  - **And**: Preview shows matching users

- **TC-AUD-003**: Segment preview
  - **Given**: Segment has conditions
  - **When**: User clicks "Preview"
  - **Then**: Sample audience members shown
  - **And**: Demographic breakdown displayed
  - **And**: Segment size calculated

##### 4.2 Segment Analysis
- **TC-AUD-010**: View segment insights
  - **Given**: Segment is created
  - **When**: User opens segment details
  - **Then**: Analytics dashboard loads
  - **And**: Key metrics are displayed
  - **And**: Demographics chart shown
  - **And**: Behavior patterns visible

- **TC-AUD-011**: Export segment data
  - **Given**: User is viewing segment
  - **When**: User clicks "Export"
  - **Then**: Export options appear (CSV, JSON)
  - **And**: File downloads successfully
  - **And**: Data includes all segment fields

##### 4.3 Segment Management
- **TC-AUD-020**: Edit existing segment
  - **Given**: Segment exists
  - **When**: User modifies conditions
  - **Then**: Segment updates
  - **And**: Size recalculates
  - **And**: Changes are saved

- **TC-AUD-021**: Delete segment
  - **Given**: Segment exists
  - **When**: User clicks delete
  - **Then**: Confirmation modal appears
  - **And**: After confirmation, segment removed
  - **And**: Segment no longer in list

---

### 5. LangFlow Workflow Tests

**File:** `e2e/workflow-creation.spec.ts`

#### Test Scenarios

##### 5.1 Workflow Builder
- **TC-WF-001**: Create new workflow
  - **Given**: User is authenticated
  - **When**: User navigates to workflows
  - **And**: User clicks "Create Workflow"
  - **Then**: Workflow canvas opens
  - **And**: Node palette is visible
  - **And**: Workflow can be named

- **TC-WF-002**: Add trigger node
  - **Given**: User is in workflow builder
  - **When**: User drags "Schedule" trigger
  - **Then**: Trigger node appears on canvas
  - **And**: Configuration panel opens
  - **And**: User can set schedule parameters

- **TC-WF-003**: Add action nodes
  - **Given**: Workflow has trigger
  - **When**: User adds "Content Generator" node
  - **And**: User adds "Social Post" node
  - **Then**: Nodes appear on canvas
  - **And**: Nodes can be configured
  - **And**: Connections between nodes visible

- **TC-WF-004**: Connect workflow nodes
  - **Given**: Multiple nodes exist
  - **When**: User drags connection from trigger to action
  - **Then**: Connection line is created
  - **And**: Data flow is established
  - **And**: Connection can be deleted

##### 5.2 Node Configuration
- **TC-WF-010**: Configure node settings
  - **Given**: Node is selected
  - **When**: User opens configuration panel
  - **Then**: Node-specific settings appear
  - **And**: User can modify parameters
  - **And**: Settings are validated
  - **And**: Changes are auto-saved

- **TC-WF-011**: Add conditional logic
  - **Given**: Workflow has multiple paths
  - **When**: User adds "Condition" node
  - **Then**: Conditional branches created
  - **And**: User defines condition rules
  - **And**: Different actions per branch

##### 5.3 Workflow Execution
- **TC-WF-020**: Test workflow execution
  - **Given**: Workflow is built
  - **When**: User clicks "Test Run"
  - **Then**: Workflow executes
  - **And**: Each node processes in order
  - **And**: Execution log shown
  - **And**: Results displayed

- **TC-WF-021**: Save and activate workflow
  - **Given**: Workflow is configured
  - **When**: User clicks "Save and Activate"
  - **Then**: Workflow is saved
  - **And**: Status changes to "Active"
  - **And**: Workflow runs on schedule

##### 5.4 Workflow Management
- **TC-WF-030**: View workflow history
  - **Given**: Workflow has executed
  - **When**: User opens execution history
  - **Then**: Past runs are listed
  - **And**: Success/failure status shown
  - **And**: Execution logs accessible

- **TC-WF-031**: Pause/Resume workflow
  - **Given**: Workflow is active
  - **When**: User clicks "Pause"
  - **Then**: Workflow status changes to "Paused"
  - **And**: Scheduled executions stop
  - **And**: User can resume later

---

### 6. Campaign Management Tests

**File:** `e2e/campaign-management.spec.ts` (existing, enhanced)

#### Test Scenarios

##### 6.1 Campaign Creation
- **TC-CAM-001**: Create new campaign
- **TC-CAM-002**: Configure campaign settings
- **TC-CAM-003**: Set campaign budget
- **TC-CAM-004**: Define target audience

##### 6.2 Campaign Execution
- **TC-CAM-010**: Launch campaign
- **TC-CAM-011**: Monitor campaign performance
- **TC-CAM-012**: Pause/Resume campaign
- **TC-CAM-013**: Adjust campaign settings

##### 6.3 Campaign Analytics
- **TC-CAM-020**: View campaign metrics
- **TC-CAM-021**: Export campaign report
- **TC-CAM-022**: Compare campaign performance

---

### 7. Dashboard Functionality Tests

**File:** `e2e/dashboard-comprehensive.spec.ts` (new)

#### Test Scenarios

##### 7.1 Dashboard Overview
- **TC-DASH-001**: Load dashboard
  - **Given**: User is authenticated
  - **When**: User navigates to dashboard
  - **Then**: All widgets load within 3 seconds
  - **And**: Key metrics are displayed
  - **And**: Recent activity shown

- **TC-DASH-002**: Real-time metric updates
  - **Given**: Dashboard is open
  - **When**: New data becomes available
  - **Then**: Metrics update automatically
  - **And**: Charts refresh
  - **And**: Notifications appear

##### 7.2 Widget Management
- **TC-DASH-010**: Customize dashboard
  - **Given**: User is on dashboard
  - **When**: User enters edit mode
  - **Then**: Widgets can be rearranged
  - **And**: Widgets can be added/removed
  - **And**: Layout is saved per user

##### 7.3 Analytics Visualization
- **TC-DASH-020**: View performance charts
- **TC-DASH-021**: Change date range
- **TC-DASH-022**: Export dashboard data

---

## Test Coverage Matrix

### Feature Coverage

| Feature Area | Critical Tests | Medium Tests | Low Priority | Total Coverage |
|--------------|----------------|--------------|--------------|----------------|
| Authentication | 12 | 8 | 5 | 95% |
| Integrations | 18 | 12 | 6 | 90% |
| AI Content | 15 | 10 | 5 | 85% |
| Audience | 12 | 8 | 4 | 85% |
| Workflows | 20 | 15 | 8 | 90% |
| Campaigns | 16 | 10 | 6 | 88% |
| Dashboard | 12 | 8 | 4 | 85% |

### Test Type Distribution

| Test Type | Percentage | Count |
|-----------|------------|-------|
| Functional | 60% | 105 |
| Integration | 25% | 44 |
| UI/UX | 10% | 18 |
| Performance | 3% | 5 |
| Security | 2% | 4 |

---

## Test Data Management

### Test Data Sources
- **Fixtures**: `/e2e/fixtures/test-data.ts`
- **Mock APIs**: `/e2e/mocks/api-responses.ts`
- **Test Users**: Defined in fixtures
- **Test Brands**: Pre-configured test brands

### Data Cleanup
- After each test suite completion
- Reset database to known state
- Clear browser storage
- Remove test artifacts

### Data Isolation
- Each test uses unique identifiers
- Tests don't depend on previous test data
- Parallel execution safe

---

## Success Criteria

### Test Passing Requirements
- **Critical Tests**: 100% pass rate
- **Medium Priority**: 95% pass rate
- **Low Priority**: 90% pass rate

### Performance Benchmarks
- **Page Load**: < 2 seconds
- **API Response**: < 500ms
- **UI Interaction**: < 100ms
- **Workflow Execution**: < 5 seconds

### Accessibility Requirements
- **WCAG 2.1 AA**: 100% compliance
- **Keyboard Navigation**: Full support
- **Screen Reader**: Compatible
- **Color Contrast**: 4.5:1 minimum

---

## Risk Assessment

### High Risk Areas
1. **OAuth Integration Flows**
   - **Risk**: Third-party service dependency
   - **Mitigation**: Mock OAuth providers for testing

2. **Real-time Updates**
   - **Risk**: WebSocket connection reliability
   - **Mitigation**: Implement reconnection logic

3. **AI Content Generation**
   - **Risk**: AI service availability
   - **Mitigation**: Mock AI responses for tests

### Medium Risk Areas
1. **Session Management**
2. **Token Refresh**
3. **Workflow Execution**

### Low Risk Areas
1. **Static Content Display**
2. **Read-only Analytics**
3. **Basic Navigation**

---

## Test Execution Schedule

### Daily (Smoke Tests)
- Authentication flow
- Basic navigation
- Critical paths

### Pre-Commit (Fast Tests)
- Unit tests
- Component tests
- Smoke tests

### Pre-Deployment (Full Suite)
- All integration tests
- Performance tests
- Accessibility tests
- Security scans

### Weekly (Extended Tests)
- Cross-browser testing
- Mobile responsiveness
- Load testing
- Visual regression

---

## Reporting and Metrics

### Test Reports
- HTML Report: Generated after each run
- JUnit XML: For CI/CD integration
- JSON Results: For programmatic access
- Screenshots: On failure
- Video: On failure (configurable)

### Key Metrics
- **Pass Rate**: Percentage of passing tests
- **Execution Time**: Total and per-suite
- **Flaky Tests**: Tests with inconsistent results
- **Coverage**: Code and feature coverage
- **Defect Density**: Bugs found per test

---

## Continuous Improvement

### Review Cycle
- **Weekly**: Review failed tests
- **Bi-weekly**: Update test coverage
- **Monthly**: Refactor test suite
- **Quarterly**: Major test strategy review

### Maintenance Tasks
- Remove obsolete tests
- Update test data
- Optimize slow tests
- Enhance test reliability
- Document new test patterns

---

## Appendix

### Test File Locations
```
production-frontend/
├── e2e/
│   ├── local-auth-flow.spec.ts
│   ├── connected-apps.spec.ts
│   ├── ai-content-creation.spec.ts
│   ├── audience-intelligence.spec.ts
│   ├── workflow-creation.spec.ts
│   ├── campaign-management.spec.ts
│   ├── dashboard-comprehensive.spec.ts
│   ├── fixtures/
│   │   └── test-data.ts
│   ├── page-objects/
│   │   ├── AuthPage.ts
│   │   ├── IntegrationsPage.ts
│   │   ├── ContentStudioPage.ts
│   │   ├── AudiencePage.ts
│   │   └── WorkflowBuilderPage.ts
│   └── utils/
│       └── test-helpers.ts
├── playwright.config.ts
└── package.json
```

### Environment Variables
```bash
# Test environment
NODE_ENV=test
PLAYWRIGHT_BASE_URL=http://localhost:3000

# API configuration
NEXT_PUBLIC_API_URL=http://localhost:8000
API_BASE_URL=http://localhost:8000/api

# Test user credentials
TEST_ADMIN_EMAIL=admin@engarde.test
TEST_ADMIN_PASSWORD=Admin123!

# Feature flags for testing
ENABLE_MOCK_API=true
ENABLE_TEST_MODE=true

# Timeouts
TEST_TIMEOUT=60000
EXPECT_TIMEOUT=10000
```

### Quick Reference Commands
```bash
# Setup
npm install && npx playwright install

# Run tests
npm run test:e2e                          # All tests
npm run test:e2e -- --headed             # With browser
npm run test:e2e -- --debug              # Debug mode
npm run test:e2e -- --ui                 # UI mode

# Specific tests
npm run test:e2e local-auth-flow
npm run test:e2e connected-apps
npm run test:e2e ai-content-creation

# Reports
npm run test:e2e -- --reporter=html      # HTML report
npx playwright show-report               # View last report
```

---

**Document Owner:** QA Team
**Review Frequency:** Monthly
**Last Reviewed:** 2025-10-05
**Next Review:** 2025-11-05
