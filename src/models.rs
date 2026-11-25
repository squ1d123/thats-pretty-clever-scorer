#[derive(Clone, Debug, Default)]
pub struct ScoreSheet {
    pub yellow: i64,
    pub green: i64,
    pub orange: i64,
    pub purple: i64,
    pub blue: i64,
    pub bonus: i64,
    pub fox_count: i64,
    pub yellow_columns: [[bool; 6]; 6],
    pub green_numbers: [bool; 11],
    pub orange_numbers: [i64; 11],
    pub purple_numbers: [bool; 11],
    pub blue_numbers: [bool; 11],
}

impl ScoreSheet {
    pub fn total(&self) -> i64 {
        self.yellow + self.green + self.orange + self.purple + self.blue + self.bonus
    }

    pub fn calculate_bonus(&mut self) {
        let lowest = [self.yellow, self.green, self.orange, self.purple, self.blue]
            .into_iter()
            .filter(|score| *score > 0)
            .min()
            .unwrap_or(0);
        self.bonus = lowest * self.fox_count;
    }

    pub fn yellow_score(&mut self) -> i64 {
        let mut score = 0;
        for (column_index, column) in self.yellow_columns.iter().enumerate() {
            if column.iter().all(|marked| *marked) {
                score += ((column_index + 1) * (column_index + 1)) as i64;
            }
        }
        self.yellow = score;
        score
    }

    pub fn green_score(&mut self) -> i64 {
        let mut score = 0;
        let mut consecutive = 0;
        for marked in self.green_numbers {
            if marked {
                consecutive += 1;
            } else {
                if consecutive > 0 {
                    score += consecutive * consecutive;
                }
                consecutive = 0;
            }
        }
        if consecutive > 0 {
            score += consecutive * consecutive;
        }
        self.green = score;
        score
    }

    pub fn orange_score(&mut self) -> i64 {
        let score = self.orange_numbers.iter().filter(|value| **value > 0).sum();
        self.orange = score;
        score
    }

    pub fn purple_score(&mut self) -> i64 {
        let score = self
            .purple_numbers
            .iter()
            .enumerate()
            .filter(|(_, marked)| **marked)
            .map(|(index, _)| (index + 1) as i64)
            .sum();
        self.purple = score;
        score
    }

    pub fn blue_score(&mut self) -> i64 {
        let marked = self.blue_numbers.iter().filter(|marked| **marked).count();
        let score = if (1..=11).contains(&marked) {
            (marked * (marked + 1) / 2) as i64
        } else {
            0
        };
        self.blue = score;
        score
    }

    pub fn calculate_scores(&mut self) {
        self.yellow_score();
        self.green_score();
        self.orange_score();
        self.purple_score();
        self.blue_score();
        self.calculate_bonus();
    }
}

#[derive(Clone, Debug)]
pub struct Player {
    pub name: String,
    pub score_sheet: ScoreSheet,
}

impl Player {
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            score_sheet: ScoreSheet::default(),
        }
    }

    pub fn total_score(&self) -> i64 {
        self.score_sheet.total()
    }
}

#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub enum GameVersion {
    All,
    #[default]
    V1,
    V2,
}

impl GameVersion {
    pub fn id(self) -> &'static str {
        match self {
            Self::All => "all",
            Self::V1 => "v1",
            Self::V2 => "v2",
        }
    }

    pub fn display_name(self) -> &'static str {
        match self {
            Self::All => "All Versions",
            Self::V1 => "Ganz Schön Clever",
            Self::V2 => "Twice as Clever",
        }
    }

    pub fn short_name(self) -> &'static str {
        match self {
            Self::All => "All",
            Self::V1 => "V1",
            Self::V2 => "V2",
        }
    }

    pub fn from_id(id: Option<&str>) -> Self {
        match id.unwrap_or_default() {
            "v2" => Self::V2,
            "v1" => Self::V1,
            _ => Self::All,
        }
    }

    pub fn colors(self) -> [u32; 5] {
        match self {
            Self::V2 => [0x9E9E9E, 0xFFEB3B, 0x2196F3, 0x4CAF50, 0xE91E63],
            _ => [0xFFD700, 0x2196F3, 0x4CAF50, 0xFF9800, 0x9C27B0],
        }
    }

    pub fn color_names(self) -> [&'static str; 5] {
        match self {
            Self::V2 => ["Silver", "Yellow", "Blue", "Green", "Pink"],
            _ => ["Yellow", "Blue", "Green", "Orange", "Purple"],
        }
    }
}

#[derive(Clone, Debug, Default)]
pub struct GameSession {
    pub id: Option<String>,
    pub created_at: Option<String>,
    pub completed_at: Option<String>,
    pub players: Vec<Player>,
    pub winner: Option<String>,
    pub notes: String,
    pub game_version: GameVersion,
}

impl GameSession {
    pub fn find_winner(&self) -> Option<usize> {
        let mut winner = None;
        let mut highest = -1;
        for (index, player) in self.players.iter().enumerate() {
            let score = player.total_score();
            if score > highest {
                highest = score;
                winner = Some(index);
            }
        }
        winner
    }

    pub fn max_score(&self) -> i64 {
        self.players
            .iter()
            .map(Player::total_score)
            .max()
            .unwrap_or(0)
    }

