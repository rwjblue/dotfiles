---
name: jj-commit
description: >-
  Create a jujutsu commit for the current working copy. Use when committing
  with jj (not git). Loads the commit-message skill for style, subject/body,
  confirm vs auto, and citations; this skill covers signing and jj mechanics
  only.
argument-hint: "[optional: brief description of changes]"
---

# JJ Commit

Create a commit for current changes with jj. The message comes from the
`commit-message` skill.

**User hint:** $ARGUMENTS

## Signing Policy (Mandatory)

- Commit signing for pushed changes is required in this environment.
- Never bypass signing via config overrides (for example `--config git.sign-on-push=false`) or by changing config to disable signing.
- If this workflow includes pushing and signing fails, stop and ask the user to resolve signer/agent issues; do not push unsigned as a workaround.

## Load `commit-message`

Do not write the message yourself. Load the `commit-message` skill and follow
it in full for mode (`--auto` / `--confirm` / `AGENTS.md`), style matching,
subject/body rules, citations, and user confirmation.

How to load it (first that works):

1. Invoke by name: `commit-message` (Cursor / Claude Code: `/commit-message`; Pi: `/skill:commit-message`; Codex: the skill name).
2. Read sibling `../commit-message/SKILL.md`.
3. Read `~/.agents/skills/commit-message/SKILL.md`.

Pass `$ARGUMENTS` through. `commit-message-default` and the older
`jj-commit-default` in `AGENTS.md` are both valid.

## Process

### 1. Review current changes

Run `jj diff --stat` to see which files are affected and the scale of changes.

Then decide how much more context you need:

- **In-session changes** — If the current conversation already contains context
  about why these files were modified (you made the changes, or they were
  discussed), the stat is sufficient. You already know the motivation; use the
  session context. Do not re-read the full diff.

- **Out-of-session changes** — If the working copy contains changes you have no
  context for (fresh session, manual edits, external tool), run `rtk jj diff`
  to understand what changed semantically. RTK compresses the output; full raw
  diff is in `~/.local/share/rtk/tee/` if needed.

If the user asked to commit only specific files or paths, scope both the stat
and any full diff to those paths (`jj diff --stat <paths>`, `rtk jj diff
<paths>`) and treat the request as a scoped commit. Do not include unrelated
working-copy changes.

If there are no changes (empty diff), inform the user there's nothing to commit.

### 2. Draft and confirm the message

Load `commit-message` (see above) with the diff context and `$ARGUMENTS`.
Stop when it returns an approved message.

### 3. Create the commit

Run `jj commit -m "<approved message>"`.

For a scoped commit, include the requested paths:

```bash
jj commit <paths> -m "<approved message>"
```

Use `jj commit` (not `jj describe`) so that `@` advances to a new empty
revision, ready for more work. Never `git commit` in a colocated jj repo.

Confirm success to the user.
