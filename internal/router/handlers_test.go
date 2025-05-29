package router

import (
	"context"
	"fmt"
	"goDial/internal/database"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Test configuration for handleStripePage
type stripePageTestConfig struct {
	testEmail        string
	expectedMinutes  int
	shouldCreateUser bool
	userMinutesToSet *int64
	description      string
}

// Helper function to setup test database with optional user data
func setupHandlerTestDB(t *testing.T, config *stripePageTestConfig) *database.DB {
	tempDir := t.TempDir()
	dbPath := filepath.Join(tempDir, "handler_test.db")

	db, err := database.InitDB(dbPath)
	require.NoError(t, err, "Failed to initialize test database")

	t.Cleanup(func() {
		db.Close()
	})

	// Create user if specified in config
	if config != nil && config.shouldCreateUser {
		ctx := context.Background()
		user, err := db.CreateUser(ctx, database.CreateUserParams{
			Email: config.testEmail,
			Name:  "Test User",
		})
		require.NoError(t, err, "Failed to create test user")

		// Set specific minutes if provided
		if config.userMinutesToSet != nil {
			_, err := db.ExecContext(ctx, "UPDATE users SET minutes = ? WHERE id = ?", *config.userMinutesToSet, user.ID)
			require.NoError(t, err, "Failed to update user minutes")
		}
	}

	return db
}

// Helper function to extract minutes from HTML response
func extractMinutesFromHTML(htmlContent string) (string, bool) {
	// Look for the minutes value in the HTML
	// This is flexible and can be adjusted if the HTML structure changes
	patterns := []string{
		`<div class="stat-value text-primary">`,
		`"Minutes Remaining"`,
		`fmt.Sprint(userMinutes)`,
	}

	for _, pattern := range patterns {
		if strings.Contains(htmlContent, pattern) {
			// Find the actual number after the pattern
			start := strings.Index(htmlContent, pattern)
			if start != -1 {
				// Look for numbers after this pattern
				remaining := htmlContent[start:]
				// This is a simple extraction - can be made more sophisticated
				for i, char := range remaining {
					if char >= '0' && char <= '9' {
						// Found start of number, extract it
						numStart := start + i
						numEnd := numStart
						for numEnd < len(htmlContent) && htmlContent[numEnd] >= '0' && htmlContent[numEnd] <= '9' {
							numEnd++
						}
						if numEnd > numStart {
							return htmlContent[numStart:numEnd], true
						}
					}
				}
			}
		}
	}
	return "", false
}

func TestHandleStripePage(t *testing.T) {
	tests := []struct {
		name   string
		config *stripePageTestConfig
		method string
	}{
		{
			name: "User exists with default minutes (0)",
			config: &stripePageTestConfig{
				testEmail:        "test@test.com",
				expectedMinutes:  0,
				shouldCreateUser: true,
				userMinutesToSet: nil, // Use default (0)
				description:      "Should display 0 minutes for new user",
			},
			method: "GET",
		},
		{
			name: "User exists with positive minutes",
			config: &stripePageTestConfig{
				testEmail:        "test@test.com",
				expectedMinutes:  150,
				shouldCreateUser: true,
				userMinutesToSet: func() *int64 { v := int64(150); return &v }(),
				description:      "Should display correct positive minutes",
			},
			method: "GET",
		},
		{
			name: "User exists with large number of minutes",
			config: &stripePageTestConfig{
				testEmail:        "test@test.com",
				expectedMinutes:  999999,
				shouldCreateUser: true,
				userMinutesToSet: func() *int64 { v := int64(999999); return &v }(),
				description:      "Should handle large minute values",
			},
			method: "GET",
		},
		{
			name: "User does not exist (error case)",
			config: &stripePageTestConfig{
				testEmail:        "test@test.com",
				expectedMinutes:  0, // Should default to 0 on error
				shouldCreateUser: false,
				userMinutesToSet: nil,
				description:      "Should default to 0 minutes when user not found",
			},
			method: "GET",
		},
		{
			name: "POST request with user data",
			config: &stripePageTestConfig{
				testEmail:        "test@test.com",
				expectedMinutes:  50,
				shouldCreateUser: true,
				userMinutesToSet: func() *int64 { v := int64(50); return &v }(),
				description:      "Should handle POST requests correctly",
			},
			method: "POST",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Setup
			db := setupHandlerTestDB(t, tt.config)
			handler := handleStripePage(db)

			// Create request
			req := httptest.NewRequest(tt.method, "/stripePage", nil)
			w := httptest.NewRecorder()

			// Execute
			handler.ServeHTTP(w, req)

			// Assert basic response properties
			assert.Equal(t, http.StatusOK, w.Code, "Handler should return 200 OK")

			body := w.Body.String()
			assert.NotEmpty(t, body, "Response body should not be empty")

			// Check for HTML structure
			bodyLower := strings.ToLower(body)
			assert.Contains(t, bodyLower, "<!doctype html>", "Response should contain HTML doctype")
			assert.Contains(t, body, "<html", "Response should contain HTML tag")

			// Check for stripe-specific content
			assert.Contains(t, body, "Stripe", "Response should contain Stripe content")
			assert.Contains(t, body, "Minutes Remaining", "Response should contain minutes display")
			assert.Contains(t, body, "Purchase Minutes", "Response should contain purchase form")

			// Verify minutes are displayed correctly
			expectedMinutesStr := fmt.Sprintf("%d", tt.config.expectedMinutes)
			assert.Contains(t, body, expectedMinutesStr,
				"Response should contain expected minutes value: %s", tt.config.description)
		})
	}
}

