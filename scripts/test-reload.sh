#!/usr/bin/env bash

# Test live reload functionality by making a small change to a template

set -e

echo "🧪 Testing live reload functionality..."

# Find a template file to modify
TEMPLATE_FILE="internal/templates/pages/home.templ"

if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "❌ Template file not found: $TEMPLATE_FILE"
    exit 1
fi

# Make a backup
cp "$TEMPLATE_FILE" "$TEMPLATE_FILE.backup"

echo "📝 Making a small change to $TEMPLATE_FILE..."

# Add a comment with timestamp to trigger a reload
echo "<!-- Test reload at $(date) -->" >> "$TEMPLATE_FILE"

echo "✅ Change made! Check your browser - it should reload automatically."
echo "💡 The page should wait for the server to be ready before reloading."

# Wait a moment, then restore the file
sleep 5

echo "🔄 Restoring original file..."
mv "$TEMPLATE_FILE.backup" "$TEMPLATE_FILE"

echo "✅ Test complete! The page should reload again." 