# Development environment

> Status: draft — decided by Wannes Gennar, 2026-07-08. Items marked
> `UNDECIDED` are open; do not assume an answer for them.

How to run Meshum locally for development. This page currently records only
the **development identity provider** — the piece with no obvious default.
Other local-development concerns will be added here as they are decided.

## Why a dev IdP is needed

Both auth axes in [identity.md](identity.md) federate to the customer's
identity provider (Entra, Okta, …): Axis A (harness → gateway, via Meshum's
authorization server) and Axis B (daemon loopback-redirect enrollment). Local
development needs a stand-in IdP so those flows run end-to-end without a real
customer IdP tenant.

## Decision: Keycloak, seeded by a checked-in realm-export

The dev IdP is [Keycloak](https://www.keycloak.org/), run in dev mode
(`start-dev`) inside `compose.yaml`, seeded on boot from a realm-export JSON
checked into the repo at `containers/keycloak/example-realm-realm.json` and mounted
into Keycloak's import directory (`--import-realm`). The mount is writable so
the CLI `export` can write straight back into the repo directory; Keycloak
only ever reads from it at startup. The realm re-imports whenever Keycloak
starts against fresh state, so
`podman compose down -v && up` yields a clean, working IdP with no manual
configuration — the wipe-and-restart cycle stays cheap.

- **Data store:** Keycloak's embedded `dev-file` (H2), on a named volume, so
  ordinary restarts are fast and a volume wipe re-imports the realm clean. It
  is decoupled from Meshum's Postgres service.
- **Realm authoring:** the realm is configured once through the Keycloak admin
  UI, then exported with `kc.sh export --realm …` and committed. The concrete
  client(s), users, and group claims live in the exported JSON itself — they
  are not enumerated here (maintainer-managed).

## Alternatives considered

Keycloak was chosen for **realism and demo-credibility** — it is the closest
stand-in to Entra/Okta and makes "tested against Keycloak; production points
at your IdP" a credible statement — accepting its heavier footprint
(~750 MB, slow start) and a loose seed file. Considered and not chosen:

- **Dex** — far lighter (~30 MB) and certified OIDC, but using it as a *leaf*
  IdP with seeded users is off-label (Dex is designed to *federate* to other
  IdPs). Less demo-credible.
- **In-tree mock** (a dev-only Elixir OIDC endpoint) — zero config files and
  zero extra containers, but a mock to maintain; the realism gap is small
  since `assent` is the abstraction boundary. Fastest daily cycle; rejected in
  favour of a real IdP.
- **`oidc-server-mock`** — purpose-built mock container; a third-party
  dependency and still needs seed config.
- **Keycloak with the seed baked into a custom image** (vs a loose JSON) —
  keeps the seed out of the loose-files category but adds a Containerfile +
  build step. Rejected in favour of the simpler loose-JSON mount.

## Scope: dev-only

The dev IdP is **generic OIDC**, not an Entra/Okta mimic. Meshum's code only
sees [`assent`](https://hex.pm/packages/assent)'s normalized output (see
[identity.md](identity.md)), so a correct-OIDC stand-in is sufficient to
exercise Meshum's federation logic; IdP-specific quirks live in `assent`'s
provider presets and are not caught by any dev stand-in. Production federates
to the customer's real IdP.

## Wiring (dev-only)

Meshum consumes the dev IdP through `assent` (already chosen in
[identity.md](identity.md#login-flow-implementation)), with dev configuration
in `config/dev.exs` pointing at the Keycloak realm issuer and the seeded
client credentials. This is dev configuration only; there is no production
equivalent.
