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

## Signing Policy (Mandatory)

- Commit signing is required for pushable changes in this environment.
- Never bypass signing by overriding config at command time (for example `--config git.sign-on-push=false` or similar).
- Never modify repo/user config to disable push signing.
- If signing fails (for example 1Password/SSH agent issues), stop and ask the user to fix or approve the next step; do not push unsigned as a workaround.

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
jj up                 # (alias) Rebase @ onto trunk(), dropping commits that become empty
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
jj git fetch          # Fetch from all remotes (configured: glob:*, handles fork workflows)
jj git push           # Push current bookmark (must remain signed)
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
jj up                 # Rebase onto trunk(), dropping commits that become empty
jj tug                # Move bookmark to nearest pushable commit
jj branch-diff        # Diff for entire branch (trunk..@)
jj branch-diff-files  # List files changed in branch
jj stack-diff         # Diff for full stack (includes sibling branches)
jj stack-diff-files   # List files changed in stack
```

### Pre-commit Integration
```bash
jj pre-commit-last    # Run pre-commit on files in @
jj pre-commit-branch  # Run pre-commit on branch files
jj pre-commit-stack   # Run pre-commit on stack files
```

### Private Commit Operations
```bash
jj rebase-private     # Rebase private commits onto @, dropping empties
```

## Custom Revset Aliases

```bash
branch()              # Linear path from trunk() to @ (trunk()..@)
stack()               # All commits diverging from trunk, including sibling branches (roots(trunk()..@)::)
open()                # All user's commits not yet landed on immutable heads
private()             # Commits with "private:" description prefix

# Ancestry/context helpers
slice()               # Ancestors of reachable mutable commits from @, depth 2
slice(from)           # Same but from a specific revision
stack_context()       # Ancestry back to trunk divergence point, depth 2
stack_context(from)   # Same but from a specific revision

# Bookmark/push helpers
closest_bookmark(to)  # Nearest bookmark ancestor of a revision
closest_pushable(to)  # Nearest ancestor with a description that is non-empty or a merge

# History
last()                # Last 20 ancestors of @ (like git log)
last(n)               # Last n ancestors of @
ropen()               # Open remote branches (remote bookmarks minus immutable, depth 2)
```

## Private Commits

Prefix with `private:` to prevent pushing:
```bash
jj commit -m "private: WIP debugging"
jj rebase-private     # Later, rebase private commits onto @
```

## Configuration Notes

- **Colocated repos**: `git.colocate = true` -- all repos are colocated, git commands work alongside jj
- **Signing**: `behavior = "drop"` locally (commits may be unsigned), but `sign-on-push = true` signs commits when pushed via 1Password SSH agent. Do not disable this for pushes.
- **Auto push bookmark**: Creates `rwjblue/push-<change_id>` on push when no bookmark exists
- **Fetch from all remotes**: `git.fetch = ["glob:*"]` -- handles fork workflows where `origin` and `upstream` both exist
- **Delta pager**: Used only for `jj diff` (scoped config), not for other commands to avoid terminal clearing
- **Scoped config**: Different email/signing key for work repos vs personal repos
