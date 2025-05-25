# Testing Guide

This guide explains how to write and run tests in the goDial project.

## Overview

The project uses Go's built-in testing framework along with the Testify library for assertions and test utilities.

## Test Structure

### Current Tests

The project currently has comprehensive database tests in `internal/database/init_test.go`:

1. **TestInitDB** - Tests database initialization and schema creation
2. **TestInitDBWithExistingDatabase** - Tests idempotent database initialization  
3. **TestDatabaseOperations** - Tests CRUD operations for users and calls

### Test Organization

```
internal/
└── database/
    ├── init.go          # Database initialization code
    ├── init_test.go     # Database tests
    ├── *.sql.go         # Generated SQLC code
    └── models.go        # Generated models
```

## Running Tests

### Basic Test Commands

```bash
# Run all tests
go test ./...

# Run tests with verbose output
go test ./... -v

# Run specific package tests
go test ./internal/database

# Run specific test function
go test ./internal/database -run TestInitDB

# Run tests with coverage
go test ./... -cover

# Generate coverage report
go test ./... -coverprofile=coverage.out
go tool cover -html=coverage.out
```

### Test Output Example

```bash
$ go test ./internal/database -v
=== RUN   TestInitDB
--- PASS: TestInitDB (0.02s)
=== RUN   TestInitDBWithExistingDatabase  
--- PASS: TestInitDBWithExistingDatabase (0.01s)
=== RUN   TestDatabaseOperations
--- PASS: TestDatabaseOperations (0.02s)
PASS
ok      goDial/internal/database        0.046s
```

## Writing Database Tests

### Test Setup Pattern

```go
func TestYourFeature(t *testing.T) {
    // Create temporary directory for test database
    tempDir := t.TempDir()
    dbPath := filepath.Join(tempDir, "test.db")

    // Initialize database
    db, err := InitDB(dbPath)
    require.NoError(t, err, "Failed to initialize database")
    defer db.Close()

    ctx := context.Background()

    // Your test logic here
}
```

### Key Testing Principles

1. **Isolation** - Each test uses its own temporary database
2. **Cleanup** - Tests clean up after themselves automatically
3. **Context** - All database operations use context
4. **Assertions** - Use testify for clear assertions

### Example: Testing User Operations

```go
func TestUserCRUD(t *testing.T) {
    // Setup
    tempDir := t.TempDir()
    dbPath := filepath.Join(tempDir, "test.db")
    db, err := InitDB(dbPath)
    require.NoError(t, err)
    defer db.Close()

    ctx := context.Background()

    // Test Create
    user, err := db.CreateUser(ctx, CreateUserParams{
        Email: "test@example.com",
        Name:  "Test User",
    })
    require.NoError(t, err)
    assert.Equal(t, "test@example.com", user.Email)
    assert.Equal(t, "Test User", user.Name)
    assert.NotZero(t, user.ID)

    // Test Read
    retrievedUser, err := db.GetUser(ctx, user.ID)
    require.NoError(t, err)
    assert.Equal(t, user.ID, retrievedUser.ID)
    assert.Equal(t, user.Email, retrievedUser.Email)

    // Test Update
    updatedUser, err := db.UpdateUser(ctx, UpdateUserParams{
        ID:   user.ID,
        Name: "Updated Name",
    })
    require.NoError(t, err)
    assert.Equal(t, "Updated Name", updatedUser.Name)

    // Test Delete
    err = db.DeleteUser(ctx, user.ID)
    require.NoError(t, err)

    // Verify deletion
    _, err = db.GetUser(ctx, user.ID)
    assert.Error(t, err) // Should return error for non-existent user
}
```

### Testing Nullable Fields

```go
func TestNullableFields(t *testing.T) {
    // Setup database...

    // Test with NULL values
    call, err := db.CreateCall(ctx, CreateCallParams{
        UserID:            userID,
        PhoneNumber:       "+1234567890",
        RecipientContext:  sql.NullString{}, // NULL
        Objective:         "Test objective",
        BackgroundContext: sql.NullString{String: "Background", Valid: true},
    })
    require.NoError(t, err)

    // Test NULL field
    assert.False(t, call.RecipientContext.Valid)

    // Test non-NULL field
    assert.True(t, call.BackgroundContext.Valid)
    assert.Equal(t, "Background", call.BackgroundContext.String)
}
```

### Testing Error Cases

```go
func TestErrorCases(t *testing.T) {
    // Setup database...

    // Test duplicate email (should fail due to UNIQUE constraint)
    _, err := db.CreateUser(ctx, CreateUserParams{
        Email: "duplicate@example.com",
        Name:  "User 1",
    })
    require.NoError(t, err)

    _, err = db.CreateUser(ctx, CreateUserParams{
        Email: "duplicate@example.com", // Same email
        Name:  "User 2",
    })
    assert.Error(t, err) // Should fail

    // Test getting non-existent record
    _, err = db.GetUser(ctx, 99999)
    assert.Error(t, err) // Should return sql.ErrNoRows
}
```

## Test Utilities

### Common Test Helpers

You can create helper functions to reduce test boilerplate:

```go
// testhelpers.go
func setupTestDB(t *testing.T) (*DB, context.Context) {
    tempDir := t.TempDir()
    dbPath := filepath.Join(tempDir, "test.db")
    
    db, err := InitDB(dbPath)
    require.NoError(t, err)
    
    t.Cleanup(func() {
        db.Close()
    })
    
    return db, context.Background()
}

func createTestUser(t *testing.T, db *DB, ctx context.Context) User {
    user, err := db.CreateUser(ctx, CreateUserParams{
        Email: fmt.Sprintf("user%d@example.com", time.Now().UnixNano()),
        Name:  "Test User",
    })
    require.NoError(t, err)
    return user
}
```

