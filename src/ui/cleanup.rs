use std::{path::PathBuf, sync::Arc};

use gpui_kit::{
    AnyElement, App as GuiApp, Context, Hsla, IntoElement, ParentElement as _, Styled as _, Window,
    base::StyledExt as _,
    component::{ActiveTheme, WindowExt, input::Input, notification::Notification},
    div, px,
};

use crate::{
    storage::Database,
    theme,
    ui::widgets::{self, ButtonStyle},
};

use super::App;

fn action_card(
    id: &'static str,
    title: &str,
    description: &str,
    color: Hsla,
    label: &str,
    handler: impl Fn(&gpui_kit::ClickEvent, &mut Window, &mut GuiApp) + 'static,
    cx: &GuiApp,
) -> AnyElement {
    div()
        .flex()
        .items_center()
        .justify_between()
        .gap(px(12.))
        .p(px(14.))
        .rounded(px(12.))
        .bg(color.opacity(0.10))
        .child(
            div()
                .v_flex()
                .gap(px(4.))
                .flex_1()
                .child(
                    div()
                        .text_size(px(15.))
                        .font_weight(gpui_kit::FontWeight::MEDIUM)
                        .child(title.to_string()),
                )
                .child(
                    div()
                        .text_size(px(12.))
                        .text_color(cx.theme().muted_foreground)
                        .child(description.to_string()),
                ),
        )
        .child(widgets::button(id, label, ButtonStyle::Secondary, handler))
        .into_any_element()
}

impl App {
    pub fn apply_custom_path(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let path_value = self.input(&self.path_input, cx);
        let trimmed = path_value.trim();
        let final_path = if trimmed.is_empty() {
            String::new()
        } else {
            let path = PathBuf::from(trimmed);
            let path = if path.is_dir() {
                path.join("ganz-schon-clever-games.db")
            } else {
                path
            };
            path.to_string_lossy().to_string()
        };
        let old_path = self.custom_db_path.clone();
        let result = Database::set_custom_db_path(&final_path).and_then(|_| Database::open());
        match result {
            Ok(database) => {
                self.db = Arc::new(database);
                self.custom_db_path = final_path.clone();
                self.refresh_stats();
                self.refresh_recent_players();
                self.refresh_history();
                self.refresh_high_scores();
                window.push_notification(
                    Notification::success(if final_path.is_empty() {
                        "Reset to the default database path"
                    } else {
                        "Custom database path applied"
                    }),
                    cx,
                );
            }
            Err(error) => {
                let _ = Database::set_custom_db_path(&old_path);
                window.push_notification(
                    Notification::error(format!("Failed to set database path: {error}")),
                    cx,
                );
            }
        }
        cx.notify();
    }

    pub fn export_to(&mut self, csv: bool, window: &mut Window, cx: &mut Context<Self>) {
        let path_value = self.input(&self.export_path_input, cx);
        let path = if path_value.trim().is_empty() {
            self.db
                .path()
                .parent()
                .unwrap_or_else(|| std::path::Path::new("."))
                .join(if csv {
                    "ganz_clever_export.csv"
                } else {
                    "ganz_clever_export.db"
                })
        } else {
            PathBuf::from(path_value.trim())
        };
        let result = if csv {
            self.db
                .export_to_csv()
                .and_then(|data| std::fs::write(&path, data).map_err(|error| error.to_string()))
        } else {
            self.db.export_sqlite(&path)
        };
        match result {
            Ok(()) => window.push_notification(
                Notification::success(format!("Exported to {}", path.display())),
                cx,
            ),
            Err(error) => window.push_notification(
                Notification::error(format!("Failed to export data: {error}")),
                cx,
            ),
        }
    }

    pub fn import_from(&mut self, csv: bool, window: &mut Window, cx: &mut Context<Self>) {
        let path_value = self.input(&self.export_path_input, cx);
        let path = PathBuf::from(path_value.trim());
        let result = if csv {
            std::fs::read_to_string(&path)
                .map_err(|error| error.to_string())
                .and_then(|data| self.db.import_from_csv(&data))
                .map(|count| format!("Imported {count} games"))
        } else {
            self.db
                .import_sqlite(&path)
                .map(|_| "Database imported".to_string())
        };
        match result {
            Ok(message) => {
                self.refresh_stats();
                self.refresh_history();
                self.refresh_high_scores();
                window.push_notification(Notification::success(message), cx);
            }
            Err(error) => window.push_notification(
                Notification::error(format!("Failed to import data: {error}")),
                cx,
            ),
        }
    }

