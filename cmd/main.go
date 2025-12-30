package main

import (
	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
	"strconv"
	"thats-pretty-clever-scorer/internal/game"
	"thats-pretty-clever-scorer/internal/ui"
)

type GameManager struct {
	Players            []*game.Player
	CurrentPlayerIndex int
	DiceSet            *game.DiceSet
	Round              int
}

func NewGameManager() *GameManager {
	return &GameManager{
		Players:            make([]*game.Player, 0),
		CurrentPlayerIndex: 0,
		DiceSet:            game.NewDiceSet(),
		Round:              1,
	}
}

func (gm *GameManager) AddPlayer(name string) {
	player := game.NewPlayer(name)
	gm.Players = append(gm.Players, player)
}

func (gm *GameManager) GetCurrentPlayer() *game.Player {
	if len(gm.Players) == 0 {
		return nil
	}
	return gm.Players[gm.CurrentPlayerIndex]
}

func (gm *GameManager) NextPlayer() {
	if len(gm.Players) > 0 {
		gm.CurrentPlayerIndex = (gm.CurrentPlayerIndex + 1) % len(gm.Players)
		if gm.CurrentPlayerIndex == 0 {
			gm.Round++
		}
	}
}

func main() {
	myApp := app.New()
	myApp.SetIcon(nil)
	myWindow := myApp.NewWindow("Ganz Schön Clever Scorer")
	myWindow.Resize(fyne.NewSize(1200, 800))

	setupScreen := createSetupScreen(myApp, myWindow)
	myWindow.SetContent(setupScreen)
	myWindow.ShowAndRun()
}

func showGameScreen(app fyne.App, window fyne.Window, gm *GameManager) {
	// Create styled game info
	gameTitleLabel := widget.NewLabelWithStyle("🎲 Ganz Schön Clever", fyne.TextAlignCenter, fyne.TextStyle{Bold: true})
	gameTitleLabel.Importance = widget.HighImportance

	roundLabel := widget.NewLabelWithStyle("🔄 Round: 1", fyne.TextAlignLeading, fyne.TextStyle{Bold: true})
	currentPlayerLabel := widget.NewLabelWithStyle("🎯 Current Player: "+getCurrentPlayerName(gm), fyne.TextAlignLeading, fyne.TextStyle{Bold: true})

	// Style control buttons
	nextPlayerBtn := widget.NewButton("➡️ Next Player", func() {
		gm.NextPlayer()
		roundLabel.SetText("🔄 Round: " + strconv.Itoa(gm.Round))
		currentPlayerLabel.SetText("🎯 Current Player: " + getCurrentPlayerName(gm))
	})
	nextPlayerBtn.Importance = widget.MediumImportance

	endGameBtn := widget.NewButton("🏁 End Game", func() {
		showFinalScores(app, window, gm)
	})
	endGameBtn.Importance = widget.HighImportance

	gameControls := container.NewHBox(
		nextPlayerBtn,
		endGameBtn,
	)

	// Create styled player tabs
	tabContainer := container.NewAppTabs()
	tabContainer.SetTabLocation(container.TabLocationBottom)

	for _, player := range gm.Players {
		playerTab := createPlayerTab(player, gm)
		tabContainer.Append(container.NewTabItem("👤 "+player.Name, playerTab))
	}

	gameContainer := container.NewVBox(
		gameTitleLabel,
		widget.NewSeparator(),
		roundLabel,
		currentPlayerLabel,
		gameControls,
		widget.NewSeparator(),
		tabContainer,
	)

	window.SetContent(gameContainer)
}

func getCurrentPlayerName(gm *GameManager) string {
	if len(gm.Players) == 0 {
		return "None"
	}
	return gm.Players[gm.CurrentPlayerIndex].Name
}

func showFinalScores(app fyne.App, window fyne.Window, gm *GameManager) {
	// Create styled title
	titleLabel := widget.NewLabelWithStyle("🏆 Game Over - Final Scores", fyne.TextAlignCenter, fyne.TextStyle{Bold: true})
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

	// Style the new game button
	newGameBtn := widget.NewButton("🆕 New Game", func() {
		window.SetContent(createSetupScreen(app, window))
	})
	newGameBtn.Importance = widget.HighImportance

	content.Add(newGameBtn)
	window.SetContent(content)
}

func createSetupScreen(app fyne.App, window fyne.Window) fyne.CanvasObject {
	gm := NewGameManager()

	playerEntry := widget.NewEntry()
	playerEntry.SetPlaceHolder("Enter player name")
	playerEntry.Resize(fyne.NewSize(200, 40))

	playerList := widget.NewList(
		func() int {
			return len(gm.Players)
		},
		func() fyne.CanvasObject {
			label := widget.NewLabel("")
			label.Resize(fyne.NewSize(300, 60)) // Make items taller
			return label
		},
		func(i widget.ListItemID, o fyne.CanvasObject) {
			label := o.(*widget.Label)
			playerText := gm.Players[i].String()
			// Add extra spacing between items
			label.SetText("  " + playerText + "  ")
		},
	)

	// Set the list to be more spaced out
	playerList.Resize(fyne.NewSize(400, 300))

	addPlayerBtn := widget.NewButton("Add Player", func() {
		if playerEntry.Text != "" {
			gm.AddPlayer(playerEntry.Text)
			playerList.Refresh()
			playerEntry.SetText("")
		}
	})

	startGameBtn := widget.NewButton("Start Game", func() {
		if len(gm.Players) > 0 {
			showGameScreen(app, window, gm)
		}
	})

	// Create styled header
	titleLabel := widget.NewLabelWithStyle("🎲 Ganz Schön Clever Scorer", fyne.TextAlignCenter, fyne.TextStyle{Bold: true})
	titleLabel.Importance = widget.HighImportance

	subtitleLabel := widget.NewLabelWithStyle("Track your scores for the popular dice game!", fyne.TextAlignCenter, fyne.TextStyle{Italic: true})
	subtitleLabel.Importance = widget.MediumImportance

	// Style buttons
	addPlayerBtn.Importance = widget.MediumImportance
	startGameBtn.Importance = widget.HighImportance

	content := container.NewVBox(
		titleLabel,
		subtitleLabel,
		widget.NewSeparator(),
		widget.NewLabelWithStyle("👥 Add Players (1-4 players):", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
		container.NewVBox(
			playerEntry,
			addPlayerBtn,
		),
		widget.NewSeparator(),
		widget.NewLabelWithStyle("📋 Current Players:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
		playerList,
		widget.NewSeparator(),
		startGameBtn,
	)

	return container.NewPadded(content)
}

func createPlayerTab(player *game.Player, gm *GameManager) fyne.CanvasObject {
	uiGM := &ui.GameManager{
		Players:            gm.Players,
		CurrentPlayerIndex: gm.CurrentPlayerIndex,
		DiceSet:            gm.DiceSet,
		Round:              gm.Round,
	}
	return ui.CreateScoreSheetUI(player, uiGM)
}