func TestHandleStripePageErrorHandling(t *testing.T) {
	// Test with a database that will be closed to simulate DB errors
	tempDir := t.TempDir()
	dbPath := filepath.Join(tempDir, "error_test.db")

	db, err := database.InitDB(dbPath)
	require.NoError(t, err, "Failed to initialize test database")

	// Close the database to simulate connection errors
	db.Close()

	handler := handleStripePage(db)
	req := httptest.NewRequest("GET", "/stripePage", nil)
	w := httptest.NewRecorder()

	// Execute
	handler.ServeHTTP(w, req)

	// Should still return 200 OK due to graceful error handling
	assert.Equal(t, http.StatusOK, w.Code, "Handler should gracefully handle DB errors")

	body := w.Body.String()
	assert.NotEmpty(t, body, "Response body should not be empty even on DB error")

	// Should default to 0 minutes
	assert.Contains(t, body, "0", "Should default to 0 minutes on error")
}

func TestHandleStripePageConcurrency(t *testing.T) {
	config := &stripePageTestConfig{
		testEmail:        "test@test.com",
		expectedMinutes:  100,
		shouldCreateUser: true,
		userMinutesToSet: func() *int64 { v := int64(100); return &v }(),
		description:      "Concurrent access test",
	}

	db := setupHandlerTestDB(t, config)
	handler := handleStripePage(db)

	const numRequests = 10
	results := make(chan int, numRequests)

	// Execute concurrent requests
	for i := 0; i < numRequests; i++ {
		go func() {
			req := httptest.NewRequest("GET", "/stripePage", nil)
			w := httptest.NewRecorder()
			handler.ServeHTTP(w, req)
			results <- w.Code
		}()
	}

	// Collect results
	for i := 0; i < numRequests; i++ {
		statusCode := <-results
		assert.Equal(t, http.StatusOK, statusCode, "All concurrent requests should succeed")
	}
}

// Test helper functions for future extensibility
func TestHandleStripePageHelpers(t *testing.T) {
	t.Run("extractMinutesFromHTML", func(t *testing.T) {
		testHTML := `<div class="stat-value text-primary">150</div>`
		minutes, found := extractMinutesFromHTML(testHTML)
		assert.True(t, found, "Should find minutes in HTML")
		assert.Equal(t, "150", minutes, "Should extract correct minutes value")
	})

	t.Run("extractMinutesFromHTML_not_found", func(t *testing.T) {
		testHTML := `<div>No minutes here</div>`
		_, found := extractMinutesFromHTML(testHTML)
		assert.False(t, found, "Should not find minutes in HTML without proper structure")
	})
}

