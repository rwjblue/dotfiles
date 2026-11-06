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

For a fix or behavior change, the "why" names the concrete problem a user or
caller hit: what they did and what went wrong. When the change in behavior
isn't obvious from that, add a short before/after (a command and its output,
or a request and its response). A reviewer who reads only the description
should understand what was broken.

**Non-stacked PR:** a single line:

`**BLUF:** <one sentence, ≤ 15 words, "what does THIS PR do?">`

**Stacked PR:** two parallel BLUF lines. Stack-level first, then this PR:

```markdown
**BLUF (stack):** <one sentence on the whole stack's goal>

**BLUF (this PR):** <one sentence, ≤ 15 words, this PR's specific goal>
```

The labels tell the reader *which* BLUF they are looking at. The *what* lives
in the sentence. Tracking ids (e.g. `ABC-123`) go in the `## Stack` section
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

Details states conclusions, not the investigation. Say what the reviewer
should believe and what follows from it. Leave out how you got there (the
repos, branches, manifests, and queries you searched, and what you couldn't
check); that trail belongs in your report to the user. If the scope of a
search matters to the reviewer, one clause covers it ("nothing in the server
or the warehouse models reads it"). A reviewer approves on consequences, and
a search log buries them.

Keep it to a few short items, each one or two sentences that lead with the
consequence. If Details runs longer than the BLUF and its "why", cut it: a
heavy Details makes the whole PR look like a wall of text, and readers skip
the BLUF along with it.

## Linkify everything linkable

Any ticket, PR, doc, or runbook that has a URL should be a Markdown link, not
bare text.

- Tickets → the tracker's issue URL. Employer-specific tracker URL patterns
  live in `../rwjblue-mode-local/SKILL.md` when it exists; this public skill
  does not list them.
- Sibling PRs → `#NNN` (auto-links in-repo)
- Internal shortlinks (e.g. `go/` links) stay as written

Bare `ABC-123` text is a miss. Ticket links live in a Context line or the
`## Stack` section, keeping the BLUF lines clean.

## Metrics, tests, color

- **Compact metric table** if the PR has a measurable outcome (perf, size,
  quality). One row per case, one aggregate row at the bottom.
- **Test/verification note** only when there is something non-obvious to share
  (a manual repro, a deliberate decision not to test something).
  "Unit tests pass" is not worth saying. Don't add "verification
  limitations" or "not yet validated" sections; caveats about what the agent
  could not check go in the agent's report to the user, not the PR body.
- Include maintainer/reviewer color (tradeoffs, rollout, edge cases, risks,
  or context from prior discussion) only when it changes how someone reviews,
  rolls out, or later uses the change. Pick the one or two items that do;
  this is not a checklist to fill. Follow-ups get one line, or none.

## Length discipline

Default to under 2 KB of prose you wrote; a repo template's boilerplate
doesn't count against it. GitHub's hard cap on the PR body is ~256 KB; you
should be nowhere near it. Anti-patterns:

- File/test enumeration ("modified X.go, added 5 tests, BUILD.bazel updated")
  — the diff already shows this.
- Research logs: per-repo or per-system lists of everywhere you looked, how
  you searched, and what you didn't check. State the conclusion instead.
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

Keep merged PRs in the list, in their original slot. Never drop an entry
because it merged: the list is the stack's history, and GitHub already marks
merged `#NNN` links. When a PR joins the stack, add it to every sibling's
list.

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
