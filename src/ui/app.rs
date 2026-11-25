use std::{sync::Arc, time::Duration};

use gpui_kit::{
    App as GuiApp, AppContext, Context, Entity, IntoElement, ParentElement as _, Render,
    SharedString, Styled as _, Subscription, Task, Window,
    component::{
        ActiveTheme, Theme, ThemeMode, WindowExt,
        input::{InputEvent, InputState},
        notification::Notification,
        scroll::ScrollableElement as _,
    },
    div, px,
};
use regex::Regex;

use crate::{
    models::{
        DatabaseStats, GameSession, GameSummary, GameVersion, HighScore, NamedCount, PlayerAverage,
        StatsTimeRange, WinPercentage,
    },
    storage::{Database, DbResult, GameHistoryFilter},
    theme,
};

use super::widgets::message_banner;

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum Screen {
    MainMenu,
    Setup,
    Calculator,
    FinalScores,
    History,
    Details(String),
    HighScores,
    Cleanup,
    Stats,
}

pub struct App {
    pub self_entity: Option<Entity<Self>>,
    pub db: Arc<Database>,
    pub screen: Screen,
    pub back_stack: Vec<Screen>,
    pub session: GameSession,
    pub theme_mode: ThemeMode,
    pub theme_system: bool,
    #[allow(dead_code)]
    pub theme_subscription: Option<Subscription>,
    pub search_task: Option<Task<()>>,
    pub setup_version: GameVersion,
    pub name_input: Entity<InputState>,
    pub search_input: Entity<InputState>,
    pub history_search_input: Entity<InputState>,
    pub path_input: Entity<InputState>,
    pub export_path_input: Entity<InputState>,
    pub score_inputs: Vec<Entity<InputState>>,
    #[allow(dead_code)]
    pub score_subscriptions: Vec<Subscription>,
    #[allow(dead_code)]
    pub input_subscriptions: Vec<Subscription>,
    pub recent_names: Vec<String>,
    pub history_filter: GameHistoryFilter,
    pub history: Vec<GameSummary>,
    pub high_scores: Vec<HighScore>,
    pub expanded_high_score: Option<i64>,
    pub expanded_game: Option<GameSession>,
    pub details_id: String,
    pub details: Option<GameSession>,
    pub stats_range: StatsTimeRange,
    pub stats_version: Option<GameVersion>,
    pub stats: DatabaseStats,
    pub games_per_month: Vec<NamedCount>,
    pub top_players: Vec<PlayerAverage>,
    pub position_averages: Vec<PlayerAverage>,
    pub win_percentages: Vec<WinPercentage>,
    pub custom_db_path: String,
    pub message: String,
}

