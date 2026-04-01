# Shell Configuration

## Purpose

Shell configs use a build-time compilation pattern: source files in `packages/` contain command directives that get expanded into `packages-dist/` for fast startup. Zsh is the primary shell; bash redirects to zsh; fish has standalone config.

## Requirements

### Requirement: Build-time command inlining

Source shell configs SHALL contain `# CMD:` and `# CMD_SILENT:` directives. The `cache-shell-startup` tool (from shared_binutils) MUST execute these commands and inline their output into `packages-dist/`, eliminating runtime shell initialization overhead.

#### Scenario: Tool initialization inlining
- **WHEN** `packages/zsh/zshrc` contains `# CMD: zoxide init zsh`
- **THEN** `cache-shell-startup` runs the command and writes the full output into `packages-dist/zsh/zshrc` between `# OUTPUT START:` / `# OUTPUT END:` markers

#### Scenario: Silent command expansion
- **WHEN** a directive uses `# CMD_SILENT:` (e.g. for completion generation)
- **THEN** the command output is inlined but build-time logging is suppressed

#### Scenario: Rebuilding after source changes
- **WHEN** source files in `packages/zsh/` (or bash, fish, starship) change
- **THEN** run `mise run shell:update` to re-run `cache-shell-startup` for all shells and rebuild completions

### Requirement: Zsh as primary shell

Zsh SHALL be the fully-configured primary shell. The startup chain MUST be: `zshenv` (sources `path.zsh` for all shell types) → `zprofile` (empty) → `zshrc` (interactive config) → `zshrc.local` (machine-specific overrides).

#### Scenario: PATH setup across shell types
- **WHEN** any zsh session starts (interactive, non-interactive, cron)
- **THEN** `zshenv` sources `path.zsh` which sets up PATH with correct ordering via `_path_add()` and `_ensure_first_path()` helper functions

#### Scenario: Interactive shell initialization
- **WHEN** an interactive zsh session starts
- **THEN** `zshrc` sets up: history options, tool initializations (zoxide, atuin, starship, mise), fpath for completions, vi mode, editor/pager settings, aliases, and sources `zshrc.local`

### Requirement: Idempotent PATH management

`path.zsh` SHALL provide helper functions that prevent PATH duplication: `_path_add()` MUST only add if not present, `_path_remove()` cleans entries, `_ensure_first_path()` moves an entry to the front. `path.zsh` is sourced in both `zshenv` and `zshrc` safely.

#### Scenario: PATH ordering
- **WHEN** `path.zsh` runs
- **THEN** it ensures this order: `/opt/homebrew/bin` → `/opt/homebrew/sbin` → `$CARGO_HOME/bin` → fzf → custom binutils → `$HOME/.local/bin`

### Requirement: Bash as zsh redirect

Bash configuration SHALL be minimal — it MUST exist only to redirect to zsh in interactive contexts and to support rdev environments where bash is the default.

#### Scenario: Interactive bash session
- **WHEN** bash starts interactively (not in rdev/tmux context)
- **THEN** it exec's into `zsh -l`, replacing the bash process

### Requirement: Fish standalone configuration

Fish SHALL have its own complete configuration built from `packages/fish/config.fish` via the same `# CMD:` directive pattern. It MUST be self-contained and not depend on zsh.

#### Scenario: Fish config build
- **WHEN** `packages/fish/config.fish` contains `# CMD: starship init fish --print-full-init`
- **THEN** `packages-dist/fish/config.fish` contains the full Starship initialization for fish

### Requirement: Completion management

Completions SHALL come from three sources: Homebrew (`/opt/homebrew/share/zsh/site-functions/`), custom completions in `packages/zsh/completions/` (expanded via `# CMD_SILENT:` into `packages-dist/`), and tool-generated completions (e.g. openspec). The fpath MUST load Homebrew first, then custom completions.

#### Scenario: Adding a non-Homebrew completion
- **WHEN** a tool's completions aren't provided by Homebrew
- **THEN** add a completion file to `packages/zsh/completions/` — either as a `# CMD_SILENT:` directive (for generated completions) or as a static file

### Requirement: Starship prompt with modular configuration

Starship SHALL use a modular config: `base.toml` holds shared settings, `jj.toml` and `git.toml` extend it via `# CMD: cat` directives. The default prompt MUST be jj-optimized (disables git modules, adds custom jj status). Users can switch via `STARSHIP_CONFIG` env var.

#### Scenario: Default starship configuration
- **WHEN** dotfiles are installed
- **THEN** `packages-dist/starship/jj.toml` is symlinked as `~/.config/starship.toml` — showing jj change/commit IDs, bookmarks, and status flags

#### Scenario: Git-focused prompt
- **WHEN** a user wants git-native prompt info instead of jj
- **THEN** set `export STARSHIP_CONFIG="$HOME/.config/starship/git.toml"` in `~/.zshrc.local`

### Requirement: Local shell overrides

Machine-specific shell customizations MUST go in `~/.zshrc.local` (installed via `copy_dotfile`, never overwritten). This file SHALL be sourced at the end of `zshrc`.

#### Scenario: Adding work-specific aliases
- **WHEN** a machine needs custom aliases or environment variables
- **THEN** add them to `~/.zshrc.local` — this file persists across dotfile updates
