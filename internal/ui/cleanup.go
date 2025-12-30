package ui

import (
	"fmt"
	"strconv"
	"time"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/dialog"
	"fyne.io/fyne/v2/widget"
	"thats-pretty-clever-scorer/internal/storage"
)

// CreateCleanupScreen creates a screen for managing and cleaning up game data
func CreateCleanupScreen(db *storage.Database, onBack func()) fyne.CanvasObject {

	// Create title
	titleLabel := widget.NewLabelWithStyle("🧹 Manage Data", fyne.TextAlignCenter, fyne.TextStyle{Bold: true})

	// Get database statistics
	stats, err := db.GetDatabaseStats()
	var statsText string
	if err != nil {
		statsText = "Error loading statistics"
	} else {
		totalGames := "0"
		highestScore := "0"
		avgScore := "0"

		if val, ok := stats["total_games"].(int); ok {
			totalGames = strconv.Itoa(val)
		}
		if val, ok := stats["highest_score"].(int64); ok {
			highestScore = strconv.Itoa(int(val))
		}
		if val, ok := stats["average_winning_score"].(float64); ok {
			avgScore = fmt.Sprintf("%.1f", val)
		}

		statsText = fmt.Sprintf("Total Games: %s | Highest Score: %s | Avg Winning Score: %s",
			totalGames, highestScore, avgScore)
	}

	statsLabel := widget.NewLabel(statsText)

	// Create cleanup options section
	optionsTitle := widget.NewLabelWithStyle("Cleanup Options", fyne.TextAlignLeading, fyne.TextStyle{Bold: true})

	// Option 1: Delete games older than X months
	monthsEntry := widget.NewEntry()
	monthsEntry.SetText("6")
	monthsEntry.SetPlaceHolder("Number of months")

	deleteOldBtn := widget.NewButton("Delete Games Older Than Selected Months", func() {
		months, err := strconv.Atoi(monthsEntry.Text)
		if err != nil || months < 1 {
			dialog.ShowError(fmt.Errorf("Please enter a valid number of months"), nil)
			return
		}

		cutoffDate := time.Now().AddDate(0, -months, 0)
		confirmDeleteOldGames(db, cutoffDate, onBack)
	})
	deleteOldBtn.Importance = widget.HighImportance

	// Option 2: Delete games below score threshold
	scoreEntry := widget.NewEntry()
	scoreEntry.SetText("50")
	scoreEntry.SetPlaceHolder("Minimum score")

	deleteLowBtn := widget.NewButton("Delete Games Below Score Threshold", func() {
		threshold, err := strconv.Atoi(scoreEntry.Text)
		if err != nil || threshold < 0 {
			dialog.ShowError(fmt.Errorf("Please enter a valid score threshold"), nil)
			return
		}

		confirmDeleteLowScoringGames(db, threshold, onBack)
	})
	deleteLowBtn.Importance = widget.HighImportance

	// Option 3: Delete games in date range
	startEntry := widget.NewEntry()
	startEntry.SetText("2024-01-01")
	startEntry.SetPlaceHolder("YYYY-MM-DD")

	endEntry := widget.NewEntry()
	endEntry.SetText("2024-12-31")
	endEntry.SetPlaceHolder("YYYY-MM-DD")

	deleteRangeBtn := widget.NewButton("Delete Games in Date Range", func() {
		startDate, err1 := time.Parse("2006-01-02", startEntry.Text)
		endDate, err2 := time.Parse("2006-01-02", endEntry.Text)

		if err1 != nil || err2 != nil {
			dialog.ShowError(fmt.Errorf("Please enter valid dates in YYYY-MM-DD format"), nil)
			return
		}

		if startDate.After(endDate) {
			dialog.ShowError(fmt.Errorf("Start date must be before end date"), nil)
			return
		}

		confirmDeleteDateRange(db, startDate, endDate, onBack)
	})
	deleteRangeBtn.Importance = widget.HighImportance

	// Layout options
	optionsContainer := container.NewVBox(
		widget.NewCard("", "Delete by Age", container.NewVBox(
			widget.NewLabel("Delete all games older than the specified number of months:"),
			container.NewHBox(monthsEntry, deleteOldBtn),
		)),
		widget.NewCard("", "Delete by Score", container.NewVBox(
			widget.NewLabel("Delete all games where the winning score is below the threshold:"),
			container.NewHBox(scoreEntry, deleteLowBtn),
		)),
		widget.NewCard("", "Delete by Date Range", container.NewVBox(
			widget.NewLabel("Delete all games within the specified date range:"),
			container.NewGridWithColumns(2,
				widget.NewLabel("Start Date:"),
				startEntry,
				widget.NewLabel("End Date:"),
				endEntry,
			),
			deleteRangeBtn,
		)),
	)

	// Warning message
	warningLabel := widget.NewLabelWithStyle(
		"⚠️ Warning: These actions are permanent and cannot be undone!",
		fyne.TextAlignCenter,
		fyne.TextStyle{Bold: true, Italic: true},
	)

	// Back button
	backBtn := widget.NewButton("← Back to Menu", onBack)

	// Main layout
	content := container.NewVBox(
		titleLabel,
		widget.NewSeparator(),
		statsLabel,
		widget.NewSeparator(),
		optionsTitle,
		optionsContainer,
		widget.NewSeparator(),
		warningLabel,
		backBtn,
	)

	return container.NewPadded(content)
}

