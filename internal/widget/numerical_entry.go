package widget

import (
	"strconv"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/driver/mobile"
	"fyne.io/fyne/v2/widget"
)

type NumericalEntry struct {
	widget.Entry
}

// NewNumericalEntry creates a new numerical entry widget.
// It only allows digits 0-9 to be entered.
func NewNumericalEntry() *NumericalEntry {
	entry := &NumericalEntry{}
	entry.ExtendBaseWidget(entry)
	return entry
}

// TypedRune receives text input events when the Entry widget is focused.
// It is called by the underlying widget.Entry when the user types a character.
// We override this to only allow digits.
func (e *NumericalEntry) TypedRune(r rune) {
	if r >= '0' && r <= '9' {
		e.Entry.TypedRune(r)
	}
}

func (e *NumericalEntry) TypedShortcut(shortcut fyne.Shortcut) {
	paste, ok := shortcut.(*fyne.ShortcutPaste)
	if !ok {
		e.Entry.TypedShortcut(shortcut)
		return
	}

	content := paste.Clipboard.Content()
	if _, err := strconv.Atoi(content); err == nil {
		e.Entry.TypedShortcut(shortcut)
	}
}

// For mobile devices we want to use the number keyboard
func (e *NumericalEntry) Keyboard() mobile.KeyboardType {
	return mobile.NumberKeyboard
}
