# agent-review.nvim — Inline Local Review for Agent Work

**Date:** 2026-06-24
**Status:** Approved design (Spec 1 of a multi-spec effort)

## Problem

Reviewing an AI agent's work currently happens on GitHub. Leaving comments there
that are only meant for one's own agent is noisy when real human reviews also
exist on the PR. The goal is to iterate **locally**: read the changed files in
Neovim, drop review comments anchored to specific lines, batch them up, and hand
the whole batch to the agent in one move.

Constraints:

- Must work with **Claude Code** (work machine) and **Codex** (personal machine).
  They share no API, so the handoff must be tool-agnostic.
- Comments are authored in Neovim and must survive editor restarts.
- The agent edits files on disk outside Neovim's awareness, so live in-process
  tracking (extmarks) cannot be the source of truth.

## Solution Overview

A standalone, publishable Neovim plugin (`packages/agent-review.nvim`) that lets
you author inline review comments while browsing a change, persists them to a
single stable Markdown file at the repo root (`.agent-review/comments.md`), and
renders them inline as virtual lines. The agent reads that file via a small
skill, addresses each comment, then asks for confirmation before archiving the
batch to `.agent-review/history/`.

The Markdown file is the **contract** between the Neovim side and the agent side.
It is simultaneously a clean brief a human/agent reads and a structured store
Neovim round-trips deterministically.

## Decomposition & Build Order

| # | Sub-project | Scope | When |
|---|---|---|---|
| **1** | **nvim plugin + file format** | Authoring, inline render, list panel, stable file, drift handling, mini.test on pure layers | **This spec** |
| 2 | Agent skill | `SKILL.md` (address → confirm → archive), symlinked into `packages/agents/skills/` to fan out to Claude + Codex via existing `dot:install` | later |
| 3 | Agent-side SDK tests | Behavioral test of the skill via the Claude Agent SDK (Claude-only; slow/costly — kept narrow) | later, optional |

No `npx` installer is needed: the existing `mise/tasks/dot/install` symlink
fan-out (`packages/agents/skills/` → `~/.claude/skills` and `~/.agents/skills`)
handles cross-tool placement of the skill.

## Scope of This Spec (Sub-project 1)

**In scope:** the `packages/agent-review.nvim` plugin; the `.agent-review/comments.md`
v1 format; mini.test coverage of the pure layers; a thin lazy spec to load the
package locally; a global-gitignore entry for `.agent-review/`.

**Deferred:** the agent `SKILL.md` and its symlink wiring (Spec 2); Claude-SDK
behavioral tests (Spec 3).

## Architecture

Pure logic is isolated from Neovim UI so the core is unit-testable.

| Module | Responsibility | nvim deps | Tested |
|---|---|---|---|
| `lua/agent-review/format.lua` | `encode(comments) → string`, `decode(string) → comments`. Pure. | none | heavy |
| `lua/agent-review/anchor.lua` | `resolve(lines, comment) → { status, line }` where status ∈ `exact` / `moved` / `orphaned`. Pure. | none | heavy |
| `lua/agent-review/store.lua` | Repo-root resolution (jj → git, reusing the existing detection pattern), load/save the file, comment CRUD, id allocation | fs only | medium |
| `lua/agent-review/render.lua` | Virtual-line + gutter-sign rendering via a dedicated extmark namespace | yes | smoke |
| `lua/agent-review/ui.lua` | Authoring float / scratch buffer, edit, delete, snacks list panel, jump-to | yes | smoke |
| `lua/agent-review/init.lua` | `setup(opts)`, user commands, keymaps, autocmds, config table | yes | — |

Repo-root resolution reuses the existing pattern (`jj root`, falling back to
`git`) already present in the Neovim config (`rwjblue/init.lua`,
`plugins/extras/jj.lua`).

### Standalone packaging

`packages/agent-review.nvim/` is laid out as a normal, publishable Neovim plugin
(`lua/agent-review/…`, `tests/`, `README.md`, plus a `skills/<name>/` directory
for Spec 2). It is loaded locally via a thin lazy spec
(`packages/nvim/lua/plugins/agent-review.lua`) that points at the package by
`dir`, so it can later be published as its own repo without restructuring.

## File Format v1

One stable file. The `>` quote is both the agent's context and Neovim's
re-anchor snippet.

```markdown
<!-- agent-review:v1 -->
# Agent review comments

<!-- agent-review:v1 comment id=1 file=src/user.ts start=42 end=44 -->
### src/user.ts:42-44
> const result = await fetchUser(id)
> return result.name

This needs a null check before `.name`.
```

