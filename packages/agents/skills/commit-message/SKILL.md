---
name: commit-message
description: >-
  Draft a commit message that matches this repo's style. Use when writing or
  rewriting a git or jj commit message, including conventional commits, subject
  and body, confirm vs auto, and what to cite. VCS-agnostic; does not create
  the commit. Callers such as jj-commit load this skill for the prose, then
  create the commit themselves.
argument-hint: "[optional: brief description of changes]"
---

# Commit message

Draft a commit message that matches the style already used in this repo.
This skill does **not** create the commit. The caller (`jj-commit`, or git)
lands it.

**User hint:** $ARGUMENTS

## Load this from another skill

Skills cannot import each other. A caller should:

1. Invoke `commit-message` by name if the agent supports it (Cursor / Claude Code: `/commit-message`; Pi: `/skill:commit-message`; Codex: the skill name).
2. Otherwise read the sibling file `../commit-message/SKILL.md` relative to the calling skill.
3. If that path is missing, read `~/.agents/skills/commit-message/SKILL.md`.

Then follow this file in full. Do not improvise the message.

## Commit mode

Determine mode in this order:

1. If `$ARGUMENTS` contains `--auto` or `--yes`, mode is `auto`.
2. Else if `$ARGUMENTS` contains `--confirm`, mode is `confirm`.
3. Else check `AGENTS.md` at repo root for a line:
   `commit-message-default: auto|confirm`
   or the older alias `jj-commit-default: auto|confirm`
4. Else default to `confirm`.

Remove mode flags from `$ARGUMENTS` before using the remaining text as the
user hint.

## 1. Review the change (caller may already have done this)

If the caller already summarized the diff, do not re-read it. Otherwise:

- Prefer a stat first (`jj diff --stat` in a colocated jj repo, else `git diff --stat` / `git diff --cached --stat`).
- **In-session changes:** the conversation already explains why the files changed. The stat is enough. Do not re-read the full diff.
- **Out-of-session changes:** you have no context (fresh session, manual edits, external tool). Read a compressed or full diff. In a jj repo, `rtk jj diff` (raw diff in `~/.local/share/rtk/tee/` if needed). Otherwise `git diff` / `git diff --cached`.

If the user asked to commit only specific paths, scope the stat and diff to those paths. Do not include unrelated working-copy changes.

If there are no changes, say so and stop.

## 2. Analyze commit style

Look at the user's recent non-empty commit subjects in this repo (about 15):

```bash
# jj (prefer when .jj/ exists)
jj log --no-pager -r "mine() & ~empty()" --limit 15 -T 'description.first_line() ++ "\n"'

# git
git log -15 --format='%s' --author="$(git config user.email)"
```

If the author filter is empty, drop it and use the repo's recent subjects.

Identify the style:

- Conventional commits (`type(scope): description`)?
- A prefix like `[category]` or `category:`?
- Plain descriptive sentences?
- Tense/mood (imperative "add X" vs past "added X")?
- Capitalized? Periods at the end?
- Typical length?

Match whatever style you observe. Do not impose conventional commits unless the repo already uses them.

## 3. Draft the message

Based on the diff, the user's hint, and the observed style.

**Subject line** (first line):

- MUST be 72 characters or fewer
- Concise summary of the change
- Show the character count next to the subject when presenting to the user

**Body** (after a blank line):

- Always include a body for non-trivial changes (most changes are non-trivial)
- Explain **why** this change is being made (the motivation/problem)
- Explain **what** the change accomplishes at a high level
- Do NOT explain **how** unless the approach is non-obvious from the diff
- Wrap lines at 72 characters
- Only skip the body for truly trivial changes (typo fixes, single-line config tweaks)
- **Reference durable history carefully.** When citing a prior change that has already landed on the repository's main/trunk history, prefer the short commit SHA because it is a durable git artifact. Do not cite SHAs from unmerged branches, stacked PRs, or commits that may be rewritten or squash-merged; those SHAs may disappear from useful history. For unmerged or squash-merged work, prefer a PR number/full PR URL, issue ID, or avoid the reference in the commit message and put the context in the PR body instead.

The message should look like it belongs with the other commits in the repo.

## 4. Confirm with the user (conditional)

If mode is `confirm`, present the proposed message and ask:

- **Use this message** -- proceed with the drafted message
- **Edit message** -- ask for their preferred message
- **See diff again** -- re-show the diff

If they want to edit, loop until they approve.

If mode is `auto`, skip confirmation. Still show the final message before the caller creates the commit.

Return the approved message to the caller. Do not run `jj commit` or `git commit` from this skill.

## If invoked directly

If you were invoked as `commit-message` and not already inside `jj-commit` or `jj-pr`:

- If `.jj/` exists, load the `jj-commit` skill to land the commit. Never `git commit` in a colocated jj repo.
- Otherwise create the commit with git, using a file so quoting survives:

```bash
git commit -F /tmp/commit-msg.txt
```

For a scoped git commit, pass the paths as well.
