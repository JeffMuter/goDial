#!/usr/bin/env bash

# Air build script for goDial with templ support and CSS rebuilding
set -e

# Set environment variables for development
export GO_ENV="development"
export AIR_ENABLED="1"

# Function to check if templates need generation
check_templates_needed() {
    # Check if any .templ file is newer than its corresponding _templ.go file
    for templ_file in $(find . -name "*.templ" -not -path "./tmp/*" -not -path "./node_modules/*" 2>/dev/null || true); do
        generated_file="${templ_file%.*}_templ.go"
        if [[ ! -f "$generated_file" ]] || [[ "$templ_file" -nt "$generated_file" ]]; then
            return 0  # true - generation needed
        fi
    done
    return 1  # false - no generation needed
}

# Function to check if CSS rebuild is needed
check_css_needed() {
    # If output.css doesn't exist, we need to build
    if [[ ! -f "./static/css/output.css" ]]; then
        return 0  # true - build needed
    fi
    
    # If input.css is newer than output.css
    if [[ "./static/css/input.css" -nt "./static/css/output.css" ]]; then
        return 0  # true - build needed
    fi
    
    # Check if any template files are newer than output.css
    for template_file in $(find ./internal/templates -name "*.templ" 2>/dev/null || true); do
        if [[ "$template_file" -nt "./static/css/output.css" ]]; then
            return 0  # true - build needed
        fi
    done
    
    return 1  # false - no build needed
}

# Generate templates only if needed
if check_templates_needed; then
    templ generate >/dev/null 2>&1
fi

# Rebuild CSS only if needed
if check_css_needed; then
    npm run build:css >/dev/null 2>&1
fi

# Build the Go application (always needed for Air)
GO_ENV="development" AIR_ENABLED="1" go build -o ./tmp/main ./cmd/main.go

# Give the binary a moment to be ready for execution
sleep 0.5 