impl App {
    pub fn new(db: Arc<Database>, window: &mut Window, cx: &mut Context<Self>) -> Self {
        let digits = Regex::new(r"^\d*$").expect("valid digit regex");
        let mut score_inputs = Vec::with_capacity(24);
        let mut score_subscriptions = Vec::with_capacity(24);
        for _index in 0..24 {
            let input = cx.new(|cx| {
                InputState::new(window, cx)
                    .placeholder("0")
                    .pattern(digits.clone())
            });
            let subscription = cx.subscribe_in(&input, window, |this, _, event, _, cx| {
                if matches!(event, InputEvent::Change) {
                    this.apply_scores_from_inputs(cx);
                }
            });
            score_inputs.push(input);
            score_subscriptions.push(subscription);
        }

        let name_input = cx.new(|cx| InputState::new(window, cx).placeholder("Player name"));
        let search_input = cx.new(|cx| InputState::new(window, cx).placeholder("Search players"));
        let history_search_input =
            cx.new(|cx| InputState::new(window, cx).placeholder("Search games or notes"));
        let path_input =
            cx.new(|cx| InputState::new(window, cx).placeholder("/path/to/database.db"));
        let export_path_input =
            cx.new(|cx| InputState::new(window, cx).placeholder("/path/to/export.csv"));

        let search_subscription =
            cx.subscribe_in(&search_input, window, |this, _, event, window, cx| {
                if matches!(event, InputEvent::Change) {
                    this.search_task = Some(cx.spawn_in(window, async move |this, cx| {
                        cx.background_executor()
                            .timer(Duration::from_millis(300))
                            .await;
                        if let Some(entity) = this.upgrade() {
                            entity.update(cx, |this, cx| this.search_players(cx));
                        }
                    }));
                }
            });
        let history_subscription =
            cx.subscribe_in(&history_search_input, window, |this, _, event, _, cx| {
                if matches!(event, InputEvent::Change) {
                    this.history_filter.query = this.input(&this.history_search_input, cx);
                    this.refresh_history();
                    cx.notify();
                }
            });

        let recent_names = db.get_recent_player_names(5).unwrap_or_default();
        let custom_db_path = Database::custom_db_path()
            .map(|path| path.to_string_lossy().to_string())
            .unwrap_or_default();
        let mut app = Self {
            self_entity: None,
            db,
            screen: Screen::MainMenu,
            back_stack: Vec::new(),
            session: GameSession::default(),
            theme_mode: window.appearance().into(),
            theme_system: false,
            theme_subscription: None,
            search_task: None,
            setup_version: GameVersion::V1,
            name_input,
            search_input,
            history_search_input,
            path_input,
            export_path_input,
            score_inputs,
            score_subscriptions,
            input_subscriptions: vec![search_subscription, history_subscription],
            recent_names,
            history_filter: GameHistoryFilter::default(),
            history: Vec::new(),
            high_scores: Vec::new(),
            expanded_high_score: None,
            expanded_game: None,
            details_id: String::new(),
            details: None,
            stats_range: StatsTimeRange::AllTime,
            stats_version: Some(GameVersion::All),
            stats: DatabaseStats::default(),
            games_per_month: Vec::new(),
            top_players: Vec::new(),
            position_averages: Vec::new(),
            win_percentages: Vec::new(),
            custom_db_path,
            message: String::new(),
        };
        app.self_entity = Some(cx.entity());
        let entity = cx.entity();
        app.theme_subscription = Some(window.observe_window_appearance(move |window, cx| {
            let mode = window.appearance().into();
            entity.update(cx, |this, cx| this.apply_theme(mode, window, cx));
        }));
        app.refresh_current(window, cx);
        app
    }

    pub fn entity(&self) -> Entity<Self> {
        self.self_entity
            .clone()
            .expect("application entity is initialized")
    }

    pub fn go(&mut self, screen: Screen, window: &mut Window, cx: &mut Context<Self>) {
        if self.screen != screen {
            self.back_stack.push(self.screen.clone());
        }
        self.screen = screen;
        self.message.clear();
        self.refresh_current(window, cx);
        cx.notify();
    }

    pub fn go_replace(&mut self, screen: Screen, window: &mut Window, cx: &mut Context<Self>) {
        self.screen = screen;
        self.back_stack.clear();
        self.message.clear();
        self.refresh_current(window, cx);
        cx.notify();
    }

    pub fn back(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        if let Some(screen) = self.back_stack.pop() {
            self.screen = screen;
            self.refresh_current(window, cx);
            cx.notify();
        } else {
            self.home(window, cx);
        }
    }

    pub fn home(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        self.screen = Screen::MainMenu;
        self.back_stack.clear();
        self.message.clear();
        self.refresh_current(window, cx);
        cx.notify();
    }

    pub fn refresh_current(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        match self.screen {
            Screen::Setup => self.refresh_recent_players(),
            Screen::Calculator => self.sync_score_inputs(window, cx),
            Screen::History => self.refresh_history(),
            Screen::HighScores => self.refresh_high_scores(),
            Screen::Details(_) => self.refresh_details(),
            Screen::Cleanup => self.refresh_stats(),
            Screen::Stats => self.refresh_stats_screen(),
            _ => {}
        }
    }

