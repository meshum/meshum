# https://just.systems

default:
    echo 'Hello, world!'

rust: format_rust lint_rust dependencies_rust test_rust

# Check if Rust code is formatted correctly
[working-directory: 'daemon']
format_rust:
    cargo fmt --check
    taplo check

# Run static analysis
[working-directory: 'daemon']
lint_rust:
    cargo check
    cargo clippy --all-targets --all-features -- -D warnings

# Check dependencies and licensing
[working-directory: 'daemon']
dependencies_rust:
    cargo machete
    cargo deny check
    cargo audit

# Attempts to automatically fix issues we can
[working-directory: 'daemon']
fix_rust:
    cargo clippy --fix --allow-dirty
    cargo fmt
    taplo format

# Runs all unit tests in the workspace.
[working-directory: 'daemon']
test_rust:
    cargo nextest run --no-fail-fast

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