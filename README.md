# Meshum

[**meshum.dev**](https://www.meshum.dev) · [Repository](https://github.com/meshum/meshum)

Meshum provides **centralized governance for AI usage within an organization**. It collects
AI telemetry, distributes skills, agents, and AI-related tooling, and lets you govern which
MCP (Model Context Protocol) servers your employees can use — down to controlling which
individual tools inside an MCP are exposed.

> **Status:** early / `0.0.1`. Interfaces are unstable and may change without notice.

## Tech stack & toolchains

Toolchains are pinned in the repo:

- **Elixir** `1.20.2-otp-29` — [`.tool-versions`](.tool-versions) (use [asdf](https://asdf-vm.com)).
- **Rust** `1.96.0` (edition 2024) — [`daemon/rust-toolchain.toml`](daemon/rust-toolchain.toml);
  `rustup` installs it automatically. `unsafe_code` is forbidden at the workspace level.

The server targets **PostgreSQL** (via Ecto).

## Getting started

Prerequisites: a working Rust toolchain (rustup), Elixir `1.20.2-otp-29`, Postgres, and
[`just`](https://just.systems). Then:

```sh
just setup
```

This installs the cargo tools used by CI, fetches/builds the daemon, and fetches, compiles,
and sets up the server (deps, compile, `mix setup`).

## Common tasks

All checks are run through `just` and mirror what CI runs (see
[`.github/workflows/`](.github/workflows)). The main entry points:

| Command | Description |
| --- | --- |
| `just` | Run everything (`just rust` + `just elixir`). |
| `just rust` | Format + lint + dependency checks + tests for the daemon. |
| `just elixir` | Run `mix check` in `server/` (warnings-as-errors, formatter, Credo, Dialyzer, Sobelow, ExUnit). |
| `just fix_rust` | Auto-fix what it can (`clippy --fix`, `cargo fmt`, `taplo format`). |
| `just test_rust` | Run the daemon tests. Accepts a profile, e.g. `just test_rust fast`. |
| `just commits` | Validate commit messages (`origin/master..HEAD`) via `committed`. |
| `just changelog` | Regenerate `CHANGELOG.md` with `git-cliff`. |

Run `just --list` to see every available recipe.

## Contributing

Contributions are welcome — please read [CONTRIBUTING.md](CONTRIBUTING.md) first. A few key
points:

- **Commit messages** must follow [Conventional Commits](https://www.conventionalcommits.org/);
  enforced in CI via `just commits`.
- **CLA required.** Because Meshum is dual-licensed (see below), every contributor must sign
  the [Individual CLA](docs/legal/icla.md) — or, when contributing on behalf of an employer,
  the [Corporate CLA](docs/legal/ccla.md). The **CLA Assistant** bot will prompt you on your
  first pull request. See [`docs/legal/README.md`](docs/legal/README.md) for details.
- **Before pushing**, run `just` locally to avoid CI failures.

## Security

Found a vulnerability? See [SECURITY.md](SECURITY.md) — report it privately to
**security@meshum.dev**, not via a public issue.

## License

Meshum is licensed under the **GNU AGPL-3.0-or-later**, dual-licensed with a commercial
option. See [`LICENSE.md`](LICENSE.md).

Contributions are accepted under the terms of the
[Contributor Licence Agreement](docs/legal/README.md).

Copyright © **Wannes Gennar** &lt;wannes@meshum.dev&gt;.

## Contact

- Website: [meshum.dev](https://www.meshum.dev)
- Source: [github.com/meshum/meshum](https://github.com/meshum/meshum)
- Legal / CLA: **legal@meshum.dev**
- Security: **security@meshum.dev** (see [SECURITY.md](SECURITY.md))
