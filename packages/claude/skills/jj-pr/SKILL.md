---
name: jj-pr
description: Create a GitHub pull request from the current jj branch, handling bookmarks, pushing, and PR creation.
argument-hint: "[optional: PR title or description hint]"
---

# JJ Pull Request

Create or update a GitHub pull request from the current jj branch.

**User hint:** $ARGUMENTS

## Process

### 1. Gather Current State

Run these to understand the current situation:
- `scripts/diff.sh` - check if `@` has uncommitted changes
- `scripts/bookmark-status.sh` - see bookmark positions

Determine the mode:

**UPDATE mode**: Closest bookmark is NOT trunk() (there's an existing feature branch)
**CREATE mode**: Closest bookmark IS trunk() (new branch needed)

---

## UPDATE Mode (existing feature branch)

### U1. Check for Existing PR

Get the bookmark name from `@-` using `scripts/parent-bookmarks.sh`.

Run `scripts/check-pr.sh <bookmark-name>` to see if a PR exists.

### U2. Handle Changes

**If `@` has changes:**
Ask the user using AskUserQuestion:
- **Squash into last commit** (Recommended) - amend the previous commit
- **Create new commit** - add as a separate commit

If squash: run `scripts/squash.sh`
If new commit: invoke `/jj-commit`, then run `jj tug` to move the bookmark forward

**If `@` is empty:**
The changes are already committed. Proceed to push.

### U3. Push Updates

Run `scripts/push-tracked.sh` to push the bookmark.

### U4. Report Result

If PR exists: Show the PR URL and confirm updates were pushed.
If no PR exists: Proceed to CREATE mode step C4 to create the PR.

---

## CREATE Mode (new branch from trunk)

### C1. Handle Uncommitted Changes

If `@` has changes, invoke `/jj-commit` first.

### C2. Create Bookmark

Run `scripts/parent-message.sh` to get the commit message at `@-`.

Generate a branch name:
- Prefix with `rwjblue/`
- Use 2-4 words from the commit message
- Use kebab-case (lowercase with hyphens)
- Example: `chore(nvim): add plugin support` -> `rwjblue/add-plugin-support`

Present the proposed branch name to the user for confirmation using AskUserQuestion.

Once confirmed, run `scripts/push-named.sh <bookmark-name>`.

### C3. Handle Stacked Branches (optional)

If closest bookmark exists but isn't on `@-`, ask the user:
- **Use `jj tug`** (Recommended) - move bookmark forward
- **Create new bookmark** - for a new branch

If tug: run `scripts/tug-and-push.sh`

### C4. Create Pull Request

First, check for a PR template:
```bash
cat .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null || cat .github/pull_request_template.md 2>/dev/null || echo "No template found"
```

Gather information for the PR:
- Run `scripts/branch-commits.sh` to get commit messages in the branch
- Run `scripts/branch-stat.sh` to get the diff summary

Draft the PR:
- **Title**: Use the primary commit message or user's hint, keep under 70 chars
- **Body**: If template exists, fill it out. Otherwise use:
  ```markdown
  ## Summary
  [1-3 bullet points describing the changes]

  ## Test plan
  [How to verify the changes work]
  ```

Present the draft to the user for approval using AskUserQuestion.

Create the PR by piping the body to `scripts/create-pr.sh`:
```bash
scripts/create-pr.sh "<bookmark-name>" "<title>" <<'EOF'
<body content>
EOF
```

### C5. Report Success

Show the PR URL and confirm the pull request was created.
