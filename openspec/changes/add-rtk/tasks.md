## 1. Installation

- [ ] 1.1 Add `rtk` to Brewfile with pinned version
- [ ] 1.2 Verify `rtk --version` works after `mise run brew:install`

## 2. RTK Configuration

- [ ] 2.1 Create `packages/rtk/config.toml` with conservative defaults (tee always-on, max_files 50, exclude_commands for test runners and compilers)
- [ ] 2.2 Add `link_dotfile` entry in `mise/tasks/dot/install` to symlink `packages/rtk/config.toml` to `~/.config/rtk/config.toml`

## 3. Claude Code Integration

- [ ] 3.1 Create `packages/claude/hooks/rtk-rewrite.sh` — PreToolUse hook that rewrites Bash commands through RTK, with graceful fallback when RTK is absent
- [ ] 3.2 Create `packages/claude/RTK.md` — awareness doc for Claude (RTK is active, `rtk proxy` bypasses, tee dir for full output)
- [ ] 3.3 Update `packages/claude/settings.json` to add PreToolUse hook entry for Bash commands pointing to rtk-rewrite.sh
- [ ] 3.4 Add `link_dotfile` entry in `mise/tasks/dot/install` for the hooks directory

## 4. Codex Integration

- [ ] 4.1 Create `packages/codex/RTK.md` — instructions for Codex to prefix commands with `rtk`
- [ ] 4.2 Create `packages/codex/AGENTS.md` with `@RTK.md` reference
- [ ] 4.3 Add `link_dotfile` entries in `mise/tasks/dot/install` for Codex AGENTS.md and RTK.md

## 5. Audit & Evaluation Tooling

- [ ] 5.1 Create `mise/tasks/rtk/audit` — runs baseline commands through `rtk` and `rtk proxy`, saves outputs, reports compression ratios, diffs against previous baseline
- [ ] 5.2 Create `packages/rtk/baselines/` directory structure for storing version-specific audit baselines
- [ ] 5.3 Run initial audit and save baseline for the pinned RTK version

## 6. RTK Evaluation Skill

- [ ] 6.1 Create `packages/agents/skills/rtk-evaluate/SKILL.md` — skill guiding an AI agent through RTK version upgrade evaluation (changelog review, audit run, security check)

## 7. Verification

- [ ] 7.1 Run `mise run dot:install` and verify all symlinks are correct
- [ ] 7.2 Start a Claude Code session and verify RTK hook fires on Bash commands
- [ ] 7.3 Verify `rtk proxy` bypass works from within a Claude Code session
- [ ] 7.4 Verify RTK absence doesn't break Claude Code (temporarily rename rtk binary, confirm hook falls through)
