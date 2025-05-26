#!/usr/bin/env bash

# goDial Test Runner
# Runs all tests with coverage reporting

set -e

echo "🧪 goDial Test Suite"
echo "===================="

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test configuration
COVERAGE_DIR="coverage"
COVERAGE_FILE="$COVERAGE_DIR/coverage.out"
COVERAGE_HTML="$COVERAGE_DIR/coverage.html"

echo -e "${BLUE}🔧 Test Configuration:${NC}"
echo -e "${BLUE}   Coverage directory: $COVERAGE_DIR${NC}"
echo -e "${BLUE}   Coverage file: $COVERAGE_FILE${NC}"
echo ""

# Create coverage directory
mkdir -p "$COVERAGE_DIR"

# Clean up any existing coverage files
rm -f "$COVERAGE_FILE" "$COVERAGE_HTML"

echo -e "${YELLOW}🧹 Cleaning up previous test artifacts...${NC}"

# Clean test cache
go clean -testcache

echo -e "${YELLOW}🔍 Running tests with coverage...${NC}"
echo ""

# Run tests with coverage
if go test -v -race -coverprofile="$COVERAGE_FILE" -covermode=atomic ./...; then
    echo ""
    echo -e "${GREEN}✅ All tests passed!${NC}"
    
    # Generate coverage report
    echo ""
    echo -e "${YELLOW}📊 Generating coverage report...${NC}"
    
    # Show coverage summary
    echo -e "${BLUE}📈 Coverage Summary:${NC}"
    go tool cover -func="$COVERAGE_FILE" | tail -1
    
    # Generate HTML coverage report
    go tool cover -html="$COVERAGE_FILE" -o "$COVERAGE_HTML"
    echo -e "${GREEN}✅ HTML coverage report generated: $COVERAGE_HTML${NC}"
    
    # Show detailed coverage by package
    echo ""
    echo -e "${BLUE}📋 Coverage by Package:${NC}"
    go tool cover -func="$COVERAGE_FILE" | grep -v "total:" | sort -k3 -nr
    
    # Check coverage threshold (80%)
    TOTAL_COVERAGE=$(go tool cover -func="$COVERAGE_FILE" | tail -1 | awk '{print $3}' | sed 's/%//')
    THRESHOLD=80
    
    echo ""
    if (( $(echo "$TOTAL_COVERAGE >= $THRESHOLD" | bc -l) )); then
        echo -e "${GREEN}✅ Coverage threshold met: ${TOTAL_COVERAGE}% >= ${THRESHOLD}%${NC}"
    else
        echo -e "${YELLOW}⚠️  Coverage below threshold: ${TOTAL_COVERAGE}% < ${THRESHOLD}%${NC}"
        echo -e "${YELLOW}💡 Consider adding more tests to improve coverage${NC}"
    fi
    
else
    echo ""
    echo -e "${RED}❌ Tests failed!${NC}"
    echo ""
    echo -e "${YELLOW}💡 Troubleshooting tips:${NC}"
    echo "  • Check test output above for specific failures"
    echo "  • Ensure database is properly set up (run 'db-migrate')"
    echo "  • Verify all dependencies are installed"
    echo "  • Run 'go mod tidy' to clean up dependencies"
    echo "  • Run individual test files: go test -v ./internal/package_name"
    exit 1
fi

echo ""
echo -e "${BLUE}📁 Test Artifacts:${NC}"
echo "  • Coverage data: $COVERAGE_FILE"
echo "  • HTML report: $COVERAGE_HTML"
echo "  • Open HTML report: open $COVERAGE_HTML (macOS) or xdg-open $COVERAGE_HTML (Linux)"
echo ""

echo -e "${YELLOW}🔧 Test Commands:${NC}"
echo "  • Run specific package: go test -v ./internal/package_name"
echo "  • Run specific test: go test -v -run TestName ./internal/package_name"
echo "  • Run tests with race detection: go test -race ./..."
echo "  • Run benchmarks: go test -bench=. ./..."
echo "  • Watch tests: test-watch"
echo ""

echo -e "${GREEN}🎉 Test run completed!${NC}"
echo "" 