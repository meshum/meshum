# https://just.systems

default: rust elixir

rust: format_rust lint_rust dependencies_rust test_rust

[working-directory: 'server']
elixir:
    mix check

# Check if Rust code is formatted correctly
format_rust: fmt_rust taplo_rust

[working-directory: 'daemon']
fmt_rust:
    cargo fmt --check

[working-directory: 'daemon']
taplo_rust:
    taplo check

# Run static analysis
lint_rust: check_rust clippy_rust

[working-directory: 'daemon']
check_rust:
    cargo check

[working-directory: 'daemon']
clippy_rust:
    cargo clippy --all-targets --all-features -- -D warnings

# Check dependencies and licensing
dependencies_rust: machete_rust deny_rust audit_rust

[working-directory: 'daemon']
machete_rust:
    cargo machete

[working-directory: 'daemon']
deny_rust:
    cargo deny check

[working-directory: 'daemon']
audit_rust:
    cargo audit

# Attempts to automatically fix issues we can
[working-directory: 'daemon']
fix_rust:
    cargo clippy --fix --allow-dirty
    cargo fmt
    taplo format

# Runs all unit tests in the workspace; CI passes the 'fast' profile for quicker builds.
[working-directory: 'daemon']
test_rust profile='dev':
    cargo nextest run --no-fail-fast --cargo-profile {{ profile }}

# Check commit messages
commits:
    committed origin/master..HEAD

# Generate the CHANGELOG.md from the Git history.
changelog:
    git-cliff -o CHANGELOG.md --latest --strip all

# Install all tools used for this repo's CI and other tools
setup: setup_tools setup_rust setup_elixir

setup_tools:
    cargo install cargo-deny
    cargo install committed
    cargo install git-cliff
    cargo install --locked cargo-nextest
    cargo install cargo-machete
    cargo install taplo-cli --locked
    cargo install cargo-audit --locked

[working-directory: 'daemon']
setup_rust:
    cargo fetch
    cargo build

[working-directory: 'server']
setup_elixir:
    mix deps.get
    mix deps.compile
    mix compile
    mix setup