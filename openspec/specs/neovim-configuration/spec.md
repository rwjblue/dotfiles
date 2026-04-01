# Neovim Configuration

## Purpose

The Neovim setup is built on LazyVim with custom plugins, keymaps, and per-machine overrides. Plugins are version-locked and managed via mise tasks.

## Requirements

### Requirement: LazyVim base framework

LazyVim SHALL provide the foundation — sensible defaults, plugin management, and extras. Custom configuration MUST layer on top without forking or patching LazyVim itself.

#### Scenario: Plugin spec loading order
- **WHEN** Neovim starts
- **THEN** it loads: LazyVim base → LazyVim extras (from `lazyvim.json`) → custom plugins (`lua/plugins/`) → local machine plugins (`local_nvim.plugins` if available)

### Requirement: LazyVim extras via lazyvim.json

Optional LazyVim feature bundles SHALL be enabled in `lazyvim.json`. This includes language support (go, rust, typescript, python, java), editor features (dap, yanky, snacks), and formatting (prettier).

#### Scenario: Enabling a new language
- **WHEN** adding support for a new language
- **THEN** add the corresponding `lazyvim.plugins.extras.lang.<name>` entry to `lazyvim.json`

### Requirement: Custom plugin organization

Custom plugin specs MUST live as individual Lua files in `lua/plugins/`. Each file SHALL return one or more lazy.nvim spec tables. An `extras/` subdirectory holds optional plugin groups (jj, zellij, lang/markdown) that can be toggled via `lazyvim.json`.

#### Scenario: Adding a new plugin
- **WHEN** adding a standalone plugin
- **THEN** create `lua/plugins/<name>.lua` returning a lazy.nvim spec table

#### Scenario: Adding an optional plugin group
- **WHEN** adding a group of related plugins that should be togglable
- **THEN** create `lua/plugins/extras/<name>.lua` and enable it via `lazyvim.json`

### Requirement: Custom utilities namespace

User helper functions MUST live in `lua/rwjblue/` to avoid polluting the global namespace. This includes lockfile management, tab helpers, terminal utilities, and AI integration (codecompanion).

#### Scenario: Adding a utility function
- **WHEN** custom Lua code is needed across multiple plugins or configs
- **THEN** add it to `lua/rwjblue/` and require it as `require("rwjblue.module")`

### Requirement: after/ directory for overrides

Post-plugin overrides SHALL use Neovim's `after/` directory: `ftplugin/` for filetype-specific settings, `queries/` for TreeSitter query overrides, and `syntax/` for temporary syntax files.

#### Scenario: Filetype-specific settings
- **WHEN** a filetype needs custom options (e.g. foldlevel)
- **THEN** add `after/ftplugin/<filetype>.lua`

#### Scenario: TreeSitter query override
- **WHEN** a language's default folding or highlighting behavior needs adjustment
- **THEN** add or modify query files in `after/queries/<language>/`

### Requirement: Plugin lock file management

`lazy-lock.json` MUST pin every plugin to a specific commit. Three mise tasks SHALL manage the lifecycle: `nvim:restore` (install from lock), `nvim:update` (update all and re-lock), `nvim:commit` (commit the lock file if changed).

#### Scenario: Restoring plugins on a new machine
- **WHEN** `mise run nvim:restore` runs
- **THEN** Neovim runs headless: `Lazy! restore` from lock file, `Lazy! clean` unused, `TSUpdateSync` parsers, `MasonUpdateAll` LSP servers

#### Scenario: Updating plugins
- **WHEN** `mise run nvim:update` runs
- **THEN** Neovim runs headless with `Lazy! sync` (updates all plugins and lock file), then `nvim:commit` auto-commits the lock file change

### Requirement: Local machine overrides

Machine-specific Neovim configuration MUST live in a `local_nvim` module (from `local-packages/`). This can add plugins, override keymaps, and provide a separate lock file for private plugins.

#### Scenario: Work-specific plugin
- **WHEN** a plugin is only needed on work machines
- **THEN** add it via `local_nvim.plugins` in the local-packages overlay

#### Scenario: Lock file selection
- **WHEN** local plugins exist
- **THEN** lazy.nvim uses the local lock file (`local_nvim/lazy-lock.json`) instead of the public one

### Requirement: Conditional features by environment

Some features SHALL be environment-dependent: Copilot MUST be disabled in rdev environments, plugin install/update checks MUST be skipped when opening commit-related filetypes (gitcommit, jj, jjdescription).

#### Scenario: Opening a commit message
- **WHEN** Neovim opens with a gitcommit or jj filetype
- **THEN** Lazy install and update checks are suppressed for faster startup
