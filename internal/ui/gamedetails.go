package ui

import (
	"fmt"
	"log/slog"
	"sort"

	"thats-pretty-clever-scorer/internal/storage"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/dialog"
	"fyne.io/fyne/v2/widget"
)

// createColoredLabel creates a label with importance levels to simulate color emphasis
func createColoredLabel(text string, colorName string) *widget.Label {
	// Use different importance levels to simulate color emphasis
	var importance widget.Importance
	switch colorName {
	case "yellow":
		importance = widget.HighImportance
	case "green":
		importance = widget.MediumImportance
	case "orange":
		importance = widget.HighImportance
	case "purple":
		importance = widget.MediumImportance
	case "blue":
		importance = widget.MediumImportance
	default:
		importance = widget.MediumImportance
	}

	label := widget.NewLabelWithStyle(text, fyne.TextAlignLeading, fyne.TextStyle{Bold: true})
	label.Importance = importance
	return label
}

// CreateGameDetailsScreen creates a screen to view detailed game information
func CreateGameDetailsScreen(db *storage.Database, gameID string, onBack func()) fyne.CanvasObject {

	// Load game data
	game, err := db.GetGameByID(gameID)
	if err != nil {
		slog.Error("Error loading game details", "error", err)
		errorLabel := widget.NewLabel("Error loading game details")
		backBtn := widget.NewButton("Back", onBack)
		return container.NewVBox(errorLabel, backBtn)
	}

	// Create game metadata
	dateText := game.CreatedAt.Format("January 2, 2006 at 3:04 PM")
	notesText := game.Notes
	if notesText == "" {
		notesText = "No notes"
	}

	metadataContainer := container.NewVBox(
		widget.NewLabelWithStyle("Game Information", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
		widget.NewLabel(fmt.Sprintf("Date: %s", dateText)),
		widget.NewLabel(fmt.Sprintf("Players: %d", len(game.Players))),
		widget.NewLabel(fmt.Sprintf("Notes: %s", notesText)),
		widget.NewSeparator(),
	)

	// Sort players by score (highest first)
	players := make([]*storage.Player, len(game.Players))
	copy(players, game.Players)
	sort.Slice(players, func(i, j int) bool {
		return players[i].FinalScore > players[j].FinalScore
	})

	// Create player cards with section breakdowns
	var playerCards []fyne.CanvasObject
	for i, player := range players {
		card := createPlayerDetailCard(player, i == 0) // First player is winner
		playerCards = append(playerCards, card)
		playerCards = append(playerCards, widget.NewSeparator())
	}

	// Create button container
	deleteBtn := widget.NewButton("🗑️ Delete Game", func() {
		showDeleteConfirmation(db, gameID, onBack)
	})
	deleteBtn.Importance = widget.DangerImportance

	backToHistoryBtn := widget.NewButton("← Back to History", func() {
		onBack()
	})
	backToHistoryBtn.Importance = widget.MediumImportance

	buttons := container.NewHBox(backToHistoryBtn, deleteBtn)

	// Main layout (navigation bar will be handled by Navigation container)
	content := container.NewScroll(container.NewVBox(
		metadataContainer,
		widget.NewSeparator(),
		container.NewVBox(playerCards...),
		widget.NewSeparator(),
		buttons,
	))

	return container.NewPadded(content)
}

// createPlayerDetailCard creates a read-only card showing player's section scores
func createPlayerDetailCard(player *storage.Player, isWinner bool) fyne.CanvasObject {

	// Player name with winner indicator
	nameText := player.Name
	if isWinner {
		nameText = "🏆 " + nameText
	}
	nameLabel := widget.NewLabelWithStyle(nameText, fyne.TextAlignCenter, fyne.TextStyle{Bold: true})

	// Section scores with colored indicators (reuse existing color function)
	yellowLabel := createColoredLabel("● Yellow:", "yellow")
	yellowValue := widget.NewLabel(fmt.Sprintf("%d", player.YellowTotal))

	greenLabel := createColoredLabel("● Green:", "green")
	greenValue := widget.NewLabel(fmt.Sprintf("%d", player.GreenTotal))

	orangeLabel := createColoredLabel("● Orange:", "orange")
	orangeValue := widget.NewLabel(fmt.Sprintf("%d", player.OrangeTotal))

	purpleLabel := createColoredLabel("● Purple:", "purple")
	purpleValue := widget.NewLabel(fmt.Sprintf("%d", player.PurpleTotal))

	blueLabel := createColoredLabel("● Blue:", "blue")
	blueValue := widget.NewLabel(fmt.Sprintf("%d", player.BlueTotal))

	// Foxes and bonus
	foxLabel := widget.NewLabelWithStyle("🦊 Foxes:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true})
	foxValue := widget.NewLabel(fmt.Sprintf("%d", player.FoxCount))

	bonusLabel := widget.NewLabelWithStyle("⭐ Bonus:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true})
	bonusValue := widget.NewLabel(fmt.Sprintf("%d", player.Bonus))

	// Total score (highlighted for winner)
	totalText := fmt.Sprintf("%d", player.FinalScore)
	if isWinner {
		totalText = "🏆 " + totalText
	}
	totalLabel := widget.NewLabelWithStyle("🎯 Total:", fyne.TextAlignLeading, fyne.TextStyle{Bold: true})
	totalValue := widget.NewLabelWithStyle(totalText, fyne.TextAlignTrailing, fyne.TextStyle{Bold: true})

	// Create score grid
	scoreGrid := container.NewGridWithColumns(2,
		yellowLabel, yellowValue,
		greenLabel, greenValue,
		orangeLabel, orangeValue,
		purpleLabel, purpleValue,
		blueLabel, blueValue,
		foxLabel, foxValue,
		bonusLabel, bonusValue,
		totalLabel, totalValue,
	)

	// Create card container
	card := container.NewVBox(
		nameLabel,
		widget.NewSeparator(),
		scoreGrid,
	)

	return card
}

// showDeleteConfirmation shows a confirmation dialog before deleting a game
func showDeleteConfirmation(db *storage.Database, gameID string, onBack func()) {

	confirmDialog := dialog.NewConfirm(
		"Delete Game",
		"Are you sure you want to delete this game? This action cannot be undone.",
		func(confirmed bool) {
			if confirmed {
				err := db.DeleteGame(gameID)
				if err != nil {
					// Show error dialog
					dialog.ShowError(fmt.Errorf("Failed to delete game: %v", err), nil)
				} else {
					// Show success and go back
					dialog.ShowInformation("Game Deleted", "The game has been successfully deleted.", nil)
					onBack()
				}
			}
		},
		nil,
	)

	confirmDialog.SetDismissText("Cancel")
	confirmDialog.Show()
}
