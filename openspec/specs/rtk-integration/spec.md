# RTK integration

## Purpose

Install a reviewed RTK release and configure how agent clients use it to reduce shell output.

## Requirements

### Requirement: RTK installed via mise
The system SHALL pin RTK's OSS release in the global mise tool configuration and lockfile.

#### Scenario: Fresh install
- **WHEN** `mise run tools:install` is run on a new machine
- **THEN** RTK is installed at the pinned version and `rtk --version` succeeds

#### Scenario: Version pinning prevents silent upgrade
- **WHEN** `mise upgrade` is run within the configured version ranges
- **THEN** RTK remains at the pinned version

### Requirement: RTK config managed in dotfiles
The system SHALL store RTK configuration in `packages/rtk/config.toml` and symlink it to RTK's platform config directory via `mise run dot:install`.

#### Scenario: Config symlinked on install
- **WHEN** `mise run dot:install` is run
- **THEN** the symlink points to `packages/rtk/config.toml` from `~/Library/Application Support/rtk/config.toml` on macOS and `~/.config/rtk/config.toml` on Linux

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
- **THEN** the hook returns a rewritten command such as `rtk git status` for Claude Code to run

#### Scenario: Hook handles RTK absence gracefully
- **WHEN** the `rtk` binary is not found in PATH
- **THEN** the hook passes the command through unchanged (no error, no broken session)

### Requirement: Claude Code RTK awareness doc
The system SHALL provide `packages/claude/RTK.md` with brief instructions telling Claude that RTK is active and how to bypass it when needed.

#### Scenario: Awareness doc content
- **WHEN** Claude Code reads RTK.md
- **THEN** it learns that `rtk bypass <cmd>` runs a command without RTK formatting and how to use a recovery path when RTK prints one

### Requirement: Codex RTK integration
The system SHALL link `~/.codex/AGENTS.md` to the shared `packages/agents/AGENTS.md` via `mise run dot:install`.

#### Scenario: Shared instructions cover RTK
- **WHEN** Codex reads its global instructions
- **THEN** it learns to use RTK for supported noisy commands when a summary suffices and to use `rtk bypass` when a hook would rewrite a command whose exact output is needed

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
