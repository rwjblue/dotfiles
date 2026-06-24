# agent-review.nvim

Author inline review comments on an agent's work locally in Neovim, batched into
a single `.agent-review/comments.md` at the repo root that a tool-agnostic agent
skill (Claude Code / Codex) reads and addresses.

## Install (local, via this dotfiles repo)

Loaded by `packages/nvim/lua/plugins/agent-review.lua` as a `dir=` plugin.
Requires `snacks.nvim`.

## Keymaps (`<leader>r` group)

| Key | Action |
|-----|--------|
| `<leader>rc` | Add comment (normal: line; visual: range) |
| `<leader>re` | Edit comment under cursor |
| `<leader>rd` | Delete comment under cursor |
| `<leader>rl` | List all comments (snacks picker) |
| `<leader>rr` | Re-render comments |
| `]r` / `[r` | Next / previous comment |

`:AgentReviewClear` wipes the active batch (archiving is normally the agent skill's job).

## File format

See `docs/superpowers/specs/2026-06-24-agent-review-nvim-design.md`.

## Tests

`mise run agent-review:test`
