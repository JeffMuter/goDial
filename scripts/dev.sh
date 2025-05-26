#!/usr/bin/env bash

# goDial Development Environment Manager
# Following the modular, easy-to-read philosophy

set -e

echo "🚀 goDial Development Environment"
echo "=================================="

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function: Check if we're in nix-shell
check_environment() {
    if [ -z "$IN_NIX_SHELL" ]; then
        echo -e "${YELLOW}📦 Entering nix-shell environment...${NC}"
        exec nix-shell --run "$0 $*"
    fi
    echo -e "${GREEN}✓ Running in nix-shell environment${NC}"
}

# Function: Clean up existing processes
cleanup() {
    echo -e "${BLUE}🧹 Cleaning up existing processes...${NC}"
    pkill air 2>/dev/null || true
    pkill tailwindcss 2>/dev/null || true
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

# Function: Generate templates
generate_templates() {
    echo -e "${BLUE}🔧 Generating templates...${NC}"
    if templ generate; then
        echo -e "${GREEN}✓ Templates generated successfully${NC}"
    else
        echo -e "${RED}✗ Template generation failed${NC}"
        exit 1
    fi
}

# Function: Build CSS
build_css() {
    echo -e "${BLUE}🎨 Building Tailwind CSS...${NC}"
    if npm run build:css; then
        echo -e "${GREEN}✓ CSS built successfully${NC}"
    else
        echo -e "${RED}✗ CSS build failed${NC}"
        exit 1
    fi
}

# Function: Start development server
start_dev_server() {
    echo -e "${BLUE}🔥 Starting development server with Air...${NC}"
    
    # Start air in background
    air &
    AIR_PID=$!
    
    # Give air time to start
    sleep 2
    
    # Start CSS watcher
    echo -e "${BLUE}👀 Starting CSS watcher...${NC}"
    npm run watch:css &
    CSS_PID=$!
    
    echo -e "${GREEN}✓ Development environment ready!${NC}"
    echo -e "${YELLOW}📍 Server running at: http://localhost:8080${NC}"
    echo -e "${YELLOW}📍 Air process ID: $AIR_PID${NC}"
    echo -e "${YELLOW}📍 CSS watcher ID: $CSS_PID${NC}"
    echo ""
    echo -e "${BLUE}🛑 Press Ctrl+C to stop all processes${NC}"
    
    # Wait for interrupt
    trap "cleanup; exit 0" INT TERM
    wait
}

# Main execution
main() {
    check_environment
    cleanup
    generate_templates
    build_css
    start_dev_server
}

# Run main function
main "$@" 