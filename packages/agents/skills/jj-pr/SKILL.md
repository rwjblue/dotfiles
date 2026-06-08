---
name: jj-pr
description: Create a GitHub pull request from the current jj branch, handling bookmarks, pushing, and PR creation.
argument-hint: "[optional: PR title or description hint]"
---

# JJ Pull Request

Create or update a GitHub pull request from the current jj branch.

**User hint:** $ARGUMENTS

## Signing Policy (Mandatory)

- Commit signing for pushed changes is required in this environment.
- Never bypass signing via config overrides (for example `--config git.sign-on-push=false`) or by changing config to disable signing.
- If pushing fails because signing fails, stop and ask the user to resolve signer/agent issues; do not push unsigned as a workaround.

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
- Determine PR target remote:
  - Run `jj git remote list`
  - If `upstream` is present, target `upstream` for PR operations
  - Otherwise, target `origin`
  - Derive `<target-repo>` (owner/name) from that remote URL and use it in `gh pr ... --repo "<target-repo>"`
  - Derive `<target-owner>` from `<target-repo>`
  - Derive `<origin-owner>` from the `origin` remote URL for head refs (`<origin-owner>:<bookmark-name>`)
  - Treat this as a fork flow when `<target-owner> != <origin-owner>`
  - **Same-repo simplification:** when `<target-owner> == <origin-owner>` (pushing to the upstream repo, not a fork), the `<origin-owner>:` prefix in `--head` is redundant. Plain `--head <bookmark-name>` works and avoids edge cases (e.g., if you mentally substitute your GitHub username instead of deriving from the origin URL, the head ref breaks). The `<origin-owner>:<bookmark-name>` form is only required for fork flow.

Determine the mode:

