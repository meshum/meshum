# Control plane (`meshum_web`)

> Status: draft — decided by Wannes Gennar, 2026-07-08. Items marked
> `UNDECIDED` are open; do not assume an answer for them.

`meshum_web` is where organisations see and manage everything Meshum
governs — policy, skill/agent distribution, upstream tool connections,
machines, and telemetry. It also doubles as the employee-facing surface for
self-serve actions (connecting upstream accounts); see [identity.md](identity.md)
for why there's no separate "employee app."

## Access model

**No role distinction in v1.** Anyone who can log in (via the customer's IdP,
see [identity.md](identity.md)) has full access to everything below — there
is no admin/employee split, no viewer role. This is a **deliberate v1
simplification, not a permanent stance**: proper authorization controls are
intended for later, just not v1/MVP. Consequence: there is one flat surface
and nav, not separate admin/employee areas.

## Navigation

Flat, ~7 top-level sections: **Dashboard · Policies · Skills & Agents ·
Upstream Tools · Machines · Telemetry · Settings.** No grouping/nesting.

## Machines

Enrollment is the daemon's own login flow (loopback-redirect OAuth), not a
control-plane-initiated action — see
[identity.md](identity.md#axis-b--daemon--control-plane-sync). The Machines
page is where that shows up afterward: list of enrolled machines (name,
owning user, last sync/poll time, enrolled date), a revoke action per
machine, and rename. There is no "generate an enrollment code/link"
affordance — nothing is generated centrally; the daemon initiates its own
enrollment.

## Policies — MCP allow/block only

Skill/agent distribution scoping does **not** live here (see below) —
Policies covers MCP server/tool allow/block exclusively (per
[governance.md](governance.md#mcp-control)).

- **UI shape: a tree.** Toggle a whole server allow/block, or expand a
  server to toggle individual tools within it.
- **Team overrides patch the org-wide baseline** — most rules are inherited;
  a team override only states what that team changes. Authoring a team
  override: pick a team, see the org baseline tree pre-filled, flip specific
  server/tool toggles for that team; unflipped items keep inheriting.
- **Precedence: team wins outright.** A team-level rule beats the
  corresponding org-level rule for that team — **org policy is a
  default/baseline, not a hard ceiling.** Teams can loosen (or otherwise
  override) it, not just narrow it.

## Skills & Agents

- **Scoping: a simple picker**, org-wide or specific team(s) — no
  patch/override/exclusion logic. A skill or agent either targets everyone
  or a defined set of teams. This is deliberately simpler than the Policies
  tree/precedence mechanism and does not reuse it.
- **Schema: one unified `Distributable` type** with a `kind: :skill | :agent`
  discriminator, not separate `Skill`/`Agent` schemas — both are "markdown +
  frontmatter, org/team-scoped, latest-only versioned" (see
  [governance.md](governance.md#skillagent-distribution)); they differ in
  frontmatter shape and in which daemon-side path the Claude Code adapter
  installs to (`~/.claude/skills/` vs `~/.claude/agents/`).
- **Authoring/upload UX: `UNDECIDED`.** Candidates surfaced, not chosen:
  - *Raw upload* (zip/folder or single `.md`) — supports supporting files
    (scripts/references, as seen in real skills like the `elixus-toolkit`
    marketplace examples); simplest server-side handling; worst authoring
    ergonomics.
  - *In-browser editor* — best ergonomics for the common case; v1 would
    likely mean no supporting files unless the editor grows a
    file-attachment affordance later — a real capability gap versus what
    skills can contain on disk.
  - *Git-backed sync* — control plane points at a repo/subdirectory and
    pulls; naturally supports arbitrary files; highest implementation cost,
    adds a third system (git hosting/access) to the trust boundary.
  - A hybrid (raw upload for skills-with-files, editor for text-only agents)
    is also plausible given `Distributable` already discriminates by `kind`.

## Upstream Tools

Employees self-serve connect their own accounts (Jira, GitHub, …) here via
one-time OAuth consent, using registered `UpstreamServer`s — see
[identity.md](identity.md#axis-a--ai-harness--gateway-the-mcp-tool-call-path).
Since there's no role split in v1, this page shows "your connections" and is
reachable by everyone; registering new `UpstreamServer` types presumably
lives on the same flat surface.

## Telemetry

**Minimal raw view for v1** — a basic event list/table, not a dashboard.
Enough to confirm ingestion is working and glance at recent activity;
aggregation/visualization is explicitly deferred beyond this. The shape of
an ingested `TelemetryEvent` itself is `UNDECIDED` — only the UI treatment
has been decided so far.

## Dashboard & Settings

Exist as nav slots (confirmed as part of the flat 7); their internal content
wasn't specifically interviewed and should be treated as ordinary
implementation detail rather than settled architecture — flagging that
explicitly rather than assuming, since it simply wasn't challenged yet.
Settings presumably houses deployment-level config (IdP connection, the
gateway↔control-plane shared secret from identity.md, etc.).

## Schema sketch

Informational, per [`.claude/rules/ecto.md`](../.claude/rules/ecto.md)
conventions. Extends [identity.md](identity.md#schema-sketch)'s sketch:

- `Distributable` — `kind` (`:skill`/`:agent`), `name`, `content` (shape
  depends on the still-open authoring-UX decision), org-wide flag or
  association to specific `TeamRef`s.
- `TelemetryEvent` — not yet designed; needs its own short round once
  ingestion is actually built (see `UNDECIDED` above).

## UNDECIDED

- Skill/agent authoring/upload UX (raw upload vs. in-browser editor vs.
  git-backed vs. a hybrid).
- `TelemetryEvent` schema shape (what an ingested event actually contains).
- Dashboard and Settings page contents (not yet interviewed).
