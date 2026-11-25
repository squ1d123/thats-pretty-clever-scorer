use gpui_kit::{
    AnyElement, App, ClickEvent, Context, Hsla, IntoElement, ParentElement as _, Styled as _,
    Window,
    base::StyledExt as _,
    component::{WindowExt, notification::Notification},
    div, px,
};

use crate::{
    theme,
    ui::widgets::{self, ButtonStyle},
};

use super::{App as ScorerApp, Screen};

fn menu_button(
    id: &'static str,
    label: &'static str,
    color: Hsla,
    foreground: Hsla,
    handler: impl Fn(&ClickEvent, &mut Window, &mut App) + 'static,
) -> AnyElement {
    widgets::colored_button(id, label, color, foreground, handler)
}

impl ScorerApp {
    pub fn render_main_menu(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> AnyElement {
        let surface = if self.theme_mode.is_dark() {
            theme::color(theme::DARK_SURFACE)
        } else {
            theme::color(theme::SURFACE)
        };
        let stats = self.stats.clone();

        let overview = div()
            .flex()
            .gap(px(12.))
            .child(widgets::stat_card(
                stats.games.to_string(),
                "Games",
                theme::color(theme::PRIMARY),
            ))
            .child(widgets::stat_card(
                stats.players.to_string(),
                "Players",
                theme::color(theme::GREEN),
            ))
            .child(widgets::stat_card(
                stats.highest_score.to_string(),
                "Best",
                theme::color(0xFFC107),
            ));

        div()
            .v_flex()
            .gap(px(18.))
            .child(widgets::header("Main Menu", cx))
            .child(widgets::card(
                surface,
                div()
                    .v_flex()
                    .gap(px(12.))
                    .child(
                        div()
                            .text_size(px(16.))
                            .child("Track your scores for the popular dice game!"),
                    )
                    .child(overview),
            ))
            .child(
                div()
                    .v_flex()
                    .gap(px(10.))
                    .child(menu_button(
                        "menu-new-game",
                        "New Game",
                        theme::color(0x4CAF50),
                        theme::color(0xFFFFFF),
                        cx.listener(|this, _, window, cx| this.go(Screen::Setup, window, cx)),
                    ))
                    .child(menu_button(
                        "menu-history",
                        "Game History",
                        theme::color(theme::PRIMARY),
                        theme::color(0xFFFFFF),
                        cx.listener(|this, _, window, cx| this.go(Screen::History, window, cx)),
                    ))
                    .child(menu_button(
                        "menu-high-scores",
                        "High Scores",
                        theme::color(0xFFC107),
                        theme::color(0x111111),
                        cx.listener(|this, _, window, cx| this.go(Screen::HighScores, window, cx)),
                    ))
                    .child(menu_button(
                        "menu-data",
                        "Manage Data",
                        theme::color(0xFF9800),
                        theme::color(0xFFFFFF),
                        cx.listener(|this, _, window, cx| this.go(Screen::Cleanup, window, cx)),
                    ))
                    .child(menu_button(
                        "menu-stats",
                        "Statistics",
                        theme::color(0x9C27B0),
                        theme::color(0xFFFFFF),
                        cx.listener(|this, _, window, cx| this.go(Screen::Stats, window, cx)),
                    )),
            )
            .child(widgets::button(
                "menu-calculator",
                "Calculator",
                ButtonStyle::Secondary,
                cx.listener(|this, _, window, cx| {
                    if this.session.players.is_empty() {
                        window
                            .push_notification(Notification::warning("Start a new game first"), cx);
                    } else {
                        this.session.calculate_scores();
                        this.go(Screen::Calculator, window, cx);
                    }
                }),
            ))
            .into_any_element()
    }
}
