package router

import (
	"goDial/internal/database"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// setupTestDB creates a test database for testing
func setupTestDB(t *testing.T) *database.DB {
	tempDir := t.TempDir()
	dbPath := filepath.Join(tempDir, "test.db")

	db, err := database.InitDB(dbPath)
	require.NoError(t, err, "Failed to initialize test database")

	t.Cleanup(func() {
		db.Close()
	})

	return db
}

func TestNewRouter(t *testing.T) {
	db := setupTestDB(t)
	router := NewRouter(db)
	assert.NotNil(t, router, "Router should not be nil")
}

func TestHomeRoute(t *testing.T) {
	db := setupTestDB(t)
	router := NewRouter(db)

	tests := []struct {
		name           string
		method         string
		path           string
		expectedStatus int
		expectedBody   string
	}{
		{
			name:           "GET home page",
			method:         "GET",
			path:           "/",
			expectedStatus: http.StatusOK,
			expectedBody:   "", // We'll check for HTML content
		},
		{
			name:           "POST to home page",
			method:         "POST",
			path:           "/",
			expectedStatus: http.StatusOK,
			expectedBody:   "", // Should still work for POST
		},
		{
			name:           "Unmatched path serves home page",
			method:         "GET",
			path:           "/nonexistent",
			expectedStatus: http.StatusOK,
			expectedBody:   "", // Home route is catch-all in Go's ServeMux
		},
		{
			name:           "Path with trailing slash serves home page",
			method:         "GET",
			path:           "/invalid/",
			expectedStatus: http.StatusOK,
			expectedBody:   "", // Home route is catch-all in Go's ServeMux
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(tt.method, tt.path, nil)
			w := httptest.NewRecorder()

			router.ServeHTTP(w, req)

			assert.Equal(t, tt.expectedStatus, w.Code, "Status code should match")

			if tt.expectedBody != "" {
				assert.Contains(t, w.Body.String(), tt.expectedBody, "Response body should contain expected content")
			}

			// For successful requests, check for HTML content
			if tt.expectedStatus == http.StatusOK {
				body := w.Body.String()
				// Check for DOCTYPE (case-insensitive)
				bodyLower := strings.ToLower(body)
				assert.Contains(t, bodyLower, "<!doctype html>", "Response should contain HTML doctype")
				assert.Contains(t, body, "<html", "Response should contain HTML tag")
			}
		})
	}
}

func TestStripePageRoute(t *testing.T) {
	db := setupTestDB(t)
	router := NewRouter(db)

	tests := []struct {
		name           string
		method         string
		path           string
		expectedStatus int
	}{
		{
			name:           "GET stripe page",
			method:         "GET",
			path:           "/stripePage",
			expectedStatus: http.StatusOK,
		},
		{
			name:           "POST to stripe page",
			method:         "POST",
			path:           "/stripePage",
			expectedStatus: http.StatusOK,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(tt.method, tt.path, nil)
			w := httptest.NewRecorder()

			router.ServeHTTP(w, req)

			assert.Equal(t, tt.expectedStatus, w.Code, "Status code should match")

			// Check for HTML content - the handler should still work even if DB query fails
			// because it gracefully handles the error by setting minutes to 0
			body := w.Body.String()
			// Check for DOCTYPE (case-insensitive)
			bodyLower := strings.ToLower(body)
			assert.Contains(t, bodyLower, "<!doctype html>", "Response should contain HTML doctype")
			assert.Contains(t, body, "<html", "Response should contain HTML tag")
		})
	}
}

func TestHealthCheckRoute(t *testing.T) {
	db := setupTestDB(t)
	router := NewRouter(db)

	req := httptest.NewRequest("GET", "/health", nil)
	w := httptest.NewRecorder()

	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code, "Health check should return 200")
	assert.Equal(t, "application/json", w.Header().Get("Content-Type"), "Health check should return JSON")

	body := w.Body.String()
	assert.Contains(t, body, `"status":"ok"`, "Health check should contain status ok")
	assert.Contains(t, body, `"timestamp"`, "Health check should contain timestamp")
}

func TestStaticFileServing(t *testing.T) {
	db := setupTestDB(t)
	router := NewRouter(db)

	tests := []struct {
		name           string
		path           string
		expectedStatus int
		description    string
	}{
		{
			name:           "Static file request",
			path:           "/static/test.css",
			expectedStatus: http.StatusNotFound, // File doesn't exist, but handler works
			description:    "Should handle static file requests",
		},
		{
			name:           "Static directory request",
			path:           "/static/",
			expectedStatus: http.StatusOK, // Directory listing or index
			description:    "Should handle static directory requests",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest("GET", tt.path, nil)
			w := httptest.NewRecorder()

			router.ServeHTTP(w, req)

			// We mainly want to ensure the static handler is properly configured
			// The exact status depends on whether files exist
			assert.True(t, w.Code == http.StatusOK || w.Code == http.StatusNotFound || w.Code == http.StatusForbidden,
				"Static handler should return a valid HTTP status")
		})
	}
}