    pub fn render_cleanup(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> AnyElement {
        let surface = if self.theme_mode.is_dark() {
            theme::color(theme::DARK_SURFACE)
        } else {
            theme::color(theme::SURFACE)
        };
        let stats = self.stats.clone();
        let path_label = if Database::uses_custom_path() {
            format!("Custom Path: {}", self.custom_db_path)
        } else {
            format!("Default Path: {}", self.db.path().display())
        };
        let actions = div()
            .v_flex()
            .gap(px(10.))
            .child(action_card(
                "delete-all-games",
                "Delete All Games",
                "Remove every saved game and player record.",
                theme::color(theme::ERROR),
                "Delete All",
                cx.listener(|this, _, window, cx| {
                    let entity = this.entity();
                    window.open_alert_dialog(cx, move |alert, _, _| {
                        let entity = entity.clone();
                        alert
                            .title("Delete All Games?")
                            .description("This cannot be undone.")
                            .ok_text("Delete All")
                            .show_cancel(true)
                            .on_ok(move |_, window, app| {
                                entity.update(app, |this, cx| {
                                    this.handle_db_result(
                                        this.db.delete_all_games(),
                                        "All games deleted",
                                        "delete all games",
                                        window,
                                        cx,
                                    );
                                    this.refresh_stats();
                                    this.refresh_history();
                                    this.refresh_high_scores();
                                    cx.notify();
                                });
                                true
                            })
                    });
                }),
                cx,
            ))
            .child(action_card(
                "clear-high-scores",
                "Clear High Scores",
                "Remove all leaderboard entries. Games are kept.",
                theme::color(theme::ORANGE),
                "Clear",
                cx.listener(|this, _, window, cx| {
                    let entity = this.entity();
                    window.open_alert_dialog(cx, move |alert, _, _| {
                        let entity = entity.clone();
                        alert
                            .title("Clear High Scores?")
                            .description("Games are kept, only the leaderboard is cleared.")
                            .ok_text("Clear")
                            .show_cancel(true)
                            .on_ok(move |_, window, app| {
                                entity.update(app, |this, cx| {
                                    this.handle_db_result(
                                        this.db.clear_high_scores(),
                                        "High scores cleared",
                                        "clear high scores",
                                        window,
                                        cx,
                                    );
                                    this.refresh_stats();
                                    this.refresh_high_scores();
                                    cx.notify();
                                });
                                true
                            })
                    });
                }),
                cx,
            ))
            .child(action_card(
                "export-csv",
                "Export as CSV",
                "Write games and players to a CSV file.",
                theme::color(theme::PRIMARY),
                "Export",
                cx.listener(|this, _, window, cx| this.export_to(true, window, cx)),
                cx,
            ))
            .child(action_card(
                "export-sqlite",
                "Export as SQLite",
                "Copy the complete database to another location.",
                theme::color(theme::PRIMARY),
                "Export",
                cx.listener(|this, _, window, cx| this.export_to(false, window, cx)),
                cx,
            ))
            .child(action_card(
                "import-csv",
                "Import from CSV",
                "Read games and players from a CSV export.",
                theme::color(0x4CAF50),
                "Import",
                cx.listener(|this, _, window, cx| this.import_from(true, window, cx)),
                cx,
            ))
            .child(action_card(
                "import-sqlite",
                "Import from SQLite",
                "Replace the current database with a backup copy first.",
                theme::color(0x4CAF50),
                "Import",
                cx.listener(|this, _, window, cx| {
                    let entity = this.entity();
                    window.open_alert_dialog(cx, move |alert, _, _| {
                        let entity = entity.clone();
                        alert
                            .title("Import Database?")
                            .description(
                                "Your current database is backed up as .db.bak before import.",
                            )
                            .ok_text("Import")
                            .show_cancel(true)
                            .on_ok(move |_, window, app| {
                                entity.update(app, |this, cx| {
                                    this.import_from(false, window, cx);
                                    this.refresh_stats();
                                    this.refresh_history();
                                    this.refresh_high_scores();
                                    cx.notify();
                                });
                                true
                            })
                    });
                }),
                cx,
            ))
            .child(action_card(
                "load-custom-path",
                "Load from Custom Path",
                "Choose a database file for this app to use.",
                theme::color(0x9C27B0),
                "Apply Path",
                cx.listener(|this, _, window, cx| this.apply_custom_path(window, cx)),
                cx,
            ))
            .child(action_card(
                "reset-default-path",
                "Reset to Default Path",
                "Return to the app's default database location.",
                theme::color(0x757575),
                "Reset",
                cx.listener(|this, _, window, cx| {
                    let entity = this.entity();
                    window.open_alert_dialog(cx, move |alert, _, _| {
                        let entity = entity.clone();
                        alert
                            .title("Reset to Default Path?")
                            .description("Data in a custom path will not be affected.")
                            .ok_text("Reset")
                            .show_cancel(true)
                            .on_ok(move |_, window, app| {
                                entity.update(app, |this, cx| {
                                    this.set_input(&this.path_input, "", window, cx);
                                    this.apply_custom_path(window, cx);
                                });
                                true
                            })
                    });
                }),
                cx,
            ))
            .into_any_element();

        div()
            .v_flex()
            .gap(px(16.))
            .child(widgets::header("Manage Data", cx))
            .child(widgets::card(
                surface,
                div()
                    .v_flex()
                    .gap(px(10.))
                    .child(
                        div()
                            .flex()
                            .gap(px(12.))
                            .child(widgets::stat_card(
                                stats.games.to_string(),
                                "Total Games",
                                theme::color(theme::PRIMARY),
                            ))
                            .child(widgets::stat_card(
                                stats.players.to_string(),
                                "Unique Players",
                                theme::color(theme::GREEN),
                            ))
                            .child(widgets::stat_card(
                                stats.highest_score.to_string(),
                                "Highest Score Ever",
                                theme::color(0xFFC107),
                            )),
                    )
                    .child(
                        div()
                            .text_size(px(12.))
                            .text_color(cx.theme().muted_foreground)
                            .child(path_label),
                    ),
            ))
            .child(widgets::card(
                surface,
                div()
                    .v_flex()
                    .gap(px(10.))
                    .child(
                        div()
                            .text_size(px(14.))
                            .child("Database path (directory or .db file)"),
                    )
                    .child(Input::new(&self.path_input)),
            ))
            .child(widgets::card(
                surface,
                div()
                    .v_flex()
                    .gap(px(10.))
                    .child(div().text_size(px(14.)).child("Import/export file path"))
                    .child(Input::new(&self.export_path_input)),
            ))
            .child(actions)
            .child(widgets::button(
                "cleanup-home",
                "Home",
                ButtonStyle::Ghost,
                cx.listener(|this, _, window, cx| this.home(window, cx)),
            ))
            .into_any_element()
    }
}
