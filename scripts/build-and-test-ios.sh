#!/bin/bash
set -e

echo "🍎 =========================================="
echo "🍎  Building and Testing Matft for iOS/macOS"
echo "🍎 =========================================="
echo ""

echo "🔨 Building project..."
swift build -v

echo ""
echo "✅ Build completed successfully!"
echo ""

echo "🧪 Running tests..."
swift test -v

echo ""
echo "🎉 =========================================="
echo "🎉  All tests passed successfully!"
echo "🎉 =========================================="
