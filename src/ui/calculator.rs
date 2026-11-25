use gpui_kit::{
    AnyElement, Context, Entity, Hsla, IntoElement, ParentElement as _, Styled as _, Window,
    base::StyledExt as _,
    component::{
        ActiveTheme,
        input::{Input, InputState},
    },
    div, px,
};

use crate::{
    theme,
    ui::widgets::{self, ButtonStyle},
};

use super::{App, Screen};

fn score_input_row(
    label: &str,
    color: Hsla,
    input: &Entity<InputState>,
    is_fox: bool,
) -> AnyElement {
    let badge = if is_fox {
        div()
            .size(px(28.))
            .rounded_full()
            .bg(color)
            .text_color(theme::area_label_color(label))
            .text_align(gpui_kit::TextAlign::Center)
            .text_size(px(14.))
            .child("🦊")
    } else {
        div()
            .size(px(28.))
            .rounded_full()
            .bg(color)
            .text_color(theme::area_label_color(label))
            .text_align(gpui_kit::TextAlign::Center)
            .text_size(px(11.))
            .child(label.to_string())
    };
    div()
        .flex()
        .items_center()
        .gap(px(10.))
        .child(badge)
        .child(div().w(px(90.)).text_size(px(13.)).child(label.to_string()))
        .child(Input::new(input).flex_1())
        .into_any_element()
}

impl App {
    pub fn render_calculator(
        &mut self,
        _window: &mut Window,
        cx: &mut Context<Self>,
    ) -> AnyElement {
        let surface = if self.theme_mode.is_dark() {
            theme::color(theme::DARK_SURFACE)
        } else {
            theme::color(theme::SURFACE)
        };
        let players = self.session.players.clone();
        let version = self.session.game_version;
        let names = version.color_names();

        let cards =
            div()
                .flex()
                .flex_wrap()
                .gap(px(12.))
                .children(
                    players
                        .into_iter()
                        .enumerate()
                        .map(|(player_index, player)| {
                            let offset = player_index * 6;
                            let rows = div()
                                .v_flex()
                                .gap(px(8.))
                                .child(score_input_row(
                                    names[0],
                                    theme::area_color(version, 0),
                                    &self.score_inputs[offset],
                                    false,
                                ))
                                .child(score_input_row(
                                    names[1],
                                    theme::area_color(version, 1),
                                    &self.score_inputs[offset + 1],
                                    false,
                                ))
                                .child(score_input_row(
                                    names[2],
                                    theme::area_color(version, 2),
                                    &self.score_inputs[offset + 2],
                                    false,
                                ))
                                .child(score_input_row(
                                    names[3],
                                    theme::area_color(version, 3),
                                    &self.score_inputs[offset + 3],
                                    false,
                                ))
                                .child(score_input_row(
                                    names[4],
                                    theme::area_color(version, 4),
                                    &self.score_inputs[offset + 4],
                                    false,
                                ))
                                .child(score_input_row(
                                    "Foxes",
                                    theme::color(theme::FOX),
                                    &self.score_inputs[offset + 5],
                                    true,
                                ));
                            let sheet = &player.score_sheet;
                            div()
                                .w(px(380.))
                                .flex()
                                .flex_col()
                                .gap(px(12.))
                                .p(px(16.))
                                .rounded(px(12.))
                                .bg(surface)
                                .child(
                                    div()
                                        .text_size(px(20.))
                                        .font_weight(gpui_kit::FontWeight::BOLD)
                                        .child(player.name),
                                )
                                .child(rows)
                                .child(
                                    div()
                                        .flex()
                                        .justify_between()
                                        .pt(px(8.))
                                        .border_t_1()
                                        .border_color(cx.theme().border)
                                        .child(
                                            div()
                                                .text_size(px(14.))
                                                .child(format!("Bonus: {}", sheet.bonus)),
                                        )
                                        .child(
                                            div()
                                                .text_size(px(18.))
                                                .font_weight(gpui_kit::FontWeight::BOLD)
                                                .child(format!("Total: {}", sheet.total())),
                                        ),
                                )
                                .into_any_element()
                        }),
                );

        div()
            .v_flex()
            .gap(px(16.))
            .child(widgets::header("Score Calculator", cx))
            .child(
                div()
                    .text_size(px(13.))
                    .text_color(cx.theme().muted_foreground)
                    .child("Enter the totals for each area. Bonus = lowest positive area × foxes."),
            )
            .child(cards)
            .child(
                div()
                    .flex()
                    .gap(px(10.))
                    .child(widgets::button(
                        "calculator-setup",
                        "Setup",
                        ButtonStyle::Secondary,
                        cx.listener(|this, _, window, cx| this.back(window, cx)),
                    ))
                    .child(widgets::button(
                        "calculator-final",
                        "Final Scores",
                        ButtonStyle::Primary,
                        cx.listener(|this, _, window, cx| {
                            this.apply_scores_from_inputs(cx);
                            this.go(Screen::FinalScores, window, cx);
                        }),
                    )),
            )
            .into_any_element()
    }
}
