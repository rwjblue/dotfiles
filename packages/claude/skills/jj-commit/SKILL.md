---
name: jj-commit
description: Create a jujutsu commit with a well-crafted commit message based on the current diff and your commit style.
argument-hint: "[optional: brief description of changes]"
disable-model-invocation: true
---

# JJ Commit

Create a commit for current changes with a commit message matching your style in this repo.

**User hint:** $ARGUMENTS

## Signing Policy (Mandatory)

- Commit signing for pushed changes is required in this environment.
- Never bypass signing via config overrides (for example `--config git.sign-on-push=false`) or by changing config to disable signing.
- If this workflow includes pushing and signing fails, stop and ask the user to resolve signer/agent issues; do not push unsigned as a workaround.

## Process

### 1. Review Current Changes

Run `jj diff` to see what changes are in the working copy (`@`).

If there are no changes (empty diff), inform the user there's nothing to commit.

### 2. Analyze Commit Style

Run `jj log --no-pager -r "mine() & ~empty()" --limit 15 -T 'description.first_line() ++ "\n"'` to see the user's recent commit messages for style reference.

Analyze the commit messages to identify the style used in this repo:
- Do they use conventional commits (`type(scope): description`)?
- Do they use a prefix like `[category]` or `category:`?
- Are they plain descriptive sentences?
- What tense/mood? (imperative "add X" vs past "added X")
- Are they capitalized? Do they end with periods?
- What's the typical length?

Match whatever style you observe in the user's commits.

### 3. Draft Commit Message

Based on:
- The diff content
- The user's hint (if provided via $ARGUMENTS)
- The commit style observed in step 2

Draft a commit message that matches the style used in this repo.

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

The message should look like it belongs with the other commits in the repo.

### 4. Confirm with User

Present the proposed commit message and ask the user to choose:
- **Use this message** -- proceed with the drafted message
- **Edit message** -- ask for their preferred message
- **See diff again** -- re-show the diff

If the user wants to edit, ask for their preferred message. Loop until the user approves.

### 5. Create the Commit

Once approved, run `jj commit -m "<approved message>"`.

This will:
- Describe the current working copy with the message
- Create a new empty commit at `@` for the next piece of work

Confirm success to the user.
