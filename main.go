package main

import (
	"strconv"
	"thats-pretty-clever-scorer/internal/ui"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
)

func main() {
	myApp := app.New()
	myApp.SetIcon(nil)
	myWindow := myApp.NewWindow("Ganz Schön Clever Scorer")
	myWindow.Resize(fyne.NewSize(1200, 800))

	setupScreen := createSetupScreen(myApp, myWindow)
	myWindow.SetContent(setupScreen)
	myWindow.ShowAndRun()
}

func createSetupScreen(app fyne.App, window fyne.Window) fyne.CanvasObject {
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
			showScoreCalculator(app, window, gm)
		}
	})
	startCalculatorBtn.Importance = widget.HighImportance

	titleLabel := widget.NewLabelWithStyle("🎲 Ganz Schön Clever Scorer", fyne.TextAlignCenter, fyne.TextStyle{Bold: true})
	titleLabel.Importance = widget.HighImportance

	subtitleLabel := widget.NewLabelWithStyle("Track your scores for the popular dice game!", fyne.TextAlignCenter, fyne.TextStyle{Italic: true})
	subtitleLabel.Importance = widget.MediumImportance

	content := container.NewBorder(
		container.NewVBox(
			titleLabel,
			subtitleLabel,
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
			nil, nil, nil, playerList,
		),
	)

	return container.NewPadded(content)
}

func showScoreCalculator(app fyne.App, window fyne.Window, gm *ui.GameManager) {
	calculatorUI := ui.CreateAllPlayersUI(gm)

	backBtn := widget.NewButton("Back to Setup", func() {
		window.SetContent(createSetupScreen(app, window))
	})
	backBtn.Importance = widget.MediumImportance

	finishBtn := widget.NewButton("Show Final Scores", func() {
		showFinalScores(app, window, gm)
	})
	finishBtn.Importance = widget.HighImportance

	content := container.NewVBox(
		calculatorUI,
		widget.NewSeparator(),
		container.NewHBox(backBtn, finishBtn),
	)

	window.SetContent(container.NewPadded(content))
}

func showFinalScores(app fyne.App, window fyne.Window, gm *ui.GameManager) {
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

	// Style buttons
	newGameBtn := widget.NewButton("🆕 New Game", func() {
		window.SetContent(createSetupScreen(app, window))
	})
	newGameBtn.Importance = widget.HighImportance

	backToCalculatorBtn := widget.NewButton("📊 Back to Calculator", func() {
		showScoreCalculator(app, window, gm)
	})
	backToCalculatorBtn.Importance = widget.MediumImportance

	buttonContainer := container.NewHBox(backToCalculatorBtn, newGameBtn)
	content.Add(buttonContainer)

	window.SetContent(container.NewPadded(content))
}
