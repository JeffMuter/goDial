# Troubleshooting Guide

This guide covers common issues you might encounter while working with goDial and their solutions.

## Database Issues

### Database File Locked

**Problem**: Error message like "database is locked" or "database file is locked"

**Causes**:
- Another process is using the database
- Previous process didn't close connection properly
- Database file permissions issue

**Solutions**:
```bash
# Check for running processes using the database
lsof goDial.db

# Kill any hanging processes
pkill -f goDial

# Remove lock file if it exists
rm -f goDial.db-journal

# Reset file permissions
chmod 644 goDial.db
```

### Migration Failures

**Problem**: Migrations fail to apply

**Common Errors**:
```
Error: failed to run migrations: no such table: goose_db_version
Error: failed to run migrations: syntax error near "AUTOINCREMENT"
```

**Solutions**:

1. **Reset database (development only)**:
```bash
rm goDial.db
go run cmd/main.go  # Recreates database with migrations
```

2. **Check migration syntax**:
```bash
# Validate migration files
goose -dir db/migrations validate
```

3. **Manual migration status check**:
```bash
goose -dir db/migrations sqlite3 goDial.db status
```

4. **Fix specific migration**:
```bash
# Roll back to specific version
goose -dir db/migrations sqlite3 goDial.db down-to 1

# Apply migrations one by one
goose -dir db/migrations sqlite3 goDial.db up-by-one
```

### Foreign Key Constraint Failures

**Problem**: Foreign key constraint violations

**Error Example**:
```
Error: FOREIGN KEY constraint failed
```

**Solutions**:

1. **Check foreign key constraints are enabled**:
```sql
PRAGMA foreign_keys;  -- Should return 1
```

2. **Verify referenced records exist**:
```sql
-- Before creating a call, ensure user exists
SELECT * FROM users WHERE id = ?;
```

3. **Check constraint definitions**:
```sql
PRAGMA foreign_key_list(calls);
```

## SQLC Issues

### Code Generation Failures

**Problem**: `sqlc generate` fails

**Common Errors**:
```
Error: query compilation failed
Error: column "xyz" doesn't exist
Error: syntax error at position X
```

**Solutions**:

1. **Check sqlc.yaml configuration**:
```yaml
version: "2"
sql:
  - engine: "sqlite"
    queries: "db/queries"
    schema: "db/schema"
    gen:
      go:
        package: "database"
        out: "internal/database"
```

2. **Validate SQL syntax**:
```bash
# Test queries manually
sqlite3 goDial.db < db/queries/users.sql
```

3. **Check schema files**:
```bash
# Ensure schema files match actual database
sqlite3 goDial.db .schema > current_schema.sql
diff current_schema.sql db/schema/001_initial.sql
```

4. **Regenerate from scratch**:
```bash
# Remove generated files
rm internal/database/*.sql.go internal/database/db.go internal/database/models.go

# Regenerate
sqlc generate
```

### Type Mismatch Errors

**Problem**: Generated code has wrong types

**Common Issues**:
- `sql.NullString` vs `string`
- `int64` vs `int`
- Missing context parameters

**Solutions**:

1. **Check query annotations**:
```sql
-- Ensure correct annotation
-- name: GetUser :one
SELECT * FROM users WHERE id = ?;
```

2. **Handle nullable fields properly**:
```go
// Use sql.NullString for nullable fields
RecipientContext: sql.NullString{String: "context", Valid: true}

// Check validity before using
if call.RecipientContext.Valid {
    fmt.Println(call.RecipientContext.String)
}
```

3. **Update function signatures**:
```go
// Ensure context is first parameter
func (q *Queries) GetUser(ctx context.Context, id int64) (User, error)
```

## Go Module Issues

### Dependency Problems

**Problem**: Module dependency errors

**Common Errors**:
```
Error: module not found
Error: version conflict
Error: checksum mismatch
```

**Solutions**:

1. **Clean module cache**:
```bash
go clean -modcache
go mod download
```

2. **Update dependencies**:
```bash
go mod tidy
go mod verify
```

3. **Fix specific dependency**:
```bash
# Update specific module
go get github.com/mattn/go-sqlite3@latest

# Use specific version
go get github.com/pressly/goose/v3@v3.17.0
```

### CGO Issues

**Problem**: CGO compilation errors with SQLite

**Error Example**:
```
Error: gcc not found
Error: sqlite3.h not found
```

**Solutions**:

1. **In nix-shell** (recommended):
```bash
nix-shell  # This provides all necessary tools
```

2. **Install build tools manually**:
```bash
# Ubuntu/Debian
sudo apt-get install build-essential

# macOS
xcode-select --install
```

3. **Use CGO_ENABLED**:
```bash
CGO_ENABLED=1 go build cmd/main.go
```

## Testing Issues

### Test Database Problems

**Problem**: Tests fail with database errors

**Common Issues**:
- Tests interfering with each other
- Database files not cleaned up
- Permission issues

**Solutions**:

