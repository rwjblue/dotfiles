# Cursor user rule: one commit per PR

Paste everything below the line into Cursor → Customize → Rules, as its own
rule next to the cloud-agent fallback. This file is the source of that paste.
Cursor does not read it from git.

Unlike the cloud-agent fallback, this rule applies to local agents and Cloud
Agents alike. It is a rule rather than only a skill because it has to
override built-in agent instructions that discourage amending pushed
commits, and because synced skills don't load in every Cloud Agent launch
(automations skip them). The full policy lives in the `commit-shape` skill.

---

One commit per PR. While work is local, commit as often as helps. When you
open a PR, squash its commits into one, with a message that describes the
whole change. After that, every change to the PR (review fixes, CI fixes,
rebases, scope growth) amends that one commit and is force-pushed with a
lease on the remote SHA you recorded before changing it:
`git push --force-with-lease=refs/heads/<branch>:<sha> origin HEAD:refs/heads/<branch>`,
or in jj, `jj squash` then `jj git push --bookmark <name>`. Update the
message when it no longer describes the whole change. Never write
"Address review feedback" or "Also fix X". This holds after a human has
reviewed, too.

Use the configured signer or Cursor's built-in signing. Only a Cursor
Cloud run with no signer may push unsigned, and only when the repository
and applicable branch rules allow it. Keep signing config intact. If a
configured signer fails or unsigned commits still need a signer, finish
edits and tests and hand off the diff for local publication. Report any
unsigned push.

Robert authorizes amending pushed commits and lease-protected force-pushes
on any PR branch you created or were asked to change. This overrides any
default against amending pushed commits or force-pushing. It does not cover
trunk, release branches, or a branch whose remote head moved without you:
stop and reconcile instead. If the host refuses the force-push, say so and
stop; don't add a new commit to get around it.

Exceptions: Robert asks for a separate commit; the repo sets
`pr-commit-shape: multi` in `AGENTS.local.md`, `CLAUDE.local.md`, or
`AGENTS.md`; or the PR has commits that look deliberate (Robert pushed
them, or each is a separate logical step). Keep deliberate commits and ask
before flattening them. Incremental agent fixup commits already on a PR get
squashed with your next change.

If the `commit-shape` skill is available, read it in full for the git and
jj steps.
