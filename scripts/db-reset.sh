#!/usr/bin/env bash

# goDial Database Reset (DESTRUCTIVE)
# Completely resets the database by removing it and reapplying all migrations

set -e

echo "💥 goDial Database Reset (DESTRUCTIVE)"
echo "======================================"

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

DB_PATH="${GODIAL_DB_PATH:-goDial.db}"
BACKUP_PATH="${DB_PATH}.backup.$(date +%Y%m%d_%H%M%S)"

echo -e "${BLUE}📊 Database: $DB_PATH${NC}"
echo ""

echo -e "${RED}⚠️  DANGER: This will completely delete and recreate the database!${NC}"
echo -e "${RED}⚠️  ALL DATA WILL BE LOST!${NC}"
echo -e "${YELLOW}⚠️  This action cannot be undone!${NC}"
echo ""

# Check if database exists
if [ -f "$DB_PATH" ]; then
    echo -e "${BLUE}📊 Current database size: $(du -h "$DB_PATH" | cut -f1)${NC}"
    
    # Show current data
    echo ""
    echo -e "${YELLOW}📊 Current data summary:${NC}"
    sqlite3 "$DB_PATH" << EOF
.mode column
.headers on
SELECT 
    'users' as table_name,
    COUNT(*) as row_count
FROM users
UNION ALL
SELECT 
    'calls' as table_name,
    COUNT(*) as row_count  
FROM calls
UNION ALL
SELECT 
    'call_logs' as table_name,
    COUNT(*) as row_count
FROM call_logs;
EOF
else
    echo -e "${YELLOW}📊 Database file does not exist${NC}"
fi

echo ""

# Ask for confirmation unless --yes flag is provided
if [[ "$1" != "--yes" ]]; then
    echo -e "${RED}Type 'DELETE ALL DATA' to confirm database reset:${NC}"
    read -r confirmation
    if [[ "$confirmation" != "DELETE ALL DATA" ]]; then
        echo -e "${YELLOW}🛑 Database reset cancelled${NC}"
        exit 0
    fi
fi

# Create backup if database exists
if [ -f "$DB_PATH" ]; then
    echo ""
    echo -e "${YELLOW}💾 Creating backup: $BACKUP_PATH${NC}"
    cp "$DB_PATH" "$BACKUP_PATH"
    echo -e "${GREEN}✅ Backup created successfully${NC}"
fi

# Remove existing database
echo ""
echo -e "${YELLOW}🗑️  Removing existing database...${NC}"
rm -f "$DB_PATH"

# Create new database and apply migrations
echo -e "${YELLOW}📊 Creating new database...${NC}"
touch "$DB_PATH"

echo -e "${YELLOW}🔧 Applying all migrations...${NC}"
if ./scripts/db-migrate.sh; then
    echo ""
    echo -e "${GREEN}✅ Database reset completed successfully!${NC}"
    
    # Show final status
    echo ""
    echo -e "${BLUE}🔍 New database status:${NC}"
    ./scripts/db-status.sh
    
else
    echo ""
    echo -e "${RED}❌ Database reset failed during migration!${NC}"
    
    # Restore backup if it exists
    if [ -f "$BACKUP_PATH" ]; then
        echo -e "${YELLOW}♻️  Attempting to restore backup...${NC}"
        cp "$BACKUP_PATH" "$DB_PATH"
        echo -e "${GREEN}✅ Backup restored${NC}"
    fi
    
    exit 1
fi

echo ""
echo -e "${BLUE}💡 What happened:${NC}"
echo "  • Old database was backed up to: $BACKUP_PATH"
echo "  • New database was created with fresh schema"
echo "  • All migrations were applied from scratch"
echo "  • SQLC code was regenerated"
echo ""

echo -e "${YELLOW}💡 Next steps:${NC}"
echo "  • Run 'db-seed' to add test data (if available)"
echo "  • Run 'test' to ensure everything works"
echo "  • Run 'dev' to start development server"
echo ""

echo -e "${YELLOW}🗑️  Cleanup:${NC}"
echo "  • Remove backup with: rm $BACKUP_PATH"
echo "  • Or keep it as a safety measure"
echo "" 