package ui

import (
	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
	"strconv"
	"thats-pretty-clever-scorer/internal/game"
)

type GameManager struct {
	Players            []*game.Player
	CurrentPlayerIndex int
	DiceSet            *game.DiceSet
	Round              int
}

func CreateScoreSheetUI(player *game.Player, gm *GameManager) fyne.CanvasObject {
	scoreLabel := widget.NewLabel("Total Score: 0")
	updateScoreLabel(player, scoreLabel)

	yellowSection := createYellowSection(player, scoreLabel)
	greenSection := createGreenSection(player, scoreLabel)
	orangeSection := createOrangeSection(player, scoreLabel)
	purpleSection := createPurpleSection(player, scoreLabel)
	blueSection := createBlueSection(player, scoreLabel)

	diceSection := CreateDiceRollerUI(gm)

	scoreSheetTabs := container.NewAppTabs(
		container.NewTabItem("Yellow", yellowSection),
		container.NewTabItem("Green", greenSection),
		container.NewTabItem("Orange", orangeSection),
		container.NewTabItem("Purple", purpleSection),
		container.NewTabItem("Blue", blueSection),
		container.NewTabItem("Dice", diceSection),
	)

	resetButton := widget.NewButton("Reset Scores", func() {
		// Reset all scores to zero
		*player.ScoreSheet = *game.NewScoreSheet()
		updateScoreLabel(player, scoreLabel)
	})

	return container.NewVBox(
		widget.NewLabel("Player: "+player.Name),
		widget.NewSeparator(),
		scoreLabel,
		widget.NewSeparator(),
		scoreSheetTabs,
		widget.NewSeparator(),
		resetButton,
	)
}

func updateScoreLabel(player *game.Player, scoreLabel *widget.Label) {
	scoreLabel.SetText("Total Score: " + strconv.Itoa(player.GetTotalScore()))
}

func createYellowSection(player *game.Player, scoreLabel *widget.Label) fyne.CanvasObject {
	var checkboxes [][]*widget.Check

	for col := 0; col < 6; col++ {
		var column []*widget.Check
		for row := 0; row < 6; row++ {
			check := widget.NewCheck("", func(checked bool) {
				// Update the score sheet data
				player.ScoreSheet.Yellow.Columns[col][row] = checked
				updateScoreLabel(player, scoreLabel)
			})
			// Set initial state
			check.SetChecked(player.ScoreSheet.Yellow.Columns[col][row])
			column = append(column, check)
		}
		checkboxes = append(checkboxes, column)
	}

	grid := container.NewGridWithColumns(6)
	for col := 0; col < 6; col++ {
		column := container.NewVBox()
		for row := 0; row < 6; row++ {
			column.Add(checkboxes[col][row])
		}
		grid.Add(column)
	}

	return container.NewVBox(
		widget.NewLabel("Yellow Area - Complete columns for points"),
		widget.NewLabel("Column 1: 1pt, Column 2: 4pts, Column 3: 9pts, etc."),
		widget.NewSeparator(),
		grid,
	)
}

func createGreenSection(player *game.Player, scoreLabel *widget.Label) fyne.CanvasObject {
	var checks []*widget.Check
	numbers := []int{2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}

	for i := range numbers {
		check := widget.NewCheck("", func(checked bool) {
			// Update the score sheet data
			player.ScoreSheet.Green.Numbers[i] = checked
			updateScoreLabel(player, scoreLabel)
		})
		// Set initial state
		check.SetChecked(player.ScoreSheet.Green.Numbers[i])
		checks = append(checks, check)
	}

	grid := container.NewGridWithColumns(11)
	for i, check := range checks {
		checkBoxWithLabel := container.NewVBox(
			widget.NewLabel(strconv.Itoa(numbers[i])),
			check,
		)
		grid.Add(checkBoxWithLabel)
	}

	return container.NewVBox(
		widget.NewLabel("Green Area - Check consecutive numbers for points"),
		widget.NewLabel("2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12"),
		widget.NewSeparator(),
		grid,
	)
}

func createOrangeSection(player *game.Player, scoreLabel *widget.Label) fyne.CanvasObject {
	var entries []*widget.Entry

	for i := 0; i < 11; i++ {
		entry := widget.NewEntry()
		entry.SetPlaceHolder("-")
		entry.OnChanged = func(value string) {
			// Update the score sheet data
			if value == "" {
				player.ScoreSheet.Orange.Numbers[i] = 0
			} else {
				if num, err := strconv.Atoi(value); err == nil && num >= 1 && num <= 6 {
					player.ScoreSheet.Orange.Numbers[i] = num
				} else {
					// Revert to valid value if invalid input
					if player.ScoreSheet.Orange.Numbers[i] > 0 {
						entry.SetText(strconv.Itoa(player.ScoreSheet.Orange.Numbers[i]))
					} else {
						entry.SetText("")
					}
				}
			}
			updateScoreLabel(player, scoreLabel)
		}
		// Set initial state
		if player.ScoreSheet.Orange.Numbers[i] > 0 {
			entry.SetText(strconv.Itoa(player.ScoreSheet.Orange.Numbers[i]))
		}
		entries = append(entries, entry)
	}

	grid := container.NewGridWithColumns(11)
	for _, entry := range entries {
		grid.Add(entry)
	}

	return container.NewVBox(
		widget.NewLabel("Orange Area - Enter any numbers"),
		widget.NewLabel("Sum of all entered numbers"),
		widget.NewSeparator(),
		grid,
	)
}

func createPurpleSection(player *game.Player, scoreLabel *widget.Label) fyne.CanvasObject {
	var checks []*widget.Check
	numbers := []int{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}

	for i := range numbers {
		check := widget.NewCheck("", func(checked bool) {
			// Update the score sheet data
			player.ScoreSheet.Purple.Numbers[i] = checked
			updateScoreLabel(player, scoreLabel)
		})
		// Set initial state
		check.SetChecked(player.ScoreSheet.Purple.Numbers[i])
		checks = append(checks, check)
	}

	grid := container.NewGridWithColumns(11)
	for i, check := range checks {
		checkBoxWithLabel := container.NewVBox(
			widget.NewLabel(strconv.Itoa(numbers[i])),
			check,
		)
		grid.Add(checkBoxWithLabel)
	}

	return container.NewVBox(
		widget.NewLabel("Purple Area - Ascending numbers (6 resets)"),
		widget.NewLabel("1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11"),
		widget.NewSeparator(),
		grid,
	)
}

func createBlueSection(player *game.Player, scoreLabel *widget.Label) fyne.CanvasObject {
	var checks []*widget.Check
	numbers := []int{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}

	for i := range numbers {
		check := widget.NewCheck("", func(checked bool) {
			// Update the score sheet data
			player.ScoreSheet.Blue.Numbers[i] = checked
			updateScoreLabel(player, scoreLabel)
		})
		// Set initial state
		check.SetChecked(player.ScoreSheet.Blue.Numbers[i])
		checks = append(checks, check)
	}

	grid := container.NewGridWithColumns(11)
	for i, check := range checks {
		checkBoxWithLabel := container.NewVBox(
			widget.NewLabel(strconv.Itoa(numbers[i])),
			check,
		)
		grid.Add(checkBoxWithLabel)
	}

	return container.NewVBox(
		widget.NewLabel("Blue Area - Check numbers for increasing points"),
		widget.NewLabel("1:1pt, 2:3pts, 3:6pts, 4:10pts, 5:15pts, etc."),
		widget.NewSeparator(),
		grid,
	)
}
