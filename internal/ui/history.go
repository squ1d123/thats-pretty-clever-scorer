package ui

import (
	"fmt"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
	"thats-pretty-clever-scorer/internal/storage"
)

// CreateGameHistoryScreen creates a screen to browse game history
func CreateGameHistoryScreen(db *storage.Database, onGameSelected func(gameID string), onBack func()) fyne.CanvasObject {

	// Create title and search controls
	titleLabel := widget.NewLabelWithStyle("📊 Game History", fyne.TextAlignCenter, fyne.TextStyle{Bold: true})

	// Search input
	searchEntry := widget.NewEntry()
	searchEntry.SetPlaceHolder("Search by player name or winner...")

	// Sort options
	sortSelect := widget.NewSelect([]string{"Date (Newest)", "Date (Oldest)", "Score (Highest)", "Score (Lowest)", "Player Count"}, nil)
	sortSelect.SetSelected("Date (Newest)")

	// Container for game list
	gameList := container.NewVBox()

	// Load games function
	loadGames := func() {
		gameList.Objects = nil // Clear existing

		// Create filter based on search and sort
		filter := storage.GameFilter{
			Query:     searchEntry.Text,
			SortBy:    storage.SortByDate,
			SortOrder: storage.SortOrderDesc,
		}

		// Map sort selection to filter
		switch sortSelect.Selected {
		case "Date (Newest)":
			filter.SortBy = storage.SortByDate
			filter.SortOrder = storage.SortOrderDesc
		case "Date (Oldest)":
			filter.SortBy = storage.SortByDate
			filter.SortOrder = storage.SortOrderAsc
		case "Score (Highest)":
			filter.SortBy = storage.SortByScore
			filter.SortOrder = storage.SortOrderDesc
		case "Score (Lowest)":
			filter.SortBy = storage.SortByScore
			filter.SortOrder = storage.SortOrderAsc
		case "Player Count":
			filter.SortBy = storage.SortByPlayerCount
			filter.SortOrder = storage.SortOrderDesc
		}

		// Load games with pagination (first 50)
		games, _, err := db.GetGames(filter, 50, 0)
		if err != nil {
			gameList.Add(widget.NewLabel("Error loading games"))
			gameList.Refresh()
			return
		}

		if len(games) == 0 {
			gameList.Add(widget.NewLabel("No games found"))
			gameList.Refresh()
			return
		}

		// Create game cards
		for _, game := range games {
			gameCard := createGameCard(game, onGameSelected)
			gameList.Add(gameCard)
			gameList.Add(widget.NewSeparator())
		}

		gameList.Refresh()
	}

	// Setup search and sort callbacks
	searchEntry.OnChanged = func(string) {
		loadGames()
	}

	sortSelect.OnChanged = func(string) {
		loadGames()
	}

	// Create controls container
	controls := container.NewHBox(
		searchEntry,
		sortSelect,
	)

	// Back button
	backBtn := widget.NewButton("← Back to Menu", onBack)

	// Initial load
	loadGames()

	// Main layout
	content := container.NewVBox(
		titleLabel,
		widget.NewSeparator(),
		controls,
		widget.NewSeparator(),
		gameList,
		backBtn,
	)

	return container.NewPadded(content)
}

// createGameCard creates a card widget for displaying game summary
func createGameCard(game *storage.GameSummary, onGameSelected func(gameID string)) fyne.CanvasObject {

	// Format date
	dateText := game.CreatedAt.Format("Jan 2, 2006 3:04 PM")

	// Create game info
	winnerText := fmt.Sprintf("🏆 %s", game.WinnerName)
	if game.WinnerName == "" {
		winnerText = "No Winner"
	}

	scoreText := fmt.Sprintf("%d pts", game.WinnerScore)
	playersText := fmt.Sprintf("%d players", game.PlayerCount)

	// Create labels
	dateLabel := widget.NewLabelWithStyle(dateText, fyne.TextAlignLeading, fyne.TextStyle{})
	winnerLabel := widget.NewLabelWithStyle(winnerText, fyne.TextAlignLeading, fyne.TextStyle{Bold: true})
	scoreLabel := widget.NewLabelWithStyle(scoreText, fyne.TextAlignTrailing, fyne.TextStyle{Bold: true})
	playersLabel := widget.NewLabel(playersText)

	// Create card structure
	header := container.NewHBox(
		winnerLabel,
		scoreLabel,
	)

	body := container.NewVBox(
		dateLabel,
		playersLabel,
	)

	// Make card clickable
	card := container.NewVBox(header, body)

	// Add click handler to view details
	tappable := &widget.Button{}
	tappable.Text = "" // Invisible button for click handling
	tappable.OnTapped = func() {
		onGameSelected(game.ID)
	}

	// Wrap card in container with click handler
	clickableCard := container.NewStack(card, tappable)

	return clickableCard
}