**Parse rules:**

- Blocks split on the `<!-- agent-review:v1 comment … -->` marker.
- Structured attributes live only in the marker (`id`, `file`, `start`, `end`) —
  safe fields only, so no escaping of snippet text inside HTML-comment attributes.
- `>`-quoted lines immediately after the `###` heading are the anchored
  snippet(s). The anchor used for drift resolution is the **first** quoted line,
  trimmed.
- Everything after the next blank line, until the next marker or EOF, is the
  comment **body** (Markdown, may be multi-line).
- Serialization regenerates the file deterministically from the comment model
  (the `###` heading is derived/regenerated, not parsed for data).

**Documented constraint:** a comment body must not contain the literal marker
prefix `<!-- agent-review:v1 comment`.

### Comment model

```
{
  id    = integer,        -- stable within the file, monotonic; targets edit/delete
  file  = string,         -- repo-root-relative path
  start = integer,        -- 1-based start line at authoring time
  end   = integer,        -- 1-based end line (== start for single-line)
  snippet = string,       -- trimmed text of the start line, for re-anchoring
  body  = string,         -- markdown, possibly multi-line
}
```

## Anchoring & Drift (`anchor.lua`, pure)

Given the current buffer's lines and a comment `{ start, snippet }`:

1. If line `start` exists and its trimmed text equals `snippet` → **exact**, `line = start`.
2. Else search the buffer for a line whose trimmed text equals `snippet`; choose
   the occurrence **nearest** to `start` → **moved**, `line = found`.
3. Else → **orphaned**, no line.

`resolve` is a pure function over `(lines, start, snippet)` returning
`{ status, line }`. Rendering consumes the result: `exact` renders normally,
`moved` renders at the new line with a subtle `(moved)` tag, `orphaned` is not
placed inline and instead appears in the list panel's orphaned bucket.

## UX Surface

- **Add comment:** normal mode comments on the current line; visual mode comments
  on the selected range. Opens a `snacks.input` one-liner; a key expands to a
  scratch Markdown buffer for longer comments. Saving writes to the store and
  re-renders.
- **Edit / Delete:** act on the comment under the cursor.
- **List panel:** a **snacks picker** (consistent with the existing `<leader>jd`
  branch-diff picker) showing `path:line` + a body preview, with a dedicated
  *Orphaned* section, a preview pane, and `<CR>` to jump.
- **Navigate:** `]r` / `[r` jump to next / previous comment.
- **Render:** automatic on buffer enter for files that have comments; uses an
  extmark namespace and clears + redraws on change.
- **Keymaps:** a `<leader>r` "review" group — `rc` add, `re` edit, `rd` delete,
  `rl` list, `rr` reload. (Verify no LazyVim default collision during
  implementation; rebindable.)
- **Local escape hatch:** `:AgentReviewClear` (no default keymap) wipes the active
  batch. Archiving is normally the skill's job; this is only for emergencies.

## Persistence

- Active file: `<repo-root>/.agent-review/comments.md`.
- History: `<repo-root>/.agent-review/history/` (written by the skill in Spec 2;
  Neovim only ensures `.agent-review/` exists).
- Add `.agent-review/` to the global gitignore managed in this repo (locate the
  exact file during implementation).

## Testing Strategy (mini.test)

- **`format`:** encode↔decode roundtrip; decode of hand-written fixtures;
  multi-line ranges; Markdown bodies (including bodies containing `>` lines);
  resilience to garbled input.
- **`anchor`:** exact; moved with nearest-match selection; orphaned; multiple
  matches; empty buffer.
- **`store`:** load/save in a temp dir; repo-root resolution inside a temp repo;
  CRUD; id allocation across reloads.
- **`render` / `ui`:** light smoke tests only.
- A `mise` task runs the suite headless (`nvim --headless` + mini.test).

## Contract for the Deferred Skill (Spec 2)

Documented here so Spec 1 writes a file the skill can consume. Skill name
`address-review` (adjustable). Behavior: read the stable file; address each
comment, using the `>` snippet to relocate a line that has drifted; summarize
what it did per comment; **ask the user to confirm**; on confirmation, move
`comments.md` → `history/<timestamp>.md` and leave a fresh active file. A single
`SKILL.md` serves both Claude and Codex via the `dot:install` symlink fan-out.

## Open / Adjustable Decisions

- `<leader>r` keymap prefix — pending LazyVim collision check; rebindable.
- Skill name `address-review` — finalized in Spec 2.
- Exact global-gitignore file location — resolved during implementation.
