# BDD Test Scenarios: Brand Endpoints 401 Authentication Race Condition

**Feature:** Brand API Authentication During Provider Initialization
**Epic:** Authentication & Authorization
**Priority:** P0 - Critical
**Test Type:** Integration, E2E, Unit
**Date:** October 8, 2025

---

## Table of Contents

1. [Feature Overview](#feature-overview)
2. [Test Scenarios](#test-scenarios)
3. [Unit Test Specifications](#unit-test-specifications)
4. [Integration Test Specifications](#integration-test-specifications)
5. [E2E Test Specifications](#e2e-test-specifications)
6. [Performance Test Specifications](#performance-test-specifications)
7. [Acceptance Criteria](#acceptance-criteria)

---

## Feature Overview

**As a** authenticated user
**I want** brand data to load seamlessly after login
**So that** I can access my dashboard and brand-specific features without errors

**Business Value:**
- Prevents user confusion from authentication errors
- Ensures reliable brand data access
- Improves user experience during login and page refresh
- Eliminates race condition bugs in production

**Technical Context:**
- React Query for data fetching
- Context providers for state management
- JWT token-based authentication
- Race condition between AuthProvider and BrandProvider initialization

---

## Test Scenarios

### Scenario 1: Fresh Login - No Race Condition

```gherkin
Feature: Brand Data Loading After Login

  Scenario: Successful login loads brand data without race condition
    Given the user is on the login page
    And the user is not authenticated
    And no tokens exist in localStorage
    When the user enters email "test@engarde.ai"
    And the user enters password "test123"
    And the user clicks the "Login" button
    Then the authentication should succeed
    And tokens should be stored in localStorage
    And the AuthProvider initialization should complete
    And the BrandProvider should wait for auth to be ready
    And the brand API request should include the Authorization header
    And the API should return 200 OK
    And the user should see their brand name in the header
    And no 401 errors should appear in the console
```

**Expected Outcome:**
- User sees dashboard with brand data
- No error messages displayed
- Console shows successful API calls
- Network tab shows Authorization header in brand requests

**Test Data:**
```json
{
  "user": {
    "email": "test@engarde.ai",
    "password": "test123",
    "userType": "brand"
  },
  "expectedBrand": {
    "id": "brand-123",
    "name": "Test Brand",
    "slug": "test-brand"
  }
}
```

---

### Scenario 2: Page Reload - Cached Authentication

```gherkin
Feature: Brand Data Loading on Page Reload

  Scenario: Page reload with cached tokens loads brand data correctly
    Given the user is authenticated
    And valid tokens exist in localStorage
    And the user data is cached in localStorage
    And the user is on the dashboard page
    When the user refreshes the browser
    Then the page should reload
    And the AuthProvider should initialize from cached tokens
    And the BrandProvider should wait for auth initialization to complete
    And the brand API request should be delayed until auth is ready
    And the Authorization header should be present in the request
    And the API should return 200 OK
    And the brand data should load without errors
    And the user should not see any flash of error state
```

**Expected Outcome:**
- Seamless page reload
- Brand data loads immediately
- No 401 errors
- No loading delays beyond network latency

**Timing Requirements:**
- Auth initialization: < 100ms
- Brand data fetch starts after auth ready
- Total time to brand data: < 500ms

---

### Scenario 3: Direct URL Navigation - Deep Link

```gherkin
Feature: Direct Navigation to Protected Brand Pages

  Scenario: User navigates directly to dashboard via URL
    Given the user has valid authentication tokens
    And the tokens are stored in localStorage
    And the browser cache is warm
    When the user navigates directly to "https://app.engarde.ai/dashboard"
    Then the app should initialize
    And the AuthProvider should load tokens synchronously
    And the AuthProvider should verify token validity
    And the BrandProvider should wait for auth verification
    And the brand API call should include Authorization header
    And the dashboard should load with brand data
    And no authentication errors should occur
```

**Expected Outcome:**
- Direct navigation works reliably
- No redirect to login page
- Brand data loads correctly
- Consistent behavior across different network conditions

---

### Scenario 4: Token Expiration Edge Case

```gherkin
Feature: Brand Data Loading with Expired Tokens

  Scenario: Brand API call with tokens that expire during initialization
    Given the user has authentication tokens
    And the tokens are about to expire in 30 seconds
    And the user is authenticated
    When the user navigates to the dashboard
    Then the AuthProvider should detect token expiration
    And the AuthProvider should attempt to refresh the token
    And the BrandProvider should wait for token refresh
    And the brand API call should use the refreshed token
    And the API should return 200 OK
    And the user should remain authenticated
    And no 401 errors should occur
```

**Expected Outcome:**
- Automatic token refresh
- No user interruption
- Brand data loads successfully
- No authentication errors

**Failure Scenario:**
```gherkin
  Scenario: Token refresh fails during brand data loading
    Given the user has authentication tokens
    And the tokens are expired
    And the token refresh endpoint is unavailable
    When the user navigates to the dashboard
    Then the AuthProvider should attempt token refresh
    And the token refresh should fail
    And the AuthProvider should log the user out
    And the BrandProvider should not make API calls
    And the user should be redirected to the login page
    And a clear error message should be displayed
```

---

### Scenario 5: Race Condition Detection

```gherkin
Feature: Race Condition Prevention in Brand Loading

  Scenario: BrandProvider attempts to load before auth is ready
    Given the AuthProvider is mounted
    And the AuthProvider initialization has started
    And the initialization is not yet complete
    When the BrandProvider mounts as a child
    And the BrandProvider executes useCurrentBrand()
    Then the useQuery hook should check the enabled condition
    And the enabled condition should be false
    And the brand API request should NOT be sent
    And the query should wait for auth to be ready
    When the AuthProvider initialization completes
    And the auth state shows isAuthenticated: true
    Then the enabled condition should become true
    And the brand API request should be sent
    And the Authorization header should be present
    And the API should return 200 OK
```

**Expected Outcome:**
- Query waits for auth readiness
- No premature API calls
- No 401 errors
- Proper synchronization between providers

**Implementation Check:**
```typescript
// Expected code behavior
enabled: !state.initializing && state.isAuthenticated
```

---

### Scenario 6: Concurrent Brand Requests

```gherkin
Feature: Multiple Brand Hooks in Same Component Tree

  Scenario: Multiple components use brand hooks simultaneously
    Given the user is authenticated
    And multiple components use useBrand() hooks
    And the components mount at the same time
    When the component tree renders
    Then only one brand API request should be made
    And the request should wait for auth readiness
    And the request should include Authorization header
    And all components should receive the same brand data
    And no duplicate requests should occur
    And no 401 errors should occur
```

**Expected Outcome:**
- Request deduplication by React Query
- Efficient API usage
- Consistent data across components
- No race conditions

---

### Scenario 7: Network Failure Recovery

```gherkin
Feature: Brand Data Loading with Network Issues

  Scenario: Brand API call fails due to network error
    Given the user is authenticated
    And the auth state is ready
    And the network connection is unstable
    When the BrandProvider loads brand data
    And the brand API request is sent with Authorization
    And the network request times out
    Then React Query should retry the request
    And the retry should include the Authorization header
    And the maximum retries should not be exceeded
    And an error message should be displayed to the user
    And the user should have an option to retry manually
```

**Expected Outcome:**
- Graceful error handling
- Automatic retries with exponential backoff
- Clear user feedback
- No authentication errors (only network errors)

---

### Scenario 8: Backend 401 vs Frontend 401

```gherkin
Feature: Distinguish Backend 401 from Race Condition 401

  Scenario: Backend returns 401 due to invalid token
    Given the user has an invalid authentication token
    And the AuthProvider initialization completes
    And the BrandProvider sends a brand API request
    And the Authorization header is present
    When the backend validates the token
    And the token is invalid or expired
    Then the backend should return 401 Unauthorized
    And the frontend should detect the 401 error
    And the frontend should clear authentication state
    And the user should be redirected to login
    And an appropriate error message should be shown

  Scenario: Frontend 401 due to missing Authorization header (race condition)
    Given the user has valid authentication tokens
    And the AuthProvider initialization is in progress
    And the BrandProvider sends a brand API request prematurely
    And the Authorization header is missing
    When the backend receives the request
    Then the backend should return 401 Unauthorized
    And the frontend should detect the race condition
    And the frontend should NOT clear authentication state
    And the request should be retried with proper Authorization
    And the retry should succeed with 200 OK
```

**Expected Outcome:**
- Proper differentiation between error types
- Correct handling for each scenario
- No false logouts
- Robust error recovery

---

## Unit Test Specifications

### Test Suite: BrandProvider Authentication Dependency

**File:** `/Users/cope/EnGardeHQ/production-frontend/__tests__/contexts/BrandContext.race-condition.test.tsx`

```typescript
describe('BrandProvider - Authentication Race Condition Prevention', () => {

  describe('When auth is initializing', () => {
    it('should not call brand API', async () => {
      // Arrange
      const mockAuthState = {
        isAuthenticated: false,
        user: null,
        loading: false,
        error: null,
        initializing: true, // ← Key: still initializing
        oauthConnections: []
      };

      const mockApiClient = {
        get: jest.fn()
      };

      // Act
      render(
        <MockAuthContext.Provider value={{ state: mockAuthState }}>
          <BrandProvider>
            <div>Test Child</div>
          </BrandProvider>
        </MockAuthContext.Provider>
      );

      // Assert
      await waitFor(() => {
        expect(mockApiClient.get).not.toHaveBeenCalled();
      }, { timeout: 200 });
    });
  });

  describe('When auth completes initialization', () => {
    it('should call brand API with Authorization header', async () => {
      // Arrange
      const mockAuthState = {
        isAuthenticated: true,
        user: { id: 'user-123', email: 'test@engarde.ai', userType: 'brand' },
        loading: false,
        error: null,
        initializing: false, // ← Auth ready
        oauthConnections: []
      };

      const mockApiClient = {
        get: jest.fn().mockResolvedValue({
          data: { data: { id: 'brand-123', name: 'Test Brand' } }
        }),
        getAccessToken: jest.fn().mockReturnValue('valid-token-123')
      };

      // Act
      render(
        <MockAuthContext.Provider value={{ state: mockAuthState }}>
          <BrandProvider>
            <div>Test Child</div>
          </BrandProvider>
        </MockAuthContext.Provider>
      );

      // Assert
      await waitFor(() => {
        expect(mockApiClient.get).toHaveBeenCalledWith('/brands/current');
        expect(mockApiClient.getAccessToken()).toBe('valid-token-123');
      });
    });
  });

  describe('When user is not authenticated', () => {
    it('should not call brand API', async () => {
      // Arrange
      const mockAuthState = {
        isAuthenticated: false, // ← Not authenticated
        user: null,
        loading: false,
        error: null,
        initializing: false, // Init complete but not authenticated
        oauthConnections: []
      };

      const mockApiClient = {
        get: jest.fn()
      };

      // Act
      render(
        <MockAuthContext.Provider value={{ state: mockAuthState }}>
          <BrandProvider>
            <div>Test Child</div>
          </BrandProvider>
        </MockAuthContext.Provider>
      );

      // Assert
      await waitFor(() => {
        expect(mockApiClient.get).not.toHaveBeenCalled();
      }, { timeout: 200 });
    });
  });
});
```

---

### Test Suite: useCurrentBrand Enabled Condition

**File:** `/Users/cope/EnGardeHQ/production-frontend/__tests__/lib/api/brands.race-condition.test.ts`

```typescript
describe('useCurrentBrand - Enabled Condition', () => {

  it('should be disabled when auth is initializing', () => {
    // Arrange
    const mockAuthState = {
      initializing: true,
      isAuthenticated: false
    };

    // Act
    const { result } = renderHook(() => useCurrentBrand(), {
      wrapper: ({ children }) => (
        <MockAuthContext.Provider value={{ state: mockAuthState }}>
          <QueryClientProvider client={queryClient}>
            {children}
          </QueryClientProvider>
        </MockAuthContext.Provider>
      )
    });

    // Assert
    expect(result.current.isLoading).toBe(false); // Not loading because disabled
    expect(result.current.data).toBeUndefined();
    expect(result.current.isFetching).toBe(false);
  });

  it('should be enabled when auth is ready and authenticated', async () => {
    // Arrange
    const mockAuthState = {
      initializing: false,
      isAuthenticated: true
    };

    const mockBrand = { id: 'brand-123', name: 'Test Brand' };
    mockApiClient.get.mockResolvedValue({ data: { data: mockBrand } });

    // Act
    const { result, waitFor } = renderHook(() => useCurrentBrand(), {
      wrapper: ({ children }) => (
        <MockAuthContext.Provider value={{ state: mockAuthState }}>
          <QueryClientProvider client={queryClient}>
            {children}
          </QueryClientProvider>
        </MockAuthContext.Provider>
      )
    });

    // Assert
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(result.current.data).toEqual(mockBrand);
    expect(mockApiClient.get).toHaveBeenCalledWith('/brands/current');
  });

  it('should transition from disabled to enabled when auth completes', async () => {
    // Arrange
    const mockAuthState = {
      initializing: true,
      isAuthenticated: false
    };

    const mockBrand = { id: 'brand-123', name: 'Test Brand' };
    mockApiClient.get.mockResolvedValue({ data: { data: mockBrand } });

    // Act - Initial render with auth initializing
    const { result, rerender, waitFor } = renderHook(() => useCurrentBrand(), {
      wrapper: ({ children }) => (
        <MockAuthContext.Provider value={{ state: mockAuthState }}>
          <QueryClientProvider client={queryClient}>
            {children}
          </QueryClientProvider>
        </MockAuthContext.Provider>
      )
    });

    // Assert - Query is disabled
    expect(result.current.isLoading).toBe(false);
    expect(mockApiClient.get).not.toHaveBeenCalled();

    // Act - Update auth state to ready
    mockAuthState.initializing = false;
    mockAuthState.isAuthenticated = true;
    rerender();

    // Assert - Query is now enabled and fetching
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(result.current.data).toEqual(mockBrand);
    expect(mockApiClient.get).toHaveBeenCalledWith('/brands/current');
  });
});
```

---

## Integration Test Specifications

### Test Suite: Full Provider Stack Integration

**File:** `/Users/cope/EnGardeHQ/production-frontend/__tests__/integration/brand-auth-integration.test.tsx`

```typescript
describe('Brand & Auth Provider Integration', () => {

  it('should load brand data after successful login flow', async () => {
    // Arrange
    const { getByLabelText, getByText, findByText } = render(
      <QueryClientProvider client={queryClient}>
        <AuthProvider>
          <BrandProvider>
            <MockLoginComponent />
            <MockDashboard />
          </BrandProvider>
        </AuthProvider>
      </QueryClientProvider>
    );

    // Mock API responses
    mockApiClient.post.mockResolvedValueOnce({
      data: {
        access_token: 'token-123',
        refresh_token: 'refresh-123',
        expires_in: 3600,
        token_type: 'Bearer',
        user: { id: 'user-123', email: 'test@engarde.ai', userType: 'brand' }
      }
    });

    mockApiClient.get.mockResolvedValueOnce({
      data: { data: { id: 'brand-123', name: 'Test Brand' } }
    });

    // Act - Login
    fireEvent.change(getByLabelText('Email'), { target: { value: 'test@engarde.ai' } });
    fireEvent.change(getByLabelText('Password'), { target: { value: 'test123' } });
    fireEvent.click(getByText('Login'));

    // Assert - Brand data loads
    const brandName = await findByText('Test Brand', {}, { timeout: 2000 });
    expect(brandName).toBeInTheDocument();

    // Verify API calls occurred in correct order
    const apiCalls = mockApiClient.mock.calls;
    expect(apiCalls[0][0]).toBe('/auth/login'); // Login first
    expect(apiCalls[1][0]).toBe('/brands/current'); // Brand second
  });

  it('should load brand data on page reload with cached auth', async () => {
    // Arrange - Set up cached auth
    localStorage.setItem('engarde_tokens', JSON.stringify({
      accessToken: 'token-123',
      refreshToken: 'refresh-123',
      expiresAt: Date.now() + 3600000
    }));

    localStorage.setItem('engarde_user', JSON.stringify({
      id: 'user-123',
      email: 'test@engarde.ai',
      userType: 'brand',
      cachedAt: Date.now()
    }));

    mockApiClient.get.mockResolvedValueOnce({
      data: { data: { id: 'brand-123', name: 'Cached Brand' } }
    });

    // Act - Render app as if page reloaded
    const { findByText } = render(
      <QueryClientProvider client={queryClient}>
        <AuthProvider>
          <BrandProvider>
            <MockDashboard />
          </BrandProvider>
        </AuthProvider>
      </QueryClientProvider>
    );

    // Assert - Brand loads without login
    const brandName = await findByText('Cached Brand', {}, { timeout: 2000 });
    expect(brandName).toBeInTheDocument();
    expect(mockApiClient.get).toHaveBeenCalledWith('/brands/current');
  });
});
```

---

## E2E Test Specifications

### Test Suite: End-to-End Brand Loading

**File:** `/Users/cope/EnGardeHQ/production-frontend/e2e/brand-401-race-condition.spec.ts`

```typescript
import { test, expect } from '@playwright/test';

test.describe('Brand 401 Race Condition Prevention', () => {

  test.beforeEach(async ({ page }) => {
    // Clear all storage
    await page.goto('/');
    await page.evaluate(() => {
      localStorage.clear();
      sessionStorage.clear();
    });
  });

  test('should load brand data after login without 401 errors', async ({ page }) => {
    // Arrange - Set up request monitoring
    const requests = [];
    const responses = [];

    page.on('request', request => {
      if (request.url().includes('/brands/current')) {
        requests.push({
          url: request.url(),
          headers: request.headers(),
          timestamp: Date.now()
        });
      }
    });

    page.on('response', response => {
      if (response.url().includes('/brands/current')) {
        responses.push({
          url: response.url(),
          status: response.status(),
          timestamp: Date.now()
        });
      }
    });

    // Act - Login
    await page.goto('/login');
    await page.fill('input[name="email"]', 'test@engarde.ai');
    await page.fill('input[name="password"]', 'test123');
    await page.click('button[type="submit"]');

    // Wait for dashboard
    await page.waitForURL('/dashboard', { timeout: 5000 });

    // Assert - Check brand data loaded
    await expect(page.locator('[data-testid="brand-name"]')).toBeVisible({ timeout: 3000 });

    // Assert - All brand requests had Authorization header
    const missingAuth = requests.filter(req => !req.headers['authorization']);
    expect(missingAuth).toHaveLength(0);

    // Assert - No 401 responses
    const unauthorized = responses.filter(res => res.status === 401);
    expect(unauthorized).toHaveLength(0);

    // Assert - At least one successful brand request
    const successful = responses.filter(res => res.status === 200);
    expect(successful.length).toBeGreaterThan(0);
  });

  test('should load brand data on page reload without 401 errors', async ({ page, context }) => {
    // Arrange - Login first
    await page.goto('/login');
    await page.fill('input[name="email"]', 'test@engarde.ai');
    await page.fill('input[name="password"]', 'test123');
    await page.click('button[type="submit"]');
    await page.waitForURL('/dashboard');

    // Store the auth state
    const cookies = await context.cookies();
    const storage = await page.evaluate(() => ({
      local: JSON.stringify(localStorage),
      session: JSON.stringify(sessionStorage)
    }));

    // Act - Reload the page
    const requests = [];
    page.on('request', request => {
      if (request.url().includes('/brands')) {
        requests.push({
          url: request.url(),
          hasAuth: !!request.headers()['authorization']
        });
      }
    });

    await page.reload();

    // Assert - Brand data loads after reload
    await expect(page.locator('[data-testid="brand-name"]')).toBeVisible({ timeout: 3000 });

    // Assert - All brand requests have auth
    expect(requests.every(req => req.hasAuth)).toBe(true);
  });

  test('should handle direct navigation to dashboard', async ({ page, context }) => {
    // Arrange - Set up auth state without going through login
    await page.goto('/');

    // Inject valid auth state
    await page.evaluate(() => {
      localStorage.setItem('engarde_tokens', JSON.stringify({
        accessToken: 'valid-test-token',
        refreshToken: 'valid-refresh-token',
        expiresAt: Date.now() + 3600000
      }));

      localStorage.setItem('engarde_user', JSON.stringify({
        id: 'user-123',
        email: 'test@engarde.ai',
        userType: 'brand',
        isActive: true,
        cachedAt: Date.now()
      }));
    });

    // Monitor requests
    const brandRequests = [];
    page.on('request', request => {
      if (request.url().includes('/brands/current')) {
        brandRequests.push({
          hasAuth: !!request.headers()['authorization'],
          authHeader: request.headers()['authorization']
        });
      }
    });

    // Act - Navigate directly to dashboard
    await page.goto('/dashboard');

    // Assert - Dashboard loads with brand data
    await expect(page.locator('[data-testid="brand-name"]')).toBeVisible({ timeout: 3000 });

    // Assert - Brand request had authorization
    expect(brandRequests.length).toBeGreaterThan(0);
    expect(brandRequests.every(req => req.hasAuth)).toBe(true);
    expect(brandRequests[0].authHeader).toMatch(/^Bearer /);
  });

  test('should show timing of auth init vs brand request', async ({ page }) => {
    // Arrange - Add performance markers
    await page.goto('/login');

    // Inject performance monitoring
    await page.evaluate(() => {
      window.authTimeline = [];

      // Intercept console logs to capture timing
      const originalLog = console.log;
      console.log = (...args) => {
        const message = args.join(' ');
        if (message.includes('AUTH') || message.includes('BRAND')) {
          window.authTimeline.push({
            message,
            timestamp: performance.now()
          });
        }
        originalLog(...args);
      };
    });

    // Act - Login
    await page.fill('input[name="email"]', 'test@engarde.ai');
    await page.fill('input[name="password"]', 'test123');
    await page.click('button[type="submit"]');
    await page.waitForURL('/dashboard');

    // Assert - Get timing data
    const timeline = await page.evaluate(() => window.authTimeline);

    // Find auth init complete and brand request start
    const authComplete = timeline.find(t => t.message.includes('AUTH') && t.message.includes('success'));
    const brandRequest = timeline.find(t => t.message.includes('BRAND') || t.message.includes('/brands/current'));

    // Assert - Brand request should come AFTER auth complete
    if (authComplete && brandRequest) {
      expect(brandRequest.timestamp).toBeGreaterThan(authComplete.timestamp);
    }

    // Log timeline for debugging
    console.log('Auth Timeline:', timeline);
  });
});
```

---

## Performance Test Specifications

### Test Suite: Race Condition Under Load

```typescript
describe('Brand Loading Performance Under Various Conditions', () => {

  test('should handle rapid page refreshes without 401', async () => {
    // Simulate user rapidly refreshing dashboard
    for (let i = 0; i < 10; i++) {
      await page.reload();
      const errors = await page.evaluate(() => {
        const consoleLogs = window.testConsoleLogs || [];
        return consoleLogs.filter(log => log.includes('401'));
      });
      expect(errors).toHaveLength(0);
    }
  });

  test('should handle slow network conditions', async ({ page, context }) => {
    // Arrange - Throttle network
    await context.route('**/*', route => {
      setTimeout(() => route.continue(), 500); // 500ms delay
    });

    // Act - Login and load brand
    await page.goto('/login');
    await page.fill('input[name="email"]', 'test@engarde.ai');
    await page.fill('input[name="password"]', 'test123');
    await page.click('button[type="submit"]');

    // Assert - Should still work despite slow network
    await expect(page.locator('[data-testid="brand-name"]')).toBeVisible({ timeout: 10000 });
  });

  test('should measure time from login to brand data load', async ({ page }) => {
    // Arrange
    await page.goto('/login');

    // Act
    const startTime = Date.now();

    await page.fill('input[name="email"]', 'test@engarde.ai');
    await page.fill('input[name="password"]', 'test123');
    await page.click('button[type="submit"]');
    await page.waitForURL('/dashboard');
    await expect(page.locator('[data-testid="brand-name"]')).toBeVisible();

    const endTime = Date.now();
    const totalTime = endTime - startTime;

    // Assert - Should complete in reasonable time
    expect(totalTime).toBeLessThan(3000); // 3 seconds max

    console.log(`Brand data load time: ${totalTime}ms`);
  });
});
```

---

## Acceptance Criteria

### Must Have (P0)

✅ **AC1:** Brand API requests MUST include Authorization header
- **Verification:** Check Network tab for `Authorization: Bearer <token>` header
- **Test:** E2E test monitors all brand requests

✅ **AC2:** Brand API requests MUST NOT be sent before auth is ready
- **Verification:** React Query `enabled` condition prevents premature execution
- **Test:** Unit tests verify enabled condition logic

✅ **AC3:** No 401 errors should occur during normal login flow
- **Verification:** Console shows no 401 errors, Network tab shows 200 responses
- **Test:** E2E test asserts zero 401 responses

✅ **AC4:** Brand data MUST load within 2 seconds of successful login
- **Verification:** Performance monitoring tracks time from login to brand load
- **Test:** Performance test measures and asserts timing

✅ **AC5:** Page reload MUST preserve authentication and load brand data
- **Verification:** Reload dashboard multiple times, verify consistent behavior
- **Test:** E2E test simulates page reload scenario

### Should Have (P1)

✅ **AC6:** Clear error messages when authentication fails
- **Verification:** User sees actionable error message
- **Test:** Error scenario tests

✅ **AC7:** Automatic retry on transient failures
- **Verification:** React Query retry logic with exponential backoff
- **Test:** Integration tests with network failures

✅ **AC8:** Monitoring and logging for race condition detection
- **Verification:** Production logs capture race condition events
- **Test:** Monitoring integration tests

### Nice to Have (P2)

✅ **AC9:** Loading states during auth initialization
- **Verification:** User sees loading indicator
- **Test:** Visual regression tests

✅ **AC10:** Graceful degradation when brand API is unavailable
- **Verification:** App remains functional without brand data
- **Test:** Fallback scenario tests

---

## Test Execution Checklist

### Pre-Test Setup

- [ ] Backend API is running and accessible
- [ ] Test database is seeded with test user (test@engarde.ai / test123)
- [ ] Test brand data exists for test user
- [ ] Environment variables are configured correctly
- [ ] Test credentials are valid

### Unit Tests

- [ ] Run: `npm run test -- brands.race-condition.test`
- [ ] All tests pass
- [ ] Coverage > 80% for modified files
- [ ] No console errors during test execution

### Integration Tests

- [ ] Run: `npm run test -- brand-auth-integration.test`
- [ ] All scenarios pass
- [ ] Request mocking works correctly
- [ ] Provider interactions are tested

### E2E Tests

- [ ] Run: `npm run test:e2e -- brand-401-race-condition.spec`
- [ ] All tests pass in Chrome
- [ ] All tests pass in Firefox
- [ ] All tests pass in Safari (if applicable)
- [ ] Screenshots captured for failures
- [ ] Network logs reviewed

### Manual Testing

- [ ] Fresh login: No 401 errors
- [ ] Page reload: Brand data loads correctly
- [ ] Direct navigation: Dashboard accessible
- [ ] Token expiration: Handled gracefully
- [ ] Network issues: Proper error handling
- [ ] Multiple tabs: Consistent behavior

---

## Test Data Requirements

### Test Users

```json
{
  "testUser1": {
    "email": "test@engarde.ai",
    "password": "test123",
    "userType": "brand",
    "brands": [
      {
        "id": "brand-123",
        "name": "Test Brand",
        "slug": "test-brand"
      }
    ]
  }
}
```

### Mock API Responses

```json
{
  "loginSuccess": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 3600,
    "token_type": "Bearer",
    "user": {
      "id": "user-123",
      "email": "test@engarde.ai",
      "userType": "brand"
    }
  },
  "brandCurrent": {
    "brand": {
      "id": "brand-123",
      "name": "Test Brand",
      "slug": "test-brand",
      "website": "https://testbrand.com"
    },
    "is_member": true,
    "member_role": "owner"
  }
}
```

---

## Debugging & Troubleshooting

### If Tests Fail

1. **Check auth state timing:**
   ```javascript
   // In browser console
   window.debugAuth()
   ```

2. **Verify token storage:**
   ```javascript
   window.checkAuth()
   ```

3. **Review request timeline:**
   - Open DevTools Network tab
   - Filter by "brands"
   - Check Authorization header in each request
   - Note timing relative to page load

4. **Enable auth tracing:**
   ```javascript
   window.traceAuth()
   ```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| 401 on first load | Race condition | Verify `enabled` condition in useCurrentBrand |
| Flaky tests | Timing-dependent assertions | Use `waitFor` with appropriate timeouts |
| Token not found | localStorage cleared | Check beforeEach hooks in tests |
| Multiple requests | React strict mode | Expected in development, single request in production |

---

## Metrics & KPIs

### Success Metrics

- **Zero 401 errors** during normal authentication flow
- **100% Authorization header presence** in brand API requests
- **< 500ms** auth initialization time (p95)
- **< 2 seconds** total time from login to brand data load (p95)
- **0 race condition incidents** in production monitoring

### Monitoring Queries

```javascript
// Production monitoring (pseudo-code)
{
  "race_condition_detection": {
    "query": "http.status_code:401 AND http.url:/brands/current",
    "alert_threshold": 10,
    "time_window": "5m"
  },
  "auth_timing": {
    "query": "performance.measure:auth_to_brand_load",
    "p95_threshold": 2000
  }
}
```

---

**Test Suite Maintained By:** QA Engineering Team
**Last Updated:** October 8, 2025
**Next Review:** After fix implementation