    pub fn refresh_recent_players(&mut self) {
        self.recent_names = self.db.get_recent_player_names(5).unwrap_or_default();
    }

    pub fn refresh_history(&mut self) {
        self.history = self.db.get_games(&self.history_filter).unwrap_or_default();
    }

    pub fn set_version_filter(&mut self, version: Option<GameVersion>, cx: &mut Context<Self>) {
        self.stats_version = Some(version.unwrap_or(GameVersion::All));
        self.refresh_stats_screen();
        self.refresh_high_scores();
        cx.notify();
    }

    pub fn refresh_high_scores(&mut self) {
        self.high_scores = self
            .db
            .get_high_scores(10, Some(self.stats_version.unwrap_or(GameVersion::All)))
            .unwrap_or_default();
        self.expanded_high_score = None;
        self.expanded_game = None;
    }

    pub fn refresh_details(&mut self) {
        self.details = self
            .db
            .get_game_details(&self.details_id)
            .unwrap_or_default();
    }

    pub fn refresh_stats(&mut self) {
        self.refresh_stats_for(None);
    }

    pub fn refresh_stats_for(&mut self, version: Option<GameVersion>) {
        self.stats = self.db.database_stats(version).unwrap_or_default();
    }

    pub fn refresh_stats_screen(&mut self) {
        let version = normalize_version(self.stats_version);
        self.refresh_stats_for(version);
        self.games_per_month = self
            .db
            .games_per_month(self.stats_range, version)
            .unwrap_or_default();
        self.top_players = self
            .db
            .top_players(self.stats_range, version)
            .unwrap_or_default();
        self.position_averages = self
            .db
            .average_score_by_position(self.stats_range, version)
            .unwrap_or_default();
        self.win_percentages = self
            .db
            .win_percentage_by_player(self.stats_range, version)
            .unwrap_or_default();
    }

    pub fn sync_score_inputs(&self, window: &mut Window, cx: &mut Context<Self>) {
        for (player_index, player) in self.session.players.iter().enumerate() {
            let sheet = &player.score_sheet;
            let values = [
                sheet.yellow,
                sheet.green,
                sheet.orange,
                sheet.purple,
                sheet.blue,
                sheet.fox_count,
            ];
            for (field, value) in values.into_iter().enumerate() {
                if let Some(input) = self.score_inputs.get(player_index * 6 + field) {
                    let text = value.to_string();
                    input.update(cx, |state, cx| state.set_value(text.clone(), window, cx));
                }
            }
        }
    }

    pub fn apply_scores_from_inputs(&mut self, cx: &mut Context<Self>) {
        let values: Vec<i64> = self
            .score_inputs
            .iter()
            .map(|input| {
                input
                    .read(cx)
                    .value()
                    .trim()
                    .parse::<i64>()
                    .unwrap_or(0)
                    .max(0)
            })
            .collect();
        let names: Vec<String> = self
            .session
            .players
            .iter()
            .map(|player| player.name.clone())
            .collect();
        for (index, name) in names.iter().enumerate() {
            let values = &values[index * 6..index * 6 + 6];
            self.session.update_player_score(
                name, values[0], values[1], values[2], values[3], values[4], values[5],
            );
        }
        cx.notify();
    }

    pub fn handle_db_result(
        &mut self,
        result: DbResult<()>,
        success: &str,
        error_context: &str,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        match result {
            Ok(()) => {
                window.push_notification(Notification::success(success), cx);
                self.message = success.to_string();
            }
            Err(error) => {
                let message = format!("Failed to {error_context}: {error}");
                window.push_notification(Notification::error(message.clone()), cx);
                self.message = message;
            }
        }
    }

    pub fn toggle_theme(&mut self, mode: ThemeMode, window: &mut Window, cx: &mut Context<Self>) {
        self.theme_system = false;
        self.apply_theme(mode, window, cx);
    }

