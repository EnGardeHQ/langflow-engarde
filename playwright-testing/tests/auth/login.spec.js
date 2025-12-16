/**
 * Authentication Tests for EnGarde Platform
 *
 * Tests user authentication flows including login, logout,
 * and role-based access control.
 */

const { test, expect } = require('@playwright/test');

test.describe('User Authentication', () => {

  test.beforeEach(async ({ page }) => {
    // Navigate to login page before each test
    await page.goto('/login');
  });

  test('should display login form correctly', async ({ page }) => {
    // Verify login form elements are present
    await expect(page.locator('[data-testid="login-form"]')).toBeVisible();
    await expect(page.locator('[data-testid="email-input"]')).toBeVisible();
    await expect(page.locator('[data-testid="password-input"]')).toBeVisible();
    await expect(page.locator('[data-testid="login-button"]')).toBeVisible();

    // Verify page title and heading
    await expect(page).toHaveTitle(/EnGarde.*Login/);
    await expect(page.locator('h1')).toContainText('Sign In');
  });

  test('should successfully login with valid admin credentials', async ({ page }) => {
    // Fill login form with admin credentials
    await page.fill('[data-testid="email-input"]', 'admin@engarde.test');
    await page.fill('[data-testid="password-input"]', 'admin123');

    // Submit login form
    await page.click('[data-testid="login-button"]');

    // Verify successful login redirect to dashboard
    await expect(page).toHaveURL(/.*\/dashboard/);
    await expect(page.locator('[data-testid="user-menu"]')).toBeVisible();
    await expect(page.locator('[data-testid="admin-panel-link"]')).toBeVisible();
  });

  test('should successfully login with valid coach credentials', async ({ page }) => {
    // Fill login form with coach credentials
    await page.fill('[data-testid="email-input"]', 'coach@engarde.test');
    await page.fill('[data-testid="password-input"]', 'coach123');

    // Submit login form
    await page.click('[data-testid="login-button"]');

    // Verify successful login and coach-specific UI elements
    await expect(page).toHaveURL(/.*\/dashboard/);
    await expect(page.locator('[data-testid="user-menu"]')).toBeVisible();
    await expect(page.locator('[data-testid="tournament-management-link"]')).toBeVisible();
  });

  test('should successfully login with valid fencer credentials', async ({ page }) => {
    // Fill login form with fencer credentials
    await page.fill('[data-testid="email-input"]', 'fencer@engarde.test');
    await page.fill('[data-testid="password-input"]', 'fencer123');

    // Submit login form
    await page.click('[data-testid="login-button"]');

    // Verify successful login and fencer-specific UI elements
    await expect(page).toHaveURL(/.*\/dashboard/);
    await expect(page.locator('[data-testid="user-menu"]')).toBeVisible();
    await expect(page.locator('[data-testid="my-tournaments-link"]')).toBeVisible();
  });

  test('should show error message for invalid credentials', async ({ page }) => {
    // Fill login form with invalid credentials
    await page.fill('[data-testid="email-input"]', 'invalid@engarde.test');
    await page.fill('[data-testid="password-input"]', 'wrongpassword');

    // Submit login form
    await page.click('[data-testid="login-button"]');

    // Verify error message is displayed
    await expect(page.locator('[data-testid="login-error"]')).toBeVisible();
    await expect(page.locator('[data-testid="login-error"]')).toContainText('Invalid email or password');

    // Verify user remains on login page
    await expect(page).toHaveURL(/.*\/login/);
  });

  test('should validate required fields', async ({ page }) => {
    // Try to submit without filling any fields
    await page.click('[data-testid="login-button"]');

    // Verify validation messages
    await expect(page.locator('[data-testid="email-error"]')).toBeVisible();
    await expect(page.locator('[data-testid="password-error"]')).toBeVisible();

    // Fill only email and try to submit
    await page.fill('[data-testid="email-input"]', 'test@engarde.test');
    await page.click('[data-testid="login-button"]');

    // Verify password validation message still shows
    await expect(page.locator('[data-testid="password-error"]')).toBeVisible();
  });

  test('should handle login loading state', async ({ page }) => {
    // Fill login form
    await page.fill('[data-testid="email-input"]', 'admin@engarde.test');
    await page.fill('[data-testid="password-input"]', 'admin123');

    // Submit and check for loading state
    await page.click('[data-testid="login-button"]');

    // Verify loading state is shown briefly
    await expect(page.locator('[data-testid="login-loading"]')).toBeVisible();

    // Wait for login to complete
    await expect(page).toHaveURL(/.*\/dashboard/, { timeout: 10000 });
  });

  test('should redirect to intended page after login', async ({ page }) => {
    // Try to access protected route while not logged in
    await page.goto('/tournaments');

    // Should be redirected to login with return URL
    await expect(page).toHaveURL(/.*\/login.*redirect/);

    // Login with valid credentials
    await page.fill('[data-testid="email-input"]', 'admin@engarde.test');
    await page.fill('[data-testid="password-input"]', 'admin123');
    await page.click('[data-testid="login-button"]');

    // Should be redirected to originally requested page
    await expect(page).toHaveURL(/.*\/tournaments/);
  });

  test('should logout successfully', async ({ page }) => {
    // Login first
    await page.fill('[data-testid="email-input"]', 'admin@engarde.test');
    await page.fill('[data-testid="password-input"]', 'admin123');
    await page.click('[data-testid="login-button"]');

    // Wait for dashboard to load
    await expect(page).toHaveURL(/.*\/dashboard/);

    // Click logout
    await page.click('[data-testid="user-menu"]');
    await page.click('[data-testid="logout-button"]');

    // Verify logout successful
    await expect(page).toHaveURL(/.*\/login/);
    await expect(page.locator('[data-testid="logout-message"]')).toBeVisible();
  });

});