#!/bin/bash

# APK Installer Build Script
# This script helps you build the APK installer app

set -e

echo "🚀 APK Installer Build Script"
echo "=============================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_success "Flutter found: $(flutter --version | head -n 1)"
echo ""

# Clean previous builds
print_info "Cleaning previous builds..."
flutter clean
print_success "Clean complete"
echo ""

# Get dependencies
print_info "Getting dependencies..."
flutter pub get
print_success "Dependencies installed"
echo ""

# Check for build type
BUILD_TYPE=${1:-release}

if [ "$BUILD_TYPE" != "debug" ] && [ "$BUILD_TYPE" != "release" ]; then
    print_error "Invalid build type. Use 'debug' or 'release'"
    exit 1
fi

print_info "Building APK in $BUILD_TYPE mode..."
echo ""

# Build APK
if [ "$BUILD_TYPE" = "release" ]; then
    flutter build apk --release
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
else
    flutter build apk --debug
    APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
fi

echo ""
print_success "Build complete!"
echo ""

# Check if APK exists
if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    print_success "APK created: $APK_PATH"
    print_info "APK size: $APK_SIZE"
    echo ""
    
    # Ask if user wants to install
    read -p "Do you want to install the APK on a connected device? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installing APK..."
        flutter install
        print_success "Installation complete!"
    fi
else
    print_error "APK not found at $APK_PATH"
    exit 1
fi

echo ""
print_success "All done! 🎉"
echo ""
print_info "Next steps:"
echo "  1. Transfer the APK to your device"
echo "  2. Enable 'Install from Unknown Sources'"
echo "  3. Install and grant all permissions"
echo "  4. Enter your API URL and download apps"
echo ""
