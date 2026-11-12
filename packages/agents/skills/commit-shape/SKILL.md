---
name: commit-shape
description: >-
  When to add a commit and when to amend one: commit freely while work is
  local, squash to one commit per PR when opening it, then amend and
  lease-push every later change. Use when opening a PR, pushing changes to an
  existing PR branch, or choosing between a new commit and an amend, in git or
  jj. Reads the pr-commit-shape repo setting.
---

# Commit shape

A PR carries exactly one commit from the moment it opens. Before that,
commit as often as is useful.

The reasons:

- GitHub's squash-merge uses a lone commit's message as-is. For several
  commits, it lists every message, so fixup subjects land in trunk history.
- With one commit, a rebase resolves each conflict once, instead of once
  per commit that touched the file.

## Load this from another skill

Skills cannot import each other. A caller should:

1. Invoke `commit-shape` by name if the agent supports it (Cursor / Claude Code: `/commit-shape`; Pi: `/skill:commit-shape`; Codex: the skill name).
2. Otherwise read the sibling file `../commit-shape/SKILL.md` relative to the calling skill.
3. If that path is missing, read `~/.agents/skills/commit-shape/SKILL.md`.

Then follow this file in full.

## Repo setting

Read `pr-commit-shape` with the repo-settings lookup in
`../commit-message/SKILL.md` (`AGENTS.local.md`, then `CLAUDE.local.md`,
then `AGENTS.md`).

- `single` (the default): follow the lifecycle below.
- `multi`: the repo wants a PR's commits kept as separate logical steps.
  When opening the PR, keep those commits. Fold each later fix into the
  commit that introduced the code it fixes, and add a commit only for new
  work.

## Lifecycle

1. **While the work is local.** Before a PR exists, use as many commits as
   help: checkpoints, one per plan task, a failing test first. Pushing a
   branch that has no PR yet (Cloud Agents do this as they go) doesn't
   change that.
2. **Opening the PR.** Squash the PR's commits into one before creating it,
   and write the message for the combined change (`../commit-message/SKILL.md`,
   "Squashing or amending"). In a stack, each PR gets its own single commit.
3. **After the PR opens.** Every change to it goes into that one commit:
   review fixes, CI fixes, rebases, and scope growth. Amend, update the
   message if it no longer describes the whole change, and force-push with
   a lease. This holds after a human has reviewed, too.

A PR is open once it exists on GitHub, whether it's a draft or ready.

## Authorization

Robert authorizes amending pushed commits and lease-protected force-pushes
on any PR branch the agent created or was asked to change. This overrides
built-in agent defaults against amending pushed commits or force-pushing.

It doesn't cover trunk, a release branch, or a branch whose remote head
moved without you. In that last case, stop and reconcile; never overwrite
someone else's push.

If the host refuses the force-push (branch protection, credentials), say so
and stop. Don't add a new commit to get around it.

## Exceptions

- Robert asks for a separate commit. Do that, for that change only.
- The repo sets `pr-commit-shape: multi`.
- The PR already has several commits. If they're incremental fixups from an
  agent ("Fix lint", "Address review"), squash them with your next change
  and say so in your report. If they look deliberate (Robert pushed them, or
  each is a separate logical step with its own full message), keep them and
  ask before flattening.

## git

Keep whatever signing the environment configures. Never pass
`--no-gpg-sign` or override signing config.

Before changing a pushed branch, record the remote SHA you start from. That
SHA is the lease. Don't refresh it right before pushing, or the lease stops
protecting anything.

```bash
git fetch origin <branch>
expected=$(git rev-parse origin/<branch>)
```

Squash when opening the PR, with a clean working tree:

```bash
git reset --soft "$(git merge-base origin/<base> HEAD)"
git commit -F /tmp/commit-msg.txt
```

Amend after the PR opens:

```bash
git add <paths>
git commit --amend --no-edit           # message still fits
git commit --amend -F /tmp/commit-msg.txt  # message needs updating
```

Push with the lease:

```bash
git fetch origin <branch>
test "$(git rev-parse origin/<branch>)" = "$expected"  # else stop and reconcile
git push --force-with-lease=refs/heads/<branch>:"$expected" origin HEAD:refs/heads/<branch>
```

## jj

Squash when opening the PR. `<base>` is `trunk()`, or the parent PR's
bookmark in a stack:

```bash
jj squash --from '<base>..@-' --into 'roots(<base>..@-)' -m "$(cat /tmp/commit-msg.txt)"
```

Amend after the PR opens: make the change in `@` on top of the PR's commit,
then fold it in. With an undescribed `@`, the PR commit keeps its message.

```bash
jj squash
jj describe -r @- --stdin < /tmp/commit-msg.txt  # only if the message needs updating
```

To fix a commit lower in a stack, use the fixup flow in `../jj/SKILL.md`
(`jj new --insert-after <rev>`, then `jj squash`).

Push one bookmark: `jj git push --bookmark <name>`. jj refuses the push if
the remote moved since your last fetch. If it does, fetch and reconcile;
don't force past it.
