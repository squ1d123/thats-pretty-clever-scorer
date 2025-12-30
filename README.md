# Ganz Schön Clever Scorer

A cross-platform scoring application for the popular dice game "Ganz Schön Clever" (That's Pretty Clever) built with Go and Fyne UI framework.

## Features

- **Multi-player Support**: Add up to 4 players and manage their scores
- **Complete Score Sheet**: Full implementation of all scoring areas:
  - Yellow: Complete columns for increasing points
  - Green: Consecutive number sequences
  - Orange: Custom number entry
  - Purple: Ascending numbers with 6 reset
  - Blue: Progressive scoring system
- **Dice Simulation**: Roll all 6 dice with visual representation
- **Round Management**: Track rounds and player turns
- **Cross-Platform**: Works on Windows, macOS, Linux, Android, and iOS

## Installation

### 📱 Android Installation (Easiest)

#### Quick Install:
```bash
# 1. Run the automated build and install script
chmod +x build-android.sh
./build-android.sh
```
*The script will handle everything - building, device detection, installation!*

#### Manual Android Build:
```bash
# 1. Install Fyne CLI
go install fyne.io/fyne/v2/cmd/fyne@latest

# 2. Build APK
fyne package -os android -name "GanzCleverScorer" -appID "com.example.ganzcleverscorer" -o bin/

# 3. Install via ADB
adb install bin/GanzCleverScorer.apk
```

#### Prerequisites for Android:
- **Android 5.0+** (API level 21+)
- **USB Debugging** enabled on phone
- **ADB** (Android Debug Bridge) installed
- **USB connection** between computer and phone

### 💻 Desktop Installation

#### From Source:
```bash
git clone <repository-url>
cd thats-pretty-clever-scorer
go mod tidy
go build -o scorer ./cmd/main.go
```

#### Cross-Platform Build:
```bash
./build.sh  # Builds for Windows, macOS, Linux, Android
```

### 📋 Prerequisites:

- **Go 1.21+** - For building the application
- **Fyne v2.7+** - Cross-platform UI framework  
- **Android SDK** (for mobile builds only)
- **For mobile**: Android Studio or Xcode

2. Install dependencies:
```bash
go mod tidy
```

3. Build for your platform:
```bash
# For current platform
go build -o scorer ./cmd/main.go

# Or use the build script for multiple platforms
./build.sh
```

### Pre-built Binaries

Check the `bin/` directory or releases section for pre-built executables for your platform.

## 🏆 Final Score Calculator Mode

1. **Start the application:**
```bash
./bin/scorer
```

2. **Add players** (1-4 players):
   - Enter player names in setup screen
   - Click "Open Score Calculator"

3. **Enter final scores** for each player:
   - 🟡 **Yellow Area**: Enter total yellow score
   - 🟢 **Green Area**: Enter total green score  
   - 🟠 **Orange Area**: Enter total orange score
   - 🟣 **Purple Area**: Enter total purple score
   - 🔵 **Blue Area**: Enter total blue score
   - 🦊 **Foxes**: Enter number of foxes collected
   - ⭐ **Bonus**: Automatically calculated (lowest section × foxes)
   - 🎯 **Total**: Automatically calculated

4. **View results**:
   - Click "Show Final Scores" to see winner
   - 🏆 Winner is highlighted with crown
   - 📊 All scores compared side-by-side

5. **Start new calculation**:
   - Click "New Game" or "Back to Setup" to reset

## Game Rules

Ganz Schön Clever is a dice game where players:
- Roll 6 colored dice (White, Yellow, Green, Orange, Purple, Blue)
- Choose one die to mark on their score sheet
- Lower value dice go to the "silver platter" for other players
- Complete various scoring patterns across 5 colored areas
- White die is wild and can be used as any color

## Scoring Areas

- **Yellow**: Complete columns (1pt, 4pts, 9pts, 16pts, 25pts, 36pts)
- **Green**: Consecutive numbers (2², 3², 4², etc.)
- **Orange**: Sum of all entered numbers
- **Purple**: Sum of ascending numbers (6 resets the sequence)
- **Blue**: Progressive scoring based on marked count

## Development

### Project Structure

```
thats-pretty-clever-scorer/
├── cmd/
│   └── main.go              # Main application entry point
├── internal/
│   ├── game/
│   │   ├── dice.go          # Dice rolling logic
│   │   ├── player.go        # Player management
│   │   └── scoresheet.go    # Score sheet data structures
│   └── ui/
│       ├── dice.go          # Dice UI components
│       └── scoresheet.go    # Score sheet UI
├── bin/                     # Built executables
├── build.sh                 # Cross-platform build script
└── go.mod                   # Go module definition
```

### Building for Different Platforms

The included `build.sh` script can build for multiple platforms:

```bash
./build.sh
```

Or manually using the Fyne CLI:

```bash
# Install Fyne CLI
go install fyne.io/fyne/v2/cmd/fyne@latest

# Build for specific platforms
fyne package -os windows -arch amd64
fyne package -os darwin -arch amd64
fyne package -os linux -arch amd64
fyne package -os android
```

### Dependencies

- Go 1.21+
- Fyne v2.7+
- For mobile builds: Android Studio / Xcode

## License

This project is open source. See LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Support

For issues or feature requests, please use the GitHub issue tracker.