// confirmDeleteOldGames shows confirmation dialog for deleting old games
func confirmDeleteOldGames(db *storage.Database, cutoffDate time.Time, onBack func()) {
	message := fmt.Sprintf("Delete all games older than %s?\n\nThis action cannot be undone.",
		cutoffDate.Format("January 2, 2006"))

	dialog.NewConfirm(
		"Delete Old Games",
		message,
		func(confirmed bool) {
			if confirmed {
				deletedCount, err := db.DeleteOldGames(cutoffDate)
				if err != nil {
					dialog.ShowError(fmt.Errorf("Failed to delete old games: %v", err), nil)
				} else {
					dialog.ShowInformation("Games Deleted", fmt.Sprintf("Successfully deleted %d old games.", deletedCount), nil)
					onBack() // Refresh screen
				}
			}
		},
		nil,
	).Show()
}

// confirmDeleteLowScoringGames shows confirmation dialog for deleting low-scoring games
func confirmDeleteLowScoringGames(db *storage.Database, threshold int, onBack func()) {
	message := fmt.Sprintf("Delete all games where the winning score is below %d?\n\nThis action cannot be undone.",
		threshold)

	dialog.NewConfirm(
		"Delete Low-Scoring Games",
		message,
		func(confirmed bool) {
			if confirmed {
				deletedCount, err := db.DeleteLowScoringGames(threshold)
				if err != nil {
					dialog.ShowError(fmt.Errorf("Failed to delete low-scoring games: %v", err), nil)
				} else {
					dialog.ShowInformation("Games Deleted", fmt.Sprintf("Successfully deleted %d low-scoring games.", deletedCount), nil)
					onBack() // Refresh screen
				}
			}
		},
		nil,
	).Show()
}

// confirmDeleteDateRange shows confirmation dialog for deleting games in date range
func confirmDeleteDateRange(db *storage.Database, startDate, endDate time.Time, onBack func()) {
	message := fmt.Sprintf("Delete all games between %s and %s?\n\nThis action cannot be undone.",
		startDate.Format("January 2, 2006"), endDate.Format("January 2, 2006"))

	dialog.NewConfirm(
		"Delete Games in Date Range",
		message,
		func(confirmed bool) {
			if confirmed {
				deletedCount, err := db.DeleteGamesInDateRange(startDate, endDate)
				if err != nil {
					dialog.ShowError(fmt.Errorf("Failed to delete games in date range: %v", err), nil)
				} else {
					dialog.ShowInformation("Games Deleted", fmt.Sprintf("Successfully deleted %d games in date range.", deletedCount), nil)
					onBack() // Refresh screen
				}
			}
		},
		nil,
	).Show()
}
