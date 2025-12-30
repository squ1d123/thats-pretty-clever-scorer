package storage

import (
	"database/sql"
	"fmt"
	"log"

	_ "modernc.org/sqlite"
)

type Database struct {
	DB *sql.DB
}

func InitializeDatabase() (*Database, error) {
	// Open database file
	dbPath := getDatabasePath()

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Test the connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	database := &Database{DB: db}

	// Create tables
	if err := database.createTables(); err != nil {
		return nil, fmt.Errorf("failed to create tables: %w", err)
	}

	log.Println("Database initialized successfully")
	return database, nil
}

func getDatabasePath() string {
	// For now, use a local file. In production, this should use the app's data directory
	return "./games.db"
}

func (d *Database) createTables() error {
	// Create games table
	gamesTable := `
	CREATE TABLE IF NOT EXISTS games (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		uuid TEXT UNIQUE NOT NULL,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		completed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		player_count INTEGER NOT NULL,
		winner_name TEXT,
		winner_score INTEGER,
		notes TEXT
	);`

	// Create players table
	playersTable := `
	CREATE TABLE IF NOT EXISTS players (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		game_id INTEGER NOT NULL,
		name TEXT NOT NULL,
		final_score INTEGER NOT NULL,
		winner BOOLEAN DEFAULT FALSE,
		
		-- Section totals only
		yellow_total INTEGER DEFAULT 0,
		green_total INTEGER DEFAULT 0,
		orange_total INTEGER DEFAULT 0,
		purple_total INTEGER DEFAULT 0,
		blue_total INTEGER DEFAULT 0,
		fox_count INTEGER DEFAULT 0,
		bonus INTEGER DEFAULT 0,
		
		FOREIGN KEY (game_id) REFERENCES games(id)
	);`

	// Create high scores table
	highScoresTable := `
	CREATE TABLE IF NOT EXISTS high_scores (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		game_id INTEGER NOT NULL,
		player_name TEXT NOT NULL,
		score INTEGER NOT NULL,
		achieved_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (game_id) REFERENCES games(id)
	);`

	// Create performance indexes
	indexes := []string{
		"CREATE INDEX IF NOT EXISTS idx_games_date ON games(created_at DESC);",
		"CREATE INDEX IF NOT EXISTS idx_games_score ON games(winner_score DESC);",
		"CREATE INDEX IF NOT EXISTS idx_players_game ON players(game_id);",
		"CREATE INDEX IF NOT EXISTS idx_high_scores ON high_scores(score DESC);",
		"CREATE INDEX IF NOT EXISTS idx_players_name ON players(name);",
	}

	// Execute table creation
	tables := []string{gamesTable, playersTable, highScoresTable}
	for _, table := range tables {
		if _, err := d.DB.Exec(table); err != nil {
			return fmt.Errorf("failed to create table: %w", err)
		}
	}

	// Execute index creation
	for _, index := range indexes {
		if _, err := d.DB.Exec(index); err != nil {
			return fmt.Errorf("failed to create index: %w", err)
		}
	}

	return nil
}

func (d *Database) Close() error {
	if d.DB != nil {
		return d.DB.Close()
	}
	return nil
}
