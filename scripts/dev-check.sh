#!/usr/bin/env bash

# goDial Development Environment Health Check

set -e

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔍 goDial Development Environment Health Check"
echo "=============================================="

# Check if ports are in use
check_port() {
    local port=$1
    local service=$2
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${GREEN}✓ $service (port $port) is running${NC}"
        return 0
    else
        echo -e "${RED}✗ $service (port $port) is not running${NC}"
        return 1
    fi
}

# Check if server responds to health check
check_health() {
    if curl -s http://localhost:8081/health >/dev/null 2>&1; then
        echo -e "${GREEN}✓ App server health check passed${NC}"
        return 0
    else
        echo -e "${RED}✗ App server health check failed${NC}"
        return 1
    fi
}

# Check if proxy is working
check_proxy() {
    if curl -s http://localhost:8080/health >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Proxy server is working${NC}"
        return 0
    else
        echo -e "${RED}✗ Proxy server is not working${NC}"
        return 1
    fi
}

# Main health check
main() {
    local all_good=true
    
    echo -e "${BLUE}Checking services...${NC}"
    
    if ! check_port 8080 "Proxy server"; then
        all_good=false
    fi
    
    if ! check_port 8081 "App server"; then
        all_good=false
    fi
    
    if ! check_health; then
        all_good=false
    fi
    
    if ! check_proxy; then
        all_good=false
    fi
    
    echo ""
    if [ "$all_good" = true ]; then
        echo -e "${GREEN}🎉 All systems are go! Development environment is healthy.${NC}"
        echo -e "${YELLOW}🌐 Visit: http://localhost:8080${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some issues detected. Please check the development server.${NC}"
        exit 1
    fi
}

main "$@" 