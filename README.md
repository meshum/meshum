# Meshum

[**meshum.dev**](https://www.meshum.dev) · [Repository](https://github.com/meshum/meshum)

**Meshum gives organizations one place to see, manage, and govern how their
people use AI.**

When a company rolls out AI tooling (Claude Code, Codex, OpenCode, …) to its
staff, the same questions surface immediately: *what are our employees
actually doing with AI? How do they share skills and agents with each other?
Which MCP servers — and which tools inside them — should be reachable? How do
we distribute all of that configuration to every machine?* Meshum is the
central platform that answers them:

- **See** — collect AI usage telemetry across your organization and turn it
  into insight.
- **Manage** — distribute skills, agents, MCP tooling, and AI client
  configuration to employee machines, from one control plane.
- **Govern** — decide which MCP servers your employees can use, down to
  filtering the individual tools an MCP server exposes.

Two things Meshum deliberately is **not**: it doesn't *run* AI (no model
hosting, no provider proxying — we manage the configuration, not the
platform), and it isn't a blocker — it gives you the tooling to set up
governance, but a determined developer can bypass blocks, so we don't pretend
otherwise.

Meshum is **self-hosted** — it holds upstream credentials and sensitive usage
telemetry, and that data belongs on your infrastructure. A hosted offering
exists for companies that prefer not to run it themselves.

> **Status:** early / `0.0.1`. Interfaces are unstable and may change without
> notice. The first MVP targets Claude (Code); other vendors follow.

## How it works

Three components (see [docs/architecture.md](docs/architecture.md)):

- **daemon** (`daemon/`, Rust) — runs on employee machines with a tray icon,
  and syncs settings, skills, agents, and configuration down from the control
  plane.
- **gateway** (`server/apps/meshum_gateway`, Elixir) — an MCP proxy: AI agents
  call it as if it were the MCP server they need (Jira, GitHub, …), and it
  filters what policy doesn't allow.
- **web** (`server/apps/meshum_web`, Elixir) — the control plane where the
  organization sees usage and manages and deploys its policies.

The vision, goals, and decisions behind all of this live in
[docs/](docs/README.md).

## Development

Toolchains are pinned in the repo:

- **Elixir** `1.20.2-otp-29` — [`.tool-versions`](.tool-versions) (use [asdf](https://asdf-vm.com)).
- **Rust** `1.96.0` (edition 2024) — [`daemon/rust-toolchain.toml`](daemon/rust-toolchain.toml);
  `rustup` installs it automatically. `unsafe_code` is forbidden at the workspace level.

The server targets **PostgreSQL** (via Ecto; `compose.yaml` provides one).
With Rust, Elixir, Postgres, and [`just`](https://just.systems) available:

```sh
just setup
```

All checks run through `just` and mirror CI (see
[`.github/workflows/`](.github/workflows)):

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
