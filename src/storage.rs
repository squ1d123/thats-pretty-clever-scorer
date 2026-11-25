use std::{
    fs,
    path::{Path, PathBuf},
    sync::Mutex,
};

use chrono::{DateTime, NaiveDateTime, Utc};
use rusqlite::{Connection, OptionalExtension, params, params_from_iter};

use crate::models::{
    DatabaseStats, GameSession, GameSummary, GameVersion, HighScore, NamedCount, Player,
    PlayerAverage, ScoreSheet, StatsTimeRange, WinPercentage,
};

pub type DbResult<T> = Result<T, String>;

#[derive(Clone, Debug)]
pub struct GameHistoryFilter {
    pub query: String,
    pub player_name: Option<String>,
    pub sort_by: String,
    pub sort_order: String,
    pub game_version: Option<GameVersion>,
}

impl Default for GameHistoryFilter {
    fn default() -> Self {
        Self {
            query: String::new(),
            player_name: None,
            sort_by: "date".to_string(),
            sort_order: "desc".to_string(),
            game_version: None,
        }
    }
}

fn now_string() -> String {
    Utc::now().format("%Y-%m-%d %H:%M:%S").to_string()
}

fn id_string() -> String {
    Utc::now().timestamp_millis().to_string()
}

fn config_path() -> PathBuf {
    let base = dirs::config_dir()
        .or_else(|| dirs::home_dir().map(|home| home.join(".config")))
        .unwrap_or_else(|| PathBuf::from("."));
    let dir = base.join("ganz-clever-scorer");
    let _ = fs::create_dir_all(&dir);
    dir.join("database_path.txt")
}

fn default_database_path() -> PathBuf {
    let base = dirs::document_dir()
        .or_else(dirs::data_dir)
        .or_else(dirs::home_dir)
        .unwrap_or_else(|| PathBuf::from("."));
    base.join("games.db")
}

pub struct Database {
    connection: Mutex<Connection>,
    path: PathBuf,
}

impl Database {
    pub fn open() -> DbResult<Self> {
        let path = Self::custom_db_path().unwrap_or_else(default_database_path);
        Self::open_at(path)
    }

