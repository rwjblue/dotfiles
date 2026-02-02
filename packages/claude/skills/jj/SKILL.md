---
name: jj
description: Jujutsu VCS workflows and custom aliases. Use when working with jj commands, commits, revsets, or version control operations.
user-invocable: false
---

# Jujutsu (jj) Version Control

Uses **Jujutsu (jj)** for version control with git backend. Key differences from git:
- No staging area - changes are automatically tracked
- Commits are mutable by default
- Working copy is always a commit (`@`)
- Branches are optional "bookmarks"

## Core Concepts

- `@` - The working copy commit (always exists)
- `@-` - Parent of working copy (very commonly used)
- `trunk()` - The main branch (usually `main` or `master`)
- `immutable()` - Commits that shouldn't be modified
- Revisions use short change IDs (e.g., `xy`, `zk`, `trunk()`)

## Most Used Commands

### Status & Viewing (daily drivers)
```bash
jj st                 # Status (alias for jj status)
jj diff               # Show changes in working copy
jj log                # Show commit history
jj show               # Show current commit details
jj show -r @-         # Show parent commit details
```

### Creating & Modifying Commits
```bash
jj new                # Create new empty commit on @
jj new <rev>          # Create new commit on specific revision
jj commit -m "msg"    # Describe @ and create new empty commit
jj commit <paths>     # Commit only specific files (partial commit)
jj describe           # Edit description of @
jj describe -r <rev>  # Edit description of specific revision
jj edit <rev>         # Make revision the working copy (to modify it)
```

### Squashing & Combining
```bash
jj sq                 # Squash @ into parent (alias for squash)
jj sq -r @-           # Squash parent into its parent
jj sq -r @- --use-destination-message  # Squash, keep destination's message
jj squash -r <rev> --into <target>     # Squash rev into specific target
jj squash <paths>     # Squash only specific files into parent
```

### Reordering & Rebasing
```bash
jj rebase -r <rev> -d trunk()           # Move single commit onto trunk
jj rebase -s <rev> -d trunk()           # Move commit and descendants onto trunk
jj rebase -r <rev> --insert-after <x>   # Insert commit after x
jj rebase -r <rev> --insert-before <x>  # Insert commit before x
jj up                 # (alias) Rebase @ onto trunk()
```

### Restoring & Undoing
```bash
jj restore            # Restore @ to match parent (discard changes)
jj restore <paths>    # Restore specific files only
jj restore --from <rev>        # Restore @ from specific revision
jj restore --from <rev> <paths>  # Restore specific files from revision
jj abandon <rev>      # Delete a commit entirely
jj undo               # Undo the last jj operation
jj op log             # View operation history (for undo)
```

### Git Integration
```bash
jj git fetch          # Fetch from all remotes (configured: glob:*)
jj git push           # Push current bookmark
jj git push --named <branch>=<rev>  # Create bookmark and push (e.g., --named my-feature=@)
jj git push -b <name> # Push specific bookmark
jj git init --colocate  # Initialize jj in existing git repo
```

### Bookmark Management
```bash
jj bookmark track <name>@origin   # Track remote bookmark locally
jj bookmark list      # List all bookmarks
jj tug                # (alias) Move nearest bookmark to current pushable commit
```

### File Tracking
```bash
jj file untrack <paths>  # Stop tracking files (like .gitignore but immediate)
jj file list             # List tracked files
```

## Custom Aliases (from config)

### Viewing History
```bash
jj open               # Show all my unmerged commits
jj ropen              # Show open remote branches
jj recent             # Show last 20 commits
```

### Branch Operations
```bash
jj up                 # Rebase onto trunk()
jj tug                # Move bookmark to nearest pushable commit
jj branch-diff        # Diff for entire branch (trunk..@)
jj branch-diff-files  # List files changed in branch
```

### Pre-commit Integration
```bash
jj pre-commit-last    # Run pre-commit on files in @
jj pre-commit-branch  # Run pre-commit on branch files
jj pre-commit-stack   # Run pre-commit on stack files
```

## Custom Revset Aliases

```bash
branch()              # Linear path from trunk() to @
stack()               # All commits diverging from trunk (includes siblings)
open()                # All user's commits not yet landed
private()             # Commits with "private:" prefix
```

## Private Commits

Prefix with `private:` to prevent pushing:
```bash
jj commit -m "private: WIP debugging"
jj rebase-private     # Later, rebase private commits onto @
```

## Configuration Notes

- **Colocated repos**: `git.colocate = true` - works with git commands too
- **SSH signing**: Uses 1Password for commit signing
- **Auto push bookmark**: Creates `rwjblue/push-<change_id>` on push
- **Delta pager**: Used only for `jj diff`
- **Scoped config**: Different email/key for work vs personal repos
