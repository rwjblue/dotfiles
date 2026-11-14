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
The system SHALL link `~/.codex/AGENTS.md` to the shared `packages/agents/AGENTS.md` via `mise run dot:install`.

#### Scenario: Shared instructions cover RTK
- **WHEN** Codex reads its global instructions
- **THEN** it learns to prefix shell commands with `rtk` when available and to use `rtk proxy` for unfiltered output

### Requirement: Easy rollback
Removing the RTK instructions from the shared AGENTS.md SHALL disable manual
prefixing guidance. Removing the hook entry from Claude Code settings.json
SHALL disable automatic rewriting.

#### Scenario: Disable automatic rewriting for Claude Code
- **WHEN** the PreToolUse hook entry is removed from settings.json
- **THEN** Claude Code no longer rewrites Bash commands through RTK

#### Scenario: Disable for Codex
- **WHEN** RTK instructions are removed from the shared AGENTS.md
- **THEN** Codex sessions work normally without RTK
