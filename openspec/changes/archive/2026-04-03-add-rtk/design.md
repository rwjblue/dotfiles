## Context

Claude Code and Codex sessions consume tokens on raw shell output. RTK is a Rust CLI proxy that compresses shell output before it reaches the AI agent. This dotfiles repo manages all tool configuration via `packages/`, symlinks via `mise/tasks/dot/install`, and Homebrew via `Brewfile`.

Currently, Claude Code config lives in `packages/claude/settings.json` (symlinked to `~/.claude/settings.json`) and Codex skills in `packages/codex/skills/` (symlinked to `~/.codex/skills/`). Neither has hooks or AGENTS.md managed by this repo yet.

RTK is pre-1.0 (~10 weeks old, v0.34.x) with no security audit. We treat it as an experiment: easy to enable, easy to disable, easy to audit on updates.

## Goals / Non-Goals

**Goals:**
- Reduce token consumption in Claude Code and Codex sessions
- Manage all RTK config through dotfiles (not via `rtk init`)
- Make it trivial to audit RTK behavior when upgrading versions
- Enable easy rollback (disable RTK without breaking anything)

**Non-Goals:**
- RTK Cloud or any paid features
- Automatic RTK version updates
- Modifying RTK's source or forking it
- Using RTK for non-AI shell usage

## Decisions

### D1: Manage RTK config in dotfiles, not via `rtk init`

`rtk init -g` writes directly to `~/.claude/settings.json`, `~/.claude/CLAUDE.md`, and creates hook scripts. This conflicts with our dotfiles-managed approach where `packages/claude/settings.json` is the source of truth.

**Decision:** Write all RTK config files in `packages/rtk/`, `packages/claude/`, and `packages/codex/` manually. Never run `rtk init`. Symlink via `mise/tasks/dot/install`.

**Alternative considered:** Run `rtk init` and commit the results. Rejected because `rtk init` assumes it owns the files and may overwrite on re-run, and it writes absolute paths that aren't portable.

### D2: Pin RTK version in Brewfile

**Decision:** Pin RTK to a specific version in the Brewfile. Upgrades are intentional, preceded by running the audit task.

**Alternative considered:** Use latest. Rejected because RTK sits in a privileged position (rewriting all Bash commands) and the project is pre-1.0 with rapid churn.

### D3: Conservative exclude list for compression

**Decision:** Exclude commands where lossy compression is dangerous: test runners, compilers, and linters. Start with `exclude_commands = ["cargo test", "npm test", "pytest", "tsc", "eslint", "rustc"]`. Expand as needed.

**Alternative considered:** Exclude nothing, rely on RTK's tee-on-failure. Rejected because silent compression of error output during debugging wastes more time than the tokens saved.

### D4: Tee mode always-on

**Decision:** Set `tee.mode = "always"` so raw output is always saved to `~/.local/share/rtk/tee/`. This enables post-hoc auditing of what RTK stripped.

**Alternative considered:** `tee.mode = "failures"` (default). Rejected for initial rollout — we want full visibility. Can relax to "failures" once trust is established.

### D5: RTK evaluation as a mise task + skill

**Decision:** Create both:
1. `mise run rtk:audit` — a task that runs a set of known commands through RTK and diffs output against baselines, reporting compression ratios and any missing critical content
2. A Claude Code skill (`rtk-evaluate`) — instructions for an AI agent to systematically evaluate a new RTK version by running the audit task, reviewing the diffs, and checking the RTK changelog for relevant changes

The mise task handles the mechanical diffing. The skill handles the judgment ("is this compression safe?").

**Alternative considered:** Just a spec document listing what to check. Rejected because a runnable task is more likely to actually get used, and the skill makes it easy to delegate the evaluation to Claude.

### D6: Claude Code hook structure

**Decision:** Create `packages/claude/hooks/rtk-rewrite.sh` as the PreToolUse hook script. Add the hook entry to `packages/claude/settings.json`. Create `packages/claude/RTK.md` as the awareness doc.

The hook script will be a simplified version of what `rtk init` generates, with hardcoded paths removed in favor of `$(which rtk)`.

### D7: Codex integration via AGENTS.md

**Decision:** Create `packages/codex/AGENTS.md` with RTK prefixing instructions and `packages/codex/RTK.md` for reference. Codex doesn't support hooks, so this is prompt-instruction-based (less reliable but the only option).

## Risks / Trade-offs

- **[Lossy compression hides errors]** → Mitigated by exclude list (D3) and always-on tee (D4). Agent can check tee dir if output seems incomplete.
- **[RTK binary compromise]** → Mitigated by version pinning (D2) and audit task (D5). RTK is open source Rust, auditable.
- **[Hook conflicts with future settings.json changes]** → Mitigated by managing the hook in dotfiles (D1), not letting RTK own the file.
- **[Codex ignores RTK instructions]** → Accepted trade-off. Monitor in practice, remove if unreliable.
- **[RTK project abandoned]** → Low risk to us — we can simply remove the package and hook. No lock-in.
- **[Tee mode disk usage]** → Set `max_files = 50` with rotation. Acceptable for the visibility it provides.
