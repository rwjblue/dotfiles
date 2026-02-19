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
- `taskfiles/*.yml` - go-task automation definitions
- `Brewfile` - Homebrew package manifest

## Key Patterns

### Adding New Tool Config

1. Create `packages/<toolname>/` with config files
2. Add symlink entry in `taskfiles/dotfiles.yml` under `DOTFILES` list:
   ```yaml
   - "packages/<toolname>/|$HOME/.config/<toolname>"
   ```
3. Run `task dotfiles:install` to apply

### Symlink vs Copy

- **Symlink** (default): Changes in repo immediately apply
- **Copy**: For files needing local customization (use `copy_dotfile` task, add to `COPY_DOTFILES`)

### Local Overrides

Work-specific or private config goes in `local-packages/` (separate repo), not here.

## Common Commands

- `./install` - Full system setup
- `FORCE=true ./install` - Reinstall, clobbering existing files
- `task -l` - List available tasks
- `task dotfiles:install` - Apply dotfile symlinks/copies
- `task nvim:restore` - Restore Neovim plugins from lock file

## Task Naming Convention

Tasks use `namespace:verb` pattern (e.g., `nvim:update`, `brew:install`).
