#!/bin/bash

echo "🔧 Fixing build issues..."
echo ""

# Remove pubspec.lock to force dependency resolution
echo "1. Removing pubspec.lock..."
rm -f pubspec.lock

# Clean Flutter build
echo "2. Cleaning Flutter build..."
flutter clean

# Remove old build artifacts
echo "3. Removing build directory..."
rm -rf build/

# Get fresh dependencies
echo "4. Getting dependencies..."
flutter pub get

# Verify dependencies
echo "5. Verifying dependencies..."
flutter pub deps | grep -E "(open_filex|install_plugin)"

echo ""
echo "✅ Done! Now try building again with:"
echo "   flutter build apk --debug"
echo ""
