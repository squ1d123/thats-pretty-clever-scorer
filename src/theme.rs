use gpui_kit::{Hsla, rgb};

use crate::models::GameVersion;

pub const PRIMARY: u32 = 0x2196F3;
pub const BACKGROUND: u32 = 0xF5F5F5;
pub const SURFACE: u32 = 0xFFFFFF;
pub const DARK_BACKGROUND: u32 = 0x121212;
pub const DARK_SURFACE: u32 = 0x1E1E1E;
pub const ERROR: u32 = 0xE53935;

pub const GREEN: u32 = 0x32CD32;
pub const ORANGE: u32 = 0xFFFF8C00;
pub const FOX: u32 = 0xFF6B35;
pub const BONUS: u32 = 0xFFD700;

pub fn color(hex: u32) -> Hsla {
    rgb(hex).into()
}

pub fn area_color(version: GameVersion, index: usize) -> Hsla {
    color(version.colors()[index.min(4)])
}

pub fn area_label_color(label: &str) -> Hsla {
    match label.to_ascii_lowercase().as_str() {
        "yellow" | "silver" | "bonus" | "foxes" => color(0x111111),
        _ => color(0xFFFFFF),
    }
}
