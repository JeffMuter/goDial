#!/usr/bin/env bash

# goDial Database Migration Runner
# Applies pending database migrations using Goose

set -e

echo "🔧 goDial Database Migration"
echo "============================"

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

# Check if migrations directory exists
if [ ! -d "$MIGRATIONS_DIR" ]; then
    echo -e "${RED}❌ Migrations directory not found: $MIGRATIONS_DIR${NC}"
    exit 1
fi

# List available migration files
echo -e "${YELLOW}📋 Available migrations:${NC}"
for migration in "$MIGRATIONS_DIR"/*.sql; do
    if [ -f "$migration" ]; then
        basename "$migration"
    fi
done

echo ""

# Create database file if it doesn't exist
if [ ! -f "$DB_PATH" ]; then
    echo -e "${YELLOW}📊 Creating new database file: $DB_PATH${NC}"
    touch "$DB_PATH"
fi

# Show current migration status before applying
echo -e "${BLUE}🔍 Current migration status:${NC}"
goose -dir "$MIGRATIONS_DIR" sqlite3 "$DB_PATH" status || true

echo ""
echo -e "${YELLOW}🚀 Applying migrations...${NC}"

# Apply migrations
if goose -dir "$MIGRATIONS_DIR" sqlite3 "$DB_PATH" up; then
    echo ""
    echo -e "${GREEN}✅ Migrations applied successfully!${NC}"
    
    # Show new status
    echo ""
    echo -e "${BLUE}🔍 Updated migration status:${NC}"
    goose -dir "$MIGRATIONS_DIR" sqlite3 "$DB_PATH" status
    
    # Regenerate SQL code after migrations
    echo ""
    echo -e "${YELLOW}🔧 Regenerating SQL code...${NC}"
    if command -v sqlc >/dev/null 2>&1; then
        if sqlc generate; then
            echo -e "${GREEN}✅ SQL code regenerated successfully${NC}"
        else
            echo -e "${YELLOW}⚠️  SQL code regeneration failed, but migrations completed${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  sqlc not found, skipping code generation${NC}"
    fi
    
else
    echo -e "${RED}❌ Migration failed!${NC}"
    echo ""
    echo -e "${YELLOW}💡 Troubleshooting tips:${NC}"
    echo "  • Check if migration files are valid SQL"
    echo "  • Ensure database is not locked by another process"
    echo "  • Run 'db-status' to see current state"
    echo "  • Check migration file syntax with 'goose validate'"
    exit 1
fi

echo ""
echo -e "${BLUE}💡 Next steps:${NC}"
echo "  • Run 'db-status' to verify changes"
echo "  • Run 'test' to ensure application still works"
echo "  • Run 'dev' to start development server"
echo "" 