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

### From Source

1. Clone the repository:
```bash
git clone <repository-url>
cd thats-pretty-clever-scorer
```

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

## Usage

1. **Start the Application**: Launch the executable
2. **Add Players**: Enter player names (1-4 players)
3. **Start Game**: Click "Start Game" to begin
4. **Take Turns**: 
   - Roll dice to get values
   - Select dice and mark score sheets
   - Use "Next Player" to advance turns
5. **View Scores**: Automatic score calculation as you play
6. **End Game**: See final scores and winner

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