    pub fn open_at(path: PathBuf) -> DbResult<Self> {
        let path = if path.is_dir() {
            path.join("games.db")
        } else {
            path
        };
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent).map_err(|error| error.to_string())?;
        }
        let connection = Connection::open(&path).map_err(|error| error.to_string())?;
        let database = Self {
            connection: Mutex::new(connection),
            path,
        };
        database.create_schema()?;
        Ok(database)
    }

    pub fn path(&self) -> &Path {
        &self.path
    }

    pub fn custom_db_path() -> Option<PathBuf> {
        let value = fs::read_to_string(config_path()).ok()?;
        let value = value.trim();
        if value.is_empty() {
            None
        } else {
            Some(PathBuf::from(value))
        }
    }

    pub fn set_custom_db_path(value: &str) -> DbResult<()> {
        let path = config_path();
        if value.trim().is_empty() {
            match fs::remove_file(&path) {
                Ok(()) => Ok(()),
                Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(()),
                Err(error) => Err(error.to_string()),
            }
        } else {
            fs::write(path, value.trim()).map_err(|error| error.to_string())
        }
    }

    pub fn uses_custom_path() -> bool {
        Self::custom_db_path().is_some()
    }

    fn create_schema(&self) -> DbResult<()> {
        let connection = self.connection.lock().map_err(|error| error.to_string())?;
        connection
            .execute_batch(
                "
                CREATE TABLE IF NOT EXISTS games (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    uuid TEXT UNIQUE NOT NULL,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    completed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    player_count INTEGER NOT NULL,
                    winner_name TEXT,
                    winner_score INTEGER,
                    notes TEXT,
                    game_version TEXT DEFAULT 'v1'
                );
                CREATE TABLE IF NOT EXISTS players (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    game_id INTEGER NOT NULL,
                    name TEXT NOT NULL,
                    final_score INTEGER NOT NULL,
                    winner BOOLEAN DEFAULT FALSE,
                    yellow_total INTEGER DEFAULT 0,
                    green_total INTEGER DEFAULT 0,
                    orange_total INTEGER DEFAULT 0,
                    purple_total INTEGER DEFAULT 0,
                    blue_total INTEGER DEFAULT 0,
                    fox_count INTEGER DEFAULT 0,
                    bonus INTEGER DEFAULT 0,
                    FOREIGN KEY (game_id) REFERENCES games(id)
                );
                CREATE TABLE IF NOT EXISTS high_scores (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    game_id INTEGER NOT NULL,
                    player_name TEXT NOT NULL,
                    score INTEGER NOT NULL,
                    achieved_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (game_id) REFERENCES games(id)
                );
                CREATE INDEX IF NOT EXISTS idx_games_date ON games(created_at DESC);
                CREATE INDEX IF NOT EXISTS idx_games_score ON games(winner_score DESC);
                CREATE INDEX IF NOT EXISTS idx_players_game ON players(game_id);
                CREATE INDEX IF NOT EXISTS idx_high_scores ON high_scores(score DESC);
                CREATE INDEX IF NOT EXISTS idx_players_name ON players(name);
                ",
            )
            .map_err(|error| error.to_string())?;
        drop(connection);
        let connection = self.connection.lock().map_err(|error| error.to_string())?;
        Self::ensure_version_column(&connection)
    }

    fn ensure_version_column(connection: &Connection) -> DbResult<()> {
        let mut statement = connection
            .prepare("PRAGMA table_info(games)")
            .map_err(|error| error.to_string())?;
        let columns = statement
            .query_map([], |row| row.get::<_, String>(1))
            .map_err(|error| error.to_string())?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|error| error.to_string())?;
        if !columns.iter().any(|column| column == "game_version") {
            connection
                .execute(
                    "ALTER TABLE games ADD COLUMN game_version TEXT DEFAULT 'v1'",
                    [],
                )
                .map_err(|error| error.to_string())?;
        }
        Ok(())
    }

    pub fn save_game(&self, session: &mut GameSession, notes: &str) -> DbResult<i64> {
        let mut connection = self.connection.lock().map_err(|error| error.to_string())?;
        Self::ensure_version_column(&connection)?;
        let now = now_string();
        let id = session.id.clone().unwrap_or_else(id_string);
        let created_at = session.created_at.clone().unwrap_or_else(|| now.clone());
        let completed_at = session.completed_at.clone().unwrap_or_else(|| now.clone());
        let winner_index = session.find_winner();
        let winner_name = winner_index
            .and_then(|index| session.players.get(index))
            .map(|player| player.name.clone());
        let winner_score = winner_index
            .and_then(|index| session.players.get(index))
            .map(Player::total_score)
            .unwrap_or(0);

        session.id = Some(id.clone());
        session.created_at = Some(created_at.clone());
        session.completed_at = Some(completed_at.clone());
        session.winner = winner_name.clone();
        session.notes = notes.to_string();

        let transaction = connection
            .transaction()
            .map_err(|error| error.to_string())?;
        transaction
            .execute(
                "INSERT INTO games (uuid, created_at, completed_at, player_count, winner_name, winner_score, notes, game_version)
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
                params![
                    id,
                    created_at,
                    completed_at,
                    session.players.len() as i64,
                    winner_name,
                    winner_score,
                    notes,
                    session.game_version.id()
                ],
            )
            .map_err(|error| error.to_string())?;
        let game_id = transaction.last_insert_rowid();

        for player in &session.players {
            let sheet = &player.score_sheet;
            transaction
                .execute(
                    "INSERT INTO players (game_id, name, final_score, winner, yellow_total, green_total,
                     orange_total, purple_total, blue_total, fox_count, bonus)
                     VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11)",
                    params![
                        game_id,
                        player.name,
                        player.total_score(),
                        i64::from(Some(&player.name) == winner_name.as_ref()),
                        sheet.yellow,
                        sheet.green,
                        sheet.orange,
                        sheet.purple,
                        sheet.blue,
                        sheet.fox_count,
                        sheet.bonus,
                    ],
                )
                .map_err(|error| error.to_string())?;
            transaction
                .execute(
                    "INSERT INTO high_scores (game_id, player_name, score, achieved_at) VALUES (?1, ?2, ?3, ?4)",
                    params![game_id, player.name, player.total_score(), now],
                )
                .map_err(|error| error.to_string())?;
        }
        transaction.commit().map_err(|error| error.to_string())?;
        Ok(game_id)
    }

    fn version_components(version: Option<GameVersion>) -> (String, Vec<GameVersion>) {
        match version {
            Some(GameVersion::All) | None => (String::new(), Vec::new()),
            Some(value) => (" AND g.game_version = ?".to_string(), vec![value]),
        }
    }

    pub fn get_games(&self, filter: &GameHistoryFilter) -> DbResult<Vec<GameSummary>> {
        let connection = self.connection.lock().map_err(|error| error.to_string())?;
        Self::ensure_version_column(&connection)?;
        let mut values: Vec<String> = Vec::new();
        let mut sql = String::from("SELECT DISTINCT g.* FROM games g");
        if let Some(player) = &filter.player_name {
            sql.push_str(" JOIN players p ON g.id = p.game_id");
            values.push(format!("%{player}%"));
            sql.push_str(" WHERE p.name LIKE ?");
        } else {
            sql.push_str(" WHERE 1 = 1");
        }
        if !filter.query.is_empty() {
            sql.push_str(" AND (g.winner_name LIKE ? OR g.notes LIKE ?)");
            let pattern = format!("%{}%", filter.query);
            values.push(pattern.clone());
            values.push(pattern);
        }
        if let Some(GameVersion::V1 | GameVersion::V2) = filter.game_version {
            sql.push_str(" AND g.game_version = ?");
            values.push(filter.game_version.unwrap().id().to_string());
        }
        let column = match filter.sort_by.as_str() {
            "score" => "g.winner_score",
            "player_count" => "g.player_count",
            _ => "g.created_at",
        };
        let order = if filter.sort_order.eq_ignore_ascii_case("asc") {
            "ASC"
        } else {
            "DESC"
        };
        sql.push_str(&format!(" ORDER BY {column} {order}"));

        let mut statement = connection
            .prepare(&sql)
            .map_err(|error| error.to_string())?;
        let rows = statement
            .query_map(params_from_iter(values.iter().map(String::as_str)), |row| {
                let version: Option<String> = row.get(8)?;
                Ok(GameSummary {
                    id: row.get(1)?,
                    db_id: row.get(0)?,
                    created_at: row.get(2)?,
                    player_count: row.get::<_, Option<i64>>(4)?.unwrap_or(0),
                    winner_name: row.get::<_, Option<String>>(5)?.unwrap_or_default(),
                    winner_score: row.get::<_, Option<i64>>(6)?.unwrap_or(0),
                    game_version: GameVersion::from_id(version.as_deref()),
                })
            })
            .map_err(|error| error.to_string())?;
        rows.collect::<Result<Vec<_>, _>>()
            .map_err(|error| error.to_string())
    }

    fn build_game_session(connection: &Connection, game_id: i64) -> DbResult<GameSession> {
        let (uuid, created_at, completed_at, notes, version): (
            String,
            Option<String>,
            Option<String>,
            Option<String>,
            Option<String>,
        ) = connection
            .query_row(
                "SELECT uuid, created_at, completed_at, notes, game_version FROM games WHERE id = ?1",
                params![game_id],
                |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?, row.get(3)?, row.get(4)?)),
            )
            .map_err(|error| error.to_string())?;
        let mut statement = connection
            .prepare(
                "SELECT name, yellow_total, green_total, orange_total, purple_total, blue_total, fox_count, bonus
                 FROM players WHERE game_id = ?1 ORDER BY id",
            )
            .map_err(|error| error.to_string())?;
        let players = statement
            .query_map(params![game_id], |row| {
                let name: String = row.get(0)?;
                let sheet = ScoreSheet {
                    yellow: row.get::<_, Option<i64>>(1)?.unwrap_or(0),
                    green: row.get::<_, Option<i64>>(2)?.unwrap_or(0),
                    orange: row.get::<_, Option<i64>>(3)?.unwrap_or(0),
                    purple: row.get::<_, Option<i64>>(4)?.unwrap_or(0),
                    blue: row.get::<_, Option<i64>>(5)?.unwrap_or(0),
                    fox_count: row.get::<_, Option<i64>>(6)?.unwrap_or(0),
                    bonus: row.get::<_, Option<i64>>(7)?.unwrap_or(0),
                    ..Default::default()
                };
                let mut player = Player::new(name);
                player.score_sheet = sheet;
                Ok(player)
            })
            .map_err(|error| error.to_string())?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|error| error.to_string())?;
        Ok(GameSession {
            id: Some(uuid),
            created_at,
            completed_at,
            players,
            winner: None,
            notes: notes.unwrap_or_default(),
            game_version: GameVersion::from_id(version.as_deref()),
        })
    }

    pub fn get_game_details(&self, uuid: &str) -> DbResult<Option<GameSession>> {
        let connection = self.connection.lock().map_err(|error| error.to_string())?;
        let game_id: Option<i64> = connection
            .query_row(
                "SELECT id FROM games WHERE uuid = ?1",
                params![uuid],
                |row| row.get(0),
            )
            .optional()
            .map_err(|error| error.to_string())?;
        match game_id {
            Some(id) => Self::build_game_session(&connection, id).map(Some),
            None => Ok(None),
        }
    }

    pub fn get_game_details_by_id(&self, game_id: i64) -> DbResult<Option<GameSession>> {
        let connection = self.connection.lock().map_err(|error| error.to_string())?;
        Self::build_game_session(&connection, game_id)
            .map(Some)
            .map_err(|error| error.to_string())
    }

    pub fn get_high_scores(
        &self,
        limit: i64,
        version: Option<GameVersion>,
    ) -> DbResult<Vec<HighScore>> {
        let connection = self.connection.lock().map_err(|error| error.to_string())?;
        let (suffix, version_values) = Self::version_components(version);
        let mut values: Vec<String> = version_values
            .iter()
            .map(|value| value.id().to_string())
            .collect();
        values.push(limit.to_string());
        let sql = format!(
            "SELECT hs.id, hs.game_id, hs.player_name, hs.score, hs.achieved_at
             FROM high_scores hs JOIN games g ON hs.game_id = g.id
             WHERE 1 = 1{suffix}
             ORDER BY hs.score DESC LIMIT ?"
        );
        let mut statement = connection
            .prepare(&sql)
            .map_err(|error| error.to_string())?;
        statement
            .query_map(params_from_iter(values.iter().map(String::as_str)), |row| {
                Ok(HighScore {
                    id: Some(row.get(0)?),
                    game_id: row.get(1)?,
                    player_name: row.get(2)?,
                    score: row.get(3)?,
                    achieved_at: row.get(4)?,
                })
            })
            .map_err(|error| error.to_string())?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|error| error.to_string())
    }

    pub fn get_recent_player_names(&self, limit: i64) -> DbResult<Vec<String>> {
        let connection = self.connection.lock().map_err(|error| error.to_string())?;
        let mut statement = connection
            .prepare(
                "SELECT DISTINCT name FROM players
                 ORDER BY (SELECT MAX(id) FROM players p2 WHERE p2.name = players.name) DESC LIMIT ?",
            )
            .map_err(|error| error.to_string())?;
        statement
            .query_map(params![limit], |row| row.get(0))
            .map_err(|error| error.to_string())?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|error| error.to_string())
    }

    pub fn search_player_names(&self, query: &str, limit: i64) -> DbResult<Vec<String>> {
        let connection = self.connection.lock().map_err(|error| error.to_string())?;
        let mut statement = connection
            .prepare("SELECT DISTINCT name FROM players WHERE name LIKE ? ORDER BY name LIMIT ?")
            .map_err(|error| error.to_string())?;
        statement
            .query_map(params![format!("%{query}%"), limit], |row| row.get(0))
            .map_err(|error| error.to_string())?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|error| error.to_string())
    }

    pub fn database_stats(&self, version: Option<GameVersion>) -> DbResult<DatabaseStats> {
        let connection = self.connection.lock().map_err(|error| error.to_string())?;
        let (suffix, version_values) = Self::version_components(version);
        let values: Vec<String> = version_values
            .iter()
            .map(|value| value.id().to_string())
            .collect();
        let game_sql = format!("SELECT COUNT(*) FROM games g WHERE 1 = 1{suffix}");
        let games: i64 = connection
            .query_row(
                &game_sql,
                params_from_iter(values.iter().map(String::as_str)),
                |row| row.get(0),
            )
            .map_err(|error| error.to_string())?;
        let high_score_sql = if version_values.is_empty() {
            "SELECT COALESCE(MAX(score), 0) FROM high_scores".to_string()
        } else {
            "SELECT COALESCE(MAX(hs.score), 0) FROM high_scores hs JOIN games g ON hs.game_id = g.id WHERE g.game_version = ?"
                .to_string()
        };
        let highest_score: i64 = connection
            .query_row(
                &high_score_sql,
                params_from_iter(values.iter().map(String::as_str)),
                |row| row.get(0),
            )
            .map_err(|error| error.to_string())?;
        let player_sql = if version_values.is_empty() {
            "SELECT COUNT(DISTINCT name) FROM players".to_string()
        } else {
            "SELECT COUNT(DISTINCT p.name) FROM players p JOIN games g ON p.game_id = g.id WHERE g.game_version = ?"
                .to_string()
        };
        let players: i64 = connection
            .query_row(
                &player_sql,
                params_from_iter(values.iter().map(String::as_str)),
                |row| row.get(0),
            )
            .map_err(|error| error.to_string())?;
        Ok(DatabaseStats {
            games,
            players,
            highest_score,
        })
    }

    pub fn delete_game(&self, game_id: i64) -> DbResult<()> {
        let mut connection = self.connection.lock().map_err(|error| error.to_string())?;
        let transaction = connection
            .transaction()
            .map_err(|error| error.to_string())?;
        transaction
            .execute("DELETE FROM players WHERE game_id = ?1", params![game_id])
            .map_err(|error| error.to_string())?;
        transaction
            .execute(
                "DELETE FROM high_scores WHERE game_id = ?1",
                params![game_id],
            )
            .map_err(|error| error.to_string())?;
        transaction
            .execute("DELETE FROM games WHERE id = ?1", params![game_id])
            .map_err(|error| error.to_string())?;
        transaction.commit().map_err(|error| error.to_string())?;
        Ok(())
    }

    pub fn delete_all_games(&self) -> DbResult<()> {
        let connection = self.connection.lock().map_err(|error| error.to_string())?;
        connection
            .execute_batch("DELETE FROM players; DELETE FROM high_scores; DELETE FROM games;")
            .map_err(|error| error.to_string())
    }

    pub fn clear_high_scores(&self) -> DbResult<()> {
        let connection = self.connection.lock().map_err(|error| error.to_string())?;
        connection
            .execute("DELETE FROM high_scores", [])
            .map_err(|error| error.to_string())?;
        Ok(())
    }

    fn months_window(range: StatsTimeRange) -> String {
        match range.months() {
            Some(months) => {
                format!(" AND datetime(created_at) >= datetime('now', '-{months} months')")
            }
            None => String::new(),
        }
    }

    pub fn games_per_month(
        &self,
        range: StatsTimeRange,
        version: Option<GameVersion>,
    ) -> DbResult<Vec<NamedCount>> {
        let connection = self.connection.lock().map_err(|error| error.to_string())?;
        let (suffix, version_values) = Self::version_components(version);
        let sql = format!(
            "SELECT strftime('%Y-%m', substr(created_at, 1, 19)) AS month, COUNT(*)
             FROM games g WHERE 1 = 1{suffix}{}
             GROUP BY month ORDER BY month",
            Self::months_window(range)
        );
        let values: Vec<String> = version_values
            .iter()
            .map(|value| value.id().to_string())
            .collect();
        connection
            .prepare(&sql)
            .map_err(|error| error.to_string())?
            .query_map(params_from_iter(values.iter().map(String::as_str)), |row| {
                Ok(NamedCount {
                    name: row.get::<_, Option<String>>(0)?.unwrap_or_default(),
                    count: row.get(1)?,
                })
            })
            .map_err(|error| error.to_string())?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|error| error.to_string())
    }

    pub fn top_players(
        &self,
        range: StatsTimeRange,
        version: Option<GameVersion>,
    ) -> DbResult<Vec<PlayerAverage>> {
        let connection = self.connection.lock().map_err(|error| error.to_string())?;
        let (suffix, version_values) = Self::version_components(version);
        let window = match range.months() {
            Some(months) => format!(" AND date(g.created_at) >= date('now', '-{months} months')"),
            None => String::new(),
        };
        let sql = format!(
            "SELECT p.name, AVG(p.final_score), MAX(p.final_score), COUNT(*)
             FROM players p JOIN games g ON p.game_id = g.id
             WHERE 1 = 1{suffix}{window}
             GROUP BY p.name ORDER BY AVG(p.final_score) DESC LIMIT 10"
        );
        let values: Vec<String> = version_values
            .iter()
            .map(|value| value.id().to_string())
            .collect();
        connection
            .prepare(&sql)
            .map_err(|error| error.to_string())?
            .query_map(params_from_iter(values.iter().map(String::as_str)), |row| {
                Ok(PlayerAverage {
                    name: row.get(0)?,
                    avg_score: row.get(1)?,
                    max_score: row.get(2)?,
                    games: row.get(3)?,
                })
            })
            .map_err(|error| error.to_string())?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|error| error.to_string())
    }

    pub fn average_score_by_position(
        &self,
        range: StatsTimeRange,
        version: Option<GameVersion>,
    ) -> DbResult<Vec<PlayerAverage>> {
        let connection = self.connection.lock().map_err(|error| error.to_string())?;
        let (suffix, version_values) = Self::version_components(version);
        let window = match range.months() {
            Some(months) => {
                format!(" AND datetime(g.created_at) >= datetime('now', '-{months} months')")
            }
            None => String::new(),
        };
        let sql = format!(
            "SELECT p.name, AVG(p.final_score), MAX(p.final_score), COUNT(DISTINCT p.game_id)
             FROM players p JOIN games g ON p.game_id = g.id
             WHERE 1 = 1{suffix}{window}
             GROUP BY p.name HAVING COUNT(DISTINCT p.game_id) >= 2
             ORDER BY AVG(p.final_score) DESC LIMIT 10"
        );
        let values: Vec<String> = version_values
            .iter()
            .map(|value| value.id().to_string())
            .collect();
        connection
            .prepare(&sql)
            .map_err(|error| error.to_string())?
            .query_map(params_from_iter(values.iter().map(String::as_str)), |row| {
                Ok(PlayerAverage {
                    name: row.get(0)?,
                    avg_score: row.get(1)?,
                    max_score: row.get(2)?,
                    games: row.get(3)?,
                })
            })
            .map_err(|error| error.to_string())?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|error| error.to_string())
    }

    pub fn win_percentage_by_player(
        &self,
        range: StatsTimeRange,
        version: Option<GameVersion>,
    ) -> DbResult<Vec<WinPercentage>> {
        let connection = self.connection.lock().map_err(|error| error.to_string())?;
        let (suffix, version_values) = Self::version_components(version);
        let window = match range.months() {
            Some(months) => format!(" AND date(g.created_at) >= date('now', '-{months} months')"),
            None => String::new(),
        };
        let version_window = if version_values.is_empty() {
            String::new()
        } else {
            " AND g2.game_version = ?".to_string()
        };
        let sql = format!(
            "SELECT p.name, COUNT(DISTINCT p.game_id),
                    (SELECT COUNT(*) FROM players p2 JOIN games g2 ON p2.game_id = g2.id
                     WHERE p2.name = p.name AND p2.final_score = (
                         SELECT MAX(final_score) FROM players WHERE game_id = p2.game_id
                     ){version_window})
             FROM players p JOIN games g ON p.game_id = g.id
             WHERE 1 = 1{suffix}{window}
             GROUP BY p.name HAVING COUNT(DISTINCT p.game_id) >= 2"
        );
        let mut values: Vec<String> = version_values
            .iter()
            .map(|value| value.id().to_string())
            .collect();
        values.extend(version_values.iter().map(|value| value.id().to_string()));
        let mut results: Vec<WinPercentage> = connection
            .prepare(&sql)
            .map_err(|error| error.to_string())?
            .query_map(params_from_iter(values.iter().map(String::as_str)), |row| {
                let name: String = row.get(0)?;
                let games: i64 = row.get(1)?;
                let wins: i64 = row.get::<_, Option<i64>>(2)?.unwrap_or(0);
                Ok(WinPercentage {
                    name,
                    games,
                    wins,
                    percentage: if games == 0 {
                        0.0
                    } else {
                        wins as f64 / games as f64 * 100.0
                    },
                })
            })
            .map_err(|error| error.to_string())?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|error| error.to_string())?;
        results.sort_by(|a, b| {
            b.percentage
                .partial_cmp(&a.percentage)
                .unwrap_or(std::cmp::Ordering::Equal)
        });
        results.truncate(10);
        Ok(results)
    }

    pub fn export_to_csv(&self) -> DbResult<String> {
        let connection = self.connection.lock().map_err(|error| error.to_string())?;
        let quote = |value: &str| format!("\"{}\"", value.replace('"', "\"\""));
        let mut output = String::from(
            "Games:\nid,uuid,created_at,completed_at,player_count,winner_name,winner_score,notes\n",
        );
        let mut statement = connection
            .prepare("SELECT id, uuid, created_at, completed_at, player_count, winner_name, winner_score, notes FROM games ORDER BY id")
            .map_err(|error| error.to_string())?;
        let games = statement
            .query_map([], |row| {
                Ok((
                    row.get::<_, i64>(0)?,
                    row.get::<_, String>(1)?,
                    row.get::<_, Option<String>>(2)?.unwrap_or_default(),
                    row.get::<_, Option<String>>(3)?.unwrap_or_default(),
                    row.get::<_, i64>(4)?,
                    row.get::<_, Option<String>>(5)?.unwrap_or_default(),
                    row.get::<_, Option<i64>>(6)?.unwrap_or_default(),
                    row.get::<_, Option<String>>(7)?.unwrap_or_default(),
                ))
            })
            .map_err(|error| error.to_string())?;
        for game in games {
            let game = game.map_err(|error| error.to_string())?;
            output.push_str(&format!(
                "{},{},{},{},{},{},{},{}\n",
                game.0,
                quote(&game.1),
                quote(&game.2),
                quote(&game.3),
                game.4,
                quote(&game.5),
                game.6,
                quote(&game.7)
            ));
        }
        output.push_str("\nPlayers:\nid,game_id,name,final_score,yellow_total,green_total,orange_total,purple_total,blue_total,fox_count,bonus,winner\n");
        let mut statement = connection
            .prepare(
                "SELECT id, game_id, name, final_score, yellow_total, green_total,
                 orange_total, purple_total, blue_total, fox_count, bonus, winner FROM players ORDER BY id",
            )
            .map_err(|error| error.to_string())?;
        let players = statement
            .query_map([], |row| {
                Ok((
                    row.get::<_, i64>(0)?,
                    row.get::<_, i64>(1)?,
                    row.get::<_, String>(2)?,
                    row.get::<_, i64>(3)?,
                    row.get::<_, i64>(4)?,
                    row.get::<_, i64>(5)?,
                    row.get::<_, i64>(6)?,
                    row.get::<_, i64>(7)?,
                    row.get::<_, i64>(8)?,
                    row.get::<_, i64>(9)?,
                    row.get::<_, i64>(10)?,
                    row.get::<_, i64>(11)?,
                ))
            })
            .map_err(|error| error.to_string())?;
        for player in players {
            let player = player.map_err(|error| error.to_string())?;
            output.push_str(&format!(
                "{},{},{},{},{},{},{},{},{},{},{},{}\n",
                player.0,
                player.1,
                quote(&player.2),
                player.3,
                player.4,
                player.5,
                player.6,
                player.7,
                player.8,
                player.9,
                player.10,
                player.11
            ));
        }
        Ok(output)
    }

    fn parse_csv_line(line: &str) -> Vec<String> {
        let mut fields = Vec::new();
        let mut field = String::new();
        let mut in_quotes = false;
        let mut characters = line.chars().peekable();
        while let Some(character) = characters.next() {
            match character {
                '"' => {
                    if in_quotes && characters.peek() == Some(&'"') {
                        field.push('"');
                        characters.next();
                    } else {
                        in_quotes = !in_quotes;
                    }
                }
                ',' if !in_quotes => {
                    fields.push(field.trim().to_string());
                    field.clear();
                }
                _ => field.push(character),
            }
        }
        fields.push(field.trim().to_string());
        fields
    }

    pub fn import_from_csv(&self, csv: &str) -> DbResult<usize> {
        let mut connection = self.connection.lock().map_err(|error| error.to_string())?;
        let transaction = connection
            .transaction()
            .map_err(|error| error.to_string())?;
        let mut in_games = false;
        let mut in_players = false;
        let mut imported = 0;
        for line in csv.lines() {
            let line = line.trim();
            if line == "Games:" {
                in_games = true;
                in_players = false;
                continue;
            }
            if line == "Players:" {
                in_games = false;
                in_players = true;
                continue;
            }
            let fields = Self::parse_csv_line(line);
            if in_games && fields.len() >= 8 && !fields[0].eq_ignore_ascii_case("id") {
                transaction
                    .execute(
                        "INSERT OR IGNORE INTO games (uuid, created_at, completed_at, player_count, winner_name, winner_score, notes)
                         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
                        params![
                            fields[1],
                            fields[2],
                            fields[3],
                            fields[4].parse::<i64>().unwrap_or(0),
                            fields[5],
                            fields[6].parse::<i64>().unwrap_or(0),
                            fields[7]
                        ],
                    )
                    .map_err(|error| error.to_string())?;
                imported += 1;
            } else if in_players && fields.len() >= 12 && !fields[0].eq_ignore_ascii_case("id") {
                transaction
                    .execute(
                        "INSERT INTO players (game_id, name, final_score, yellow_total, green_total,
                         orange_total, purple_total, blue_total, fox_count, bonus, winner)
                         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11)",
                        params![
                            fields[1].parse::<i64>().unwrap_or(0),
                            fields[2],
                            fields[3].parse::<i64>().unwrap_or(0),
                            fields[4].parse::<i64>().unwrap_or(0),
                            fields[5].parse::<i64>().unwrap_or(0),
                            fields[6].parse::<i64>().unwrap_or(0),
                            fields[7].parse::<i64>().unwrap_or(0),
                            fields[8].parse::<i64>().unwrap_or(0),
                            fields[9].parse::<i64>().unwrap_or(0),
                            fields[10].parse::<i64>().unwrap_or(0),
                            fields[11].parse::<i64>().unwrap_or(0),
                        ],
                    )
                    .map_err(|error| error.to_string())?;
            }
        }
        transaction.commit().map_err(|error| error.to_string())?;
        Ok(imported)
    }

    pub fn export_sqlite(&self, destination: &Path) -> DbResult<()> {
        fs::copy(&self.path, destination).map_err(|error| error.to_string())?;
        Ok(())
    }

    pub fn import_sqlite(&self, source: &Path) -> DbResult<()> {
        if !source.is_file() {
            return Err(format!("database file not found: {}", source.display()));
        }
        let source_connection =
            Connection::open_with_flags(source, rusqlite::OpenFlags::SQLITE_OPEN_READ_ONLY)
                .map_err(|error| format!("invalid SQLite database: {error}"))?;
        source_connection
            .query_row(
                "SELECT name FROM sqlite_master WHERE type = 'table' LIMIT 1",
                [],
                |_| Ok(()),
            )
            .optional()
            .map_err(|error| format!("invalid SQLite database: {error}"))?;
        drop(source_connection);
        let backup = self.path.with_extension("db.bak");
        if backup.exists() {
            fs::remove_file(&backup).map_err(|error| error.to_string())?;
        }
        let in_memory = Connection::open_in_memory().map_err(|error| error.to_string())?;
        {
            let mut guard = self.connection.lock().map_err(|error| error.to_string())?;
            let _old_connection = std::mem::replace(&mut *guard, in_memory);
        }
        fs::rename(&self.path, &backup).map_err(|error| error.to_string())?;
        fs::copy(source, &self.path).map_err(|error| error.to_string())?;
        let connection = Connection::open(&self.path).map_err(|error| error.to_string())?;
        {
            let mut guard = self.connection.lock().map_err(|error| error.to_string())?;
            *guard = connection;
        }
        self.create_schema()?;
        Ok(())
    }
}

