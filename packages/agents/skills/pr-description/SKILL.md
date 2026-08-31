---
name: pr-description
description: >-
  Draft a GitHub pull request title and body: BLUF, dual BLUF for stacked PRs,
  optional Details, stack section, linkify tickets, length discipline, and
  --body-file for gh. Use when creating or editing a PR description, stacked or
  not. VCS-agnostic; does not push or open the PR. Callers such as jj-pr load
  this skill for the prose, then run gh themselves.
argument-hint: "[optional: PR title or description hint]"
---

# PR description

Draft a GitHub pull request title and body. This skill does **not** push,
create, or edit the PR. The caller (`jj-pr`, or `gh` directly) submits it.

**User hint:** $ARGUMENTS

## Load this from another skill

Skills cannot import each other. A caller should:

1. Invoke `pr-description` by name if the agent supports it (Cursor / Claude Code: `/pr-description`; Pi: `/skill:pr-description`; Codex: the skill name).
2. Otherwise read the sibling file `../pr-description/SKILL.md` relative to the calling skill.
3. If that path is missing, read `~/.agents/skills/pr-description/SKILL.md`.

Then follow this file in full. Do not improvise the title or body.

## What the caller must provide

The caller gathers repo state and passes it in. At minimum:

- Target repo (`owner/name`), draft vs ready, base branch, head ref
- Whether this is stacked, and if so the ordered stack (trunk first, then PRs)
- Commit messages and a diff stat for **this** PR's range
- Any PR template path/contents
- User hint (`$ARGUMENTS`)

If those are missing, ask the caller/user rather than guessing.

## Title

Use the primary commit message or the user's hint. Keep under 70 characters.

## Body: wrapping and citations

Do NOT hard-wrap prose in the PR body at any specific line length. PR
descriptions are rendered as markdown on GitHub, which reflows text
automatically. Write full paragraphs as single unwrapped lines. (This is
different from commit messages, which should be wrapped at 72 characters.)

When citing prior PR-reviewed changes, prefer **PR numbers (`#NNNN`) or full
PR URLs** because GitHub auto-links these. Use raw commit SHAs only when the
exact commit identity matters, such as cherry-picks, reverts, bisect notes,
comparison anchors, or upstream commits without a PR.

If a PR template exists, fill it out. Otherwise write a description that
prioritizes reviewer context, using the sections below.

## BLUF

Open with the bottom-line-up-front headline, a blank line, then 1–3 supporting
sentences for the "why" (motivation, gating, scope). Do NOT mush headline and
context into one paragraph. The reviewer should grasp the change from the
headline alone.

**Non-stacked PR:** a single line:

`**BLUF:** <one sentence, ≤ 15 words, "what does THIS PR do?">`

**Stacked PR:** two parallel BLUF lines. Stack-level first, then this PR:

```markdown
**BLUF (stack):** <one sentence on the whole stack's goal>

**BLUF (this PR):** <one sentence, ≤ 15 words, this PR's specific goal>
```

The labels tell the reader *which* BLUF they are looking at. The *what* lives
in the sentence. Tracking ids (e.g. `PACT-292`) go in the `## Stack` section
or a Context line, not the label.

Write the `**BLUF (stack):**` line ONCE and reuse it **verbatim** in every PR
of the stack. Only `**BLUF (this PR):**` changes. The stack line is shared
zoom-out context, not a dependency crutch: the `**BLUF (this PR):**` line plus
the "why" must still read cold.

## Standalone reviewability

