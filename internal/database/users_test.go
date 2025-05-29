package database

import (
	"context"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func setupUserTestDB(t *testing.T) *DB {
	tempDir := t.TempDir()
	dbPath := filepath.Join(tempDir, "user_test.db")

	db, err := InitDB(dbPath)
	require.NoError(t, err, "Failed to initialize test database")

	t.Cleanup(func() {
		db.Close()
	})

	return db
}

func TestGetUserMinutes(t *testing.T) {
	db := setupUserTestDB(t)
	ctx := context.Background()

	tests := []struct {
		name           string
		setupUser      *CreateUserParams
		queryEmail     string
		expectedResult interface{}
		expectError    bool
		description    string
	}{
		{
			name: "User exists with default minutes (0)",
			setupUser: &CreateUserParams{
				Email: "user@example.com",
				Name:  "Test User",
			},
			queryEmail:     "user@example.com",
			expectedResult: int64(0), // Default value from migration
			expectError:    false,
			description:    "Should return 0 minutes for newly created user",
		},
		{
			name:           "User does not exist",
			setupUser:      nil,
			queryEmail:     "nonexistent@example.com",
			expectedResult: nil,
			expectError:    true,
			description:    "Should return error when user doesn't exist",
		},
		{
			name: "Empty email query",
			setupUser: &CreateUserParams{
				Email: "test@example.com",
				Name:  "Test User",
			},
			queryEmail:     "",
			expectedResult: nil,
			expectError:    true,
			description:    "Should return error for empty email",
		},
		{
			name: "Case sensitive email",
			setupUser: &CreateUserParams{
				Email: "CaseTest@Example.Com",
				Name:  "Case Test User",
			},
			queryEmail:     "casetest@example.com", // Different case
			expectedResult: nil,
			expectError:    true,
			description:    "Should be case sensitive for email lookup",
		},
		{
			name: "Email with special characters",
			setupUser: &CreateUserParams{
				Email: "user+test@example-domain.co.uk",
				Name:  "Special Email User",
			},
			queryEmail:     "user+test@example-domain.co.uk",
			expectedResult: int64(0),
			expectError:    false,
			description:    "Should handle emails with special characters",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Setup: Create user if specified
			if tt.setupUser != nil {
				_, err := db.CreateUser(ctx, *tt.setupUser)
				require.NoError(t, err, "Failed to create test user")
			}

			// Execute: Get user minutes
			result, err := db.GetUserMinutes(ctx, tt.queryEmail)

			// Assert: Check results
			if tt.expectError {
				assert.Error(t, err, tt.description)
				assert.Nil(t, result, "Result should be nil when error occurs")
			} else {
				assert.NoError(t, err, tt.description)
				assert.Equal(t, tt.expectedResult, result, tt.description)
			}
		})
	}
}

func TestGetUserMinutesWithManuallySetMinutes(t *testing.T) {
	db := setupUserTestDB(t)
	ctx := context.Background()

	// Create a user first
	user, err := db.CreateUser(ctx, CreateUserParams{
		Email: "minutes-test@example.com",
		Name:  "Minutes Test User",
	})
	require.NoError(t, err, "Failed to create test user")

	// Manually update the user's minutes using raw SQL
	// (since there's no UpdateUserMinutes function in the current schema)
	testCases := []struct {
		name           string
		minutesToSet   int64
		expectedResult int64
		description    string
	}{
		{
			name:           "User with positive minutes",
			minutesToSet:   100,
			expectedResult: 100,
			description:    "Should return correct positive minutes",
		},
		{
			name:           "User with zero minutes",
			minutesToSet:   0,
			expectedResult: 0,
			description:    "Should return zero minutes",
		},
		{
			name:           "User with large number of minutes",
			minutesToSet:   999999,
			expectedResult: 999999,
			description:    "Should handle large minute values",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Update minutes directly in database
			_, err := db.db.ExecContext(ctx, "UPDATE users SET minutes = ? WHERE id = ?", tc.minutesToSet, user.ID)
			require.NoError(t, err, "Failed to update user minutes")

			// Test GetUserMinutes
			result, err := db.GetUserMinutes(ctx, user.Email)
			assert.NoError(t, err, tc.description)
			assert.Equal(t, tc.expectedResult, result, tc.description)
		})
	}
}

func TestGetUserMinutesConcurrency(t *testing.T) {
	db := setupUserTestDB(t)
	ctx := context.Background()

	// Create test user
	user, err := db.CreateUser(ctx, CreateUserParams{
		Email: "concurrent@example.com",
		Name:  "Concurrent Test User",
	})
	require.NoError(t, err, "Failed to create test user")

	// Test concurrent access
	const numGoroutines = 10
	results := make(chan interface{}, numGoroutines)
	errors := make(chan error, numGoroutines)

	for i := 0; i < numGoroutines; i++ {
		go func() {
			result, err := db.GetUserMinutes(ctx, user.Email)
			results <- result
			errors <- err
		}()
	}

	// Collect results
	for i := 0; i < numGoroutines; i++ {
		result := <-results
		err := <-errors
		assert.NoError(t, err, "Concurrent access should not cause errors")
		assert.Equal(t, int64(0), result, "All concurrent calls should return same result")
	}
}

func BenchmarkGetUserMinutes(b *testing.B) {
	tempDir := b.TempDir()
	dbPath := filepath.Join(tempDir, "bench.db")

	db, err := InitDB(dbPath)
	if err != nil {
		b.Fatalf("Failed to initialize test database: %v", err)
	}
	defer db.Close()

	ctx := context.Background()

	// Create test user
	user, err := db.CreateUser(ctx, CreateUserParams{
		Email: "bench@example.com",
		Name:  "Benchmark User",
	})
	if err != nil {
		b.Fatalf("Failed to create test user: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := db.GetUserMinutes(ctx, user.Email)
		if err != nil {
			b.Fatalf("GetUserMinutes failed: %v", err)
		}
	}
}
