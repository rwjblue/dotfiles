---
name: severity-scale
description: >-
  The 1/5–5/5 severity prefixes that say how much a finding matters and whether
  it blocks. Use when writing review comments, feedback on someone else's work
  in any medium, or concerns and risks reported to the user. Callers such as
  pr-review and rwjblue-mode load this for the scale and calibration.
---

# Severity scale

A finding with no stated severity reads as either "everything matters" or
"nothing does", so the reader has to guess how hard to push back. The prefix
answers that before they read the rest.

## Load this from another skill

Skills cannot import each other. A caller should:

1. Invoke `severity-scale` by name if the agent supports it (Cursor / Claude Code: `/severity-scale`; Pi: `/skill:severity-scale`; Codex: the skill name).
2. Otherwise read the sibling file `../severity-scale/SKILL.md` relative to the calling skill.
3. If that path is missing, read `~/.agents/skills/severity-scale/SKILL.md`.

Then follow this file in full.

## The scale

Start each finding with one of these exact prefixes:

- `1/5 (nit, non-blocking)`
- `2/5 (minor preference, non-blocking)`
- `3/5 (strong opinion: non-blocking)`
- `4/5 (serious issue: blocking)`
- `5/5 (fundamental issue: blocking)`

Always keep the label with the number. A bare "2/5" means nothing to a reader
who hasn't seen the convention; the label makes it self-explanatory.

Follow the prefix with a colon, the issue and its consequence, and a concrete
change, test, or decision. One finding per prefix.

## Calibrate honestly

- `4/5` and `5/5` need a concrete failure, a broken contract, or a promise the
  code contradicts. A preference is never blocking, however strongly held;
  that is what `3/5` is for.
- Don't inflate a score to get attention or deflate one to seem agreeable. The
  scale is only useful while the reader can trust it.
- Don't pad with low-value nits or invent a finding to have one. Silence is a
  valid result.

## Where it applies

- **Feedback on someone else's work**, in any medium: PR reviews, design doc
  and RFC comments, plan reviews, Slack replies that push back on a proposal.
  In a casual Slack thread, a lighter "non-blocking nit:" or "blocking:" is
  fine; the point is the strength signal, not the format.
- **Concerns and risks an agent raises to the user.** Add the evidence state
  after the label, because severity and confidence are separate questions:
  `4/5 (serious issue: blocking), unverified: <issue>. <what would confirm
  it>.` Use `verified` only when a test, reproduction, or CI run showed it, and
  say which.

Skip it for announcements, status updates, answers, explanations, and your own
proposals. None of those ask the reader to weigh a critique, so a prefix there
is noise.
