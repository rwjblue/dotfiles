---
name: task
description: Mise taskrunner automation patterns. Use when adding tasks, running commands, or understanding task structure.
user-invocable: false
---

# Mise Taskrunner Automation

All automation uses **mise** (https://mise.jdx.dev) file-based tasks. Tasks are executable scripts in the `mise/tasks/` directory.

## File Structure

```
mise/
├── config.toml               # Project-level mise config (schema, min_version)
└── tasks/
    ├── install                # Full setup orchestration
    ├── system/
    │   ├── install            # System dependency orchestration
    │   └── install-linux      # Linux-specific tool installation
    ├── binutils/
    │   ├── install            # Clone, build, symlink orchestration
    │   ├── build              # Build shared + local binutils
    │   └── cache-shell-startup # Cache shell startup files
    ├── dot/
    │   └── install            # Link/copy all dotfiles
    ├── brew/
    │   ├── install            # Install Homebrew + bundle
    │   ├── update             # Dump Brewfile + commit
    │   ├── upgrade            # brew update + upgrade + update Brewfile
    │   └── cleanup            # brew cleanup + autoremove
    ├── nvim/
    │   ├── restore            # Restore plugins from lazy-lock.json
    │   ├── update             # Update plugins + commit lock file
    │   └── commit             # Commit lazy-lock.json if changed
    ├── shell/
    │   └── update             # Refresh shell startup cache + completions
    └── tools/
        ├── install            # mise install
        ├── update             # mise up
        └── outdated           # mise outdated -l
```

## Naming Convention

Tasks follow `namespace:verb` pattern, defined by directory structure:
- `nvim:update` → `mise/tasks/nvim/update`
- `brew:install` → `mise/tasks/brew/install`
- `dot:install` → `mise/tasks/dot/install`

## Common Commands

```bash
mise tasks               # List all available tasks
mise run install         # Run full setup
mise run <name>          # Run specific task (e.g., mise run brew:install)
```

## Adding New Tasks

1. Create an executable script in `mise/tasks/<namespace>/`
2. Add `#!/usr/bin/env bash` and `set -euo pipefail`
3. Add `#MISE description="..."` metadata comment
4. Use `#MISE hide=true` for internal/helper tasks
5. Use `#MISE depends=[...]` for task dependencies
6. Make the file executable: `chmod +x mise/tasks/<namespace>/<task>`

## Task Metadata

Tasks use `#MISE` comment directives:
- `#MISE description="..."` - Task description shown in `mise tasks`
- `#MISE depends=["dep1", "dep2"]` - Run dependencies before this task
- `#MISE hide=true` - Hide from `mise tasks` listing

## Variables

- `$MISE_PROJECT_ROOT` - Repository root (set automatically by mise)
- `$FORCE` - From FORCE env var for reinstall mode
- `$OSTYPE` - Platform detection (`darwin*` for macOS, `linux*` for Linux)
