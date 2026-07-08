# Vision

> Status: draft — decided by Wannes Gennar, 2026-07-08.
> This page states *why* Meshum exists; component facts live in
> [architecture.md](architecture.md), v1 scope in [governance.md](governance.md).

## Origin

Meshum comes from first-hand consulting experience at companies rolling out AI
tooling (Claude Code, OpenClaw, …) to their developers — and soon after, their
non-developer staff. The same questions came up over and over:

- How can our employees use these tools *effectively*?
- What are the security concerns?
- How can employees share things like skills with each other?
- How can we get insight into what our employees do with AI?
- How can we prevent security leaks (like tools reading credential files) and
  harmful tooling?
- How can we use those insights to help employees be more effective?

Seeing companies build ad-hoc internal answers to these questions reinforced
that there is real demand for a central way to gain insight into — and manage
and govern — AI usage in small-to-medium companies.

## The vision

A **centralized platform** where a company can *see* its AI usage and *manage*
it: distributing MCP tooling, skills, and agents; combining telemetry and
configuration out of the box. Not just for Claude (Code), but across any
vendor — Codex, OpenCode, zAI, OpenAI, xAI, ….

What Meshum deliberately does **not** do:

- **We don't run the AI.** No model deployment, no proxying through providers.
  We manage the *configuration*, not the platform.
- **We don't position as a blocker.** We can't decide what a company wants to
  block, so we provide the tooling to set up governance (hooks, MCP tool
  filtering, …) — but we don't advertise as something that blocks, because a
  dedicated developer can bypass blocks anyway and that's not the position we
  want.

## Audience

**Management buys it; employees use it** — or are subjected to it. The
northstar principle: employees are *glad it exists and don't fight it*. The
employee-facing experience (daemon, synced tooling) must be smooth, not
adversarial.

## Why self-hosted, and who hosts

Meshum handles many sensitive credentials (upstream keys for MCP servers) and
collects potentially sensitive information (telemetry of AI usage). Single-
tenant self-hosting is architecturally much easier and safer out of the box,
and the additional privacy is a free bonus.

- Larger companies (~100–150 people) tend to have their own cloud
  infrastructure (Azure, AWS) and will want to deploy there — they're unlikely
  to hand this much sensitive data to external hosting.
- Smaller companies (10–50 people) may have no dedicated infrastructure —
  especially outside the dev industry — or an overworked solo devops; the
  **hosted offering** exists for them.

## Business model

AGPL + commercial dual licensing is *a* revenue stream (acknowledged: not a
big one). **Hosting is the intended business model.** The primary motivation,
though, is to build something cool that people will use.

## Roadmap posture

**Claude (Code) is the first MVP target**; other vendors follow. Caveat: don't
overfit to Claude's platform — keep the design generic enough that adding a
new provider doesn't require a rebuild.

## What success looks like

A usable product — even if not feature-complete — that the founder would be
proud to demo to the companies whose struggles inspired it. If they're
impressed, that's success.
