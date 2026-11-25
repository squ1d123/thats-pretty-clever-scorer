use gpui_kit::{
    AnyElement, App, ClickEvent, ElementId, FontWeight, Hsla, IntoElement, ParentElement as _,
    SharedString, Styled, Window,
    component::{ActiveTheme, button::Button, button::ButtonVariants},
    div, px,
};

#[derive(Clone, Copy, Default)]
pub enum ButtonStyle {
    #[default]
    Primary,
    Secondary,
    Success,
    Danger,
    Ghost,
}

pub fn button(
    id: impl Into<ElementId>,
    label: impl Into<SharedString>,
    style: ButtonStyle,
    handler: impl Fn(&ClickEvent, &mut Window, &mut App) + 'static,
) -> AnyElement {
    let button = Button::new(id).label(label).on_click(handler);
    let button = match style {
        ButtonStyle::Primary => button.primary(),
        ButtonStyle::Secondary => button.secondary(),
        ButtonStyle::Success => button.success(),
        ButtonStyle::Danger => button.danger(),
        ButtonStyle::Ghost => button.ghost(),
    };
    button.into_any_element()
}

pub fn colored_button(
    id: impl Into<ElementId>,
    label: impl Into<SharedString>,
    background: Hsla,
    foreground: Hsla,
    handler: impl Fn(&ClickEvent, &mut Window, &mut App) + 'static,
) -> AnyElement {
    Button::new(id)
        .label(label)
        .bg(background)
        .text_color(foreground)
        .rounded(px(12.))
        .on_click(handler)
        .into_any_element()
}

pub fn title(text: impl Into<SharedString>, size: f32) -> AnyElement {
    let text: SharedString = text.into();
    div()
        .text_size(px(size))
        .font_weight(FontWeight::BOLD)
        .child(text)
        .into_any_element()
}

pub fn card(background: Hsla, content: impl IntoElement) -> AnyElement {
    div()
        .p(px(16.))
        .rounded(px(12.))
        .bg(background)
        .child(content)
        .into_any_element()
}

pub fn pill(text: impl Into<SharedString>, background: Hsla, foreground: Hsla) -> AnyElement {
    let text: SharedString = text.into();
    div()
        .px(px(10.))
        .py(px(4.))
        .rounded(px(6.))
        .bg(background)
        .text_color(foreground)
        .text_size(px(12.))
        .child(text)
        .into_any_element()
}

pub fn label_value(
    label: impl Into<SharedString>,
    value: impl Into<SharedString>,
    color: Hsla,
) -> AnyElement {
    let label: SharedString = label.into();
    let value: SharedString = value.into();
    div()
        .flex()
        .items_center()
        .gap(px(12.))
        .child(
            div()
                .w(px(80.))
                .py(px(4.))
                .rounded(px(4.))
                .bg(color)
                .text_color(crate::theme::area_label_color(&label))
                .text_center()
                .text_size(px(12.))
                .child(label),
        )
        .child(div().text_size(px(13.)).child(value))
        .into_any_element()
}

pub fn message_banner(message: &str, cx: &App) -> AnyElement {
    if message.is_empty() {
        return div().into_any_element();
    }
    div()
        .p(px(10.))
        .rounded(px(8.))
        .bg(cx.theme().accent.opacity(0.15))
        .text_color(cx.theme().accent)
        .child(message.to_string())
        .into_any_element()
}

pub fn stat_card(
    value: impl Into<SharedString>,
    description: impl Into<SharedString>,
    color: Hsla,
) -> AnyElement {
    let value: SharedString = value.into();
    let description: SharedString = description.into();
    div()
        .flex_1()
        .p(px(14.))
        .rounded(px(12.))
        .bg(color.opacity(0.12))
        .flex()
        .flex_col()
        .items_center()
        .gap(px(4.))
        .child(
            div()
                .text_size(px(24.))
                .font_weight(FontWeight::BOLD)
                .text_color(color)
                .child(value),
        )
        .child(div().text_size(px(12.)).child(description))
        .into_any_element()
}

pub fn header(title_text: &str, cx: &App) -> AnyElement {
    div()
        .flex()
        .items_center()
        .justify_between()
        .pb(px(12.))
        .child(title(title_text, 28.))
        .child(
            div()
                .text_size(px(12.))
                .italic()
                .text_color(cx.theme().muted_foreground)
                .child("Ganz Schön Clever Scorer"),
        )
        .into_any_element()
}

pub fn bar(label: &str, value: f64, maximum: f64, color: Hsla) -> AnyElement {
    let width = if maximum <= 0.0 {
        0.0
    } else {
        (value / maximum * 100.0).clamp(0.0, 100.0)
    };
    div()
        .flex()
        .flex_col()
        .gap(px(4.))
        .child(
            div()
                .flex()
                .justify_between()
                .text_size(px(12.))
                .child(label.to_string())
                .child(format!("{value:.0}")),
        )
        .child(
            div()
                .h(px(10.))
                .w_full()
                .rounded(px(5.))
                .bg(color.opacity(0.15))
                .child(
                    div()
                        .h_full()
                        .w(gpui_kit::rems((width / 100.0 * 40.0) as f32))
                        .rounded(px(5.))
                        .bg(color),
                ),
        )
        .into_any_element()
}
