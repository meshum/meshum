# Quality requirements

> Status: draft — decided by Wannes Gennar, 2026-07-08.

Code quality is a **first-class requirement** — without devolving into an
overengineering circlejerk. Both Rust and Elixir are minimalistic, elegant
languages and should be leveraged as such.

## Rust (`daemon/`)

- Very strict linting/analysis is the bar: everything `just rust` runs
  (fmt, taplo, check, clippy pedantic, machete, deny, audit, nextest).
- Documentation coverage is already covered by those requirements
  (`missing_docs` warns at the workspace level; `unsafe_code` is forbidden).

## Elixir (`server/`)

- Analysis via `just elixir` (`mix check`: credo, dialyxir, etc.).
- Documentation coverage is **not** currently enforced by the analysis —
  adding enforcement is a decided improvement (TODO: pick and wire up
  tooling for it).

## Generated documentation

Properly documenting code is a requirement (per the above); generated output
(`server/doc/`, rustdoc) is an artefact of that, not managed documentation.