**UPDATE mode**: Closest bookmark is NOT trunk() (there's an existing feature branch)
**CREATE mode**: Closest bookmark IS trunk() (new branch needed)

---

## UPDATE Mode (existing feature branch)

### U1. Check for Existing PR

Get the bookmark name from `closest_bookmark(@)` using `jj log --no-pager -r "closest_bookmark(@)" -T 'bookmarks'`.

Run `gh pr list --repo "<target-repo>" --head "<origin-owner>:<bookmark-name>" --json url,state,title,number --limit 1` to see if a PR exists.

### U2. Detect Stacked PR vs Update

Compare `closest_bookmark(@)` with `@-`. If the bookmark is already on `@-`, skip to U3.

If the bookmark is **behind** `@-` (new commits exist beyond the bookmark), ask the user:
- **Update existing PR** (Recommended) - move the bookmark forward to include new commits
- **Create stacked PR** - keep the bookmark where it is and create a new PR targeting it

If **Update existing PR**: run `jj tug` to move the existing bookmark forward to the nearest pushable commit, then continue to U3.
If **Create stacked PR**: jump to CREATE mode (C1), passing the existing bookmark name as the stacked base branch.

### U3. Handle Changes

**If `@` has changes:**
Ask the user to choose:
- **Squash into last commit** (Recommended) - amend the previous commit
- **Create new commit** - add as a separate commit

If squash: run `jj squash`
If new commit: invoke `/jj-commit` (which uses `jj commit`, not `jj describe`), then run `jj tug` to move the bookmark forward

**If `@` is empty:**
The changes are already committed. Proceed to push.

### U4. Push Updates

Run `jj git push --tracked` to push the bookmark.

### U5. Optionally Update PR Title/Body

If the PR exists, ask the user if they want to update the PR title or description.

If yes, use `--body-file` when updating the body so markdown, backticks, and shell-special characters are preserved:
```bash
cat > /tmp/pr-body.md <<'EOF'
<new body content>
EOF

gh pr edit <pr-number> --repo "<target-repo>" --title "<new title>" --body-file /tmp/pr-body.md
```

### U6. Report Result

If PR exists: Show the PR URL and confirm updates were pushed.
If no PR exists: Proceed to CREATE mode step C3 to create the PR.

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
jj git push --bookmark <bookmark-name>
```

If multiple bookmarks in the stack moved (e.g., a rebase shifted every revision's SHA), push them all together:

```bash
jj git push --tracked
```

Each tracked bookmark whose target SHA changed gets pushed; bookmarks already in sync are skipped.

### A5. Update PR description if scope changed

If the amendment changed *what* the PR does (not just *how*), update the description per U5 — the diff is now different from the body's claims.

---

## CREATE Mode (new branch from trunk or stacked base)

### C1. Handle Uncommitted Changes

If `@` has changes, invoke `/jj-commit` first. This uses `jj commit` (not `jj describe`) so that `@` becomes empty and the committed change lands at `@-`.

### C2. Create Bookmark

Run `jj log --no-pager -r "@-" -T 'description.first_line()'` to get the commit message at `@-`.

If this is a stacked PR, leave the stacked base bookmark where it is. Do not run `jj tug` or otherwise move the base bookmark; create a new bookmark for the follow-up PR at `@-`.

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
- For each bookmark, run `gh pr list --repo "<target-repo>" --head "<origin-owner>:<bookmark>" --json url,title,number --limit 1` to get its PR info
- Include the current PR (being created now) as the last entry

Determine stacked PR creation mode:
- **True stacked mode**: only when `<stacked-base-bookmark>` exists as a branch in `<target-repo>`
  - Check with: `gh api repos/<target-repo>/branches/<stacked-base-bookmark>`
  - If this succeeds, create with `--base "<stacked-base-bookmark>"`
- **Upstream fallback mode**: when stacked base branch is missing from `<target-repo>` (common fork flow)
  - Do **not** create the follow-up PR in your fork unless the user explicitly asks
  - Create the PR in `<target-repo>` against `trunk()` instead
  - Include explicit stack context in the body explaining:
    - Which prior PR this depends on (URL)
    - That this PR temporarily includes commits from earlier PR(s)
    - That after earlier PR(s) merge, the branch will be rebased and merged commits removed, leaving only incremental changes

Draft the PR:
- **Title**: Use the primary commit message or user's hint, keep under 70 chars
- **Body**: Do NOT hard-wrap prose in the PR body at any specific line length. PR descriptions are rendered as markdown on GitHub, which reflows text automatically. Write full paragraphs as single unwrapped lines. (This is different from commit messages, which should be wrapped at 72 characters.)
  When citing prior PR-reviewed changes, prefer **PR numbers (`#NNNN`) or full PR URLs** in the PR body because GitHub auto-links these. Use raw commit SHAs only when the exact commit identity matters, such as cherry-picks, reverts, bisect notes, comparison anchors, or upstream commits without a PR.
  If template exists, fill it out. Otherwise write a description that prioritizes reviewer context:

  - **BLUF up top.** Open with `**BLUF; _Why_** — <one paragraph stating the motivation, constraint, or problem being solved>`. Reviewers should know within two sentences whether this PR matters to them.
  - **One paragraph on the non-obvious "what".** Call out only what isn't already obvious from the diff. Don't restate file changes — the diff shows them.
  - **Compact metric table** if the PR has a measurable outcome (perf, size, quality). One row per case, one aggregate row at the bottom.
  - **Stack section** if stacked (see template below).
  - **Test/verification note** only when there's something non-obvious to share — manual repro steps, known gaps, a deliberate decision not to test something. "Unit tests pass" is not worth saying.
  - Include any useful maintainer/reviewer "color" (tradeoffs considered, follow-up work, rollout notes, edge cases, risks, or context from prior discussion).

  **Length discipline.** Default to under 2 KB. GitHub's hard cap on the PR body is ~256 KB but you should be nowhere near it. Anti-patterns to avoid:
  - File/test enumeration ("modified X.go, added 5 tests, BUILD.bazel updated") — the diff already shows this.
  - Pre/post-condition lists summarizing what changed mechanically.
  - "What to spot-check" filler — reviewers know how to read a diff.
  - Pasting more than ~50 KB of raw evidence inline (logs, captures, eval outputs) — link to a gist or a local path instead.

  The "Churchillian PR" — the one that defends itself against being read by sheer length — is the failure mode. Punchy and skimmable wins.
  If stacked (true stacked mode or upstream fallback mode), include a **Stack** section immediately below the main author-written description, before generated template metadata, checklists, release notes, or tracking sections. In templates that separate reviewer prose from metadata with `---`, place `## Stack` before that separator. Use a single numbered list with the trunk branch (`master`/`main`/etc.) as item **#1** in bold, then PRs in dependency order with a 👉 prefix on the current PR:
  ```markdown
  ## Stack

  1. **master**
  2. https://github.com/askscio/scio/pull/AAAA
  3. https://github.com/askscio/scio/pull/BBBB
  4. 👉 https://github.com/askscio/scio/pull/CCCC
  5. https://github.com/askscio/scio/pull/DDDD
  ```
  Reading top→bottom: PR at slot 2 builds on `master`, slot 3 builds on slot 2, etc. — direction is unambiguous. Including the trunk as a numbered base resolves "is this stack growing up or down?" confusion that comes up otherwise. Bare GitHub PR URLs render as rich auto-linked cards with title and status — no need to repeat the title manually. The 👉 prefix is more scannable than a "(this PR)" suffix and survives PR renames without going stale.

Present the draft to the user for approval.

Create the PR:
```bash
# Prefer --body-file to avoid shell interpolation issues with markdown/backticks
cat > /tmp/pr-body.md <<'EOF'
<body content>
EOF

# True stacked mode:
gh pr create --repo "<target-repo>" --draft --head "<origin-owner>:<bookmark-name>" --base "<stacked-base-bookmark>" --title "<title>" --body-file /tmp/pr-body.md

# Upstream fallback mode:
gh pr create --repo "<target-repo>" --draft --head "<origin-owner>:<bookmark-name>" --base "<trunk-bookmark-or-branch>" --title "<title>" --body-file /tmp/pr-body.md
```

### C4. Update Stack in Other PRs (stacked PRs only)

After creating the PR, update all other open PRs in the stack so they have the complete stack list.

Only do this in **true stacked mode** where the PRs live in the same `<target-repo>`. Skip this step in upstream fallback mode.

- For each other PR in the stack, read its current body via `gh pr view <pr-number> --repo "<target-repo>" --json body`
- Replace or insert the `## Stack` section immediately below the author-written prose, before generated template metadata, checklists, release notes, or tracking sections. If the template uses `---` to separate reviewer prose from metadata, place the stack before that separator, not at the bottom of the body.
- Use bare GitHub PR URLs for other entries; bold the PR's own entry with its title and "(this PR)"
- Update via `gh pr edit <pr-number> --repo "<target-repo>" --body-file /tmp/pr-body.md`

### C5. Report Success

Show the PR URL and confirm the pull request was created.

### C6. Stack composition changes after creation

If you later add, remove, or rename a PR in the stack, update every other PR's Stack section to match. Same flow as C4 — read each body, replace the Stack section, write back via `gh pr edit --body-file`. Stale stack listings on siblings confuse reviewers.