pub fn format_date(value: Option<&str>, with_time: bool) -> String {
    let Some(value) = value else {
        return "Unknown date".to_string();
    };
    let parsed = NaiveDateTime::parse_from_str(value, "%Y-%m-%d %H:%M:%S")
        .or_else(|_| NaiveDateTime::parse_from_str(value, "%Y-%m-%dT%H:%M:%S"))
        .or_else(|_| DateTime::parse_from_rfc3339(value).map(|date| date.naive_local()));
    match parsed {
        Ok(date) => {
            if with_time {
                date.format("%b %d, %Y %H:%M").to_string()
            } else {
                date.format("%b %d, %Y").to_string()
            }
        }
        Err(_) => value.to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_database() -> (Database, tempfile::TempDir) {
        let directory = tempfile::tempdir().unwrap();
        let database = Database::open_at(directory.path().join("test.db")).unwrap();
        (database, directory)
    }

    #[test]
    fn saves_and_loads_games() {
        let (database, _directory) = test_database();
        let mut session = GameSession {
            game_version: GameVersion::V2,
            ..Default::default()
        };
        assert!(session.add_player("Alice"));
        assert!(session.add_player("Bob"));
        session.players[0].score_sheet.yellow = 10;
        session.players[0].score_sheet.fox_count = 2;
        session.players[0].score_sheet.calculate_bonus();
        session.players[1].score_sheet.yellow = 20;
        let id = database.save_game(&mut session, "fun game").unwrap();
        assert!(id > 0);
        let summaries = database.get_games(&GameHistoryFilter::default()).unwrap();
        assert_eq!(summaries.len(), 1);
        assert_eq!(summaries[0].winner_name, "Alice");
        assert_eq!(summaries[0].game_version, GameVersion::V2);
        let loaded = database
            .get_game_details(session.id.as_deref().unwrap())
            .unwrap()
            .unwrap();
        assert_eq!(loaded.players.len(), 2);
        assert_eq!(loaded.players[0].score_sheet.bonus, 20);
        assert!(loaded.winner.is_none());
    }

    #[test]
    fn high_scores_and_stats() {
        let (database, _directory) = test_database();
        let mut session = GameSession::default();
        session.add_player("Alice");
        session.players[0].score_sheet.yellow = 42;
        database.save_game(&mut session, "").unwrap();
        let scores = database.get_high_scores(10, None).unwrap();
        assert_eq!(scores.len(), 1);
        assert_eq!(scores[0].score, 42);
        let stats = database.database_stats(None).unwrap();
        assert_eq!(stats.games, 1);
        assert_eq!(stats.highest_score, 42);
        assert_eq!(stats.players, 1);
    }

    #[test]
    fn csv_round_trip() {
        let (database, _directory) = test_database();
        let mut session = GameSession::default();
        session.add_player("Alice");
        session.players[0].score_sheet.orange = 15;
        database.save_game(&mut session, "notes").unwrap();
        let csv = database.export_to_csv().unwrap();
        database.delete_all_games().unwrap();
        assert_eq!(database.database_stats(None).unwrap().games, 0);
        database.import_from_csv(&csv).unwrap();
        let stats = database.database_stats(None).unwrap();
        assert_eq!(stats.games, 1);
        assert_eq!(stats.players, 1);
    }
}
