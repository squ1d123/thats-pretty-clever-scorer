package ui

import (
	"fmt"
	"strconv"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
	"thats-pretty-clever-scorer/internal/storage"
)

// ScreenCallback represents a function to change screens
type ScreenCallback func(screen string)

// CreateMainMenu creates the main menu screen
func CreateMainMenu(app fyne.App, window fyne.Window, db *storage.Database, onScreenChange ScreenCallback) fyne.CanvasObject {

	// Get database stats for overview
	stats, _ := db.GetDatabaseStats()

	// Create welcome header
	titleLabel := widget.NewLabelWithStyle("🏆 Ganz Schön Clever Scorer", fyne.TextAlignCenter, fyne.TextStyle{Bold: true})
	titleLabel.TextStyle.Bold = true

	// Create stats overview
	totalGames := "0"
	highestScore := "0"

	if stats != nil {
		if totalGamesVal, ok := stats["total_games"].(int); ok {
			totalGames = strconv.Itoa(totalGamesVal)
		}
		if highestScoreVal, ok := stats["highest_score"].(int64); ok {
			highestScore = strconv.Itoa(int(highestScoreVal))
		}
	}

	statsLabel := widget.NewLabel(fmt.Sprintf("Total Games: %s | Highest Score: %s", totalGames, highestScore))

	// Create navigation buttons
	newGameBtn := widget.NewButton("🎮 New Game", func() {
		onScreenChange("setup")
	})
	newGameBtn.Importance = widget.HighImportance

	historyBtn := widget.NewButton("📊 Game History", func() {
		onScreenChange("history")
	})
	historyBtn.Importance = widget.MediumImportance

	highScoresBtn := widget.NewButton("🏅 High Scores", func() {
		onScreenChange("highscores")
	})
	highScoresBtn.Importance = widget.MediumImportance

	cleanupBtn := widget.NewButton("🧹 Manage Data", func() {
		onScreenChange("cleanup")
	})
	cleanupBtn.Importance = widget.MediumImportance

	exitBtn := widget.NewButton("🚪 Exit", func() {
		app.Quit()
	})
	exitBtn.Importance = widget.MediumImportance

	// Create button container with consistent sizing
	buttons := container.NewVBox(
		newGameBtn,
		historyBtn,
		highScoresBtn,
		cleanupBtn,
		exitBtn,
	)

	// Main layout (navigation bar will be handled by Navigation container)
	content := container.NewVBox(
		titleLabel,
		widget.NewSeparator(),
		statsLabel,
		widget.NewSeparator(),
		container.NewCenter(buttons),
	)

	return container.NewPadded(content)
}

// CreateHighScoresScreen creates the high scores screen
func CreateHighScoresScreen(db *storage.Database, onBack func()) fyne.CanvasObject {

	// Get top 10 high scores
	highScores, err := db.GetHighScores(10)
	if err != nil {
		// Show error message
		errorLabel := widget.NewLabel("Error loading high scores")
		backBtn := widget.NewButton("Back", onBack)
		return container.NewVBox(errorLabel, backBtn)
	}

	// Create list of high scores
	var scoreWidgets []fyne.CanvasObject

	if len(highScores) == 0 {
		scoreWidgets = append(scoreWidgets, widget.NewLabel("No high scores yet. Start playing!"))
	} else {
		for i, hs := range highScores {
			rankText := fmt.Sprintf("#%d", i+1)
			scoreText := fmt.Sprintf("%d pts", hs.Score)
			playerText := hs.PlayerName
			dateText := hs.AchievedAt.Format("2006-01-02")

			// Create row with rank, player, score, and date
			rankLabel := widget.NewLabelWithStyle(rankText, fyne.TextAlignLeading, fyne.TextStyle{Bold: true})
			playerLabel := widget.NewLabel(playerText)
			scoreLabel := widget.NewLabelWithStyle(scoreText, fyne.TextAlignTrailing, fyne.TextStyle{Bold: true})
			dateLabel := widget.NewLabel(dateText)

			// Color coding for top 3
			if i == 0 {
				rankLabel.SetText("🥇 " + rankText)
			} else if i == 1 {
				rankLabel.SetText("🥈 " + rankText)
			} else if i == 2 {
				rankLabel.SetText("🥉 " + rankText)
			}

			// Create row container
			row := container.NewHBox(
				container.NewVBox(rankLabel, dateLabel),
				container.NewVBox(playerLabel),
				container.NewVBox(scoreLabel),
			)

			scoreWidgets = append(scoreWidgets, row)
			scoreWidgets = append(scoreWidgets, widget.NewSeparator())
		}
	}

	// Main layout (navigation bar will be handled by Navigation container)
	content := container.NewVBox(
		container.NewVBox(scoreWidgets...),
	)

	return container.NewPadded(content)
}
