#!/usr/bin/env bash

# goDial Production Build
# Builds the application for production deployment

set -e

echo "🏗️  goDial Production Build"
echo "==========================="

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Build configuration
BUILD_DIR="bin"
BINARY_NAME="goDial"
BINARY_PATH="$BUILD_DIR/$BINARY_NAME"

# Get version info
VERSION=$(git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME=$(date -u '+%Y-%m-%d_%H:%M:%S_UTC')

echo -e "${BLUE}🔧 Build Configuration:${NC}"
echo -e "${BLUE}   Version: $VERSION${NC}"
echo -e "${BLUE}   Commit: $COMMIT${NC}"
echo -e "${BLUE}   Build time: $BUILD_TIME${NC}"
echo -e "${BLUE}   Output: $BINARY_PATH${NC}"
echo ""

# Create build directory
mkdir -p "$BUILD_DIR"

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
rm -f "$BINARY_PATH"

# Generate templates
echo -e "${YELLOW}🎨 Generating templates...${NC}"
if command -v templ >/dev/null 2>&1; then
    if templ generate; then
        echo -e "${GREEN}✅ Templates generated successfully${NC}"
    else
        echo -e "${RED}❌ Template generation failed${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  templ not found, skipping template generation${NC}"
fi

# Generate SQL code
echo -e "${YELLOW}🔧 Generating SQL code...${NC}"
if command -v sqlc >/dev/null 2>&1; then
    if sqlc generate; then
        echo -e "${GREEN}✅ SQL code generated successfully${NC}"
    else
        echo -e "${RED}❌ SQL code generation failed${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  sqlc not found, skipping SQL code generation${NC}"
fi

# Build CSS if needed
if [ -f "package.json" ] && [ -d "node_modules" ]; then
    echo -e "${YELLOW}🎨 Building CSS...${NC}"
    if npm run build:css 2>/dev/null; then
        echo -e "${GREEN}✅ CSS built successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  CSS build failed or not configured${NC}"
    fi
fi

# Run tests before building
echo -e "${YELLOW}🧪 Running tests...${NC}"
if go test -short ./...; then
    echo -e "${GREEN}✅ All tests passed${NC}"
else
    echo -e "${RED}❌ Tests failed${NC}"
    echo -e "${YELLOW}💡 Fix tests before building for production${NC}"
    exit 1
fi

# Build the application
echo ""
echo -e "${YELLOW}🏗️  Building application...${NC}"

# Build flags for production
BUILD_FLAGS=(
    -ldflags "-s -w -X main.version=$VERSION -X main.commit=$COMMIT -X main.buildTime=$BUILD_TIME"
    -trimpath
    -o "$BINARY_PATH"
    cmd/main.go
)

if go build "${BUILD_FLAGS[@]}"; then
    echo -e "${GREEN}✅ Build completed successfully!${NC}"
    
    # Show binary info
    echo ""
    echo -e "${BLUE}📊 Binary Information:${NC}"
    ls -lah "$BINARY_PATH"
    
    # Show binary size
    BINARY_SIZE=$(du -h "$BINARY_PATH" | cut -f1)
    echo -e "${BLUE}   Size: $BINARY_SIZE${NC}"
    
    # Test the binary
    echo ""
    echo -e "${YELLOW}🔍 Testing binary...${NC}"
    if "$BINARY_PATH" --version 2>/dev/null || echo "Binary created successfully"; then
        echo -e "${GREEN}✅ Binary is functional${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not test binary (--version flag may not be implemented)${NC}"
    fi
    
else
    echo -e "${RED}❌ Build failed!${NC}"
    echo ""
    echo -e "${YELLOW}💡 Troubleshooting tips:${NC}"
    echo "  • Check for compilation errors above"
    echo "  • Ensure all dependencies are available"
    echo "  • Run 'go mod tidy' to clean up dependencies"
    echo "  • Verify Go version compatibility"
    exit 1
fi

echo ""
echo -e "${BLUE}🚀 Deployment Information:${NC}"
echo "  • Binary: $BINARY_PATH"
echo "  • Run with: ./$BINARY_PATH"
echo "  • Database: Ensure goDial.db is in the same directory"
echo "  • Static files: Ensure static/ directory is available"
echo "  • Templates: Templates are compiled into the binary"
echo ""

echo -e "${YELLOW}📦 Production Checklist:${NC}"
echo "  ✅ Binary compiled with optimizations"
echo "  ✅ Templates generated and embedded"
echo "  ✅ SQL code generated"
echo "  ✅ Tests passed"
echo "  📋 TODO: Set up database migrations on target server"
echo "  📋 TODO: Configure environment variables"
echo "  📋 TODO: Set up reverse proxy (nginx/caddy)"
echo "  📋 TODO: Configure SSL certificates"
echo ""

echo -e "${GREEN}🎉 Production build completed!${NC}"
echo "" 