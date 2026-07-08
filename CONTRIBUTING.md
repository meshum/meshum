# Contributing

## AI usage

AI assistance is welcome under the conditions in [AI-POLICY.md](AI-POLICY.md):
you remain fully responsible for what you submit, and disclosure of AI
involvement is expected.

## Layout

Monorepo with two main pieces:

- `daemon/` — Rust client-side daemon. Cargo workspace (`resolver = "3"`), members `crates/*`. Toolchain pinned in `daemon/rust-toolchain.toml` (1.96.0, edition 2024). Config: `clippy.toml`, `deny.toml` (license/advisory policy), `rustfmt.toml`.
- `server/` — Elixir Mix umbrella (`apps_path: "apps"`) with three apps:
  - `meshum` — core business logic, Ecto/Postgres.
  - `meshum_gateway` — Phoenix API-only JSON gateway.
  - `meshum_web` — Phoenix + LiveView web app, depends on `meshum` in-umbrella.

  Elixir/OTP pinned at the repo root in `.tool-versions` (`elixir 1.20.2-otp-29`).

Root tooling: `justfile` (task runner, used both locally and in CI), `cliff.toml` (changelog config), `LICENSE.md`.

## Setup

```
just setup
```

Installs the required cargo tools, fetches/builds the daemon, and fetches/compiles/sets up the server.

## Before pushing

Run the checks relevant to what you touched — these are the same checks CI runs (`.github/workflows/daemon.yml`, `server.yml`), so running them locally avoids CI failures.

- `just` - runs `just rust` and `just elixir`
- `just rust` — format (rustfmt + taplo), lint (cargo check + clippy with `-D warnings`), dependency checks (cargo-machete, cargo-deny, cargo-audit), and tests (cargo-nextest). Sub-recipes (`fmt_rust`, `clippy_rust`, `test_rust`, etc.) exist if you only want one check.
- `just fix_rust` — auto-fixes what it can: `cargo clippy --fix --allow-dirty`, `cargo fmt`, `taplo format`.
- `just elixir` — runs `mix check` in `server/`, which covers compiler warnings-as-errors, formatter check, Credo, Dialyzer, Sobelow, unused-deps check, and ExUnit in one command.
- `just commits` — validates commit messages against `origin/master..HEAD` via `committed`.

## Commit messages

Commit messages must follow [Conventional Commits](https://www.conventionalcommits.org/). This is enforced in CI via `just commits` (the `commits` job in both `daemon.yml` and `server.yml`) — run `just commits` locally before pushing.

## Editor

Opening the repo in VS Code will prompt you to install the recommended extensions (`.vscode/extensions.json`): Elixir (ElixirLS, Phoenix, formatter, Hex package intellisense), Rust (rust-analyzer), and even-better-toml.

## License

AGPL-3.0, dual-licensed with a commercial option — see [LICENSE.md](LICENSE.md).

## Signing the CLA

Before your first pull request can be merged, you must sign a Contributor Licence
Agreement. Meshum is AGPL-3.0 with a commercial dual licence, so we need the right to
relicense your contribution — see [`docs/legal/README.md`](docs/legal/README.md) for the
why.

- Contributing as an individual? Sign the [Individual CLA](docs/legal/icla.md).
- Contributing on behalf of an employer? Have an authorised representative sign the
  [Corporate CLA](docs/legal/ccla.md).

The CLA bot posts a comment on your pull request with the exact phrase to copy-paste. The
`CLA` status check is required and blocks the merge until you have signed — it updates
automatically within seconds. Questions go to **legal@meshum.dev**.
