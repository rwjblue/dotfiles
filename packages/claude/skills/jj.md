# Jujutsu (jj) Version Control

This skill helps with Jujutsu workflows in this repository.

## Overview

This repo uses **Jujutsu (jj)** for version control, not git directly (though jj has git backend).

## Key Differences from Git

- No staging area - changes are automatically tracked
- Commits are mutable by default
- Working copy is always a commit
- Branches are optional bookmarks

## Common Commands

```bash
jj status          # Show working copy status
jj diff            # Show changes in working copy
jj log             # Show commit history
jj new             # Create new empty commit
jj commit -m "msg" # Describe and finalize current commit
jj squash          # Squash into parent
jj edit <rev>      # Edit an existing commit
```

## Commit Conventions

- Keep commits small and focused
- Use imperative mood ("Add feature" not "Added feature")
- Single-file changes: use `scripts/commit_changed_file.sh`

## Configuration

jj config lives in `packages/jj/` and is symlinked to `~/.config/jj/`.
