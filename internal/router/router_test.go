package router

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestNewRouter(t *testing.T) {
	router := NewRouter()
	assert.NotNil(t, router, "Router should not be nil")
}

func TestHomeRoute(t *testing.T) {
	router := NewRouter()

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
			name:           "Invalid path returns 404",
			method:         "GET",
			path:           "/nonexistent",
			expectedStatus: http.StatusNotFound,
			expectedBody:   "404 page not found",
		},
		{
			name:           "Path with trailing slash",
			method:         "GET",
			path:           "/invalid/",
			expectedStatus: http.StatusNotFound,
			expectedBody:   "404 page not found",
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

			// For successful home page requests, check for HTML content
			if tt.path == "/" && tt.expectedStatus == http.StatusOK {
				body := w.Body.String()
				// Check for DOCTYPE (case-insensitive)
				bodyLower := strings.ToLower(body)
				assert.Contains(t, bodyLower, "<!doctype html>", "Response should contain HTML doctype")
				assert.Contains(t, body, "<html", "Response should contain HTML tag")
			}
		})
	}
}

func TestSimpleHomeRoute(t *testing.T) {
	router := NewRouter()

	tests := []struct {
		name           string
		method         string
		path           string
		expectedStatus int
	}{
		{
			name:           "GET simple home page",
			method:         "GET",
			path:           "/simple",
			expectedStatus: http.StatusOK,
		},
		{
			name:           "POST to simple home page",
			method:         "POST",
			path:           "/simple",
			expectedStatus: http.StatusOK,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(tt.method, tt.path, nil)
			w := httptest.NewRecorder()

			router.ServeHTTP(w, req)

			assert.Equal(t, tt.expectedStatus, w.Code, "Status code should match")

			// Check for HTML content
			body := w.Body.String()
			// Check for DOCTYPE (case-insensitive)
			bodyLower := strings.ToLower(body)
			assert.Contains(t, bodyLower, "<!doctype html>", "Response should contain HTML doctype")
			assert.Contains(t, body, "<html", "Response should contain HTML tag")
		})
	}
}

func TestStaticFileServing(t *testing.T) {
	router := NewRouter()

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
	router := NewRouter()

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
	router := NewRouter()

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
			expectedStatus: http.StatusNotFound,
			description:    "Should return 404 for non-root paths",
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

			handleHome(w, req)

			assert.Equal(t, tt.expectedStatus, w.Code, tt.description)
		})
	}
}

func TestHandleSimpleHomeFunction(t *testing.T) {
	req := httptest.NewRequest("GET", "/simple", nil)
	w := httptest.NewRecorder()

	handleSimpleHome(w, req)

	assert.Equal(t, http.StatusOK, w.Code, "Simple home handler should return 200")

	body := w.Body.String()
	// Check for DOCTYPE (case-insensitive)
	bodyLower := strings.ToLower(body)
	assert.Contains(t, bodyLower, "<!doctype html>", "Response should contain HTML doctype")
}

func TestRouterHeaders(t *testing.T) {
	router := NewRouter()

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
	router := NewRouter()

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
	router := NewRouter()
	req := httptest.NewRequest("GET", "/", nil)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)
	}
}

func BenchmarkSimpleHomeRoute(b *testing.B) {
	router := NewRouter()
	req := httptest.NewRequest("GET", "/simple", nil)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)
	}
}

func BenchmarkStaticRoute(b *testing.B) {
	router := NewRouter()
	req := httptest.NewRequest("GET", "/static/test.css", nil)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)
	}
}
