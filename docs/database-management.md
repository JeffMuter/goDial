# Database Management Guide

This guide explains how to work with the database stack in goDial: SQLite3, SQLC, and Goose.

## Overview

Our database stack consists of three main components:

1. **SQLite3** - The database engine (file-based, serverless)
2. **Goose** - Database migration tool (schema versioning)
3. **SQLC** - SQL-to-Go code generator (type-safe queries)

## SQLite3 Basics

### What is SQLite3?
SQLite is a file-based database that doesn't require a separate server. Perfect for development and small to medium applications.

### Database File Location
- **Development**: `goDial.db` (in project root)
- **Tests**: Temporary files in test directories

### Connecting to Database
```bash
# Using sqlite3 CLI (if available)
sqlite3 goDial.db

# View tables
.tables

# View schema
.schema

# Exit
.quit
```

## Goose Migrations

### What are Migrations?
Migrations are versioned SQL scripts that modify your database schema. They allow you to:
- Track database changes over time
- Apply changes consistently across environments
- Roll back changes if needed

### Migration Files
Located in `db/migrations/`, named with format: `001_description.sql`

### Migration Structure
```sql
-- +goose Up
-- SQL statements for applying the migration
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL
);

-- +goose Down  
-- SQL statements for rolling back the migration
DROP TABLE IF EXISTS users;
```

### Common Migration Commands

```bash
# Create a new migration
goose -dir db/migrations create add_user_table sql

# Apply all pending migrations
goose -dir db/migrations sqlite3 goDial.db up

# Apply specific number of migrations
goose -dir db/migrations sqlite3 goDial.db up-by-one

# Roll back last migration
goose -dir db/migrations sqlite3 goDial.db down

# Check migration status
goose -dir db/migrations sqlite3 goDial.db status

# Reset database (careful!)
goose -dir db/migrations sqlite3 goDial.db reset
```

### Migration Best Practices

1. **Always test migrations** - Test both up and down migrations
2. **Make migrations reversible** - Always include proper down migrations
3. **One change per migration** - Keep migrations focused and atomic
4. **Never edit existing migrations** - Create new migrations for changes
5. **Backup before major changes** - Especially in production

### Example: Adding a New Table

1. Create migration:
```bash
goose -dir db/migrations create add_call_logs sql
```

2. Edit the generated file:
```sql
-- +goose Up
CREATE TABLE call_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    call_id INTEGER NOT NULL,
    message TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (call_id) REFERENCES calls(id)
);

-- +goose Down
DROP TABLE IF EXISTS call_logs;
```

3. Apply migration:
```bash
goose -dir db/migrations sqlite3 goDial.db up
```

## SQLC Code Generation

### What is SQLC?
SQLC generates type-safe Go code from SQL queries. You write SQL, and it creates Go functions with proper types.

### Configuration
See `sqlc.yaml` for configuration. Key settings:
- **engine**: "sqlite" 
- **queries**: "db/queries" (where SQL queries are stored)
- **schema**: "db/schema" (database schema files)
- **out**: "internal/database" (where Go code is generated)

### Writing Queries

Queries go in `db/queries/` directory, organized by table:

**Example: `db/queries/users.sql`**
```sql
-- name: CreateUser :one
INSERT INTO users (email, name)
VALUES (?, ?)
RETURNING *;

-- name: GetUser :one
SELECT * FROM users
WHERE id = ?;

-- name: ListUsers :many
SELECT * FROM users
ORDER BY created_at DESC;

-- name: UpdateUser :one
UPDATE users
SET name = ?, updated_at = CURRENT_TIMESTAMP
WHERE id = ?
RETURNING *;

-- name: DeleteUser :exec
DELETE FROM users
WHERE id = ?;
```

### Query Annotations

- `:one` - Returns single row
- `:many` - Returns multiple rows  
- `:exec` - Executes without returning data
- `:execrows` - Returns number of affected rows

### Parameter Types

SQLC automatically infers types, but you can be explicit:

```sql
-- name: CreateUserWithParams :one
INSERT INTO users (email, name, age)
VALUES (?, ?, ?)
RETURNING *;
```

This generates:
```go
type CreateUserWithParamsParams struct {
    Email string
    Name  string
    Age   int64
}

func (q *Queries) CreateUserWithParams(ctx context.Context, arg CreateUserWithParamsParams) (User, error)
```

### Generating Code

```bash
# Generate Go code from SQL queries
sqlc generate

# This creates files in internal/database/:
# - db.go (base types and interfaces)
# - models.go (struct definitions)
# - users.sql.go (user query functions)
# - calls.sql.go (call query functions)
```

### Using Generated Code

```go
// Initialize database
db, err := database.InitDB("goDial.db")
if err != nil {
    log.Fatal(err)
}
defer db.Close()

ctx := context.Background()

// Create a user
user, err := db.CreateUser(ctx, database.CreateUserParams{
    Email: "user@example.com",
    Name:  "John Doe",
})

// Get a user
user, err := db.GetUser(ctx, userID)

// List users
users, err := db.ListUsers(ctx)
```

## Database Schema Management

### Schema Files
Keep your schema documented in `db/schema/` for reference:

```sql
-- db/schema/001_initial.sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Schema Evolution

1. **Create migration** for schema changes
2. **Update schema file** to reflect current state
3. **Add/update queries** in `db/queries/`
4. **Regenerate code** with `sqlc generate`
5. **Update application code** to use new types/functions

## Working with Nullable Fields

SQLite allows NULL values, which SQLC handles with `sql.NullString`, `sql.NullInt64`, etc:

```go
// Creating with nullable field
call, err := db.CreateCall(ctx, database.CreateCallParams{
    UserID:           userID,
    PhoneNumber:      "+1234567890",
    RecipientContext: sql.NullString{String: "Context", Valid: true},
    Objective:        "Call objective",
    BackgroundContext: sql.NullString{}, // NULL value
})

// Checking nullable field
if call.RecipientContext.Valid {
    fmt.Println("Context:", call.RecipientContext.String)
} else {
    fmt.Println("No context provided")
}
```

## Database Initialization

The database is automatically initialized when the application starts:

1. **Connection** - Opens SQLite database file
2. **Migration** - Runs any pending Goose migrations
3. **Ready** - Database is ready for use

This happens in `internal/database/init.go` and is called from `cmd/main.go`.

## Best Practices

### Migrations
- Keep migrations small and focused
- Test both up and down migrations
- Never edit existing migrations
- Use descriptive names

### Queries
- Use meaningful query names
- Group related queries in same file
- Use proper parameter binding (?)
- Handle nullable fields appropriately

### Code Organization
- Keep database logic in `internal/database/`
- Use the generated types and functions
- Handle errors appropriately
- Use context for cancellation

### Testing
- Use temporary databases for tests
- Test database operations thoroughly
- Clean up test data properly 