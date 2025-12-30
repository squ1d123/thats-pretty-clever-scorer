package main

import (
	"fmt"
	"strconv"
	"thats-pretty-clever-scorer/internal/storage"
	"thats-pretty-clever-scorer/internal/ui"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/dialog"
	"fyne.io/fyne/v2/widget"
)

func main() {
	myApp := app.New()
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

	// Show main menu
	navigateToMainMenu(myApp, myWindow, db)
	myWindow.ShowAndRun()
}

// navigateToMainMenu creates and displays the main menu
func navigateToMainMenu(app fyne.App, window fyne.Window, db *storage.Database) {
	mainMenu := ui.CreateMainMenu(app, window, db, func(screen string) {
		switch screen {
		case "setup":
			window.SetContent(createSetupScreen(app, window, db))
		case "history":
			window.SetContent(ui.CreateGameHistoryScreen(db, func(gameID string) {
				window.SetContent(ui.CreateGameDetailsScreen(db, gameID, func() {
					navigateToMainMenu(app, window, db)
				}))
			}, func() {
				navigateToMainMenu(app, window, db)
			}))
		case "highscores":
			window.SetContent(ui.CreateHighScoresScreen(db, func() {
				navigateToMainMenu(app, window, db)
			}))
		case "cleanup":
			window.SetContent(ui.CreateCleanupScreen(db, func() {
				navigateToMainMenu(app, window, db)
			}, window))
		}
	})
	window.SetContent(mainMenu)
}

func createSetupScreen(app fyne.App, window fyne.Window, db *storage.Database) fyne.CanvasObject {
	gm := ui.NewGameManager()

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
			playerText := gm.Players[i].GetScoreText()
			label.SetText("  " + playerText + "  ")
		},
	)

	addPlayerBtn := widget.NewButton("Add Player", func() {
		if playerEntry.Text != "" {
			gm.AddPlayer(playerEntry.Text)
			playerList.Refresh()
			playerEntry.SetText("")
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

	playerContent := container.NewBorder(
		container.NewVBox(
			widget.NewSeparator(),
			widget.NewLabelWithStyle("👥 Add Players (1-4 players):", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			container.NewVBox(
				playerEntry,
				addPlayerBtn,
			),
			widget.NewSeparator(),
		),
		container.NewVBox(
			startCalculatorBtn,
		),
		nil, nil,
		container.NewBorder(widget.NewLabelWithStyle("📋 Current Players:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			nil, nil, playerList,
		),
	)

	// Create main layout with navigation
	navBar := ui.CreateNavigationBar("🎮 Game Setup", func() {
		navigateToMainMenu(app, window, db)
	})

	content := container.NewVBox(
		navBar,
		subtitleLabel,
		playerContent,
	)

	return container.NewPadded(content)
}

func showScoreCalculator(app fyne.App, window fyne.Window, gm *ui.GameManager, db *storage.Database) {
	calculatorUI := ui.CreateAllPlayersUI(gm)

	backBtn := widget.NewButton("Back to Setup", func() {
		window.SetContent(createSetupScreen(app, window, db))
	})
	backBtn.Importance = widget.MediumImportance

	finishBtn := widget.NewButton("Show Final Scores", func() {
		showFinalScores(app, window, gm, db)
	})
	finishBtn.Importance = widget.HighImportance

	// Create navigation bar
	navBar := ui.CreateNavigationBar("📊 Score Calculator", func() {
		navigateToMainMenu(app, window, db)
	})

	content := container.NewVBox(
		navBar,
		calculatorUI,
		widget.NewSeparator(),
		container.NewHBox(backBtn, finishBtn),
	)

	window.SetContent(container.NewPadded(container.NewScroll(content)))
}

func showFinalScores(app fyne.App, window fyne.Window, gm *ui.GameManager, db *storage.Database) {
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
		window.SetContent(createSetupScreen(app, window, db))
	})
	newGameBtn.Importance = widget.HighImportance

	backToCalculatorBtn := widget.NewButton("📊 Back to Calculator", func() {
		showScoreCalculator(app, window, gm, db)
	})
	backToCalculatorBtn.Importance = widget.MediumImportance

	buttonContainer := container.NewHBox(backToCalculatorBtn, saveBtn, newGameBtn)
	content.Add(buttonContainer)

	// Create navigation bar
	navBar := ui.CreateNavigationBar("🏆 Final Scores", func() {
		navigateToMainMenu(app, window, db)
	})

	finalContent := container.NewVBox(
		navBar,
		content,
	)

	window.SetContent(container.NewPadded(finalContent))
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
