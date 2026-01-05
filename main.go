package main

import (
	"fmt"
	"strconv"
	"thats-pretty-clever-scorer/internal/storage"
	"thats-pretty-clever-scorer/internal/ui"
	"time"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/dialog"
	"fyne.io/fyne/v2/driver/mobile"
	"fyne.io/fyne/v2/widget"
)

// Global navigation container reference
var globalNav *container.Navigation

func main() {
	myApp := app.NewWithID("com.squ1d123.ganzcleverscorer")
	myApp.SetIcon(nil)
	myWindow := myApp.NewWindow("Ganz Schön Clever Scorer")
	myWindow.Resize(fyne.NewSize(1200, 800))

	// Initialize database
	db, err := storage.InitializeDatabase(myApp)
	if err != nil {
		dialog.ShowError(fmt.Errorf("Failed to initialize database: %v", err), myWindow)
		return
	}
	defer db.Close()

	// Show main menu with navigation container
	setupNavigation(myApp, myWindow, db)

	// Handle back button on mobile devices
	if fyne.CurrentDevice().IsMobile() {
		myWindow.Canvas().SetOnTypedKey(func(ev *fyne.KeyEvent) {
			if ev.Name == mobile.KeyBack {
				// globalNav should be initialized at this point from setupNavigation
				if globalNav != nil {
					globalNav.Back()
				}
			}
		})
	}
	myWindow.ShowAndRun()
}

// setupNavigation creates the navigation container and sets up the app structure
func setupNavigation(app fyne.App, window fyne.Window, db *storage.Database) {
	// Create main menu screen
	mainMenu := ui.CreateMainMenu(app, window, db, func(screen string) {
		navigateToScreen(app, window, db, screen)
	})

	// Initialize navigation container with main menu as root
	globalNav = container.NewNavigationWithTitle(mainMenu, "Ganz Schön Clever Scorer")

	// Set navigation container as window content
	window.SetContent(globalNav)
}

// navigateToScreen handles navigation to different screens using the navigation container
func navigateToScreen(app fyne.App, window fyne.Window, db *storage.Database, screen string) {
	if globalNav == nil {
		dialog.ShowError(fmt.Errorf("Navigation container not found"), window)
		return
	}

	switch screen {
	case "setup":
		setupScreen := createSetupScreen(app, window, db)
		globalNav.PushWithTitle(setupScreen, "🎮 Game Setup")
	case "history":
		historyScreen := ui.CreateGameHistoryScreen(db, func(gameID string) {
			detailsScreen := ui.CreateGameDetailsScreen(db, gameID, func() {
				globalNav.Back() // Go back to history
			}, window)
			globalNav.PushWithTitle(detailsScreen, "📊 Game Details")
		}, func() {
			globalNav.Back() // Go back to main menu
		})
		globalNav.PushWithTitle(historyScreen, "📊 Game History")
	case "highscores":
		highScoresScreen := ui.CreateHighScoresScreen(db, func() {
			globalNav.Back() // Go back to main menu
		})
		globalNav.PushWithTitle(highScoresScreen, "🏅 High Scores")
	case "cleanup":
		cleanupScreen := ui.CreateCleanupScreen(db, func() {
			globalNav.Back() // Go back to main menu
		}, window)
		globalNav.PushWithTitle(cleanupScreen, "🧹 Manage Data")
	}
}

