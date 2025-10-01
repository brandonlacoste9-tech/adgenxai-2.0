import { test, expect } from '@playwright/test';

/**
 * UI smoke tests for AdGenXAI
 * Tests the /dashboard route and footer GitHub link
 */

test.describe('AdGenXAI UI Smoke Tests', () => {
  test('should load the dashboard route', async ({ page }) => {
    await page.goto('/dashboard');
    
    // Check that the dashboard heading is visible
    const heading = page.getByRole('heading', { name: /AdGenXAI 2\.0 Dashboard/i });
    await expect(heading).toBeVisible();
    
    // Check that welcome message is present
    await expect(page.getByText(/Welcome to the AdGenXAI Dashboard/i)).toBeVisible();
  });

  test('should have a working GitHub link in the footer', async ({ page }) => {
    await page.goto('/dashboard');
    
    // Find the GitHub link in the footer
    const githubLink = page.getByRole('link', { name: /View on GitHub/i });
    await expect(githubLink).toBeVisible();
    
    // Verify the link points to the correct repository
    await expect(githubLink).toHaveAttribute(
      'href', 
      'https://github.com/brandonlacoste9-tech/adgenxai-2.0'
    );
    
    // Verify link opens in new tab
    await expect(githubLink).toHaveAttribute('target', '_blank');
  });

  test('should load the root route', async ({ page }) => {
    await page.goto('/');
    
    // Root should also show the dashboard
    const heading = page.getByRole('heading', { name: /AdGenXAI 2\.0 Dashboard/i });
    await expect(heading).toBeVisible();
  });
});
