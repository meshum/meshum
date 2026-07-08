# AI context layout

> Status: draft — decided by Wannes Gennar, 2026-07-08.

How AI instruction/context files are organised in this repo.

- Multiple harnesses consume the context files: Claude Code, OpenCode, and
  others. Instructions are **never duplicated** — each lives in exactly one
  place.
- Folder-global instructions live in `AGENTS.md` (read by all harnesses).
  Claude Code reads only `CLAUDE.md`, so each `AGENTS.md` is accompanied by a
  `CLAUDE.md` containing just an `@AGENTS.md` import.
- Scoped domain/language/filetype constraints live in `.claude/rules/*.md`
  with `paths:` glob frontmatter, loading only when matching files are
  touched. Other harnesses don't support rule files, so **rule files are
  designed for Claude Code**. As a best-effort fallback, `AGENTS.md` files
  instruct harnesses that don't auto-load rules to read the rule files whose
  `paths:` globs match before editing — non-deterministic, but better than
  nothing.
- Context files are lean: only information global to the folder they're in,
  pointing into `docs/` rather than restating it.

## Skills & agents

Meshum-specific machinery lives in-repo under `.claude/`. Approved first wave:

| What | Kind |
|---|---|
| Reviewer encoding `docs/quality.md` | agent |
| Elixir/Phoenix conventions | rule files |
| Rust workspace conventions | rule files |

Reusable, project-agnostic machinery does not belong in this repo.
