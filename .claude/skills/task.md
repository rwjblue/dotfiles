# go-task Automation

This skill helps with go-task usage in this repository.

## Overview

All automation uses **go-task** (https://taskfile.dev). Tasks are defined in YAML files.

## File Structure

```
Taskfile.dist.yml      # Root taskfile, includes taskfiles/*
taskfiles/
├── binutils.yml       # Custom Rust utilities
├── brew.yml           # Homebrew management
├── dotfiles.yml       # Symlink/copy dotfiles
├── mise.yml           # Polyglot tool manager
├── nvim.yml           # Neovim plugin management
├── shell.yml          # Shell environment refresh
└── system.yml         # System dependencies
```

## Naming Convention

Tasks follow `namespace:verb` pattern:
- `nvim:update` - Update Neovim plugins
- `brew:install` - Install Homebrew packages
- `dotfiles:install` - Apply dotfile symlinks

## Common Commands

```bash
task -l              # List all available tasks
task install         # Run full setup
task <name>          # Run specific task
task --dry           # Show what would run
```

## Adding New Tasks

1. Add to appropriate `taskfiles/<namespace>.yml`
2. Use `desc:` for user-facing tasks
3. Use `internal: true` for helper tasks
4. Follow existing indentation (2 spaces)

## Variables

- `{{.ROOT_DIR}}` - Repository root
- `{{.FORCE}}` - From FORCE env var for reinstall mode
- Task-local vars in `vars:` block
