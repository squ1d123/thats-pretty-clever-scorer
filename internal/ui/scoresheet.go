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
	// Create styled score label
	scoreLabel := widget.NewLabelWithStyle("🎯 Total Score: 0", fyne.TextAlignCenter, fyne.TextStyle{Bold: true})
	scoreLabel.Importance = widget.HighImportance
	updateScoreLabel(player, scoreLabel)

	// Create player header with background
	playerLabel := widget.NewLabelWithStyle("👤 "+player.Name, fyne.TextAlignLeading, fyne.TextStyle{Bold: true})
	playerLabel.Importance = widget.MediumImportance

	yellowSection := createYellowSection(player, scoreLabel)
	greenSection := createGreenSection(player, scoreLabel)
	orangeSection := createOrangeSection(player, scoreLabel)
	purpleSection := createPurpleSection(player, scoreLabel)
	blueSection := createBlueSection(player, scoreLabel)

	diceSection := CreateDiceRollerUI(gm)

	// Create styled tabs with emojis
	scoreSheetTabs := container.NewAppTabs(
		container.NewTabItem("🟡 Yellow", yellowSection),
		container.NewTabItem("🟢 Green", greenSection),
		container.NewTabItem("🟠 Orange", orangeSection),
		container.NewTabItem("🟣 Purple", purpleSection),
		container.NewTabItem("🔵 Blue", blueSection),
		container.NewTabItem("🎲 Dice", diceSection),
	)

	// Set tab location to bottom for better mobile experience
	scoreSheetTabs.SetTabLocation(container.TabLocationBottom)

	// Create main container with padding and background
	content := container.NewVBox(
		playerLabel,
		widget.NewSeparator(),
		scoreLabel,
		widget.NewSeparator(),
		scoreSheetTabs,
	)

	return container.NewPadded(content)
}

func updateScoreLabel(player *game.Player, scoreLabel *widget.Label) {
	scoreLabel.SetText("Total Score: " + strconv.Itoa(player.GetTotalScore()))
}

func createYellowSection(player *game.Player, scoreLabel *widget.Label) fyne.CanvasObject {
	var checkboxes [][]*widget.Check

	// Create section header
	header := widget.NewLabelWithStyle("🟡 Yellow Area", fyne.TextAlignCenter, fyne.TextStyle{Bold: true})
	header.Importance = widget.MediumImportance

	description := widget.NewLabel("Complete entire columns for points:\n• Column 1: 1pt  • Column 2: 4pts  • Column 3: 9pts\n• Column 4: 16pts • Column 5: 25pts • Column 6: 36pts")
	description.Wrapping = fyne.TextWrapWord

	for col := 0; col < 6; col++ {
		var column []*widget.Check
		for row := 0; row < 6; row++ {
			check := widget.NewCheck("", func(checked bool) {
				player.ScoreSheet.Yellow.Columns[col][row] = checked
				updateScoreLabel(player, scoreLabel)
			})
			check.SetChecked(player.ScoreSheet.Yellow.Columns[col][row])
			column = append(column, check)
		}
		checkboxes = append(checkboxes, column)
	}

	// Create styled grid with column labels
	grid := container.NewVBox()

	// Add header row with column numbers
	headerRow := container.NewGridWithColumns(6)
	for col := 1; col <= 6; col++ {
		colLabel := widget.NewLabelWithStyle(strconv.Itoa(col), fyne.TextAlignCenter, fyne.TextStyle{Bold: true})
		colLabel.Importance = widget.MediumImportance
		headerRow.Add(colLabel)
	}
	grid.Add(headerRow)
	grid.Add(widget.NewSeparator())

	// Add checkbox rows
	for row := 0; row < 6; row++ {
		rowContainer := container.NewGridWithColumns(6)
		for col := 0; col < 6; col++ {
			rowContainer.Add(checkboxes[col][row])
		}
		grid.Add(rowContainer)
	}

	return container.NewVBox(
		header,
		widget.NewSeparator(),
		description,
		widget.NewSeparator(),
		grid,
	)
}

func createGreenSection(player *game.Player, scoreLabel *widget.Label) fyne.CanvasObject {
	var checks []*widget.Check
	numbers := []int{2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}

	for i := range numbers {
		check := widget.NewCheck("", func(checked bool) {
			player.ScoreSheet.Green.Numbers[i] = checked
			updateScoreLabel(player, scoreLabel)
		})
		check.SetChecked(player.ScoreSheet.Green.Numbers[i])
		checks = append(checks, check)
	}

	// Create styled header
	header := widget.NewLabelWithStyle("🟢 Green Area", fyne.TextAlignCenter, fyne.TextStyle{Bold: true})
	header.Importance = widget.MediumImportance

	description := widget.NewLabel("Mark consecutive numbers from left to right:\n• 2 consecutive: 4pts  • 3 consecutive: 9pts  • 4 consecutive: 16pts\n• 5 consecutive: 25pts  • 6+ consecutive: 36+pts")
	description.Wrapping = fyne.TextWrapWord

	// Create grid with better spacing
	grid := container.NewGridWithColumns(11)
	for i, check := range checks {
		checkBoxWithLabel := container.NewVBox(
			widget.NewLabelWithStyle(strconv.Itoa(numbers[i]), fyne.TextAlignCenter, fyne.TextStyle{Bold: true}),
			check,
		)
		grid.Add(container.NewPadded(checkBoxWithLabel))
	}

	return container.NewVBox(
		header,
		widget.NewSeparator(),
		description,
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
