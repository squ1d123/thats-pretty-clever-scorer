package storage

import (
	"fmt"
)

// GetHighScores returns the top high scores
func (d *Database) GetHighScores(limit int) ([]*HighScore, error) {
	query := `
		SELECT hs.id, hs.game_id, hs.player_name, hs.score, hs.achieved_at
		FROM high_scores hs
		ORDER BY hs.score DESC, hs.achieved_at ASC
		LIMIT ?
	`

	rows, err := d.DB.Query(query, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to query high scores: %w", err)
	}
	defer rows.Close()

	var highScores []*HighScore
	for rows.Next() {
		hs := &HighScore{}
		err := rows.Scan(&hs.ID, &hs.GameID, &hs.PlayerName, &hs.Score, &hs.AchievedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan high score: %w", err)
		}
		highScores = append(highScores, hs)
	}

	return highScores, nil
}

// GetPlayerHighScores returns high scores for a specific player
func (d *Database) GetPlayerHighScores(playerName string, limit int) ([]*HighScore, error) {
	query := `
		SELECT hs.id, hs.game_id, hs.player_name, hs.score, hs.achieved_at
		FROM high_scores hs
		WHERE hs.player_name LIKE ?
		ORDER BY hs.score DESC, hs.achieved_at ASC
		LIMIT ?
	`

	rows, err := d.DB.Query(query, playerName, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to query player high scores: %w", err)
	}
	defer rows.Close()

	var highScores []*HighScore
	for rows.Next() {
		hs := &HighScore{}
		err := rows.Scan(&hs.ID, &hs.GameID, &hs.PlayerName, &hs.Score, &hs.AchievedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan player high score: %w", err)
		}
		highScores = append(highScores, hs)
	}

	return highScores, nil
}

// GetBestSectionScores returns the best scores for each color section
func (d *Database) GetBestSectionScores(limit int) (map[string][]*Player, error) {
	result := make(map[string][]*Player)

	sections := map[string]string{
		"yellow": "yellow_total",
		"green":  "green_total",
		"orange": "orange_total",
		"purple": "purple_total",
		"blue":   "blue_total",
		"bonus":  "bonus",
	}

	for sectionName, columnName := range sections {
		query := fmt.Sprintf(`
			SELECT name, %s, achieved_at
			FROM players p
			JOIN games g ON p.game_id = g.id
			WHERE %s > 0
			ORDER BY %s DESC, g.created_at ASC
			LIMIT ?
		`, columnName, columnName, columnName)

		rows, err := d.DB.Query(query, limit)
		if err != nil {
			return nil, fmt.Errorf("failed to query best %s scores: %w", sectionName, err)
		}

		var players []*Player
		for rows.Next() {
			player := &Player{}
			var achievedAt string
			err := rows.Scan(&player.Name, getSectionScorePointer(player, sectionName), &achievedAt)
			if err != nil {
				rows.Close()
				return nil, fmt.Errorf("failed to scan %s player: %w", sectionName, err)
			}
			players = append(players, player)
		}
		rows.Close()

		result[sectionName] = players
	}

	return result, nil
}

// getSectionScorePointer returns a pointer to the appropriate score field based on section
func getSectionScorePointer(player *Player, section string) interface{} {
	switch section {
	case "yellow":
		return &player.YellowTotal
	case "green":
		return &player.GreenTotal
	case "orange":
		return &player.OrangeTotal
	case "purple":
		return &player.PurpleTotal
	case "blue":
		return &player.BlueTotal
	case "bonus":
		return &player.Bonus
	default:
		return &player.FinalScore
	}
}

// IsHighScore checks if a score is among the top scores
func (d *Database) IsHighScore(score int, limit int) (bool, int, error) {
	// Get the lowest score in current top N
	query := `
		SELECT MIN(score)
		FROM (
			SELECT score
			FROM high_scores
			ORDER BY score DESC, achieved_at ASC
			LIMIT ?
		) as top_scores
	`

	var lowestScore *int
	err := d.DB.QueryRow(query, limit).Scan(&lowestScore)
	if err != nil {
		return false, 0, fmt.Errorf("failed to check high score: %w", err)
	}

	// If we have fewer than N scores, any score qualifies
	if lowestScore == nil {
		return true, 0, nil
	}

	return score >= *lowestScore, *lowestScore, nil
}

// GetPlayerStatistics returns detailed statistics for a player
func (d *Database) GetPlayerStatistics(playerName string) (map[string]interface{}, error) {
	stats := make(map[string]interface{})

	// Total games played
	var totalGames int
	err := d.DB.QueryRow(`
		SELECT COUNT(*)
		FROM players p
		WHERE p.name LIKE ?
	`, playerName).Scan(&totalGames)
	if err != nil {
		return nil, fmt.Errorf("failed to get total games: %w", err)
	}
	stats["total_games"] = totalGames

	// Games won
	var gamesWon int
	err = d.DB.QueryRow(`
		SELECT COUNT(*)
		FROM players p
		WHERE p.name LIKE ? AND p.winner = TRUE
	`, playerName).Scan(&gamesWon)
	if err != nil {
		return nil, fmt.Errorf("failed to get games won: %w", err)
	}
	stats["games_won"] = gamesWon

	// Win rate
	if totalGames > 0 {
		stats["win_rate"] = float64(gamesWon) / float64(totalGames) * 100
	} else {
		stats["win_rate"] = 0.0
	}

	// Best score
	var bestScore *int
	err = d.DB.QueryRow(`
		SELECT MAX(final_score)
		FROM players p
		WHERE p.name LIKE ?
	`, playerName).Scan(&bestScore)
	if err != nil {
		return nil, fmt.Errorf("failed to get best score: %w", err)
	}
	stats["best_score"] = bestScore

	// Average score
	var avgScore *float64
	err = d.DB.QueryRow(`
		SELECT AVG(final_score)
		FROM players p
		WHERE p.name LIKE ?
	`, playerName).Scan(&avgScore)
	if err != nil {
		return nil, fmt.Errorf("failed to get average score: %w", err)
	}
	stats["average_score"] = avgScore

	// Best section scores
	sections := map[string]string{
		"best_yellow": "yellow_total",
		"best_green":  "green_total",
		"best_orange": "orange_total",
		"best_purple": "purple_total",
		"best_blue":   "blue_total",
		"best_bonus":  "bonus",
	}

	for statName, columnName := range sections {
		var best *int
		err = d.DB.QueryRow(fmt.Sprintf(`
			SELECT MAX(%s)
			FROM players p
			WHERE p.name LIKE ?
		`, columnName), playerName).Scan(&best)
		if err != nil {
			return nil, fmt.Errorf("failed to get best %s: %w", columnName, err)
		}
		stats[statName] = best
	}

	return stats, nil
}
