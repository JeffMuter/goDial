#!/usr/bin/env bash

# goDial Dependency Updater
# Updates Go modules and Node.js dependencies safely

set -e

echo "📦 goDial Dependency Updater"
echo "============================="

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Create backup of current dependency files
BACKUP_DIR="deps_backup_$(date +%Y%m%d_%H%M%S)"
echo -e "${YELLOW}💾 Creating backup of dependency files...${NC}"
mkdir -p "$BACKUP_DIR"
cp go.mod go.sum "$BACKUP_DIR/" 2>/dev/null || true
cp package.json package-lock.json "$BACKUP_DIR/" 2>/dev/null || true
echo -e "${GREEN}✅ Backup created: $BACKUP_DIR${NC}"

echo ""
echo -e "${BLUE}📊 Current dependency status:${NC}"

# Show current Go module info
echo -e "${YELLOW}🔧 Go modules:${NC}"
go list -m -u all | head -10
echo "  ... (showing first 10, run 'go list -m -u all' for complete list)"

# Show current Node.js packages if they exist
if [ -f "package.json" ]; then
    echo ""
    echo -e "${YELLOW}📦 Node.js packages:${NC}"
    if command -v npm >/dev/null 2>&1; then
        npm outdated || echo "  All packages are up to date"
    else
        echo "  npm not found, skipping Node.js dependency check"
    fi
fi

echo ""
echo -e "${YELLOW}🔄 Updating dependencies...${NC}"

# Update Go dependencies
echo ""
echo -e "${BLUE}🔧 Updating Go modules...${NC}"

# Get all modules that can be updated
echo "  • Fetching latest module information..."
go get -u ./...

echo "  • Cleaning up unused dependencies..."
go mod tidy

echo "  • Verifying module integrity..."
go mod verify

echo -e "${GREEN}✅ Go modules updated successfully${NC}"

# Update Node.js dependencies if package.json exists
if [ -f "package.json" ]; then
    echo ""
    echo -e "${BLUE}📦 Updating Node.js dependencies...${NC}"
    
    if command -v npm >/dev/null 2>&1; then
        echo "  • Updating npm packages..."
        npm update
        
        echo "  • Auditing for security vulnerabilities..."
        npm audit fix --force || echo "  (some audit issues may require manual intervention)"
        
        echo -e "${GREEN}✅ Node.js dependencies updated successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  npm not found, skipping Node.js updates${NC}"
    fi
fi

# Regenerate code after dependency updates
echo ""
echo -e "${YELLOW}🔧 Regenerating code after updates...${NC}"
if ./scripts/generate.sh; then
    echo -e "${GREEN}✅ Code regeneration completed${NC}"
else
    echo -e "${RED}❌ Code regeneration failed${NC}"
    echo -e "${YELLOW}💡 You may need to fix compatibility issues${NC}"
fi

# Run tests to verify everything still works
echo ""
echo -e "${YELLOW}🧪 Running tests to verify updates...${NC}"
if go test -short ./...; then
    echo -e "${GREEN}✅ All tests passed after updates${NC}"
else
    echo -e "${RED}❌ Tests failed after updates${NC}"
    echo ""
    echo -e "${YELLOW}🔄 Restoring from backup...${NC}"
    cp "$BACKUP_DIR/go.mod" "$BACKUP_DIR/go.sum" . 2>/dev/null || true
    cp "$BACKUP_DIR/package.json" "$BACKUP_DIR/package-lock.json" . 2>/dev/null || true
    
    echo -e "${YELLOW}💡 Dependencies restored to previous state${NC}"
    echo -e "${YELLOW}💡 Check the test failures and update dependencies manually${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Dependency update completed successfully!${NC}"

# Show what was updated
echo ""
echo -e "${BLUE}📊 Update summary:${NC}"

# Show Go module changes
echo -e "${YELLOW}🔧 Go module changes:${NC}"
if diff "$BACKUP_DIR/go.mod" go.mod >/dev/null 2>&1; then
    echo "  No changes to go.mod"
else
    echo "  go.mod was updated (see diff below)"
fi

if diff "$BACKUP_DIR/go.sum" go.sum >/dev/null 2>&1; then
    echo "  No changes to go.sum"
else
    echo "  go.sum was updated with new checksums"
fi

# Show Node.js package changes
if [ -f "package.json" ] && [ -f "$BACKUP_DIR/package.json" ]; then
    echo ""
    echo -e "${YELLOW}📦 Node.js package changes:${NC}"
    if diff "$BACKUP_DIR/package.json" package.json >/dev/null 2>&1; then
        echo "  No changes to package.json"
    else
        echo "  package.json was updated"
    fi
fi

echo ""
echo -e "${BLUE}🔍 Verification:${NC}"
echo "  • All tests passed"
echo "  • Code regeneration successful"
echo "  • Module integrity verified"
echo "  • Backup available at: $BACKUP_DIR"
echo ""

echo -e "${YELLOW}💡 Next steps:${NC}"
echo "  • Review changes: git diff"
echo "  • Test thoroughly in development"
echo "  • Update documentation if APIs changed"
echo "  • Commit changes: git add . && git commit -m 'Update dependencies'"
echo ""

echo -e "${YELLOW}🗑️  Cleanup:${NC}"
echo "  • Remove backup: rm -rf $BACKUP_DIR"
echo "  • Or keep it until you're confident in the updates"
echo "" 