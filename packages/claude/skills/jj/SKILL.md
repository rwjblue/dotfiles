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
- Branches are optional bookmarks

## Core Concepts

- `@` - The working copy commit (always exists)
- `trunk()` - The main branch (usually `main` or `master`)
- `immutable()` - Commits that shouldn't be modified (trunk, pushed commits)
- Bookmarks - jj's equivalent of git branches

## Custom Revset Aliases

```bash
branch()              # Linear path from trunk() to @ (current branch)
stack()               # All commits diverging from trunk (includes siblings)
open()                # All user's commits that haven't landed yet
ropen()               # All open remote bookmarks
last(n)               # Last n ancestors of @ (default 20)
slice(rev)            # View ancestry back to where it diverged
private()             # Commits with "private:" prefix in description
```

## Custom Command Aliases

### Viewing History
```bash
jj open               # Show all my unmerged commits
jj ropen              # Show open remote branches
jj recent             # Show last 20 commits (like git log)
```

### Branch Management
```bash
jj up                 # Rebase current work onto trunk()
jj tug                # Move nearest bookmark forward to nearest pushable commit
jj branch-diff        # Show diff for entire branch (trunk..@)
jj branch-diff-files  # List files changed in branch
```

### Stack Operations
```bash
jj stack-diff         # Show diff for full stack (includes siblings)
jj stack-diff-files   # List files changed in stack
```

### Pre-commit Integration
```bash
jj pre-commit-last    # Run pre-commit on files changed in @
jj pre-commit-branch  # Run pre-commit on files changed in branch
jj pre-commit-stack   # Run pre-commit on files changed in stack
```

### Other
```bash
jj sq                 # Alias for squash
jj ws                 # Alias for workspace
jj rebase-private     # Rebase private commits onto @
```

## Common Workflows

### Starting New Work
```bash
jj new                # Create new empty commit on top of @
# or
jj new trunk()        # Start fresh from trunk
```

### Making Changes
```bash
# Just edit files - changes auto-tracked
jj status             # See what changed
jj diff               # View changes
jj commit -m "msg"    # Describe and finalize
```

### Updating a Branch
```bash
jj up                 # Rebase onto latest trunk()
jj git fetch          # Fetch from all remotes (configured: glob:*)
```

### Pushing Changes
```bash
jj tug                # Move bookmark to current commit
jj git push           # Push to remote (auto-signs commits)
```

### Private Commits
Prefix description with `private:` to mark commits as private (won't be pushed):
```bash
jj commit -m "private: WIP debugging"
jj rebase-private     # Later, rebase private commits onto current work
```

## Configuration Notes

- **Colocated repos**: `git.colocate = true` - jj repos also work with git
- **SSH signing**: Uses 1Password for commit signing
- **Delta pager**: Used only for `jj diff` to avoid terminal clearing issues
- **Auto push bookmark**: Creates `rwjblue/push-<change_id>` on push
- **Fetch all remotes**: `jj git fetch` fetches from all remotes (for fork workflows)

## Scoped Config

Different email/signing key for work repos (gleanwork, askscio, etc.) vs personal repos.