// Benchmark test for performance monitoring
func BenchmarkHandleStripePage(b *testing.B) {
	tempDir := b.TempDir()
	dbPath := filepath.Join(tempDir, "bench.db")

	db, err := database.InitDB(dbPath)
	if err != nil {
		b.Fatalf("Failed to initialize test database: %v", err)
	}
	defer db.Close()

	// Create test user
	ctx := context.Background()
	_, err = db.CreateUser(ctx, database.CreateUserParams{
		Email: "test@test.com",
		Name:  "Benchmark User",
	})
	if err != nil {
		b.Fatalf("Failed to create test user: %v", err)
	}

	handler := handleStripePage(db)
	req := httptest.NewRequest("GET", "/stripePage", nil)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		w := httptest.NewRecorder()
		handler.ServeHTTP(w, req)
		if w.Code != http.StatusOK {
			b.Fatalf("Handler returned non-200 status: %d", w.Code)
		}
	}
}

// Integration test that combines database and handler testing
func TestHandleStripePageIntegration(t *testing.T) {
	config := &stripePageTestConfig{
		testEmail:        "test@test.com", // Use the hardcoded email that handleStripePage actually uses
		expectedMinutes:  250,
		shouldCreateUser: true,
		userMinutesToSet: func() *int64 { v := int64(250); return &v }(),
		description:      "Integration test with real database operations",
	}

	db := setupHandlerTestDB(t, config)

	// Verify database state first
	ctx := context.Background()
	minutes, err := db.GetUserMinutes(ctx, config.testEmail)
	require.NoError(t, err, "Database should contain test user")
	assert.Equal(t, int64(250), minutes, "Database should have correct minutes")

	// Test handler
	handler := handleStripePage(db)
	req := httptest.NewRequest("GET", "/stripePage", nil)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code, "Handler should return 200 OK")
	body := w.Body.String()
	assert.Contains(t, body, "250", "Handler should display correct minutes from database")
}

// Test for future modifications - demonstrates how to test different email sources
func TestHandleStripePageWithDifferentEmailSources(t *testing.T) {
	// This test demonstrates how the handler could be modified to get email from different sources
	// Currently it's hardcoded to "test@test.com", but this shows how to test different scenarios

	config := &stripePageTestConfig{
		testEmail:        "test@test.com", // Current hardcoded email
		expectedMinutes:  75,
		shouldCreateUser: true,
		userMinutesToSet: func() *int64 { v := int64(75); return &v }(),
		description:      "Test with current hardcoded email",
	}

	db := setupHandlerTestDB(t, config)
	handler := handleStripePage(db)

	// Test with different request contexts that could provide email in the future
	testCases := []struct {
		name        string
		setupReq    func() *http.Request
		description string
	}{
		{
			name: "Basic request",
			setupReq: func() *http.Request {
				return httptest.NewRequest("GET", "/stripePage", nil)
			},
			description: "Should work with basic request",
		},
		{
			name: "Request with headers",
			setupReq: func() *http.Request {
				req := httptest.NewRequest("GET", "/stripePage", nil)
				req.Header.Set("User-Email", "future@test.com") // For future use
				return req
			},
			description: "Should work with headers (for future email extraction)",
		},
		{
			name: "Request with query params",
			setupReq: func() *http.Request {
				return httptest.NewRequest("GET", "/stripePage?email=future@test.com", nil)
			},
			description: "Should work with query params (for future email extraction)",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			req := tc.setupReq()
			w := httptest.NewRecorder()

			handler.ServeHTTP(w, req)

			assert.Equal(t, http.StatusOK, w.Code, tc.description)
			body := w.Body.String()
			assert.Contains(t, body, "75", "Should display correct minutes regardless of request format")
		})
	}
}
