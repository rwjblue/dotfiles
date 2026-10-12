---
name: pr-review
description: >-
  Review GitHub pull requests and PR stacks with actionable, severity-prefixed
  comments and pending-review safeguards. Use when asked to review PRs, leave
  draft review comments, or revise pending reviews. Not for implementing fixes
  or writing PR descriptions.
---

# PR review

Review the code, not just the PR description. For a stack, work from the root
(first to land) upward. Keep comments concise and leave GitHub reviews pending
unless the user explicitly authorizes submission.

## 1. Establish scope and mode

- Review-only request: report findings in chat; do not write to GitHub.
- Request to leave review comments: create or update **pending** reviews.
- Submission request: require explicit authorization for the target PRs and
  outcome (`APPROVE`, `REQUEST_CHANGES`, or `COMMENT`). Acknowledging findings,
  saying "sounds good," or discussing approval is not submission authorization.
- Do not edit implementation files, commit, push, merge, or deploy as part of a
  review. Those require separate requests.

Resolve each PR's repository, current head SHA, base, state, and existing reviews.
For stacks, confirm dependency order from head/base refs and commit ancestry;
PR numbers and the supplied order are not proof. Ask only if the order or scope
cannot be resolved. Flag prerequisites outside the requested stack without
creating reviews on additional PRs.

Use an available GitHub CLI or structured API before browser automation. Inspect
repository guidance before reviewing code. Preserve the user's checkout; use
read-only snapshots or an isolated checkout when tests need the PR's code.

## 2. Review bottom-up

For each PR, read its incremental diff against its actual base, then inspect the
surrounding callers, helpers, contracts, and tests. Do not repeatedly review the
cumulative stack diff. Check that each layer can land independently, then check
the complete stack's behavior.

Trace important flows end-to-end:

- Public contract → binding/validation → handler → backend → response. Check
  nullability, required fields, error codes, IDs, URLs, and round-trip behavior.
- Authentication, authorization, feature gates, and routing. Check that route
  matching and policy lookup agree, including encoded paths and method handling.
- Failure, timeout, quota, partial-result, batch, and expensive-content behavior.
  Check correlation, resource use, rollout dependencies, and observable failures.

Read existing review comments and identify which are resolved, outdated, or still
open. Avoid reposting an existing finding unless the user requests an independent
copy; mention still-open findings in the summary instead. Assign each new finding
to the earliest PR that introduces it, and comment once rather than on every
layer that inherits it.

Separate demonstrated defects from preferences and verification gaps. Validate
suspected defects against the actual implementation and contract. Do not label a
deliberate trade-off a bug without a concrete failure or contradictory promise.

Run focused tests or a minimal reproduction where practical. Check whether fakes
actually observe the behavior being asserted; a test returning canned content
may pass even when the request drops the content flag. Distinguish full tests,
isolated reproductions, static inspection, and CI evidence. Report checks that
could not run and why; never imply verification that did not happen.

## 3. Write actionable comments

Start every finding with one of these exact prefixes:

- `1/5 (nit, non-blocking)`
- `2/5 (minor preference, non-blocking)`
- `3/5 (strong opinion: non-blocking)`
- `4/5 (serious issue: blocking)`
- `5/5 (fundamental issue: blocking)`

Follow the prefix with a colon, the issue and its consequence, and a concrete
change or test. Keep each comment to one finding, usually 2–4 short sentences.
Use natural language and contractions where they fit. Skip praise sandwiches,
robotic headings, vague questions, and a tutorial on concepts the author knows.
If the resolution genuinely needs a human decision, name that decision rather
than inventing a fix.

Example:

> 4/5 (serious issue: blocking): This returns the display ID, but lookup uses the
> stored ID. A caller can receive an ID that immediately fails on its next read.
> Please return the stored ID and add a read → returned ID → lookup test.

Use blocking severities for concrete issues that need resolution before landing,
not personal preferences. Do not pad the review with low-value nits or invent a
finding for every PR. Keep evidence with the comment, but link lengthy logs or
reproductions instead of pasting them.

## 4. Save pending reviews safely

Only perform this step when the user authorized GitHub draft comments.

1. Confirm the authenticated reviewer and inspect any existing pending review.
   Preserve its comments; do not discard or overwrite it. Reuse it only for
   authorized additions or edits. Ask if an existing draft creates ambiguity.
2. Recheck each PR's head SHA before writing. If it changed, re-review affected
   code and relocate comments rather than attaching stale findings.
3. Anchor comments to the owning PR's diff with the correct path, side, and line.
   Use a review-level finding when no honest inline anchor exists.
4. Use a JSON payload file so quotes, Markdown, and backticks survive unchanged.
   For a new review, include the reviewed `commit_id` and inline `comments`.
   **Omit `event` entirely** from the create-review request; that creates a pending
   review. Do not use `gh pr review`, which submits a review.

   With `repo`, `pr`, and `payload_file` set to the verified target and payload:

   ```bash
   gh api --method POST "repos/$repo/pulls/$pr/reviews" --input "$payload_file"
   ```

5. Record the returned review ID and URL. Verify remotely that `state` is
   `PENDING`, `submitted_at` is null, and the saved comments match the intended
   text and locations. Do not claim success from the write response alone.
6. After a write error, inspect remote state before retrying. Creation and comment
   insertion are not idempotent. Never duplicate a review or comment to force a
   successful tool result.

Create reviews in landing order. Do not create empty reviews for PRs with no new
findings. Do not post standalone public comments as a fallback for pending-review
failures. If draft creation is unavailable, retain the comments in chat and
explain the limitation.

## 5. Report and iterate

Summarize findings in landing order with pending-review links, severity, and the
requested fixes. Identify PRs with no new findings and note relevant existing
blockers without reposting them. State what was verified, what could not run,
and whether anything was submitted. Keep the summary compact.

For revisions, locate the saved review/comment by ID and change only what the
user requested. Keep the review pending unless submission is explicitly
requested. Deleting comments also requires explicit authorization.

If the user suggests blanket approval while any `4/5` or `5/5` findings remain
unresolved, explain the conflict and recommend request-changes for the affected
PRs. Do not silently turn blocking findings into approval. Non-blocking findings
do not by themselves prevent approval; publication still depends on required
fixes in lower layers.
