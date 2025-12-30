# Ganz Schön Clever Scorer

A comprehensive cross-platform scoring application for the popular dice game "Ganz Schön Clever" (That's Pretty Clever) built with Go and Fyne UI framework.

## Features

### 🎮 Core Game Management
- **Multi-player Support**: Add 1-4 players and manage their scores in real-time
- **Complete Score Sheet**: Full implementation of all scoring areas:
  - 🟡 **Yellow Area**: Complete columns for increasing points (1, 4, 9, 16, 25, 36)
  - 🟢 **Green Area**: Consecutive number sequences with exponential scoring (2², 3², 4², etc.)
  - 🟠 **Orange Area**: Custom number entry with sum calculation
  - 🟣 **Purple Area**: Ascending numbers with reset on 6
  - 🔵 **Blue Area**: Progressive scoring system based on marked count
  - 🦊 **Foxes**: Special bonus tracking
  - ⭐ **Bonus Calculation**: Automatic bonus (lowest section × foxes)
- **Final Score Calculator**: Calculate and display winner with crown highlighting
- **Game Statistics**: Real-time score tracking and comparison

### 💾 Data Management
- **Game History**: Complete game session storage with timestamps
- **High Scores**: Top 10 leaderboard with rankings and medals
- **Game Details**: View detailed breakdown of past games
- **Search & Filter**: Find games by player name, date range, or score
- **Data Cleanup**: Manage and delete old game data
- **SQLite Database**: Persistent local storage for all game data

### 🎨 User Interface
- **Modern UI**: Clean, intuitive interface with Fyne framework
- **Responsive Design**: Adapts to different screen sizes
- **Navigation System**: Consistent navigation across all screens
- **Visual Feedback**: Color-coded elements and importance indicators
- **Emoji Integration**: Visually appealing icons and indicators

### 📱 Cross-Platform Support
- **Desktop**: Windows, macOS, Linux
- **Mobile**: Android (tested), iOS support
- **Touch Interface**: Optimized for both mouse and touch input

## Installation

### 📋 Prerequisites

- **Go 1.24+** - For building the application
- **Fyne v2.7+** - Cross-platform UI framework (automatically managed by Go modules)
- **Android SDK** (for mobile builds only)
- **ADB** - Android Debug Bridge (for Android installation)

### 📱 Android Installation

#### Quick Install (Recommended):
```bash
# Clone and build for Android
git clone <repository-url>
cd thats-pretty-clever-scorer
chmod +x build-android.sh
./build-android.sh
```
*The script handles everything: dependencies, building, device detection, and installation!*

#### Manual Android Build:
```bash
# 1. Install Fyne CLI
go install fyne.io/fyne/v2/cmd/fyne@latest

# 2. Build APK
fyne package -os android -name "GanzCleverScorer" -appID "com.squ1d123.ganzcleverscorer" -o bin/

# 3. Install via ADB (ensure device is connected with USB debugging)
adb install bin/GanzCleverScorer.apk
```

#### Android Requirements:
- **Android 5.0+** (API level 21+)
- **USB Debugging** enabled
- **USB connection** between computer and phone

### 💻 Desktop Installation

#### From Source:
```bash
# Clone the repository
git clone <repository-url>
cd thats-pretty-clever-scorer

# Install dependencies
go mod tidy

# Build for current platform
go build -o ganz-clever-scorer main.go

# Run the application
./ganz-clever-scorer
```

#### Cross-Platform Build:
```bash
# Build for multiple platforms
chmod +x build.sh
./build.sh
```

#### Using Fyne Package:
```bash
# Install Fyne CLI
go install fyne.io/fyne/v2/cmd/fyne@latest

# Build for specific platforms
fyne package -os windows -arch amd64 -name "GanzCleverScorer"
fyne package -os darwin -arch amd64 -name "GanzCleverScorer"
fyne package -os linux -arch amd64 -name "GanzCleverScorer"
fyne package -os android -name "GanzCleverScorer"
```

### Pre-built Binaries

Check the `bin/` directory for pre-built executables for your platform after running the build scripts.

## 🎮 How to Use

### Starting the Application
```bash
# Run from source
go run main.go

# Or run built executable
./ganz-clever-scorer
```

### Game Setup and Scoring

1. **Main Menu** - Choose from:
   - 🎮 **New Game**: Start a new scoring session
   - 📊 **Game History**: View past games and results
   - 🏅 **High Scores**: See top 10 best scores
   - 🧹 **Manage Data**: Clean up old games

2. **Add Players** (1-4 players):
   - Enter player names in the setup screen
   - Click "Add Player" for each participant
   - Click "Open Score Calculator" when ready

3. **Enter Scores** for each player:
   - 🟡 **Yellow Area**: Total yellow score (0-91 points)
   - 🟢 **Green Area**: Total green score (0-65 points)
   - 🟠 **Orange Area**: Total orange score (sum of dice values)
   - 🟣 **Purple Area**: Total purple score (sum of ascending numbers)
   - 🔵 **Blue Area**: Total blue score (0-35 points)
   - 🦊 **Foxes**: Number of foxes collected (0-4)
   - ⭐ **Bonus**: Automatically calculated (lowest section × foxes)
   - 🎯 **Total**: Automatically calculated as sum of all sections

4. **View Results**:
   - Click "Show Final Scores" to see winner determination
   - 🏆 Winner highlighted with crown emoji
   - 📊 All scores compared side-by-side with detailed breakdown
   - 💾 **Save Game**: Store game with optional notes for future reference

5. **Game Management**:
   - **New Game**: Start fresh with new players
   - **Back to Calculator**: Modify scores before saving
   - **Save & Exit**: Store game and return to main menu

### Data Management Features

#### Game History
- View complete list of all played games
- Sort by date, score, or player count
- Click any game to see detailed breakdown
- Search by player name or date range

#### High Scores
- Top 10 leaderboard with medal rankings (🥇🥈🥉)
- Player name, score, and achievement date
- Automatic ranking updates after each saved game

#### Data Cleanup
- Delete individual games or bulk cleanup
- Clear high scores table
- Database statistics overview

## 🎲 Game Rules (Quick Reference)

Ganz Schön Clever is a strategic dice game where players:
- Roll 6 colored dice each round (White, Yellow, Green, Orange, Purple, Blue)
- Choose one colored die to mark on their personal score sheet
- All lower value dice automatically go to the "silver platter" for use by all players
- Complete various scoring patterns across 5 colored areas plus fox bonus
- White die is wild and can be used as any color

### Scoring Areas

- **🟡 Yellow**: Complete columns (1, 4, 9, 16, 25, 36 points per column)
- **🟢 Green**: Consecutive numbers (2², 3², 4², 5², 6², 7², 8² points)
- **🟠 Orange**: Sum of all entered dice values
- **🟣 Purple**: Sum of ascending numbers (6 resets the sequence to 1)
- **🔵 Blue**: Progressive scoring (1, 2, 3, 5, 7, 11, 15, 21, 28, 36 points per mark)
- **🦊 Foxes**: Special bonuses collected throughout the game
- **⭐ Bonus**: Calculated as (lowest section score × number of foxes)

*This app focuses on score calculation and tracking, not dice rolling simulation.*

## 🛠️ Development

### Project Structure

```
thats-pretty-clever-scorer/
├── main.go                  # Main application entry point with UI navigation
├── internal/
│   ├── game/
│   │   ├── player.go        # Player management and score calculation
│   │   └── scoresheet.go    # Score sheet data structures and validation
│   ├── storage/
│   │   ├── database.go      # SQLite database initialization and management
│   │   ├── models.go        # Data models for games, players, and high scores
│   │   ├── games.go         # Game session CRUD operations
│   │   └── highscores.go    # High score tracking and queries
│   └── ui/
│       ├── mainmenu.go      # Main menu with statistics and navigation
│       ├── navigation.go    # Reusable navigation bar component
│       ├── scoresheet.go    # Score calculator UI for all players
│       ├── history.go       # Game history with search and filtering
│       ├── gamedetails.go   # Detailed view of individual games
│       └── cleanup.go       # Data management and cleanup interface
├── Icon.png                 # Application icon
├── FyneApp.toml            # Fyne application configuration
├── build.sh                # Cross-platform build script
├── build-android.sh        # Android-specific build and install script
├── go.mod                  # Go module definition
└── go.sum                  # Go module checksums
```

### Key Components

#### Data Layer
- **SQLite Database**: Persistent storage using modernc.org/sqlite
- **Game Sessions**: Complete game tracking with player details
- **High Scores**: Automatic leaderboard maintenance
- **Search & Filter**: Advanced querying capabilities

#### Business Logic
- **Player Management**: Multi-player score tracking
- **Score Validation**: Automatic bonus calculations
- **Game Statistics**: Real-time score computation
- **Winner Determination**: Automatic crown assignment

#### UI Components
- **Responsive Layout**: Adapts to desktop and mobile screens
- **Navigation System**: Consistent back navigation across screens
- **Data Tables**: Sortable and filterable game history
- **Visual Feedback**: Color-coded elements and importance indicators

### Building for Different Platforms

#### Cross-Platform Build:
```bash
# Build for all supported platforms
chmod +x build.sh
./build.sh
```

#### Platform-Specific Builds:
```bash
# Install Fyne CLI
go install fyne.io/fyne/v2/cmd/fyne@latest

# Windows
fyne package -os windows -arch amd64 -name "GanzCleverScorer" -icon Icon.png

# macOS
fyne package -os darwin -arch amd64 -name "GanzCleverScorer" -icon Icon.png

# Linux
fyne package -os linux -arch amd64 -name "GanzCleverScorer" -icon Icon.png

# Android
fyne package -os android -name "GanzCleverScorer" -appID "com.squ1d123.ganzcleverscorer" -icon Icon.png
```

#### Development Setup:
```bash
# Clone and setup
git clone <repository-url>
cd thats-pretty-clever-scorer

# Install dependencies
go mod tidy

# Run in development mode
go run main.go

# Build for testing
go build -o test-build main.go
./test-build
```

### Dependencies

- **Go 1.24+**: Core programming language
- **Fyne v2.7+**: Cross-platform UI framework
- **SQLite (modernc.org/sqlite)**: Embedded database engine
- **Google UUID**: Unique identifier generation

### Development Tools
- **Fyne CLI**: Packaging and deployment tool
- **Android SDK**: Mobile development (if building for Android)
- **ADB**: Android debugging and installation

## 📄 License

This project is open source and available under the MIT License. See LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add some amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Guidelines
- Follow Go coding conventions
- Test on multiple platforms if possible
- Update documentation for new features
- Ensure UI responsiveness across different screen sizes

## 🐛 Support

For issues, bug reports, or feature requests:
- **GitHub Issues**: Use the issue tracker for bugs and feature requests
- **Discussion**: Use GitHub Discussions for questions and general feedback
- **Documentation**: Check this README and inline code comments

## 📊 Application Details

- **Version**: 1.0.0
- **Build**: 5
- **App ID**: `com.squ1d123.ganzcleverscorer`
- **Database**: SQLite with automatic migrations
- **UI Framework**: Fyne v2.7+ for cross-platform support
- **Supported Languages**: Go (English interface)

---

**Enjoy tracking your Ganz Schön Clever games! 🎲🏆**