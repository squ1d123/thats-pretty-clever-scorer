use gpui_kit::{
    AnyElement, AppContext as _, Context, FontWeight, IntoElement, ParentElement as _, Styled as _,
    Window,
    base::StyledExt as _,
    component::{
        WindowExt,
        input::{Input, InputState},
        notification::Notification,
    },
    div, px,
};

use crate::{
    theme,
    ui::widgets::{self, ButtonStyle},
};

use super::{App, Screen};

impl App {
    pub fn render_final_scores(
        &mut self,
        _window: &mut Window,
        cx: &mut Context<Self>,
    ) -> AnyElement {
        let surface = if self.theme_mode.is_dark() {
            theme::color(theme::DARK_SURFACE)
        } else {
            theme::color(theme::SURFACE)
        };
        let max_score = self.session.max_score();
        let players = self.session.players.clone();

        let cards = div()
            .v_flex()
            .gap(px(10.))
            .children(players.into_iter().map(|player| {
                let is_winner = player.total_score() == max_score;
                let background = if is_winner {
                    theme::color(0xFFE9A8)
                } else {
                    surface
                };
                div()
                    .flex()
                    .items_center()
                    .justify_between()
                    .p(px(16.))
                    .rounded(px(12.))
                    .bg(background)
                    .child(
                        div()
                            .text_size(px(18.))
                            .font_weight(FontWeight::BOLD)
                            .child(format!(
                                "{}{}",
                                player.name,
                                if is_winner { " 🏆 (WINNER)" } else { "" }
                            )),
                    )
                    .child(
                        div()
                            .text_size(px(16.))
                            .child(format!("{} points", player.total_score())),
                    )
                    .into_any_element()
            }));

        div()
            .v_flex()
            .gap(px(16.))
            .child(widgets::header("Final Scores", cx))
            .child(widgets::card(surface, cards))
            .child(
                div()
                    .flex()
                    .gap(px(10.))
                    .child(widgets::button(
                        "final-calculator",
                        "Calculator",
                        ButtonStyle::Secondary,
                        cx.listener(|this, _, window, cx| this.back(window, cx)),
                    ))
                    .child(widgets::button(
                        "final-save",
                        "Save Game",
                        ButtonStyle::Success,
                        cx.listener(|this, _, window, cx| {
                            let entity = this.entity();
                            let notes_input = cx.new(|cx| {
                                InputState::new(window, cx).placeholder("Enter optional notes...")
                            });
                            window.open_alert_dialog(cx, move |alert, _, _app| {
                                let entity = entity.clone();
                                let notes_input = notes_input.clone();
                                alert
                                    .title("Save Game")
                                    .description(Input::new(&notes_input))
                                    .ok_text("Save")
                                    .show_cancel(true)
                                    .on_ok(move |_, window, app| {
                                        entity.update(app, |this, cx| {
                                            let notes = this.input(&notes_input, cx);
                                            match this.db.save_game(&mut this.session, &notes) {
                                                Ok(_) => {
                                                    this.refresh_stats();
                                                    window.push_notification(
                                                        Notification::success(
                                                            "Game saved successfully!",
                                                        ),
                                                        cx,
                                                    );
                                                    cx.notify();
                                                }
                                                Err(error) => window.push_notification(
                                                    Notification::error(format!(
                                                        "Failed to save game: {error}"
                                                    )),
                                                    cx,
                                                ),
                                            }
                                        });
                                        true
                                    })
                            });
                        }),
                    ))
                    .child(widgets::button(
                        "final-new-game",
                        "New Game",
                        ButtonStyle::Primary,
                        cx.listener(|this, _, window, cx| {
                            this.session = crate::models::GameSession {
                                game_version: this.session.game_version,
                                ..Default::default()
                            };
                            this.go_replace(Screen::Setup, window, cx);
                        }),
                    )),
            )
            .into_any_element()
    }
}
