use gpui_kit::{
    AnyElement, Context, FontWeight, IntoElement, ParentElement as _, Styled as _, Window,
    base::StyledExt as _, component::ActiveTheme, div, prelude::FluentBuilder as _, px,
};

use crate::{storage::format_date, theme, ui::widgets};

use super::App;

impl App {
    pub fn render_details(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> AnyElement {
        let surface = if self.theme_mode.is_dark() {
            theme::color(theme::DARK_SURFACE)
        } else {
            theme::color(theme::SURFACE)
        };
        let Some(game) = self.details.clone() else {
            return div()
                .v_flex()
                .gap(px(12.))
                .child(widgets::header("Game Details", cx))
                .child(div().child("Game not found"))
                .child(widgets::button(
                    "details-home",
                    "Home",
                    widgets::ButtonStyle::Ghost,
                    cx.listener(|this, _, window, cx| this.home(window, cx)),
                ))
                .into_any_element();
        };
        let names = game.game_version.color_names();
        let max_score = game
            .players
            .iter()
            .map(|player| player.total_score())
            .max()
            .unwrap_or(-1);
        let player_cards =
            div()
                .flex()
                .flex_wrap()
                .gap(px(12.))
                .children(game.players.iter().cloned().map(|player| {
                    let sheet = &player.score_sheet;
                    let is_winner = player.total_score() == max_score;
                    let rows = div()
                        .v_flex()
                        .gap(px(6.))
                        .child(widgets::label_value(
                            names[0],
                            sheet.yellow.to_string(),
                            theme::area_color(game.game_version, 0),
                        ))
                        .child(widgets::label_value(
                            names[1],
                            sheet.green.to_string(),
                            theme::area_color(game.game_version, 1),
                        ))
                        .child(widgets::label_value(
                            names[2],
                            sheet.orange.to_string(),
                            theme::area_color(game.game_version, 2),
                        ))
                        .child(widgets::label_value(
                            names[3],
                            sheet.purple.to_string(),
                            theme::area_color(game.game_version, 3),
                        ))
                        .child(widgets::label_value(
                            names[4],
                            sheet.blue.to_string(),
                            theme::area_color(game.game_version, 4),
                        ))
                        .child(widgets::label_value(
                            "Foxes",
                            sheet.fox_count.to_string(),
                            theme::color(theme::FOX),
                        ))
                        .child(widgets::label_value(
                            "Bonus",
                            sheet.bonus.to_string(),
                            theme::color(theme::BONUS),
                        ))
                        .child(
                            div()
                                .mt(px(6.))
                                .pt(px(6.))
                                .border_t_1()
                                .border_color(cx.theme().border)
                                .flex()
                                .justify_between()
                                .child(
                                    div()
                                        .text_size(px(14.))
                                        .font_weight(FontWeight::BOLD)
                                        .child("Total"),
                                )
                                .child(
                                    div()
                                        .text_size(px(14.))
                                        .font_weight(FontWeight::BOLD)
                                        .child(player.total_score().to_string()),
                                ),
                        );
                    div()
                        .w(px(330.))
                        .flex()
                        .flex_col()
                        .gap(px(10.))
                        .p(px(14.))
                        .rounded(px(12.))
                        .bg(if is_winner {
                            theme::color(0xFFE9A8)
                        } else {
                            surface
                        })
                        .child(
                            div()
                                .text_size(px(18.))
                                .font_weight(FontWeight::BOLD)
                                .child(if is_winner {
                                    format!("{} 🏆", player.name)
                                } else {
                                    player.name
                                }),
                        )
                        .child(rows)
                        .into_any_element()
                }));

        div()
            .v_flex()
            .gap(px(16.))
            .child(widgets::header("Game Details", cx))
            .child(widgets::card(
                surface,
                div()
                    .v_flex()
                    .gap(px(8.))
                    .child(widgets::pill(
                        game.game_version.display_name(),
                        theme::area_color(game.game_version, 0),
                        theme::area_label_color("Yellow"),
                    ))
                    .child(div().text_size(px(14.)).child(format!(
                        "Played on {}",
                        format_date(game.created_at.as_deref(), true)
                    )))
                    .when(!game.notes.is_empty(), |this| {
                        this.child(
                            div()
                                .text_size(px(13.))
                                .text_color(cx.theme().muted_foreground)
                                .child(game.notes.clone()),
                        )
                    }),
            ))
            .child(player_cards)
            .child(widgets::button(
                "details-back",
                "Back",
                widgets::ButtonStyle::Ghost,
                cx.listener(|this, _, window, cx| this.back(window, cx)),
            ))
            .into_any_element()
    }
}
