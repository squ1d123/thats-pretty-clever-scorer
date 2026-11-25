use gpui_kit::{
    AnyElement, Context, FontWeight, InteractiveElement as _, IntoElement, ParentElement as _,
    StatefulInteractiveElement as _, Styled as _, Window, base::StyledExt as _,
    component::ActiveTheme, div, px,
};

use crate::{
    models::GameVersion,
    storage::format_date,
    theme,
    ui::widgets::{self, ButtonStyle},
};

use super::{App, Screen};

impl App {
    pub fn render_high_scores(
        &mut self,
        _window: &mut Window,
        cx: &mut Context<Self>,
    ) -> AnyElement {
        let surface = if self.theme_mode.is_dark() {
            theme::color(theme::DARK_SURFACE)
        } else {
            theme::color(theme::SURFACE)
        };
        let selected = self.stats_version.unwrap_or(GameVersion::All);
        let version_buttons = div()
            .flex()
            .gap(px(8.))
            .child(widgets::button(
                "scores-version-all",
                format!(
                    "{}All Versions",
                    if selected == GameVersion::All {
                        "✓ "
                    } else {
                        ""
                    }
                ),
                if selected == GameVersion::All {
                    ButtonStyle::Primary
                } else {
                    ButtonStyle::Secondary
                },
                cx.listener(|this, _, _, cx| this.set_version_filter(None, cx)),
            ))
            .child(widgets::button(
                "scores-version-v1",
                format!(
                    "{}Ganz Schön Clever",
                    if selected == GameVersion::V1 {
                        "✓ "
                    } else {
                        ""
                    }
                ),
                if selected == GameVersion::V1 {
                    ButtonStyle::Primary
                } else {
                    ButtonStyle::Secondary
                },
                cx.listener(|this, _, _, cx| this.set_version_filter(Some(GameVersion::V1), cx)),
            ))
            .child(widgets::button(
                "scores-version-v2",
                format!(
                    "{}Twice as Clever",
                    if selected == GameVersion::V2 {
                        "✓ "
                    } else {
                        ""
                    }
                ),
                if selected == GameVersion::V2 {
                    ButtonStyle::Primary
                } else {
                    ButtonStyle::Secondary
                },
                cx.listener(|this, _, _, cx| this.set_version_filter(Some(GameVersion::V2), cx)),
            ));

        let scores = self.high_scores.clone();
        let rows = if scores.is_empty() {
            div()
                .py(px(24.))
                .text_color(cx.theme().muted_foreground)
                .child("No high scores yet. Play some games!")
                .into_any_element()
        } else {
            div()
                .v_flex()
                .gap(px(8.))
                .children(scores.into_iter().enumerate().map(|(index, score)| {
                    let medal = match index {
                        0 => "1".to_string(),
                        1 => "2".to_string(),
                        2 => "3".to_string(),
                        _ => (index + 1).to_string(),
                    };
                    let medal_color = match index {
                        0 => theme::color(0xFFC107),
                        1 => theme::color(0x9E9E9E),
                        2 => theme::color(0xD7A066),
                        _ => theme::color(0x607D8B),
                    };
                    let is_expanded = self.expanded_high_score == score.id;
                    let score_game_id = score.game_id;
                    let details = if is_expanded {
                        let mut players = self
                            .expanded_game
                            .clone()
                            .map(|game| game.players)
                            .unwrap_or_default();
                        players.sort_by_key(|player| std::cmp::Reverse(player.total_score()));
                        let game_id = self
                            .expanded_game
                            .as_ref()
                            .and_then(|game| game.id.clone())
                            .unwrap_or_default();
                        let game_details = if self.expanded_game.is_none() {
                            div()
                                .text_size(px(12.))
                                .child("Game not found")
                                .into_any_element()
                        } else {
                            widgets::button(
                                ("view-full-game", score_game_id as usize),
                                "View Full Game Details",
                                ButtonStyle::Ghost,
                                cx.listener(move |this, _, window, cx| {
                                    this.details_id = game_id.clone();
                                    this.go(Screen::Details(this.details_id.clone()), window, cx);
                                }),
                            )
                            .into_any_element()
                        };
                        div()
                            .v_flex()
                            .gap(px(6.))
                            .mt(px(10.))
                            .pt(px(10.))
                            .border_t_1()
                            .border_color(cx.theme().border)
                            .child(
                                div()
                                    .text_size(px(12.))
                                    .text_color(cx.theme().muted_foreground)
                                    .child(format!(
                                        "Game on {}",
                                        format_date(
                                            self.expanded_game
                                                .as_ref()
                                                .and_then(|game| game.created_at.as_deref()),
                                            false
                                        )
                                    )),
                            )
                            .children(players.into_iter().map(|player| {
                                div()
                                    .text_size(px(13.))
                                    .child(format!("{}: {} pts", player.name, player.total_score()))
                                    .into_any_element()
                            }))
                            .child(game_details)
                            .into_any_element()
                    } else {
                        div().into_any_element()
                    };
                    div()
                        .id(("high-score", score.id.unwrap_or(score.game_id) as usize))
                        .p(px(12.))
                        .rounded(px(10.))
                        .bg(surface)
                        .child(
                            div()
                                .flex()
                                .items_center()
                                .gap(px(12.))
                                .child(
                                    div()
                                        .size(px(32.))
                                        .rounded_full()
                                        .bg(medal_color)
                                        .text_color(theme::color(0x111111))
                                        .text_align(gpui_kit::TextAlign::Center)
                                        .child(medal),
                                )
                                .child(
                                    div()
                                        .v_flex()
                                        .flex_1()
                                        .child(
                                            div()
                                                .text_size(px(15.))
                                                .font_weight(FontWeight::MEDIUM)
                                                .child(score.player_name),
                                        )
                                        .child(
                                            div()
                                                .text_size(px(12.))
                                                .text_color(cx.theme().muted_foreground)
                                                .child(format!(
                                                    "Achieved {}",
                                                    format_date(
                                                        score.achieved_at.as_deref(),
                                                        false
                                                    )
                                                )),
                                        ),
                                )
                                .child(
                                    div()
                                        .text_size(px(20.))
                                        .font_weight(FontWeight::BOLD)
                                        .child(score.score.to_string()),
                                ),
                        )
                        .child(details)
                        .on_click(cx.listener(move |this, _, _, cx| {
                            this.expanded_high_score = if this.expanded_high_score == score.id {
                                None
                            } else {
                                this.expanded_game = this
                                    .db
                                    .get_game_details_by_id(score_game_id)
                                    .unwrap_or_default();
                                score.id
                            };
                            cx.notify();
                        }))
                        .into_any_element()
                }))
                .into_any_element()
        };

        div()
            .v_flex()
            .gap(px(16.))
            .child(widgets::header("High Scores", cx))
            .child(widgets::card(surface, version_buttons))
            .child(widgets::card(surface, rows))
            .child(widgets::button(
                "scores-home",
                "Home",
                ButtonStyle::Ghost,
                cx.listener(|this, _, window, cx| this.home(window, cx)),
            ))
            .into_any_element()
    }
}
