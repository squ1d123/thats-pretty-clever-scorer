package ui

import (
	"sync"
	"time"

	"fyne.io/fyne/v2"
)

// Debouncer helps reduce unnecessary UI refreshes
type Debouncer struct {
	mu     sync.Mutex
	timer  *time.Timer
	action func()
}

// NewDebouncer creates a new debouncer
func NewDebouncer() *Debouncer {
	return &Debouncer{}
}

// Debounce executes the action after delay, canceling previous pending actions
func (d *Debouncer) Debounce(delay time.Duration, action func()) {
	d.mu.Lock()
	defer d.mu.Unlock()

	// Cancel existing timer
	if d.timer != nil {
		d.timer.Stop()
	}

	// Schedule new action
	d.timer = time.AfterFunc(delay, func() {
		// Execute on UI thread
		fyne.Do(action)
	})
}
