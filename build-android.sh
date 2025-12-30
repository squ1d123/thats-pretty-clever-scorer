#!/bin/bash

# Ganz Schön Clever Scorer - Android Build & Install Script
# This script builds the Android APK and installs it on a connected device

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🏗 Ganz Schön Clever Scorer - Android Build & Install${NC}"
echo "=================================================="

# Check if required tools are installed
check_requirements() {
    echo -e "${YELLOW}📋 Checking requirements...${NC}"
    
    if ! command -v go &> /dev/null; then
        echo -e "${RED}❌ Go is not installed. Please install Go first.${NC}"
        echo "Visit: https://golang.org/dl/"
        exit 1
    fi
    
    if ! command -v fyne &> /dev/null; then
        echo -e "${RED}❌ Fyne CLI is not installed. Installing...${NC}"
        go install fyne.io/fyne/v2/cmd/fyne@latest
    fi
    
    if ! command -v adb &> /dev/null; then
        echo -e "${RED}❌ ADB is not installed. Please install Android SDK platform-tools.${NC}"
        echo "Visit: https://developer.android.com/studio/releases/platform-tools"
        echo "Or on Ubuntu/Debian: sudo apt-get install android-tools-adb"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All requirements satisfied!${NC}"
}

# Build the application
build_app() {
    echo -e "${BLUE}🔨 Building Android APK...${NC}"
    
    # Clean previous builds
    rm -rf bin/GanzCleverScorer.apk
    
    # Build Android APK
    fyne package -os android \
        -name "GanzCleverScorer" \
        -app-id "com.example.ganzcleverscorer" \
        -app-version 1.0 \
        -app-build 1 \
        -icon Icon.png
        # -o bin/
    
    if [ -f "GanzCleverScorer.apk" ]; then
        echo -e "${GREEN}✅ Build successful!${NC}"
        mv GanzCleverScorer.apk bin/
        ls -la bin/*.apk
    else
        echo -e "${RED}❌ Build failed!${NC}"
        exit 1
    fi
}

# Check for connected Android device
check_device() {
    echo -e "${BLUE}📱 Checking for connected Android device...${NC}"
    
    if adb devices | grep -q "device$"; then
        echo -e "${GREEN}✅ Android device found!${NC}"
        adb devices
    else
        echo -e "${YELLOW}⚠️  No Android device found.${NC}"
        echo "Please make sure:"
        echo "1. USB debugging is enabled on your phone"
        echo "2. Your phone is connected via USB"
        echo "3. You have authorized this computer on your phone"
        echo ""
        echo "Enable USB Debugging:"
        echo "Settings → About Phone → Tap 'Build Number' 7 times → Developer Options → USB Debugging"
        exit 1
    fi
}

# Install the application
install_app() {
    echo -e "${BLUE}📲 Installing APK on device...${NC}"
    
    # Install the APK
    adb install -r bin/GanzCleverScorer.apk
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Installation successful!${NC}"
        echo -e "${GREEN}🎮 You can now open 'GanzCleverScorer' from your app drawer!${NC}"
    else
        echo -e "${RED}❌ Installation failed!${NC}"
        echo "Trying to uninstall old version first..."
        adb uninstall com.example.ganzcleverscorer
        echo "Retrying installation..."
        adb install bin/GanzCleverScorer.apk
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Installation successful on retry!${NC}"
            echo -e "${GREEN}🎮 You can now open 'GanzCleverScorer' from your app drawer!${NC}"
        else
            echo -e "${RED}❌ Installation still failed.${NC}"
            exit 1
        fi
    fi
}

# Main execution
main() {
    echo -e "${BLUE}Starting Android build and install process...${NC}"
    echo ""
    
    # Create icon if it doesn't exist
    if [ ! -f "Icon.png" ]; then
        echo -e "${YELLOW}⚠️  Icon.png not found. You may want to add an app icon.${NC}"
        echo "Continuing with default icon..."
    fi
    
    check_requirements
    echo ""
    build_app
    echo ""
    check_device
    echo ""
    install_app
    echo ""
    echo -e "${GREEN}🎉 All done! Enjoy using Ganz Schön Clever Scorer on Android!${NC}"
}

# Run main function
main "$@"
