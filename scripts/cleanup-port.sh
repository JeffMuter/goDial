#!/usr/bin/env bash

# goDial Port Cleanup Script
# Use this if the dev script fails to clean up port 8080

set -e

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PORT=${1:-8080}

echo "🧹 goDial Port Cleanup"
echo "======================"
echo -e "${BLUE} Cleaning up port $PORT...${NC}"

# Check what's using the port
echo -e "${BLUE} Checking what's using port $PORT:${NC}"
lsof -i :$PORT 2>/dev/null || echo -e "${GREEN}✓ No processes found using port $PORT${NC}"

# Kill processes using the port
PIDS=$(lsof -ti:$PORT 2>/dev/null || true)
if [ -n "$PIDS" ]; then
    echo -e "${YELLOW} Found processes using port $PORT: $PIDS${NC}"
    
    # Try graceful termination first
    echo -e "${BLUE} Attempting graceful termination...${NC}"
    echo "$PIDS" | xargs kill -TERM 2>/dev/null || true
    sleep 3
    
    # Check if any are still running
    REMAINING_PIDS=$(lsof -ti:$PORT 2>/dev/null || true)
    if [ -n "$REMAINING_PIDS" ]; then
        echo -e "${RED} Force killing remaining processes: $REMAINING_PIDS${NC}"
        echo "$REMAINING_PIDS" | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
    
    # Final check
    FINAL_CHECK=$(lsof -ti:$PORT 2>/dev/null || true)
    if [ -n "$FINAL_CHECK" ]; then
        echo -e "${RED}✗ Failed to clean up port $PORT${NC}"
        echo -e "${YELLOW} Remaining processes:${NC}"
        lsof -i :$PORT 2>/dev/null || true
        exit 1
    else
        echo -e "${GREEN}✓ Port $PORT cleaned up successfully${NC}"
    fi
else
    echo -e "${GREEN}✓ Port $PORT is already free${NC}"
fi

echo -e "${GREEN}✓ Cleanup complete${NC}" 