### Using Test Helpers

```go
func TestWithHelpers(t *testing.T) {
    db, ctx := setupTestDB(t)
    user := createTestUser(t, db, ctx)
    
    // Test your feature with the created user
    call, err := db.CreateCall(ctx, CreateCallParams{
        UserID:      user.ID,
        PhoneNumber: "+1234567890",
        Objective:   "Test call",
    })
    require.NoError(t, err)
    assert.Equal(t, user.ID, call.UserID)
}
```

## Test Data Management

### Generating Test Data

```go
func generateTestEmail() string {
    return fmt.Sprintf("test%d@example.com", time.Now().UnixNano())
}

func generateTestUser() CreateUserParams {
    return CreateUserParams{
        Email: generateTestEmail(),
        Name:  "Test User",
    }
}
```

### Table-Driven Tests

```go
func TestUserValidation(t *testing.T) {
    db, ctx := setupTestDB(t)

    tests := []struct {
        name      string
        params    CreateUserParams
        wantError bool
    }{
        {
            name: "valid user",
            params: CreateUserParams{
                Email: "valid@example.com",
                Name:  "Valid User",
            },
            wantError: false,
        },
        {
            name: "empty email",
            params: CreateUserParams{
                Email: "",
                Name:  "User",
            },
            wantError: true,
        },
        {
            name: "empty name",
            params: CreateUserParams{
                Email: "user@example.com",
                Name:  "",
            },
            wantError: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            _, err := db.CreateUser(ctx, tt.params)
            if tt.wantError {
                assert.Error(t, err)
            } else {
                assert.NoError(t, err)
            }
        })
    }
}
```

## Integration Tests

### Testing Database Migrations

```go
func TestMigrations(t *testing.T) {
    tempDir := t.TempDir()
    dbPath := filepath.Join(tempDir, "test.db")

    // Test that migrations run successfully
    db, err := InitDB(dbPath)
    require.NoError(t, err)
    defer db.Close()

    // Verify all expected tables exist
    tables := []string{"users", "calls", "call_logs"}
    for _, table := range tables {
        var count int
        err := db.QueryRow("SELECT COUNT(*) FROM " + table).Scan(&count)
        assert.NoError(t, err, "Table %s should exist", table)
    }
}
```

### Testing Transaction Behavior

```go
func TestTransactions(t *testing.T) {
    db, ctx := setupTestDB(t)

    // Begin transaction
    tx, err := db.BeginTx(ctx, nil)
    require.NoError(t, err)

    // Use transaction
    queries := db.WithTx(tx)
    user, err := queries.CreateUser(ctx, CreateUserParams{
        Email: "tx@example.com",
        Name:  "TX User",
    })
    require.NoError(t, err)

    // Rollback transaction
    err = tx.Rollback()
    require.NoError(t, err)

    // Verify user was not created
    _, err = db.GetUser(ctx, user.ID)
    assert.Error(t, err) // Should not exist
}
```

## Performance Testing

### Benchmarking Database Operations

```go
func BenchmarkCreateUser(b *testing.B) {
    tempDir := b.TempDir()
    dbPath := filepath.Join(tempDir, "bench.db")
    db, err := InitDB(dbPath)
    require.NoError(b, err)
    defer db.Close()

    ctx := context.Background()

    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        _, err := db.CreateUser(ctx, CreateUserParams{
            Email: fmt.Sprintf("user%d@example.com", i),
            Name:  "Bench User",
        })
        require.NoError(b, err)
    }
}
```

## Test Configuration

### Environment Variables for Tests

```go
func getTestDBPath() string {
    if path := os.Getenv("TEST_DB_PATH"); path != "" {
        return path
    }
    return ":memory:" // Use in-memory database for tests
}
```

### Test Build Tags

```go
//go:build integration
// +build integration

func TestIntegration(t *testing.T) {
    // Integration tests that require external resources
}
```

Run with: `go test -tags=integration ./...`

## Best Practices

### Test Organization

1. **One test file per source file** - `init.go` → `init_test.go`
2. **Group related tests** - Use subtests for variations
3. **Clear test names** - Describe what is being tested
4. **Setup and teardown** - Use `t.TempDir()` and `defer`

### Assertions

1. **Use require for setup** - Fail fast if setup fails
2. **Use assert for checks** - Continue testing even if assertion fails
3. **Meaningful messages** - Add context to assertions
4. **Test both success and failure** - Cover error cases

### Database Testing

1. **Isolated tests** - Each test uses its own database
2. **Test migrations** - Verify schema changes work
3. **Test constraints** - Verify foreign keys, unique constraints
4. **Test nullable fields** - Handle NULL values properly

### Performance

1. **Use in-memory databases** - For faster test execution
2. **Parallel tests** - Use `t.Parallel()` when safe
3. **Benchmark critical paths** - Measure performance of key operations
4. **Profile tests** - Use `go test -cpuprofile` for analysis

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: actions/setup-go@v3
      with:
        go-version: 1.23.3
    - run: go test ./... -v -cover
```

### Test Coverage

```bash
# Generate coverage report
go test ./... -coverprofile=coverage.out

# View coverage in terminal
go tool cover -func=coverage.out

# Generate HTML coverage report
go tool cover -html=coverage.out -o coverage.html
``` 