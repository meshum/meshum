# Meshum

Centralized governance for AI usage within an organization. Start at
`docs/README.md` — it indexes the vision, architecture, governance scope, and
quality requirements. Open questions are marked `UNDECIDED` in docs: never
fill one in yourself; ask a human.

## Layout

- `daemon/` — Rust workspace: the client daemon that runs on employee machines.
- `server/` — Elixir/Phoenix umbrella: `meshum` (shared business logic),
  `meshum_gateway` (MCP proxy), `meshum_web` (control plane).
- `docs/` — project documentation. `docs/legal/` is human-only: never modify it.

See `docs/architecture.md` before assuming what any component does.

## Commands

- `just setup` — install toolchains and dependencies.
- `just` — run all checks (Rust + Elixir); `just rust` / `just elixir` for one side.
- `just commits` — validate commit messages (conventional commits, enforced).

## Opening pull requests

Before opening a PR, verify it complies with [AI-POLICY.md](AI-POLICY.md) —
in particular that your human has actually reviewed and can defend the work
(they are responsible for it), and that AI involvement is disclosed in the PR
or commit attribution. If compliance is unclear, discuss it with the user
before opening the PR.

## Conventions

- Quality bar: `docs/quality.md`. Code quality is first-class; no
  overengineering.
- Changelog via git-cliff (`just changelog`); commits must be conventional.
- Language/filetype coding rules live in `.claude/rules/*.md` (path-scoped,
  auto-loaded by Claude Code). **If your harness does not load these
  automatically, read the rule files whose `paths:` globs match the files you
  are about to edit before editing them.**
