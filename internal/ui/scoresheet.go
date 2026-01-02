package ui

import (
	"slices"
	"strconv"
	"thats-pretty-clever-scorer/internal/game"
	cWidget "thats-pretty-clever-scorer/internal/widget"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
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
		gm.Players = slices.Delete(gm.Players, index, index+1)
	}
}

func (gm *GameManager) UpdatePlayerName(index int, newName string) {
	if index >= 0 && index < len(gm.Players) {
		gm.Players[index].Name = newName
	}
}

func updateTotalsFunc(sa game.ScoreArea, player *game.Player, updateDisplays func()) func(string) {
	return func(value string) {
		// If value is unset, set it to 0
		if value == "" {
			value = "0"
		}

		if num, err := strconv.Atoi(value); err == nil && num >= 0 {
			sa.Record(num)
			player.ScoreSheet.CalculateBonus()
			updateDisplays()
		}
	}
}

func CreatePlayerScoreUI(player *game.Player, index int, gm *GameManager) fyne.CanvasObject {
	// Create section inputs
	yellowEntry := cWidget.NewNumericalEntry()
	yellowEntry.SetPlaceHolder("0")

	greenEntry := cWidget.NewNumericalEntry()
	greenEntry.SetPlaceHolder("0")

	orangeEntry := cWidget.NewNumericalEntry()
	orangeEntry.SetPlaceHolder("0")

	purpleEntry := cWidget.NewNumericalEntry()
	purpleEntry.SetPlaceHolder("0")

	blueEntry := cWidget.NewNumericalEntry()
	blueEntry.SetPlaceHolder("0")

	foxEntry := cWidget.NewNumericalEntry()
	foxEntry.SetPlaceHolder("0")

	// Auto-calculated display
	totalLabel := widget.NewLabelWithStyle("0", fyne.TextAlignCenter, fyne.TextStyle{Bold: true})
	bonusLabel := widget.NewLabelWithStyle("0", fyne.TextAlignCenter, fyne.TextStyle{Bold: true})

	updateDisplays := func() {
		totalLabel.SetText(strconv.Itoa(player.GetTotalScore()))
		bonusLabel.SetText(strconv.Itoa(player.ScoreSheet.Bonus.Total))
	}

	// Update displays when any entry changes
	yellowEntry.OnChanged = updateTotalsFunc(player.ScoreSheet.Yellow, player, updateDisplays)
	greenEntry.OnChanged = updateTotalsFunc(player.ScoreSheet.Green, player, updateDisplays)
	orangeEntry.OnChanged = updateTotalsFunc(player.ScoreSheet.Orange, player, updateDisplays)
	purpleEntry.OnChanged = updateTotalsFunc(player.ScoreSheet.Purple, player, updateDisplays)
	blueEntry.OnChanged = updateTotalsFunc(player.ScoreSheet.Blue, player, updateDisplays)
	foxEntry.OnChanged = updateTotalsFunc(player.ScoreSheet.Bonus, player, updateDisplays)

	// Initial update
	updateDisplays()

	// Create compact card layout
	playerCard := container.NewVBox(
		widget.NewLabelWithStyle("👤 "+player.Name, fyne.TextAlignCenter, fyne.TextStyle{Bold: true}),
		widget.NewSeparator(),
		container.NewGridWithColumns(2,
			widget.NewLabelWithStyle("🟡Yellow:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			yellowEntry,
			widget.NewLabelWithStyle("🟢Green:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			greenEntry,
			widget.NewLabelWithStyle("🟠Orange:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			orangeEntry,
			widget.NewLabelWithStyle("🟣Purple:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			purpleEntry,
			widget.NewLabelWithStyle("🔵Blue:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			blueEntry,
		),
		widget.NewSeparator(),
		container.NewGridWithColumns(2,
			widget.NewLabelWithStyle("🦊Foxes:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			foxEntry,
			widget.NewLabelWithStyle("⭐Bonus:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
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
