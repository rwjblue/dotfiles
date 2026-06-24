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

Comments live in `.agent-review/comments.md` at the repo root, e.g.:

````markdown
<!-- agent-review:v1 -->
# Agent review comments

<!-- agent-review:v1 comment id=1 file=src/user.ts start=42 end=44 -->
### src/user.ts:42-44
> const result = await fetchUser(id)

This needs a null check before `.name`.
````

The HTML-comment marker carries the structured anchor (`id`, `file`, `start`, `end`);
the `>` quote is the line snippet used to re-anchor if the code drifts; the prose
below is the comment body. See also
`docs/superpowers/specs/2026-06-24-agent-review-nvim-design.md` in the dotfiles repo.

## Tests

`mise run agent-review:test`
