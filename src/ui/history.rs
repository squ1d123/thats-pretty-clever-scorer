use gpui_kit::{
    AnyElement, Context, FontWeight, IntoElement, ParentElement as _, Styled as _, Window,
    base::StyledExt as _,
    component::{ActiveTheme, WindowExt, input::Input},
    div, px,
};

use crate::{
    models::GameVersion,
    storage::format_date,
    theme,
    ui::widgets::{self, ButtonStyle},
};

use super::{App, Screen};

impl App {
    pub fn cycle_history_sort(&mut self, cx: &mut Context<Self>) {
        self.history_filter.sort_by = match self.history_filter.sort_by.as_str() {
            "date" => "score",
            "score" => "player_count",
            _ => "date",
        }
        .to_string();
        self.refresh_history();
        cx.notify();
    }

    pub fn toggle_history_order(&mut self, cx: &mut Context<Self>) {
        self.history_filter.sort_order = if self.history_filter.sort_order == "desc" {
            "asc".to_string()
        } else {
            "desc".to_string()
        };
        self.refresh_history();
        cx.notify();
    }

    pub fn cycle_history_version(&mut self, cx: &mut Context<Self>) {
        self.history_filter.game_version = match self.history_filter.game_version {
            None => Some(GameVersion::V1),
            Some(GameVersion::V1) => Some(GameVersion::V2),
            _ => None,
        };
        self.refresh_history();
        cx.notify();
    }

    pub fn render_history(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> AnyElement {
        let surface = if self.theme_mode.is_dark() {
            theme::color(theme::DARK_SURFACE)
        } else {
            theme::color(theme::SURFACE)
        };
        let sort_label = match self.history_filter.sort_by.as_str() {
            "score" => "Score",
            "player_count" => "Players",
            _ => "Date",
        };
        let version_label = self
            .history_filter
            .game_version
            .map(GameVersion::short_name)
            .unwrap_or("All");
        let games = self.history.clone();

        let rows = if games.is_empty() {
            div()
                .py(px(24.))
                .text_color(cx.theme().muted_foreground)
                .child("No games found")
                .into_any_element()
        } else {
            div()
                .v_flex()
                .gap(px(8.))
                .children(games.into_iter().map(|game| {
                    let game_id = game.id.clone();
                    let db_id = game.db_id;
                    let subtitle = format!(
                        "{} players • {} • {}",
                        game.player_count,
                        format_date(game.created_at.as_deref(), false),
                        game.game_version.short_name()
                    );
                    div()
                        .flex()
                        .items_center()
                        .justify_between()
                        .p(px(12.))
                        .rounded(px(10.))
                        .bg(cx.theme().accent.opacity(0.06))
                        .child(
                            div()
                                .v_flex()
                                .gap(px(2.))
                                .child(
                                    div()
                                        .text_size(px(15.))
                                        .font_weight(FontWeight::MEDIUM)
                                        .child(format!(
                                            "{}: {} pts",
                                            game.winner_name, game.winner_score
                                        )),
                                )
                                .child(
                                    div()
                                        .text_size(px(12.))
                                        .text_color(cx.theme().muted_foreground)
                                        .child(subtitle),
                                ),
                        )
                        .child(
                            div()
                                .flex()
                                .gap(px(6.))
                                .child(widgets::button(
                                    ("view-game", db_id as usize),
                                    "Details",
                                    ButtonStyle::Secondary,
                                    cx.listener(move |this, _, window, cx| {
                                        this.details_id = game_id.clone();
                                        this.go(
                                            Screen::Details(this.details_id.clone()),
                                            window,
                                            cx,
                                        );
                                    }),
                                ))
                                .child(widgets::button(
                                    ("delete-game", db_id as usize),
                                    "Delete",
                                    ButtonStyle::Danger,
                                    cx.listener(move |this, _, window, cx| {
                                        let entity = this.entity();
                                        window.open_alert_dialog(cx, move |alert, _, _| {
                                            let entity = entity.clone();
                                            alert
                                                .title("Delete Game?")
                                                .description("This cannot be undone.")
                                                .ok_text("Delete")
                                                .show_cancel(true)
                                                .on_ok(move |_, window, app| {
                                                    entity.update(app, |this, cx| {
                                                        this.handle_db_result(
                                                            this.db.delete_game(db_id),
                                                            "Game deleted",
                                                            "delete game",
                                                            window,
                                                            cx,
                                                        );
                                                        this.refresh_history();
                                                        this.refresh_stats();
                                                        cx.notify();
                                                    });
                                                    true
                                                })
                                        });
                                    }),
                                )),
                        )
                        .into_any_element()
                }))
                .into_any_element()
        };

        div()
            .v_flex()
            .gap(px(16.))
            .child(widgets::header("Game History", cx))
            .child(widgets::card(
                surface,
                div()
                    .v_flex()
                    .gap(px(10.))
                    .child(Input::new(&self.history_search_input))
                    .child(if self.history_filter.query.is_empty() {
                        div().into_any_element()
                    } else {
                        widgets::button(
                            "history-clear-search",
                            "Clear",
                            ButtonStyle::Ghost,
                            cx.listener(|this, _, window, cx| {
                                this.set_input(&this.history_search_input, "", window, cx);
                                this.history_filter.query.clear();
                                this.refresh_history();
                                cx.notify();
                            }),
                        )
                        .into_any_element()
                    })
                    .child(
                        div()
                            .flex()
                            .flex_wrap()
                            .gap(px(8.))
                            .child(widgets::button(
                                "history-sort",
                                format!("Sort: {sort_label}"),
                                ButtonStyle::Secondary,
                                cx.listener(|this, _, _, cx| this.cycle_history_sort(cx)),
                            ))
                            .child(widgets::button(
                                "history-order",
                                if self.history_filter.sort_order == "desc" {
                                    "Descending ↓"
                                } else {
                                    "Ascending ↑"
                                },
                                ButtonStyle::Secondary,
                                cx.listener(|this, _, _, cx| this.toggle_history_order(cx)),
                            ))
                            .child(widgets::button(
                                "history-version",
                                format!("Version: {version_label}"),
                                ButtonStyle::Secondary,
                                cx.listener(|this, _, _, cx| this.cycle_history_version(cx)),
                            )),
                    ),
            ))
            .child(widgets::card(surface, rows))
            .child(widgets::button(
                "history-home",
                "Home",
                ButtonStyle::Ghost,
                cx.listener(|this, _, window, cx| this.home(window, cx)),
            ))
            .into_any_element()
    }
}
