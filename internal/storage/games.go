package storage

import (
	"database/sql"
	"fmt"
	"strings"
	"time"
)

// SaveGame saves a complete game session to the database
func (d *Database) SaveGame(session *GameSession) error {
	tx, err := d.DB.Begin()
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	// Insert game record
	gameResult, err := tx.Exec(`
		INSERT INTO games (uuid, created_at, completed_at, player_count, winner_name, winner_score, notes)
		VALUES (?, ?, ?, ?, ?, ?, ?)
	`, session.ID, session.CreatedAt, session.CompletedAt, len(session.Players), session.GetWinnerName(), session.GetWinnerScore(), session.Notes)

	if err != nil {
		return fmt.Errorf("failed to insert game: %w", err)
	}

	gameID, err := gameResult.LastInsertId()
	if err != nil {
		return fmt.Errorf("failed to get game ID: %w", err)
	}

	// Insert players with section totals
	for _, player := range session.Players {
		player.GameID = int(gameID) // Update the game ID for each player

		_, err := tx.Exec(`
			INSERT INTO players (game_id, name, final_score, winner, 
				yellow_total, green_total, orange_total, purple_total, blue_total, fox_count, bonus)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, gameID, player.Name, player.FinalScore, player.Winner,
			player.YellowTotal, player.GreenTotal, player.OrangeTotal,
			player.PurpleTotal, player.BlueTotal, player.FoxCount, player.Bonus)

		if err != nil {
			return fmt.Errorf("failed to insert player %s: %w", player.Name, err)
		}
	}

	// Add to high scores table (only for the winner)
	if session.Winner != nil {
		_, err := tx.Exec(`
			INSERT INTO high_scores (game_id, player_name, score, achieved_at)
			VALUES (?, ?, ?, ?)
		`, gameID, session.Winner.Name, session.Winner.FinalScore, session.CompletedAt)

		if err != nil {
			return fmt.Errorf("failed to insert high score: %w", err)
		}
	}

	return tx.Commit()
}

// GetGameByID retrieves a complete game session by its ID
func (d *Database) GetGameByID(gameID string) (*GameSession, error) {
	// Get game details
	var gameSession GameSession
	err := d.DB.QueryRow(`
		SELECT uuid, created_at, completed_at, player_count, winner_name, winner_score, notes
		FROM games WHERE uuid = ?
	`, gameID).Scan(&gameSession.ID, &gameSession.CreatedAt, &gameSession.CompletedAt,
		new(int), &gameSession.Winner, new(int), &gameSession.Notes)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("game not found")
		}
		return nil, fmt.Errorf("failed to get game: %w", err)
	}

	// Get players for this game
	players, err := d.getPlayersByGameID(gameID)
	if err != nil {
		return nil, fmt.Errorf("failed to get players: %w", err)
	}

	gameSession.Players = players

	// Find winner
	for _, player := range players {
		if player.Winner {
			gameSession.Winner = player
			break
		}
	}

	return &gameSession, nil
}

// getPlayersByGameID retrieves all players for a given game
func (d *Database) getPlayersByGameID(gameID string) ([]*Player, error) {
	rows, err := d.DB.Query(`
		SELECT id, game_id, name, final_score, winner,
			   yellow_total, green_total, orange_total, purple_total, blue_total, fox_count, bonus
		FROM players 
		WHERE game_id = (SELECT id FROM games WHERE uuid = ?)
		ORDER BY final_score DESC
	`, gameID)

	if err != nil {
		return nil, fmt.Errorf("failed to query players: %w", err)
	}
	defer rows.Close()

	var players []*Player
	for rows.Next() {
		player := &Player{}
		err := rows.Scan(&player.ID, &player.GameID, &player.Name, &player.FinalScore, &player.Winner,
			&player.YellowTotal, &player.GreenTotal, &player.OrangeTotal,
			&player.PurpleTotal, &player.BlueTotal, &player.FoxCount, &player.Bonus)

		if err != nil {
			return nil, fmt.Errorf("failed to scan player: %w", err)
		}

		players = append(players, player)
	}

	return players, nil
}

// GetGames returns a paginated list of games with optional filtering
func (d *Database) GetGames(filter GameFilter, limit, offset int) ([]*GameSummary, int, error) {
	whereClause := ""
	args := []interface{}{}

	// Build WHERE clause
	conditions := []string{}

	if filter.Query != "" {
		conditions = append(conditions, "(winner_name LIKE ? OR EXISTS (SELECT 1 FROM players p WHERE p.game_id = games.id AND p.name LIKE ?))")
		args = append(args, "%"+filter.Query+"%", "%"+filter.Query+"%")
	}

	if filter.PlayerName != "" {
		conditions = append(conditions, "EXISTS (SELECT 1 FROM players p WHERE p.game_id = games.id AND p.name LIKE ?)")
		args = append(args, "%"+filter.PlayerName+"%")
	}

	if filter.DateFrom != nil {
		conditions = append(conditions, "created_at >= ?")
		args = append(args, filter.DateFrom)
	}

	if filter.DateTo != nil {
		conditions = append(conditions, "created_at <= ?")
		args = append(args, filter.DateTo)
	}

	if len(conditions) > 0 {
		whereClause = "WHERE " + strings.Join(conditions, " AND ")
	}

	// Build ORDER BY clause
	orderClause := "ORDER BY created_at DESC" // default
	switch filter.SortBy {
	case SortByScore:
		orderClause = "ORDER BY winner_score " + string(filter.SortOrder)
	case SortByPlayerCount:
		orderClause = "ORDER BY player_count " + string(filter.SortOrder)
	case SortByDate:
		if filter.SortOrder == SortOrderAsc {
			orderClause = "ORDER BY created_at ASC"
		}
	}

	// Get total count
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM games %s", whereClause)
	var total int
	err := d.DB.QueryRow(countQuery, args...).Scan(&total)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count games: %w", err)
	}

	// Get paginated results
	query := fmt.Sprintf(`
		SELECT uuid, created_at, player_count, winner_name, winner_score 
		FROM games %s %s
		LIMIT ? OFFSET ?
	`, whereClause, orderClause)

	args = append(args, limit, offset)
	rows, err := d.DB.Query(query, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to query games: %w", err)
	}
	defer rows.Close()

	var games []*GameSummary
	for rows.Next() {
		game := &GameSummary{}
		err := rows.Scan(&game.ID, &game.CreatedAt, &game.PlayerCount, &game.WinnerName, &game.WinnerScore)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan game: %w", err)
		}
		games = append(games, game)
	}

	return games, total, nil
}

// DeleteGame deletes a game and all related data
func (d *Database) DeleteGame(gameID string) error {
	tx, err := d.DB.Begin()
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	// Get game database ID
	var dbGameID int
	err = tx.QueryRow("SELECT id FROM games WHERE uuid = ?", gameID).Scan(&dbGameID)
	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("game not found")
		}
		return fmt.Errorf("failed to get game ID: %w", err)
	}

	// Delete related records in order
	_, err = tx.Exec("DELETE FROM high_scores WHERE game_id = ?", dbGameID)
	if err != nil {
		return fmt.Errorf("failed to delete high scores: %w", err)
	}

	_, err = tx.Exec("DELETE FROM players WHERE game_id = ?", dbGameID)
	if err != nil {
		return fmt.Errorf("failed to delete players: %w", err)
	}

	_, err = tx.Exec("DELETE FROM games WHERE id = ?", dbGameID)
	if err != nil {
		return fmt.Errorf("failed to delete game: %w", err)
	}

	return tx.Commit()
}

// GetDatabaseStats returns statistics about the database
func (d *Database) GetDatabaseStats() (map[string]interface{}, error) {
	stats := make(map[string]interface{})

	// Total games
	var totalGames int
	err := d.DB.QueryRow("SELECT COUNT(*) FROM games").Scan(&totalGames)
	if err != nil {
		return nil, fmt.Errorf("failed to get total games: %w", err)
	}
	stats["total_games"] = totalGames

	// Earliest and latest game dates
	var earliestGame, latestGame sql.NullTime
	d.DB.QueryRow("SELECT MIN(created_at) FROM games").Scan(&earliestGame)
	d.DB.QueryRow("SELECT MAX(created_at) FROM games").Scan(&latestGame)
	stats["earliest_game"] = earliestGame
	stats["latest_game"] = latestGame

	// Average winning score
	var avgScore sql.NullFloat64
	d.DB.QueryRow("SELECT AVG(winner_score) FROM games WHERE winner_score IS NOT NULL").Scan(&avgScore)
	stats["average_winning_score"] = avgScore

	// Highest score
	var highestScore sql.NullInt64
	d.DB.QueryRow("SELECT MAX(winner_score) FROM games").Scan(&highestScore)
	stats["highest_score"] = highestScore

	return stats, nil
}

// DeleteOldGames deletes games older than specified date
func (d *Database) DeleteOldGames(cutoffDate time.Time) (int, error) {
	tx, err := d.DB.Begin()
	if err != nil {
		return 0, fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	// Get games to be deleted
	rows, err := tx.Query("SELECT id FROM games WHERE created_at < ?", cutoffDate)
	if err != nil {
		return 0, fmt.Errorf("failed to get old games: %w", err)
	}
	defer rows.Close()

	var gameIDs []int
	for rows.Next() {
		var gameID int
		err := rows.Scan(&gameID)
		if err != nil {
			return 0, fmt.Errorf("failed to scan game ID: %w", err)
		}
		gameIDs = append(gameIDs, gameID)
	}

	// Delete related records
	for _, gameID := range gameIDs {
		_, err := tx.Exec("DELETE FROM high_scores WHERE game_id = ?", gameID)
		if err != nil {
			return 0, fmt.Errorf("failed to delete high scores: %w", err)
		}

		_, err = tx.Exec("DELETE FROM players WHERE game_id = ?", gameID)
		if err != nil {
			return 0, fmt.Errorf("failed to delete players: %w", err)
		}

		_, err = tx.Exec("DELETE FROM games WHERE id = ?", gameID)
		if err != nil {
			return 0, fmt.Errorf("failed to delete game: %w", err)
		}
	}

	return len(gameIDs), tx.Commit()
}

// DeleteLowScoringGames deletes games where winning score is below threshold
func (d *Database) DeleteLowScoringGames(threshold int) (int, error) {
	tx, err := d.DB.Begin()
	if err != nil {
		return 0, fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	// Get games to be deleted
	rows, err := tx.Query("SELECT id FROM games WHERE winner_score < ?", threshold)
	if err != nil {
		return 0, fmt.Errorf("failed to get low scoring games: %w", err)
	}
	defer rows.Close()

	var gameIDs []int
	for rows.Next() {
		var gameID int
		err := rows.Scan(&gameID)
		if err != nil {
			return 0, fmt.Errorf("failed to scan game ID: %w", err)
		}
		gameIDs = append(gameIDs, gameID)
	}

	// Delete related records
	for _, gameID := range gameIDs {
		_, err := tx.Exec("DELETE FROM high_scores WHERE game_id = ?", gameID)
		if err != nil {
			return 0, fmt.Errorf("failed to delete high scores: %w", err)
		}

		_, err = tx.Exec("DELETE FROM players WHERE game_id = ?", gameID)
		if err != nil {
			return 0, fmt.Errorf("failed to delete players: %w", err)
		}

		_, err = tx.Exec("DELETE FROM games WHERE id = ?", gameID)
		if err != nil {
			return 0, fmt.Errorf("failed to delete game: %w", err)
		}
	}

	return len(gameIDs), tx.Commit()
}

// DeleteGamesInDateRange deletes games within specified date range
func (d *Database) DeleteGamesInDateRange(startDate, endDate time.Time) (int, error) {
	tx, err := d.DB.Begin()
	if err != nil {
		return 0, fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	// Get games to be deleted
	rows, err := tx.Query("SELECT id FROM games WHERE created_at BETWEEN ? AND ?", startDate, endDate)
	if err != nil {
		return 0, fmt.Errorf("failed to get games in date range: %w", err)
	}
	defer rows.Close()

	var gameIDs []int
	for rows.Next() {
		var gameID int
		err := rows.Scan(&gameID)
		if err != nil {
			return 0, fmt.Errorf("failed to scan game ID: %w", err)
		}
		gameIDs = append(gameIDs, gameID)
	}

	// Delete related records
	for _, gameID := range gameIDs {
		_, err := tx.Exec("DELETE FROM high_scores WHERE game_id = ?", gameID)
		if err != nil {
			return 0, fmt.Errorf("failed to delete high scores: %w", err)
		}

		_, err = tx.Exec("DELETE FROM players WHERE game_id = ?", gameID)
		if err != nil {
			return 0, fmt.Errorf("failed to delete players: %w", err)
		}

		_, err = tx.Exec("DELETE FROM games WHERE id = ?", gameID)
		if err != nil {
			return 0, fmt.Errorf("failed to delete game: %w", err)
		}
	}

	return len(gameIDs), tx.Commit()
}