func createSetupScreen(app fyne.App, window fyne.Window, db *storage.Database) fyne.CanvasObject {
	gm := ui.NewGameManager()

	// Setup state for search and recent players
	var recentPlayers []string
	var searchDebouncer *time.Timer

	// Manual entry field
	playerEntry := widget.NewEntry()
	playerEntry.SetPlaceHolder("Enter player name")
	playerEntry.Resize(fyne.NewSize(200, 40))

	playerList := widget.NewList(
		func() int {
			return len(gm.Players)
		},
		func() fyne.CanvasObject {
			label := widget.NewLabel("")
			return label
		},
		func(i widget.ListItemID, o fyne.CanvasObject) {
			label := o.(*widget.Label)
			playerName := gm.Players[i].Name
			label.SetText("  " + playerName + "  ")
		},
	)

	// Search entry field
	searchEntry := widget.NewEntry()
	searchEntry.SetPlaceHolder("🔍 Search players...")

	// Recent/search players container
	playerButtonsContainer := container.NewVBox()

	// Declare updatePlayerButtons function before use
	var updatePlayerButtons func([]string)

	updatePlayerButtons = func(players []string) {
		playerButtonsContainer.RemoveAll()
		if len(players) == 0 {
			noPlayersLabel := widget.NewLabel("No previous players found")
			noPlayersLabel.Alignment = fyne.TextAlignCenter
			playerButtonsContainer.Add(noPlayersLabel)
		} else {
			// Create a grid for player buttons
			buttonGrid := container.NewGridWithColumns(3)
			for _, playerName := range players {
				// Capture playerName to avoid closure issues
				name := playerName
				playerBtn := widget.NewButton(name, func() {
					gm.AddPlayer(name)
					playerList.Refresh()
					// Clear search after adding
					searchEntry.SetText("")
					newPlayers, _ := db.GetRecentPlayerNames(5)
					recentPlayers = newPlayers
					updatePlayerButtons(newPlayers)
				})
				buttonGrid.Add(playerBtn)
			}
			playerButtonsContainer.Add(buttonGrid)
		}
		// This will async refresh the container UI
		fyne.Do(func() {
			playerButtonsContainer.Refresh()
		})
	}

	// Load recent players asynchronously
	time.AfterFunc(50*time.Millisecond, func() {
		players, err := db.GetRecentPlayerNames(5)
		if err == nil {
			recentPlayers = players
			updatePlayerButtons(players)
		}
	})

	// Set up live search with debouncing
	searchEntry.OnChanged = func(text string) {
		if searchDebouncer != nil {
			searchDebouncer.Stop()
		}

		if text == "" {
			updatePlayerButtons(recentPlayers)
			return
		}

		searchDebouncer = time.AfterFunc(300*time.Millisecond, func() {
			players, err := db.SearchPlayerNames(text, 20)
			if err == nil {
				updatePlayerButtons(players)
			}
		})
	}

	addPlayerBtn := widget.NewButton("Add Player", func() {
		if playerEntry.Text != "" {
			gm.AddPlayer(playerEntry.Text)
			playerList.Refresh()
			playerEntry.SetText("")
			// Refresh recent players after adding via manual entry
			go func() {
				players, _ := db.GetRecentPlayerNames(5)
				recentPlayers = players
				updatePlayerButtons(players)
			}()
		}
	})
	addPlayerBtn.Importance = widget.MediumImportance

	startCalculatorBtn := widget.NewButton("Open Score Calculator", func() {
		if len(gm.Players) > 0 {
			showScoreCalculator(app, window, gm, db)
		}
	})
	startCalculatorBtn.Importance = widget.HighImportance

	subtitleLabel := widget.NewLabelWithStyle("Track your scores for the popular dice game!", fyne.TextAlignCenter, fyne.TextStyle{Italic: true})
	subtitleLabel.Importance = widget.MediumImportance

	// Create main layout (navigation bar will be handled by Navigation container)
	content := container.NewBorder(
		container.NewVBox(
			subtitleLabel,
			widget.NewSeparator(),
			widget.NewLabelWithStyle("👥 Add Players (1-4 players):", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			searchEntry,
			widget.NewLabelWithStyle("Quick Add:", fyne.TextAlignLeading, fyne.TextStyle{Italic: true}),
			playerButtonsContainer,
			widget.NewSeparator(),
			widget.NewLabelWithStyle("Or Enter Name:", fyne.TextAlignLeading, fyne.TextStyle{Italic: true}),
			container.NewVBox(
				playerEntry,
				addPlayerBtn,
			),
			widget.NewSeparator(),
			widget.NewLabelWithStyle("📋 Current Players:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
		),
		container.NewVBox(
			startCalculatorBtn,
		),
		nil, nil,
		playerList,
	)

	return container.NewPadded(content)
}

func showScoreCalculator(app fyne.App, window fyne.Window, gm *ui.GameManager, db *storage.Database) {
	calculatorUI := ui.CreateAllPlayersUI(gm)

	backBtn := widget.NewButton("Back to Setup", func() {
		globalNav.Back() // Go back to setup screen
	})
	backBtn.Importance = widget.MediumImportance

	finishBtn := widget.NewButton("Show Final Scores", func() {
		finalScoresScreen := createFinalScoresScreen(app, window, gm, db)
		globalNav.PushWithTitle(finalScoresScreen, "🏆 Final Scores")
	})
	finishBtn.Importance = widget.HighImportance

	// Create content (navigation bar will be handled by Navigation container)
	content := container.NewVBox(
		calculatorUI,
		widget.NewSeparator(),
		container.NewHBox(backBtn, finishBtn),
	)

	// Push this screen to navigation
	calculatorScreen := container.NewPadded(container.NewScroll(content))
	globalNav.PushWithTitle(calculatorScreen, "📊 Score Calculator")
}

func createFinalScoresScreen(app fyne.App, window fyne.Window, gm *ui.GameManager, db *storage.Database) fyne.CanvasObject {
	titleLabel := widget.NewLabelWithStyle("🏆 Final Scores", fyne.TextAlignCenter, fyne.TextStyle{Bold: true})
	titleLabel.Importance = widget.HighImportance

	content := container.NewVBox(
		titleLabel,
		widget.NewSeparator(),
	)

	// Find winner
	maxScore := -1
	for _, player := range gm.Players {
		if player.GetTotalScore() > maxScore {
			maxScore = player.GetTotalScore()
		}
	}

	// Display scores with winner highlighting
	for _, player := range gm.Players {
		score := player.GetTotalScore()
		scoreText := strconv.Itoa(score) + " points"

		if score == maxScore {
			// Winner gets special styling
			scoreLabel := widget.NewLabelWithStyle("🏆 "+player.Name+" (WINNER): "+scoreText, fyne.TextAlignLeading, fyne.TextStyle{Bold: true})
			scoreLabel.Importance = widget.HighImportance
			content.Add(scoreLabel)
		} else {
			scoreLabel := widget.NewLabel("👤 " + player.Name + ": " + scoreText)
			scoreLabel.Importance = widget.MediumImportance
			content.Add(scoreLabel)
		}
		content.Add(widget.NewSeparator())
	}

	// Add save functionality
	saveBtn := widget.NewButton("💾 Save Game", func() {
		saveGameDialog(db, gm, app, window)
	})
	saveBtn.Importance = widget.HighImportance

	// Style buttons
	newGameBtn := widget.NewButton("🆕 New Game", func() {
		// Clear navigation stack back to setup and create new game
		for globalNav.Back() != nil {
			// Keep going back until we reach root
		}
		setupScreen := createSetupScreen(app, window, db)
		globalNav.PushWithTitle(setupScreen, "🎮 Game Setup")
	})
	newGameBtn.Importance = widget.HighImportance

	backToCalculatorBtn := widget.NewButton("📊 Calculator", func() {
		globalNav.Back() // Go back to calculator
	})
	backToCalculatorBtn.Importance = widget.MediumImportance

	buttonContainer := container.NewHBox(backToCalculatorBtn, saveBtn, newGameBtn)
	content.Add(buttonContainer)

	// Return content (navigation bar will be handled by Navigation container)
	return container.NewPadded(content)
}

// saveGameDialog handles saving a game to database
func saveGameDialog(db *storage.Database, gm *ui.GameManager, _ fyne.App, window fyne.Window) {
	// Create notes entry
	notesEntry := widget.NewEntry()
	notesEntry.SetPlaceHolder("Enter optional notes for this game...")

	// Create dialog content
	dialogContent := container.NewVBox(
		widget.NewLabel("Save this game to your history?"),
		notesEntry,
	)

	// Create dialog with buttons
	dialog.NewCustomConfirm("Save Game", "Save", "Cancel", dialogContent, func(confirmed bool) {
		if confirmed {
			// Create game session
			notes := notesEntry.Text
			gameSession := storage.NewGameSession(gm.Players, notes)

			// Save to database
			err := db.SaveGame(gameSession)
			if err != nil {
				dialog.ShowError(fmt.Errorf("Failed to save game: %v", err), window)
			} else {
				dialog.ShowInformation("Game Saved", "The game has been successfully saved to your history!", window)
			}
		}
	}, window).Show()
}
