#!/usr/bin/env bash

# goDial Database Status Checker
# Shows current migration status and database information

set -e

echo "🔍 goDial Database Status"
echo "========================="

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

DB_PATH="${GODIAL_DB_PATH:-goDial.db}"

# Check if database file exists
if [ ! -f "$DB_PATH" ]; then
    echo -e "${RED}❌ Database file not found: $DB_PATH${NC}"
    echo -e "${YELLOW}💡 Run 'db-migrate' to create and initialize the database${NC}"
    exit 1
fi

echo -e "${BLUE}📊 Database file: $DB_PATH${NC}"

# Get database file size
DB_SIZE=$(du -h "$DB_PATH" | cut -f1)
echo -e "${BLUE}📏 Database size: $DB_SIZE${NC}"

echo ""
echo -e "${YELLOW}🔧 Migration Status:${NC}"
echo "==================="

# Show goose migration status
if goose -dir db/migrations sqlite3 "$DB_PATH" status; then
    echo ""
    echo -e "${GREEN}✅ Migration status retrieved successfully${NC}"
else
    echo -e "${RED}❌ Failed to get migration status${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}📋 Database Schema Information:${NC}"
echo "==============================="

# Show table information
sqlite3 "$DB_PATH" << EOF
.mode column
.headers on
.print "Tables in database:"
SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'goose_%' ORDER BY name;

.print ""
.print "Migration history (from goose_db_version):"
SELECT * FROM goose_db_version ORDER BY version_id;
EOF

echo ""
echo -e "${YELLOW}📊 Table Row Counts:${NC}"
echo "==================="

# Count rows in each table
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

echo ""
echo -e "${BLUE}💡 Useful commands:${NC}"
echo "  • db-migrate   - Apply pending migrations"
echo "  • db-rollback  - Rollback last migration"
echo "  • db-reset     - Reset database (DESTRUCTIVE)"
echo "  • db-backup    - Create database backup"
echo "" 