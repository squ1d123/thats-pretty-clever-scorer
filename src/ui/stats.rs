use gpui_kit::{
    AnyElement, Context, FontWeight, IntoElement, ParentElement as _, Styled as _, Window,
    base::StyledExt as _, component::ActiveTheme, div, prelude::FluentBuilder as _, px,
};

use crate::{
    models::{GameVersion, StatsTimeRange},
    theme,
    ui::widgets::{self, ButtonStyle},
};

use super::App;

impl App {
    pub fn set_stats_range(&mut self, range: StatsTimeRange, cx: &mut Context<Self>) {
        self.stats_range = range;
        self.refresh_stats_screen();
        cx.notify();
    }

    pub fn render_stats(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> AnyElement {
        let surface = if self.theme_mode.is_dark() {
            theme::color(theme::DARK_SURFACE)
        } else {
            theme::color(theme::SURFACE)
        };
        let stats = self.stats.clone();

        let range_buttons = div().flex().flex_wrap().gap(px(6.)).children(
            [
                StatsTimeRange::AllTime,
                StatsTimeRange::LastMonth,
                StatsTimeRange::Last3Months,
                StatsTimeRange::Last6Months,
                StatsTimeRange::LastYear,
            ]
            .into_iter()
            .map(|range| {
                widgets::button(
                    ("stats-range", range as usize),
                    range.label(),
                    if self.stats_range == range {
                        ButtonStyle::Primary
                    } else {
                        ButtonStyle::Secondary
                    },
                    cx.listener(move |this, _, _, cx| this.set_stats_range(range, cx)),
                )
            }),
        );

        let selected_version = self.stats_version.unwrap_or(GameVersion::All);
        let version_buttons = div()
            .flex()
            .gap(px(6.))
            .child(widgets::button(
                "stats-version-all",
                format!(
                    "{}All Versions",
                    if selected_version == GameVersion::All {
                        "✓ "
                    } else {
                        ""
                    }
                ),
                if selected_version == GameVersion::All {
                    ButtonStyle::Primary
                } else {
                    ButtonStyle::Secondary
                },
                cx.listener(|this, _, _, cx| this.set_version_filter(None, cx)),
            ))
            .child(widgets::button(
                "stats-version-v1",
                format!(
                    "{}Ganz Schön Clever",
                    if selected_version == GameVersion::V1 {
                        "✓ "
                    } else {
                        ""
                    }
                ),
                if selected_version == GameVersion::V1 {
                    ButtonStyle::Primary
                } else {
                    ButtonStyle::Secondary
                },
                cx.listener(|this, _, _, cx| this.set_version_filter(Some(GameVersion::V1), cx)),
            ))
            .child(widgets::button(
                "stats-version-v2",
                format!(
                    "{}Twice as Clever",
                    if selected_version == GameVersion::V2 {
                        "✓ "
                    } else {
                        ""
                    }
                ),
                if selected_version == GameVersion::V2 {
                    ButtonStyle::Primary
                } else {
                    ButtonStyle::Secondary
                },
                cx.listener(|this, _, _, cx| this.set_version_filter(Some(GameVersion::V2), cx)),
            ));

        if stats.games == 0 {
            return div()
                .v_flex()
                .gap(px(16.))
                .child(widgets::header("Statistics", cx))
                .child(widgets::card(
                    surface,
                    div()
                        .v_flex()
                        .gap(px(10.))
                        .child(range_buttons)
                        .child(version_buttons)
                        .child(
                            div()
                                .py(px(24.))
                                .text_color(cx.theme().muted_foreground)
                                .child("No games to display statistics for yet."),
                        ),
                ))
                .into_any_element();
        }

        let overview = div()
            .flex()
            .gap(px(12.))
            .child(widgets::stat_card(
                stats.games.to_string(),
                "Total Games",
                theme::color(theme::PRIMARY),
            ))
            .child(widgets::stat_card(
                stats.players.to_string(),
                "Total Players",
                theme::color(theme::GREEN),
            ))
            .child(widgets::stat_card(
                stats.highest_score.to_string(),
                "Highest Score",
                theme::color(0xFFC107),
            ));

        let month_max = self
            .games_per_month
            .iter()
            .map(|entry| entry.count)
            .max()
            .unwrap_or(0)
            + 2;
        let months = div()
            .v_flex()
            .gap(px(8.))
            .when(!self.games_per_month.is_empty(), |this| {
                this.children(self.games_per_month.clone().into_iter().map(|entry| {
                    widgets::bar(
                        &entry.name,
                        entry.count as f64,
                        month_max as f64,
                        theme::color(theme::PRIMARY),
                    )
                }))
            })
            .when(self.games_per_month.is_empty(), |this| {
                this.child(
                    div()
                        .text_size(px(12.))
                        .text_color(cx.theme().muted_foreground)
                        .child("No games in this period"),
                )
            });

        let average_max = self
            .position_averages
            .iter()
            .map(|entry| entry.avg_score)
            .fold(0.0, f64::max)
            + 20.0;
        let averages = div()
            .v_flex()
            .gap(px(8.))
            .when(!self.position_averages.is_empty(), |this| {
                this.children(self.position_averages.clone().into_iter().map(|entry| {
                    widgets::bar(
                        &entry.name,
                        entry.avg_score,
                        average_max,
                        theme::color(theme::ORANGE),
                    )
                }))
            })
            .when(self.position_averages.is_empty(), |this| {
                this.child(
                    div()
                        .text_size(px(12.))
                        .text_color(cx.theme().muted_foreground)
                        .child("No data available (need 2+ games with same player)"),
                )
            });

        let win_max = self
            .win_percentages
            .iter()
            .map(|entry| entry.percentage)
            .fold(0.0, f64::max)
            + 10.0;
        let win_max = if win_max <= 10.0 { 100.0 } else { win_max };
        let win_rates = div()
            .v_flex()
            .gap(px(8.))
            .when(!self.win_percentages.is_empty(), |this| {
                this.children(self.win_percentages.clone().into_iter().map(|entry| {
                    widgets::bar(
                        &entry.name,
                        entry.percentage,
                        win_max,
                        theme::color(if entry.percentage > 50.0 {
                            theme::GREEN
                        } else {
                            theme::ORANGE
                        }),
                    )
                }))
            })
            .when(self.win_percentages.is_empty(), |this| {
                this.child(
                    div()
                        .text_size(px(12.))
                        .text_color(cx.theme().muted_foreground)
                        .child("No data available"),
                )
            });

        let top_players = div().v_flex().gap(px(8.)).children(
            self.top_players
                .clone()
                .into_iter()
                .enumerate()
                .map(|(index, player)| {
                    let medal_color = match index {
                        0 => theme::color(0xFFC107),
                        1 => theme::color(0x9E9E9E),
                        2 => theme::color(0xD7A066),
                        _ => theme::color(0x607D8B),
                    };
                    div()
                        .flex()
                        .items_center()
                        .gap(px(10.))
                        .child(
                            div()
                                .size(px(28.))
                                .rounded_full()
                                .bg(medal_color)
                                .text_color(theme::color(0x111111))
                                .text_align(gpui_kit::TextAlign::Center)
                                .child(format!("{}", index + 1)),
                        )
                        .child(
                            div()
                                .v_flex()
                                .flex_1()
                                .child(
                                    div()
                                        .text_size(px(14.))
                                        .font_weight(FontWeight::MEDIUM)
                                        .child(player.name),
                                )
                                .child(
                                    div()
                                        .text_size(px(11.))
                                        .text_color(cx.theme().muted_foreground)
                                        .child(format!("{} games played", player.games)),
                                ),
                        )
                        .child(div().text_size(px(12.)).child(format!(
                            "Avg: {:.0}   Best: {}",
                            player.avg_score, player.max_score
                        )))
                        .into_any_element()
                }),
        );

        div()
            .v_flex()
            .gap(px(16.))
            .child(widgets::header("Statistics", cx))
            .child(widgets::card(
                surface,
                div()
                    .v_flex()
                    .gap(px(10.))
                    .child(range_buttons)
                    .child(version_buttons),
            ))
            .child(overview)
            .child(widgets::card(
                surface,
                div()
                    .v_flex()
                    .gap(px(8.))
                    .child(widgets::title("Games Per Month", 18.))
                    .child(months),
            ))
            .child(widgets::card(
                surface,
                div()
                    .v_flex()
                    .gap(px(8.))
                    .child(widgets::title("Average Score by Player", 18.))
                    .child(averages),
            ))
            .child(widgets::card(
                surface,
                div()
                    .v_flex()
                    .gap(px(8.))
                    .child(widgets::title("Win Percentage by Player", 18.))
                    .child(win_rates),
            ))
            .child(widgets::card(
                surface,
                div()
                    .v_flex()
                    .gap(px(8.))
                    .child(widgets::title("Top Players by Average Score", 18.))
                    .child(top_players),
            ))
            .child(widgets::button(
                "stats-home",
                "Home",
                ButtonStyle::Ghost,
                cx.listener(|this, _, window, cx| this.home(window, cx)),
            ))
            .into_any_element()
    }
}