    pub fn use_system_theme(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        self.theme_system = true;
        self.apply_theme(window.appearance().into(), window, cx);
    }

    pub fn apply_theme(&mut self, mode: ThemeMode, window: &mut Window, cx: &mut Context<Self>) {
        self.theme_mode = mode;
        Theme::change(mode, Some(window), cx);
        cx.notify();
    }

    pub fn input(&self, entity: &Entity<InputState>, cx: &GuiApp) -> String {
        entity.read(cx).value().to_string()
    }

    pub fn set_input(
        &self,
        entity: &Entity<InputState>,
        value: &str,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        let value = value.to_string();
        entity.update(cx, |state, cx| state.set_value(value, window, cx));
    }
}

pub fn normalize_version(version: Option<GameVersion>) -> Option<GameVersion> {
    match version {
        Some(GameVersion::All) | None => None,
        Some(version) => Some(version),
    }
}

impl Render for App {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let surface = if self.theme_mode.is_dark() {
            theme::color(theme::DARK_SURFACE)
        } else {
            theme::color(theme::SURFACE)
        };
        let background = if self.theme_mode.is_dark() {
            theme::color(theme::DARK_BACKGROUND)
        } else {
            theme::color(theme::BACKGROUND)
        };
        let foreground = cx.theme().foreground;

        let body = match &self.screen {
            Screen::MainMenu => self.render_main_menu(window, cx),
            Screen::Setup => self.render_setup(window, cx),
            Screen::Calculator => self.render_calculator(window, cx),
            Screen::FinalScores => self.render_final_scores(window, cx),
            Screen::History => self.render_history(window, cx),
            Screen::Details(_) => self.render_details(window, cx),
            Screen::HighScores => self.render_high_scores(window, cx),
            Screen::Cleanup => self.render_cleanup(window, cx),
            Screen::Stats => self.render_stats(window, cx),
        };

        div()
            .size_full()
            .flex()
            .flex_col()
            .bg(background)
            .text_color(foreground)
            .child(
                div()
                    .flex()
                    .items_center()
                    .justify_between()
                    .px(px(20.))
                    .py(px(10.))
                    .bg(surface)
                    .child(
                        div()
                            .text_size(px(16.))
                            .font_weight(gpui_kit::FontWeight::BOLD)
                            .child(SharedString::from("🎲 Ganz Schön Clever Scorer")),
                    )
                    .child(
                        div()
                            .flex()
                            .gap(px(8.))
                            .child(super::widgets::button(
                                "top-home",
                                "Home",
                                super::widgets::ButtonStyle::Ghost,
                                cx.listener(|this, _, window, cx| this.home(window, cx)),
                            ))
                            .child(super::widgets::button(
                                "top-system",
                                if self.theme_system {
                                    "✓ System"
                                } else {
                                    "System"
                                },
                                super::widgets::ButtonStyle::Ghost,
                                cx.listener(|this, _, window, cx| {
                                    this.use_system_theme(window, cx)
                                }),
                            ))
                            .child(super::widgets::button(
                                "top-light",
                                "Light",
                                super::widgets::ButtonStyle::Ghost,
                                cx.listener(|this, _, window, cx| {
                                    this.toggle_theme(ThemeMode::Light, window, cx)
                                }),
                            ))
                            .child(super::widgets::button(
                                "top-dark",
                                "Dark",
                                super::widgets::ButtonStyle::Ghost,
                                cx.listener(|this, _, window, cx| {
                                    this.toggle_theme(ThemeMode::Dark, window, cx)
                                }),
                            )),
                    ),
            )
            .child(
                div()
                    .px(px(20.))
                    .pt(px(10.))
                    .child(message_banner(&self.message, cx)),
            )
            .child(
                div()
                    .flex_1()
                    .min_h(px(0.))
                    .p(px(20.))
                    .overflow_y_scrollbar()
                    .child(body),
            )
            .into_any_element()
    }
}
