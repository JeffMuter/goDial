# Development Workflow

This guide covers the day-to-day development workflow for the goDial project.

## Daily Development Setup

### 1. Start Development Environment
```bash
# Enter the nix shell (this sets up all tools)
nix-shell

# You'll see the welcome message with available commands
```

### 2. Verify Everything Works
```bash
# Run tests to ensure everything is working
go test ./...

# Run the application to verify it starts
go run cmd/main.go
```

## Common Development Tasks

### Adding a New Database Table

1. **Create Migration**
```bash
# Create a new migration file
goose -dir db/migrations create add_new_table sql
```

2. **Edit Migration File**
```sql
-- +goose Up
CREATE TABLE new_table (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- +goose Down
DROP TABLE IF EXISTS new_table;
```

3. **Apply Migration**
```bash
# Apply the migration
goose -dir db/migrations sqlite3 goDial.db up
```

4. **Add Queries**
Create `db/queries/new_table.sql`:
```sql
-- name: CreateNewRecord :one
INSERT INTO new_table (name)
VALUES (?)
RETURNING *;

-- name: GetNewRecord :one
SELECT * FROM new_table
WHERE id = ?;

-- name: ListNewRecords :many
SELECT * FROM new_table
ORDER BY created_at DESC;
```

5. **Generate Go Code**
```bash
sqlc generate
```

6. **Use in Application**
```go
// Now you can use the generated functions
record, err := db.CreateNewRecord(ctx, "Record Name")
```

### Modifying Existing Tables

1. **Create Migration for Changes**
```bash
goose -dir db/migrations create add_column_to_users sql
```

2. **Add Column**
```sql
-- +goose Up
ALTER TABLE users ADD COLUMN phone TEXT;

-- +goose Down
ALTER TABLE users DROP COLUMN phone;
```

3. **Update Queries (if needed)**
Add new queries or modify existing ones in `db/queries/users.sql`

4. **Regenerate Code**
```bash
sqlc generate
```

### Adding New Features

1. **Plan Database Changes**
   - What tables/columns do you need?
   - What queries will you need?

2. **Create Migrations**
   - One migration per logical change
   - Test both up and down migrations

3. **Write Queries**
   - Add SQL queries for your feature
   - Use descriptive names

4. **Generate Code**
   ```bash
   sqlc generate
   ```

5. **Implement Feature**
   - Use generated database functions
   - Write tests for your feature

6. **Test Everything**
   ```bash
   go test ./...
   ```

## Testing Workflow

### Running Tests

```bash
# Run all tests
go test ./...

# Run tests with verbose output
go test ./... -v

# Run specific package tests
go test ./internal/database -v

# Run specific test function
go test ./internal/database -run TestInitDB -v
```

### Writing Tests

1. **Database Tests**
   - Use temporary databases
   - Test database operations
   - Clean up properly

2. **Example Test Structure**
```go
func TestNewFeature(t *testing.T) {
    // Setup
    tempDir := t.TempDir()
    dbPath := filepath.Join(tempDir, "test.db")
    db, err := InitDB(dbPath)
    require.NoError(t, err)
    defer db.Close()

    ctx := context.Background()

    // Test your feature
    result, err := db.YourNewFunction(ctx, params)
    require.NoError(t, err)
    assert.Equal(t, expected, result)
}
```

## Code Organization

### Directory Structure
```
internal/
├── database/           # Database layer
│   ├── init.go        # Database initialization
│   ├── init_test.go   # Database tests
│   └── *.sql.go       # Generated SQLC code
├── web/               # Web handlers (future)
├── call/              # Call logic (future)
└── auth/              # Authentication (future)
```

### Best Practices

1. **Keep database logic in `internal/database/`**
2. **Use generated types and functions**
3. **Handle errors appropriately**
4. **Use context for cancellation**
5. **Write tests for new features**

## Git Workflow

### Typical Workflow

1. **Create Feature Branch**
```bash
git checkout -b feature/new-feature
```

2. **Make Changes**
   - Create migrations
   - Add queries
   - Generate code
   - Implement feature
   - Write tests

3. **Test Changes**
```bash
go test ./...
```

4. **Commit Changes**
```bash
git add .
git commit -m "Add new feature with database support"
```

5. **Push and Create PR**
```bash
git push origin feature/new-feature
```

### What to Commit

**DO commit:**
- Migration files (`db/migrations/`)
- Query files (`db/queries/`)
- Application code
- Tests
- Documentation updates

**DON'T commit:**
- Generated SQLC code (`internal/database/*.sql.go`)
- Database files (`*.db`)
- Temporary files

### .gitignore Recommendations
```
# Database files
*.db
*.db-journal

# Generated code (optional - some teams commit this)
internal/database/db.go
internal/database/models.go
internal/database/*.sql.go

# Build artifacts
bin/
main
```

## Debugging

### Database Issues

1. **Check Migration Status**
```bash
goose -dir db/migrations sqlite3 goDial.db status
```

2. **Inspect Database**
```bash
sqlite3 goDial.db
.tables
.schema table_name
```

3. **Reset Database (Development Only)**
```bash
rm goDial.db
go run cmd/main.go  # This will recreate and migrate
```

### SQLC Issues

1. **Regenerate Code**
```bash
sqlc generate
```

2. **Check Configuration**
   - Verify `sqlc.yaml` settings
   - Check query syntax
   - Ensure schema files are correct

3. **Common Errors**
   - Missing context parameter
   - Wrong parameter types
   - Invalid SQL syntax

### Application Issues

1. **Check Logs**
   - Database initialization logs
   - Migration logs
   - Application logs

2. **Verify Dependencies**
```bash
go mod tidy
go mod verify
```

## Performance Tips

### Database Performance

1. **Use Indexes**
   - Add indexes for frequently queried columns
   - Include indexes in migrations

2. **Optimize Queries**
   - Use EXPLAIN QUERY PLAN
   - Avoid N+1 queries
   - Use appropriate JOINs

3. **Connection Management**
   - Reuse database connections
   - Use connection pooling for high load

### Development Performance

1. **Fast Feedback Loop**
   - Use `go run` for quick testing
   - Run specific tests during development
   - Use build tags for different environments

2. **Efficient Regeneration**
   - Only regenerate SQLC when queries change
   - Use file watchers for automatic regeneration

## Environment Management

### Development Environment
- Uses `nix-shell` for consistent tooling
- SQLite database file in project root
- All tools available in PATH

### Testing Environment
- Temporary databases for each test
- Isolated test data
- Fast test execution

### Production Considerations
- Database backup strategy
- Migration rollback plan
- Monitoring and logging
- Performance optimization 