#!/usr/bin/env bash

# goDial Cleanup Script
# Removes build artifacts, temporary files, and caches

echo "🧹 goDial Cleanup"
echo "=================="

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Cleaning up project artifacts...${NC}"
echo ""

# Clean Go build cache
echo -e "${YELLOW}🗑️  Cleaning Go build cache...${NC}"
go clean -cache
go clean -testcache
go clean -modcache 2>/dev/null || echo "  (module cache requires sudo, skipping)"
echo -e "${GREEN}✅ Go caches cleaned${NC}"

# Clean build artifacts
echo ""
echo -e "${YELLOW}🗑️  Cleaning build artifacts...${NC}"
rm -rf bin/
rm -rf dist/
rm -f goDial
echo -e "${GREEN}✅ Build artifacts cleaned${NC}"

# Clean test artifacts
echo ""
echo -e "${YELLOW}🗑️  Cleaning test artifacts...${NC}"
rm -rf coverage/
rm -f *.out
rm -f *.prof
echo -e "${GREEN}✅ Test artifacts cleaned${NC}"

# Clean temporary files
echo ""
echo -e "${YELLOW}🗑️  Cleaning temporary files...${NC}"
find . -name "*.tmp" -type f -delete 2>/dev/null || true
find . -name "*.temp" -type f -delete 2>/dev/null || true
find . -name ".DS_Store" -type f -delete 2>/dev/null || true
find . -name "Thumbs.db" -type f -delete 2>/dev/null || true
rm -f /tmp/godial_*
echo -e "${GREEN}✅ Temporary files cleaned${NC}"

# Clean generated files (optional)
if [[ "$1" == "--generated" ]]; then
    echo ""
    echo -e "${YELLOW}🗑️  Cleaning generated files...${NC}"
    find . -name "*_templ.go" -type f -delete 2>/dev/null || true
    rm -rf internal/database/db.go internal/database/models.go internal/database/querier.go 2>/dev/null || true
    echo -e "${GREEN}✅ Generated files cleaned${NC}"
    echo -e "${YELLOW}💡 Run 'generate' to recreate generated files${NC}"
fi

# Clean node modules and npm cache (if exists)
if [ -d "node_modules" ]; then
    echo ""
    echo -e "${YELLOW}🗑️  Cleaning Node.js artifacts...${NC}"
    rm -rf node_modules/
    npm cache clean --force 2>/dev/null || true
    echo -e "${GREEN}✅ Node.js artifacts cleaned${NC}"
    echo -e "${YELLOW}💡 Run 'npm install' to reinstall dependencies${NC}"
fi

# Clean old backups (older than 30 days)
if [ -d "backups" ]; then
    echo ""
    echo -e "${YELLOW}🗑️  Cleaning old backups...${NC}"
    OLD_BACKUPS=$(find backups/ -name "*.gz" -mtime +30 2>/dev/null | wc -l || echo "0")
    if [ "$OLD_BACKUPS" -gt 0 ]; then
        find backups/ -name "*.gz" -mtime +30 -delete 2>/dev/null || true
        echo -e "${GREEN}✅ Removed $OLD_BACKUPS old backup(s)${NC}"
    else
        echo -e "${BLUE}ℹ️  No old backups to clean${NC}"
    fi
fi

# Clean log files
echo ""
echo -e "${YELLOW}🗑️  Cleaning log files...${NC}"
find . -name "*.log" -type f -delete 2>/dev/null || true
find . -name "*.log.*" -type f -delete 2>/dev/null || true
echo -e "${GREEN}✅ Log files cleaned${NC}"

echo ""
echo -e "${GREEN}✅ Cleanup completed!${NC}"

# Show disk space saved (approximate)
echo ""
echo -e "${BLUE}💾 Cleanup summary:${NC}"
echo "  • Go build and test caches cleared"
echo "  • Build artifacts removed (bin/, dist/)"
echo "  • Test coverage files removed"
echo "  • Temporary and system files removed"
if [[ "$1" == "--generated" ]]; then
    echo "  • Generated code files removed"
fi
if [ -d "node_modules" ]; then
    echo "  • Node.js dependencies removed"
fi
echo ""

echo -e "${YELLOW}🔧 Available cleanup options:${NC}"
echo "  • clean           - Standard cleanup (safe)"
echo "  • clean --generated - Also remove generated code files"
echo ""

echo -e "${YELLOW}💡 After cleanup:${NC}"
echo "  • Run 'generate' to recreate generated files"
echo "  • Run 'npm install' to reinstall Node.js dependencies"
echo "  • Run 'build' to rebuild the application"
echo "" 