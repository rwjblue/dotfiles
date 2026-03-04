---
name: dotfiles
description: Dotfiles repository structure and patterns. Use when adding configs, managing symlinks, or understanding the packages/ layout.
user-invocable: false
---

# Dotfiles Management

## Repository Structure

- `packages/` - Source configs organized by tool (nvim, git, zsh, claude, etc.)
- `packages-dist/` - Generated outputs (shell configs)
- `local-packages/` - Separate private repo for work-specific overrides (symlinked)
- `mise/config.toml` and `mise/tasks/` - Mise taskrunner automation
- `Brewfile` - Homebrew package manifest

## Key Patterns

### Adding New Tool Config

1. Create `packages/<toolname>/` with config files
2. Add a `link_dotfile` call in `mise/tasks/dot/install`:
   ```bash
   link_dotfile "packages/<toolname>/"  "$HOME/.config/<toolname>"
   ```
3. Run `mise run dot:install` to apply

### Symlink vs Copy

- **Symlink** (default): Changes in repo immediately apply
- **Copy**: For files needing local customization (use `copy_dotfile` function in `mise/tasks/dot/install`)

### Local Overrides

Work-specific or private config goes in `local-packages/` (separate repo), not here.

## Common Commands

- `./install` - Full system setup
- `FORCE=true ./install` - Reinstall, clobbering existing files
- `mise tasks` - List available tasks
- `mise run dot:install` - Apply dotfile symlinks/copies
- `mise run nvim:restore` - Restore Neovim plugins from lock file

## Task Naming Convention

Tasks use `namespace:verb` pattern (e.g., `nvim:update`, `brew:install`), defined by directory structure under `mise/tasks/`.
