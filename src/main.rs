use std::sync::Arc;

use gpui_kit::{AppContext as _, WindowOptions, application, open_window};

mod models;
mod storage;
mod theme;
mod ui;

use storage::Database;

fn main() {
    let db = Arc::new(Database::open().expect("failed to open the database"));

    application()
        .with_assets(gpui_kit::assets::Assets)
        .run(move |cx| {
            gpui_kit::init(cx);
            let db = db.clone();
            open_window(WindowOptions::default(), cx, move |window, cx| {
                let db = db.clone();
                cx.new(|cx| ui::app::App::new(db, window, cx))
            })
            .expect("failed to open the main window");
        });
}
