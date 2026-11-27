---
name: jj-pr
description: >-
  Create or update GitHub pull requests for jj branches, including stacked
  PRs, existing PR updates, signed pushes, bookmark handling, and body-file
  based gh commands. Use whenever creating a PR, updating a PR after review
  fixes, pushing PR branch changes, or editing PR descriptions. Loads
  pr-description for title/body prose and jj-commit for new commits.
argument-hint: "[optional: PR title or description hint]"
---

# JJ Pull Request

Create or update a GitHub pull request from the current jj branch.
Combine commit and PR creation through this workflow when the user requests
both. Use the selected jj checkout, an authenticated `gh` CLI for the target
GitHub host, and the signing policy below.

**User hint:** $ARGUMENTS

## Commit signing

Before pushing, follow [Commit signing](../commit-shape/SKILL.md#commit-signing).

## Related skills

Read the related skills using paths relative to this file. If sibling paths
are unavailable, invoke the corresponding skill by name.

**`commit-shape`** for when to squash, amend, or add a commit:

1. Read [commit-shape](../commit-shape/SKILL.md).
2. It reads the `pr-commit-shape` repo setting. The steps below assume the default, `single`: one commit per PR, squashed at creation and amended after. Under `multi`, or one of its exceptions, follow `commit-shape` instead of the squash steps here.

**`commit-message` via `jj-commit`** when you need a new commit:

1. Read [jj-commit](../jj-commit/SKILL.md).
2. `jj-commit` loads `commit-message` for the prose. Use `jj commit`, not `jj describe`.

**`pr-description`** for every title and body (create or edit):

Read [pr-description](../pr-description/SKILL.md).

Follow `pr-description` in full for BLUF, dual BLUF, Details, stack section
format, linkify, length, wrapping, citations, and `--body-file`. This skill
only covers jj bookmarks, push, and `gh` invocation.

## Process

### 1. Gather Current State

Run these to understand the current situation:
- `jj root` to identify the checkout selected for the task. Run the workflow
  from that root so repository settings and PR templates resolve correctly.
- `jj diff` - check if `@` has uncommitted changes
- Inspect the working-copy parent, nearest feature bookmarks, and trunk:
  ```bash
  jj log --no-pager -r '@-' -T 'change_id.short() ++ " " ++ bookmarks ++ "\n"'
  jj log --no-pager -r 'heads((trunk()..@) & bookmarks())' -T 'change_id.short() ++ " " ++ bookmarks ++ "\n"'
  jj log --no-pager -r 'trunk()' -T 'change_id.short() ++ " " ++ bookmarks ++ "\n"'
  ```
- Determine PR target remote:
  - Run `jj git remote list`
  - If `upstream` is present, target `upstream` for PR operations
  - Otherwise, target `origin`
  - Derive `<target-repo>` (owner/name) and `<github-host>` from the target remote URL. Use `gh pr ... --repo "<github-host>/<target-repo>"` and pass `--hostname "<github-host>"` to `gh api`.
  - Confirm the target and origin are on the same GitHub host, and use `origin` as the push remote.
  - Derive `<origin-owner>` from the `origin` remote URL for head refs (`<origin-owner>:<bookmark-name>`)
  - Set `<head-ref>` to the bookmark name when origin and target identify the same repository. For a fork, use `<origin-owner>:<bookmark-name>`.

Determine the mode:

**UPDATE mode** applies when there is a feature bookmark. If multiple bookmarks
remain and the request does not identify one, resolve which bookmark to use.

**CREATE mode** applies when there is no feature bookmark.

---

## UPDATE Mode (existing feature branch)

### U1. Check for Existing PR

Use the selected feature bookmark. Look up its open PR by owner and branch
using the [GitHub pull request API](https://docs.github.com/en/rest/pulls/pulls#list-pull-requests):

```bash
gh api --hostname "<github-host>" --method GET "repos/<target-repo>/pulls" \
  -f state=open -f head="<origin-owner>:<bookmark-name>" \
  --jq 'map({url: .html_url, state, title, number, base: .base.ref})'
```

If the user requested a new PR and this bookmark already has an open PR,
confirm whether they want to update it or create a separate PR before
changing the existing branch. For a separate PR, continue at C1 with the
existing bookmark as the stacked base.

If there is no open PR, continue at C1. Use the selected feature bookmark
as the new PR's head and use trunk as the base unless the user chose another
base.

### U2. Detect Stacked PR vs Update

Compare the feature bookmark with `@-`. If the bookmark is already on `@-`, skip to U3.

If the bookmark is **behind** `@-` (new commits exist beyond the bookmark), ask the user:
- **Update existing PR** (Recommended) - move the bookmark forward to include new commits
- **Create stacked PR** - keep the bookmark where it is and create a new PR targeting it

If **Update existing PR** under the single-commit policy, squash the new
commits into the PR's commit, then continue to U3:

```bash
jj squash --from '<bookmark-name>..@-' --into '<bookmark-name>' --use-destination-message
```

If the PR's message no longer describes the whole change, redraft it with `commit-message` ("Squashing or amending") and apply it with `jj describe -r '<bookmark-name>' --stdin`.

Under the multi-commit policy, keep the commits and move the selected bookmark
to `@-` with `jj bookmark move "<bookmark-name>" --to @-` before continuing.

If **Create stacked PR**: jump to CREATE mode (C1), passing the existing bookmark name as the stacked base branch.

### U3. Handle Changes

**If `@` has changes:**
If the changes belong in the PR's nearest commit under `commit-shape`, run
`jj squash` to fold them into it. If the message no longer describes the
whole change, redraft it as in U2. For a multi-commit PR, fold a fix into the
commit it belongs to and verify the descendant commits after the rewrite.

Create a separate commit only when the user asks for one or `commit-shape`
says to. Load `jj-commit`, then move the selected bookmark forward with
`jj bookmark move "<bookmark-name>" --to @-`.

**If `@` is empty:**
The changes are already committed. Proceed to push.

### U4. Push Updates

Run `jj git push --remote origin --bookmark "<bookmark-name>"` to push the
selected bookmark.

### U5. Optionally Update PR Title/Body

If the PR exists, ask the user if they want to update the PR title or description.

If yes, load `pr-description` with the current PR, then submit with
`--body-file` as that skill specifies. Use a fresh temporary body file for
this operation.

```bash
body_file="$(mktemp)"
cat > "$body_file" <<'EOF'
<new body content>
EOF

gh pr edit <pr-number> --repo "<github-host>/<target-repo>" --title "<new title>" --body-file "$body_file"
```

### U6. Report Result

Show the PR URL and confirm updates were pushed.

---

## AMEND Mode (rewriting an existing PR's commit)

Use when you need to change what's *inside* an existing PR's commit — review fixes that should fold into the existing commit instead of stacking on top, scope expansion within a draft PR, or conflict resolution after a rebase. Distinct from UPDATE mode (which adds a *new* commit on top, moving the bookmark forward) and CREATE mode (which makes a new bookmark from trunk).

### A1. Position the working copy on the target revision

```bash
jj edit <change-id>
```

Use the change ID of the revision whose bookmark matches the PR you want to amend. The working copy is now ON that revision; descendants auto-rebase as you mutate.

### A2. Make changes

Edit files normally. jj snapshots automatically — do NOT run `jj commit` or `jj describe` to land them. Your edits become part of the existing revision.

If descendants conflict during the rebase, resolve them in place; `jj resolve --list` shows what needs attention.

### A3. Verify

Build and test as needed. The commit message and bookmark stay attached to this revision; only the SHA changes.

### A4. Push

```bash
jj git push --remote origin --bookmark <bookmark-name>
```

If multiple bookmarks in the intended stack moved, push them one at a
time, bottom-up. Verify each remote head before pushing the next.

### A5. Update PR description if scope changed

If the amendment changed *what* the PR does (not just *how*), load `pr-description` and submit per U5 — the diff is now different from the body's claims.

---

## CREATE Mode (new branch from trunk or stacked base)

### C1. Handle Uncommitted Changes

If `@` has changes, load `jj-commit` first. This uses `jj commit` (not `jj describe`) so that `@` becomes empty and the committed change lands at `@-`.
Pass through any path scope and commit message approval flags the user set.

### C1b. Squash to one commit

The new PR's range is `trunk()..@-`, or `<stacked-base-bookmark>..@-` for a
stacked PR. Stop before pushing if that range has no changes. If it holds
multiple commits and `commit-shape` calls for one, squash them before
creating or moving the bookmark. Use a message for the combined change from
`commit-message` ("Squashing or amending"):

```bash
jj squash --from '<base>..@-' --into 'roots(<base>..@-)' -m "$(cat /tmp/commit-msg.txt)"
```

In a stack being created all at once, run this per PR, bottom-up, with each PR's own range.

### C2. Create Bookmark

If using an existing feature bookmark as the new PR's head, confirm that
head and ensure it points at `@-`. Move it there if needed, then push it with
`jj git push --remote origin --bookmark "<bookmark-name>"` and continue at C3.

Run `jj log --no-pager -r "@-" -T 'description.first_line()'` to get the commit message at `@-`.

If this is a stacked PR, leave the stacked base bookmark where it is and
create a new bookmark for the follow-up PR at `@-`.

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

Check that the proposed bookmark name is available locally and on the push
remote. Present the proposed branch name to the user for confirmation.

Once confirmed, run `jj git push --remote origin --named "<bookmark-name>=@-"`.

### C3. Create Pull Request

First, check for a PR template:
```bash
cat .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null || cat .github/pull_request_template.md 2>/dev/null || echo "No template found"
```

Gather information for the PR:
- If stacked: use `jj log --no-pager -r "<stacked-base-bookmark>..@-" -T 'description ++ "\n---\n"'` and `jj diff --stat -r "<stacked-base-bookmark>..@-"`
- Otherwise: use `jj log --no-pager -r "trunk()..@-" -T 'description ++ "\n---\n"'` and `jj diff --stat -r "trunk()..@-"`

If this is a stacked PR, gather the full stack for the PR body:
- Run `jj log --no-pager -r "bookmarks() & trunk()..@-" --reversed -T 'bookmarks ++ "\n"'` to find all bookmarks in the stack (bottom-up order, base first)
- For each bookmark, use the API lookup in U1 with that bookmark's name to get its PR info. Include known merged PRs by querying with `state=all` when needed.
- In fork flows, this lookup is still required even when the bookmark branch is missing from `<target-repo>`. GitHub upstream PRs commonly use fork head refs (`<origin-owner>:<bookmark>`) while not exposing the fork branch as a base branch in `<target-repo>`. Do not infer "no upstream PR" from a missing target-repo branch.
- Record any existing PR URL for each stacked base bookmark. Use that URL in the Stack section and fallback explanation.
- Include the current PR (being created now) as the last entry. Before PR creation, use a placeholder such as `👉 <current PR, created below>`.

Determine stacked PR creation mode:
- **True stacked mode**: only when `<stacked-base-bookmark>` exists as a branch in `<target-repo>`
  - Check that exact branch via the repository branches API on `<github-host>`. Confirm a missing branch before falling back. Authentication and transport errors require resolving the lookup.
  - If this succeeds, create with `--base "<stacked-base-bookmark>"`
- **Upstream fallback mode**: when stacked base branch is missing from `<target-repo>` (common fork flow)
  - First use the U1 API lookup with `<stacked-base-bookmark>` to check for
    an upstream PR for that exact head ref.
  - If found, cite that PR URL or number as the dependency. Do not say "no upstream PR found."
  - If not found, say only that no upstream PR was found for `<origin-owner>:<stacked-base-bookmark>` after checking that exact head ref.
  - Do **not** create the follow-up PR in your fork unless the user explicitly asks
  - Create the PR in `<target-repo>` against `trunk()` instead
  - Pass fallback context into `pr-description` (depends-on URL if one exists, temporary extra commits, rebase after merge)

Load `pr-description` with the gathered commits, diff stat, template, stack list, and mode. Present its draft (that skill already asks for approval).

For a regular PR or upstream fallback, set `<base-branch>` to the intended
trunk branch in the target repository. For a true stacked PR, use the
stacked base bookmark. Check for an existing PR for this head before creating
a new one, including after an uncertain create result.

Create the PR with `--body-file` (see `pr-description`). Use a fresh temporary
body file for this operation.

```bash
body_file="$(mktemp)"
cat > "$body_file" <<'EOF'
<body content>
EOF

gh pr create --repo "<github-host>/<target-repo>" --draft \
  --head "<head-ref>" --base "<base-branch>" --title "<title>" \
  --body-file "$body_file"
```

After `gh pr create` succeeds, capture the created PR URL. If this is a
stacked PR, update the body file so its own Stack entry uses the real URL,
then immediately update the newly created PR body:

```bash
gh pr edit <new-pr-number-or-url> --repo "<github-host>/<target-repo>" --body-file "$body_file"
```

The post-create body must include the complete stack with the current PR URL marked by `👉`, for both true stacked mode and upstream fallback mode. This keeps the PR body self-contained and avoids leaving placeholder branch names or "created below" text in the final description.

### C4. Update Stack in Other PRs (stacked PRs only)

After creating the PR, update all other open PRs in the stack so they have the complete stack list.

Only do this in **true stacked mode** where the PRs live in the same `<target-repo>`. Skip this step in upstream fallback mode.

- For each other PR in the stack, read its current body via `gh pr view <pr-number> --repo "<github-host>/<target-repo>" --json body`
- Replace or insert the `## Stack` section per `pr-description` (immediately below the author-written prose, before generated template metadata). If the template uses `---` to separate reviewer prose from metadata, place the stack before that separator, not at the bottom of the body.
- Use the `#NNN — <short label>` form for every entry (trunk as bold #1); mark whichever PR is being viewed with the 👉 prefix. The `**BLUF (stack):**` line stays verbatim across all siblings; only `**BLUF (this PR):**` and the 👉 position differ per PR.
- Update via `gh pr edit <pr-number> --repo "<github-host>/<target-repo>" --body-file "$body_file"`.

### C5. Report Success

Show the PR URL and confirm the pull request was created.

### C6. Stack composition changes after creation

If you later add, remove, or rename a PR in the stack, update every other PR's Stack section to match. Same flow as C4 — read each body, replace the Stack section, write back via `gh pr edit --body-file`. Stale stack listings on siblings confuse reviewers.
