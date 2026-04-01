# Package & Symlink Architecture

## Purpose

Dotfile configurations are organized into versioned source packages (`packages/`), linked or copied to their runtime locations via `mise run dot:install`.

## Requirements

### Requirement: Package directory structure

Each tool's configuration MUST live in its own directory under `packages/<toolname>/`. This directory contains the canonical source files for that tool's configuration.

#### Scenario: Adding a new tool configuration
- **WHEN** a new tool needs managed configuration
- **THEN** create `packages/<toolname>/` with the tool's config files and add a `link_dotfile` call in `mise/tasks/dot/install`

### Requirement: Symlink-first installation

The default installation method SHALL be symlinking via `link_dotfile()`. Symlinked configs stay in sync with the repository — editing the source or pulling updates immediately takes effect.

#### Scenario: Normal dotfile installation
- **WHEN** `mise run dot:install` runs
- **THEN** each `link_dotfile` call creates a symlink from the target location (e.g. `~/.config/nvim`) to the source in `packages/`

#### Scenario: Target already exists as correct symlink
- **WHEN** the target is already a symlink pointing to the correct source
- **THEN** the link is left unchanged (idempotent)

#### Scenario: Broken symlink exists at target
- **WHEN** a symlink exists at the target but points to a nonexistent path
- **THEN** the broken symlink is removed and replaced with the correct one

#### Scenario: Non-symlink file exists at target
- **WHEN** a regular file or directory exists at the target location
- **THEN** a message is logged and the file is left untouched (no clobbering)

#### Scenario: Force mode installation
- **WHEN** `FORCE=true` is set
- **THEN** the target is removed with `rm -rf` before creating the symlink, regardless of what exists there

### Requirement: Copy-only for local overrides

Files that users customize per-machine MUST be installed via `copy_dotfile()`. These are created once and SHALL never be overwritten, even with `FORCE=true`.

#### Scenario: First-time copy installation
- **WHEN** `copy_dotfile` runs and the target does not exist
- **THEN** the file is copied to the target location

#### Scenario: Copy target already exists
- **WHEN** `copy_dotfile` runs and the target already exists
- **THEN** the file is left untouched (never overwrites, ignores FORCE)

#### Scenario: Typical copy-only files
- **WHEN** a file serves as a machine-specific override template
- **THEN** it uses `copy_dotfile` — examples: `.zshrc.local`, `.gitconfig.local`, `.tmux.local.conf`

### Requirement: Local-packages overlay

Work-specific or private configurations MUST live in `local-packages/`, a symlink to a separate private repository. This keeps the public dotfiles repo generic.

#### Scenario: Local configuration override
- **WHEN** a tool needs work-specific settings
- **THEN** the override goes in `local-packages/` and is wired in via the tool's local include mechanism (e.g. git's `[include]`, zsh's `source ~/.zshrc.local`, mise's `config.local.toml`)

#### Scenario: Local mise tasks
- **WHEN** work-specific mise tasks are needed
- **THEN** they go in `local-packages/mise/tasks/` and are loaded via `task_config.includes` in `local-packages/mise/config.local.toml`

### Requirement: packages-dist distribution layer

Shell configurations SHALL use a build step: source files in `packages/` contain `# CMD:` directives that get expanded by `cache-shell-startup` into `packages-dist/`. The distributed (built) files are what MUST be symlinked to the home directory.

#### Scenario: Shell config with CMD directives
- **WHEN** a source file contains `# CMD: <command>` or `# CMD_SILENT: <command>`
- **THEN** `cache-shell-startup` executes the command and inlines its output between `# OUTPUT START:` / `# OUTPUT END:` markers in `packages-dist/`

#### Scenario: Starship modular config
- **WHEN** starship configs in `packages/starship/` use `# CMD: cat ./packages/starship/base.toml`
- **THEN** the base config is inlined into each variant (git.toml, jj.toml) at build time, producing self-contained files in `packages-dist/starship/`

#### Scenario: Rebuilding distributed files
- **WHEN** source files in `packages/` change
- **THEN** run `mise run shell:update` which re-runs `cache-shell-startup` for all shells and rebuilds completions
