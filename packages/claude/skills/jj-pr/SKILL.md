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
- `jj diff` - check if `@` has uncommitted changes
- Bookmark status - run all three of these commands:
  ```bash
  echo "=== @- (parent commit) ===" && jj log --no-pager -r "@-" -T 'change_id.short() ++ " " ++ bookmarks ++ "\n"'
  echo "=== closest_bookmark(@) ===" && jj log --no-pager -r "closest_bookmark(@)" -T 'change_id.short() ++ " " ++ bookmarks ++ "\n"'
  echo "=== trunk() ===" && jj log --no-pager -r "trunk()" -T 'change_id.short() ++ " " ++ bookmarks ++ "\n"'
  ```

Determine the mode:

**UPDATE mode**: Closest bookmark is NOT trunk() (there's an existing feature branch)
**CREATE mode**: Closest bookmark IS trunk() (new branch needed)

---

## UPDATE Mode (existing feature branch)

### U1. Check for Existing PR

Get the bookmark name from `closest_bookmark(@)` using `jj log --no-pager -r "closest_bookmark(@)" -T 'bookmarks'`.

Run `gh pr view <bookmark-name> --json url,state,title 2>/dev/null` to see if a PR exists.

### U2. Detect Stacked PR vs Update

Compare `closest_bookmark(@)` with `@-`. If the bookmark is already on `@-`, skip to U3.

If the bookmark is **behind** `@-` (new commits exist beyond the bookmark), ask the user:
- **Update existing PR** (Recommended) - move the bookmark forward to include new commits
- **Create stacked PR** - keep the bookmark where it is and create a new PR targeting it

If **Update existing PR**: continue to U3.
If **Create stacked PR**: jump to CREATE mode (C1), passing the existing bookmark name as the stacked base branch.

### U3. Handle Changes

**If `@` has changes:**
Ask the user to choose:
- **Squash into last commit** (Recommended) - amend the previous commit
- **Create new commit** - add as a separate commit

If squash: run `jj squash`
If new commit: invoke `/jj-commit`, then run `jj tug` to move the bookmark forward

**If `@` is empty:**
The changes are already committed. Proceed to push.

### U4. Push Updates

Run `jj git push --tracked` to push the bookmark.

### U5. Optionally Update PR Title/Body

If the PR exists, ask the user if they want to update the PR title or description.

If yes, use `gh pr edit <bookmark-name> --title "<new title>" --body "<new body>"` to update it.

### U6. Report Result

If PR exists: Show the PR URL and confirm updates were pushed.
If no PR exists: Proceed to CREATE mode step C4 to create the PR.

---

## CREATE Mode (new branch from trunk or stacked base)

### C1. Handle Uncommitted Changes

If `@` has changes, invoke `/jj-commit` first.

### C2. Create Bookmark

Run `jj log --no-pager -r "@-" -T 'description.first_line()'` to get the commit message at `@-`.

Generate a branch name:
- Prefix with `rwjblue/`
- Use 2-4 words from the commit message
- Use kebab-case (lowercase with hyphens)
- Example: `chore(nvim): add plugin support` -> `rwjblue/add-plugin-support`

Present the proposed branch name to the user for confirmation.

Once confirmed, run `jj git push --named "<bookmark-name>=@-"`.

### C3. Handle Stacked Branches (optional)

If closest bookmark exists but isn't on `@-`, ask the user to choose:
- **Use `jj tug`** (Recommended) - move bookmark forward
- **Create new bookmark** - for a new branch

If tug: run `jj tug && jj git push --tracked`

### C4. Create Pull Request

First, check for a PR template:
```bash
cat .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null || cat .github/pull_request_template.md 2>/dev/null || echo "No template found"
```

Gather information for the PR:
- If stacked: use `jj log --no-pager -r "<stacked-base-bookmark>..@-" -T 'description ++ "\n---\n"'` and `jj diff --stat -r "<stacked-base-bookmark>..@-"`
- Otherwise: use `jj log --no-pager -r "trunk()..@-" -T 'description ++ "\n---\n"'` and `jj diff --stat -r "trunk()..@-"`

Draft the PR:
- **Title**: Use the primary commit message or user's hint, keep under 70 chars
- **Body**: If template exists, fill it out. Otherwise use:
  ```markdown
  ## Summary
  [1-3 bullet points describing the changes]

  ## Test plan
  [How to verify the changes work]
  ```

Present the draft to the user for approval.

Create the PR:
```bash
# If stacked, add --base "<stacked-base-bookmark>" to target the parent PR's branch
gh pr create --draft --head "<bookmark-name>" --title "<title>" --body "$(cat <<'EOF'
<body content>
EOF
)"
```

### C5. Report Success

Show the PR URL and confirm the pull request was created.
