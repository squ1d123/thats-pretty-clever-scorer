# Ganz Schön Clever Scorer

A native desktop scoring application for the dice game *Ganz Schön Clever* (That's Pretty Clever), built with Rust and [GPUI-Kit](https://github.com/longbridge/gpui-kit). It is a port of the original Flutter application and preserves its scoring rules, game versions, and data format.

## Features

- Score entry for up to four players across all six areas (yellow, green, orange, purple, blue, and foxes/bonus), with live totals.
- Automatic scoring for each area, including both original game versions and their different colour values.
- Bonus calculation: lowest strictly positive area score multiplied by the number of foxes.
- Game setup with recent-player suggestions and name search.
- Final scores with winner highlighting (all tied winners are highlighted).
- Game history with search, player/version filters, sorting, details, and deletion.
- High-score leaderboard with version filtering and expandable game details.
- Statistics: games per month, average score per player, win percentage, and top players, filtered by time range and game version.
- Data management: delete all games, clear high scores, CSV/SQLite export and import, and configurable database location.
- Light and dark themes.

## Requirements

- Rust 1.85+ (edition 2024) via [rustup](https://rustup.rs/)
- A system SQLite development library (`libsqlite3-dev` on Debian/Ubuntu, `sqlite3-devel` on Fedora)
- GPUI's platform dependencies on Linux (Vulkan/wayland/X11 development packages)

## Build and run

With [mise](https://mise.jdx.dev/) installed, trust the project config once, then use the short task aliases:

```bash
mise trust
mise run build   # or: mise run b
mise run run     # or: mise run r
mise run release # or: mise run rel
```

The raw Cargo commands still work as well:

```bash
cargo build
cargo run
cargo build --release
```

Release binaries are written to `target/release/ganz-clever-scorer`.

## Tests

```bash
mise run test    # or: mise run t
mise run check   # or: mise run c — formatting, clippy and tests
```

Equivalent raw commands:

```bash
cargo test
cargo clippy --all-targets -- -D warnings
cargo fmt --all -- --check
```

The suite covers the scoring rules (area scoring, bonus, winner selection) and the SQLite layer (save/load, high scores and statistics, CSV round trip).

## Architecture

```
src/
├── main.rs              # Application bootstrap (GPUI-Kit window)
├── models.rs            # Score sheets, players, games, summaries and statistics
├── storage.rs           # SQLite schema, queries, CSV/SQLite import and export
├── theme.rs             # Colours matching the original Flutter theme
└── ui/
    ├── app.rs           # Root App entity, screen router and shared state
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

The app uses a single retained `App` entity. All inputs are `Entity<InputState>` objects with subscriptions that update state in place; navigation is an enum-based screen stack in `App`. Persistence uses SQLite through `rusqlite` with a mutex-protected connection.

## Data storage

By default games are stored in `games.db` in the user's Documents directory. A custom file or directory can be configured from the **Manage Data** screen; the choice is saved in the user config directory under `ganz-clever-scorer/database_path.txt`. A custom directory is resolved to `<directory>/ganz-schon-clever-games.db`.

CSV exports contain `Games:` and `Players:` sections and can be imported from the same screen. SQLite imports first back up the active database as `<database>.db.bak`.

## Behaviour notes

The port intentionally preserves two quirks of the original application:

- The bonus uses the lowest *strictly positive* area value multiplied by the fox count.
- The calculator's area labels are offset by one relative to the fields they edit (the label named `green` edits green, `orange` edits orange, and so on), matching the original label mapping.

Games loaded from history do not display a stored winner, again matching the original behaviour.
