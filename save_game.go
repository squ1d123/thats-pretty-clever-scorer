package main

import (
	"fmt"
	"thats-pretty-clever-scorer/internal/storage"
	"thats-pretty-clever-scorer/internal/ui"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/dialog"
	"fyne.io/fyne/v2/widget"
)

// saveGameDialog handles saving a game to database
func saveGameDialog(db *storage.Database, gm *ui.GameManager, app fyne.App, window fyne.Window) {
	// Create notes entry
	notesEntry := widget.NewEntry()
	notesEntry.SetPlaceHolder("Enter optional notes for this game...")

	// Create dialog content
	content := container.NewVBox(
		widget.NewLabel("Save this game to your history?"),
		notesEntry,
	)

	// Create dialog with buttons
	dialog.NewCustomConfirm("Save Game", "Save", "Cancel", content, func(confirmed bool) {
		if confirmed {
			// Create game session
			notes := notesEntry.Text
			gameSession := storage.NewGameSession(gm.Players, notes)

			// Save to database
			err := db.SaveGame(gameSession)
			if err != nil {
				dialog.ShowError(fmt.Errorf("Failed to save game: %v", err), window)
			} else {
				dialog.ShowInformation("Game Saved", "The game has been successfully saved to your history!", window)
			}
		}
	}, window).Show()
}
