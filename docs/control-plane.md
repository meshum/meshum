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
enrollment. This page is also where a machine's daemon-reported health/last-seen
state and recent operation incidents surface (see
[daemon-reconciliation.md](daemon-reconciliation.md#reporting-machine-health-and-incidents)).

## Tool access (Policies) — MCP allow/block only

Skill/agent distribution scoping does **not** live here (see below) —
this section covers MCP server/tool allow/block exclusively (per
[governance.md](governance.md#mcp-control)).

**Concept name: `ToolAccess`.** The persisted rows and evaluation logic are
`ToolAccess` (runtime allow/block rules, distinct from the declarative
`Manifest`; see [governance.md](governance.md#tool-access-granularity)). The
nav label and this page's user-facing copy say **"Policies"** since that reads
better for non-technical admins; that's a UI-copy choice, distinct from the
`ToolAccess` concept/schema name.

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
- **These are `Manifest` items.** A `Distributable` row
  (plus config and, long-term, tool installs) is one entry in the org's
  declarative desired state — the `Manifest` (see
  [governance.md](governance.md#version-controlled-desired-state)). `Manifest`
  is the umbrella that the YAML import/export operates over (see below); the
  persisted `Distributable` rows are **unchanged** — `Manifest` names their
  collective role, it is not a competing schema.
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

## Version-controlled desired state (YAML)

The org's `Manifest` — its declarative desired state — is
importable/exportable as a **single YAML document**, GitOps-style, so an org
can keep desired state in version control and apply it to the control plane.
Scope and semantics for v1:

- **One document = the whole org.** A YAML document represents the **full**
  organisation's desired state: every team's skills, agents, config and tool
  installs — not a per-team file. Scoped/filtered export or import (e.g. "just
  team A") is **deferred** beyond v1: a decided later-work item, not an open
  question.
- **`ToolAccess` is out.** The runtime allow/block rules (see
  [Tool access](#tool-access-policies--mcp-allowblock-only)) are **not** part of this
  mechanism in v1 — they stay UI/DB-managed. Cheap to fold in later, but
  explicitly out of v1 scope.
- **Import is full-replace.** An imported document is treated as the *complete*
  desired state: anything not present in it is **deleted**, not merged or
  patched.
- **Plan-then-apply, one mechanism for both.** Built on `Ecto.Multi` +
  changesets. One function builds an `Ecto.Multi` from the diff between current
  DB state and the imported document — each changeset carrying insert/update/
  delete intent. The **same** `Multi` value drives both steps:
  - **Preview:** inspect it with `Multi.to_list/1` and render each step's
    changeset (`.changes` / `.action` / `.data`) to the admin as "will be added
    / updated / deleted" before they confirm.
  - **Apply:** `Repo.transaction/1` on the identical value.

  Because preview and apply come from one data structure, there is **no drift**
  between what was shown and what actually runs.
- **Known limitation, accepted for v1: `Multi.run/3` steps are opaque.**
  Anything that can't be expressed as a plain changeset (e.g. bulk operations
  depending on a prior step's result) is a `Multi.run/3` function, which can't
  be statically previewed without executing it. v1 **flags these in the UI as
  "opaque, changes not shown"** rather than blocking on richer preview support
  — that support is deferred, not required for v1.
- **Server-side only.** This lives in `meshum`/`meshum_web` and converges the
  *control plane's* stored state to the imported document. It says nothing
  about the daemon's own local-machine reconciliation loop (Rust side,
  converging an employee machine to whatever `Manifest` the server holds) —
  that is a separate, not-yet-designed problem; do not assume this covers it.
- **Conflict/authority, accepted for v1: last-write-wins.** UI edits and YAML
  import both write the same underlying state; there is **no drift detection**
  between the two paths and **no "git is the sole source of truth"**
  enforcement. A deliberate v1 simplification (not permanent, just not v1),
  consistent with the project's other such flags.

## Upstream Tools

Employees self-serve connect their own accounts (Jira, GitHub, …) here via
one-time OAuth consent, using registered `UpstreamServer`s — see
[identity.md](identity.md#axis-a--ai-harness--gateway-the-mcp-tool-call-path).
Since there's no role split in v1, this page shows "your connections" and is
reachable by everyone; registering new `UpstreamServer` types — paste the
upstream MCP URL, discovery/DCR does the rest (see
[identity.md](identity.md#registering-an-upstream-admin)) — presumably lives
on the same flat surface.

## Telemetry

**Minimal raw view for v1** — a basic event list/table, not a dashboard.
Enough to confirm ingestion is working and glance at recent activity;
aggregation/visualization is explicitly deferred beyond this.

**Event source:** harnesses that natively emit OTel
(Claude Code) send it straight to the control plane's ingestion endpoint;
the daemon and/or hooks forward on a harness's behalf only when native
support is missing. The gateway does not emit telemetry — MCP-call
visibility is the Policies pillar's job, not this one. See
[governance.md](governance.md#telemetry).

**Event shape:** raw and append-only, not normalized
into bespoke fields — a CQRS-adjacent stance where v1 only ever writes and
lists, and aggregation/projection is deferred to whenever a real dashboard
gets built (explicitly not v1). Every event carries a thin, always-present
envelope for listing/filtering, plus an opaque payload for whatever the
source actually sent:

- **Envelope (target shape, not enforced at ingest):** `occurred_at`,
  `user_ref_id`, `machine_id` — the goal is for every event to resolve to an
  employee **and** the specific machine it came from, mirroring how
  Machines/Upstream Tools already scope by user (see
  [identity.md](identity.md)). This can't be guaranteed on ingest: Meshum
  doesn't control what a harness's OTel exporter actually sends, and the
  spike below found harness-native OTel carries no machine identifier at
  all. Deriving these fields (e.g. matching self-reported `user.email`) is
  deferred to a later aggregation job, not done at ingest.
- **Payload (opaque):** the raw OTel signal (span/log/metric) as received,
  stored as-is. This is the entirety of what v1 persists — the envelope
  fields above are not separate columns yet.

### Observed event shapes (spike findings, 2026-07-10 — Claude Code only)

A throwaway ingestion probe (`POST /otel/ingest`, no auth, raw-inspects and
stores the request body as-is) was pointed at a real Claude Code session's
OTel exporter to see actual payloads before committing to parsing/attribution
logic. **Sample size caveat: every finding below comes from one Claude Code
CLI session. OpenCode and other harnesses have not been tested yet and may
shape their export differently — treat this as a first data point, not a
general OTel contract.**

- **Transport confirmed workable as OTLP/JSON.** Each POST body is a
  standard OTLP/JSON export envelope: `resourceLogs[].resource.attributes`
  (host/OS/`service.name: "claude-code"`/`service.version`) then
  `resourceLogs[].scopeLogs[].logRecords[]` for logs, or
  `resourceMetrics[].scopeMetrics[].metrics[]` for metrics. One HTTP request
  = one full export batch — a single observed request carried 25
  `logRecords` in one body. This confirms the "one opaque row per request"
  storage stance (see Event shape above) is workable in practice, not just
  in theory.
- **Every log record and every metric data point self-reports a full
  attribution block**, independent of anything the ingestion endpoint's
  auth does:
  - `user.email` (plaintext), `user.id` (hashed), `user.account_uuid`,
    `user.account_id` — Claude Code/Anthropic account identity.
  - `organization.id` — the *Anthropic* org, not a Meshum org (Meshum has no
    `Org` table — see [identity.md](identity.md#tenancy) — so this field is
    not usable as a Meshum tenant key, only as an Anthropic-account-level
    grouping signal).
  - `session.id` — this CLI session's UUID, stable across every event in
    that session, **including subagent-spawned tool calls** (subagents do
    not get their own `session.id`).
  - `terminal.type` (e.g. `"WarpTerminal"`).

  Practical implication: **`user.email` is reliably present per-event in the
  payload itself.** This means the deferred aggregation job can derive
  `user_ref_id` (by matching `user.email` against `UserRef.email`) without
  needing verified request headers or a smarter auth mechanism at ingest
  time — it directly supports the "ingest raw now, attribute later via a
  separate job" approach decided for v1. `machine_id` has no equivalent
  payload field observed so far — nothing here identifies *which* employee
  machine (if any) forwarded the event, since this was harness-native
  telemetry, not daemon-forwarded.
- **Event catalog observed** (`event.name` / log record body): 
  `plugin_loaded`, `hook_registered`, `hook_execution_start`,
  `hook_execution_complete`, `mcp_server_connection`, `user_prompt`,
  `assistant_response`, `at_mention`, `api_request`, `tool_result`,
  `tool_decision`, `subagent_completed`. One metric name observed on the
  `resourceMetrics` side: `claude_code.session.count` (monotonic sum, one
  data point per session start/resume).
  - **`api_request`** carries the cost/usage signal: `model`,
    `input_tokens`, `output_tokens`, `cache_read_tokens`,
    `cache_creation_tokens`, `cost_usd` / `cost_usd_micros`, `duration_ms`,
    `effort`, `speed`, `request_id`, `prompt.id`.
  - **`tool_result`** carries per-tool-call usage and the permission
    decision: `tool_name`, `tool_use_id`, `success`, `duration_ms`,
    `tool_input_size_bytes`, `tool_result_size_bytes`, `decision_source`
    (e.g. `config`, `user_temporary`), `decision_type` (e.g. `accept`),
    and — only for MCP-routed tools — `mcp_server_scope`.
  - **`subagent_completed`** is a rollup emitted once per subagent
    invocation: `agent_type` (e.g. `"Explore"`), `agent.source`
    (`"built-in"` vs. custom), `is_built_in`, `is_async`, `total_tokens`,
    `total_tool_uses`, `duration_ms`, `model`, `prompt.id`. **Known gap:**
    the subagent's own underlying `tool_result`/`api_request` events are
    *not* separately tagged with an agent/subagent id — they're interleaved
    into the same parent `session.id`'s log stream, correlatable only
    loosely via shared `prompt.id` and event ordering (`event.sequence`),
    not a hard foreign key. Reconstructing "what did this specific subagent
    invocation do" from raw events would require sequence-window inference,
    not a join — worth keeping in mind if per-agent-type cost/usage
    breakdowns are ever wanted in the aggregation job.

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
  association to specific `TeamRef`s. Rows of this (plus config and, long-term,
  tool installs) are what a `Manifest` YAML document serialises. `Manifest`
  itself is **not** necessarily a persisted table in v1 — it is the declarative
  document the import/export and diff operate over (see
  [Version-controlled desired state](#version-controlled-desired-state-yaml)).
- `ToolAccess` — org-wide or team-scoped MCP allow/block rules (the persisted
  form of the runtime rules the gateway consults per call — see
  [identity.md](identity.md#schema-sketch)).
- `TelemetryEvent` — a single opaque `payload` column (the raw OTel signal
  as received); that's the entirety of what v1 persists (see
  [Telemetry](#telemetry) above). `occurred_at`, `user_ref_id`, and
  `machine_id` are the target envelope a later aggregation job derives from
  the payload — not columns on this schema in v1. No `source`/`kind`
  discriminator field either — a spike is needed on what's actually in the
  payload before deciding whether one can be populated reliably (see
  `UNDECIDED` below). Retention: **indefinite in v1**, no pruning job.

## UNDECIDED

- Skill/agent authoring/upload UX (raw upload vs. in-browser editor vs.
  git-backed vs. a hybrid).
- Whether `TelemetryEvent` needs an explicit `source`/`kind` field
  (e.g. distinguishing daemon-forwarded vs. harness-native-OTel events) or
  whether that's inferable from the payload alone. The field is not added
  yet — its presence can't be guaranteed until a spike
  determines what daemon-forwarded vs. harness-native payloads actually
  contain. Note: daemon-forwarded AI-usage telemetry is out of MVP scope (see
  [daemon-reconciliation.md](daemon-reconciliation.md#mvp-scope)), which
  removes one motivating case for this field for now — it does **not** close
  this item, which stays open pending the payload-shape spike.
- Dashboard and Settings page contents (not yet interviewed).
