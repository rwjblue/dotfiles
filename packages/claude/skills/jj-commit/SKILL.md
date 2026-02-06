---
name: jj-commit
description: Create a jujutsu commit with a well-crafted commit message based on the current diff and your commit style.
argument-hint: "[optional: brief description of changes]"
---

# JJ Commit

Create a commit for current changes with a commit message matching your style in this repo.

**User hint:** $ARGUMENTS

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

Draft a concise commit message that matches the style used in this repo. Consider:
- What kind of change is this? (new feature, bug fix, refactor, etc.)
- What area/component does it affect?
- What does it accomplish?

The first line MUST be 72 characters or fewer. If the message needs more detail, use a blank line followed by a body paragraph. Show the character count next to the first line when presenting to the user.

The message should look like it belongs with the other commits in the repo.

### 4. Confirm with User

Present the proposed commit message using AskUserQuestion:
- Show the message you've drafted
- Offer options: "Use this message", "Edit message", "See diff again"
- If user wants to edit, ask for their preferred message
- Loop until the user approves

### 5. Create the Commit

Once approved, run `jj commit -m "<approved message>"`.

This will:
- Describe the current working copy with the message
- Create a new empty commit at `@` for the next piece of work

Confirm success to the user.
