#!/usr/bin/env bash

# goDial Database Rollback
# Rolls back the last applied migration using Goose

set -e

echo "⏪ goDial Database Rollback"
echo "==========================="

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

DB_PATH="${GODIAL_DB_PATH:-goDial.db}"
MIGRATIONS_DIR="db/migrations"

echo -e "${BLUE}📊 Database: $DB_PATH${NC}"
echo -e "${BLUE}📁 Migrations: $MIGRATIONS_DIR${NC}"
echo ""

# Check if database file exists
if [ ! -f "$DB_PATH" ]; then
    echo -e "${RED}❌ Database file not found: $DB_PATH${NC}"
    echo -e "${YELLOW}💡 Run 'db-migrate' to create and initialize the database${NC}"
    exit 1
fi

# Show current migration status
echo -e "${BLUE}🔍 Current migration status:${NC}"
goose -dir "$MIGRATIONS_DIR" sqlite3 "$DB_PATH" status

echo ""
echo -e "${YELLOW}⚠️  WARNING: This will rollback the last applied migration!${NC}"
echo -e "${RED}⚠️  This operation may result in data loss!${NC}"
echo ""

# Ask for confirmation unless --yes flag is provided
if [[ "$1" != "--yes" ]]; then
    read -p "Are you sure you want to rollback the last migration? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🛑 Rollback cancelled${NC}"
        exit 0
    fi
fi

echo ""
echo -e "${YELLOW}⏪ Rolling back last migration...${NC}"

# Perform rollback
if goose -dir "$MIGRATIONS_DIR" sqlite3 "$DB_PATH" down; then
    echo ""
    echo -e "${GREEN}✅ Rollback completed successfully!${NC}"
    
    # Show new status
    echo ""
    echo -e "${BLUE}🔍 Updated migration status:${NC}"
    goose -dir "$MIGRATIONS_DIR" sqlite3 "$DB_PATH" status
    
    # Regenerate SQL code after rollback
    echo ""
    echo -e "${YELLOW}🔧 Regenerating SQL code...${NC}"
    if command -v sqlc >/dev/null 2>&1; then
        if sqlc generate; then
            echo -e "${GREEN}✅ SQL code regenerated successfully${NC}"
        else
            echo -e "${YELLOW}⚠️  SQL code regeneration failed, but rollback completed${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  sqlc not found, skipping code generation${NC}"
    fi
    
else
    echo -e "${RED}❌ Rollback failed!${NC}"
    echo ""
    echo -e "${YELLOW}💡 Troubleshooting tips:${NC}"
    echo "  • Check if there are migrations to rollback"
    echo "  • Ensure database is not locked by another process"
    echo "  • Run 'db-status' to see current state"
    echo "  • Check if the down migration in the SQL file is valid"
    exit 1
fi

echo ""
echo -e "${BLUE}💡 Next steps:${NC}"
echo "  • Run 'db-status' to verify changes"
echo "  • Run 'test' to ensure application still works"
echo "  • Consider running 'db-migrate' if you need to reapply"
echo ""

echo -e "${YELLOW}📚 About Goose Rollbacks:${NC}"
echo "Goose rollbacks execute the '-- +goose Down' section of migration files."
echo "This should contain SQL that undoes the changes in the '-- +goose Up' section."
echo "Always test rollbacks in development before using in production!"
echo "" 