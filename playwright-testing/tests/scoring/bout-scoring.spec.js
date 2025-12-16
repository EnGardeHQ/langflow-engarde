/**
 * Bout Scoring Tests for EnGarde Platform
 *
 * Tests the core fencing bout scoring functionality including
 * touch recording, timer management, and bout completion.
 */

const { test, expect } = require('@playwright/test');

test.describe('Bout Scoring System', () => {

  // Use coach authentication state for these tests
  test.use({ storageState: '/Users/cope/EnGardeHQ/playwright-testing/config/auth-coach.json' });

  test.beforeEach(async ({ page }) => {
    // Navigate to active bout scoring page
    await page.goto('/tournaments/test-tournament-001/bouts/active');
  });

  test('should display bout scoring interface correctly', async ({ page }) => {
    // Verify main scoring elements are present
    await expect(page.locator('[data-testid="bout-scoring-interface"]')).toBeVisible();
    await expect(page.locator('[data-testid="fencer-left-panel"]')).toBeVisible();
    await expect(page.locator('[data-testid="fencer-right-panel"]')).toBeVisible();
    await expect(page.locator('[data-testid="bout-timer"]')).toBeVisible();
    await expect(page.locator('[data-testid="bout-controls"]')).toBeVisible();

    // Verify fencer information is displayed
    await expect(page.locator('[data-testid="fencer-left-name"]')).toContainText('Test Fencer 1');
    await expect(page.locator('[data-testid="fencer-right-name"]')).toContainText('Test Fencer 2');

    // Verify scoring buttons
    await expect(page.locator('[data-testid="score-left-button"]')).toBeVisible();
    await expect(page.locator('[data-testid="score-right-button"]')).toBeVisible();
    await expect(page.locator('[data-testid="double-touch-button"]')).toBeVisible();
    await expect(page.locator('[data-testid="no-touch-button"]')).toBeVisible();
  });

  test('should start bout timer correctly', async ({ page }) => {
    // Verify timer shows initial time (3:00 for standard bout)
    await expect(page.locator('[data-testid="bout-timer"]')).toContainText('3:00');

    // Start the bout
    await page.click('[data-testid="start-bout-button"]');

    // Verify timer starts counting down
    await page.waitForTimeout(2000);
    const timerText = await page.locator('[data-testid="bout-timer"]').textContent();
    expect(timerText).toMatch(/2:5[0-9]/); // Should be around 2:58 or 2:59
  });

  test('should record touch for left fencer', async ({ page }) => {
    // Start the bout
    await page.click('[data-testid="start-bout-button"]');

    // Record touch for left fencer
    await page.click('[data-testid="score-left-button"]');

    // Verify score updated
    await expect(page.locator('[data-testid="fencer-left-score"]')).toContainText('1');
    await expect(page.locator('[data-testid="fencer-right-score"]')).toContainText('0');

    // Verify touch is logged
    await expect(page.locator('[data-testid="touch-log"]')).toContainText('Touch: Test Fencer 1');
  });

  test('should record touch for right fencer', async ({ page }) => {
    // Start the bout
    await page.click('[data-testid="start-bout-button"]');

    // Record touch for right fencer
    await page.click('[data-testid="score-right-button"]');

    // Verify score updated
    await expect(page.locator('[data-testid="fencer-left-score"]')).toContainText('0');
    await expect(page.locator('[data-testid="fencer-right-score"]')).toContainText('1');

    // Verify touch is logged
    await expect(page.locator('[data-testid="touch-log"]')).toContainText('Touch: Test Fencer 2');
  });

  test('should record double touch correctly', async ({ page }) => {
    // Start the bout
    await page.click('[data-testid="start-bout-button"]');

    // Record double touch
    await page.click('[data-testid="double-touch-button"]');

    // Verify both scores increased
    await expect(page.locator('[data-testid="fencer-left-score"]')).toContainText('1');
    await expect(page.locator('[data-testid="fencer-right-score"]')).toContainText('1');

    // Verify double touch is logged
    await expect(page.locator('[data-testid="touch-log"]')).toContainText('Double Touch');
  });

  test('should handle no touch action', async ({ page }) => {
    // Start the bout
    await page.click('[data-testid="start-bout-button"]');

    // Get initial scores
    const leftScore = await page.locator('[data-testid="fencer-left-score"]').textContent();
    const rightScore = await page.locator('[data-testid="fencer-right-score"]').textContent();

    // Record no touch
    await page.click('[data-testid="no-touch-button"]');

    // Verify scores unchanged
    await expect(page.locator('[data-testid="fencer-left-score"]')).toContainText(leftScore);
    await expect(page.locator('[data-testid="fencer-right-score"]')).toContainText(rightScore);

    // Verify no touch is logged
    await expect(page.locator('[data-testid="touch-log"]')).toContainText('No Touch');
  });

  test('should pause and resume bout timer', async ({ page }) => {
    // Start the bout
    await page.click('[data-testid="start-bout-button"]');

    // Wait for timer to count down
    await page.waitForTimeout(2000);

    // Pause the bout
    await page.click('[data-testid="pause-bout-button"]');

    // Get current timer value
    const pausedTime = await page.locator('[data-testid="bout-timer"]').textContent();

    // Wait to ensure timer is paused
    await page.waitForTimeout(2000);

    // Verify timer didn't change
    await expect(page.locator('[data-testid="bout-timer"]')).toContainText(pausedTime);

    // Resume the bout
    await page.click('[data-testid="resume-bout-button"]');

    // Wait and verify timer is counting down again
    await page.waitForTimeout(2000);
    const resumedTime = await page.locator('[data-testid="bout-timer"]').textContent();
    expect(resumedTime).not.toBe(pausedTime);
  });

  test('should complete bout when target score reached', async ({ page }) => {
    // Start the bout
    await page.click('[data-testid="start-bout-button"]');

    // Score 15 touches for left fencer (target score for epee)
    for (let i = 0; i < 15; i++) {
      await page.click('[data-testid="score-left-button"]');
      await page.waitForTimeout(100); // Brief delay between touches
    }

    // Verify bout completion
    await expect(page.locator('[data-testid="bout-complete-dialog"]')).toBeVisible();
    await expect(page.locator('[data-testid="bout-winner"]')).toContainText('Test Fencer 1');
    await expect(page.locator('[data-testid="final-score"]')).toContainText('15-0');
  });

  test('should complete bout when time expires', async ({ page }) => {
    // Set up a shorter bout time for testing (simulate time expiry)
    await page.evaluate(() => {
      // Mock the timer to expire quickly
      window.boutTimer = { timeRemaining: 1000 }; // 1 second
    });

    // Start the bout
    await page.click('[data-testid="start-bout-button"]');

    // Wait for time to expire
    await page.waitForTimeout(2000);

    // Verify bout completion dialog appears
    await expect(page.locator('[data-testid="bout-complete-dialog"]')).toBeVisible();
    await expect(page.locator('[data-testid="time-expired-message"]')).toBeVisible();
  });

  test('should undo last touch correctly', async ({ page }) => {
    // Start the bout
    await page.click('[data-testid="start-bout-button"]');

    // Record a touch
    await page.click('[data-testid="score-left-button"]');

    // Verify score
    await expect(page.locator('[data-testid="fencer-left-score"]')).toContainText('1');

    // Undo the touch
    await page.click('[data-testid="undo-touch-button"]');

    // Verify score reverted
    await expect(page.locator('[data-testid="fencer-left-score"]')).toContainText('0');

    // Verify undo is logged
    await expect(page.locator('[data-testid="touch-log"]')).toContainText('Undo: Touch removed');
  });

  test('should handle yellow and red cards', async ({ page }) => {
    // Start the bout
    await page.click('[data-testid="start-bout-button"]');

    // Open penalty options
    await page.click('[data-testid="penalty-menu-button"]');

    // Give yellow card to left fencer
    await page.click('[data-testid="yellow-card-left-button"]');

    // Verify yellow card is displayed
    await expect(page.locator('[data-testid="fencer-left-penalties"]')).toContainText('Yellow');

    // Give red card to right fencer
    await page.click('[data-testid="penalty-menu-button"]');
    await page.click('[data-testid="red-card-right-button"]');

    // Verify red card and resulting touch
    await expect(page.locator('[data-testid="fencer-right-penalties"]')).toContainText('Red');
    await expect(page.locator('[data-testid="fencer-left-score"]')).toContainText('1'); // Red card gives opponent a touch
  });

  test('should display bout statistics correctly', async ({ page }) => {
    // Start the bout and record some touches
    await page.click('[data-testid="start-bout-button"]');

    await page.click('[data-testid="score-left-button"]');
    await page.click('[data-testid="score-right-button"]');
    await page.click('[data-testid="double-touch-button"]');

    // Open statistics panel
    await page.click('[data-testid="statistics-button"]');

    // Verify statistics are displayed
    await expect(page.locator('[data-testid="statistics-panel"]')).toBeVisible();
    await expect(page.locator('[data-testid="total-touches"]')).toContainText('4'); // 1+1+2 for double
    await expect(page.locator('[data-testid="bout-duration"]')).toBeVisible();
    await expect(page.locator('[data-testid="touch-rate"]')).toBeVisible();
  });

  test('should save bout results correctly', async ({ page }) => {
    // Complete a bout
    await page.click('[data-testid="start-bout-button"]');

    // Score to completion
    for (let i = 0; i < 15; i++) {
      await page.click('[data-testid="score-left-button"]');
    }

    // Wait for completion dialog
    await expect(page.locator('[data-testid="bout-complete-dialog"]')).toBeVisible();

    // Save the results
    await page.click('[data-testid="save-results-button"]');

    // Verify success message
    await expect(page.locator('[data-testid="save-success-message"]')).toBeVisible();
    await expect(page.locator('[data-testid="save-success-message"]')).toContainText('Bout results saved successfully');

    // Verify navigation back to tournament page
    await expect(page).toHaveURL(/.*\/tournaments\/.*$/);
  });

});