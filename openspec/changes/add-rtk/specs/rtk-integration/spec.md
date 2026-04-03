## ADDED Requirements

### Requirement: RTK installed via Homebrew
The system SHALL install RTK via the Brewfile with a pinned version.

#### Scenario: Fresh install
- **WHEN** `mise run brew:install` is run on a new machine
- **THEN** RTK is installed at the pinned version and `rtk --version` succeeds

#### Scenario: Version pinning prevents silent upgrade
- **WHEN** `brew upgrade` is run
- **THEN** RTK is NOT upgraded beyond the pinned version

### Requirement: RTK config managed in dotfiles
The system SHALL store RTK configuration in `packages/rtk/config.toml` and symlink it to `~/.config/rtk/config.toml` via `mise run dot:install`.

#### Scenario: Config symlinked on install
- **WHEN** `mise run dot:install` is run
- **THEN** `~/.config/rtk/config.toml` is a symlink to `packages/rtk/config.toml`

#### Scenario: Config includes conservative defaults
- **WHEN** the RTK config is read
- **THEN** `tee.mode` is set to `"always"`, `tee.max_files` is set to `50`, and `hooks.exclude_commands` includes test runners and compilers

### Requirement: Claude Code hook for transparent rewriting
The system SHALL provide a PreToolUse hook at `packages/claude/hooks/rtk-rewrite.sh` that transparently rewrites Bash commands through RTK.

#### Scenario: Hook registered in settings.json
- **WHEN** `packages/claude/settings.json` is read
- **THEN** it contains a `PreToolUse` hook entry for `Bash` commands pointing to the rtk-rewrite script

#### Scenario: Hook rewrites commands
- **WHEN** Claude Code executes a Bash command like `git status`
- **THEN** the hook rewrites it to `rtk git status` and returns the compressed output

#### Scenario: Hook handles RTK absence gracefully
- **WHEN** the `rtk` binary is not found in PATH
- **THEN** the hook passes the command through unchanged (no error, no broken session)

### Requirement: Claude Code RTK awareness doc
The system SHALL provide `packages/claude/RTK.md` with brief instructions telling Claude that RTK is active and how to bypass it when needed.

#### Scenario: Awareness doc content
- **WHEN** Claude Code reads RTK.md
- **THEN** it learns that `rtk proxy <cmd>` bypasses compression and that full output is available in the tee directory

### Requirement: Codex RTK integration
The system SHALL provide `packages/codex/AGENTS.md` and `packages/codex/RTK.md` with instructions for Codex to prefix shell commands with `rtk`.

#### Scenario: AGENTS.md references RTK.md
- **WHEN** Codex reads AGENTS.md
- **THEN** it finds an `@RTK.md` reference

#### Scenario: RTK.md instructs prefixing
- **WHEN** Codex reads RTK.md
- **THEN** it learns to prefix shell commands with `rtk` and that `rtk proxy` bypasses compression

### Requirement: Easy rollback
Disabling RTK SHALL require only removing the hook entry from settings.json (Claude Code) or the RTK instructions from AGENTS.md (Codex). No other config changes needed.

#### Scenario: Disable for Claude Code
- **WHEN** the PreToolUse hook entry is removed from settings.json
- **THEN** Claude Code sessions work normally without RTK, with no errors or missing config references

#### Scenario: Disable for Codex
- **WHEN** RTK references are removed from AGENTS.md
- **THEN** Codex sessions work normally without RTK
