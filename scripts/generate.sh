#!/usr/bin/env bash

# goDial Code Generator
# Regenerates all generated code (templates, SQL, etc.)

set -e

echo "🔧 goDial Code Generator"
echo "========================"

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Regenerating all generated code...${NC}"
echo ""

# Generate templates
echo -e "${YELLOW}🎨 Generating Templ templates...${NC}"
if command -v templ >/dev/null 2>&1; then
    if templ generate; then
        echo -e "${GREEN}✅ Templates generated successfully${NC}"
    else
        echo -e "${RED}❌ Template generation failed${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ templ not found${NC}"
    echo -e "${YELLOW}💡 Install templ: go install github.com/a-h/templ/cmd/templ@latest${NC}"
    exit 1
fi

# Generate SQL code
echo ""
echo -e "${YELLOW}🗄️  Generating SQLC code...${NC}"
if command -v sqlc >/dev/null 2>&1; then
    if sqlc generate; then
        echo -e "${GREEN}✅ SQL code generated successfully${NC}"
    else
        echo -e "${RED}❌ SQL code generation failed${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ sqlc not found${NC}"
    echo -e "${YELLOW}💡 Install sqlc: go install github.com/kyleconroy/sqlc/cmd/sqlc@latest${NC}"
    exit 1
fi

# Generate Go code (if needed)
echo ""
echo -e "${YELLOW}🔧 Running go generate...${NC}"
if go generate ./...; then
    echo -e "${GREEN}✅ Go generate completed${NC}"
else
    echo -e "${YELLOW}⚠️  Go generate had issues (this might be normal)${NC}"
fi

# Format generated code
echo ""
echo -e "${YELLOW}✨ Formatting generated code...${NC}"
if go fmt ./...; then
    echo -e "${GREEN}✅ Code formatted successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Code formatting had issues${NC}"
fi

echo ""
echo -e "${GREEN}✅ All code generation completed!${NC}"

# Show what was generated
echo ""
echo -e "${BLUE}📋 Generated files:${NC}"
echo "  • Templ templates: internal/templates/**/*_templ.go"
echo "  • SQLC database code: internal/database/*.go"
echo "  • Any //go:generate directives in .go files"
echo ""

echo -e "${YELLOW}💡 What each tool does:${NC}"
echo "  • Templ: Converts .templ files to Go code for HTML templates"
echo "  • SQLC: Generates type-safe Go code from SQL queries"
echo "  • go generate: Runs any //go:generate directives in Go files"
echo ""

echo -e "${BLUE}🔄 When to regenerate:${NC}"
echo "  • After modifying .templ template files"
echo "  • After changing SQL queries in db/queries/"
echo "  • After updating database schema"
echo "  • After adding //go:generate directives"
echo "  • Before building for production"
echo "" 