use gpui_kit::{
    AnyElement, Context, IntoElement, ParentElement as _, Styled as _, Window,
    base::StyledExt as _,
    component::{ActiveTheme, input::Input},
    div,
    prelude::FluentBuilder as _,
    px,
};

use crate::{
    models::GameVersion,
    theme,
    ui::widgets::{self, ButtonStyle},
};

use super::{App, Screen};

impl App {
    pub fn search_players(&mut self, cx: &mut Context<Self>) {
        let query = self.input(&self.search_input, cx);
        self.recent_names = if query.trim().is_empty() {
            self.db.get_recent_player_names(5).unwrap_or_default()
        } else {
            self.db
                .search_player_names(query.trim(), 20)
                .unwrap_or_default()
        };
        cx.notify();
    }

    pub fn add_player_name(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let name = self.input(&self.name_input, cx);
        let name = name.trim().to_string();
        if name.is_empty() {
            return;
        }
        if self.session.add_player(&name) {
            self.set_input(&self.name_input, "", window, cx);
            self.refresh_recent_players();
            cx.notify();
        }
    }

    pub fn render_setup(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> AnyElement {
        let surface = if self.theme_mode.is_dark() {
            theme::color(theme::DARK_SURFACE)
        } else {
            theme::color(theme::SURFACE)
        };
        let version = self.setup_version;
        let colors = version.colors();
        let color_names = version.color_names();

        let swatches =
            div()
                .flex()
                .flex_wrap()
                .gap(px(10.))
                .children(colors.into_iter().enumerate().map(|(index, color)| {
                    div()
                        .flex()
                        .flex_col()
                        .items_center()
                        .gap(px(4.))
                        .child(div().size(px(24.)).rounded(px(6.)).bg(theme::color(color)))
                        .child(
                            div()
                                .text_size(px(11.))
                                .child(color_names[index].to_string()),
                        )
                        .into_any_element()
                }));

        let quick_add = div().flex().flex_wrap().gap(px(8.)).children(
            self.recent_names
                .clone()
                .into_iter()
                .enumerate()
                .map(|(index, name)| {
                    widgets::button(
                        ("quick-add", index),
                        name.clone(),
                        ButtonStyle::Secondary,
                        cx.listener(move |this, _, _, cx| {
                            this.session.add_player(&name);
                            this.refresh_recent_players();
                            cx.notify();
                        }),
                    )
                }),
        );

        let players = div().v_flex().gap(px(8.)).children(
            self.session
                .players
                .clone()
                .into_iter()
                .enumerate()
                .map(|(index, player)| {
                    div()
                        .flex()
                        .items_center()
                        .justify_between()
                        .p(px(10.))
                        .rounded(px(10.))
                        .bg(cx.theme().accent.opacity(0.08))
                        .child(
                            div()
                                .flex()
                                .items_center()
                                .gap(px(10.))
                                .child(
                                    div()
                                        .size(px(28.))
                                        .rounded_full()
                                        .bg(theme::color(theme::PRIMARY))
                                        .text_color(theme::color(0xFFFFFF))
                                        .text_center()
                                        .text_size(px(13.))
                                        .child(format!("{}", index + 1)),
                                )
                                .child(div().child(player.name)),
                        )
                        .child(widgets::button(
                            ("remove-player", index),
                            "Remove",
                            ButtonStyle::Danger,
                            cx.listener(move |this, _, _, cx| {
                                this.session.remove_player(index);
                                cx.notify();
                            }),
                        ))
                        .into_any_element()
                }),
        );

        div()
            .v_flex()
            .gap(px(18.))
            .child(widgets::header("Game Setup", cx))
            .child(widgets::card(
                surface,
                div()
                    .v_flex()
                    .gap(px(12.))
                    .child(div().text_size(px(14.)).child("Game Version"))
                    .child(
                        div()
                            .flex()
                            .gap(px(8.))
                            .child(widgets::button(
                                "version-v1",
                                GameVersion::V1.display_name(),
                                if version == GameVersion::V1 {
                                    ButtonStyle::Primary
                                } else {
                                    ButtonStyle::Secondary
                                },
                                cx.listener(|this, _, _, cx| {
                                    this.setup_version = GameVersion::V1;
                                    this.session.game_version = GameVersion::V1;
                                    cx.notify();
                                }),
                            ))
                            .child(widgets::button(
                                "version-v2",
                                GameVersion::V2.display_name(),
                                if version == GameVersion::V2 {
                                    ButtonStyle::Primary
                                } else {
                                    ButtonStyle::Secondary
                                },
                                cx.listener(|this, _, _, cx| {
                                    this.setup_version = GameVersion::V2;
                                    this.session.game_version = GameVersion::V2;
                                    cx.notify();
                                }),
                            )),
                    )
                    .child(div().child(format!("Colors: {}", color_names.join(", "))))
                    .child(swatches),
            ))
            .child(widgets::card(
                surface,
                div()
                    .v_flex()
                    .gap(px(10.))
                    .child(div().text_size(px(14.)).child("Add Players (1–4)"))
                    .child(Input::new(&self.search_input))
                    .child(quick_add)
                    .child(
                        div()
                            .flex()
                            .gap(px(8.))
                            .child(Input::new(&self.name_input).flex_1())
                            .child(widgets::button(
                                "add-player",
                                "Add",
                                ButtonStyle::Success,
                                cx.listener(|this, _, window, cx| this.add_player_name(window, cx)),
                            )),
                    ),
            ))
            .child(widgets::card(surface, players))
            .child(
                div()
                    .flex()
                    .gap(px(10.))
                    .child(widgets::button(
                        "setup-home",
                        "Home",
                        ButtonStyle::Ghost,
                        cx.listener(|this, _, window, cx| this.home(window, cx)),
                    ))
                    .when(!self.session.players.is_empty(), |this| {
                        this.child(widgets::button(
                            "setup-calculator",
                            "Calculator",
                            ButtonStyle::Primary,
                            cx.listener(|this, _, window, cx| {
                                this.session.calculate_scores();
                                this.go(Screen::Calculator, window, cx);
                            }),
                        ))
                    }),
            )
            .into_any_element()
    }
}
