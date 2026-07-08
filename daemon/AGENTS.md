# daemon

Rust Cargo workspace for the Meshum client daemon: runs on employee machines
(tray icon for status), synchronises settings and decisions from the control
plane. See `docs/architecture.md` for what it does and doesn't do.

- Toolchain pinned in `rust-toolchain.toml`; edition 2024.
- Checks: `just rust` (fmt, taplo, check, clippy, machete, deny, audit,
  nextest); `just fix_rust` to auto-fix; `just test_rust` for tests only.

Coding rules live in `../.claude/rules/rust.md`, path-scoped for Claude Code.
**If your harness does not load `.claude/rules/` automatically, read that file
before editing Rust code here.**
