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
	roundLabel := widget.NewLabel("Round: 1")
	currentPlayerLabel := widget.NewLabel("Current Player: " + getCurrentPlayerName(gm))

	nextPlayerBtn := widget.NewButton("Next Player", func() {
		gm.NextPlayer()
		roundLabel.SetText("Round: " + strconv.Itoa(gm.Round))
		currentPlayerLabel.SetText("Current Player: " + getCurrentPlayerName(gm))
	})

	gameControls := container.NewHBox(
		nextPlayerBtn,
		widget.NewButton("End Game", func() {
			showFinalScores(app, window, gm)
		}),
	)

	tabContainer := container.NewAppTabs()

	for _, player := range gm.Players {
		playerTab := createPlayerTab(player, gm)
		tabContainer.Append(container.NewTabItem(player.Name, playerTab))
	}

	gameContainer := container.NewVBox(
		widget.NewLabel("Ganz Schön Clever"),
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
	var scores []fyne.CanvasObject

	for _, player := range gm.Players {
		scoreLabel := widget.NewLabel(player.Name + ": " + strconv.Itoa(player.GetTotalScore()) + " points")
		scores = append(scores, scoreLabel)
	}

	content := container.NewVBox(
		widget.NewLabel("Final Scores"),
		widget.NewSeparator(),
	)

	for _, score := range scores {
		content.Add(score)
	}

	content.Add(widget.NewSeparator())
	content.Add(widget.NewButton("New Game", func() {
		window.SetContent(createSetupScreen(app, window))
	}))

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

	content := container.NewVBox(
		widget.NewLabel("Ganz Schön Clever Scorer"),
		widget.NewSeparator(),
		widget.NewLabel("Add Players:"),
		container.NewVBox(
			playerEntry,
			addPlayerBtn,
		),
		widget.NewSeparator(),
		widget.NewLabel("Players:"),
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
