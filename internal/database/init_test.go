package database

import (
	"context"
	"database/sql"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestInitDB(t *testing.T) {
	// Create a temporary directory for test database
	tempDir := t.TempDir()
	dbPath := filepath.Join(tempDir, "test.db")

	// Initialize database
	db, err := InitDB(dbPath)
	require.NoError(t, err, "Failed to initialize database")
	defer db.Close()

	// Verify database file was created
	_, err = os.Stat(dbPath)
	assert.NoError(t, err, "Database file should exist")

	// Test database connection
	err = db.Ping()
	assert.NoError(t, err, "Database should be pingable")

	// Verify tables were created by checking if we can query them
	tables := []string{"users", "calls", "call_logs"}
	for _, table := range tables {
		var count int
		err := db.QueryRow("SELECT COUNT(*) FROM " + table).Scan(&count)
		assert.NoError(t, err, "Should be able to query table: %s", table)
		assert.Equal(t, 0, count, "Table %s should be empty initially", table)
	}
}

func TestInitDBWithExistingDatabase(t *testing.T) {
	// Create a temporary directory for test database
	tempDir := t.TempDir()
	dbPath := filepath.Join(tempDir, "test.db")

	// Initialize database first time
	db1, err := InitDB(dbPath)
	require.NoError(t, err, "Failed to initialize database first time")
	db1.Close()

	// Initialize database second time (should not fail)
	db2, err := InitDB(dbPath)
	require.NoError(t, err, "Failed to initialize existing database")
	defer db2.Close()

	// Verify database is still functional
	err = db2.Ping()
	assert.NoError(t, err, "Database should be pingable after second init")
}

func TestDatabaseOperations(t *testing.T) {
	// Create a temporary directory for test database
	tempDir := t.TempDir()
	dbPath := filepath.Join(tempDir, "test.db")

	// Initialize database
	db, err := InitDB(dbPath)
	require.NoError(t, err, "Failed to initialize database")
	defer db.Close()

	ctx := context.Background()

	// Test creating a user
	user, err := db.CreateUser(ctx, CreateUserParams{
		Email: "test@example.com",
		Name:  "Test User",
	})
	require.NoError(t, err, "Failed to create user")
	assert.Equal(t, "test@example.com", user.Email)
	assert.Equal(t, "Test User", user.Name)
	assert.NotZero(t, user.ID)

	// Test getting the user
	retrievedUser, err := db.GetUser(ctx, user.ID)
	require.NoError(t, err, "Failed to get user")
	assert.Equal(t, user.ID, retrievedUser.ID)
	assert.Equal(t, user.Email, retrievedUser.Email)
	assert.Equal(t, user.Name, retrievedUser.Name)

	// Test creating a call
	call, err := db.CreateCall(ctx, CreateCallParams{
		UserID:            user.ID,
		PhoneNumber:       "+1234567890",
		RecipientContext:  sql.NullString{String: "Test recipient", Valid: true},
		Objective:         "Test objective",
		BackgroundContext: sql.NullString{String: "Test background", Valid: true},
	})
	require.NoError(t, err, "Failed to create call")
	assert.Equal(t, user.ID, call.UserID)
	assert.Equal(t, "+1234567890", call.PhoneNumber)
	assert.Equal(t, "Test objective", call.Objective)
	assert.True(t, call.Status.Valid)
	assert.Equal(t, "pending", call.Status.String)

	// Test getting the call
	retrievedCall, err := db.GetCall(ctx, call.ID)
	require.NoError(t, err, "Failed to get call")
	assert.Equal(t, call.ID, retrievedCall.ID)
	assert.Equal(t, call.UserID, retrievedCall.UserID)
	assert.Equal(t, call.PhoneNumber, retrievedCall.PhoneNumber)
}
