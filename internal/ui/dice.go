package ui

import (
	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
	"thats-pretty-clever-scorer/internal/game"
)

func CreateDiceRollerUI(gm *GameManager) fyne.CanvasObject {
	var diceLabels []*widget.Label

	colors := []game.Color{
		game.White, game.Yellow, game.Green,
		game.Orange, game.Purple, game.Blue,
	}

	colorNames := map[game.Color]string{
		game.White:  "White",
		game.Yellow: "Yellow",
		game.Green:  "Green",
		game.Orange: "Orange",
		game.Purple: "Purple",
		game.Blue:   "Blue",
	}

	for _, color := range colors {
		label := widget.NewLabel(colorNames[color] + ": -")
		diceLabels = append(diceLabels, label)
	}

	rollButton := widget.NewButton("Roll Dice", func() {
		gm.DiceSet.Roll()
		for i, die := range gm.DiceSet.Dice {
			diceLabels[i].SetText(colorNames[die.Color] + ": " + string(rune(die.Value+'0')))
		}
	})

	diceGrid := container.NewGridWithColumns(3)
	for _, label := range diceLabels {
		diceGrid.Add(label)
	}

	selectedDieLabel := widget.NewLabel("Selected Die: None")
	silverPlatterLabel := widget.NewLabel("Silver Platter: None")

	return container.NewVBox(
		widget.NewLabel("Dice Roller"),
		widget.NewSeparator(),
		rollButton,
		widget.NewSeparator(),
		widget.NewLabel("Current Roll:"),
		diceGrid,
		widget.NewSeparator(),
		selectedDieLabel,
		silverPlatterLabel,
	)
}
