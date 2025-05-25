# goDial Documentation

Welcome to the goDial project documentation! This directory contains guides to help you understand and work with the project's database stack: SQLite3, SQLC, and Goose.

## Quick Start

1. **Enter development environment:**
   ```bash
   nix-shell
   ```

2. **Run the application:**
   ```bash
   go run cmd/main.go
   ```

3. **Run tests:**
   ```bash
   go test ./...
   ```

## Documentation Index

- [**Database Management Guide**](database-management.md) - Complete guide to working with SQLite, Goose migrations, and SQLC
- [**Development Workflow**](development-workflow.md) - Day-to-day development practices
- [**Testing Guide**](testing.md) - How to write and run tests
- [**Troubleshooting**](troubleshooting.md) - Common issues and solutions

## Project Structure

```
goDial/
├── cmd/                         # Application entry points
│   └── main.go                  # Main application
├── internal/                    # Internal packages
│   └── database/                # Database layer
│       ├── init.go              # Database initialization
│       ├── init_test.go         # Database tests
│       ├── *.sql.go             # Generated SQLC code
│       └── migrations/          # Embedded migrations
├── db/                          # Database definitions
│   ├── migrations/              # Source migration files
│   ├── queries/                 # SQL queries for SQLC
│   └── schema/                  # Database schema files
├── docs/                        # This documentation
├── shell.nix                    # Nix development environment
├── sqlc.yaml                    # SQLC configuration
└── go.mod                       # Go module definition
```

## Technology Stack

- **Go 1.23.3** - Programming language
- **SQLite3** - Database engine
- **SQLC** - SQL-to-Go code generator
- **Goose** - Database migration tool
- **Nix** - Development environment management
- **Testify** - Testing framework

## Key Concepts

### Database Layer Architecture

1. **Migrations** (Goose) - Version control for database schema
2. **Queries** (SQLC) - Type-safe database operations
3. **Models** (SQLC) - Generated Go structs for database tables
4. **Initialization** - Automatic setup and migration on startup

### Development Flow

1. Write SQL migrations in `db/migrations/`
2. Write SQL queries in `db/queries/`
3. Run `sqlc generate` to create Go code
4. Use generated code in your application
5. Test everything works with `go test ./...` 