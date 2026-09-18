---
name: ham2k-issue
description: Draft, file, and track Ham2K issues in Cabo. Use for reporting HaLo bugs or suggestions, attaching patches, and requests such as "What's the status of our issues?" or "Have our extension blockers been addressed?"
---

# Ham2K issues

Use https://cabo.ham2k.com/halo and the user's authenticated local browser,
normally signed in as Robert Jackson. Use the agent-browser skill for browser
interaction; an available authenticated browser tool is also suitable. Inspect
the current UI rather than relying on saved element IDs or guessed APIs.

For HaLo contributions, use a Cabo issue and an optional patch: no forks,
pushes, or pull requests. Keep implementation on a separate local jj bookmark.
Reporting or checking an issue does not require implementing a fix.

## Write for the person reading it

Lead with what the operator sees, what they expected, and why the difference
matters. A concrete example and a few natural paragraphs usually suffice.
Write like a helpful fellow operator, without inflated severity, stock
bug-report language, or unnecessary jargon.

Keep the problem statement grounded in observations. Put investigation in a
separate paragraph, labeled **Investigation** when useful. Distinguish what
code or tests establish from what we suspect. A plausible cause is not a
confirmed diagnosis; a proposed patch is not a shipped fix. Include only
details that help reproduce, understand, or fix the problem. State validation
limits honestly, including when only a test subset ran.

## File an issue

- Prepare the exact title, description, and any patch for the user's wording
  review. Wait for approval before posting. Prior approval in the conversation
  counts; do not ask again. Apply the same review to substantive follow-up
  comments, unless the user has already approved their content.
- In the HaLo board, **+ New card** creates the title/kind. Open the card to
  add its description. Choose the appropriate kind; leave priority and assignee
  alone unless requested. If submission is uncertain, check for the card
  before retrying to avoid duplicates.
- Attach only the relevant patch. **Attach a file** uploads it into the
  comment composer; submit **Comment** too and verify the posted attachment.
- Return the issue URL and add it to the register below. If a local fix exists,
  include the issue ID and full URL in its commit description, preserving
  useful text.

## Remember what we are following

Keep a JSON register at `$XDG_STATE_HOME/ham2k-issue/issues.json`, falling back
to `~/.local/state/ham2k-issue/issues.json`. This is persistent private state,
separate from the public dotfiles skill and any one project's checkout.
Create it only if absent; preserve existing entries and unrelated fields.
Use this shape, with one entry per canonical issue URL:

```json
{
  "issues": [{
    "id": "HALO-721",
    "url": "https://cabo.ham2k.com/halo/c/721",
    "title": "Contest score total is hidden when a band breakdown is present",
    "whyItMatters": "Operators need to see their running contest score.",
    "neededFor": ["HaLo contest scoring display"],
    "lastCheckedAt": null,
    "trackerStatus": null,
    "resolution": "Patch submitted; upstream outcome not checked.",
    "evidence": [],
    "localFix": {"bookmark": "fix/scoring-total"}
  }]
}
```

Record issues we file or the user explicitly asks to follow. Keep the reason
and affected extension or workflow so a later session knows why we care.
Retain resolved entries. Save offered patches under this state directory's
`patches/` folder and record their paths; `/tmp` is not durable storage. Never
store cookies, tokens, or browser profiles in the register or dotfiles.

## Check progress in a new session

For "our issues," load the register and open the relevant saved Cabo URLs.
Check the current column/status, description, and recent comments for fixes,
release/build references, and requests for information. Include previously
resolved issues if the user asks about all tracked issues. If the register is
missing, explain that and offer to rebuild it from the user's Cabo issues;
do not silently treat every project card as ours.

Compare each result with its saved observation, then update `lastCheckedAt`
with the UTC time and retain useful evidence links and concise notes. Report
the issue link, what changed, and what it means for the workflow or extension
we are waiting on. Separate **still open**, **reported fixed**, and **verified
for our use**. A Done column or maintainer comment is evidence of a reported
fix, not proof that the user's installed build includes it. Confirm the
relevant behavior before calling it verified; state any remaining check.

Reading status and updating the local register need no posting approval.
If access fails, preserve the last observation and label it stale; never infer
that an inaccessible issue was resolved. Status checks are on demand unless
the user asks for a recurring check. Do not automatically comment, close
issues, or start implementing follow-up work during a status request.
