#!/usr/bin/env bash

# goDial Development Environment Manager

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
        echo -e "${YELLOW} Entering nix-shell environment...${NC}"
        exec nix-shell --run "$0 $*"
    fi
    echo -e "${GREEN}✓ Running in nix-shell environment${NC}"
}

# Function: Check if port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

# Function: Kill processes using specific port
kill_port_processes() {
    local port=$1
    
    # Find and kill processes using the port
    local pids=$(lsof -ti:$port 2>/dev/null || true)
    if [ -n "$pids" ]; then
        echo "$pids" | xargs kill -TERM 2>/dev/null || true
        sleep 2
        
        # Force kill if still running
        local remaining_pids=$(lsof -ti:$port 2>/dev/null || true)
        if [ -n "$remaining_pids" ]; then
            echo "$remaining_pids" | xargs kill -9 2>/dev/null || true
            sleep 1
        fi
    fi
}

# Function: Clean up existing processes
cleanup() {
    echo -e "${BLUE} Cleaning up existing processes...${NC}"
    
    # Kill air processes
    pkill -f "air" 2>/dev/null || true
    
    # Kill tailwindcss processes
    pkill -f "tailwindcss" 2>/dev/null || true
    
    # Kill any Go processes that might be our app
    pkill -f "./tmp/main" 2>/dev/null || true
    pkill -f "goDial" 2>/dev/null || true
    
    # Kill processes using both ports (proxy and app)
    kill_port_processes 8080
    kill_port_processes 8081
    
    # Wait for cleanup to complete
    sleep 2
    
    # Verify ports are free
    if ! check_port 8080; then
        echo -e "${RED}✗ Port 8080 is still in use after cleanup${NC}"
        lsof -i :8080 2>/dev/null || true
        exit 1
    fi
    
    if ! check_port 8081; then
        echo -e "${RED}✗ Port 8081 is still in use after cleanup${NC}"
        lsof -i :8081 2>/dev/null || true
        exit 1
    fi
    
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

# Function: Generate templates
generate_templates() {
    echo -e "${BLUE} Generating templates...${NC}"
    if templ generate >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Templates generated successfully${NC}"
    else
        echo -e "${RED}✗ Template generation failed${NC}"
        templ generate  # Show errors
        exit 1
    fi
}

# Function: Build CSS
build_css() {
    echo -e "${BLUE} Building Tailwind CSS...${NC}"
    if npm run build:css >/dev/null 2>&1; then
        echo -e "${GREEN}✓ CSS built successfully${NC}"
    else
        echo -e "${RED}✗ CSS build failed${NC}"
        npm run build:css  # Show errors
        exit 1
    fi
}

# Function: Wait for server to be ready
wait_for_server() {
    local max_attempts=30
    local attempt=1
    
    echo -e "${BLUE} Waiting for server to be ready...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:8081/health >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Server is ready${NC}"
            return 0
        fi
        
        if [ $((attempt % 5)) -eq 0 ]; then
            echo -e "${YELLOW} Still waiting for server... (attempt $attempt/$max_attempts)${NC}"
        fi
        
        sleep 1
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}✗ Server failed to start within expected time${NC}"
    return 1
}

# Function: Start development server
start_dev_server() {
    echo -e "${BLUE} Starting development server with Air...${NC}"
    
    # Start air (it will handle both the app and proxy)
    air &
    AIR_PID=$!
    
    # Wait for the server to be ready
    if wait_for_server; then
        echo -e "${GREEN}✓ Development environment ready!${NC}"
        echo -e "${YELLOW}✓ Server running at: http://localhost:8080${NC}"
        echo -e "${BLUE}✓ Live reload enabled${NC}"
        echo ""
        echo -e "${BLUE} Press Ctrl+C to stop all processes${NC}"
        
        # Wait for interrupt
        trap "cleanup; exit 0" INT TERM
        wait
    else
        echo -e "${RED}✗ Failed to start development server${NC}"
        cleanup
        exit 1
    fi
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