    pub fn calculate_scores(&mut self) {
        for player in &mut self.players {
            player.score_sheet.calculate_scores();
        }
        if let Some(index) = self.find_winner() {
            self.winner = Some(self.players[index].name.clone());
        }
    }

    pub fn add_player(&mut self, name: &str) -> bool {
        if self.players.len() >= 4
            || self
                .players
                .iter()
                .any(|player| player.name.eq_ignore_ascii_case(name))
        {
            return false;
        }
        self.players.push(Player::new(name));
        true
    }

    pub fn remove_player(&mut self, index: usize) {
        if index < self.players.len() {
            self.players.remove(index);
        }
    }

    #[allow(clippy::too_many_arguments)]
    pub fn update_player_score(
        &mut self,
        player_name: &str,
        yellow: i64,
        green: i64,
        orange: i64,
        purple: i64,
        blue: i64,
        fox_count: i64,
    ) {
        if let Some(player) = self
            .players
            .iter_mut()
            .find(|player| player.name == player_name)
        {
            player.score_sheet.yellow = yellow;
            player.score_sheet.green = green;
            player.score_sheet.orange = orange;
            player.score_sheet.purple = purple;
            player.score_sheet.blue = blue;
            player.score_sheet.fox_count = fox_count;
            player.score_sheet.calculate_bonus();
        }
    }
}

#[derive(Clone, Debug)]
pub struct GameSummary {
    pub id: String,
    pub db_id: i64,
    pub created_at: Option<String>,
    pub player_count: i64,
    pub winner_name: String,
    pub winner_score: i64,
    pub game_version: GameVersion,
}

#[derive(Clone, Debug)]
pub struct HighScore {
    pub id: Option<i64>,
    pub game_id: i64,
    pub player_name: String,
    pub score: i64,
    pub achieved_at: Option<String>,
}

#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub enum StatsTimeRange {
    #[default]
    AllTime,
    LastMonth,
    Last3Months,
    Last6Months,
    LastYear,
}

impl StatsTimeRange {
    pub fn label(self) -> &'static str {
        match self {
            Self::AllTime => "All Time",
            Self::LastMonth => "Last Month",
            Self::Last3Months => "Last 3 Months",
            Self::Last6Months => "Last 6 Months",
            Self::LastYear => "Last Year",
        }
    }

    pub fn months(self) -> Option<i64> {
        match self {
            Self::AllTime => None,
            Self::LastMonth => Some(1),
            Self::Last3Months => Some(3),
            Self::Last6Months => Some(6),
            Self::LastYear => Some(12),
        }
    }
}

#[derive(Clone, Debug, Default)]
pub struct DatabaseStats {
    pub games: i64,
    pub players: i64,
    pub highest_score: i64,
}

#[derive(Clone, Debug)]
pub struct NamedCount {
    pub name: String,
    pub count: i64,
}

#[derive(Clone, Debug)]
pub struct PlayerAverage {
    pub name: String,
    pub avg_score: f64,
    pub max_score: i64,
    pub games: i64,
}

#[derive(Clone, Debug)]
pub struct WinPercentage {
    pub name: String,
    #[allow(dead_code)]
    pub games: i64,
    #[allow(dead_code)]
    pub wins: i64,
    pub percentage: f64,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn yellow_scores_only_complete_columns() {
        let mut sheet = ScoreSheet::default();
        assert_eq!(sheet.yellow_score(), 0);
        for value in sheet.yellow_columns[0].iter_mut() {
            *value = true;
        }
        assert_eq!(sheet.yellow_score(), 1);
        for value in sheet.yellow_columns[5].iter_mut() {
            *value = true;
        }
        assert_eq!(sheet.yellow_score(), 37);
    }

    #[test]
    fn green_scores_runs_of_consecutive_numbers() {
        let mut sheet = ScoreSheet::default();
        for value in sheet.green_numbers.iter_mut().take(3) {
            *value = true;
        }
        sheet.green_numbers[5] = true;
        sheet.green_numbers[6] = true;
        assert_eq!(sheet.green_score(), 13);
    }

    #[test]
    fn blue_scores_triangular_numbers() {
        let mut sheet = ScoreSheet::default();
        for value in sheet.blue_numbers.iter_mut().take(11) {
            *value = true;
        }
        assert_eq!(sheet.blue_score(), 66);
    }

    #[test]
    fn bonus_uses_lowest_positive_area_and_foxes() {
        let mut sheet = ScoreSheet {
            yellow: 12,
            orange: 7,
            purple: 20,
            blue: 30,
            fox_count: 3,
            ..Default::default()
        };
        sheet.calculate_bonus();
        assert_eq!(sheet.bonus, 21);
        assert_eq!(sheet.total(), 90);
    }

    #[test]
    fn winner_goes_to_first_player_on_ties() {
        let mut session = GameSession::default();
        session.add_player("First");
        session.add_player("Second");
        session.players[0].score_sheet.yellow = 10;
        session.players[1].score_sheet.yellow = 10;
        assert_eq!(session.find_winner(), Some(0));
        assert_eq!(session.players.len(), 2);
        assert!(!session.add_player("first"));
    }
}
