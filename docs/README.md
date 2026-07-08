# Meshum documentation

How this folder works (decided by Wannes Gennar, 2026-07-08):

- **Flat structure**, decided-facts pages like `architecture.md`. No ADR
  ceremony, no numbered decision records — too much complexity/ceremony makes
  docs hard to follow/read as humans.
- **AI-first, human-second**: pages are written primarily so AI models can
  onboard cold, while staying readable for contributors.
- Open questions are marked `UNDECIDED` in place. An `UNDECIDED` marker means
  exactly that — no human has decided yet, and **AI models must not fill in
  the blank**; ask instead.
- `docs/legal/` is the exception to all of the above: legal documents,
  human-authored. **AI models are not allowed to modify anything under
  `docs/legal/`.**
- Generated API documentation (`server/doc/`, Rust rustdoc output) is not part
  of this folder's scope; it is an artefact of properly documenting code (see
  [quality.md](quality.md)).

## Pages

- [vision.md](vision.md) — why Meshum exists, audience, business model,
  roadmap posture.
- [architecture.md](architecture.md) — components, communication, deployment.
- [identity.md](identity.md) — tenancy, identity ownership, the two
  independent auth axes (harness↔gateway vs. daemon↔control plane), and the
  authorization server.
- [governance.md](governance.md) — what governance means for v1, philosophy,
  out-of-scope list.
- [control-plane.md](control-plane.md) — `meshum_web` design: navigation,
  policy UI, skill/agent distribution, machines, telemetry.
- [quality.md](quality.md) — quality requirements per language/component.
- [ai-context.md](ai-context.md) — how AI instruction files, rule files, and
  skills/agents are organised.
- [legal/](legal/README.md) — CLA / licensing (human-only).
