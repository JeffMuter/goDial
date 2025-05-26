#!/usr/bin/env bash

# goDial Database Backup
# Creates a timestamped backup of the database

set -e

echo "💾 goDial Database Backup"
echo "========================="

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

DB_PATH="${GODIAL_DB_PATH:-goDial.db}"
BACKUP_DIR="backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="goDial_backup_${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}.db"
COMPRESSED_PATH="${BACKUP_DIR}/${BACKUP_NAME}.db.gz"

echo -e "${BLUE}📊 Database: $DB_PATH${NC}"
echo -e "${BLUE}📁 Backup directory: $BACKUP_DIR${NC}"
echo ""

# Check if database file exists
if [ ! -f "$DB_PATH" ]; then
    echo -e "${RED}❌ Database file not found: $DB_PATH${NC}"
    echo -e "${YELLOW}💡 Run 'db-migrate' to create and initialize the database${NC}"
    exit 1
fi

# Create backup directory if it doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${YELLOW}📁 Creating backup directory: $BACKUP_DIR${NC}"
    mkdir -p "$BACKUP_DIR"
fi

# Show database info before backup
echo -e "${BLUE}📊 Database information:${NC}"
DB_SIZE=$(du -h "$DB_PATH" | cut -f1)
echo -e "${BLUE}   Size: $DB_SIZE${NC}"

# Show record counts
echo -e "${BLUE}   Records:${NC}"
sqlite3 "$DB_PATH" << EOF
.mode column
.headers off
SELECT '     users: ' || COUNT(*) FROM users;
SELECT '     calls: ' || COUNT(*) FROM calls;
SELECT '     call_logs: ' || COUNT(*) FROM call_logs;
EOF

echo ""
echo -e "${YELLOW}💾 Creating backup...${NC}"

# Create backup
if cp "$DB_PATH" "$BACKUP_PATH"; then
    echo -e "${GREEN}✅ Backup created: $BACKUP_PATH${NC}"
    
    # Compress backup
    echo -e "${YELLOW}🗜️  Compressing backup...${NC}"
    if gzip "$BACKUP_PATH"; then
        echo -e "${GREEN}✅ Backup compressed: $COMPRESSED_PATH${NC}"
        
        # Show compression stats
        ORIGINAL_SIZE=$(du -h "$DB_PATH" | cut -f1)
        COMPRESSED_SIZE=$(du -h "$COMPRESSED_PATH" | cut -f1)
        echo -e "${BLUE}   Original size: $ORIGINAL_SIZE${NC}"
        echo -e "${BLUE}   Compressed size: $COMPRESSED_SIZE${NC}"
        
        FINAL_BACKUP="$COMPRESSED_PATH"
    else
        echo -e "${YELLOW}⚠️  Compression failed, keeping uncompressed backup${NC}"
        FINAL_BACKUP="$BACKUP_PATH"
    fi
    
else
    echo -e "${RED}❌ Backup failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Backup completed successfully!${NC}"
echo -e "${BLUE}📍 Backup location: $FINAL_BACKUP${NC}"

# List recent backups
echo ""
echo -e "${YELLOW}📋 Recent backups:${NC}"
ls -lah "$BACKUP_DIR" | grep "goDial_backup" | tail -5

echo ""
echo -e "${BLUE}💡 Backup management:${NC}"
echo "  • View all backups: ls -lah $BACKUP_DIR"
echo "  • Restore backup: cp $FINAL_BACKUP.restored $DB_PATH (after gunzip if compressed)"
echo "  • Delete old backups: find $BACKUP_DIR -name '*.gz' -mtime +30 -delete"
echo ""

echo -e "${YELLOW}📚 About backups:${NC}"
echo "Backups are created with timestamps and compressed with gzip."
echo "They include the full database with all data and schema."
echo "Regular backups are recommended before migrations or major changes."
echo ""

# Optional: Clean up old backups (older than 30 days)
OLD_BACKUPS=$(find "$BACKUP_DIR" -name "goDial_backup_*.gz" -mtime +30 2>/dev/null | wc -l || echo "0")
if [ "$OLD_BACKUPS" -gt 0 ]; then
    echo -e "${YELLOW}🗑️  Found $OLD_BACKUPS old backup(s) (>30 days)${NC}"
    echo "   Run this to clean them up: find $BACKUP_DIR -name 'goDial_backup_*.gz' -mtime +30 -delete"
    echo ""
fi 