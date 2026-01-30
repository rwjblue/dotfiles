---
name: nvim
description: Neovim/LazyVim configuration. Use when working with Neovim config, plugins, keymaps, or TreeSitter queries.
user-invocable: false
---

# Neovim Configuration

## Overview

- Based on **LazyVim** starter
- Config location: `packages/nvim/`
- Plugin management: lazy.nvim with `lazy-lock.json` for version pinning

## Directory Structure

```
packages/nvim/
├── init.lua              # Entry point
├── lazy-lock.json        # Plugin version lock file
└── lua/
    ├── config/           # Core config (autocmds, keymaps, options)
    ├── plugins/          # Plugin specs (lazy.nvim format)
    └── util/             # Custom utilities
```

## Common Tasks

- `task nvim:restore` - Restore plugins to locked versions
- `task nvim:update` - Update plugins and lock file

## Plugin Development

When adding/modifying plugins:

1. Add plugin spec in `lua/plugins/<name>.lua`
2. Follow lazy.nvim spec format with `opts`, `config`, `dependencies`
3. After testing, run `task nvim:update` to update lock file

## TreeSitter Customization

Query overrides go in `after/queries/<language>/` following standard Neovim patterns.

## References

- LazyVim docs: https://lazy.folke.io
- Plugin specs live in `lua/plugins/`
