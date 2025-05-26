#!/usr/bin/env bash

# goDial Simple Build - No npm needed!
# Following the modular, easy-to-read philosophy

echo "🚀 goDial Simple Build (Pure Go)"
echo "==============================="

# Check if we're in nix-shell, if not, enter it
if [ -z "$IN_NIX_SHELL" ]; then
    echo "📦 Entering nix-shell environment..."
    exec nix-shell --run "$0"
fi

echo "✓ Running in nix-shell environment"

# Clean up old processes
echo "🧹 Cleaning up..."
pkill air 2>/dev/null || true

# Generate templates
echo "🔧 Generating templates..."
if templ generate; then
    echo "✓ Templates generated successfully"
else
    echo "✗ Template generation failed"
    exit 1
fi

# Build the Go application
echo "🏗️  Building Go application..."
if go build -o bin/goDial cmd/main.go; then
    echo "✓ Go application built successfully"
else
    echo "✗ Go build failed"
    exit 1
fi

echo ""
echo "🎉 Build complete!"
echo "📍 Run: ./bin/goDial"
echo "📍 Or use Air for hot reload: air"
echo ""
echo "💡 No npm, no CSS build process, just pure Go!" 