package ui

import (
	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
)

// CreateNavigationBar creates a consistent navigation bar for all screens
func CreateNavigationBar(title string, onMainMenu func()) fyne.CanvasObject {
	titleLabel := widget.NewLabelWithStyle(title, fyne.TextAlignLeading, fyne.TextStyle{Bold: true})
	mainMenuBtn := widget.NewButton("🏠 Main Menu", onMainMenu)
	mainMenuBtn.Importance = widget.MediumImportance

	return container.NewBorder(
		container.NewVBox(
			widget.NewSeparator(),
			container.NewHBox(titleLabel, mainMenuBtn),
			widget.NewSeparator(),
		), // Top border content
		nil, // Bottom border
		nil, // Left border
		nil, // Right border
		nil, // Center
	)
}
