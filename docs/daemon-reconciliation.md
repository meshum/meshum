# Daemon reconciliation

> Status: draft — decided by Wannes Gennar, 2026-07-12. Items marked
> `UNDECIDED` are open; do not assume an answer for them.

The daemon reconciles an employee machine's local state against the org's
`Manifest` — the declarative desired state it syncs down over Axis B (see
[identity.md](identity.md#axis-b--daemon--control-plane-sync) and
[governance.md](governance.md#skillagent-distribution)). This page covers the
part that lives on the Rust side: **how the daemon
actually realises a `Manifest` item on the local machine, and how it reports
its own operational state back.** It does not restate the `Manifest` schema,
the server-side YAML import/apply flow (see
[control-plane.md](control-plane.md#version-controlled-desired-state-yaml)), or
Axis B enrollment/credentials (see
[identity.md](identity.md#axis-b--daemon--control-plane-sync)) — those are
unchanged; this builds on top of them.

The `Manifest` expresses **generic intent only** — e.g. "OTel: enabled",
"this skill: present". It never names a mechanism. How a given piece of intent
becomes reality on a given machine is decided elsewhere, as follows.

## Capability routing

Routing — deciding *how* a capability gets realised for a given org, harness,
and capability — is decided **server-side, in `meshum`**, never by the daemon
and never by the admin authoring the `Manifest`. For any one capability on any
one harness (Claude Code, OpenCode, …) there are two **mutually exclusive**
realisation paths, chosen by a per-capability-per-harness lookup in `meshum`:

- **Provider-managed.** The harness vendor exposes an org-level admin API
  (e.g. a Claude Code Enterprise tier). `meshum`/`meshum_web` calls that API
  directly to enforce the capability centrally. **The daemon has no role** —
  there is no local drift to detect, because the vendor enforces the setting.
  This path runs as its own reconciliation loop inside `meshum`, on its own
  schedule/trigger, with its own credential model — conceptually closer to an
  `UpstreamConnection` (see [identity.md](identity.md#schema-sketch)) than to
  daemon sync. **Its detailed design is out of scope for this page**; it is
  named here only so the fork is visible and so it is clear this path is
  handled server-side, not by the daemon.
- **Daemon-managed.** No applicable vendor API/tier exists, so the daemon must
  realise the capability locally — write a settings file, install a plugin,
  register a hook — and re-apply it whenever local state drifts. This is the
  same managed-state, re-sync-on-drift model already stated for skills/agents
  (see [governance.md](governance.md#skillagent-distribution)), now stated as
  applying **per capability**, not only to skills and agents.

The lookup that picks the path is not hardcoded into the daemon and is not a
choice the `Manifest` author makes. The `Manifest` still says only "OTel:
enabled"; `meshum` resolves that intent to either "call the vendor API" or
"instruct the daemon" for this org and harness.

The daemon-managed path **reuses the per-harness adapter pattern already
decided for skill and agent installation** (see
[governance.md](governance.md#skillagent-distribution): the daemon has
per-harness adapters that install via whatever mechanism each supported AI
client uses natively; v1 ships the Claude Code adapter only). Capability
realisation is not a second, parallel adapter mechanism — it is more work for
those same adapters.

## Closed-vocabulary operations

The daemon-managed path is deliberately constrained so that a compromised or
spoofed control plane cannot use it as a remote-code-execution vector. **The
daemon never accepts generic remote instructions** like "write this content to
this file" or "run this command" — accepting those would let anyone who can
impersonate the control plane do arbitrary things on every enrolled machine.

The model is the one MDM (mobile device management) systems use: the OS
defines a fixed, versioned schema of manageable settings, and the management
server may only set values within that schema — it can never push arbitrary
shell or file operations. The daemon's adapters are that schema.

- **Fixed set of named, typed operations.** Each adapter ships a closed set of
  named operations with typed parameters — e.g. `set_otel(enabled: bool)` on
  the Claude Code adapter, `install_plugin(name: string)` on an OpenCode
  adapter. `meshum` can only invoke these **by name with typed arguments**. It
  can never send a raw path/content pair or a command line.
- **Per-operation, flat-integer versioning.** Each operation carries its own
  version — a flat integer, not semver — e.g. `set_otel@1`, `set_otel@2`.
  Operations version **independently**: there is no "daemon version" that gates
  what a daemon can run, only "does this daemon have `operation_name@N`
  compiled in." Different operations sit at different version numbers with no
  relationship between them.
- **`name@version` naming, borrowed from GitHub Actions — but *not* its
  fetch-and-execute mechanism.** A GitHub Actions runner resolves a version
  reference and fetches and executes the referenced code at runtime; that is
  exactly the RCE vector this design avoids. Here, an operation's
  implementation **is compiled into the daemon binary at release time**. A
  version reference names a fixed, already-shipped implementation — it is never
  a pointer the daemon resolves or fetches dynamically.
- **Exact-match execution only.** The daemon holds a fixed table of
  `(operation, version) → implementation` it was compiled with, and executes
  only an **exact** hit against that table. There is no compatibility-range
  reasoning anywhere: no "I know v1, so v2 is probably fine," and no "I know
  v2, so I can serve a v1 request by inference." A version bump can change
  argument semantics in ways the daemon cannot detect, so guessing
  compatibility is precisely the cleverness this model rejects. Keeping
  backward compatibility with an older version means **deliberately retaining
  that older version's implementation in the binary as a distinct table
  entry** — never inferring it at runtime.
- **Fail closed and stay visible on unknown/incompatible operations.** If
  `meshum` asks a daemon to run an `(operation, version)` it does not have
  compiled in, the daemon refuses — and that refusal is **reported** (see
  [Reporting](#reporting-machine-health-and-incidents) below), never silently
  dropped. In normal operation this is rare, because capability
  self-reporting (below) already tells `meshum` what the daemon can do; refusal
  is a defensive backstop, not the expected path.

**Accepted permanent constraint (not a v1 shortcut):** supporting a new
capability, or a new harness, always requires shipping a new daemon release
carrying the new adapter code. The control plane alone can never grant a daemon
an ability it was not built with. This is the deliberate cost of the
closed-vocabulary model.

## Capability self-reporting

Because `meshum` decides routing and instructions server-side, it needs to
know each connected daemon's actual compiled `(operation, version)` table
before asking it to do anything — otherwise it might request an operation that
daemon lacks. Every time a daemon reports in, it sends its **full** capability
table, not a delta. This matches the project's stance elsewhere of declaring
full current truth rather than diffing (the same "managed state, re-sync on
drift" philosophy behind skill/agent distribution). The capability table
travels on the reporting channel below, **not** on the sync poll.

## Reporting (machine health and incidents)

Daemon status, capability, and error reporting is an **entirely separate
mechanism** from the Axis B sync relationship — different endpoint, different
implementation, on purpose. Reporting is **not** bundled into the sync poll
(where the daemon pulls its `Manifest`/instructions). Coupling the two — having
the daemon submit a report and receive its next instructions in one
request/response — is explicitly rejected: it ties together two things that
must fail independently. An error worth reporting should not have to wait for
the next poll interval, and a poll must not be blockable by reporting
plumbing. So a reporting failure can never touch the sync path, and a sync
failure can never touch reporting.

Axis B's own transport protocol (HTTP polling for the MVP, with WebSocket/gRPC
possible later — see [architecture.md](architecture.md#communication)) remains
genuinely undecided at the protocol level. **This reporting channel's transport
choice is independent of that** and does not resolve it.

### Reporting format

The reporting payload is a **bespoke, first-party shape** — call it a
`MachineReport` — **not** OpenTelemetry. OTel's value is interoperability with
heterogeneous, pre-existing third-party exporters and collectors that Meshum
does not control. Daemon fleet-health reporting is the opposite case: both the
daemon and `meshum_web` are Meshum-authored and closed-loop. OTel's protocol
machinery (resource semantics, scope, batching envelopes) buys no
interoperability benefit here and only adds complexity.

This is a **distinct pillar** from the AI-harness usage telemetry pillar (see
[governance.md](governance.md#telemetry) and
[control-plane.md](control-plane.md#telemetry)), which *does* use OTLP-shaped
ingestion and is unchanged. That pillar reports AI **usage**; this one reports
the daemon's own **operational health**. Two properties differ structurally,
not by accident:

- **Storage semantics split by shape.** The report carries two kinds of data:
  - **State (upserted).** The daemon's current `(operation, version)`
    capability table, its own build/release version, and a health/last-seen
    signal. There is no value in retaining "was healthy at check-in N," so this
    is **not** append-only: every report overwrites the previous state. It
    lives as fields on the existing `Machine` schema (see
    [identity.md](identity.md#schema-sketch)).
  - **Errors (appended, only when present).** A list of
    `{operation, version, message, occurred_at}` entries for anything that
    failed or was refused since the last report. This genuinely is log-shaped —
    you want the history of what broke, when, and why — so it is a separate,
    append-only construct, a `MachineIncident` table tied to the `Machine`. It
    is populated only when something goes wrong, never on a healthy check-in.
- **Transport: plain HTTP/JSON.** Sufficient, and consistent with the
  project's "HTTP polling for the MVP" bias. As above, this is independent of
  and does not resolve Axis B's still-open transport question.
- **Attribution is verified here.** The daemon authenticates with its own
  `MachineCredential` (see
  [identity.md](identity.md#axis-b--daemon--control-plane-sync)), so the
  request itself proves which machine sent it: `machine_id` — and the owning
  `user_ref_id`, transitively via the `Machine`'s owning `UserRef` — is a
  **verified** field at ingest, not something derived later from a
  self-reported payload. This is a deliberate structural difference from the
  AI-usage telemetry pillar, whose attribution is unverified and derived later
  from payload contents (see
  [identity.md](identity.md#telemetry-ingestion-auth) and
  [control-plane.md](control-plane.md#telemetry)) — not an inconsistency
  between the two.

## MVP scope

**Daemon-forwarded AI-usage telemetry is out of scope for the MVP.** The
daemon relaying a harness's OTel export on its behalf — the fallback for
harnesses that cannot emit OTel natively, mentioned as a future path in
[architecture.md](architecture.md#communication) and
[governance.md](governance.md#telemetry) — is a deliberate scoping decision to
leave out of v1, not an oversight.

This does **not** resolve the open `UNDECIDED` item in
[control-plane.md](control-plane.md#undecided) about whether `TelemetryEvent`
needs a `source`/`kind` discriminator. That item stays open for its own
separate reason (a pending multi-harness OTel-payload-shape spike). Leaving
daemon-forwarding out of the MVP merely removes one motivating case for that
field, for now.
