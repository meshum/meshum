# Meshum daemon

The Meshum client daemon: a Rust binary that runs on employee machines with a
tray icon for status. It synchronises settings and decisions from the Meshum
control plane onto the local machine — agents, skills, configs, agent settings
(think `~/.claude/settings.json`), and hooks. It governs; it does not enforce
or block anything locally.

See [`docs/architecture.md`](../docs/architecture.md) for how it fits into
Meshum as a whole.

## Development

- Toolchain: pinned in [`rust-toolchain.toml`](rust-toolchain.toml)
  (Rust 1.96.0, edition 2024), installed automatically by `rustup`.
- Checks: `just rust` from the repo root (fmt, taplo, check, clippy, machete,
  deny, audit, nextest); `just fix_rust` auto-fixes; `just test_rust` runs
  tests only.
