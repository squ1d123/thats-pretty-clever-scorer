#!/bin/bash

# Ganz Schön Clever Scorer - Build Script
# This script builds the application for multiple platforms using Fyne

echo "Building Ganz Schön Clever Scorer for multiple platforms..."

# Create bin directory if it doesn't exist
mkdir -p bin

# Build for Windows (amd64)
echo "Building for Windows (amd64)..."
fyne package -os windows -arch amd64 -name "GanzCleverScorer" -icon icon.png -o bin/GanzCleverScorer-windows.exe

# Build for macOS (amd64)
echo "Building for macOS (amd64)..."
fyne package -os darwin -arch amd64 -name "GanzCleverScorer" -icon icon.png -o bin/GanzCleverScorer-mac

# Build for macOS (arm64)
echo "Building for macOS (arm64)..."
fyne package -os darwin -arch arm64 -name "GanzCleverScorer" -icon icon.png -o bin/GanzCleverScorer-mac-arm64

# Build for Linux (amd64)
echo "Building for Linux (amd64)..."
fyne package -os linux -arch amd64 -name "GanzCleverScorer" -icon icon.png -o bin/GanzCleverScorer-linux

# Build for Android
echo "Building for Android..."
fyne package -os android -name "GanzCleverScorer" -appID com.example.ganzcleverscorer -icon icon.png -o bin/GanzCleverScorer.apk

echo "Build complete! Files are in the bin/ directory:"
ls -la bin/

echo ""
echo "To build for iOS, you need Xcode and should run:"
echo "fyne package -os ios -name 'GanzCleverScorer' -appID com.example.ganzcleverscorer -icon icon.png"