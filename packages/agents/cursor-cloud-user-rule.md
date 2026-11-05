# Cursor user rule: cloud-agent skill fallback

Paste everything below the line into Cursor → Customize → Rules.
This file is the source of that paste. Cursor does not read it from git.

Skills normally reach Cloud Agents through Cursor's Sync Skills for Cloud
Agents (fed by `mise run cursor:skills-sync`) or a repo start script that runs
`packages/cursor/cloud-agent-bootstrap.sh`. Neither covers every launch path
(automations skip synced skills), so this rule is the fallback.

---

Cloud-agent skills fallback. If you are not a Cursor Cloud Agent
(home is `/home/ubuntu`), ignore this rule.

GitHub gate: open PRs as draft. Do not mark them ready for review. Do not
request review. Do not comment on the PR or on review threads. Do not
approve or merge. Follow-up stays in the Cursor cloud-agent thread.
Only an explicit instruction from Robert in the user conversation lifts
this gate, and only for that action.

PR descriptions: Cursor's PR tool (`update_pr`) replaces only the text
between `<!-- CURSOR_AGENT_PR_BODY_BEGIN -->` and
`<!-- CURSOR_AGENT_PR_BODY_END -->`. On a body without those markers,
such as a PR Robert opened locally, it keeps the old body and appends a
second copy. Before you send a body with `update_pr`, read the live body
with `gh pr view`. If both markers are there, use `update_pr` and leave
the markers out of the body you pass; the tool adds them. If they are
missing, do not call `update_pr` with a body. Write the full new body,
wrapped in the two markers, to a file Robert can open (the Project
store, or `/opt/cursor/artifacts/`), and give him
`gh pr edit <number> --repo <owner/repo> --body-file <path>` to run.
Once he has, later updates go through `update_pr`. The tool also
adds an "Open in Web / Open in Cursor" footer that no setting removes;
leave it.

Robert's personal skills (`commit-message`, `pr-description`,
`rwjblue-mode`, and others) come from https://github.com/rwjblue/dotfiles.
If `commit-message` is in your available-skills catalog, use the catalog
copies and skip the snippet below.

Otherwise, at the start of the session, before other work, fetch the
latest copy. Always run it, even if `~/dotfiles` exists, so a cached
environment doesn't serve stale skills:

```bash
if [ -d "$HOME/dotfiles/.git" ]; then
  git -C "$HOME/dotfiles" pull --ff-only --quiet
else
  git clone --depth 1 --quiet https://github.com/rwjblue/dotfiles.git "$HOME/dotfiles"
fi
```

Skills fetched this way are not in your catalog. Do not invoke them by
name. Read `$HOME/dotfiles/packages/agents/skills/<name>/SKILL.md` and
treat that file as the skill.

Before you draft any commit message, PR title, or PR body (including the
automatic PR at the end of a Cloud Agent run), Read the `commit-message`
and `pr-description` skills in full and follow them. Do not improvise. Do
not rely on a remembered BLUF or conventional-commit habit.

Do not copy those files into the current repo.