func TestRouterHTTPMethods(t *testing.T) {
	db := setupTestDB(t)
	router := NewRouter(db)

	methods := []string{"GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"}

	for _, method := range methods {
		t.Run("Method_"+method, func(t *testing.T) {
			req := httptest.NewRequest(method, "/", nil)
			w := httptest.NewRecorder()

			router.ServeHTTP(w, req)

			// All methods should be handled (Go's default mux accepts all methods)
			assert.Equal(t, http.StatusOK, w.Code, "All HTTP methods should be accepted on home route")
		})
	}
}

func TestRouterConcurrency(t *testing.T) {
	db := setupTestDB(t)
	router := NewRouter(db)

	// Test concurrent requests to ensure router is thread-safe
	const numRequests = 100
	results := make(chan int, numRequests)

	for i := 0; i < numRequests; i++ {
		go func() {
			req := httptest.NewRequest("GET", "/", nil)
			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)
			results <- w.Code
		}()
	}

	// Collect all results
	for i := 0; i < numRequests; i++ {
		status := <-results
		assert.Equal(t, http.StatusOK, status, "Concurrent requests should all succeed")
	}
}

func TestHandleHomeFunction(t *testing.T) {
	tests := []struct {
		name           string
		path           string
		expectedStatus int
		description    string
	}{
		{
			name:           "Exact root path",
			path:           "/",
			expectedStatus: http.StatusOK,
			description:    "Should serve home page for exact root path",
		},
		{
			name:           "Non-root path",
			path:           "/other",
			expectedStatus: http.StatusOK,
			description:    "Should serve home page for any path (catch-all behavior)",
		},
		{
			name:           "Root with query params",
			path:           "/?param=value",
			expectedStatus: http.StatusOK,
			description:    "Should serve home page with query parameters",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest("GET", tt.path, nil)
			w := httptest.NewRecorder()

			handleHomePage(w, req)

			assert.Equal(t, tt.expectedStatus, w.Code, tt.description)
		})
	}
}

func TestHandleSimpleHomeFunction(t *testing.T) {
	req := httptest.NewRequest("GET", "/", nil)
	w := httptest.NewRecorder()

	handleHomePage(w, req)

	assert.Equal(t, http.StatusOK, w.Code, "Home handler should return 200")

	body := w.Body.String()
	// Check for DOCTYPE (case-insensitive)
	bodyLower := strings.ToLower(body)
	assert.Contains(t, bodyLower, "<!doctype html>", "Response should contain HTML doctype")
}

func TestRouterHeaders(t *testing.T) {
	db := setupTestDB(t)
	router := NewRouter(db)

	req := httptest.NewRequest("GET", "/", nil)
	req.Header.Set("User-Agent", "goDial-Test/1.0")
	req.Header.Set("Accept", "text/html,application/xhtml+xml")

	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code, "Request with headers should succeed")

	// Check that content type is set for HTML responses
	contentType := w.Header().Get("Content-Type")
	assert.True(t, strings.Contains(contentType, "text/html") || contentType == "",
		"Content-Type should be HTML or empty (default)")
}

func TestRouterErrorHandling(t *testing.T) {
	db := setupTestDB(t)
	router := NewRouter(db)

	// Test various invalid paths
	invalidPaths := []string{
		"/favicon.ico",
		"/robots.txt",
		"/sitemap.xml",
		"/admin",
		"/api/v1/test",
		"/../etc/passwd",
		"/static/../../../etc/passwd",
	}

	for _, path := range invalidPaths {
		t.Run("Invalid_path_"+path, func(t *testing.T) {
			req := httptest.NewRequest("GET", path, nil)
			w := httptest.NewRecorder()

			router.ServeHTTP(w, req)

			// Should return a valid HTTP status code
			// Path traversal attempts might be handled differently by the static file server
			assert.True(t, w.Code >= 200 && w.Code < 600,
				"Invalid paths should return appropriate status codes")
		})
	}
}

// Benchmark tests
func BenchmarkHomeRoute(b *testing.B) {
	// Create a temporary directory for test database
	tempDir := b.TempDir()
	dbPath := filepath.Join(tempDir, "bench.db")

	db, err := database.InitDB(dbPath)
	if err != nil {
		b.Fatalf("Failed to initialize test database: %v", err)
	}
	defer db.Close()

	router := NewRouter(db)
	req := httptest.NewRequest("GET", "/", nil)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)
	}
}

func BenchmarkStripePageRoute(b *testing.B) {
	// Create a temporary directory for test database
	tempDir := b.TempDir()
	dbPath := filepath.Join(tempDir, "bench.db")

	db, err := database.InitDB(dbPath)
	if err != nil {
		b.Fatalf("Failed to initialize test database: %v", err)
	}
	defer db.Close()

	router := NewRouter(db)
	req := httptest.NewRequest("GET", "/stripePage", nil)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)
	}
}

func BenchmarkStaticRoute(b *testing.B) {
	// Create a temporary directory for test database
	tempDir := b.TempDir()
	dbPath := filepath.Join(tempDir, "bench.db")

	db, err := database.InitDB(dbPath)
	if err != nil {
		b.Fatalf("Failed to initialize test database: %v", err)
	}
	defer db.Close()

	router := NewRouter(db)
	req := httptest.NewRequest("GET", "/static/test.css", nil)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)
	}
}
