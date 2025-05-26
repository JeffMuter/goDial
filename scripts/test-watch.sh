#!/usr/bin/env bash

# goDial Test Watcher
# Automatically runs tests when files change

echo "👀 goDial Test Watcher"
echo "======================"

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Watching for file changes...${NC}"
echo -e "${YELLOW}💡 Press Ctrl+C to stop watching${NC}"
echo ""

# Function to run tests
run_tests() {
    echo -e "${YELLOW}🔄 File changed, running tests...${NC}"
    echo "=================================="
    
    # Clear test cache for fresh run
    go clean -testcache
    
    # Run tests with minimal output for watch mode
    if go test -short ./...; then
        echo -e "${GREEN}✅ Tests passed at $(date)${NC}"
    else
        echo -e "${RED}❌ Tests failed at $(date)${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}👀 Watching for changes...${NC}"
    echo ""
}

# Check if inotify-tools is available (Linux)
if command -v inotifywait >/dev/null 2>&1; then
    echo -e "${BLUE}📡 Using inotifywait for file watching${NC}"
    
    # Run initial test
    run_tests
    
    # Watch for changes
    while inotifywait -r -e modify,create,delete --include='\.go$' . 2>/dev/null; do
        # Small delay to avoid multiple rapid triggers
        sleep 0.5
        run_tests
    done

# Check if fswatch is available (macOS)
elif command -v fswatch >/dev/null 2>&1; then
    echo -e "${BLUE}📡 Using fswatch for file watching${NC}"
    
    # Run initial test
    run_tests
    
    # Watch for changes
    fswatch -o --include='\.go$' . | while read num; do
        # Small delay to avoid multiple rapid triggers
        sleep 0.5
        run_tests
    done

# Fallback to polling
else
    echo -e "${YELLOW}⚠️  No file watcher found, using polling method${NC}"
    echo -e "${YELLOW}💡 Install inotify-tools (Linux) or fswatch (macOS) for better performance${NC}"
    
    # Store initial checksums
    CHECKSUM_FILE="/tmp/godial_test_checksums"
    find . -name "*.go" -type f -exec md5sum {} \; > "$CHECKSUM_FILE" 2>/dev/null || \
    find . -name "*.go" -type f -exec md5 {} \; > "$CHECKSUM_FILE" 2>/dev/null
    
    # Run initial test
    run_tests
    
    # Poll for changes every 2 seconds
    while true; do
        sleep 2
        
        # Check for changes
        CURRENT_CHECKSUM="/tmp/godial_test_checksums_current"
        find . -name "*.go" -type f -exec md5sum {} \; > "$CURRENT_CHECKSUM" 2>/dev/null || \
        find . -name "*.go" -type f -exec md5 {} \; > "$CURRENT_CHECKSUM" 2>/dev/null
        
        if ! diff "$CHECKSUM_FILE" "$CURRENT_CHECKSUM" >/dev/null 2>&1; then
            cp "$CURRENT_CHECKSUM" "$CHECKSUM_FILE"
            run_tests
        fi
        
        rm -f "$CURRENT_CHECKSUM"
    done
fi 