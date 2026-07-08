# server

Elixir/Phoenix umbrella. Apps: `meshum` (shared business logic),
`meshum_gateway` (MCP proxy), `meshum_web` (control plane / LiveView). See
`docs/architecture.md` for what each does.

## Guidelines

- Use the `mix precommit` alias when you are done with all changes and fix any
  pending issues; `just elixir` runs the full analysis suite.
- Use the already included `:req` (`Req`) library for HTTP requests; **avoid**
  `:httpoison`, `:tesla`, and `:httpc`.
- Elixir is a minimalistic, elegant language — leverage it as such; quality
  bar in `docs/quality.md`.

## Coding rules

Detailed Elixir/Phoenix/Ecto/HEEx/LiveView rules live in `../.claude/rules/`
(`elixir.md`, `ecto.md`, `phoenix.md`, `phoenix-web.md`), path-scoped for
Claude Code. **If your harness does not load `.claude/rules/` automatically,
read the rule files whose `paths:` globs match the files you are about to
edit before editing them.**