The PR description must read cold. Assume the reviewer has not opened the rest
of the stack. Never refer to other PRs in the stack by position ("PR 4", "the
next PR"). If a sibling PR's behavior is load-bearing for understanding this
one, describe it inline; otherwise drop the reference. Words like "earlier"
and "later" are fine as glue ("a later commit clears the matching metadata")
but only when the description still reads without them.

## Optional `### Details`

When there is non-obvious what/why beyond the BLUF (a gotcha, a deliberate
decision, behavior the diff and any code/proto doc-comments don't make
obvious), put it under a `### Details` heading so it is clearly separated from
the BLUF line(s) above.

**Omit the section entirely** when the `**BLUF (this PR)**` line plus the diff
already say everything. A one-line proto field whose own doc-comment is
self-explanatory needs no Details. Never restate file changes; the diff shows
them.

## Linkify everything linkable

Any ticket, PR, doc, or runbook that has a URL should be a Markdown link, not
bare text.

- Linear/PACT issues → `https://linear.app/gleanwork/issue/PACT-NNN`
- Jira escalations (`EE-`, `EN-`, etc.) → `https://askscio.atlassian.net/browse/<KEY>`
- Sibling PRs → `#NNN` (auto-links in-repo)
- `go/` shortlinks stay as written

Bare `EE-29350` / `PACT-292` text is a miss. Ticket links live in the
Context/Jira line or the `## Stack` section, keeping the BLUF lines clean.

## Metrics, tests, color

- **Compact metric table** if the PR has a measurable outcome (perf, size,
  quality). One row per case, one aggregate row at the bottom.
- **Test/verification note** only when there is something non-obvious to share
  (manual repro, known gaps, a deliberate decision not to test something).
  "Unit tests pass" is not worth saying.
- Include useful maintainer/reviewer color (tradeoffs, follow-up, rollout,
  edge cases, risks, or context from prior discussion).

## Length discipline

Default to under 2 KB. GitHub's hard cap on the PR body is ~256 KB; you should
be nowhere near it. Anti-patterns:

- File/test enumeration ("modified X.go, added 5 tests, BUILD.bazel updated")
  — the diff already shows this.
- Pre/post-condition lists summarizing what changed mechanically.
- "What to spot-check" filler — reviewers know how to read a diff.
- Pasting more than ~50 KB of raw evidence inline (logs, captures, eval
  outputs) — link to a gist or a local path instead.

The "Churchillian PR" — the one that defends itself against being read by
sheer length — is the failure mode. Punchy and skimmable wins.

## Stack section

If stacked (true stacked mode **or** upstream fallback mode), include a
**Stack** section immediately below the main author-written description,
before generated template metadata, checklists, release notes, or tracking
sections. In templates that separate reviewer prose from metadata with `---`,
place `## Stack` before that separator.

Use a single numbered list with the trunk branch (`master`/`main`/etc.) as
item **#1** in bold, then PRs in dependency order, each as `#NNN — <short
label>`, with a 👉 prefix on the current PR:

```markdown
## Stack

1. **master**
2. #AAAA — add client_id proto field
3. 👉 #BBBB — populate client_id from JWT claim
```

Reading top→bottom: PR at slot 2 builds on `master`, slot 3 builds on slot 2,
etc. Including the trunk as a numbered base resolves "is this stack growing up
or down?" Each entry is `#NNN — <≤6-word label>`: the `#NNN` auto-links, and
the short label is skimmable (preferred over bare-URL cards). The label is a
terse description of that PR's change, not its full title. The 👉 prefix marks
the current PR — more scannable than a "(this PR)" suffix and survives PR
renames.

When updating sibling PRs, reuse `**BLUF (stack):**` verbatim. Only
`**BLUF (this PR):**` and the 👉 position differ per PR.

### Upstream fallback (body copy)

When the stacked base branch is missing from the target repo (common fork
flow) and the caller is opening this PR against trunk, include explicit stack
context in the body:

- Which prior PR this depends on (URL)
- That this PR temporarily includes commits from earlier PR(s)
- That after earlier PR(s) merge, the branch will be rebased and merged
  commits removed, leaving only incremental changes

## Present and return

Present the draft title and body to the user for approval. Loop on edits until
they approve.

Return the approved title and body to the caller. Do not run `gh pr create`
or `gh pr edit` from this skill.

## Submitting (for the caller)

When the caller (or a direct invocation after approval) sends the body to
GitHub, always use `--body-file` so markdown, backticks, and shell-special
characters survive:

```bash
cat > /tmp/pr-body.md <<'EOF'
<body content>
EOF

gh pr create --repo "<target-repo>" --title "<title>" --body-file /tmp/pr-body.md
# or: gh pr edit <pr-number> --repo "<target-repo>" --title "<title>" --body-file /tmp/pr-body.md
```

Never pass the body as a shell-interpolated `--body` string.

## If invoked directly

If you were invoked as `pr-description` and not already inside `jj-pr`, draft
as above, then let the user (or `jj-pr`) submit. If they want you to submit
and `.jj/` exists, load `jj-pr` rather than inventing git bookmark/push steps.
