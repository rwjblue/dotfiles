# Installation Pipeline

## Purpose

The dotfiles installation is a 4-stage sequential pipeline orchestrated by mise tasks. It bootstraps a workstation from scratch or safely re-runs on an existing setup.

## Requirements

### Requirement: Minimal entry point

The `./install` script SHALL bootstrap mise if not present, then delegate everything to `mise run install`. No logic MUST live in the entry point itself.

#### Scenario: Fresh machine with no mise
- **WHEN** `./install` runs and `mise` is not on PATH
- **THEN** mise is installed via `curl https://mise.run | sh` before proceeding

### Requirement: Four-stage sequential execution

The install task SHALL run four stages in strict order: system dependencies, custom utilities, dotfile configuration, and editor setup. Each stage MUST complete before the next begins.

#### Scenario: Full installation order
- **WHEN** `mise run install` executes
- **THEN** it runs in order: `system:install` → `binutils:install` → `dot:install` → `nvim:restore`

### Requirement: System dependency installation

`system:install` SHALL handle platform-specific package managers and tool runtimes. On macOS it MUST install Homebrew and packages from `Brewfile`. On all platforms it installs and updates mise-managed tools.

#### Scenario: macOS system setup
- **WHEN** running on macOS (`darwin*`)
- **THEN** `brew:install` runs Homebrew installation and `brew bundle` from `Brewfile`, then `tools:install` and `tools:update` handle mise-managed runtimes

#### Scenario: Linux system setup
- **WHEN** running on Linux
- **THEN** `system:install-linux` handles platform-specific tools (starship, eza, bat, delta, sd via cargo binstall, fzf from git)

### Requirement: Custom utilities build

`binutils:install` SHALL clone and build the shared_binutils Rust project (from `malleatus/shared_binutils`), build local binutils from `packages/binutils/`, and generate symlinks for all utilities.

#### Scenario: First-time binutils setup
- **WHEN** `shared_binutils` directory doesn't exist
- **THEN** it's cloned from GitHub, then both shared and local binutils are compiled with `cargo build`

### Requirement: Dotfile configuration

`dot:install` SHALL create all symlinks and copies, then MUST run `shell:update` to rebuild shell caches and completions.

#### Scenario: Shell cache rebuild
- **WHEN** `dot:install` completes symlink setup
- **THEN** `shell:update` runs `cache-shell-startup` for all shells (zsh, bash, fish, starship), clears the zsh completion cache, and rebuilds completions

### Requirement: Editor setup

`nvim:restore` SHALL run Neovim in headless mode to restore plugins from the lock file, clean unused plugins, update TreeSitter parsers, and update Mason-managed LSP servers.

#### Scenario: Neovim headless restoration
- **WHEN** `nvim:restore` runs
- **THEN** it executes `Lazy! restore`, `Lazy! clean`, `Lazy! clear`, `TSUpdateSync`, and `MasonUpdateAll` in a single headless Neovim session

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
