# Installation Pipeline

## Purpose

The dotfiles installation is a 4-stage sequential pipeline orchestrated by mise tasks. It bootstraps a workstation from scratch or safely re-runs on an existing setup.

## Requirements

### Requirement: Minimal entry point

The `./install` script SHALL bootstrap mise if not present, then delegate setup to `mise run install` from the repository root.

#### Scenario: Fresh machine with no mise
- **WHEN** `./install` runs and `mise` is not on PATH
- **THEN** mise is installed via `curl https://mise.run | sh` before proceeding

### Requirement: Four-stage sequential execution

The install task SHALL run four stages in strict order: system dependencies, custom utilities, dotfile configuration, and editor setup. Each stage MUST complete before the next begins.

#### Scenario: Full installation order
- **WHEN** `mise run install` executes
- **THEN** it runs in order: `system:install` → `binutils:install` → `dot:install` → `nvim:restore`

### Requirement: System dependency installation

`system:install` SHALL handle platform-specific package managers and tool runtimes. On macOS it MUST install Homebrew and packages from `Brewfile`. On all platforms it installs mise-managed tools at their locked versions; it MUST NOT upgrade them (that is `tools:update`).

#### Scenario: macOS system setup
- **WHEN** running on macOS (`darwin*`)
- **THEN** `brew:install` makes the default prefixes available on `PATH`, installs Homebrew if needed, and runs `brew bundle --no-upgrade` from `Brewfile`. The subsequent stages can use the Homebrew-installed tools in the same invocation.

#### Scenario: Linux system setup
- **WHEN** running on Linux
- **THEN** `system:install` reports missing host prerequisites before downloading tools. After mise installs the managed runtime tools, `system:install-linux` installs Starship, installs eza, bat, delta, and sd using cargo binstall, and sets up fzf.

#### Scenario: Global mise configuration on first install
- **WHEN** no global mise configuration exists
- **THEN** the install tasks use the repository's `packages/mise/config.toml` and its adjacent lockfile until the managed configuration is linked. Resolving tools does not require an authenticated `gh` account.

### Requirement: Custom utilities build

`binutils:install` SHALL clone and build the shared_binutils Rust project (from `malleatus/shared_binutils`), build local binutils from `packages/binutils/`, and generate symlinks for all utilities.

#### Scenario: First-time binutils setup
- **WHEN** `shared_binutils` directory doesn't exist
- **THEN** it's cloned from GitHub, then the installer compiles and generates symlinks for the built workspaces before the home binutils config is available

### Requirement: Dotfile configuration

`dot:install` SHALL run `shell:update` before creating symlinks and copies that depend on generated files.

#### Scenario: Shell cache rebuild
- **WHEN** `dot:install` runs with no generated shell files
- **THEN** `shell:update` generates the Zsh, Fish, and Starship configurations and clears the Zsh completion cache before the installer creates any links to generated files. Zsh rebuilds its completion cache on the next interactive launch.

### Requirement: Editor setup

`nvim:restore` SHALL use the public Neovim configuration and plugin lockfile and wait for the corresponding Tree-sitter parsers. Mason-managed tools are installed by normal editor setup or updated explicitly with `:MasonUpdateAll`.

#### Scenario: Neovim headless restoration
- **WHEN** `nvim:restore` runs
- **THEN** it verifies the public plugin pins and parser setup before exiting. It uses a dedicated public data directory when the installed configuration differs from the bundled configuration or uses a private overlay.

### Requirement: Idempotent execution

The entire pipeline MUST be safe to re-run. Each task SHALL check for existing state before acting: existence checks before installing, symlink validation before linking, `cargo build` skips up-to-date artifacts, and Lazy restore is idempotent.

#### Scenario: Re-running install on configured machine
- **WHEN** `./install` runs on a machine that's already set up
- **THEN** each stage detects existing state and skips unnecessary work — no destructive changes occur

#### Scenario: Forced re-installation
- **WHEN** `FORCE=true ./install` runs
- **THEN** dotfile symlinks are removed and recreated (via `dot:install`), but copy-only files and system packages are unaffected

### Requirement: Fail-fast error handling

All tasks MUST use `set -euo pipefail`. Any failure SHALL stop the pipeline immediately with no retry logic. The user fixes the issue and re-runs (safe due to idempotency).

#### Scenario: Mid-pipeline failure
- **WHEN** a task fails (e.g. `cargo build` error)
- **THEN** execution stops immediately; the user can re-run after fixing the issue without side effects
