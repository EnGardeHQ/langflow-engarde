/**
 * Tournament Management Tests for EnGarde Platform
 *
 * Tests tournament creation, editing, and management functionality
 * for coaches and administrators.
 */

const { test, expect } = require('@playwright/test');

test.describe('Tournament Management', () => {

  // Use admin authentication state for these tests
  test.use({ storageState: '/Users/cope/EnGardeHQ/playwright-testing/config/auth-admin.json' });

  test.beforeEach(async ({ page }) => {
    // Navigate to tournaments page before each test
    await page.goto('/tournaments');
  });

  test('should display tournaments list page correctly', async ({ page }) => {
    // Verify page title and main elements
    await expect(page).toHaveTitle(/EnGarde.*Tournaments/);
    await expect(page.locator('[data-testid="tournaments-header"]')).toBeVisible();
    await expect(page.locator('[data-testid="create-tournament-button"]')).toBeVisible();
    await expect(page.locator('[data-testid="tournaments-table"]')).toBeVisible();
  });

  test('should create a new tournament successfully', async ({ page }) => {
    // Click create tournament button
    await page.click('[data-testid="create-tournament-button"]');

    // Verify create tournament modal/form is displayed
    await expect(page.locator('[data-testid="create-tournament-form"]')).toBeVisible();

    // Fill tournament details
    await page.fill('[data-testid="tournament-name-input"]', 'Test Tournament 2024');
    await page.fill('[data-testid="tournament-date-input"]', '2024-12-15');
    await page.fill('[data-testid="tournament-location-input"]', 'Test Fencing Club');
    await page.selectOption('[data-testid="tournament-weapon-select"]', 'epee');
    await page.fill('[data-testid="tournament-entry-fee-input"]', '50');
    await page.fill('[data-testid="tournament-max-entries-input"]', '64');

    // Set tournament times
    await page.fill('[data-testid="tournament-checkin-time-input"]', '08:00');
    await page.fill('[data-testid="tournament-start-time-input"]', '09:00');

    // Add tournament description
    await page.fill('[data-testid="tournament-description-textarea"]', 'Annual year-end epee tournament for all skill levels.');

    // Submit the form
    await page.click('[data-testid="create-tournament-submit-button"]');

    // Verify success message and redirect
    await expect(page.locator('[data-testid="success-message"]')).toBeVisible();
    await expect(page.locator('[data-testid="success-message"]')).toContainText('Tournament created successfully');

    // Verify tournament appears in the list
    await expect(page.locator('[data-testid="tournament-Test Tournament 2024"]')).toBeVisible();
  });

  test('should validate required fields when creating tournament', async ({ page }) => {
    // Click create tournament button
    await page.click('[data-testid="create-tournament-button"]');

    // Try to submit without filling required fields
    await page.click('[data-testid="create-tournament-submit-button"]');

    // Verify validation messages
    await expect(page.locator('[data-testid="tournament-name-error"]')).toBeVisible();
    await expect(page.locator('[data-testid="tournament-date-error"]')).toBeVisible();
    await expect(page.locator('[data-testid="tournament-location-error"]')).toBeVisible();
    await expect(page.locator('[data-testid="tournament-weapon-error"]')).toBeVisible();
  });

  test('should edit existing tournament', async ({ page }) => {
    // Find and click edit button for first tournament
    await page.click('[data-testid="tournament-row"]:first-child [data-testid="edit-tournament-button"]');

    // Verify edit form is displayed
    await expect(page.locator('[data-testid="edit-tournament-form"]')).toBeVisible();

    // Modify tournament details
    const newName = 'Updated Test Tournament 2024';
    await page.fill('[data-testid="tournament-name-input"]', newName);
    await page.fill('[data-testid="tournament-entry-fee-input"]', '60');

    // Submit changes
    await page.click('[data-testid="update-tournament-submit-button"]');

    // Verify success message
    await expect(page.locator('[data-testid="success-message"]')).toBeVisible();
    await expect(page.locator('[data-testid="success-message"]')).toContainText('Tournament updated successfully');

    // Verify changes are reflected in the list
    await expect(page.locator(`[data-testid="tournament-${newName}"]`)).toBeVisible();
  });

  test('should delete tournament with confirmation', async ({ page }) => {
    // Get initial tournament count
    const initialCount = await page.locator('[data-testid="tournament-row"]').count();

    // Click delete button for first tournament
    await page.click('[data-testid="tournament-row"]:first-child [data-testid="delete-tournament-button"]');

    // Verify confirmation dialog
    await expect(page.locator('[data-testid="delete-confirmation-dialog"]')).toBeVisible();
    await expect(page.locator('[data-testid="delete-confirmation-message"]')).toContainText('Are you sure you want to delete this tournament?');

    // Confirm deletion
    await page.click('[data-testid="confirm-delete-button"]');

    // Verify success message
    await expect(page.locator('[data-testid="success-message"]')).toBeVisible();
    await expect(page.locator('[data-testid="success-message"]')).toContainText('Tournament deleted successfully');

    // Verify tournament count decreased
    await expect(page.locator('[data-testid="tournament-row"]')).toHaveCount(initialCount - 1);
  });

  test('should cancel tournament deletion', async ({ page }) => {
    // Get initial tournament count
    const initialCount = await page.locator('[data-testid="tournament-row"]').count();

    // Click delete button
    await page.click('[data-testid="tournament-row"]:first-child [data-testid="delete-tournament-button"]');

    // Verify confirmation dialog
    await expect(page.locator('[data-testid="delete-confirmation-dialog"]')).toBeVisible();

    // Cancel deletion
    await page.click('[data-testid="cancel-delete-button"]');

    // Verify dialog is closed and tournament count unchanged
    await expect(page.locator('[data-testid="delete-confirmation-dialog"]')).not.toBeVisible();
    await expect(page.locator('[data-testid="tournament-row"]')).toHaveCount(initialCount);
  });

  test('should filter tournaments by weapon', async ({ page }) => {
    // Verify filter dropdown is available
    await expect(page.locator('[data-testid="weapon-filter-select"]')).toBeVisible();

    // Filter by epee
    await page.selectOption('[data-testid="weapon-filter-select"]', 'epee');

    // Wait for filter to apply
    await page.waitForTimeout(500);

    // Verify only epee tournaments are shown
    const tournamentRows = page.locator('[data-testid="tournament-row"]');
    const count = await tournamentRows.count();

    for (let i = 0; i < count; i++) {
      const weapon = await tournamentRows.nth(i).locator('[data-testid="tournament-weapon"]').textContent();
      expect(weapon).toContain('Epee');
    }
  });

  test('should search tournaments by name', async ({ page }) => {
    // Use search functionality
    await page.fill('[data-testid="tournament-search-input"]', 'Test');

    // Wait for search to apply
    await page.waitForTimeout(500);

    // Verify filtered results contain search term
    const tournamentRows = page.locator('[data-testid="tournament-row"]');
    const count = await tournamentRows.count();

    for (let i = 0; i < count; i++) {
      const name = await tournamentRows.nth(i).locator('[data-testid="tournament-name"]').textContent();
      expect(name.toLowerCase()).toContain('test');
    }
  });

  test('should sort tournaments by date', async ({ page }) => {
    // Click on date column header to sort
    await page.click('[data-testid="sort-by-date-header"]');

    // Wait for sort to apply
    await page.waitForTimeout(500);

    // Verify tournaments are sorted by date (ascending)
    const dates = await page.locator('[data-testid="tournament-date"]').allTextContents();
    const sortedDates = [...dates].sort();
    expect(dates).toEqual(sortedDates);

    // Click again to sort descending
    await page.click('[data-testid="sort-by-date-header"]');
    await page.waitForTimeout(500);

    // Verify reverse sort
    const datesDesc = await page.locator('[data-testid="tournament-date"]').allTextContents();
    const sortedDatesDesc = [...dates].sort().reverse();
    expect(datesDesc).toEqual(sortedDatesDesc);
  });

  test('should view tournament details', async ({ page }) => {
    // Click on first tournament name to view details
    await page.click('[data-testid="tournament-row"]:first-child [data-testid="tournament-name-link"]');

    // Verify tournament details page
    await expect(page).toHaveURL(/.*\/tournaments\/.*\/details/);
    await expect(page.locator('[data-testid="tournament-details-header"]')).toBeVisible();
    await expect(page.locator('[data-testid="tournament-participants-section"]')).toBeVisible();
    await expect(page.locator('[data-testid="tournament-schedule-section"]')).toBeVisible();
  });

  test('should handle tournament status changes', async ({ page }) => {
    // Find tournament with 'upcoming' status
    const upcomingTournament = page.locator('[data-testid="tournament-row"]').filter({ hasText: 'Upcoming' }).first();

    // Click status dropdown
    await upcomingTournament.locator('[data-testid="tournament-status-dropdown"]').click();

    // Change status to 'active'
    await page.click('[data-testid="status-option-active"]');

    // Verify status change confirmation
    await expect(page.locator('[data-testid="status-change-confirmation"]')).toBeVisible();
    await page.click('[data-testid="confirm-status-change-button"]');

    // Verify status updated
    await expect(upcomingTournament.locator('[data-testid="tournament-status"]')).toContainText('Active');
  });

});