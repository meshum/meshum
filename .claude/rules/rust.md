---
paths:
  - "daemon/**/*.rs"
  - "daemon/**/Cargo.toml"
---

# Rust rules

- Workspace lints are strict and non-negotiable: `unsafe_code` is forbidden,
  missing docs on public items warn, clippy pedantic is on. Fix warnings —
  never `#[allow]` them away.
- Document all public items; generated rustdoc is an artefact of this
  requirement (see `docs/quality.md`).
- Dependencies are governed by `deny.toml`; keep them minimal. Prefer the
  standard library.
- Rust is a minimalistic, elegant language — leverage it as such; no
  overengineering (`docs/quality.md`).
- Run `just rust` before considering work done; `just fix_rust` auto-fixes,
  `just test_rust` runs tests only.