1. **Use proper test isolation**:
```go
func TestExample(t *testing.T) {
    // Always use t.TempDir() for test databases
    tempDir := t.TempDir()
    dbPath := filepath.Join(tempDir, "test.db")
    // ...
}
```

2. **Check test cleanup**:
```go
func TestExample(t *testing.T) {
    db, err := InitDB(dbPath)
    require.NoError(t, err)
    defer db.Close()  // Ensure cleanup
    // ...
}
```

3. **Run tests in isolation**:
```bash
# Run tests one at a time
go test ./internal/database -count=1

# Disable test caching
go test ./... -count=1
```

### Test Timeout Issues

**Problem**: Tests hang or timeout

**Solutions**:

1. **Add timeouts to contexts**:
```go
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
```

2. **Check for deadlocks**:
```bash
# Run with race detector
go test ./... -race
```

3. **Use shorter timeouts**:
```bash
go test ./... -timeout=30s
```

## Nix Shell Issues

### Shell Environment Problems

**Problem**: Tools not available in shell

**Error Example**:
```
command not found: sqlc
command not found: goose
```

**Solutions**:

1. **Reload nix-shell**:
```bash
exit
nix-shell
```

2. **Check shell.nix**:
```nix
buildInputs = with pkgs; [
  go
  sqlc
  goose
  sqlite
  # ... other tools
];
```

3. **Update nixpkgs**:
```bash
nix-channel --update
nix-shell
```

### Environment Variable Issues

**Problem**: Environment variables not set correctly

**Solutions**:

1. **Check shellHook**:
```nix
shellHook = ''
  export CGO_ENABLED=1
  export GOPROXY="https://proxy.golang.org,direct"
'';
```

2. **Manual export**:
```bash
export CGO_ENABLED=1
export GOPATH=""  # Clear if set incorrectly
```

## Performance Issues

### Slow Database Operations

**Problem**: Database queries are slow

**Solutions**:

1. **Add indexes**:
```sql
-- Add index for frequently queried columns
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_calls_user_id ON calls(user_id);
CREATE INDEX idx_calls_status ON calls(status);
```

2. **Analyze query performance**:
```sql
EXPLAIN QUERY PLAN SELECT * FROM calls WHERE user_id = ?;
```

3. **Use connection pooling**:
```go
// Set connection limits
db.SetMaxOpenConns(25)
db.SetMaxIdleConns(25)
db.SetConnMaxLifetime(5 * time.Minute)
```

### Memory Issues

**Problem**: High memory usage

**Solutions**:

1. **Close database connections**:
```go
defer db.Close()
```

2. **Use context cancellation**:
```go
ctx, cancel := context.WithCancel(context.Background())
defer cancel()
```

3. **Limit query results**:
```sql
-- Add LIMIT to large queries
SELECT * FROM calls ORDER BY created_at DESC LIMIT 100;
```

## Development Workflow Issues

### File Permission Problems

**Problem**: Permission denied errors

**Solutions**:

1. **Fix file permissions**:
```bash
chmod 644 goDial.db
chmod 755 bin/
```

2. **Check directory permissions**:
```bash
ls -la
chmod 755 .
```

### Git Issues

**Problem**: Large files or generated code in git

**Solutions**:

1. **Update .gitignore**:
```
# Database files
*.db
*.db-journal

# Generated code (optional)
internal/database/db.go
internal/database/models.go
internal/database/*.sql.go

# Build artifacts
bin/
main
```

2. **Remove tracked files**:
```bash
git rm --cached goDial.db
git rm --cached internal/database/*.sql.go
```

## Debugging Tips

### Enable Debug Logging

1. **Database operations**:
```go
// Add logging to database operations
log.Printf("Executing query: %s", query)
```

2. **SQL query logging**:
```go
// Use database/sql logging
db.SetConnMaxLifetime(time.Hour)
```

### Use Development Tools

1. **SQLite browser**:
```bash
# Install SQLite browser for GUI inspection
sqlite3 goDial.db
```

2. **Go debugging**:
```bash
# Use delve debugger
go install github.com/go-delve/delve/cmd/dlv@latest
dlv debug cmd/main.go
```

### Check System Resources

1. **Disk space**:
```bash
df -h
```

2. **Memory usage**:
```bash
free -h
top
```

3. **File descriptors**:
```bash
lsof | wc -l
ulimit -n
```

## Getting Help

### Log Collection

When reporting issues, include:

1. **Error messages** (full stack trace)
2. **Environment info**:
```bash
go version
sqlite3 --version
uname -a
```

3. **Database schema**:
```bash
sqlite3 goDial.db .schema > schema.sql
```

4. **Migration status**:
```bash
goose -dir db/migrations sqlite3 goDial.db status
```

### Useful Commands for Diagnosis

```bash
# Check database integrity
sqlite3 goDial.db "PRAGMA integrity_check;"

# Check foreign key violations
sqlite3 goDial.db "PRAGMA foreign_key_check;"

# Show database info
sqlite3 goDial.db ".dbinfo"

# Show table info
sqlite3 goDial.db ".schema users"

# Check Go module status
go mod graph
go mod why github.com/mattn/go-sqlite3
``` 