package ui

import (
	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
	"strconv"
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

	updateDiceDisplay := func() {
		for i, die := range gm.DiceSet.Dice {
			diceLabels[i].SetText(colorNames[die.Color] + ": " + strconv.Itoa(die.Value))
		}
	}

	rollButton := widget.NewButton("Roll Dice", func() {
		gm.DiceSet.Roll()
		updateDiceDisplay()
	})

	diceGrid := container.NewGridWithColumns(3)
	for _, label := range diceLabels {
		diceGrid.Add(label)
	}

	selectedDieLabel := widget.NewLabel("Selected Die: None")
	silverPlatterLabel := widget.NewLabel("Silver Platter: None")

	useDieButtons := container.NewGridWithColumns(3)
	for i, color := range colors {
		dieBtn := widget.NewButton("Use "+colorNames[color], func() {
			if gm.DiceSet.Dice[i].Value > 0 {
				selectedDieLabel.SetText("Selected Die: " + colorNames[color] + " (" + strconv.Itoa(gm.DiceSet.Dice[i].Value) + ")")
				// Find lower dice for silver platter
				lowerDice := gm.DiceSet.GetLowerDice(gm.DiceSet.Dice[i].Value)
				silverText := "Silver Platter: "
				for _, lower := range lowerDice {
					silverText += colorNames[lower.Color] + "(" + strconv.Itoa(lower.Value) + ") "
				}
				if len(lowerDice) == 0 {
					silverText += "None"
				}
				silverPlatterLabel.SetText(silverText)
			}
		})
		useDieButtons.Add(dieBtn)
	}

	// Create styled header
	header := widget.NewLabelWithStyle("🎲 Dice Roller", fyne.TextAlignCenter, fyne.TextStyle{Bold: true})
	header.Importance = widget.MediumImportance

	// Style the roll button to be more prominent
	rollButton.Importance = widget.HighImportance

	return container.NewVBox(
		header,
		widget.NewSeparator(),
		rollButton,
		widget.NewSeparator(),
		widget.NewLabelWithStyle("🎯 Current Roll:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
		container.NewPadded(diceGrid),
		widget.NewSeparator(),
		widget.NewLabelWithStyle("🎮 Select Die to Use:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
		container.NewPadded(useDieButtons),
		widget.NewSeparator(),
		container.NewVBox(
			widget.NewLabelWithStyle("✅ Selected Die:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			selectedDieLabel,
		),
		container.NewVBox(
			widget.NewLabelWithStyle("🍽 Silver Platter:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			silverPlatterLabel,
		),
	)
}
