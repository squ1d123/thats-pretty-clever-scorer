# 🏆 Ganz Schön Clever Scorer - Android Build & Installation Guide

This guide shows you how to build the Android APK and install it on your phone directly from your computer.

## 📋 Prerequisites

### Required Software:
1. **Go 1.21+** - For building the application
   - Install from: https://golang.org/dl/
   - Verify: `go version`

2. **Android SDK Platform-Tools** - For ADB (Android Debug Bridge)
   - Linux: `sudo apt-get install android-tools-adb`
   - macOS: `brew install android-platform-tools`
   - Windows: Download from [Android Developer](https://developer.android.com/studio/releases/platform-tools)

3. **Enable USB Debugging** on your Android phone:
   ```
   Settings → About Phone → Tap 'Build Number' 7 times → Developer Options
   In Developer Options → Enable "USB Debugging"
   ```

4. **USB Connection**:
   - Connect phone to computer via USB
   - Allow USB debugging authorization on phone when prompted

## 🏗️ Quick Build & Install

### Method 1: Automated Script (Recommended)
```bash
# Make script executable and run
chmod +x build-android.sh
./build-android.sh
```

The script will:
- ✅ Check all requirements
- 🏗️ Build Android APK  
- 📱 Verify device connection
- 📲 Install the application
- 🎉 Open app automatically

### Method 2: Manual Build Steps
```bash
# 1. Install Fyne CLI
go install fyne.io/fyne/v2/cmd/fyne@latest

# 2. Build APK
fyne package -os android \
    -name "GanzCleverScorer" \
    -appID "com.example.ganzcleverscorer" \
    -version 1.0 \
    -build 1 \
    -icon icon.png \
    -o bin/

# 3. Install via ADB
adb install bin/GanzCleverScorer.apk
```

## 📱 Installation Process

### What the Script Does:
1. **🔍 Requirements Check** - Verifies Go, Fyne, ADB installed
2. **🏗️ Build Process** - Compiles and packages Android APK
3. **📱 Device Detection** - Confirms phone is connected and authorized
4. **📲 Installation** - Installs/updates app on device
5. **🎮 Launch** - App available in phone's app drawer

### Expected Output:
```bash
🏗 Ganz Schön Clever Scorer - Android Build & Install
==================================================
📋 Checking requirements...
✅ All requirements satisfied!

🔨 Building Android APK...
✅ Build successful!
-rwxr-xr-x 1 user user 15M Dec 30 12:34 ganzCleverScorer.apk

📱 Checking for connected Android device...
✅ Android device found!
List of devices attached
XXXXXXXXXXXXXX	device

📲 Installing APK on device...
✅ Installation successful!
🎮 You can now open 'GanzCleverScorer' from your app drawer!

🎉 All done! Enjoy using Ganz Schön Clever Scorer on Android!
```

## 🔧 Troubleshooting

### Common Issues & Solutions:

#### ❌ "No Android device found"
**Solutions:**
1. Enable USB debugging on phone (see prerequisites above)
2. Check USB cable connection
3. Authorize computer on phone when prompted
4. Try different USB cable/port
5. Install phone manufacturer's USB drivers (Windows)

#### ❌ "Installation failed"
**Solutions:**
1. **Uninstall old version first:**
   ```bash
   adb uninstall com.example.ganzcleverscorer
   adb install bin/ganzCleverScorer.apk
   ```

2. **Enable "Install from unknown sources":**
   - Settings → Security → Enable "Unknown Sources"
   - (Varies by Android version/manufacturer)

3. **Clear app cache:**
   ```bash
   adb shell pm clear com.example.ganzcleverscorer
   ```

#### ❌ "ADB command not found"
**Solutions:**
1. Install Android SDK Platform-Tools (see prerequisites)
2. Add ADB to your PATH:
   ```bash
   export PATH=$PATH:/path/to/android-sdk/platform-tools
   ```

#### ❌ "Build failed"
**Solutions:**
1. Verify Go installation: `go version`
2. Clean previous builds: `rm -rf bin/`
3. Update Fyne CLI: `go install fyne.io/fyne/v2/cmd/fyne@latest`

## 📱 Device Compatibility

### Minimum Requirements:
- **Android 5.0+** (API level 21+)
- **RAM:** 512MB minimum, 1GB recommended
- **Storage:** 50MB available space

### Tested On:
- ✅ Android 10+ (modern devices)
- ✅ Android 8.0+ (most devices)  
- ✅ Various screen sizes and resolutions

## 🎮 App Usage on Android

### Post-Installation:
1. **Find App:** Look for "GanzCleverScorer" in your app drawer
2. **First Setup:** Add players (1-4 players)
3. **Score Entry:** Enter final scores for each colored section
4. **Bonus Calculation:** Add fox count, bonus calculated automatically
5. **Results:** View winner and final scores

### Android Features:
- 📱 **Touch-optimized** interface
- 🔄 **Responsive** design for all screen sizes
- 📊 **Real-time** score calculations
- 🏆 **Winner** detection and celebration

## 🔒 Security Notes

This app:
- ✅ **Does not require internet** permission
- ✅ **Does not access** personal data
- ✅ **Does not track** location or usage
- ✅ **Open source** and auditable
- ✅ **Self-contained** - all data stored locally

## 🆘 Alternative Installation Methods

### Method 3: Direct APK Transfer
```bash
# Build APK (same as manual method)
fyne package -os android -name "GanzCleverScorer" -appID "com.example.ganzcleverscorer" -o bin/

# Transfer APK to phone via USB or cloud storage
# On phone: Enable "Install from unknown sources" 
# Navigate to APK file and install directly
```

### Method 4: Google Play Store (Future)
The app could be published to Google Play Store for easier installation and automatic updates.

## 🎯 Support

### For Build Issues:
1. Check this repository's Issues section
2. Verify Go installation with `go version`
3. Test with: `go build -o bin/scorer ./cmd/main.go`

### For App Issues:
1. Test on computer first: `./bin/scorer`
2. Check Android version compatibility
3. Report device model and Android version

---

## 🚀 Quick Start Commands

```bash
# One command to build and install (if everything set up)
chmod +x build-android.sh && ./build-android.sh

# Manual build only
go build -o bin/scorer ./cmd/main.go

# Manual Android build only
fyne package -os android -name "GanzCleverScorer" -appID "com.example.ganzcleverscorer" -o bin/

# Check connected devices
adb devices

# Install manually
adb install bin/ganzCleverScorer.apk
```

Enjoy using the Ganz Schön Clever Scorer on your Android device! 🎉