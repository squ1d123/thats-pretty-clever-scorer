package ui

import (
	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
	"strconv"
	"thats-pretty-clever-scorer/internal/game"
)

type GameManager struct {
	Players []*game.Player
}

func NewGameManager() *GameManager {
	return &GameManager{
		Players: make([]*game.Player, 0),
	}
}

func (gm *GameManager) AddPlayer(name string) {
	player := game.NewPlayer(name)
	gm.Players = append(gm.Players, player)
}

func (gm *GameManager) RemovePlayer(index int) {
	if index >= 0 && index < len(gm.Players) {
		gm.Players = append(gm.Players[:index], gm.Players[index+1:]...)
	}
}

func (gm *GameManager) UpdatePlayerName(index int, newName string) {
	if index >= 0 && index < len(gm.Players) {
		gm.Players[index].Name = newName
	}
}

func CreatePlayerScoreUI(player *game.Player, index int, gm *GameManager) fyne.CanvasObject {
	// Create section inputs
	yellowEntry := widget.NewEntry()
	yellowEntry.SetPlaceHolder("0")
	yellowEntry.SetText(strconv.Itoa(player.ScoreSheet.Yellow.Total))
	yellowEntry.OnChanged = func(value string) {
		if num, err := strconv.Atoi(value); err == nil && num >= 0 {
			player.ScoreSheet.Yellow.Total = num
			player.ScoreSheet.CalculateBonus()
		}
	}

	greenEntry := widget.NewEntry()
	greenEntry.SetPlaceHolder("0")
	greenEntry.SetText(strconv.Itoa(player.ScoreSheet.Green.Total))
	greenEntry.OnChanged = func(value string) {
		if num, err := strconv.Atoi(value); err == nil && num >= 0 {
			player.ScoreSheet.Green.Total = num
			player.ScoreSheet.CalculateBonus()
		}
	}

	orangeEntry := widget.NewEntry()
	orangeEntry.SetPlaceHolder("0")
	orangeEntry.SetText(strconv.Itoa(player.ScoreSheet.Orange.Total))
	orangeEntry.OnChanged = func(value string) {
		if num, err := strconv.Atoi(value); err == nil && num >= 0 {
			player.ScoreSheet.Orange.Total = num
			player.ScoreSheet.CalculateBonus()
		}
	}

	purpleEntry := widget.NewEntry()
	purpleEntry.SetPlaceHolder("0")
	purpleEntry.SetText(strconv.Itoa(player.ScoreSheet.Purple.Total))
	purpleEntry.OnChanged = func(value string) {
		if num, err := strconv.Atoi(value); err == nil && num >= 0 {
			player.ScoreSheet.Purple.Total = num
			player.ScoreSheet.CalculateBonus()
		}
	}

	blueEntry := widget.NewEntry()
	blueEntry.SetPlaceHolder("0")
	blueEntry.SetText(strconv.Itoa(player.ScoreSheet.Blue.Total))
	blueEntry.OnChanged = func(value string) {
		if num, err := strconv.Atoi(value); err == nil && num >= 0 {
			player.ScoreSheet.Blue.Total = num
			player.ScoreSheet.CalculateBonus()
		}
	}

	foxEntry := widget.NewEntry()
	foxEntry.SetPlaceHolder("0")
	foxEntry.SetText(strconv.Itoa(player.ScoreSheet.Bonus.FoxCount))
	foxEntry.OnChanged = func(value string) {
		if num, err := strconv.Atoi(value); err == nil && num >= 0 {
			player.ScoreSheet.Bonus.FoxCount = num
			player.ScoreSheet.CalculateBonus()
		}
	}

	// Auto-calculated display
	totalLabel := widget.NewLabelWithStyle("0", fyne.TextAlignCenter, fyne.TextStyle{Bold: true})
	bonusLabel := widget.NewLabelWithStyle("0", fyne.TextAlignCenter, fyne.TextStyle{Bold: true})

	updateDisplays := func() {
		totalLabel.SetText(strconv.Itoa(player.GetTotalScore()))
		bonusLabel.SetText(strconv.Itoa(player.ScoreSheet.Bonus.Bonus))
	}

	// Update displays when any entry changes
	yellowEntry.OnChanged = func(value string) {
		if num, err := strconv.Atoi(value); err == nil && num >= 0 {
			player.ScoreSheet.Yellow.Total = num
			player.ScoreSheet.CalculateBonus()
			updateDisplays()
		}
	}

	greenEntry.OnChanged = func(value string) {
		if num, err := strconv.Atoi(value); err == nil && num >= 0 {
			player.ScoreSheet.Green.Total = num
			player.ScoreSheet.CalculateBonus()
			updateDisplays()
		}
	}

	orangeEntry.OnChanged = func(value string) {
		if num, err := strconv.Atoi(value); err == nil && num >= 0 {
			player.ScoreSheet.Orange.Total = num
			player.ScoreSheet.CalculateBonus()
			updateDisplays()
		}
	}

	purpleEntry.OnChanged = func(value string) {
		if num, err := strconv.Atoi(value); err == nil && num >= 0 {
			player.ScoreSheet.Purple.Total = num
			player.ScoreSheet.CalculateBonus()
			updateDisplays()
		}
	}

	blueEntry.OnChanged = func(value string) {
		if num, err := strconv.Atoi(value); err == nil && num >= 0 {
			player.ScoreSheet.Blue.Total = num
			player.ScoreSheet.CalculateBonus()
			updateDisplays()
		}
	}

	foxEntry.OnChanged = func(value string) {
		if num, err := strconv.Atoi(value); err == nil && num >= 0 {
			player.ScoreSheet.Bonus.FoxCount = num
			player.ScoreSheet.CalculateBonus()
			updateDisplays()
		}
	}

	// Initial update
	updateDisplays()

	// Create compact card layout
	playerCard := container.NewVBox(
		widget.NewLabelWithStyle("👤 "+player.Name, fyne.TextAlignCenter, fyne.TextStyle{Bold: true}),
		widget.NewSeparator(),
		container.NewGridWithColumns(2,
			widget.NewLabelWithStyle("🟡:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			yellowEntry,
			widget.NewLabelWithStyle("🟢:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			greenEntry,
			widget.NewLabelWithStyle("🟠:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			orangeEntry,
			widget.NewLabelWithStyle("🟣:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			purpleEntry,
			widget.NewLabelWithStyle("🔵:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			blueEntry,
		),
		widget.NewSeparator(),
		container.NewGridWithColumns(2,
			widget.NewLabelWithStyle("🦊:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			foxEntry,
			widget.NewLabelWithStyle("⭐:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			bonusLabel,
		),
		widget.NewSeparator(),
		container.NewHBox(
			widget.NewLabelWithStyle("🎯 Total:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			totalLabel,
		),
	)

	return playerCard
}

func CreateAllPlayersUI(gm *GameManager) fyne.CanvasObject {
	// Create grid layout for better screen utilization
	grid := container.NewGridWithColumns(2) // 2 columns of players
	grid.Refresh()

	refreshPlayers := func() {
		// Clear existing content
		grid.Objects = nil

		// Add players to grid (up to 2 per row)
		for i, player := range gm.Players {
			playerUI := CreatePlayerScoreUI(player, i, gm)
			grid.Add(playerUI)
		}
		grid.Refresh()
	}

	refreshPlayers()

	return container.NewVBox(
		widget.NewLabelWithStyle("🏆 Final Score Calculator", fyne.TextAlignCenter, fyne.TextStyle{Bold: true}),
		widget.NewSeparator(),
		grid,
	)
}
