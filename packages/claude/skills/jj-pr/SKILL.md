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
- If the commit message has a category prefix, include it as a kebab-case prefix in the branch name:
  - `[Category Name] ...` format: extract the bracketed text
  - `type(scope): ...` format: extract the scope
- Follow with 2-4 descriptive words from the rest of the message
- Use kebab-case (lowercase with hyphens)
- Examples:
  - `[MCP Server] Enable JSON response` -> `rwjblue/mcp-server-enable-json-response`
  - `feat(skills): Add stacked PR support` -> `rwjblue/skills-add-stacked-pr-support`
  - `Add dark mode toggle` -> `rwjblue/add-dark-mode-toggle`

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

If this is a stacked PR, gather the full stack for the PR body:
- Run `jj log --no-pager -r "bookmarks() & trunk()..@-" --reversed -T 'bookmarks ++ "\n"'` to find all bookmarks in the stack (bottom-up order, base first)
- For each bookmark, run `gh pr view <bookmark> --json url,title 2>/dev/null` to get its PR info
- Include the current PR (being created now) as the last entry

Draft the PR:
- **Title**: Use the primary commit message or user's hint, keep under 70 chars
- **Body**: If template exists, fill it out. Otherwise use:
  ```markdown
  ## Summary
  [1-3 bullet points describing the changes]

  ## Test plan
  [How to verify the changes work]
  ```
  If stacked, include a **Stack** section at the end of the author-written description, before any template boilerplate (checklists, release notes, metadata sections). Use bottom-up order where the base PR is #1:
  ```markdown
  ## Stack
  1. https://github.com/askscio/scio/pull/NNNNN
  2. **Current PR title** (this PR)
  ```
  Use bare GitHub PR URLs for other PRs in the stack (GitHub renders these as rich links with title and status). Bold the current PR's own entry with its title and mark it with "(this PR)".

Present the draft to the user for approval.

Create the PR:
```bash
# If stacked, add --base "<stacked-base-bookmark>" to target the parent PR's branch
gh pr create --draft --head "<bookmark-name>" --title "<title>" --body "$(cat <<'EOF'
<body content>
EOF
)"
```

### C5. Update Stack in Other PRs (stacked PRs only)

After creating the PR, update all other open PRs in the stack so they have the complete stack list:
- For each other PR in the stack, read its current body via `gh pr view <bookmark> --json body`
- Replace or insert the `## Stack` section at the end of the author-written description, before any template boilerplate
- Use bare GitHub PR URLs for other entries; bold the PR's own entry with its title and "(this PR)"
- Update via `gh pr edit <bookmark> --body "..."`

### C6. Report Success

Show the PR URL and confirm the pull request was created.
