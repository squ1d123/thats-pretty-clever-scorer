# Agent Instructions

## Project Overview

- **Name:** Ganz Schön Clever Scorer
- **Type:** Rust desktop application (GPUI-Kit)
- **Purpose:** Scoring application for the dice game "Ganz Schön Clever" (That's Pretty Clever)
- **Target Platform:** Desktop (Linux, macOS, Windows via GPUI)

## Tech Stack

- **Framework:** GPUI-Kit 0.7 (`gpui-kit` crate)
- **State Management:** A single retained `App` entity; Riverpod is no longer used
- **Navigation:** `Screen` enum stack inside `App`; GoRouter is no longer used
- **Database:** SQLite through `rusqlite` (system SQLite); `sqflite` is no longer used
- **Additional:** `chrono`, `regex`, `dirs`

## Key Commands

```bash
# Run the app
cargo run

# Run tests
cargo test

# Analyze/format
cargo clippy
cargo fmt -- --check

# Build release binary
cargo build --release
```

## Architecture

```
src/
├── main.rs              # GPUI-Kit application bootstrap
├── models.rs            # Score sheets, players, game sessions, summaries, statistics
├── storage.rs           # SQLite schema, CRUD, queries, CSV/SQLite import/export
├── theme.rs             # Colours matching the original Flutter app
└── ui/
    ├── app.rs           # Root App entity, screen router, shared state and inputs
    ├── widgets.rs       # Shared buttons, cards, labels and bars
    ├── main_menu.rs
    ├── setup.rs
    ├── calculator.rs
    ├── final_scores.rs
    ├── history.rs
    ├── details.rs
    ├── high_scores.rs
    ├── cleanup.rs
    └── stats.rs
```

## Database Schema

- **games:** id, uuid, created_at, completed_at, player_count, winner_name, winner_score, notes, game_version
- **players:** id, game_id, name, final_score, winner, yellow/green/orange/purple/blue totals, fox_count, bonus
- **high_scores:** id, game_id, player_name, score, achieved_at

## Testing

Unit tests live next to the logic they cover in `src/models.rs` and `src/storage.rs`. Run them with `cargo test`.

## Code Style

- Follow standard Rust formatting (`cargo fmt`) and clippy conventions
- Keep GPUI idioms: retained entities, `cx.notify()`, `cx.listener(...)`, `cx.subscribe_in(...)`
- No additional comments unless explicitly requested
