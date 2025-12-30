package storage

import (
	"time"

	"github.com/google/uuid"
	"thats-pretty-clever-scorer/internal/game"
)

// GameSession represents a complete game with all player data
type GameSession struct {
	ID          string    `json:"id"`
	CreatedAt   time.Time `json:"created_at"`
	CompletedAt time.Time `json:"completed_at"`
	Players     []*Player `json:"players"`
	Winner      *Player   `json:"winner,omitempty"`
	Notes       string    `json:"notes"`
}

// Player represents a player in a saved game
type Player struct {
	ID          int    `json:"id"`
	GameID      int    `json:"game_id"`
	Name        string `json:"name"`
	FinalScore  int    `json:"final_score"`
	Winner      bool   `json:"winner"`
	YellowTotal int    `json:"yellow_total"`
	GreenTotal  int    `json:"green_total"`
	OrangeTotal int    `json:"orange_total"`
	PurpleTotal int    `json:"purple_total"`
	BlueTotal   int    `json:"blue_total"`
	FoxCount    int    `json:"fox_count"`
	Bonus       int    `json:"bonus"`
}

// HighScore represents a high score entry
type HighScore struct {
	ID         int       `json:"id"`
	GameID     int       `json:"game_id"`
	PlayerName string    `json:"player_name"`
	Score      int       `json:"score"`
	AchievedAt time.Time `json:"achieved_at"`
}

// GameSummary represents a game for list views
type GameSummary struct {
	ID          string    `json:"id"`
	CreatedAt   time.Time `json:"created_at"`
	PlayerCount int       `json:"player_count"`
	WinnerName  string    `json:"winner_name"`
	WinnerScore int       `json:"winner_score"`
}

// SortBy defines sorting options for game queries
type SortBy string

const (
	SortByDate        SortBy = "date"
	SortByScore       SortBy = "score"
	SortByPlayerCount SortBy = "player_count"
)

// SortOrder defines sort direction
type SortOrder string

const (
	SortOrderAsc  SortOrder = "asc"
	SortOrderDesc SortOrder = "desc"
)

// GameFilter represents search and filter criteria
type GameFilter struct {
	Query      string     `json:"query"`
	PlayerName string     `json:"player_name"`
	SortBy     SortBy     `json:"sort_by"`
	SortOrder  SortOrder  `json:"sort_order"`
	DateFrom   *time.Time `json:"date_from,omitempty"`
	DateTo     *time.Time `json:"date_to,omitempty"`
}

// ToPlayer converts a game.Player to storage.Player
func ToPlayer(gamePlayer *game.Player, gameID int) *Player {
	return &Player{
		GameID:      gameID,
		Name:        gamePlayer.Name,
		FinalScore:  gamePlayer.GetTotalScore(),
		YellowTotal: gamePlayer.ScoreSheet.Yellow.Total,
		GreenTotal:  gamePlayer.ScoreSheet.Green.Total,
		OrangeTotal: gamePlayer.ScoreSheet.Orange.Total,
		PurpleTotal: gamePlayer.ScoreSheet.Purple.Total,
		BlueTotal:   gamePlayer.ScoreSheet.Blue.Total,
		FoxCount:    gamePlayer.ScoreSheet.Bonus.FoxCount,
		Bonus:       gamePlayer.ScoreSheet.Bonus.Bonus,
	}
}

// NewGameSession creates a new GameSession from game.Players
func NewGameSession(players []*game.Player, notes string) *GameSession {
	var winner *game.Player
	highestScore := -1

	// Find the winner
	for _, player := range players {
		score := player.GetTotalScore()
		if score > highestScore {
			highestScore = score
			winner = player
		}
	}

	// Create player models
	storagePlayers := make([]*Player, 0, len(players))
	for _, player := range players {
		storagePlayer := ToPlayer(player, 0) // GameID will be set after saving
		storagePlayer.Winner = (player == winner)
		storagePlayers = append(storagePlayers, storagePlayer)
	}

	return &GameSession{
		ID:          uuid.New().String(),
		CreatedAt:   time.Now(),
		CompletedAt: time.Now(),
		Players:     storagePlayers,
		Winner:      ToPlayer(winner, 0),
		Notes:       notes,
	}
}

// GetWinnerName returns the winner's name
func (gs *GameSession) GetWinnerName() string {
	if gs.Winner != nil {
		return gs.Winner.Name
	}
	return ""
}

// GetWinnerScore returns the winner's score
func (gs *GameSession) GetWinnerScore() int {
	if gs.Winner != nil {
		return gs.Winner.FinalScore
	}
	return 0
}
